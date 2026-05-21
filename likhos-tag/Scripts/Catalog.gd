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
		"name": "Зенит ПОСП",
		"weight": 0.9,
	},
	"PU": {
		"display": "PU",
		"name": "ПУ 3.5x",
		"weight": 0.4,
	},
	"Vudu": {
		"display": "Vudu",
		"name": "EOTech Vudu 1-10x",
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
	"ANPEQ": {
		"display": "PEQ-15",
		"name": "ATPIAL AN/PEQ-15",
		"weight": 0.21
	},
	"Hybrid": {
		"display": ".46",
		"name": "SilencerCo Hybrid .46",
		"weight": 0.4,
	},
	"Monster": {
		"display": "Monster",
		"name": "SureFire SOCOM556 Monster",
		"weight": 0.5,
	},
	"Navy": {
		"display": "Navy",
		"name": "KAC Navy",
		"weight": 0.43,
	},
	"OZ5": {
		"display": "SAPL",
		"name": "Swiss Arms Pro Laser",
		"weight": 0.21,
	},
	"PBS": {
		"display": "PBS-1",
		"name": "ПБС-1",
		"weight": 0.62,
	},
	"PTN": {
		"display": "Putnik",
		"name": "Resilient Suppressors Putnik",
		"weight": 0.59,
	},
	"Rider": {
		"display": "Ryder",
		"name": "SureFire Ryder 9M-Ti",
		"weight": 0.31,
	},
	"Salvo": {
		"display": "SLV-12",
		"name": "SilencerCo Salvo 12",
		"weight": 0.97,
	},
	"SOCOM": {
		"display": "RC2",
		"name": "SureFire SOCOM556 RC2",
		"weight": 0.48,
	},
	"Thor": {
		"display": "Thor",
		"name": "AWC Thor PSR",
		"weight": 0.51,
	},
	"AK_12_Magazine": {
		"name": "AK-12 mag. [6Л34]",
		"weight": 0.19,
	},
	"AKM_Magazine": {
		"name": "AKM \"Banana\" [57-A-231]",
		"weight": 0.43,
	},
	"AKS_74U_Magazine": {
		"name": "AK-74 \"Bakelite\" [6Л20]",
		"weight": 0.23,
	},
	"KAR_21_223_Magazine": {
		"name": "Magpul PMAG Gen M3",
		"weight": 0.14
	},
	"KAR_21_308_Magazine": {
		"name": "Magpul PMAG LR/SR Gen M3",
		"weight": 0.18,
	},
	"RK_Magazine": {
		"name": "Sako RK-95 TP mag.",
		"weight": 0.17,
	},
	"STANAG_Magazine": {
		"name": "USGI STANAG mag.",
		"weight": 0.17,
	},
	"SVD_Magazine": {
		"name": "SVD \"Waffle\" [6Л18]",
		"weight": 0.21,
	},
	"VSS_Magazine": {
		"name": "VSS \"Plum\" [6Л24]",
		"weight": 0.18,
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
