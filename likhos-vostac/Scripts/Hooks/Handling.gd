extends RefCounted

const ScopeCatalog := preload("../ScopeCatalog.gd")
const RigOpticPatches := preload("../RigOpticPatches.gd")
const Out := preload("../../Lib/Out.gd")
const InputBus := preload("../Nodes/InputBus.gd")
var config := preload("../Config.gd").instance
var gameData = preload("res://Resources/GameData.tres")

enum IdleCategory { Default, Pistol, FuddGrip, SMG, StocklessSMG }

var _idle_offsets := {
	IdleCategory.Default: {
		"pos": Vector3(0, 0, 0.02),
		"rot": Vector3(10, 35, -20),
	},
	IdleCategory.SMG: {
		"pos": Vector3(0, 0, 0.04),
		"rot": Vector3(0, 45, 0),
	},
	IdleCategory.Pistol: {
		"pos": Vector3(0.1, -0.06, 0.1),
		"rot": Vector3(-65, -10, 0),
		"hide_left_arm": true,
	},
	IdleCategory.StocklessSMG: {
		"pos": Vector3(0.1, -0.16, 0.1),
		"rot": Vector3(-65, -10, 0),
		"hide_left_arm": true,
	},
	IdleCategory.FuddGrip: {
		"pos": Vector3(0, 0, 0.05),
		"rot": Vector3(-5, 40, 10),
	},
}

const _SECONDARY_OPTIC_ROT_OFFSET := Vector3(-15.0, 0.0, 0)
const _DETACH_PITCH := deg_to_rad(-10.0)
const _LOOK_DOWN_PITCH := deg_to_rad(-45.0)
const _STOW_POS_OFFSET := Vector3(0.15, -0.25, 0.3)
const _STOW_HOLD_LOOK_DOWN := 0.2
const _LEFT_ARM_BONE := "Arm_Upper_L"
const _NEAR_ZERO := Vector3(0.001, 0.001, 0.001)
# longest stock rig measures ~1.22m, plus ~0.2m for a muzzle device; anything past this means the measurement went wrong
const _MAX_PROBE_LENGTH := 2.0

# the handling speed modifier - read as % of base
enum HandlingMode {
	Aim = 100,
	RDS = 115,
	Cant = 130,
	Zoom = 80,
	Default = 50,
}

# the weight factor is the line through (light, light mult) and (base, 1.0), capped at light mult and floored at heavy mult
const _SPEED_WEIGHT_BASE := 5.0
const _SPEED_WEIGHT_LIGHT := 3.0
const _SPEED_WEIGHT_LIGHT_MULT := 1.6
const _SPEED_WEIGHT_HEAVY_MULT := 0.4

var _lib
var _bus: InputBus
var _handlingMode := HandlingMode.Default
var _target_idle := false
var _manager_local_baseline: Transform3D
var _baseline_captured := false
var _pitch_offset: float = 0.0
var _stow_hold: float = 0.0
var _stow_rot: Vector3
var _idle_hide_left_arm := false


func _init(lib, bus: InputBus) -> void:
	_lib = lib
	_bus = bus
	_stow_rot = _stow_rotation()


# a basic rotation vector wont work here bacause at steep pitch - Y rotation stops working
func _stow_rotation() -> Vector3:
	var pitch := Basis.from_euler(Vector3(deg_to_rad(80.0), 0.0, deg_to_rad(10.0)))
	var kick := Basis(Vector3.FORWARD, deg_to_rad(20.0))
	var e := (kick * pitch).get_euler()
	return Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z))


func on_rig_update_post(_animate: bool) -> void:
	var manager: Node3D = _lib._caller
	if !manager:
		return

	if !_baseline_captured:
		_manager_local_baseline = manager.transform
		_baseline_captured = true
	elif config.free_look:
		manager.transform = _manager_local_baseline

	var rig = manager.get_child(manager.get_child_count() - 1) if manager.get_child_count() else null
	var optic = rig.activeOptic if rig else null
	var data = rig.data if rig else null

	# save weapon weight for the handling speed calc, and the action for the reload lock
	var weapon = rig.weaponSlot.get_children()[0] if rig && rig.weaponSlot else null
	config.current_weapon_weight = weapon.Weight() if weapon else 0.0
	config.current_weapon_action = data.weaponAction if data else ""
	Out.debug("weapon weight: %.1fkg" % config.current_weapon_weight)

	# knife, grenade and fishing rigs come through as null and reset the optic state
	RigOpticPatches.clamp_rail_position(rig as WeaponRig)
	ScopeCatalog.sync_optic_state(rig as WeaponRig)

	# fold/unfold iron sights based on optic presence
	# BUGFIX - vanilla doens't check frontSightIndex, which casues flicker on M4A1, which doens't have foldable front sight
	if data && data.foldSights:
		var rot = Quaternion.from_euler(Vector3(data.foldSightsRotation if optic else 0.0, 0, 0))
		rig.skeleton.set_bone_pose_rotation(rig.backSightIndex, rot)
		if rig.frontSightIndex:
			rig.skeleton.set_bone_pose_rotation(rig.frontSightIndex, rot)

	# BUGFIX - vanilla sizes the collision probe from a coarse authored bucket, so short weapons deflect off walls they are nowhere near and the longest rifles clip walls they should have deflected from
	if rig is not WeaponRig || !rig.collision || !rig.muzzle:
		return

	var handling: Node3D = rig.get_node_or_null("Handling")
	if !handling:
		Out.warning("no Handling node on the %s rig - collision probe left at its authored length" % data.file)
		return

	# Handling-local space shares the probe's origin and axis but excludes the pose, and highPosition is the most forward firing pose, so the probe covers aim and canted too
	var muzzle_offset: float = handling.to_local(rig.muzzle.global_position).z
	var reach: float = -data.highPosition.z + muzzle_offset

	if reach <= 0.0 || reach > _MAX_PROBE_LENGTH:
		Out.warning("collision probe reach %.2fm out of range on the %s rig - left at its authored length" % [reach, data.file])
		return

	rig.collision.target_position.z = reach


# vanilla ClearRig resets isAiming but not isCanted, which would stay set with no rig left to resolve it
func on_clear_rig_post() -> void:
	gameData.isCanted = false
	_bus.withdraw_weapon()


# only overrides the tiers vanilla mis-gates; the clean case falls through to vanilla's weapon_high/low handling
func on_weapon_position() -> void:
	if config.gated():
		_lib.skip_super()
		return

	if config.locked():
		gameData.weaponPosition = 1
		_lib.skip_super()
		return

	if gameData.isCanted || config.binoculars_active || gameData.isRunning || gameData.isColliding:
		_lib.skip_super()
		return


func on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if !h:
		return
	_lib.skip_super()

	if config.gated():
		return

	gameData.isColliding = h.collision.is_colliding()
	_resolve_aim_intent()
	_handlingMode = HandlingMode.Default
	_target_idle = false
	
	_set_target(h)
	_apply_target(h, delta)
	_apply_left_arm(h)


func _resolve_aim_intent() -> void:
	# the bus already accounts for locks and for binoculars taking over the arms
	# airborne and colliding only suspend the aim here, so the bus keeps a held or latched aim and it comes back on landing or once the weapon clears
	gameData.isAiming = _bus.aim() && !gameData.isFalling && !gameData.isColliding
	gameData.isCanted = _bus.canted()


func _set_target(h: Node) -> void:
	var data = h.data
	var rig = h.get_parent()
	var optic = rig.activeOptic

	if gameData.isClearing:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if gameData.isInspecting:
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return

	if gameData.isInserting:
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if gameData.isChecking || (gameData.isReloading && data.weaponAction != "Manual"):
		h.targetPosition = data.highPosition
		h.targetRotation = data.highRotation
		return

	if gameData.isPlacing:
		_set_target_idle(h)
		return

	if gameData.isRunning:
		_set_target_idle(h)
		return

	# binos has no weapon pose of its own; stow the rig out of the camera while glassing
	if config.binoculars_active:
		h.targetPosition = data.lowPosition + _STOW_POS_OFFSET
		h.targetRotation = _stow_rot
		return

	# below the admin poses so their animations play out; patrol/stow instead of data.collisionPosition clears the wall and keeps free-look pitch from re-aiming the collision ray
	if gameData.isColliding:
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
		if optic && config.current_scope_mag > 1.5:
			_handlingMode = HandlingMode.Zoom
		elif optic:
			_handlingMode = HandlingMode.RDS
		else:
			_handlingMode = HandlingMode.Aim

		if !optic:
			h.targetPosition = data.aimPosition
		else:
			h.targetPosition = ScopeCatalog.get_aim_position(rig)

		h.targetRotation = data.aimRotation
		return

	if gameData.weaponPosition == 2:
		h.targetPosition = data.highPosition
		h.targetRotation = data.highRotation
		return

	_set_target_idle(h)


func _set_target_idle(h: Node) -> void:
	var data = h.data
	_target_idle = true
	_idle_hide_left_arm = false

	if data.type != "Weapon":
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if config.free_look && _stow_hold > 0.0:
		h.targetPosition = data.lowPosition + _STOW_POS_OFFSET
		h.targetRotation = _stow_rot
		return

	if !config.patrol_position:
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	var category := IdleCategory.Default
	if data.file == "MP5K" || data.file == "MP7":
		category = IdleCategory.StocklessSMG
	elif data.weaponType == "Pistol":
		category = IdleCategory.Pistol
	elif data.file in ["Mosin", "M28", "M28_MOD", "Remington_870"]:
		category = IdleCategory.FuddGrip
	elif data.weaponType == "SMG":
		category = IdleCategory.SMG

	var entry: Dictionary = _idle_offsets[category]
	_idle_hide_left_arm = entry.get("hide_left_arm", false)

	h.targetPosition = data.lowPosition + entry["pos"]
	h.targetRotation = data.lowRotation + entry["rot"] + (_SECONDARY_OPTIC_ROT_OFFSET if gameData.secondaryOptic else Vector3.ZERO)


func _apply_target(h: Node, delta: float) -> void:
	var rate: float = h.handlingSpeed * (_handlingMode / 100.0)

	# a weight of 0 means no weapon is resolved, the cap would give it the light mult
	if config.current_weapon_weight > 0.0:
		rate *= clampf(remap(config.current_weapon_weight, _SPEED_WEIGHT_LIGHT, _SPEED_WEIGHT_BASE, _SPEED_WEIGHT_LIGHT_MULT, 1.0), _SPEED_WEIGHT_HEAVY_MULT, _SPEED_WEIGHT_LIGHT_MULT)

	config.current_handling_rate = rate
	var t: float = delta * rate

	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), t)
	var target_quat := Quaternion.from_euler(Vector3(deg_to_rad(h.targetRotation.x), deg_to_rad(h.targetRotation.y), deg_to_rad(h.targetRotation.z)))
	h.quaternion = h.quaternion.slerp(target_quat, t)

	if !_baseline_captured || !config.free_look:
		return

	var rig: Node3D = h.get_parent()
	var manager: Node3D = rig.get_parent() if rig else null
	var outer_cam: Node3D = manager.get_parent() if manager else null
	if !outer_cam:
		return

	var cam_xform: Transform3D = outer_cam.global_transform
	var cam_euler := cam_xform.basis.get_euler()

	if cam_euler.x < _LOOK_DOWN_PITCH:
		_stow_hold = _STOW_HOLD_LOOK_DOWN
	elif _stow_hold > 0.0:
		_stow_hold -= delta

	var offset_target: float
	if !_target_idle:
		offset_target = 0.0
	elif _stow_hold > 0.0:
		offset_target = cam_euler.x
	else:
		# above the detach pitch the weapon holds at it in world space, below it the weapon follows the camera in its idle pose
		offset_target = maxf(cam_euler.x - _DETACH_PITCH, 0.0)

	_pitch_offset = lerp(_pitch_offset, offset_target, t)

	var weapon_basis := Basis.from_euler(Vector3(cam_euler.x - _pitch_offset, cam_euler.y, cam_euler.z))
	manager.global_transform = Transform3D(weapon_basis, cam_xform.origin) * _manager_local_baseline


func _apply_left_arm(h: Node) -> void:
	var rig = h.get_parent()
	if !rig || !rig.skeleton:
		return

	var arm_idx: int = rig.skeleton.find_bone(_LEFT_ARM_BONE)
	if arm_idx == -1:
		return

	# collapse the left support arm while stowed (hacky: zero-scale the shoulder bone)
	if _target_idle && (_stow_hold > 0.0 || _idle_hide_left_arm):
		rig.skeleton.set_bone_pose_scale(arm_idx, _NEAR_ZERO)
	else:
		rig.skeleton.set_bone_pose_scale(arm_idx, Vector3.ONE)
