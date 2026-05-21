const Out = preload("../Lib/Out.gd")
const ModConfig = preload("./ModConfig.gd")

const _FALLBACK_MAG: Array[float] = [1.0]

static var _lens_geometry_cache := {}

const DATA := {
	"ACOG": {
		"mag_range": [4.0],
		"eye_relief": Vector2(2.5, 4.5),
		"lens_radius": 0.013,
		"lens_center": Vector3(0.0, 0.0, -0.102),
		"display": "ACOG",
		"name": "Trijicon ACOG TA31",
		"weight": 0.45,
	},
	"HMR": {
		"mag_range": [4.0],
		"eye_relief": Vector2(5.5, 8.0),
		"lens_radius": 0.017,
		"lens_center": Vector3(0.0, 0.0, -0.069),
		"display": "HAMR",
		"name": "Leupold HAMR 4x",
		"rarity": 2, # legendary
		"weight": 0.4,
	},
	"POSP": {
		"mag_range": [2.0, 3.5, 6.0],
		"mag_range_discrete": [2.0, 3.0, 4.0, 5.0, 6.0],
		"eye_relief": Vector2(6.5, 9.0),
		"force_z_pos": true,
		"lens_radius": 0.012,
		"lens_center": Vector3(0.0, 0.0, -0.078),
		"scope": false,
		"variable": true,
		"weight": 0.9,
		"name": "POSP 2-6x",
		"reticleSize": Vector3(0.3, 0.3, 0.3), # default X is very small
		"reticleSizeP": Vector3(0.5, 0.5, 0.5), # default X is very small
	},
	"PU": {
		"mag_range": [3.5],
		"eye_relief": Vector2(6.5, 8.5),
		"force_z_pos": true,
		"lens_radius": 0.0115,
		"lens_center": Vector3(0.0, 0.0, -0.081),
		"weight": 0.75,
		"display": "PU",
		"name": "PU",
	},
	"Vudu": {
		"isFFP": true,
		"mag_range": [1.0, 3.2, 10.0],
		"mag_range_normalized": [1.0, 1.6, 2.5, 4.0, 6.3, 10.0],
		"mag_range_discrete": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
		"eye_relief": Vector2(6.5, 12.5),
		"lens_radius": 0.020,
		"lens_center": Vector3(0.0, 0.0, -0.131),
		"display": "Vudu",
		"name": "EOTech Vudu 1-10x FFP",
		"rarity": 2, # legendary
		"value": 2500,
		"weight": 0.8,
		"reticleSizeP": Vector3(0.1, 0.3, 1.2), # default Z is too small
	},
	"Leopard": {
		"isFFP": true,
		"mag_range": [1.1, 3.0, 8.0],
		"mag_range_normalized": [1.1, 1.7, 2.8, 4.8, 8.0],
		"mag_range_discrete": [1.1, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
		"eye_relief": Vector2(7.0, 11.5),
		"lens_radius": 0.0185,
		"lens_center": Vector3(0.0, 0.0, -0.177),
		"display": "Leupold",
		"name": "Leupold Mark 8 CQBSS",
		"weight": 0.85,
		"reticleSizeP": Vector3(0.2, 0.4, 0.6), # default X is very small
	},
	"RMR": {
		"display": "RMR",
		"name": "Trijicon RMR",
		"weight": 0.1,
	},
	"EXPS": {
		"display": "EXP",
		"name": "EOTech EXPS",
		"weight": 0.5,
	},
	"Kobra": {
		"display": "Kobra",
		"name": "Kobra",
		"weight": 0.4,
	},
	"Micro": {
		"display": "T2",
		"name": "Aimpoint T2",
		"weight": 0.15,
	},
	"MRO": {
		"display": "MRO",
		"name": "Trijicon MRO",
		"weight": 0.15,
	},
	"PRO": {
		"display": "PRO",
		"name": "Aimpoint PRO",
		"weight": 0.35,
	},
	"SRO": {
		"display": "SRO",
		"name": "Trijicon SRO",
		"weight": 0.1,
	}
}


static func get_mag_range(key: String) -> Array:
	var entry: Dictionary = DATA.get(key, {})
	var field := "mag_range"
	match ModConfig.mag_schema:
		&"discrete":
			field = "mag_range_discrete"
		&"normalized":
			field = "mag_range_normalized"
	return entry.get(field, entry.get("mag_range", _FALLBACK_MAG))


static func update_optic_cache(rig, optic) -> void:
	if !optic || !rig.data:
		rig.set_meta("lensDistance", 0.0)
		rig.set_meta("opticAimZ", 0.0)
		rig.set_meta("scopeShadow", 0.0)
		rig.set_meta("opticAngle", 0.0)
		rig.set_meta("opticIsFFP", false)
		return
	var key := String(optic.attachmentData.file)
	var entry: Dictionary = DATA.get(key, {})
	var eye_relief_raw = entry.get("eye_relief")
	var eye_relief: Vector2 = eye_relief_raw * 0.01 if eye_relief_raw is Vector2 else Vector2.ZERO

	var lens_center: Vector3 = entry.get("lens_center", Vector3.ZERO)
	var lens_radius: float = entry.get("lens_radius", 0.0)
	if lens_center == Vector3.ZERO || lens_radius <= 0.0:
		var geom = _ensure_lens_geometry(optic, key)
		if lens_center == Vector3.ZERO:
			lens_center = geom.get("center", Vector3.ZERO)
		if lens_radius <= 0.0:
			lens_radius = geom.get("radius", 0.0)
	var lens_local: Vector3 = optic.transform * lens_center

	var lens_distance: float
	var optic_aim_z: float
	if entry.get("force_z_pos", false) && eye_relief_raw is Vector2:
		lens_distance = eye_relief.x
		optic_aim_z = lens_local.z - eye_relief.x
	else:
		optic_aim_z = rig.data.aimPosition.z + 0.075
		lens_distance = lens_local.z - optic_aim_z

	var slack: float = 0.03
	var shadow: float = 0.0
	if lens_distance < eye_relief.x:
		shadow = clampf((eye_relief.x - lens_distance) / slack, 0.0, 1.0)
	elif lens_distance > eye_relief.y:
		shadow = clampf((lens_distance - eye_relief.y) / slack, 0.0, 1.0)

	var angle: float = 2.0 * atan(lens_radius / lens_distance) if (lens_radius > 0.0 && lens_distance > 0.0) else 0.0

	rig.set_meta("lensDistance", lens_distance)
	rig.set_meta("opticAimZ", optic_aim_z)
	rig.set_meta("scopeShadow", shadow)
	rig.set_meta("opticAngle", angle)
	rig.set_meta("opticIsFFP", entry.get("isFFP", false))


static func _ensure_lens_geometry(optic, key: String) -> Dictionary:
	if _lens_geometry_cache.has(key):
		return _lens_geometry_cache[key]
	var result := {"center": Vector3.ZERO, "radius": 0.0}
	if optic.mesh == null || optic.mesh.mesh == null:
		return result
	var arrays = optic.mesh.mesh.surface_get_arrays(optic.maskIndex)
	if arrays.is_empty():
		return result
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return result
	var t = optic.mesh.transform
	var sum := Vector3.ZERO
	for v in verts:
		sum += t * v
	var center: Vector3 = sum / verts.size()
	var max_r_sq: float = 0.0
	for v in verts:
		var p = t * v
		var dx: float = p.x - center.x
		var dy: float = p.y - center.y
		var r_sq: float = dx * dx + dy * dy
		if r_sq > max_r_sq:
			max_r_sq = r_sq
	result["center"] = center
	result["radius"] = sqrt(max_r_sq)
	_lens_geometry_cache[key] = result
	Out.debug("extracted lens geometry for", key, "center:", center, "radius:", result["radius"])
	return result


static func apply(lib) -> void:
	var attData = load("res://Scripts/AttachmentData.gd").new()

	for file in DATA:
		var fields := {}
		for key in DATA[file]:
			if key in attData:
				fields[key] = DATA[file][key]

		if "display" in fields:
			fields["inventory"] = fields["display"]
			fields["equipment"] = fields["display"]
			fields["rotated"] = fields["display"]

		if !fields.is_empty():
			lib.patch(lib.Registry.ITEMS, file, fields)
