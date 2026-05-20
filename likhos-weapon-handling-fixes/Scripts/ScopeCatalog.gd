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


static func is_ffp(key: String) -> bool:
	return DATA.get(key, {}).get("isFFP", false)


static func get_fixed_z(key: String):
	var entry: Dictionary = DATA.get(key, {})
	if entry.get("force_z_pos", false) && entry.get("eye_relief") is Vector2:
		return entry.eye_relief.x / 100.0
	return null


static func get_eye_relief(key: String) -> Vector2:
	var er = DATA.get(key, {}).get("eye_relief", null)
	if !(er is Vector2):
		return Vector2.ZERO
	return er * 0.01


static func get_lens_radius(optic) -> float:
	var key := String(optic.attachmentData.file)
	var radius: float = DATA.get(key, {}).get("lens_radius", 0.0)
	if radius > 0.0:
		return radius
	return _ensure_lens_geometry(optic, key).get("radius", 0.0)


static func get_lens_center(optic) -> Vector3:
	var key := String(optic.attachmentData.file)
	var center = DATA.get(key, {}).get("lens_center", null)
	if center is Vector3:
		return center
	return _ensure_lens_geometry(optic, key).get("center", Vector3.ZERO)


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
