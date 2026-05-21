extends RefCounted

const Out = preload("../Lib/Out.gd")

const DATA := {
	"ACOG": {
		"display": "ACOG",
		"name": "Trijicon ACOG TA31",
		"weight": 0.45,
	},
	"HMR": {
		"display": "HAMR",
		"name": "Leupold HAMR 4x",
		"weight": 0.4,
	},
	"POSP": {
		"weight": 0.9,
	},
	"PU": {
		"display": "PU",
		"name": "PU",
		"weight": 0.75,
	},
	"Vudu": {
		"display": "Vudu",
		"name": "EOTech Vudu 1-10x FFP",
		"weight": 0.8,
	},
	"Leopard": {
		"display": "Leupold",
		"name": "Leupold Mark 8 CQBSS",
		"weight": 0.85,
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
	},
}


static func apply(lib) -> void:
	for file in DATA:
		var fields: Dictionary = DATA[file].duplicate()
		if "display" in fields:
			fields["inventory"] = fields["display"]
			fields["equipment"] = fields["display"]
			fields["rotated"] = fields["display"]
		if !lib.patch(lib.Registry.ITEMS, file, fields):
			Out.warning("patch failed for %s" % file)
