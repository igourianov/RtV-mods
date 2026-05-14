extends "./WeaponRig_Base.gd"

const ModConfig = preload("./ModConfig.gd")

# Lens radius in meters, keyed by optic node name. Populated from mesh on first
# miss; pre-seed entries here to skip the one-shot extraction.
var _lens_radius_cache := {
	"Vudu": 0.020,
	"ACOG": 0.0117,
	"Leopard": 0.0185,
	"HMR": 0.017,
	"PU": 0.0115,
	"POSP": 0.012
}
var _old_fov: float = 0.0


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


func on_ads_post(_delta: float) -> void:
	var rig = owner
	var optic = rig.activeOptic
	var att = optic.attachmentData

	ModConfig.current_scope_mag = 1.0
	if att.scope && !gameData.secondaryOptic:
		ModConfig.current_scope_mag = 4.0
	elif att.variable && rig.slotData.zoom == 1:
		gameData.isScoped = gameData.PIP # force isScoped on 1x in PIP mode
		ModConfig.current_scope_mag = 1.1
	elif att.variable && rig.slotData.zoom == 2:
		ModConfig.current_scope_mag = 3.0
	elif att.variable && rig.slotData.zoom == 3:
		ModConfig.current_scope_mag = 6.0

	if !gameData.PIP || !gameData.isAiming || !gameData.isScoped || gameData.isColliding || !optic:
		return

	gameData.aimFOV = gameData.baseFOV # force FOV back into 1x (your eyes don't have zoom)

	var lens_radius: float = _get_lens_radius(optic)
	if lens_radius <= 0.0:
		return

	var distance: float = (ModConfig.FIXED_SCOPE_AIM_OFFSET if att.scope else ModConfig.VARIABLE_SCOPE_AIM_OFFSET) + ModConfig.eye_relief_offset
	var target_fov: float = rad_to_deg(2.0 * atan(lens_radius / distance) / ModConfig.current_scope_mag)

	optic.camera.fov = target_fov


func _get_lens_radius(optic) -> float:
	var key = String(optic.name)
	var cached = _lens_radius_cache.get(key, -1.0)
	if cached >= 0.0:
		return cached
	var radius: float = _extract_lens_radius(optic)
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
