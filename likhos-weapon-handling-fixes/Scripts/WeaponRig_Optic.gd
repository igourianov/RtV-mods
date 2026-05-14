extends "./WeaponRig_Base.gd"

const ModConfig = preload("./ModConfig.gd")

const _FIXED_SCOPE_AIM_OFFSET = 0.015
const _VARIABLE_SCOPE_AIM_OFFSET = 0.03

var _last_optic_for_scale = null
var _cached_lens_scale: float = 1.0


func _input(event) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var rig = owner
	if rig == null:
		return

	var optic = rig.activeOptic
	var zoomIn = event.is_action_pressed("optic_zoom_in", true)
	var zoomOut = event.is_action_pressed("optic_zoom_out", true)

	if (gameData.isAiming || ModConfig.lpvo_ooa_zoom) && (zoomIn || zoomOut) && optic && optic.attachmentData.variable:
		if zoomIn && rig.slotData.zoom != 3:
			rig.slotData.zoom += 1
			rig.PlayRailMove()
		elif zoomOut && rig.slotData.zoom != 1:
			rig.slotData.zoom -= 1
			rig.PlayRailMove()
		return

	if event.is_action_pressed("secondary_optic") && optic && optic.secondary && optic.attachmentData.secondary:
		gameData.secondaryOptic = !gameData.secondaryOptic
		#rig.UpdateAimOffset()
		_apply_aim_offset()
		return


func _apply_aim_offset() -> void:
	var rig = owner
	var data = rig.data
	var optic = rig.activeOptic

	if optic && optic.secondary && gameData.secondaryOptic:
		Out.bugfix("recalc secondary optic Y offset")
		rig.aimOffset = optic.position.y + optic.secondary.position.y * optic.scale.y
	elif optic:
		rig.aimOffset = optic.position.y
	else:
		rig.aimOffset = 0.0

	if data.foldSights:
		var rot = Quaternion.from_euler(Vector3(data.foldSightsRotation if optic else 0.0, 0, 0))
		rig.skeleton.set_bone_pose_rotation(rig.backSightIndex, rot)
		if rig.frontSightIndex:
			rig.skeleton.set_bone_pose_rotation(rig.frontSightIndex, rot)
		else:
			Out.bugfix("do not attempt to rotate front sight on M4A1 (flicker)")


func on_ads_post(delta: float) -> void:
	var rig = owner
	var optic = rig.activeOptic
	var att = optic.attachmentData

	ModConfig.current_scope_mag = 1.0
	if rig.slotData.zoom == 1:
		gameData.isScoped = gameData.PIP
		ModConfig.current_scope_mag = 1.1
	elif rig.slotData.zoom == 2:
		ModConfig.current_scope_mag = 3.0
	elif rig.slotData.zoom == 3:
		ModConfig.current_scope_mag = 6.0

	if !gameData.PIP || !gameData.isAiming || gameData.isColliding || optic == null:
		return

	var lens_scale: float
	if optic == _last_optic_for_scale:
		lens_scale = _cached_lens_scale
	else:
		lens_scale = optic.transform.basis.get_scale().y
		_cached_lens_scale = lens_scale
		_last_optic_for_scale = optic

	if !att.variable && (!att.scope || gameData.secondaryOptic):
		return

	gameData.aimFOV = gameData.baseFOV

	if att.scope && !gameData.secondaryOptic:
		ModConfig.current_scope_mag = 4.0
		var distance = _distance_factor(_FIXED_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
		optic.camera.fov = distance * gameData.baseFOV * lens_scale / ModConfig.current_scope_mag
		return

	var distance = _distance_factor(_VARIABLE_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
	optic.camera.fov = lerp(optic.camera.fov, distance * gameData.baseFOV * lens_scale / ModConfig.current_scope_mag, delta * 10.0)


func _distance_factor(base: float, distance: float) -> float:
	var f: float = base / (base + distance)
	return f
