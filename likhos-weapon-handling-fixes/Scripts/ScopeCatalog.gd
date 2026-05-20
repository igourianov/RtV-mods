const Out = preload("../Lib/Out.gd")
const ModConfig = preload("./ModConfig.gd")

const _FALLBACK_MAG: Array[float] = [1.0]

const DATA := {
	"ACOG": {
		"mag_range": [4.0],
		"eye_relief": Vector2(2.5, 4.5),
		"lens_radius": 0.0117,
		"display": "ACOG",
		"name": "Trijicon ACOG TA31",
		"weight": 0.45,
	},
	"HMR": {
		"mag_range": [4.0],
		"eye_relief": Vector2(5.5, 8.0),
		"lens_radius": 0.017,
		"display": "HAMR",
		"name": "Leupold HAMR 4x",
		"weight": 0.4,
	},
	"POSP": {
		"mag_range": [2.0, 3.5, 6.0],
		"mag_range_discrete": [2.0, 3.0, 4.0, 5.0, 6.0],
		"eye_relief": Vector2(6.5, 9.0),
		"lens_radius": 0.012,
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
		"lens_radius": 0.0115,
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


static func get_lens_radius(key: String) -> float:
	return DATA.get(key, {}).get("lens_radius", 0.0)


static func get_eye_relief(key: String) -> Vector2:
	var er = DATA.get(key, {}).get("eye_relief", null)
	if !(er is Vector2):
		return Vector2.ZERO
	return er * 0.01


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
