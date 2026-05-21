extends RefCounted

const Out = preload("../Lib/Out.gd")

const DATA := {
	"ACOG": {
		"inventory": "ACOG",
		"name": "Trijicon ACOG TA31",
		"weight": 0.5,
	},
	"HMR": {
		"inventory": "HAMR",
		"name": "Leupold HAMR 4x",
		"weight": 0.5,
	},
	"POSP": {
		"name": "Зенит ПОСП",
		"weight": 0.9,
	},
	"PU": {
		"inventory": "PU",
		"name": "ПУ 3.5x",
		"weight": 0.4,
	},
	"Vudu": {
		"inventory": "Vudu",
		"name": "EOTech Vudu 1-10x",
		"weight": 0.75,
	},
	"Leopard": {
		"inventory": "Mark 8",
		"name": "Leupold Mark 8 CQBSS",
		"weight": 0.85,
	},
	"RMR": {
		"inventory": "RMR",
		"name": "Trijicon RMR",
		"weight": 0.035,
	},
	"EXPS": {
		"inventory": "EXPS",
		"name": "EOTech EXPS",
		"weight": 0.4,
	},
	"Kobra": {
		"inventory": "Kobra",
		"name": "Аксион ЭКП-8-16 \"Кобра\"",
		"weight": 0.4,
	},
	"Micro": {
		"inventory": "T2",
		"name": "Aimpoint T2",
		"weight": 0.2,
	},
	"MRO": {
		"inventory": "MRO",
		"name": "Trijicon MRO",
		"weight": 0.2,
	},
	"PRO": {
		"inventory": "PRO",
		"name": "Aimpoint PRO",
		"weight": 0.35,
	},
	"SRO": {
		"inventory": "SRO",
		"name": "Trijicon SRO",
		"weight": 0.045,
	},
	"ANPEQ": {
		"inventory": "PEQ-15",
		"name": "ATPIAL AN/PEQ-15",
		"weight": 0.21
	},
	"Hybrid": {
		"inventory": ".46",
		"name": "SilencerCo Hybrid .46",
		"weight": 0.4,
	},
	"Monster": {
		"inventory": "Monster",
		"name": "SureFire SOCOM556 Monster",
		"weight": 0.5,
	},
	"Navy": {
		"inventory": "Navy",
		"name": "KAC Navy",
		"weight": 0.43,
	},
	"OZ5": {
		"inventory": "SAPL",
		"name": "Swiss Arms Pro Laser",
		"weight": 0.21,
	},
	"PBS": {
		"inventory": "PBS-1",
		"name": "ПБС-1",
		"weight": 0.62,
	},
	"PTN": {
		"inventory": "Putnik",
		"name": "Resilient Suppressors Putnik",
		"weight": 0.59,
	},
	"Rider": {
		"inventory": "Ryder",
		"name": "SureFire Ryder 9M-Ti",
		"weight": 0.31,
	},
	"Salvo": {
		"inventory": "SLV-12",
		"name": "SilencerCo Salvo 12",
		"weight": 0.97,
	},
	"SOCOM": {
		"inventory": "RC2",
		"name": "SureFire SOCOM556 RC2",
		"weight": 0.48,
	},
	"Thor": {
		"inventory": "Thor",
		"name": "AWC Thor PSR",
		"weight": 0.51,
	},
	"AK_12_Magazine": {
		"name": "AK-12 mag. [6Л34]",
		"display": "AK-12 mag.",
		"weight": 0.19,
	},
	"AKM_Magazine": {
		"name": "AKM \"Banana\" [57-A-231]",
		"display": "AKM mag.",
		"weight": 0.43,
	},
	"AKS_74U_Magazine": {
		"name": "AK-74 \"Bakelite\" [6Л20]",
		"display": "AK-74 mag.",
		"weight": 0.23,
	},
	"KAR_21_223_Magazine": {
		"name": "Magpul PMAG M3 [MAG557]",
		"display": "PMAG",
		"weight": 0.14
	},
	"KAR_21_308_Magazine": {
		"name": "Magpul PMAG LR/SR M3 [MAG291]",
		"display": "PMAG LS/SR",
		"weight": 0.18,
		"defaultAmount": 20,
		"maxAmount": 20,
	},
	"RK_Magazine": {
		"name": "Sako RK-95 TP mag.",
		"display": "RK mag.",
		"weight": 0.17,
	},
	"STANAG_Magazine": {
		"name": "USGI STANAG mag.",
		"display": "USGI mag.",
		"weight": 0.17,
	},
	"SVD_Magazine": {
		"name": "SVD \"Waffle\" [6Л10]",
		"display": "SVD mag.",
		"weight": 0.21,
	},
	"VSS_Magazine": {
		"name": "VSS \"Plum\" [6Л24]",
		"display": "VSS mag.",
		"weight": 0.18,
	},
}


static func apply(lib) -> void:
	for file in DATA:
		var fields: Dictionary = DATA[file].duplicate()
		if "inventory" in fields:
			fields["rotated"] = fields["inventory"]
			fields["equipment"] = fields["inventory"]
			if !("display" in fields):
				fields["display"] = fields["inventory"]
			
		if !lib.patch(lib.Registry.ITEMS, file, fields):
			Out.warning("patch failed for %s" % file)
