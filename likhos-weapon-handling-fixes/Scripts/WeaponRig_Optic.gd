extends "./WeaponRig_Base.gd"

const ModConfig = preload("./ModConfig.gd")
const ScopeCatalog = preload("./ScopeCatalog.gd")
const _RETICLE_SHADER := preload("res://mods/likhos-weapon-handling-fixes/Shaders/Reticle.gdshader")

const _ZOOM_ACCEL_WINDOW := 175
const _ZOOM_ACCEL_MAX := 3

var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")

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
	gameData.isScoped = ScopeCatalog.is_magnified(optic) && !gameData.secondaryOptic

	var rig = get_parent()
	if gameData.secondaryOptic:
		# BUGFIX: vanilla fails to factor optic.scale, which results in incorrect Y offset on several guns
		rig.aimOffset = optic.position.y + optic.secondary.position.y * optic.scale.y
	else:
		rig.aimOffset = optic.position.y

	return true


func _process(delta: float) -> void:
	_handle_ads(delta)


func _handle_ads(delta: float) -> void:
	var rig = get_parent()
	var optic = rig.activeOptic
	var att = optic.attachmentData if optic else null
	ModConfig.current_scope_mag = 1.0
	gameData.aimFOV = gameData.baseFOV

	if !optic || !att:
		return

	if !gameData.isAiming || gameData.isColliding:
		rig.ocularOpacity = move_toward(rig.ocularOpacity, 0.0 if (att.scope || att.variable) else 1.0, delta * 5.0)
		_update_reticle(rig, optic, 0.0)
		return

	var geom = ScopeCatalog.get_optic_geometry(optic)
	var handling = rig.get_node("Handling")
	var lens_z: float = (optic.transform * geom.lens_center).z
	var lens_distance: float = lens_z + handling.position.z
	var target_lens_distance: float = lens_z - handling.targetPosition.z
	var shadow: float = ScopeCatalog.compute_shadow(lens_distance, geom.eye_relief)
	var angle: float = ScopeCatalog.compute_angle(geom.lens_radius, lens_distance)

	rig.ocularOpacity = move_toward(rig.ocularOpacity, 0.0 if (att.scope && gameData.secondaryOptic) else 1.0, delta * 5.0)

	if gameData.isAiming && !_validate_lens_distance(rig, lens_distance, target_lens_distance):
		gameData.isAiming = false
		return

	if (att.scope && !gameData.secondaryOptic) || att.variable:
		var sizes = att.reticleSizeP if gameData.PIP else att.reticleSize
		var mags = ScopeCatalog.get_mag_range(att.file)
		ModConfig.current_scope_mag = mags[clamp(rig.slotData.zoom, 1, mags.size()) - 1]
		if mags.size() > 1 && geom.isFFP:
			var t = clampf(inverse_lerp(mags[0], mags[-1], ModConfig.current_scope_mag), 0.0, 1.0)
			rig.reticleSize = lerp(rig.reticleSize, lerp(sizes.x, sizes.z, t), delta * 10.0)
		else:
			rig.reticleSize = sizes.x
		if !gameData.PIP:
			gameData.aimFOV = gameData.baseFOV / ModConfig.current_scope_mag
	else:
		rig.reticleSize = att.reticleSize.x

	if gameData.PIP && gameData.isScoped:
		_update_optic_camera(optic, delta, angle)

	_update_reticle(rig, optic, shadow if gameData.PIP else 0.0)


func _validate_lens_distance(rig, lens_distance: float, target_lens_distance: float) -> bool:
	if target_lens_distance >= 0.02 || lens_distance >= 0.02:
		return true
	gameData.impact = true
	gameData.damage = true
	gameData.health -= 2.0

	ModConfig.optic_shiner = true

	var audio = audioInstance2D.instantiate()
	rig.add_child(audio)
	audio.PlayInstance(audioLibrary.damage)
	
	Out.protip(&"optic-too-close", "The optic is mounted too close! You gave yourself a shiner by trying to ADS, you dummy.")
	return false

func _update_optic_camera(optic, delta: float, optic_angle: float) -> void:
	var camera = optic.get_viewport().get_camera_3d()
	if !camera:
		return

	if camera.near > 0.01:
		camera.near = 0.01

	if optic_angle <= 0.0:
		return

	var target_fov: float = rad_to_deg(optic_angle / ModConfig.current_scope_mag)
	optic.camera.fov = lerp(optic.camera.fov, target_fov, delta * 10.0)


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

