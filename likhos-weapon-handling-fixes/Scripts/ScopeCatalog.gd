const Out = preload("../Lib/Out.gd")
const ModConfig = preload("./ModConfig.gd")

const _EXTRA_FIELDS := ["mag_range", "default_mag_range", "isFFP", "lens_radius"]

const _DEFAULT_LPVO_MAG: Array[float] = [1.0, 3.0, 6.0]
const _DEFAULT_SCOPE_MAG: Array[float] = [4.0]
const _FALLBACK_MAG: Array[float] = [1.0]

const DATA := {
	"ACOG": {
		"mag_range": [4.0],
		"default_mag_range": _DEFAULT_SCOPE_MAG,
		"lens_radius": 0.0117,
		"display": "ACOG",
		"name": "Trijicon ACOG TA31",
		"weight": 0.45,
	},
	"HMR": {
		"mag_range": [4.0],
		"default_mag_range": _DEFAULT_SCOPE_MAG,
		"lens_radius": 0.017,
		"display": "HAMR",
		"name": "Leupold HAMR 4x",
		"weight": 0.4,
	},
	"POSP": {
		"mag_range": [2.0, 4.0, 6.0],
		"default_mag_range": _DEFAULT_SCOPE_MAG,
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
		"default_mag_range": _DEFAULT_SCOPE_MAG,
		"lens_radius": 0.0115,
		"weight": 0.75,
		"display": "PU",
		"name": "PU",
	},
	"Vudu": {
		"isFFP": true,
		"mag_range": [1.0, 5.0, 10.0],
		"default_mag_range": _DEFAULT_LPVO_MAG,
		"lens_radius": 0.020,
		"display": "Vudu",
		"name": "EOTech Vudu 1-10x FFP",
		"rarity": 2, # legendary
		"value": 2500,
		"weight": 0.8,
	},
	"Leopard": {
		"isFFP": true,
		"mag_range": [1.1, 4.5, 8.0],
		"default_mag_range": _DEFAULT_LPVO_MAG,
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


static func get_mag_range(key) -> Array:
	var entry = DATA.get(key, {})
	if ModConfig.real_scope_mag:
		return entry.get("mag_range", _FALLBACK_MAG)
	return entry.get("default_mag_range", entry.get("mag_range", _FALLBACK_MAG))


static func is_ffp(key) -> bool:
	return DATA.get(key, {}).get("isFFP", false)


static func get_lens_radius(key) -> float:
	return DATA.get(key, {}).get("lens_radius", 0.0)


static func apply(lib) -> void:
	for file in DATA:
		var fields := {}
		for key in DATA[file]:
			if !(key in _EXTRA_FIELDS):
				fields[key] = DATA[file][key]

		if "display" in fields:
			fields["inventory"] = fields["display"]
			fields["equipment"] = fields["display"]
			fields["rotated"] = fields["display"]

		if !fields.is_empty():
			lib.patch(lib.Registry.ITEMS, file, fields)
