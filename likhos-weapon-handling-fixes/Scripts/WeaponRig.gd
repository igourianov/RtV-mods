extends RefCounted

const _FIXED_SCOPE_AIM_OFFSET = 0.015
const _VARIABLE_SCOPE_AIM_OFFSET = 0.03
const _HOLD_THRESHOLD = 0.25
const _AMMO_CHECK_INTRO_TIME_DEFAULT = 1.0
const _HOLD_TIMER_NAME = "LikhoReloadHoldTimer"
const _AUDIO_PLAYER_NAME = "LikhoAmmoAudioPlayer"

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

enum AmmoCheckState {
	IDLE = 1,
	PENDING = 2,
	CHECK_INTRO = 3,
	CHECK_PAUSED = 4,
	CHECK_OUTRO = 5,
}

const AMMO_CHECK_INTRO_TIMES = {
	"AKM": 1.65,
	"AK_12": 1.45,
	"AKS_74U": 1.40,
	"RK_62": 1.35,
	"RK_62M": 1.35,
	"RK_95": 1.35,
	"M4A1": 1.15,
	"MK18": 1.2,
	"HK416": 1.2,
	"KAR_21_223": 1.05,
	"KAR_21_308": 1.05,
	"M78": 1.25,
	"MP5": 1.0,
	"MP5K": 1.0,
	"MP5SD": 1.0,
	"MP7": 1.3,
	"KP_31": 1.2,
	"VSS": 1.45,
	"SVD": 2.0,
	"Mosin": 1.5,
	"Remington_870": 1.2,
	"Makarov": 1.75,
	"P320": 1.15,
	"Glock_17": 1.15,
	"Colt_1911": 1.15,
}

var gameData = preload("res://Resources/GameData.tres")

var _lib
var _preferences: Preferences
var _last_optic_for_scale = null
var _cached_lens_scale: float = 1.0
var _state: AmmoCheckState = AmmoCheckState.IDLE


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

	var optic = rig.activeOptic
	var zoomIn = event.is_action_pressed("optic_zoom_in", true)
	var zoomOut = event.is_action_pressed("optic_zoom_out", true)

	if event.is_action_pressed("reload"):
		_on_reload_press(rig)
	elif event.is_action_released("reload"):
		_on_reload_release(rig)

	if (gameData.freeze
		|| gameData.isPlacing
		|| gameData.isReloading
		|| gameData.isInserting
		|| gameData.isChecking
		|| gameData.isCaching
		|| gameData.isTransitioning
		|| gameData.isFiring):
		return

	if event.is_action_pressed("inspect"):
		_inspect_toggle(rig)
		return

	if gameData.isInspecting:
		_inspect_action(rig, event.is_action_pressed("canted"), zoomIn, zoomOut)
		return

	if event.is_action_pressed("secondary_optic"):
		if optic && optic.secondary && optic.attachmentData.secondary:
			gameData.secondaryOptic = !gameData.secondaryOptic
			rig.UpdateAimOffset()

	if (gameData.isAiming || ModConfig.lpvo_ooa_zoom) && (zoomIn || zoomOut) && optic && optic.attachmentData.variable:
		if zoomIn && rig.slotData.zoom != 3:
			rig.slotData.zoom += 1
			rig.PlayRailMove()
		elif zoomOut && rig.slotData.zoom != 1:
			rig.slotData.zoom -= 1
			rig.PlayRailMove()


func _inspect_toggle(rig):
	gameData.isInspecting = !gameData.isInspecting
	gameData.isFiring = false

	if gameData.isInspecting:
		gameData.inspectPosition = 1
		rig.PlayInspectStart()
		rig.animator["parameters/conditions/Inspect_Front"] = true
		rig.animator["parameters/conditions/Inspect_Idle"] = false
		rig.UpdateBullets()
		rig.UpdateHUD()
	elif gameData.inspectPosition == 1:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Front"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
	elif gameData.inspectPosition == 2:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Back"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
		gameData.inspectPosition = 1


func _inspect_action(rig, canted, zoomIn, zoomOut):
	if canted:
		if gameData.inspectPosition == 1:
			rig.PlayInspectRotate()
			rig.animator["parameters/conditions/Inspect_Front"] = false
			rig.animator["parameters/conditions/Inspect_Back"] = true
			gameData.inspectPosition = 2
		elif gameData.inspectPosition == 2:
			rig.PlayInspectRotate()
			rig.animator["parameters/conditions/Inspect_Front"] = true
			rig.animator["parameters/conditions/Inspect_Back"] = false
			gameData.inspectPosition = 1

	var optic = rig.activeOptic
	if (zoomIn || zoomOut) && optic && optic.railMovement:
		if zoomIn && optic.position.z < optic.maxPosition:
			optic.position.z += 0.01
			rig.slotData.position += 0.01
			rig.PlayRailMove()
		elif zoomOut && optic.position.z > optic.minPosition:
			optic.position.z -= 0.01
			rig.slotData.position -= 0.01
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
	if !is_instance_valid(rig) || _is_busy(rig) || (rig.data.weaponAction != "Manual" && rig.data.weaponAction != "Single" && !rig.magazine.visible):
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
	var gd = gameData
	return (gameData.freeze
		|| gameData.isPlacing
		|| gameData.isReloading
		|| gameData.isInserting
		|| gameData.isChecking
		|| gameData.isCaching
		|| gameData.isTransitioning
		|| gameData.isFiring
		|| gameData.isOccupied
		|| gameData.isClearing
		|| gameData.isInspecting)


func _do_ammo_check(rig) -> void:
	gameData.isFiring = false
	rig.UpdateBullets()
	rig.UpdateHUD()

	gameData.isChecking = true
	_play_animation(rig, "Ammo_Check")
	var audio = _play_audio(rig, rig.data.ammoCheck)

	var intro_time: float = AMMO_CHECK_INTRO_TIMES.get(rig.data.file, _AMMO_CHECK_INTRO_TIME_DEFAULT)
	await rig.get_tree().create_timer(intro_time * 0.7, false).timeout
	if !is_instance_valid(rig):
		return

	ModConfig.ammo_check_delayed = true
	await rig.get_tree().create_timer(intro_time * 0.3, false).timeout
	if !is_instance_valid(rig):
		return

	if _state != AmmoCheckState.CHECK_INTRO:
		# released during intro, no pause happened, skip outro wait
		gameData.isChecking = false
		ModConfig.ammo_check_delayed = false
		_state = AmmoCheckState.IDLE
		return

	# held past intro: pause animator and wait for release
	rig.animator.process_mode = Node.PROCESS_MODE_DISABLED
	if audio && is_instance_valid(audio):
		audio.stream_paused = true

	_state = AmmoCheckState.CHECK_PAUSED
	while _state == AmmoCheckState.CHECK_PAUSED:
		await rig.get_tree().process_frame
		if !is_instance_valid(rig):
			return

	rig.animator.process_mode = Node.PROCESS_MODE_INHERIT
	if audio && is_instance_valid(audio):
		audio.stream_paused = false

	gameData.isChecking = false
	ModConfig.ammo_check_delayed = false
	_state = AmmoCheckState.IDLE


func _do_reload(rig) -> void:
	var gd = gameData
	var data = rig.data
	var slotData = rig.slotData

	if gameData.isOccupied:
		return

	gameData.isFiring = false

	if slotData.state == "Jammed":
		if !gameData.isClearing:
			gameData.isClearing = true
			_play_audio(rig, rig.audioLibrary.malfunctionClearRifle)
			await rig.get_tree().create_timer(2.0, false).timeout
			gameData.isClearing = false
			slotData.state = ""
		return

	if data.weaponAction == "Manual" && !gameData.isInserting:
		if slotData.amount != 0 && !slotData.chamber:
			_play_reload(rig, "Reload", data.reload)
			slotData.chamber = true
			slotData.amount -= 1
			rig.UpdateBullets()
		return

	if data.weaponAction == "Single" && !gameData.isInserting:
		if rig.interface.GetAmmo(data):
			if !slotData.chamber && !slotData.casing:
				rig.cartridge.show()
				_play_reload(rig, "Reload_Empty", data.reloadEmpty)
				slotData.chamber = true
			elif !slotData.chamber && slotData.casing:
				rig.cartridge.show()
				_play_reload(rig, "Reload_Tactical", data.reloadTactical)
				slotData.casing = false
				slotData.chamber = true
		return

	if !rig.magazine.visible && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, false):
			_play_reload(rig, "Magazine_Attach_Empty", data.magazineAttachEmpty)
			slotData.chamber = true
			rig.magazine.show()
			rig.UpdateBullets()
		return

	if !rig.magazine.visible && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, false):
			_play_reload(rig, "Magazine_Attach_Tactical", data.magazineAttachTactical)
			rig.magazine.show()
			rig.UpdateBullets()
		return

	if rig.magazine.visible && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			_play_reload(rig, "Reload_Empty", data.reloadEmpty)
			slotData.chamber = true
		return

	if rig.magazine.visible && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			_play_reload(rig, "Reload_Tactical", data.reloadTactical)
		return


func _play_reload(rig, state_name: String, event) -> void:
	gameData.isReloading = true
	_play_animation(rig, state_name)
	_play_audio(rig, event)
	await rig.get_tree().create_timer(1.5, false).timeout # wait before unlocking reload flag
	gameData.isReloading = false


func _play_animation(rig, state_name: String) -> void:
	rig.animator["parameters/playback"].start(state_name)


func _play_audio(rig, event) -> AudioStreamPlayer:
	if event == null || event.audioClips.is_empty():
		return null
	var audio = rig.get_node_or_null(_AUDIO_PLAYER_NAME)
	if audio == null:
		audio = AudioStreamPlayer.new()
		audio.name = _AUDIO_PLAYER_NAME
		rig.add_child(audio)
	else:
		audio.stop()
		audio.stream_paused = false
	audio.stream = event.audioClips.pick_random()
	audio.volume_db = event.volume
	audio.play()
	return audio


func on_update_aim_offset() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	var data = rig.data
	var optic = rig.activeOptic

	if optic && optic.secondary && gameData.secondaryOptic:
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
	var gd = gameData
	var optic = rig.activeOptic
	var att = optic.attachmentData

	ModConfig.current_scope_mag = 1.0
	if rig.slotData.zoom == 1:
		gameData.isScoped = gameData.PIP # override vanilla behavior
		ModConfig.current_scope_mag = 1.1
	elif rig.slotData.zoom == 2:
		ModConfig.current_scope_mag = 3.0
	elif rig.slotData.zoom == 3:
		ModConfig.current_scope_mag = 6.0

	if !gameData.PIP || !gameData.isAiming || gameData.isColliding || optic == null:
		return

	var lens_scale: float
	if optic == _last_optic_for_scale:
		lens_scale = _cached_lens_scale
	else:
		lens_scale = optic.transform.basis.get_scale().y
		_cached_lens_scale = lens_scale
		_last_optic_for_scale = optic

	if !att.variable && (!att.scope || gameData.secondaryOptic):
		return

	gameData.aimFOV = gameData.baseFOV # override vanilla behavior

	if att.scope && !gameData.secondaryOptic:
		ModConfig.current_scope_mag = 4.0
		var distance = distance_factor(_FIXED_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
		optic.camera.fov = distance * gameData.baseFOV * lens_scale / ModConfig.current_scope_mag
		return

	var distance = distance_factor(_VARIABLE_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
	optic.camera.fov = lerp(optic.camera.fov, distance * gameData.baseFOV * lens_scale / ModConfig.current_scope_mag, delta * 10.0)


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
