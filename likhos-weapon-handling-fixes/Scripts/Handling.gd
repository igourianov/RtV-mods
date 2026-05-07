extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

const _META_LASER_LATCH = "likho_laser_latch"
const _LASER_SOUND_VOLUME_DB = -12.0
const _LASER_IN_START = 0.0
const _LASER_IN_DURATION = 0.015
const _LASER_OUT_START = 0.120
const _LASER_OUT_DURATION = 0.0
const _FIXED_SCOPE_AIM_OFFSET = -0.035
const _VARIABLE_SCOPE_AIM_OFFSET = -0.05
const _PATROL_POSITION = Vector3(0.06, -0.18, -0.25)
const _PATROL_ROTATION = Vector3(25, 50, -20)
const _PATROL_WEAPON_TYPES = {"Rifle": null, "SMG": null, "Bolt": null, "Shotgun": null}
const _SECONDARY_OPTIC_LOW_ROTATION_OFFSET = Vector3(-10.0, 0.0, 0.0)
const _MOSIN_LOW_ROTATION_OFFSET = Vector3(-15.0, 15.0, 0.0)
const _REMINGTON_870_LOW_ROTATION_OFFSET = Vector3(-20.0, 10.0, 0.0)
const _BASE_WEAPON_WEIGHT = 4.0

# the handling speed modifier - read as % of base
enum HandlingMode {
	Default = 100,
	RDS = 115,
	Cant = 130,
	Scope1x = 105,
	ScopeZoom = 80
}

var _lib
var _preferences: Preferences
var _flashlight_stream: AudioStream = load("res://Audio/Interaction/Files/Flashlight.wav")
var _lens_min_z_cache := {}
var _handlingMode = HandlingMode.Default
var _laser
var _weapon_weight: float = 0.0
var gameData = preload("res://Resources/GameData.tres")


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences
	if _flashlight_stream == null:
		Out.warning("failed to load flashlight audio")


func on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if h == null:
		return
	_lib.skip_super()
	_weapon_handling(h, h.get_parent(), delta)


func _weapon_handling(h, rig, delta: float) -> void:
	var data = h.data
	var optic = rig.activeOptic

	if gameData.freeze:
		return

	var lowPosition: Vector3
	var lowRotation: Vector3
	if ModConfig.disable_lowered_override:
		lowPosition = data.lowPosition
		lowRotation = data.lowRotation
	else:
		lowPosition = _PATROL_POSITION if _PATROL_WEAPON_TYPES.has(data.weaponType) else data.lowPosition
		if !_PATROL_WEAPON_TYPES.has(data.weaponType):
			lowRotation = data.lowRotation
		elif gameData.secondaryOptic:
			lowRotation = _PATROL_ROTATION + _SECONDARY_OPTIC_LOW_ROTATION_OFFSET
		elif data.file == "Mosin":
			lowRotation = _PATROL_ROTATION + _MOSIN_LOW_ROTATION_OFFSET
		elif data.file == "Remington_870":
			lowRotation = _PATROL_ROTATION + _REMINGTON_870_LOW_ROTATION_OFFSET
		else:
			lowRotation = _PATROL_ROTATION
	
	var speed: float
	if ModConfig.override_handling_speed:
		var weightFactor = _BASE_WEAPON_WEIGHT / lerp(_BASE_WEAPON_WEIGHT, _weapon_weight, ModConfig.handling_speed_weight_factor)
		speed = h.handlingSpeed * (_handlingMode / 100.0) * weightFactor
	else:
		speed = h.handlingSpeed
	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), delta * speed)
	h.rotation_degrees = lerp(h.rotation_degrees, h.targetRotation, delta * speed)

	if gameData.isClearing:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		_handlingMode = HandlingMode.Default
		_laser_deactivate(h)
		gameData.isAiming = false
		gameData.isCanted = false		
		return

	if h.collision.is_colliding():
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		gameData.isColliding = true
		gameData.isAiming = false
		gameData.isCanted = false
		_handlingMode = HandlingMode.Default
		return

	gameData.isColliding = false

	if gameData.isPlacing:
		gameData.weaponPosition = 1
		h.targetPosition = lowPosition
		h.targetRotation = lowRotation
		_handlingMode = HandlingMode.Default
		_laser_deactivate(h)
		gameData.isAiming = false
		gameData.isCanted = false
		return

	if gameData.isInspecting:
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		_handlingMode = HandlingMode.Default
		_laser_deactivate(h)
		gameData.isAiming = false
		gameData.isCanted = false
		return

	if gameData.isInserting:
		h.targetPosition = data.lowPosition 
		h.targetRotation = data.lowRotation
		_handlingMode = HandlingMode.Default
		_laser_deactivate(h)
		gameData.isAiming = false
		gameData.isCanted = false
		return

	if gameData.isRunning || gameData.isChecking || (gameData.isReloading && data.weaponAction != "Manual"):
		gameData.isAiming = false
		if !gameData.isRunning:
			gameData.isCanted = false
			_laser_deactivate(h)
		_restore_look_sensitivity(gameData)
		_handlingMode = HandlingMode.Default
		if gameData.weaponPosition == 2:
			h.targetPosition = data.highPosition
			h.targetRotation = data.highRotation
		else:
			h.targetPosition = lowPosition
			h.targetRotation = lowRotation
		return

	var cantToggle = false
	if ModConfig.cant_mode == "default":
		cantToggle = gameData.aimMode == 2
	elif ModConfig.cant_mode == "toggle":
		cantToggle = true

	if !cantToggle:
		gameData.isCanted = Input.is_action_pressed("canted")
	elif Input.is_action_just_pressed("canted"):
		gameData.isCanted = !gameData.isCanted 

	if gameData.isCanted:
		_handlingMode = HandlingMode.Cant
		if ModConfig.laser_auto_on:
			_laser_activate(h)
		_restore_look_sensitivity(gameData)
		if ModConfig.disable_canted_override:
			h.targetPosition = data.cantedPosition
			h.targetRotation = data.cantedRotation
		else:
			h.targetPosition = data.cantedPosition + Vector3(0.0, -0.05, 0.0)
			h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, -20.0)
		return

	_laser_deactivate(h)
	_restore_look_sensitivity(gameData)

	if gameData.aimMode == 1: # hold
		gameData.isAiming = Input.is_action_pressed("aim")
	elif Input.is_action_just_pressed("aim"):
		gameData.isAiming = !gameData.isAiming

	if !gameData.isAiming:
		if gameData.weaponPosition == 2:
			h.targetPosition = data.highPosition
			h.targetRotation = data.highRotation
		else:
			h.targetPosition = lowPosition
			h.targetRotation = lowRotation
		return

	if optic == null:
		_handlingMode = HandlingMode.Default
	elif optic.attachmentData.scope && !gameData.secondaryOptic:
		_handlingMode = HandlingMode.ScopeZoom
	elif optic.attachmentData.variable:
		_handlingMode = HandlingMode.Scope1x if rig.slotData.zoom == 1 else HandlingMode.ScopeZoom
	else:
		_handlingMode = HandlingMode.RDS

	if ModConfig.disable_optic_override:
		if rig.activeOptic:
			h.targetPosition = Vector3(0.0, -rig.aimOffset, data.aimPosition.z)
		else:
			h.targetPosition = data.aimPosition
		h.targetRotation = data.aimRotation
		if gameData.isScoped && !gameData.PIP:
			h.targetPosition -= Vector3(0.0, 0.0, 0.1)
	else:
		if optic && gameData.PIP && optic.attachmentData.scope && !gameData.secondaryOptic:
			var aim_z = _optic_lens_aim_z(optic) + _FIXED_SCOPE_AIM_OFFSET - ModConfig.eye_relief_offset
			h.targetPosition = Vector3(0.0, -rig.aimOffset, aim_z)
		elif optic && gameData.PIP && optic.attachmentData.variable && !gameData.secondaryOptic:
			var aim_z = _optic_lens_aim_z(optic) + _VARIABLE_SCOPE_AIM_OFFSET - ModConfig.eye_relief_offset
			h.targetPosition = Vector3(0.0, -rig.aimOffset, aim_z)
		elif optic:
			var y_offset: float = rig.aimOffset
			if gameData.secondaryOptic && optic.secondary != null:
				var primary_in_rig: Vector3 = rig.to_local(optic.global_position)
				var secondary_in_rig: Vector3 = rig.to_local(optic.secondary.global_position)
				y_offset = optic.position.y + (secondary_in_rig.y - primary_in_rig.y)
			h.targetPosition = Vector3(0.0, -y_offset, data.aimPosition.z)
			if gameData.isScoped:
				h.targetPosition += Vector3(0.0, 0.0, -0.1)
		else:
			h.targetPosition = data.aimPosition
		h.targetRotation = data.aimRotation


func on_rig_update_post(_animate) -> void:
	var manager = _lib._caller
	if manager == null:
		return
	var rig = manager.get_child(manager.get_child_count() - 1) if manager.get_child_count() else null

	# save weapon weight for the handling speed calc
	var weapon = rig.weaponSlot.get_children()[0] if rig && rig.weaponSlot else null
	_weapon_weight = weapon.Weight() if weapon else 0.0

	# save laser module reference
	_laser = null
	for node in (rig.attachments.get_children() if rig else []):
		if node.visible && node.has_method("PlayLaser"):
			_laser = node

	# BUG FIX
	# Vanilla forgets to reset secondaryOptic flag when equipping another optic 
	# Causes other scopes to break in PIP mode
	var optic = rig.activeOptic if rig else null
	if gameData.secondaryOptic:
		if optic == null || !optic.attachmentData.secondary || optic.secondary == null:
			gameData.secondaryOptic = false


func _optic_lens_aim_z(optic) -> float:
	var local_min_z = _optic_lens_local_min_z(optic)
	return (optic.transform * Vector3(0, 0, local_min_z)).z


func _optic_lens_local_min_z(optic) -> float:
	var key = optic.scene_file_path if optic.scene_file_path != "" else optic.name
	if _lens_min_z_cache.has(key):
		return _lens_min_z_cache[key]
	if optic.mesh == null or optic.mesh.mesh == null:
		return 0.0
	var arrays = optic.mesh.mesh.surface_get_arrays(optic.maskIndex)
	if arrays.is_empty():
		return 0.0
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return 0.0
	var t = optic.mesh.transform
	var min_z = INF
	for v in verts:
		min_z = min(min_z, (t * v).z)
	_lens_min_z_cache[key] = min_z
	return min_z


func _restore_look_sensitivity(gameData) -> void:
	if _preferences != null:
		gameData.lookSensitivity = _preferences.lookSensitivity


func _laser_activate(h) -> void:
	if h.get_meta(_META_LASER_LATCH, false) || !_laser:
		return
	_laser.active = true
	_laser.raycast.global_position = _laser.owner.raycast.global_position
	_laser.laser.show()
	_play_laser_sound(_laser, _LASER_IN_START, _LASER_IN_DURATION)
	h.set_meta(_META_LASER_LATCH, true)


func _laser_deactivate(h) -> void:
	if !h.get_meta(_META_LASER_LATCH, false):
		return
	h.set_meta(_META_LASER_LATCH, false)
	if !_laser:
		return
	_laser.active = false
	_laser.laser.hide()
	_play_laser_sound(_laser, _LASER_OUT_START, _LASER_OUT_DURATION)


func _play_laser_sound(node, start: float, duration: float) -> void:
	var audio = node.audioInstance2D.instantiate()
	node.add_child(audio)
	if _flashlight_stream != null:
		audio.stream = _flashlight_stream
		audio.volume_db = _LASER_SOUND_VOLUME_DB
		audio.play(start)
		if duration > 0.0:
			var timer = node.get_tree().create_timer(duration, false)
			timer.timeout.connect(func() -> void:
				if is_instance_valid(audio):
					audio.stop()
			)
	else:
		audio.PlayInstance(node.audioLibrary.UIClick)
		audio.volume_db += _LASER_SOUND_VOLUME_DB
