extends RefCounted

const _FIXED_SCOPE_AIM_OFFSET = 0.015
const _VARIABLE_SCOPE_AIM_OFFSET = 0.03
const _HOLD_THRESHOLD = 0.25
const _AMMO_CHECK_INTRO_TIME_DEFAULT = 1.0
const _AMMO_CHECK_OUTRO_TIME = 1.0
const _HOLD_TIMER_NAME = "LikhoReloadHoldTimer"
const _AMMO_CHECK_STATE_NAME = "Ammo_Check"

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

enum AmmoCheckState {
	IDLE,
	PENDING,
	CHECK_INTRO,
	CHECK_PAUSED,
	CHECK_OUTRO,
}

const AMMO_CHECK_INTRO_TIMES = {
	"AKM": 1.65, #
	"AK_12": 1.45, #
	"AKS_74U": 1.40, #
	"RK_62": 1.35, #
	"RK_62M": 1.35, #
	"RK_95": 1.35, #
	"M4A1": 1.15, #
	"MK18": 1.2, #
	"HK416": 1.2, #
	"KAR_21_223": 1.05, #
	"KAR_21_308": 1.05, #
	"M78": 1.25, #
	"MP5": 1.0, #
	"MP5K": 1.0, #
	"MP5SD": 1.0, #
	"MP7": 1.3, #
	"KP_31": 1.2, #
	"VSS": 1.45, #
	"SVD": 2.0, #
	"Mosin": 1.5,
	"Remington_870": 1.2, #
	"Makarov": 1.75, #
	"P320": 1.15, #
	"Glock_17": 1.15, #
	"Colt_1911": 1.15, #
}

var gameData = preload("res://Resources/GameData.tres")

var _lib
var _preferences: Preferences
var _last_optic_for_scale = null
var _cached_lens_scale: float = 1.0
var _state: AmmoCheckState = AmmoCheckState.IDLE
var _seq: int = 0


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_ammo_check_replace() -> void:
	_lib.skip_super()


func on_reload_replace() -> void:
	_lib.skip_super()


func on_input(event) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	var gd = rig.gameData
	var optic = rig.activeOptic
	var zoomIn = Input.is_action_pressed("optic_zoom_in")
	var zoomOut = Input.is_action_pressed("optic_zoom_out")

	if event.is_action_pressed("reload"):
		_on_reload_press(rig)
	elif event.is_action_released("reload"):
		_on_reload_release(rig)

	if (gd.freeze
		|| gd.isPlacing
		|| gd.isReloading
		|| gd.isInserting
		|| gd.isChecking
		|| gd.isCaching
		|| gd.isTransitioning
		|| gd.isFiring):
		return

	if event.is_action_pressed("inspect"):
		gd.isInspecting = !gd.isInspecting
		gd.isFiring = false

		if gd.isInspecting:
			gd.inspectPosition = 1
			rig.PlayInspectStart()
			rig.animator["parameters/conditions/Inspect_Front"] = true
			rig.animator["parameters/conditions/Inspect_Idle"] = false
			rig.UpdateBullets()
			rig.UpdateHUD()
		else:
			if gd.inspectPosition == 1:
				rig.PlayInspectEnd()
				rig.animator["parameters/conditions/Inspect_Front"] = false
				rig.animator["parameters/conditions/Inspect_Idle"] = true
			elif gd.inspectPosition == 2:
				rig.PlayInspectEnd()
				rig.animator["parameters/conditions/Inspect_Back"] = false
				rig.animator["parameters/conditions/Inspect_Idle"] = true
				gd.inspectPosition = 1
		return

	if gd.isInspecting:
		if event.is_action_pressed("canted"):
			if gd.inspectPosition == 1:
				rig.PlayInspectRotate()
				rig.animator["parameters/conditions/Inspect_Front"] = false
				rig.animator["parameters/conditions/Inspect_Back"] = true
				gd.inspectPosition = 2
			elif gd.inspectPosition == 2:
				rig.PlayInspectRotate()
				rig.animator["parameters/conditions/Inspect_Front"] = true
				rig.animator["parameters/conditions/Inspect_Back"] = false
				gd.inspectPosition = 1

		if (zoomIn || zoomOut) && optic && optic.railMovement:
			if zoomIn && optic.position.z < optic.maxPosition:
				optic.position.z += 0.01
				rig.slotData.position += 0.01
				rig.PlayRailMove()
			elif zoomOut && optic.position.z > optic.minPosition:
				optic.position.z -= 0.01
				rig.slotData.position -= 0.01
				rig.PlayRailMove()
		return

	if event.is_action_pressed("secondary_optic"):
		if optic && optic.secondary && optic.attachmentData.secondary:
			gd.secondaryOptic = !gd.secondaryOptic
			rig.UpdateAimOffset()

	var zoomAllowed = (gd.isAiming
		|| ModConfig.lpvo_oof_zoom == "enabled"
		|| (ModConfig.lpvo_oof_zoom == "rail" && Input.is_action_pressed("rail_movement")))

	if zoomAllowed && (zoomIn || zoomOut) && optic && optic.attachmentData.variable:
		var slotData = rig.slotData
		if zoomIn && slotData.zoom != 3:
			slotData.zoom += 1
			rig.PlayRailMove()
		elif zoomOut && slotData.zoom != 1:
			slotData.zoom -= 1
			rig.PlayRailMove()


func _on_reload_press(rig) -> void:
	if _state != AmmoCheckState.IDLE:
		return
	if _is_busy(rig):
		return
	var timer = _get_or_create_timer(rig)
	timer.stop()
	timer.start()
	_state = AmmoCheckState.PENDING


func _on_reload_release(rig) -> void:
	if _state == AmmoCheckState.PENDING:
		var timer = rig.get_node_or_null(_HOLD_TIMER_NAME)
		if timer:
			timer.stop()
		_state = AmmoCheckState.IDLE
		_do_reload(rig)
	elif _state == AmmoCheckState.CHECK_INTRO:
		_state = AmmoCheckState.CHECK_OUTRO
	elif _state == AmmoCheckState.CHECK_PAUSED:
		rig.animator.process_mode = Node.PROCESS_MODE_INHERIT
		_state = AmmoCheckState.CHECK_OUTRO


func _on_hold_timeout(rig) -> void:
	if _state != AmmoCheckState.PENDING:
		return
	if !is_instance_valid(rig):
		_state = AmmoCheckState.IDLE
		return
	if _is_busy(rig):
		_state = AmmoCheckState.IDLE
		return
	if !_can_ammo_check(rig):
		_state = AmmoCheckState.IDLE
		return
	_state = AmmoCheckState.CHECK_INTRO
	_do_ammo_check(rig)


func _get_or_create_timer(rig) -> Timer:
	var timer = rig.get_node_or_null(_HOLD_TIMER_NAME)
	if timer == null:
		timer = Timer.new()
		timer.name = _HOLD_TIMER_NAME
		timer.one_shot = true
		timer.wait_time = _HOLD_THRESHOLD
		rig.add_child(timer)
		timer.timeout.connect(_on_hold_timeout.bind(rig))
	return timer


func _is_busy(rig) -> bool:
	var gd = rig.gameData
	return (gd.freeze
		|| gd.isPlacing
		|| gd.isReloading
		|| gd.isInserting
		|| gd.isChecking
		|| gd.isCaching
		|| gd.isTransitioning
		|| gd.isFiring
		|| gd.isOccupied
		|| gd.isClearing
		|| gd.isInspecting)


func _can_ammo_check(rig) -> bool:
	if rig.data.weaponAction != "Manual" && rig.data.weaponAction != "Single":
		if !rig.magazine.visible:
			return false
	return true


func _do_ammo_check(rig) -> void:
	_seq += 1
	var my_seq = _seq

	rig.gameData.isFiring = false
	rig.UpdateBullets()
	rig.UpdateHUD()
	rig.PlayAmmoCheck()
	rig.gameData.isChecking = true
	var playback = rig.animator["parameters/playback"]
	playback.start(_AMMO_CHECK_STATE_NAME)

	var intro_time: float = AMMO_CHECK_INTRO_TIMES.get(rig.data.file, _AMMO_CHECK_INTRO_TIME_DEFAULT)
	await rig.get_tree().create_timer(intro_time, false).timeout
	if !_seq_valid(rig, my_seq):
		return

	if _state == AmmoCheckState.CHECK_INTRO:
		rig.animator.process_mode = Node.PROCESS_MODE_DISABLED
		_state = AmmoCheckState.CHECK_PAUSED
		while _state == AmmoCheckState.CHECK_PAUSED:
			await rig.get_tree().process_frame
			if !_seq_valid(rig, my_seq):
				return
		rig.animator.process_mode = Node.PROCESS_MODE_INHERIT

	await rig.get_tree().create_timer(_AMMO_CHECK_OUTRO_TIME, false).timeout
	if !_seq_valid(rig, my_seq):
		return

	rig.gameData.isChecking = false
	_state = AmmoCheckState.IDLE


func _seq_valid(rig, my_seq: int) -> bool:
	if my_seq != _seq:
		return false
	if !is_instance_valid(rig):
		return false
	return true


func _do_reload(rig) -> void:
	var gd = rig.gameData
	var data = rig.data
	var slotData = rig.slotData

	if gd.isOccupied:
		return

	gd.isFiring = false

	if slotData.state == "Jammed":
		if !gd.isClearing:
			gd.isClearing = true
			rig.PlayMalfunctionClear()
			await rig.get_tree().create_timer(2.0, false).timeout
			gd.isClearing = false
			slotData.state = ""
		return

	if data.weaponAction == "Manual" && !gd.isInserting:
		if slotData.amount != 0 && !slotData.chamber:
			await _play_reload_anim(rig, "Reload", rig.PlayReload)
			slotData.chamber = true
			slotData.amount -= 1
			rig.UpdateBullets()
		return

	if data.weaponAction == "Single" && !gd.isInserting:
		if rig.interface.GetAmmo(data):
			if !slotData.chamber && !slotData.casing:
				rig.cartridge.show()
				await _play_reload_anim(rig, "Reload_Empty", rig.PlayReloadEmpty)
				slotData.chamber = true
			elif !slotData.chamber && slotData.casing:
				rig.cartridge.show()
				await _play_reload_anim(rig, "Reload_Tactical", rig.PlayReloadTactical)
				slotData.casing = false
				slotData.chamber = true
		return

	if !rig.magazine.visible && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, false):
			await _play_reload_anim(rig, "Magazine_Attach_Empty", rig.PlayMagazineAttachEmpty)
			slotData.chamber = true
			rig.magazine.show()
			rig.UpdateBullets()
		return

	if !rig.magazine.visible && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, false):
			await _play_reload_anim(rig, "Magazine_Attach_Tactical", rig.PlayMagazineAttachTactical)
			rig.magazine.show()
			rig.UpdateBullets()
		return

	if rig.magazine.visible && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			await _play_reload_anim(rig, "Reload_Empty", rig.PlayReloadEmpty)
			slotData.chamber = true
		return

	if rig.magazine.visible && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			await _play_reload_anim(rig, "Reload_Tactical", rig.PlayReloadTactical)
		return


func _play_reload_anim(rig, condition: String, play_sound: Callable) -> void:
	rig.gameData.isReloading = true
	play_sound.call()
	rig.animator["parameters/conditions/" + condition] = true
	await rig.get_tree().create_timer(0.1, false).timeout
	rig.animator["parameters/conditions/" + condition] = false


func on_update_aim_offset() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	var data = rig.data
	var optic = rig.activeOptic

	if optic && optic.secondary && rig.gameData.secondaryOptic:
		# HAMR secondary position fix for Russian guns
		Out.bugfix("recalc secondary optic Y offset")
		rig.aimOffset = optic.position.y + optic.secondary.position.y * optic.scale.y
	elif optic:
		rig.aimOffset = optic.position.y
	else:
		rig.aimOffset = 0.0

	if data.foldSights:
		var rot = Quaternion.from_euler(Vector3(data.foldSightsRotation if optic else 0.0, 0, 0))
		rig.skeleton.set_bone_pose_rotation(rig.backSightIndex, rot)
		if rig.frontSightIndex: # frontSightIndex is not set on M4A1
			rig.skeleton.set_bone_pose_rotation(rig.frontSightIndex, rot)
		else:
			Out.bugfix("do not attempt to rotate fron sight on M4A1 (flicker)")


func on_ads_post(delta: float) -> void:
	var rig = _lib._caller
	var gd = rig.gameData
	var optic = rig.activeOptic
	var att = optic.attachmentData

	ModConfig.current_scope_mag = 1.0
	if rig.slotData.zoom == 1:
		gd.isScoped = gd.PIP # override vanilla behavior
		ModConfig.current_scope_mag = 1.1
	elif rig.slotData.zoom == 2:
		ModConfig.current_scope_mag = 3.0
	elif rig.slotData.zoom == 3:
		ModConfig.current_scope_mag = 6.0

	if !gd.PIP || !gd.isAiming || gd.isColliding || optic == null:
		return

	var lens_scale: float
	if optic == _last_optic_for_scale:
		lens_scale = _cached_lens_scale
	else:
		lens_scale = optic.transform.basis.get_scale().y
		_cached_lens_scale = lens_scale
		_last_optic_for_scale = optic

	if !att.variable && (!att.scope || gd.secondaryOptic):
		return

	gd.aimFOV = gd.baseFOV # override vanilla behavior

	if att.scope && !gd.secondaryOptic:
		ModConfig.current_scope_mag = 4.0
		var distance = distance_factor(_FIXED_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
		optic.camera.fov = distance * gd.baseFOV * lens_scale / ModConfig.current_scope_mag
		return

	var distance = distance_factor(_VARIABLE_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
	optic.camera.fov = lerp(optic.camera.fov, distance * gd.baseFOV * lens_scale / ModConfig.current_scope_mag, delta * 10.0)


func distance_factor(base: float, distance: float) -> float:
	var f: float = base / (base + distance)
	return f


func on_insert_post() -> void:
	var rig = _lib._caller
	if rig == null:
		return

	# chamber should always be cleared when opening bolt
	if gameData.isInserting && rig.data.weaponType == "Bolt" && Input.is_action_just_pressed("prepare"):
		rig.slotData.chamber = false
		rig.slotData.casing = false
		Out.bugfix("always clear chamber when opening bolt")
