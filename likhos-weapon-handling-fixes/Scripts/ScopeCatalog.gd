const Out = preload("../Lib/Out.gd")
const ModConfig = preload("./ModConfig.gd")

const _EXTRA_FIELDS := ["mag_range", "default_mag_range", "reticlePlane"]

const _DEFAULT_LPVO_MAG: Array[float] = [1.0, 3.0, 6.0]
const _DEFAULT_SCOPE_MAG: Array[float] = [4.0]
const _FALLBACK_MAG: Array[float] = [1.0]

const DATA := {
	"ACOG": {
		"mag_range": [4.0],
		"default_mag_range": _DEFAULT_SCOPE_MAG,
		"display": "ACOG",
		"inventory": "ACOG",
		"equipment": "ACOG",
		"rotated": "ACOG",
		"name": "Trijicon ACOG TA31",
		"weight": 0.45,
	},
	"HMR": {
		"mag_range": [4.0],
		"default_mag_range": _DEFAULT_SCOPE_MAG,
		"display": "HAMR",
		"inventory": "HAMR",
		"equipment": "HAMR",
		"rotated": "HAMR",
		"name": "Leupold HAMR 4x",
		"weight": 0.4,
	},
	"POSP": {
		"mag_range": [2.0, 3.0, 4.0, 5.0, 6.0],
		"default_mag_range": _DEFAULT_SCOPE_MAG,
		"scope": false,
		"variable": true,
		"weight": 0.9,
		"name": "POSP 2-6x",
	},
	"PU": {
		"mag_range": [3.5],
		"default_mag_range": _DEFAULT_SCOPE_MAG,
		"weight": 0.75,
		"display": "PU",
		"inventory": "PU",
		"equipment": "PU",
		"rotated": "PU",
		"name": "PU",
	},
	"Vudu": {
		"reticlePlane": &"FFP",
		"mag_range": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
		"default_mag_range": _DEFAULT_LPVO_MAG,
		"display": "Vudu",
		"inventory": "Vudu",
		"equipment": "Vudu",
		"rotated": "Vudu",
		"name": "EOTech Vudu 1-10x FFP",
		"rarity": 2, # legendary
		"value": 2500,
		"weight": 0.8,
	},
	"Leopard": {
		"reticlePlane": &"FFP",
		"mag_range": [1.1, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
		"default_mag_range": _DEFAULT_LPVO_MAG,
		"display": "Leupold",
		"inventory": "Leupold",
		"equipment": "Leupold",
		"rotated": "Leupold",
		"name": "Leupold Mark 8 CQBSS",
		"weight": 0.85,
	}
}


static func get_mag_range(key) -> Array:
	var entry = DATA.get(key, {})
	if ModConfig.real_scope_mag:
		return entry.get("mag_range", _FALLBACK_MAG)
	return entry.get("default_mag_range", entry.get("mag_range", _FALLBACK_MAG))


static func apply(lib) -> void:
	for file in DATA:
		var fields := {}
		for key in DATA[file]:
			if !(key in _EXTRA_FIELDS):
				fields[key] = DATA[file][key]
		if !fields.is_empty():
			lib.patch(lib.Registry.ITEMS, file, fields)
