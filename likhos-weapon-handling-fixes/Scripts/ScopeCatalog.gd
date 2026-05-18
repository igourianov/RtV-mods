const Out = preload("../Lib/Out.gd")

const _SCOPE_FIELDS := ["magnification", "reticlePlane"]

const DATA := {
	"ACOG": {
		"magnification": [4.0],
		"display": "ACOG",
		"inventory": "ACOG",
		"equipment": "ACOG",
		"rotated": "ACOG",
		"name": "Trijicon ACOG TA31",
	},
	"HMR": {
		"magnification": [4.0],
		"display": "HAMR",
		"inventory": "HAMR",
		"equipment": "HAMR",
		"rotated": "HAMR",
		"name": "Leupold HAMR 4x",
	},
	"POSP": {
		"magnification": [4.0]
	},
	"PU": {
		"magnification": [3.5]
	},
	"Vudu": {
		"reticlePlane": &"FFP",
		"magnification": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
		"display": "Vudu",
		"inventory": "Vudu",
		"equipment": "Vudu",
		"rotated": "Vudu",
		"name": "EOTech Vudu 1-10x FFP",
		"rarity": 2, # legendary
		"value": 2500
	},
	"Leopard": {
		"reticlePlane": &"FFP",
		"magnification": [1.1, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
		"display": "Leupold",
		"inventory": "Leupold",
		"equipment": "Leupold",
		"rotated": "Leupold",
		"name": "Leupold Mark 8 CQBSS"
	}
}


static func get_mag_range(key) -> Array:
	return DATA.get(key, {}).get("magnification", [1.0])


static func apply(lib) -> void:
	for file in DATA:
		var fields := {}
		for key in DATA[file]:
			if !(key in _SCOPE_FIELDS):
				fields[key] = DATA[file][key]
		if !fields.is_empty():
			lib.patch(lib.Registry.ITEMS, file, fields)
