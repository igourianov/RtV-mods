extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const ScopeCatalog = preload("./ScopeCatalog.gd")
const Out = preload("../Lib/Out.gd")
var gameData = preload("res://Resources/GameData.tres")

var _IDLE_POSITION_OFFSET = Vector3(0, 0, 0.03)
var _IDLE_ROTATION_OFFSET = Vector3(0, 10, 20)
const _SECONDARY_OPTIC_LOW_ROTATION_OFFSET = Vector3(-20.0, 0.0, -10.0)
const _LOOK_DOWN_THRESHOLD_DEG: float = -30.0


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
var _free_look_blend: float = 1.0
var _manager_local_baseline: Transform3D
var _baseline_captured := false
var _handling_speed: float = 7.5
var _camera_pitch_deg: float = 0.0


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_input(evt) -> void:
	_lib.skip_super()

	_debug_adjust_target(evt)

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

	if evt.ctrl_pressed:
		var step = -5.0 if evt.shift_pressed else 5.0
		_IDLE_ROTATION_OFFSET[axis_idx] += step
	else:
		var step = -0.01 if evt.shift_pressed else 0.01
		_IDLE_POSITION_OFFSET[axis_idx] += step

	Out.debug("_IDLE_POSITION_OFFSET:", _IDLE_POSITION_OFFSET, "_IDLE_ROTATION_OFFSET:", _IDLE_ROTATION_OFFSET)


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
	_process_handling_state(h)
	_apply_target(h, delta)


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

	if gameData.isChecking && ModConfig.ammo_check_view:
		h.targetPosition = data.highPosition
		h.targetRotation = data.highRotation
		return

	if gameData.isReloading && data.weaponAction != "Manual":
		h.targetPosition = data.lowPosition
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
			aim_z = rig.get_meta("opticAimZ", 0.0)

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

	_free_look = ModConfig.enable_free_look && data.type == "Weapon" && _camera_pitch_deg >= _LOOK_DOWN_THRESHOLD_DEG

	if !_free_look:
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	var pos_offset = _IDLE_POSITION_OFFSET
	var rot_offset = _IDLE_ROTATION_OFFSET
	if gameData.secondaryOptic:
		rot_offset += _SECONDARY_OPTIC_LOW_ROTATION_OFFSET

	h.targetPosition = data.collisionPosition + pos_offset
	h.targetRotation = data.collisionRotation + rot_offset


func _apply_target(h, delta: float):
	_handling_speed = h.handlingSpeed * (_handlingMode / 100.0)
	var t := delta * _handling_speed

	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), t)
	h.rotation_degrees = lerp(h.rotation_degrees, h.targetRotation, t)

	if !_baseline_captured:
		return

	var rig = h.get_parent()
	var manager = rig.get_parent() if rig else null
	var outer_cam = manager.get_parent() if manager else null
	if !outer_cam:
		return

	_camera_pitch_deg = rad_to_deg(outer_cam.global_transform.basis.get_euler().x)
	_free_look_blend = lerp(_free_look_blend, 0.0 if _free_look else 1.0, t)

	var cam_xform: Transform3D = outer_cam.global_transform
	var euler = cam_xform.basis.get_euler()
	euler.x = 0.0
	var body_xform := Transform3D(Basis.from_euler(euler), cam_xform.origin)

	manager.global_transform = body_xform.interpolate_with(cam_xform, _free_look_blend) * _manager_local_baseline


func on_rig_update_post(_animate) -> void:
	var manager = _lib._caller
	if manager == null:
		return

	if !_baseline_captured:
		_manager_local_baseline = manager.transform
		_baseline_captured = true
	else:
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

	if rig:
		ScopeCatalog.update_optic_cache(rig, optic)

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
