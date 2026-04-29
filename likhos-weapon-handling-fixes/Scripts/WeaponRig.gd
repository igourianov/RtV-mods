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


func on_input_pre(event) -> void:
	var rig = _lib._caller
	if rig == null:
		return

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

	if Input.is_action_pressed("rail_movement"):
		return
	if gd.isInspecting:
		return
	if gd.isAiming:
		return

	if Input.is_action_just_pressed("secondary_optic"):
		var sec_optic = rig.activeOptic
		if sec_optic != null && sec_optic.attachmentData.secondary && sec_optic.secondary != null:
			gd.secondaryOptic = !gd.secondaryOptic
			rig.UpdateAimOffset()

	if not (event is InputEventMouseButton and event.is_pressed()):
		return

	var optic = rig.activeOptic
	if optic == null or not optic.attachmentData.variable:
		return

	var slotData = rig.slotData
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and slotData.zoom != 3:
		slotData.zoom += 1
		rig.PlayRailMove()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and slotData.zoom != 1:
		slotData.zoom -= 1
		rig.PlayRailMove()


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
