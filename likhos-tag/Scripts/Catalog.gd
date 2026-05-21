extends RefCounted

const Out = preload("../Lib/Out.gd")

const DATA := {
	"ACOG": {
		"display": "ACOG",
		"name": "Trijicon ACOG TA31",
		"weight": 0.5,
	},
	"HMR": {
		"display": "HAMR",
		"name": "Leupold HAMR 4x",
		"weight": 0.5,
	},
	"POSP": {
		"name": "Зенит ПОСП 2-6х"
		"weight": 0.9,
	},
	"PU": {
		"display": "PU",
		"name": "ПУ 3.5x",
		"weight": 0.4,
	},
	"Vudu": {
		"display": "Vudu",
		"name": "EOTech Vudu",
		"weight": 0.75,
	},
	"Leopard": {
		"display": "Mark 8",
		"name": "Leupold Mark 8 CQBSS",
		"weight": 0.85,
	},
	"RMR": {
		"display": "RMR",
		"name": "Trijicon RMR",
		"weight": 0.035,
	},
	"EXPS": {
		"display": "EXPS",
		"name": "EOTech EXPS",
		"weight": 0.4,
	},
	"Kobra": {
		"display": "Kobra",
		"name": "Аксион ЭКП-8-16 \"Кобра\"",
		"weight": 0.4,
	},
	"Micro": {
		"display": "T2",
		"name": "Aimpoint T2",
		"weight": 0.2,
	},
	"MRO": {
		"display": "MRO",
		"name": "Trijicon MRO",
		"weight": 0.2,
	},
	"PRO": {
		"display": "PRO",
		"name": "Aimpoint PRO",
		"weight": 0.35,
	},
	"SRO": {
		"display": "SRO",
		"name": "Trijicon SRO",
		"weight": 0.045,
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
