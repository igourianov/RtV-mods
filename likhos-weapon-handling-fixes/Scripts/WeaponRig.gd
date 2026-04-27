extends RefCounted

var _lib
var _preferences: Preferences
var current_scope_mag: float = 0.0
var _ammo_check_saved_position: int = 0


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


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
	if !rig.gameData.PIP:
		return
	if rig == null || !rig.gameData.PIP || !rig.gameData.isAiming || rig.gameData.isColliding:
		current_scope_mag = 0.0
		return

	var optic = rig.activeOptic
	if optic == null:
		current_scope_mag = 0.0
		return

	var lens_scale = optic.transform.basis.get_scale().y

	if optic.attachmentData.scope && !rig.gameData.secondaryOptic:
		optic.camera.fov = rig.gameData.baseFOV * lens_scale / 4.0
		rig.gameData.aimFOV = rig.gameData.baseFOV
		current_scope_mag = rig.gameData.baseFOV / max(optic.camera.fov, 1.0)
		return

	if !optic.attachmentData.variable || rig.slotData == null:
		current_scope_mag = 0.0
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

	current_scope_mag = rig.gameData.baseFOV / max(optic.camera.fov, 1.0)
