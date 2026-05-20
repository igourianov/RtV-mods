extends "./WeaponRig_Base.gd"

const ModConfig = preload("./ModConfig.gd")
const ScopeCatalog = preload("./ScopeCatalog.gd")
const _RETICLE_SHADER := preload("res://mods/likhos-weapon-handling-fixes/Shaders/Reticle.gdshader")

# Runtime cache for lens radii extracted from mesh, keyed by optic node name
var _lens_radius_cache := {}

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
	ModConfig.current_scope_mag = 1.0
	gameData.aimFOV = gameData.baseFOV
	gameData.isScoped = false

	if !optic:
		return

	var att = optic.attachmentData

	if !gameData.isAiming || gameData.isColliding:
		rig.ocularOpacity = move_toward(rig.ocularOpacity, 0.0 if (att.scope || att.variable) else 1.0, delta * 5.0)
		_update_reticle(rig, optic)
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
		var lens_radius: float = _get_lens_radius(optic)
		var distance: float = ModConfig.current_lens_camera_distance
		if lens_radius > 0.0 && distance > 0.0:
			var target_fov: float = rad_to_deg(2.0 * atan(lens_radius / distance) / ModConfig.current_scope_mag)
			optic.camera.fov = lerp(optic.camera.fov, target_fov, delta * 10.0)

	_update_reticle(rig, optic)


func _update_reticle(rig, optic) -> void:
	if !optic.reticle:
		return
	var att = optic.attachmentData
	if att && (att.scope || att.variable):
		if !("shader_parameter/shadow" in optic.reticle):
			optic.reticle.shader = _RETICLE_SHADER
		optic.reticle.set_shader_parameter("shadow", ModConfig.current_scope_shadow)
	optic.reticle.set_shader_parameter("size", rig.reticleSize)
	optic.reticle.set_shader_parameter("opacity", rig.ocularOpacity)


func _get_lens_radius(optic) -> float:
	var key = String(optic.name)
	var radius: float = ScopeCatalog.get_lens_radius(key)
	if radius > 0.0:
		return radius
	var cached = _lens_radius_cache.get(key, -1.0)
	if cached >= 0.0:
		return cached
	radius = _extract_lens_radius(optic)
	_lens_radius_cache[key] = radius
	Out.debug("extracted lens radius for", key, ":", radius)
	return radius


func _extract_lens_radius(optic) -> float:
	if optic.mesh == null || optic.mesh.mesh == null:
		return 0.0
	var arrays = optic.mesh.mesh.surface_get_arrays(optic.maskIndex)
	if arrays.is_empty():
		return 0.0
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return 0.0
	var t = optic.mesh.transform
	var centroid: Vector3 = Vector3.ZERO
	for v in verts:
		centroid += t * v
	centroid /= verts.size()
	var max_r_sq: float = 0.0
	for v in verts:
		var p = t * v
		var dx: float = p.x - centroid.x
		var dy: float = p.y - centroid.y
		var r_sq: float = dx * dx + dy * dy
		if r_sq > max_r_sq:
			max_r_sq = r_sq
	return sqrt(max_r_sq)
