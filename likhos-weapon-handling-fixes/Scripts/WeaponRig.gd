extends RefCounted

const _FIXED_SCOPE_AIM_OFFSET = 0.015
const _VARIABLE_SCOPE_AIM_OFFSET = 0.03

const _HOLD_THRESHOLD = 0.3
const _AMMO_CHECK_INTRO_TIME_DEFAULT = 1.0
const _HOLD_TIMER_NAME = "LikhoReloadHoldTimer"
const _AUDIO_PLAYER_NAME = "LikhoAmmoAudioPlayer"

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")
const Inputs = preload("../Lib/Inputs.gd")

enum AmmoCheckState {
	NONE = 1,
	PENDING = 2,
	PULLING = 3,
	PAUSED = 4,
	REINSERTING = 5,
}

enum AmmoInsertState {
	NONE,
	OPEN,
	IDLE,
	INSERT,
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
var _ammo_check_state: AmmoCheckState = AmmoCheckState.NONE
var _is_reloading := false
var _ammo_insert_state := AmmoInsertState.NONE


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_physics_process(delta:float):
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	if _is_busy() || gameData.isReloading || gameData.isClearing || gameData.isInserting || gameData.isInspecting:
		return

	rig.FireInput()
	rig.FireTimer(delta)
	rig.FireImpulse(delta)


func on_input(event) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	if _is_busy():
		return

	if _handle_manual_reload(rig, event) || _handle_ammo(rig, event) || _handle_inspecting(rig, event) || _handle_optic(rig, event):
		return


func _handle_optic(rig, event: InputEvent) -> bool:
	var optic = rig.activeOptic
	var zoomIn = event.is_action_pressed("optic_zoom_in", true)
	var zoomOut = event.is_action_pressed("optic_zoom_out", true)

	if (gameData.isAiming || ModConfig.lpvo_ooa_zoom) && (zoomIn || zoomOut) && optic && optic.attachmentData.variable:
		if zoomIn && rig.slotData.zoom != 3:
			rig.slotData.zoom += 1
			rig.PlayRailMove()
		elif zoomOut && rig.slotData.zoom != 1:
			rig.slotData.zoom -= 1
			rig.PlayRailMove()
		return true

	if event.is_action_pressed("secondary_optic") && optic && optic.secondary && optic.attachmentData.secondary:
		gameData.secondaryOptic = !gameData.secondaryOptic
		rig.UpdateAimOffset()
		return true

	return false


func _handle_inspecting(rig, event: InputEvent) -> bool:

	if event.is_action_pressed("inspect"):
		_inspect_toggle(rig)
		return true

	if !gameData.isInspecting:
		return false

	if event.is_action_pressed("canted"):
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
		return true

	var optic = rig.activeOptic
	var zoomIn = event.is_action_pressed("optic_zoom_in", true)
	var zoomOut = event.is_action_pressed("optic_zoom_out", true)

	if (zoomIn || zoomOut) && optic && optic.railMovement:
		if zoomIn && optic.position.z < optic.maxPosition:
			optic.position.z += 0.01
			rig.slotData.position += 0.01
			rig.PlayRailMove()
		elif zoomOut && optic.position.z > optic.minPosition:
			optic.position.z -= 0.01
			rig.slotData.position -= 0.01
			rig.PlayRailMove()
		return true

	return false
	

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
		Out.protip("inspect-rotate", "Press [%s] to rotate or [%s] / [%s] to move optic" % [
			Inputs.get_binding("canted"),
			Inputs.get_binding("optic_zoom_in"),
			Inputs.get_binding("optic_zoom_out")
		])
	elif gameData.inspectPosition == 1:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Front"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
	elif gameData.inspectPosition == 2:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Back"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
		gameData.inspectPosition = 1


func _handle_ammo(rig, event):

	if _ammo_check_state == AmmoCheckState.NONE && event.is_action_pressed("reload") && !gameData.isReloading:
		_ammo_check_state = AmmoCheckState.PENDING
		_await_ammo_check(rig)
		return true

	if _ammo_check_state != AmmoCheckState.NONE && event.is_action_released("reload"):
		if _ammo_check_state == AmmoCheckState.PENDING:
			_ammo_check_state = AmmoCheckState.NONE
			_do_reload(rig)
		elif _ammo_check_state == AmmoCheckState.PULLING:
			_ammo_check_state = AmmoCheckState.REINSERTING
		elif _ammo_check_state == AmmoCheckState.PAUSED:
			_ammo_check_state = AmmoCheckState.REINSERTING
		return true

	if _ammo_check_state == AmmoCheckState.PAUSED && event.is_action_pressed("fire") && rig.data.weaponAction != "Manual":
		_ammo_check_state = AmmoCheckState.NONE
		_do_reload(rig, true)
		return true

	return false


func _await_ammo_check(rig):
	await rig.get_tree().create_timer(_HOLD_THRESHOLD, false).timeout
	if _ammo_check_state == AmmoCheckState.PENDING && is_instance_valid(rig) && !_is_busy() && (rig.data.weaponAction == "Manual" || rig.magazine.visible):
		_do_ammo_check(rig)


func _is_busy() -> bool:
	return (gameData.freeze
		|| gameData.isDead
		|| gameData.isPlacing
		|| gameData.isDrawing
		|| gameData.isCaching
		|| gameData.isTransitioning
		|| gameData.isOccupied)


func _do_ammo_check(rig) -> void:
	_ammo_check_state = AmmoCheckState.PULLING
	ModConfig.ammo_check_view = false

	gameData.isFiring = false
	gameData.isChecking = true

	rig.UpdateBullets()
	rig.UpdateHUD()
	
	_play_animation(rig, "Ammo_Check")
	var audio = _play_audio(rig, rig.data.ammoCheck)

	var intro_time: float = AMMO_CHECK_INTRO_TIMES.get(rig.data.file, _AMMO_CHECK_INTRO_TIME_DEFAULT)
	await rig.get_tree().create_timer(intro_time * 0.6, false).timeout
	if !is_instance_valid(rig):
		return

	ModConfig.ammo_check_view = true
	await rig.get_tree().create_timer(intro_time * 0.4, false).timeout
	if !is_instance_valid(rig):
		return

	if _ammo_check_state != AmmoCheckState.PULLING:
		# released during intro, no pause happened, skip outro wait
		gameData.isChecking = false
		ModConfig.ammo_check_view = false
		_ammo_check_state = AmmoCheckState.NONE
		return

	# held past intro: pause animator and wait for release
	rig.animator.process_mode = Node.PROCESS_MODE_DISABLED
	audio.stream_paused = true

	if rig.data.weaponAction != "Manual":
		Out.protip("ammo-check-reload", "Press [%s] to reload" % Inputs.get_binding("fire"))

	_ammo_check_state = AmmoCheckState.PAUSED
	while _ammo_check_state == AmmoCheckState.PAUSED:
		await rig.get_tree().process_frame
		if !is_instance_valid(rig):
			return

	rig.animator.process_mode = Node.PROCESS_MODE_INHERIT
	audio.stream_paused = false

	await rig.get_tree().create_timer((1.5 if gameData.isReloading else 0.5), false).timeout

	ModConfig.ammo_check_view = false
	gameData.isChecking = false
	_ammo_check_state = AmmoCheckState.NONE


func _do_reload(rig, ammoCheck: bool = false) -> void:
	var data = rig.data
	var slotData = rig.slotData
	var magAttach = ammoCheck || !rig.magazine.visible

	if gameData.isOccupied || gameData.isReloading || gameData.isClearing:
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
		await _play_reload(rig, "Reload", data.reload)
		slotData.casing = false
		slotData.chamber = false
		if slotData.amount:
			slotData.chamber = true
			slotData.amount -= 1
		rig.UpdateBullets()
		return

	if magAttach && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, magAttach):
			await _play_reload(rig, "Magazine_Attach_Empty", data.magazineAttachEmpty)
			slotData.chamber = true
			rig.magazine.show()
			rig.UpdateBullets()
		return

	if magAttach && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, magAttach):
			await _play_reload(rig, "Magazine_Attach_Tactical", data.magazineAttachTactical)
			rig.magazine.show()
			rig.UpdateBullets()
		return

	if rig.magazine.visible && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			await _play_reload(rig, "Reload_Empty", data.reloadEmpty)
			slotData.chamber = true
		return

	if rig.magazine.visible && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			await _play_reload(rig, "Reload_Tactical", data.reloadTactical)
		return


func _handle_manual_reload(rig, event) -> bool:

	if rig.data.weaponAction != "Manual":
		return false

	if _ammo_insert_state == AmmoInsertState.NONE && event.is_action_pressed("prepare"):
		
		_do_insert(rig)
	elif _ammo_insert_state == AmmoInsertState.IDLE && event.is_action_pressed("fire"):
		_ammo_insert_state = AmmoInsertState.INSERT
	elif _ammo_insert_state == AmmoInsertState.IDLE && event.is_action_pressed("prepare"):
		_ammo_insert_state = AmmoInsertState.NONE
	else:
		return false
	
	return true


func _do_insert(rig):
	
	gameData.isInserting = true

	_ammo_insert_state = AmmoInsertState.OPEN
	_play_audio(rig, rig.data.insertStart)
	_play_animation(rig, "Insert_Start")
	await _await_animation(rig, "Insert_Idle")
	_ammo_insert_state = AmmoInsertState.IDLE

	rig.slotData.chamber = false
	rig.slotData.casing = false

	Out.protip("ammo-check-insert", "Press [%s] to start reloading" % Inputs.get_binding("fire"))

	while _ammo_insert_state != AmmoInsertState.NONE:
		if _ammo_insert_state == AmmoInsertState.INSERT && rig.slotData.amount < rig.data.maxAmount && rig.interface.GetAmmo(rig.data):
			_play_audio(rig, rig.data.insert)
			_play_animation(rig, "Insert")
			await _await_animation(rig, "Insert_Idle")
			rig.slotData.amount += 1
		_ammo_insert_state = AmmoInsertState.IDLE
		await rig.get_tree().process_frame

	_play_audio(rig, rig.data.insertEnd)
	_play_animation(rig, "Insert_End")
	await _await_animation(rig, "Idle")

	if rig.data.weaponType == "Bolt" && rig.slotData.amount:
		rig.slotData.chamber = true
		rig.slotData.amount -= 1

	gameData.isInserting = false


func _play_reload(rig, state_name: String, event) -> void:
	Out.debug("_play_reload:", state_name)
	gameData.isReloading = true
	_play_animation(rig, state_name)
	_play_audio(rig, event)
	await _await_animation(rig)
	#if rig.data.weaponAction == "Manual":
	#	await _await_animation(rig)
	#else:
	#	await rig.get_tree().create_timer(2.0, false).timeout
	gameData.isReloading = false
	Out.debug("_play_reload done")


func _play_animation(rig, state_name: String) -> void:
	rig.animator["parameters/playback"].start(state_name)


func _await_animation(rig, target_state: String = "Idle"):
	await rig.get_tree().create_timer(0.1, false).timeout # allow animation to transition out of Idle
	var playback = rig.animator.get("parameters/playback")
	Out.debug("animation waiting for:", target_state)
	while target_state != playback.get_current_node():
		#Out.debug("animation waiting for:", target_state, "| current:", playback.get_current_node())
		await rig.get_tree().process_frame
	Out.debug("animation ended")


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
