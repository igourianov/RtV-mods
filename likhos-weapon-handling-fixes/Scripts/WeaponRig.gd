extends RefCounted

var _lib
var _preferences: Preferences
var current_scope_mag: float = 0.0
var active_rig: WeaponRig
var _ammo_check_saved_position: int = 0
var _last_optic_for_scale = null
var _cached_lens_scale: float = 1.0


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_input(event) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	var gd = rig.gameData

	if (gd.freeze
		|| gd.isPlacing
		|| gd.isReloading
		|| gd.isInserting
		|| gd.isChecking
		|| gd.isCaching
		|| gd.isTransitioning
		|| gd.isFiring):
		return

	if event.is_action_pressed("inspect"):
		gd.isInspecting = !gd.isInspecting
		gd.isFiring = false

		if gd.isInspecting:
			gd.inspectPosition = 1
			rig.PlayInspectStart()
			rig.animator["parameters/conditions/Inspect_Front"] = true
			rig.animator["parameters/conditions/Inspect_Idle"] = false
			rig.UpdateBullets()
			rig.UpdateHUD()
		else:
			if gd.inspectPosition == 1:
				rig.PlayInspectEnd()
				rig.animator["parameters/conditions/Inspect_Front"] = false
				rig.animator["parameters/conditions/Inspect_Idle"] = true
			elif gd.inspectPosition == 2:
				rig.PlayInspectEnd()
				rig.animator["parameters/conditions/Inspect_Back"] = false
				rig.animator["parameters/conditions/Inspect_Idle"] = true
				gd.inspectPosition = 1
		return

	if gd.isInspecting:
		if event.is_action_pressed("canted"):
			if gd.inspectPosition == 1:
				rig.PlayInspectRotate()
				rig.animator["parameters/conditions/Inspect_Front"] = false
				rig.animator["parameters/conditions/Inspect_Back"] = true
				gd.inspectPosition = 2
			elif gd.inspectPosition == 2:
				rig.PlayInspectRotate()
				rig.animator["parameters/conditions/Inspect_Front"] = true
				rig.animator["parameters/conditions/Inspect_Back"] = false
				gd.inspectPosition = 1

		if event is InputEventMouseButton && event.is_pressed():
			var optic = rig.activeOptic
			if optic == null || !optic.railMovement:
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_UP && optic.position.z < optic.maxPosition:
				optic.position.z += 0.01
				rig.slotData.position += 0.01
				rig.PlayRailMove()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN && optic.position.z > optic.minPosition:
				optic.position.z -= 0.01
				rig.slotData.position -= 0.01
				rig.PlayRailMove()
		return

	if event.is_action_pressed("secondary_optic"):
		var sec_optic = rig.activeOptic
		if sec_optic != null && sec_optic.attachmentData.secondary && sec_optic.secondary != null:
			gd.secondaryOptic = !gd.secondaryOptic
			rig.UpdateAimOffset()

	if event is InputEventMouseButton && event.is_pressed():
		var optic = rig.activeOptic
		if optic == null || !optic.attachmentData.variable:
			return
		var slotData = rig.slotData
		if event.button_index == MOUSE_BUTTON_WHEEL_UP && slotData.zoom != 3:
			slotData.zoom += 1
			rig.PlayRailMove()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN && slotData.zoom != 1:
			slotData.zoom -= 1
			rig.PlayRailMove()


func on_physics_process_pre(_delta: float) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	if rig.gameData.isInspecting:
		_lib.skip_super()


func on_ammo_check_pre() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_ammo_check_saved_position = rig.gameData.weaponPosition


func on_ammo_check_post() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	rig.gameData.weaponPosition = _ammo_check_saved_position


func on_ready_post() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	# Vanilla M4A1_Rig.tscn sets backSightIndex but never sets frontSightIndex,
	# leaving it at the export default 0. With foldSights = true, UpdateAimOffset
	# writes a fold rotation to bone 0 (M4A1_Body, the root) every call, which
	# the AnimationTree reverts on the next physics tick — visible as a flicker.
	# Alias frontSightIndex to backSightIndex so the redundant write is harmless.
	if rig.data != null && rig.data.foldSights && rig.backSightIndex > 0 && rig.frontSightIndex == 0:
		rig.frontSightIndex = rig.backSightIndex


func on_ads_post(delta: float) -> void:
	var rig = _lib._caller
	active_rig = rig

	var gd = rig.gameData

	# Vanilla leaves gameData.secondaryOptic set when the active optic changes outside
	# the Inspect attach/detach path. The next optic's _physics_process then disables
	# its PIP surface and never re-enables it.
	if gd.secondaryOptic:
		var current = rig.activeOptic
		if current == null || !current.attachmentData.secondary || current.secondary == null:
			gd.secondaryOptic = false

	if !gd.PIP || !gd.isAiming || gd.isColliding:
		current_scope_mag = 0.0
		return

	var optic = rig.activeOptic
	if optic == null:
		current_scope_mag = 0.0
		return

	var att = optic.attachmentData

	var lens_scale: float
	if optic == _last_optic_for_scale:
		lens_scale = _cached_lens_scale
	else:
		lens_scale = optic.transform.basis.get_scale().y
		_cached_lens_scale = lens_scale
		_last_optic_for_scale = optic

	var base_fov = gd.baseFOV

	if att.scope && !gd.secondaryOptic:
		optic.camera.fov = base_fov * lens_scale / 4.0
		gd.aimFOV = base_fov
		current_scope_mag = base_fov / max(optic.camera.fov, 1.0)
		return

	if !att.variable || rig.slotData == null:
		current_scope_mag = 0.0
		return

	gd.aimFOV = base_fov

	match rig.slotData.zoom:
		1:
			gd.isScoped = true
			optic.camera.fov = lerp(optic.camera.fov, base_fov * lens_scale / 1.1, delta * 10.0)
			if _preferences != null:
				gd.scopeSensitivity = _preferences.aimSensitivity
		2:
			optic.camera.fov = lerp(optic.camera.fov, base_fov * lens_scale / 3.0, delta * 10.0)
			if _preferences != null:
				gd.scopeSensitivity = _preferences.scopeSensitivity
		3:
			optic.camera.fov = lerp(optic.camera.fov, base_fov * lens_scale / 6.0, delta * 10.0)
			if _preferences != null:
				gd.scopeSensitivity = _preferences.scopeSensitivity * 0.5

	current_scope_mag = base_fov / max(optic.camera.fov, 1.0)
