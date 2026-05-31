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
	},
	"HMR": {
		"mag_range": [4.0],
		"eye_relief": Vector2(5.5, 8.0),
		"lens_radius": 0.017,
		"lens_center": Vector3(0.0, 0.0, -0.069),
	},
	"POSP": {
		"mag_range": [2.0, 3.5, 6.0],
		"mag_range_discrete": [2.0, 3.0, 4.0, 5.0, 6.0],
		"eye_relief": Vector2(6.5, 9.0),
		"lens_radius": 0.012,
		"lens_center": Vector3(0.0, 0.0, -0.078),
	},
	"PU": {
		"mag_range": [3.5],
		"eye_relief": Vector2(6.5, 8.5),
		"lens_radius": 0.0115,
		"lens_center": Vector3(0.0, 0.0, -0.081),
	},
	"Vudu": {
		"isFFP": true,
		"mag_range": [1.0, 3.2, 10.0],
		"mag_range_normalized": [1.0, 1.6, 2.5, 4.0, 6.3, 10.0],
		"mag_range_discrete": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
		"eye_relief": Vector2(6.5, 12.5),
		"lens_radius": 0.020,
		"lens_center": Vector3(0.0, 0.0, -0.131),
	},
	"Leopard": {
		"isFFP": true,
		"mag_range": [1.1, 3.0, 8.0],
		"mag_range_normalized": [1.1, 1.7, 2.8, 4.8, 8.0],
		"mag_range_discrete": [1.1, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
		"eye_relief": Vector2(7.0, 11.5),
		"lens_radius": 0.0185,
		"lens_center": Vector3(0.0, 0.0, -0.177),
	},
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


static func get_optic_geometry(optic) -> Dictionary:
	if !optic:
		return {"lens_center": Vector3.ZERO, "lens_radius": 0.0, "eye_relief": Vector2.ZERO, "isFFP": false}
	var key := String(optic.attachmentData.file)
	var entry: Dictionary = DATA.get(key, {})
	var eye_relief_raw = entry.get("eye_relief")
	var eye_relief: Vector2 = eye_relief_raw * 0.01 if eye_relief_raw is Vector2 else Vector2.ZERO

	var lens_center: Vector3 = entry.get("lens_center", Vector3.ZERO)
	var lens_radius: float = entry.get("lens_radius", 0.0)
	if lens_center == Vector3.ZERO || lens_radius <= 0.0:
		var geom = _ensure_lens_geometry(optic, key)
		if lens_center == Vector3.ZERO:
			lens_center = geom.center
		if lens_radius <= 0.0:
			lens_radius = geom.radius

	return {
		"lens_center": lens_center,
		"lens_radius": lens_radius,
		"eye_relief": eye_relief,
		"isFFP": entry.get("isFFP", false),
	}


static func compute_shadow(lens_distance: float, eye_relief: Vector2) -> float:
	var slack: float = 0.03
	if lens_distance < eye_relief.x:
		return clampf((eye_relief.x - lens_distance) / slack, 0.0, 1.0)
	elif lens_distance > eye_relief.y:
		return clampf((lens_distance - eye_relief.y) / slack, 0.0, 1.0)
	return 0.0


static func compute_angle(lens_radius: float, lens_distance: float) -> float:
	if lens_radius > 0.0 && lens_distance > 0.0:
		return 2.0 * atan(lens_radius / lens_distance)
	return 0.0


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
	lib.patch(lib.Registry.ITEMS, "HMR", {
		"rarity": 2, # legendary
		"value": 2000,
	})
	var posp = lib.get_entry(lib.Registry.ITEMS, "POSP")
	lib.patch(lib.Registry.ITEMS, "POSP", {
		"name": posp.name + " 2-6x",
		"scope": false,
		"variable": true,
		"reticleSize": Vector3(0.3, 0.3, 0.3), # default X is very small
		"reticleSizeP": Vector3(0.5, 0.5, 0.5), # default X is very small
	})
	lib.patch(lib.Registry.ITEMS, "Vudu", {
		"rarity": 2, # legendary
		"value": 3000,
		"reticleSizeP": Vector3(0.1, 0.3, 1.2), # default Z is too small
	})
	lib.patch(lib.Registry.ITEMS, "Leopard", {
		"reticleSizeP": Vector3(0.2, 0.4, 0.6), # default X is very small
	})
