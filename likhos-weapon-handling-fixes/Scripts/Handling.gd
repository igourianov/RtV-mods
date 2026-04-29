extends RefCounted

const _META_LASER_LATCH = "likho_laser_latch"
const _LASER_SOUND_VOLUME_DB = -12.0
const _LASER_IN_START = 0.0
const _LASER_IN_DURATION = 0.015
const _LASER_OUT_START = 0.120
const _LASER_OUT_DURATION = 0.0
const _FIXED_SCOPE_AIM_OFFSET = -0.035
const _VARIABLE_SCOPE_AIM_OFFSET = -0.05
const _FLASHLIGHT_WAV_PATH = "res://Audio/Interaction/Files/Flashlight.wav"
const _PATROL_POSITION = Vector3(0.06, -0.18, -0.25)
const _PATROL_ROTATION = Vector3(25, 50, -20)
const _PATROL_WEAPON_TYPES = {"Rifle": null, "SMG": null, "Bolt": null, "Shotgun": null}
const _SECONDARY_OPTIC_LOW_ROTATION_OFFSET = Vector3(-10.0, 0.0, 0.0)

var _lib
var _preferences: Preferences
var _config
var _flashlight_stream: AudioStream
var _lens_min_z_cache := {}


func _init(lib, preferences: Preferences, config) -> void:
	_lib = lib
	_preferences = preferences
	_config = config
	_flashlight_stream = load(_FLASHLIGHT_WAV_PATH)
	if _flashlight_stream == null:
		push_warning("[likho] failed to load %s" % _FLASHLIGHT_WAV_PATH)


func on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if h == null:
		return
	_lib.skip_super()
	_weapon_handling(h, delta)


func _weapon_handling(h, delta: float) -> void:
	var gd = h.gameData
	var data = h.data

	if gd.freeze:
		return

	var lowPosition = _PATROL_POSITION if _PATROL_WEAPON_TYPES.has(data.weaponType) else data.lowPosition
	var lowRotation: Vector3
	if !_PATROL_WEAPON_TYPES.has(data.weaponType):
		lowRotation = data.lowRotation
	elif gd.secondaryOptic:
		lowRotation = _PATROL_ROTATION + _SECONDARY_OPTIC_LOW_ROTATION_OFFSET
	else:
		lowRotation = _PATROL_ROTATION
		

	var speed: float = delta * h.handlingSpeed
	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), speed)
	h.rotation_degrees = lerp(h.rotation_degrees, h.targetRotation, speed)

	if gd.isClearing:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if h.collision.is_colliding():
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		gd.isColliding = true
		gd.isAiming = false
		gd.isCanted = false
		return

	gd.isColliding = false

	if gd.isPlacing:
		gd.weaponPosition = 1
		h.targetPosition = lowPosition
		h.targetRotation = lowRotation
		return

	if gd.isInspecting:
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return

	if gd.isInserting:
		h.targetPosition = data.lowPosition 
		h.targetRotation = data.lowRotation
		gd.isAiming = false
		gd.isCanted = false
		return

	if gd.isRunning || gd.isChecking || (gd.isReloading && data.weaponAction != "Manual"):
		h.aimToggle = false
		h.canted = false
		gd.isAiming = false
		gd.isCanted = false
		_restore_look_sensitivity(gd)
		if gd.weaponPosition == 2:
			h.targetPosition = data.highPosition
			h.targetRotation = data.highRotation
		else:
			h.targetPosition = lowPosition
			h.targetRotation = lowRotation
		return

	match _config.cant_mode:
		"hold":
			h.canted = Input.is_action_pressed("canted")
		"toggle":
			if Input.is_action_just_pressed("canted"):
				h.canted = !h.canted
		_:
			if gd.aimMode == 1:
				h.canted = Input.is_action_pressed("canted")
			elif gd.aimMode == 2 && Input.is_action_just_pressed("canted"):
				h.canted = !h.canted

	if h.canted:
		if gd.aimMode == 1:
			_laser_activate(h)
		gd.isCanted = true
		gd.isAiming = false
		if _preferences != null:
			gd.lookSensitivity = _preferences.aimSensitivity
		h.targetPosition = data.cantedPosition + Vector3(0.0, -0.05, 0.0)
		h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, -20.0)
		return

	_laser_deactivate(h)
	gd.isCanted = false
	_restore_look_sensitivity(gd)

	if gd.aimMode == 2 && Input.is_action_just_pressed("aim"):
		h.aimToggle = !h.aimToggle

	if gd.aimMode == 2:
		gd.isAiming = h.aimToggle
	else:
		gd.isAiming = Input.is_action_pressed("aim")

	if !gd.isAiming:
		if gd.weaponPosition == 2:
			h.targetPosition = data.highPosition
			h.targetRotation = data.highRotation
		else:
			h.targetPosition = lowPosition
			h.targetRotation = lowRotation
		return

	var parent = h.get_parent()
	var optic = parent.activeOptic
	if optic && gd.PIP && optic.attachmentData.scope && !gd.secondaryOptic:
		var aim_z = _optic_lens_aim_z(optic) + _FIXED_SCOPE_AIM_OFFSET
		h.targetPosition = Vector3(0.0, -parent.aimOffset, aim_z)
	elif optic && gd.PIP && optic.attachmentData.variable && !gd.secondaryOptic:
		var aim_z = _optic_lens_aim_z(optic) + _VARIABLE_SCOPE_AIM_OFFSET
		h.targetPosition = Vector3(0.0, -parent.aimOffset, aim_z)
	elif optic:
		var y_offset: float = parent.aimOffset
		if gd.secondaryOptic && optic.secondary != null:
			var primary_in_rig: Vector3 = parent.to_local(optic.global_position)
			var secondary_in_rig: Vector3 = parent.to_local(optic.secondary.global_position)
			y_offset = optic.position.y + (secondary_in_rig.y - primary_in_rig.y)
		h.targetPosition = Vector3(0.0, -y_offset, data.aimPosition.z)
		if gd.isScoped:
			h.targetPosition += Vector3(0.0, 0.0, -0.1)
	else:
		h.targetPosition = data.aimPosition
	h.targetRotation = data.aimRotation


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


func _restore_look_sensitivity(gd) -> void:
	if _preferences != null:
		gd.lookSensitivity = _preferences.lookSensitivity


func _find_laser(h) -> Node:
	var rig = h.get_parent()
	if rig == null:
		return null
	var atts = rig.get("attachments")
	if atts == null:
		return null
	for child in atts.get_children():
		if child.visible && child.has_method("PlayLaser"):
			return child
	return null


func _laser_activate(h) -> void:
	if h.get_meta(_META_LASER_LATCH, false):
		return
	var node = _find_laser(h)
	if node == null or node.active:
		return
	node.active = true
	node.raycast.global_position = node.owner.raycast.global_position
	node.laser.show()
	_play_laser_sound(node, _LASER_IN_START, _LASER_IN_DURATION)
	h.set_meta(_META_LASER_LATCH, true)


func _laser_deactivate(h) -> void:
	if not h.get_meta(_META_LASER_LATCH, false):
		return
	h.set_meta(_META_LASER_LATCH, false)
	var node = _find_laser(h)
	if node == null:
		return
	node.active = false
	node.laser.hide()
	_play_laser_sound(node, _LASER_OUT_START, _LASER_OUT_DURATION)


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
