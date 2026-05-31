extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")
var gameData = preload("res://Resources/GameData.tres")

enum IdleCategory { Default, Pistol, NoGrip, SMG }

var _idle_offsets := {
	IdleCategory.Default: {
		"pos": Vector3(0, -0.04, 0.02),
		"rot": Vector3(10, 25, 10),
	},
	IdleCategory.SMG: {
		"pos": Vector3(0, -0.06, 0.04),
		"rot": Vector3(15, 20, 10),
	},
	IdleCategory.Pistol: {
		"pos": Vector3(-0.07, -0.06, 0),
		"rot": Vector3(15, 10, 0),
	},
	IdleCategory.NoGrip: {
		"pos": Vector3(0, -0.06, 0.05),
		"rot": Vector3(-5, 40, 10),
	},
}
var _current_idle_category: int = IdleCategory.Default
const _SECONDARY_OPTIC_ROT_OFFSET := Vector3(-15.0, 0.0, 0)
const _BODY_OFFSET := 0.22
const _LOP_SHORT_THRESHOLD := 0.15
var _rear_z_cache := {}
var _trigger_z_cache := {}
const _ANCHOR_PITCH := -10.0
const _LOOK_DOWN_PITCH := -45.0
const _LOOK_DOWN_POS := Vector3(0.2, -0.28, -0.25)
const _LOOK_DOWN_ROT := Vector3(45, -0.5, 10)


# the handling speed modifier - read as % of base
enum HandlingMode {
	Default = 100,
	RDS = 115,
	Cant = 130,
	ScopeZoom = 80
}


var _lib
var _preferences: Preferences
var _handlingMode = HandlingMode.Default
var _aim_intent := false
var _cant_intent := false
var _free_look := true
var _anchored := false
var _manager_local_baseline: Transform3D
var _baseline_captured := false
var _handling_speed: float = 7.5
var _camera_pitch_deg: float = 0.0
var _anchor_pitch: float = 0.0
var _smoothed_pitch: float = 0.0


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_input(evt) -> void:
	_lib.skip_super()

	#_debug_adjust_target(evt)

	var aimToggle = gameData.aimMode == 2
	var cantToggle = false
	if ModConfig.cant_mode == &"default":
		cantToggle = aimToggle
	elif ModConfig.cant_mode == &"toggle":
		cantToggle = true

	if !gameData.freeze && evt.is_action_pressed("aim"):
		_aim_intent = !_aim_intent if aimToggle else true
		_resolve_intent(true)
	elif !gameData.freeze && evt.is_action_pressed("canted"):
		_cant_intent = !_cant_intent if cantToggle else true
		_resolve_intent(false)
	elif evt.is_action_released("aim") && !aimToggle:
		_aim_intent = false
		_resolve_intent(true)
	elif evt.is_action_released("canted") && !cantToggle:
		_cant_intent = false
		_resolve_intent(false)


func _debug_adjust_target(evt) -> void:

	if !(evt is InputEventKey) || !evt.pressed || evt.echo:
		return

	var axis_idx = -1
	match evt.keycode:
		KEY_F7: axis_idx = 0
		KEY_F8: axis_idx = 1
		KEY_F9: axis_idx = 2
		_: return

	var entry = _idle_offsets[_current_idle_category]
	if evt.ctrl_pressed:
		var step = -5.0 if evt.shift_pressed else 5.0
		entry["rot"][axis_idx] += step
	else:
		var step = -0.01 if evt.shift_pressed else 0.01
		entry["pos"][axis_idx] += step

	Out.debug("[%s] pos:" % IdleCategory.keys()[_current_idle_category], entry["pos"], "rot:", entry["rot"])


func _resolve_intent(aim_changed: bool) -> void:
	if aim_changed:
		gameData.isAiming = _aim_intent
		gameData.isCanted = false if _aim_intent else _cant_intent
	else:
		gameData.isCanted = _cant_intent
		gameData.isAiming = false if _cant_intent else _aim_intent


func on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if !h:
		return
	_lib.skip_super()

	if gameData.freeze:
		return

	gameData.isColliding = h.collision.is_colliding()

	_handlingMode = HandlingMode.Default
	_free_look = false
	_anchored = false
	_process_handling_state(h)
	_apply_target(h, delta)
	#Out.debug("pos:", h.targetPosition, "rot:", h.targetRotation)


func _process_handling_state(h) -> void:
	var data = h.data
	var rig = h.get_parent()

	if gameData.isClearing || gameData.isColliding:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if gameData.isInspecting:
		gameData.weaponPosition = 1
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return

	if gameData.isInserting:
		gameData.weaponPosition = 1
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if (gameData.isChecking && ModConfig.ammo_check_view) || (gameData.isReloading && data.weaponAction != "Manual"):
		h.targetPosition = data.lowPosition + (Vector3.ZERO if gameData.isReloading else Vector3(0, 0.05, 0))
		h.targetRotation = data.lowRotation + Vector3(-20, 0, 0)
		return

	if gameData.isPlacing:
		gameData.weaponPosition = 1
		_set_target_idle(h)
		return

	if gameData.isRunning:
		_set_target_idle(h)
		return

	if gameData.isColliding:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if gameData.isCanted:
		_handlingMode = HandlingMode.Cant
		var optic = rig.activeOptic
		h.targetPosition = data.cantedPosition + Vector3(0.0, -0.03, 0.0)
		if optic && (optic.attachmentData.variable || optic.attachmentData.scope):
			h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, -20.0)
		else:
			h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, 10.0)
		return

	if gameData.isAiming:
		var optic = rig.activeOptic
		if optic && optic.attachmentData.scope && !gameData.secondaryOptic:
			_handlingMode = HandlingMode.ScopeZoom
		elif optic && optic.attachmentData.variable && ModConfig.current_scope_mag >= 1.5:
			_handlingMode = HandlingMode.ScopeZoom
		elif optic:
			_handlingMode = HandlingMode.RDS

		var aim_z = data.aimPosition.z - 0.1 # vanilla logic
		if optic && gameData.isScoped && gameData.PIP:
			aim_z = rig.get_meta("eyeAnchorZ", data.aimPosition.z)

		h.targetPosition = Vector3(0.0, -rig.aimOffset, aim_z) if optic else data.aimPosition
		h.targetRotation = data.aimRotation
		return

	if gameData.weaponPosition == 2:
		h.targetPosition = data.highPosition
		h.targetRotation = data.highRotation
		return

	_set_target_idle(h)


func _set_target_idle(h) -> void:
	var data = h.data

	if data.type != "Weapon" || !ModConfig.enable_free_look:
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if _camera_pitch_deg < _LOOK_DOWN_PITCH:
		h.targetPosition = _LOOK_DOWN_POS
		h.targetRotation = _LOOK_DOWN_ROT
		return

	_free_look = _camera_pitch_deg >= _ANCHOR_PITCH
	_anchored = !_free_look

	if data.weaponType == "Pistol":
		_current_idle_category = IdleCategory.Pistol
	elif data.weaponType == "SMG":
		_current_idle_category = IdleCategory.SMG
	elif data.file == "Mosin" || data.file == "Remington_870":
		_current_idle_category = IdleCategory.NoGrip
	else:
		_current_idle_category = IdleCategory.Default

	var entry = _idle_offsets[_current_idle_category]
	var pos_offset: Vector3 = entry["pos"]
	var rot_offset: Vector3 = entry["rot"]
	if gameData.secondaryOptic:
		rot_offset += _SECONDARY_OPTIC_ROT_OFFSET

	h.targetPosition = data.lowPosition + pos_offset
	h.targetRotation = data.lowRotation + rot_offset


func _apply_target(h, delta: float):
	_handling_speed = h.handlingSpeed * (_handlingMode / 100.0)
	var t := delta * _handling_speed

	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), t)
	h.rotation_degrees = lerp(h.rotation_degrees, h.targetRotation, t)

	if !_baseline_captured || !ModConfig.enable_free_look:
		return

	var rig = h.get_parent()
	var manager = rig.get_parent() if rig else null
	var outer_cam = manager.get_parent() if manager else null
	if !outer_cam:
		return

	var cam_xform: Transform3D = outer_cam.global_transform
	var cam_euler := cam_xform.basis.get_euler()
	_camera_pitch_deg = rad_to_deg(cam_euler.x)

	if _camera_pitch_deg >= _ANCHOR_PITCH:
		_anchor_pitch = cam_euler.x

	var target_pitch: float
	if _free_look:
		target_pitch = 0.0
	elif _anchored:
		target_pitch = cam_euler.x - _anchor_pitch
	else:
		target_pitch = cam_euler.x

	_smoothed_pitch = lerp(_smoothed_pitch, target_pitch, t)

	var weapon_basis := Basis.from_euler(Vector3(_smoothed_pitch, cam_euler.y, cam_euler.z))
	manager.global_transform = Transform3D(weapon_basis, cam_xform.origin) * _manager_local_baseline


func on_rig_update_post(_animate) -> void:
	var manager = _lib._caller
	if manager == null:
		return

	if !_baseline_captured:
		_manager_local_baseline = manager.transform
		_baseline_captured = true
	elif ModConfig.enable_free_look:
		manager.transform = _manager_local_baseline

	var rig = manager.get_child(manager.get_child_count() - 1) if manager.get_child_count() else null

	# save weapon weight for the handling speed calc
	var weapon = rig.weaponSlot.get_children()[0] if rig && rig.weaponSlot else null
	ModConfig.current_weapon_weight = weapon.Weight() if weapon else 0.0
	Out.debug("weapon weight: %.1fkg" % ModConfig.current_weapon_weight)

	# Vanilla forgets to reset secondaryOptic flag when equipping another optic
	# Causes other scopes to break in PIP mode
	var optic = rig.activeOptic if rig else null
	if gameData.secondaryOptic && !(optic && optic.secondary):
		gameData.secondaryOptic = false
		Out.bugfix("reset gameData.secondaryOptic flag")

	if rig && rig.data:
		var eye_z := _eye_anchor_z(rig, rig.data)
		rig.set_meta("eyeAnchorZ", eye_z)

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


func _eye_anchor_z(rig, data) -> float:
	if data.weaponType == "Pistol":
		return data.aimPosition.z

	var rear_z := _buttstock_rear_z(rig)
	if is_nan(rear_z):
		return data.aimPosition.z

	var trigger_z := _trigger_z(rig)
	if is_nan(trigger_z):
		return data.aimPosition.z

	var lop: float = trigger_z - rear_z
	Out.debug("gun geometry [%s] rear_z: %.3f trigger_z: %.3f lop: %.3f" % [String(data.file), rear_z, trigger_z, lop])

	if lop < _LOP_SHORT_THRESHOLD:
		return data.aimPosition.z

	return rear_z + _BODY_OFFSET


func _buttstock_rear_z(rig) -> float:
	var key := String(rig.data.file)
	if _rear_z_cache.has(key):
		return _rear_z_cache[key]

	var body = _find_body_mesh(rig)
	if !body:
		Out.warning("could not find body mesh for", key)
		return NAN

	var aabb: AABB = body.get_aabb()
	var rear_z: float = (body.transform * Vector3(0.0, 0.0, aabb.position.z)).z
	_rear_z_cache[key] = rear_z
	return rear_z


func _trigger_z(rig) -> float:
	var key := String(rig.data.file)
	if _trigger_z_cache.has(key):
		return _trigger_z_cache[key]

	var skeleton = rig.skeleton
	if !skeleton:
		Out.warning("no skeleton for", key)
		return NAN

	for i in skeleton.get_bone_count():
		if String(skeleton.get_bone_name(i)).ends_with("_Trigger"):
			var trigger_z: float = skeleton.get_bone_global_rest(i).origin.z
			_trigger_z_cache[key] = trigger_z
			return trigger_z

	Out.warning("could not find trigger bone for", key)
	return NAN


func _find_body_mesh(rig):
	if !rig.skeleton:
		return null
	for child in rig.skeleton.get_children():
		if child is MeshInstance3D && String(child.name).ends_with("Body"):
			return child
	return null
