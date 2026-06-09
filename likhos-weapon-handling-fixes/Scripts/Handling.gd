extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const ScopeCatalog = preload("./ScopeCatalog.gd")
const Out = preload("../Lib/Out.gd")
var gameData = preload("res://Resources/GameData.tres")

enum IdleCategory { Default, Pistol, NoGrip, SMG }

var _idle_offsets := {
	IdleCategory.Default: {
		"pos": Vector3(0, -0.04, 0.02),
		"rot": Vector3(10, 35, -20),
	},
	IdleCategory.SMG: {
		"pos": Vector3(0, -0.06, 0.04),
		"rot": Vector3(0, 45, -20),
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
const _ANCHOR_PITCH := -10.0
const _LOOK_DOWN_PITCH := -45.0
const _STOW_POS_OFFSET := Vector3(0.15, -0.25, 0.3)
const _STOW_HOLD := 1.0
const _LEFT_ARM_BONE := "Arm_Upper_L"
const _STOW_ARM_SCALE := Vector3(0.001, 0.001, 0.001)

# the handling speed modifier - read as % of base
enum HandlingMode {
	Default = 100,
	RDS = 115,
	Cant = 130,
	ScopeZoom = 80,
	Admin = 50,
}

const _AIM_POS_OVERRIDE := {
	"SVD": -0.08,
	"M78": -0.09,
	"AKM": -0.07,
	"AK_12": -0.04,
	"AKS_74U": -0.1,
	"VSS": -0.08,
	"MP5SD": -0.1,
	"MP5K": -0.1,
	"MP5": -0.1,
	"RK_95": -0.06,
	"RK_62": -0.06,
	"RK_62M": -0.06,
	"M4A1": -0.07,
	"MK18": -0.06,
	"HK416": -0.06,
	"KAR_21_223": -0.12,
	"KAR_21_308": -0.12,
	"MP7": -0.16,
	"Mosin": -0.22,
}


var _lib
var _preferences: Preferences
var _handlingMode = HandlingMode.Default
var _aim_intent := false
var _cant_intent := false
var _aim_priority := true
var _free_look := true
var _anchored := false
var _manager_local_baseline: Transform3D
var _baseline_captured := false
var _handling_speed: float = 7.5
var _camera_pitch_deg: float = 0.0
var _anchor_pitch: float = 0.0
var _smoothed_pitch: float = 0.0
var _stow_hold: float = 0.0
var _stow_active := false
var _stow_rot: Vector3


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences
	_stow_rot = _stow_rotation()


func on_input(evt: InputEvent) -> void:
	_lib.skip_super()

	if gameData.freeze:
		return

	var aimToggle: bool = gameData.aimMode == 2
	var cantToggle := false
	if ModConfig.cant_mode == &"default":
		cantToggle = aimToggle
	elif ModConfig.cant_mode == &"toggle":
		cantToggle = true

	if evt.is_action_pressed("aim"):
		_aim_intent = !_aim_intent if aimToggle else true
		_aim_priority = true
	elif evt.is_action_pressed("canted"):
		_cant_intent = !_cant_intent if cantToggle else true
		_aim_priority = false
	elif !aimToggle && evt.is_action_released("aim"):
		_aim_intent = false
	elif !cantToggle && evt.is_action_released("canted"):
		_cant_intent = false


func on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if !h:
		return
	_lib.skip_super()

	gameData.isColliding = h.collision.is_colliding()
	_resolve_intent()
	_free_look = false
	_anchored = false
	_stow_active = false

	if gameData.freeze:
		_stow_hold = _STOW_HOLD
		_set_target_idle(h)
		_apply_target(h, delta)
		_apply_left_arm(h)
		return

	if gameData.isAiming || gameData.isCanted:
		_stow_hold = 0.0
	elif _camera_pitch_deg < _LOOK_DOWN_PITCH:
		_stow_hold = _STOW_HOLD
	else:
		_stow_hold = max(0.0, _stow_hold - delta)

	_process_handling_state(h)
	_apply_target(h, delta)
	_apply_left_arm(h)


func _apply_left_arm(h) -> void:
	var rig = h.get_parent()
	if !rig || !rig.skeleton:
		return

	var arm_idx = rig.skeleton.find_bone(_LEFT_ARM_BONE)
	if arm_idx == -1:
		return

	# collapse the left support arm while stowed (hacky: zero-scale the shoulder bone)
	if _stow_active:
		rig.skeleton.set_bone_pose_scale(arm_idx, _STOW_ARM_SCALE)
	else:
		rig.skeleton.set_bone_pose_scale(arm_idx, Vector3.ONE)


func _resolve_intent() -> void:

	if gameData.isInspecting || gameData.isChecking || ModConfig.binoculars_active:
		gameData.isAiming = false
		gameData.isCanted = false
		return

	if !_aim_priority:
		gameData.isCanted = _cant_intent
		gameData.isAiming = false if _cant_intent else _aim_intent
	elif ModConfig.optic_shiner:
		_aim_intent = false
		gameData.isAiming = false
		ModConfig.optic_shiner = false
	else:
		gameData.isAiming = _aim_intent
		gameData.isCanted = false if _aim_intent else _cant_intent


func _process_handling_state(h) -> void:
	var data = h.data
	var rig = h.get_parent()
	var optic = rig.activeOptic

	if gameData.isClearing || gameData.isColliding:
		_handlingMode = HandlingMode.Default
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if gameData.isInspecting:
		_handlingMode = HandlingMode.Admin
		gameData.weaponPosition = 1
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return

	if gameData.isInserting:
		_handlingMode = HandlingMode.Admin
		gameData.weaponPosition = 1
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if (gameData.isChecking && ModConfig.ammo_check_view) || (gameData.isReloading && data.weaponAction != "Manual"):
		_handlingMode = HandlingMode.Admin
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

	if gameData.isCanted:
		_handlingMode = HandlingMode.Cant
		h.targetPosition = data.cantedPosition + Vector3(0.0, -0.03, 0.0)
		if optic && (optic.attachmentData.variable || optic.attachmentData.scope):
			h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, -20.0)
		else:
			h.targetRotation = data.cantedRotation + Vector3(0.0, 0.0, 10.0)
		return

	if gameData.isAiming:
		if optic && ModConfig.current_scope_mag > 1.5:
			_handlingMode = HandlingMode.ScopeZoom
		elif optic:
			_handlingMode = HandlingMode.RDS
		else:
			_handlingMode = HandlingMode.Default

		if !optic:
			h.targetPosition = data.aimPosition
		elif gameData.PIP && gameData.isScoped:
			h.targetPosition = Vector3(0.0, -rig.aimOffset, _AIM_POS_OVERRIDE.get(data.file, data.aimPosition.z * 0.67))
		else:
			h.targetPosition = Vector3(0.0, -rig.aimOffset, data.aimPosition.z)

		h.targetRotation = data.aimRotation
		return

	if gameData.weaponPosition == 2:
		_handlingMode = HandlingMode.Default
		h.targetPosition = data.highPosition
		h.targetRotation = data.highRotation
		return

	_set_target_idle(h)


func _set_target_idle(h) -> void:
	var data = h.data

	_free_look = _camera_pitch_deg >= _ANCHOR_PITCH
	_anchored = !_free_look

	if data.type != "Weapon" || !ModConfig.enable_free_look:
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if _stow_hold > 0.0:
		_free_look = true
		_anchored = false
		_stow_active = true
		_handlingMode = HandlingMode.Admin
		h.targetPosition = data.lowPosition + _STOW_POS_OFFSET
		h.targetRotation = _stow_rot
		return

	if _anchored:
		_handlingMode = HandlingMode.Admin

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


# a basic rotation vector wont work here bacause at steep pitch - Y rotation stops working
func _stow_rotation() -> Vector3:
	var pitch := Basis.from_euler(Vector3(deg_to_rad(80.0), 0.0, deg_to_rad(10.0)))
	var kick := Basis(Vector3.FORWARD, deg_to_rad(20.0))
	var e := (kick * pitch).get_euler()
	return Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z))


func _apply_target(h, delta: float) -> void:
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
	if !manager:
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

	# BUGFIX
	# Vanilla forgets to reset secondaryOptic flag when equipping another optic
	# Causes other scopes to break in PIP mode
	var optic = rig.activeOptic if rig else null
	if gameData.secondaryOptic && !(optic && optic.secondary):
		gameData.secondaryOptic = false

	gameData.isScoped = ScopeCatalog.is_magnified(optic) && !gameData.secondaryOptic

	# fold/unfold iron sights based on optic presence
	# BUGFIX - vanilla doens't check frontSightIndex, which casues flicker on M4A1, which doens't have foldable front sight
	var data = rig.data if rig else null
	if data && data.foldSights:
		var rot = Quaternion.from_euler(Vector3(data.foldSightsRotation if optic else 0.0, 0, 0))
		rig.skeleton.set_bone_pose_rotation(rig.backSightIndex, rot)
		if rig.frontSightIndex: 
			rig.skeleton.set_bone_pose_rotation(rig.frontSightIndex, rot)

	# true up cocked state if mag was loaded from inventory
	if rig && rig.slotData:
		rig.slotData.set_meta("cocked", rig.slotData.chamber)
