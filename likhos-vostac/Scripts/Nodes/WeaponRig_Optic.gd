extends "./WeaponRig_Base.gd"

const ScopeCatalog := preload("../ScopeCatalog.gd")
const ZoomAccelerator := preload("../ZoomAccelerator.gd")
const _RETICLE_SHADER := preload("res://mods/likhos-vostac/Shaders/Reticle.gdshader")
# Per-optic `size` values are authored against vanilla's view-direction UV. This rescales them onto lens UV.
const _LENS_UV_SCALE := 3.0

var _zoom := ZoomAccelerator.new()
var _rig: WeaponRig
var _handling: Node3D


func _ready() -> void:
	# injected in the rig's _ready, so its node tree is complete
	_rig = get_parent()
	_handling = _rig.get_node("Handling")
	set_process_input(true)
	set_process(true)


func _input(event: InputEvent) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var optic = _rig.activeOptic

	if _handle_zoom(event, optic):
		return

	_handle_secondary_optic(event)


func _handle_zoom(event: InputEvent, optic: Node3D) -> bool:
	if !optic || !optic.attachmentData.variable:
		return false

	var zoomIn := event.is_action_pressed("optic_zoom_in", true)
	var zoomOut := event.is_action_pressed("optic_zoom_out", true)
	var zoomAllowed: bool = (gameData.isAiming || config.zoom_out_of_aim == Config.ZoomOutOfAim.ENABLED
		|| (config.zoom_out_of_aim == Config.ZoomOutOfAim.RAIL_MOVEMENT && Input.is_action_pressed("rail_movement")))

	if !zoomAllowed || !(zoomIn || zoomOut):
		return false

	var max_zoom := ScopeCatalog.get_mag_range(optic.attachmentData).size()
	var dir := 1 if zoomIn else -1

	var new_zoom := _zoom.step(dir, _rig.slotData.zoom - 1, max_zoom) + 1
	if new_zoom != _rig.slotData.zoom:
		_rig.slotData.zoom = new_zoom
		ScopeCatalog.sync_optic_state(_rig)
		_zoom_audio.click()
	return true


func _handle_secondary_optic(event: InputEvent) -> bool:
	if !event.is_action_pressed("secondary_optic") || !ScopeCatalog.has_secondary_sight(_rig):
		return false

	gameData.secondaryOptic = !gameData.secondaryOptic
	ScopeCatalog.sync_optic_state(_rig)

	return true


func _process(delta: float) -> void:
	_handle_ads(delta)


func _handle_ads(delta: float) -> void:
	var optic = _rig.activeOptic
	var att = optic.attachmentData if optic else null
	# vanilla ADS runs for an unknown scope and owns its FOV, reticle and ocular opacity
	if att && ScopeCatalog.is_unknown(att):
		return

	gameData.aimFOV = gameData.baseFOV

	if !optic || !att:
		return

	if !gameData.isAiming:
		_rig.ocularOpacity = move_toward(_rig.ocularOpacity, 0.0 if (att.scope || att.variable) else 1.0, delta * 5.0)
		_update_reticle(optic)
		return

	_rig.ocularOpacity = move_toward(_rig.ocularOpacity, 0.0 if (att.scope && gameData.secondaryOptic) else 1.0, delta * 5.0)

	if (att.scope && !gameData.secondaryOptic) || att.variable:
		var sizes: Vector3 = att.reticleSizeP if gameData.PIP else att.reticleSize
		var mags = ScopeCatalog.get_mag_range(att)
		# FFP optics have their reticle sizes differ across the mag range, SFP optics have them equal
		var t := clampf(inverse_lerp(mags[0], mags[-1], config.current_scope_mag), 0.0, 1.0) if mags.size() > 1 else 0.0
		_rig.reticleSize = lerp(_rig.reticleSize, lerp(sizes.x, sizes.z, t), delta * 10.0)
		if !gameData.PIP:
			gameData.aimFOV = gameData.baseFOV / config.current_scope_mag
	else:
		_rig.reticleSize = att.reticleSize.x

	if gameData.PIP && gameData.isScoped:
		_update_optic_camera(optic, delta)

	_update_reticle(optic)


func _update_optic_camera(optic: Node3D, delta: float) -> void:
	var camera:Camera3D = optic.get_viewport().get_camera_3d()
	if !camera:
		return

	if camera.near > 0.01:
		camera.near = 0.01

	var lens := ScopeCatalog.get_lens(optic)
	var lens_distance: float = (optic.transform * lens.center).z + _handling.position.z
	if lens.radius <= 0.0 || lens_distance <= 0.0:
		return

	# the angle the lens covers from the eye, spread over the magnification
	var target_fov: float = rad_to_deg(2.0 * atan(lens.radius / lens_distance) / config.current_scope_mag)
	optic.camera.fov = lerp(optic.camera.fov, target_fov, delta * 10.0)


func _update_reticle(optic: Node3D) -> void:
	if !optic.reticle:
		return
	var att = optic.attachmentData
	if att && (att.scope || att.variable) && !("shader_parameter/lens_uv_scale" in optic.reticle):
		optic.reticle.shader = _RETICLE_SHADER
		optic.reticle.set_shader_parameter("lens_uv_scale", _LENS_UV_SCALE)
	optic.reticle.set_shader_parameter("size", _rig.reticleSize)
	optic.reticle.set_shader_parameter("opacity", _rig.ocularOpacity)
