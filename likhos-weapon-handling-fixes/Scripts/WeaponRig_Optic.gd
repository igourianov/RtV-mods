extends "./WeaponRig_Base.gd"

const ModConfig = preload("./ModConfig.gd")
const ScopeCatalog = preload("./ScopeCatalog.gd")
const _RETICLE_SHADER := preload("res://mods/likhos-weapon-handling-fixes/Shaders/Reticle.gdshader")

const _ZOOM_ACCEL_WINDOW := 175
const _ZOOM_ACCEL_MAX := 3

var _last_zoom_msec := 0
var _last_zoom_dir := 0
var _zoom_accel := 1


func _ready() -> void:
	set_process_input(true)
	set_process(true)


func _input(event) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var optic = get_parent().activeOptic

	if _handle_zoom(event, optic):
		return

	if _handle_secondary_optic(event, optic):
		return


func _handle_zoom(event, optic) -> bool:

	if !optic || !optic.attachmentData.variable:
		return false

	var zoomIn = event.is_action_pressed("optic_zoom_in", true)
	var zoomOut = event.is_action_pressed("optic_zoom_out", true)
	var zoomAllowed: bool = (gameData.isAiming || ModConfig.lpvo_ooa_zoom == &"enabled"
		|| (ModConfig.lpvo_ooa_zoom == &"rail" && Input.is_action_pressed("rail_movement")))

	if !zoomAllowed || !(zoomIn || zoomOut):
		return false

	var rig = get_parent()
	var max_zoom = ScopeCatalog.get_mag_range(optic.attachmentData.file).size()
	var dir := 1 if zoomIn else -1
	var now := Time.get_ticks_msec()

	if dir == _last_zoom_dir && now - _last_zoom_msec <= _ZOOM_ACCEL_WINDOW:
		_zoom_accel = min(_zoom_accel + 1, _ZOOM_ACCEL_MAX)
	else:
		_zoom_accel = 1

	_last_zoom_dir = dir
	_last_zoom_msec = now

	var new_zoom: int = clamp(rig.slotData.zoom + dir * _zoom_accel, 1, max_zoom)
	if new_zoom != rig.slotData.zoom:
		rig.slotData.zoom = new_zoom
		rig.PlayRailMove()
	return true


func _handle_secondary_optic(event, optic) -> bool:
	if !optic || !optic.secondary || !optic.attachmentData.secondary || !event.is_action_pressed("secondary_optic"):
		return false

	gameData.secondaryOptic = !gameData.secondaryOptic

	var rig = get_parent()
	if gameData.secondaryOptic:
		Out.bugfix("recalc secondary optic Y offset")
		rig.aimOffset = optic.position.y + optic.secondary.position.y * optic.scale.y
	else:
		rig.aimOffset = optic.position.y

	return true


func _process(delta: float) -> void:
	_handle_ads(delta)


func _handle_ads(delta: float) -> void:
	var rig = get_parent()
	var optic = rig.activeOptic
	var shadow: float = 0.0
	ModConfig.current_scope_mag = 1.0
	gameData.aimFOV = gameData.baseFOV
	gameData.isScoped = false

	if !optic:
		return

	var att = optic.attachmentData

	if !gameData.isAiming || gameData.isColliding:
		rig.ocularOpacity = move_toward(rig.ocularOpacity, 0.0 if (att.scope || att.variable) else 1.0, delta * 5.0)
		_update_reticle(rig, optic, shadow)
		return

	rig.ocularOpacity = move_toward(rig.ocularOpacity, 0.0 if (att.scope && gameData.secondaryOptic) else 1.0, delta * 5.0)

	if (att.scope && !gameData.secondaryOptic) || att.variable:
		var sizes = att.reticleSizeP if gameData.PIP else att.reticleSize
		var mags = ScopeCatalog.get_mag_range(att.file)
		ModConfig.current_scope_mag = mags[clamp(rig.slotData.zoom, 1, mags.size()) - 1]
		if mags.size() > 1 && ScopeCatalog.is_ffp(att.file):
			var t = clampf(inverse_lerp(mags[0], mags[-1], ModConfig.current_scope_mag), 0.0, 1.0)
			rig.reticleSize = lerp(rig.reticleSize, lerp(sizes.x, sizes.z, t), delta * 10.0)
		else:
			rig.reticleSize = sizes.x
		if gameData.PIP:
			gameData.isScoped = true
		else:
			gameData.aimFOV = gameData.baseFOV / ModConfig.current_scope_mag
			gameData.isScoped = ModConfig.current_scope_mag > 1.0
	else:
		rig.reticleSize = att.reticleSize.x

	if gameData.PIP && gameData.isScoped:
		shadow = _update_optic_camera(optic, delta)

	_update_reticle(rig, optic, shadow)


func _update_optic_camera(optic, delta: float) -> float:
	var camera = optic.get_viewport().get_camera_3d()
	if !camera:
		return 0.0

	if camera.near > 0.01:
		camera.near = 0.01

	var lens_world: Vector3 = optic.global_transform * ScopeCatalog.get_lens_center(optic)
	var lens_distance: float = camera.global_transform.origin.distance_to(lens_world)
	var lens_radius: float = ScopeCatalog.get_lens_radius(optic)
	if lens_radius > 0.0 && lens_distance > 0.0:
		var target_fov: float = rad_to_deg(2.0 * atan(lens_radius / lens_distance) / ModConfig.current_scope_mag)
		optic.camera.fov = lerp(optic.camera.fov, target_fov, delta * 10.0)

	var eye_relief: Vector2 = ScopeCatalog.get_eye_relief(optic.attachmentData.file)
	var slack: float = 0.03
	if lens_distance < eye_relief.x:
		return clampf((eye_relief.x - lens_distance) / slack, 0.0, 1.0)
	elif lens_distance > eye_relief.y:
		return clampf((lens_distance - eye_relief.y) / slack, 0.0, 1.0)
	return 0.0


func _update_reticle(rig, optic, shadow: float) -> void:
	if !optic.reticle:
		return
	var att = optic.attachmentData
	if att && (att.scope || att.variable):
		if !("shader_parameter/shadow" in optic.reticle):
			optic.reticle.shader = _RETICLE_SHADER
		optic.reticle.set_shader_parameter("shadow", shadow)
	optic.reticle.set_shader_parameter("size", rig.reticleSize)
	optic.reticle.set_shader_parameter("opacity", rig.ocularOpacity)
