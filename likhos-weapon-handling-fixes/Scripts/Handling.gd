extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const ScopeCatalog = preload("./ScopeCatalog.gd")
const Out = preload("../Lib/Out.gd")
var gameData = preload("res://Resources/GameData.tres")

const _PATROL_POSITION = Vector3(0.06, -0.18, -0.25)
const _PATROL_ROTATION = Vector3(25, 50, -20)
const _PATROL_WEAPON_TYPES = {"Rifle": null, "SMG": null, "Bolt": null, "Shotgun": null}
const _SECONDARY_OPTIC_LOW_ROTATION_OFFSET = Vector3(-10.0, 0.0, 0.0)
const _MOSIN_LOW_ROTATION_OFFSET = Vector3(-15.0, 15.0, 0.0)
const _REMINGTON_870_LOW_ROTATION_OFFSET = Vector3(-20.0, 10.0, 0.0)

const SCOPE_SHADOW_NONE := 0.02
const SCOPE_SHADOW_FULL := 0.002

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
var _handlingMode = HandlingMode.Default
var _aim_intent := false
var _cant_intent := false


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if h == null:
		return
	_lib.skip_super()

	if gameData.freeze:
		return

	gameData.isColliding = h.collision.is_colliding()

	if _override_handling(h, h.get_parent()):
		_handlingMode = HandlingMode.Default
	elif !_weapon_handling(h, h.get_parent(), delta):
		_set_target_idle(h)

	_apply_target(h, delta)


func on_input(evt) -> void:
	_lib.skip_super()

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


func _resolve_intent(aim_changed: bool) -> void:
	if aim_changed:
		gameData.isAiming = _aim_intent
		gameData.isCanted = false if _aim_intent else _cant_intent
	else:
		gameData.isCanted = _cant_intent
		gameData.isAiming = false if _cant_intent else _aim_intent


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

	var aim_z = data.aimPosition.z
	if optic && gameData.isScoped:
		aim_z += 0.05 if gameData.PIP else -0.1

	_update_scope_shadow(optic)

	h.targetPosition = Vector3(0.0, -rig.aimOffset, aim_z) if optic else data.aimPosition
	h.targetRotation = data.aimRotation
	return true


func _update_scope_shadow(optic) -> void:
	ModConfig.current_scope_shadow_tightness = SCOPE_SHADOW_NONE
	ModConfig.current_lens_camera_distance = 0.0

	if !optic || !gameData.PIP || gameData.secondaryOptic:
		return

	var att = optic.attachmentData
	if !(att.scope || att.variable):
		return

	var camera = optic.get_viewport().get_camera_3d()
	if !camera:
		return

	if camera.near > 0.01:
		camera.near = 0.01

	var lens_world: Vector3 = optic.global_transform * ScopeCatalog.get_optic_lens_center(optic)
	var eye_dist: float = camera.global_transform.origin.distance_to(lens_world)
	ModConfig.current_lens_camera_distance = eye_dist
	Out.debug("eye_dist: %.4fcm (%s)" % [eye_dist * 100.0, att.file])

	var eye_relief: Vector2 = ScopeCatalog.get_eye_relief(att.file)
	var slack: float = (eye_relief.y - eye_relief.x)
	var eye_relief_distance: float = 0.0
	if eye_dist < eye_relief.x:
		eye_relief_distance = clampf((eye_relief.x - eye_dist) / slack, 0.0, 1.0)
	elif eye_dist > eye_relief.y:
		eye_relief_distance = clampf((eye_dist - eye_relief.y) / slack, 0.0, 1.0)
	if eye_relief_distance:
		ModConfig.current_scope_shadow_tightness = lerp(SCOPE_SHADOW_NONE, SCOPE_SHADOW_FULL, eye_relief_distance)


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

