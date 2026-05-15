extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")
var gameData = preload("res://Resources/GameData.tres")

const _LASER_SOUND_VOLUME_DB = -12.0
const _LASER_IN_START = 0.0
const _LASER_IN_DURATION = 0.015
const _LASER_OUT_START = 0.120
const _LASER_OUT_DURATION = 0.0
const _PATROL_POSITION = Vector3(0.06, -0.18, -0.25)
const _PATROL_ROTATION = Vector3(25, 50, -20)
const _PATROL_WEAPON_TYPES = {"Rifle": null, "SMG": null, "Bolt": null, "Shotgun": null}
const _SECONDARY_OPTIC_LOW_ROTATION_OFFSET = Vector3(-10.0, 0.0, 0.0)
const _MOSIN_LOW_ROTATION_OFFSET = Vector3(-15.0, 15.0, 0.0)
const _REMINGTON_870_LOW_ROTATION_OFFSET = Vector3(-20.0, 10.0, 0.0)


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
var _canted_elapsed: float = 0
var _aim_elapsed: float = 0


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

	if gameData.freeze:
		return

	var oldCanted: bool = gameData.isCanted

	_handle_input(h, delta)

	if oldCanted != gameData.isCanted: # only apply laser logic on switch
		if !gameData.isCanted:
			_laser_deactivate(h)
		elif ModConfig.laser_auto_on:
			_laser_activate(h)

	if _override_handling(h, h.get_parent()):
		_handlingMode = HandlingMode.Default
		gameData.isAiming = false
		gameData.isCanted = false
	elif !_weapon_handling(h, h.get_parent(), delta):
		_set_target_idle(h)

	_apply_target(h, delta)


func _handle_input(h, delta: float):
	var aimToggle = gameData.aimMode == 2
	var cantToggle = false

	if ModConfig.cant_mode == "default":
		cantToggle = aimToggle
	elif ModConfig.cant_mode == "toggle":
		cantToggle = true

	if !cantToggle:
		gameData.isCanted = Input.is_action_pressed("canted")
	elif Input.is_action_just_pressed("canted"):
		gameData.isCanted = !gameData.isCanted

	if !aimToggle:
		gameData.isAiming = Input.is_action_pressed("aim")
	elif Input.is_action_just_pressed("aim"):
		gameData.isAiming = !gameData.isAiming

	_aim_elapsed = _aim_elapsed + delta if gameData.isAiming else 0.0
	_canted_elapsed = _canted_elapsed + delta if gameData.isCanted else 0.0

	if gameData.isAiming && gameData.isCanted:
		# resolve action conflict - last one wins
		if _aim_elapsed > _canted_elapsed:
			gameData.isAiming = false
		else:
			gameData.isCanted = false

	gameData.isColliding = h.collision.is_colliding()


func _override_handling(h, rig) -> bool:
	var data = h.data

	if gameData.isClearing:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return true

	if gameData.isInspecting:
		gameData.weaponPosition = 1
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return true
	if gameData.isInserting && data.weaponType == "Shotgun":
		gameData.weaponPosition = 1
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return true

	if gameData.isPlacing || gameData.isInserting:
		gameData.weaponPosition = 1
		_set_target_idle(h)
		return true

	if gameData.isChecking && ModConfig.ammo_check_view:
		h.targetPosition = data.highPosition
		h.targetRotation = data.highPosition
		return true

	if gameData.isChecking && gameData.isReloading:
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return true

	if gameData.isRunning || (gameData.isReloading && data.weaponAction != "Manual"):
		_set_target_idle(h)
		return true

	return false


func _weapon_handling(h, rig, delta: float) -> bool:
	var data = h.data
	var optic = rig.activeOptic

	if gameData.isColliding:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return true

	if gameData.isCanted:
		_handlingMode = HandlingMode.Cant
		if ModConfig.disable_canted_override:
			h.targetPosition = data.cantedPosition
			h.targetRotation = data.cantedRotation
		else:
			h.targetPosition = data.cantedPosition + Vector3(0.0, -0.03, 0.0)
			if optic && (optic.attachmentData.variable || optic.attachmentData.scope):
				h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, -20.0)
			else:
				h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, 10.0)
		return true

	if !gameData.isAiming:
		return false

	if optic == null:
		_handlingMode = HandlingMode.Default
	elif optic.attachmentData.scope && !gameData.secondaryOptic:
		_handlingMode = HandlingMode.ScopeZoom
	elif optic.attachmentData.variable:
		_handlingMode = HandlingMode.Scope1x if rig.slotData.zoom == 1 else HandlingMode.ScopeZoom
	else:
		_handlingMode = HandlingMode.RDS

	# vanilla logic
	if ModConfig.disable_optic_override:
		h.targetPosition = Vector3(0.0, -rig.aimOffset, data.aimPosition.z) if optic else data.aimPosition
		h.targetRotation = data.aimRotation
		if gameData.isScoped && !gameData.PIP:
			h.targetPosition -= Vector3(0.0, 0.0, 0.1)
		return true

	var aim_z = data.aimPosition.z
	if optic && gameData.PIP && !gameData.secondaryOptic:
		if optic.attachmentData.scope:
			aim_z = _optic_lens_aim_z(optic) - ModConfig.FIXED_SCOPE_AIM_OFFSET - ModConfig.eye_relief_offset
		elif optic.attachmentData.variable:
			aim_z = _optic_lens_aim_z(optic) - ModConfig.VARIABLE_SCOPE_AIM_OFFSET - ModConfig.eye_relief_offset

	h.targetPosition = Vector3(0.0, -rig.aimOffset, aim_z) if optic else data.aimPosition
	h.targetRotation = data.aimRotation
	return true


func _set_target_idle(h):
	var data = h.data

	if gameData.weaponPosition == 2:
		h.targetPosition = data.highPosition
		h.targetRotation = data.highRotation
		return

	if ModConfig.disable_lowered_override:
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	h.targetPosition = _PATROL_POSITION if _PATROL_WEAPON_TYPES.has(data.weaponType) else data.lowPosition

	if !_PATROL_WEAPON_TYPES.has(data.weaponType):
		h.targetRotation = data.lowRotation
	elif gameData.secondaryOptic:
		h.targetRotation = _PATROL_ROTATION + _SECONDARY_OPTIC_LOW_ROTATION_OFFSET
	elif data.file == "Mosin":
		h.targetRotation = _PATROL_ROTATION + _MOSIN_LOW_ROTATION_OFFSET
	elif data.file == "Remington_870":
		h.targetRotation = _PATROL_ROTATION + _REMINGTON_870_LOW_ROTATION_OFFSET
	else:
		h.targetRotation = _PATROL_ROTATION


func _apply_target(h, delta: float):
	var speed: float = h.handlingSpeed * (_handlingMode / 100.0)
	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), delta * speed)
	h.rotation_degrees = lerp(h.rotation_degrees, h.targetRotation, delta * speed)


func on_rig_update_post(_animate) -> void:
	var manager = _lib._caller
	if manager == null:
		return
	var rig = manager.get_child(manager.get_child_count() - 1) if manager.get_child_count() else null

	# save weapon weight for the handling speed calc
	var weapon = rig.weaponSlot.get_children()[0] if rig && rig.weaponSlot else null
	ModConfig.current_weapon_weight = weapon.Weight() if weapon else 0.0
	Out.debug("weapon weight: %.1fkg" % ModConfig.current_weapon_weight)

	# save laser module reference
	_laser = null
	for node in (rig.attachments.get_children() if rig else []):
		if node.visible && node.has_method("PlayLaser"):
			_laser = node

	# Vanilla forgets to reset secondaryOptic flag when equipping another optic
	# Causes other scopes to break in PIP mode
	var optic = rig.activeOptic if rig else null
	if gameData.secondaryOptic && !(optic && optic.secondary):
		gameData.secondaryOptic = false
		Out.bugfix("reset gameData.secondaryOptic flag")

	# fold/unfold iron sights based on optic presence
	var data = rig.data if rig else null
	if data && data.foldSights:
		var rot = Quaternion.from_euler(Vector3(data.foldSightsRotation if optic else 0.0, 0, 0))
		rig.skeleton.set_bone_pose_rotation(rig.backSightIndex, rot)
		if rig.frontSightIndex:
			rig.skeleton.set_bone_pose_rotation(rig.frontSightIndex, rot)
		else:
			Out.bugfix("do not attempt to rotate front sight on M4A1 (flicker)")

	# true up cocked state if mag was loaded from inventory
	if rig && rig.slotData:
		rig.slotData.set_meta("cocked", rig.slotData.chamber)
		


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


func _laser_activate(h) -> void:
	if ModConfig.laser_latch || !_laser || _laser.active:
		return
	_laser.active = true
	#_laser.raycast.global_position = _laser.owner.raycast.global_position
	_laser.laser.show()
	_play_laser_sound(_laser, _LASER_IN_START, _LASER_IN_DURATION)
	ModConfig.laser_latch = true


func _laser_deactivate(h) -> void:
	if !ModConfig.laser_latch:
		return
	ModConfig.laser_latch = false
	if !_laser || !_laser.active:
		return
	_laser.active = false
	_laser.laser.hide()
	_play_laser_sound(_laser, _LASER_OUT_START, _LASER_OUT_DURATION)


func _play_laser_sound(node, start: float, duration: float) -> void:
	if !_flashlight_stream:
		return
	var audio = node.audioInstance2D.instantiate()
	node.add_child(audio)
	audio.stream = _flashlight_stream
	audio.volume_db = _LASER_SOUND_VOLUME_DB
	audio.play(start)
	if duration > 0.0:
		await node.get_tree().create_timer(duration, false).timeout
		if is_instance_valid(audio):
			audio.stop()
