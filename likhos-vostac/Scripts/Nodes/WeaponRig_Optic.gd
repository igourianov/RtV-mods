extends "./WeaponRig_Base.gd"

const ScopeCatalog := preload("../ScopeCatalog.gd")
const ZoomAccelerator := preload("../ZoomAccelerator.gd")
const _RETICLE_SHADER := preload("res://mods/likhos-vostac/Shaders/Reticle.gdshader")
# Per-optic `size` values are authored against vanilla's view-direction UV. This rescales them onto lens UV.
const _LENS_UV_SCALE := 3.0
# Swing shadow response to the scope's misalignment angle, in degrees, and its reach in lens UV (lens width 1.0).
const _SHADOW_DEAD_ZONE := 1.0
const _SHADOW_FULL_ANGLE := 5.0
const _SHADOW_MAX_REACH := 0.6
# Per second.
const _SHADOW_EXHAUSTION_RATE := 1.0
# The exhausted wobble and the crouch or stand kick peak around the dead zone on their own, so they count this many times over.
const _SHADOW_WOBBLE_GAIN := 3.0
const _SHADOW_KICK_GAIN := 3.0

var _zoom := ZoomAccelerator.new()
var _shadow_exhaustion := 0.0
var _shadow_offset := Vector2.ZERO
var _handling: Node3D
var _sway
var _noise: Node3D
var _impulse: Node3D


func _ready() -> void:
	# injected in the rig's _ready, so its node tree is complete
	var rig = get_parent()
	_handling = rig.get_node_or_null("Handling")
	_sway = rig.get_node_or_null("Handling/Sway")
	_noise = rig.get_node_or_null("Handling/Sway/Noise")
	_impulse = rig.get_node_or_null("Handling/Sway/Noise/Tilt/Impulse")
	set_process_input(true)
	set_process(true)


func _input(event: InputEvent) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var optic = get_parent().activeOptic

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

	var rig = get_parent()
	var max_zoom := ScopeCatalog.get_mag_range(optic.attachmentData).size()
	var dir := 1 if zoomIn else -1

	var new_zoom := _zoom.step(dir, rig.slotData.zoom - 1, max_zoom) + 1
	if new_zoom != rig.slotData.zoom:
		rig.slotData.zoom = new_zoom
		ScopeCatalog.sync_optic_state(rig)
		_zoom_audio.click()
	return true


func _handle_secondary_optic(event: InputEvent) -> bool:
	var rig = get_parent()
	if !event.is_action_pressed("secondary_optic") || !ScopeCatalog.has_secondary_sight(rig):
		return false

	gameData.secondaryOptic = !gameData.secondaryOptic
	ScopeCatalog.sync_optic_state(rig)

	return true


func _process(delta: float) -> void:
	_handle_ads(delta)


func _handle_ads(delta: float) -> void:
	var rig = get_parent()
	var optic = rig.activeOptic
	var att = optic.attachmentData if optic else null
	gameData.aimFOV = gameData.baseFOV

	if !optic || !att:
		return

	_shadow_exhaustion = move_toward(_shadow_exhaustion, 1.0 if gameData.armStamina <= 0.0 else 0.0, delta * _SHADOW_EXHAUSTION_RATE)
	_shadow_offset = Vector2.ZERO

	if !gameData.isAiming || gameData.isColliding:
		rig.ocularOpacity = move_toward(rig.ocularOpacity, 0.0 if (att.scope || att.variable) else 1.0, delta * 5.0)
		_update_reticle(rig, optic)
		return

	rig.ocularOpacity = move_toward(rig.ocularOpacity, 0.0 if (att.scope && gameData.secondaryOptic) else 1.0, delta * 5.0)

	if (att.scope && !gameData.secondaryOptic) || att.variable:
		var sizes: Vector3 = att.reticleSizeP if gameData.PIP else att.reticleSize
		var mags = ScopeCatalog.get_mag_range(att)
		# FFP optics have their reticle sizes differ across the mag range, SFP optics have them equal
		var t := clampf(inverse_lerp(mags[0], mags[-1], config.current_scope_mag), 0.0, 1.0) if mags.size() > 1 else 0.0
		rig.reticleSize = lerp(rig.reticleSize, lerp(sizes.x, sizes.z, t), delta * 10.0)
		if !gameData.PIP:
			gameData.aimFOV = gameData.baseFOV / config.current_scope_mag
	else:
		rig.reticleSize = att.reticleSize.x

	if gameData.PIP && gameData.isScoped:
		_update_optic_camera(optic, delta)

	if gameData.isScoped:
		_update_shadow()

	_update_reticle(rig, optic)


func _update_shadow() -> void:
	var lag: Vector3 = _sway.rotation_degrees - _sway.originalRotation
	var wobble: Vector3 = _noise.rotation_degrees * _SHADOW_WOBBLE_GAIN * _shadow_exhaustion
	var kick: Vector3 = _impulse.rotation_degrees * _SHADOW_KICK_GAIN
	var total: Vector3 = lag + wobble + kick
	# x is the yaw, y the pitch, in view space with y up, signed so the vector points where the clear aperture shifts.
	# A yaw to the right tilts the lens normal left, and vanilla's view ray plus normal offset then clears the right side.
	var misalignment := Vector2(-total.y, total.x)
	var magnitude := misalignment.length()

	if magnitude <= _SHADOW_DEAD_ZONE:
		return
	var reach := clampf(inverse_lerp(_SHADOW_DEAD_ZONE, _SHADOW_FULL_ANGLE, magnitude), 0.0, 1.0) * _SHADOW_MAX_REACH
	# Lens UV runs y down.
	_shadow_offset = misalignment / magnitude * reach * Vector2(1.0, -1.0)


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


func _update_reticle(rig: WeaponRig, optic: Node3D) -> void:
	if !optic.reticle:
		return
	var att = optic.attachmentData
	if att && (att.scope || att.variable):
		if !("shader_parameter/lens_uv_scale" in optic.reticle):
			optic.reticle.shader = _RETICLE_SHADER
			optic.reticle.set_shader_parameter("lens_uv_scale", _LENS_UV_SCALE)
		optic.reticle.set_shader_parameter("shadow_offset", _shadow_offset)
	optic.reticle.set_shader_parameter("size", rig.reticleSize)
	optic.reticle.set_shader_parameter("opacity", rig.ocularOpacity)
