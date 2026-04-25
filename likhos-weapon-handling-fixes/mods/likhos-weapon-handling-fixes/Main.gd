extends Node

const _META_LASER_LATCH = "likho_laser_latch"
const _LASER_SOUND_VOLUME_DB = -12.0
const _FLASHLIGHT_WAV_PATH = "res://Audio/Interaction/Files/Flashlight.wav"
const _LASER_IN_START = 0.0
const _LASER_IN_DURATION = 0.015
const _LASER_OUT_START = 0.120
const _LASER_OUT_DURATION = 0.0
const _SCOPE_AIM_OFFSET = -0.05

var _lib
var _flashlight_stream: AudioStream
var _preferences: Preferences
var _current_scope_mag: float = 0.0
var _lens_min_z_cache := {}


func _ready() -> void:
	if not Engine.has_meta("RTVModLib"):
		push_error("[likho] RTVModLib meta not available")
		return
	_lib = Engine.get_meta("RTVModLib")
	_flashlight_stream = load(_FLASHLIGHT_WAV_PATH)
	if _flashlight_stream == null:
		push_warning("[likho] failed to load %s" % _FLASHLIGHT_WAV_PATH)
	_preferences = Preferences.Load()
	_lib.hook("handling-weaponhandling", _on_weapon_handling)
	_lib.hook("weaponrig-ads-post", _on_ads_post)
	_lib.hook("weaponrig-ammocheck", _on_ammo_check)
	_lib.hook("camera-scopedof-post", _on_scope_dof_post)
	print("[likho] hooks registered")


func _on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if h == null:
		return
	_lib.skip_super()
	_weapon_handling(h, delta)


func _on_ads_post(delta: float) -> void:
	var rig = _lib._caller
	if rig == null || !rig.gameData.PIP || !rig.gameData.isAiming || rig.gameData.isColliding:
		_current_scope_mag = 0.0
		return

	var optic = rig.activeOptic
	if optic == null:
		_current_scope_mag = 0.0
		return

	var lens_scale = optic.transform.basis.get_scale().y

	if optic.attachmentData.scope && !rig.gameData.secondaryOptic:
		optic.camera.fov = rig.gameData.baseFOV * lens_scale / 4.0
		rig.gameData.aimFOV = rig.gameData.baseFOV
		_current_scope_mag = rig.gameData.baseFOV / max(optic.camera.fov, 1.0)
		return

	if !optic.attachmentData.variable || rig.slotData == null:
		_current_scope_mag = 0.0
		return

	rig.gameData.aimFOV = rig.gameData.baseFOV

	match rig.slotData.zoom:
		1:
			rig.gameData.isScoped = true
			optic.camera.fov = lerp(optic.camera.fov, rig.gameData.baseFOV * lens_scale / 1.1, delta * 10.0)
			if _preferences != null:
				rig.gameData.scopeSensitivity = _preferences.aimSensitivity
		2:
			optic.camera.fov = lerp(optic.camera.fov, rig.gameData.baseFOV * lens_scale / 3.0, delta * 10.0)
			if _preferences != null:
				rig.gameData.scopeSensitivity = _preferences.scopeSensitivity
		3:
			optic.camera.fov = lerp(optic.camera.fov, rig.gameData.baseFOV * lens_scale / 6.0, delta * 10.0)
			if _preferences != null:
				rig.gameData.scopeSensitivity = _preferences.scopeSensitivity * 0.5

	_current_scope_mag = rig.gameData.baseFOV / max(optic.camera.fov, 1.0)


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


func _on_scope_dof_post(_delta: float) -> void:
	if _current_scope_mag <= 0.0:
		return
	var cam = _lib._caller
	if cam == null || cam.attribute == null:
		return
	cam.attribute.dof_blur_near_enabled = true
	cam.attribute.dof_blur_near_distance = 0.04
	cam.attribute.dof_blur_near_transition = 5.0
	cam.attribute.dof_blur_amount = clamp((_current_scope_mag - 2.0) * 0.010, 0.0, 0.20)


func _on_ammo_check() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	if rig.gameData.isChecking:
		_lib.skip_super()
		return
	_ammo_check_preserve_position(rig)
	_lib.skip_super()


func _ammo_check_preserve_position(rig) -> void:
	var prev_position = rig.gameData.weaponPosition
	await rig._rtv_vanilla_AmmoCheck()
	rig.gameData.weaponPosition = prev_position


func _weapon_handling(h, delta: float) -> void:
	var gd = h.gameData
	var data = h.data

	if gd.freeze:
		return

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
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if gd.isInspecting:
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return

	var ready_pos = data.highPosition if gd.weaponPosition == 2 else data.lowPosition
	var ready_rot = data.highRotation if gd.weaponPosition == 2 else data.lowRotation

	if gd.isRunning || gd.isChecking || (gd.isReloading && data.weaponAction != "Manual"):
		h.aimToggle = false
		h.canted = false
		gd.isAiming = false
		gd.isCanted = false
		_restore_look_sensitivity(gd)
		h.targetPosition = ready_pos
		h.targetRotation = ready_rot
		return

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
		h.targetPosition = data.cantedPosition - Vector3(-0.05, 0.05, 0.0)
		h.targetRotation = data.cantedRotation + Vector3(0.0, 00.0, -20.0)
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
		h.targetPosition = ready_pos
		h.targetRotation = ready_rot
		return

	var parent = h.get_parent()
	var optic = parent.activeOptic
	if optic:
		var aim_z = (optic.transform * Vector3(0, 0, _optic_lens_local_min_z(optic))).z + _SCOPE_AIM_OFFSET
		h.targetPosition = Vector3(0.0, -parent.aimOffset, aim_z)
	else:
		h.targetPosition = data.aimPosition
	h.targetRotation = data.aimRotation


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
