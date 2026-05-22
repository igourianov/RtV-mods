extends RefCounted

const Out = preload("../Lib/Out.gd")
const ModConfig = preload("./ModConfig.gd")

const EXTRAS := ["grau_index", "model"]
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
		"name": ["BelOMO POSP", "БелОМО ПОСП"],
		"weight": 0.9,
	},
	"PU": {
		"inventory": "PU",
		"name": ["PU 3.5x", "ПУ 3.5x"],
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
		"name": ["Axion \"Kobra\"", "Аксион \"Кобра\""],
		"model": ["EKP-8-18", "ЭКП-8-18"],
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
		"name": "L3 Insight AN/PEQ-15",
		"weight": 0.21
	},
	"Hybrid": {
		"inventory": ".46",
		"name": "SilencerCo Hybrid 46",
		"weight": 0.4,
	},
	"Monster": {
		"inventory": "Monster",
		"name": "SureFire SOCOM556 Monster",
		"weight": 0.5,
	},
	"Navy": {
		"inventory": "Navy",
		"name": "KAC MP5-N Suppressor",
		"weight": 0.43,
	},
	"OZ5": {
		"inventory": "SAPL",
		"name": "Swiss Arms Pro Laser",
		"weight": 0.21,
	},
	"PBS": {
		"inventory": "PBS-1",
		"name": ["PBS-1", "ПБС-1"],
		"grau_index": "6Ч12",
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
	"AK_12": {
		"name": ["AK-12 Gen 1", "АК-12 Gen 1"],
		"grau_index": "6П70",
		"inventory": "AK-12",
	},
	"AKM": {
		"name": ["AKM \"Kalash\"", "АКМ \"Калаш\""],
		"grau_index": "6П1",
		"inventory": "AKM",
		"weight": 3.1,
	},
	"AKS_74U": {
		"name": ["AKS-74U", "АКС-74У"],
		"grau_index": "6П26",
		"inventory": "AKS-74U",
		"weight": 2.7,
	},
	"Colt_1911": {
		"name": "Colt 1911",
		"inventory": "1911",
	},
	"Glock_17": {
		"name": "Glock 17",
		"inventory": "G17",
	},
	"HK416": {
		"name": "H&K 416",
		"inventory": "HK416",
		"weight": 3.5,
	},
	"KAR_21_223": {
		"name": "KAR-21 .223",
		"inventory": "KAR-21-223",
	},
	"KAR_21_308": {
		"name": "KAR-21 .308",
		"inventory": "KAR-21-308",
	},
	"KP_31": {
		"name": "Suomi KP-31",
		"inventory": "KP-31",
	},
	"M4A1": {
		"name": "Colt M4A1",
		"inventory": "M4A1",
		"weight": 3.3,
	},
	"M78": {
		"name": "Valmet M78",
		"inventory": "Valmet",
		"weight": 5.0,
	},
	"Makarov": {
		"name": ["PM", "ПМ"],
		"grau_index": "56-А-125",
		"inventory": "PM",
	},
	"MK18": {
		"name": "Mk 18 Mod 1",
		"inventory": "MK18",
	},
	"Mosin": {
		"name": ["Mosin-Nagant M1891", "Трёхлинейка 1891/30"],
		"inventory": "Mosin",
	},
	"MP5": {
		"name": "H&K MP5A3",
		"inventory": "MP5",
		"weight": 3.1,
	},
	"MP5K": {
		"name": "H&K MP5K",
		"inventory": "MP5K",
	},
	"MP5SD": {
		"name": "H&K MP5SD",
		"inventory": "MP5SD",
		"weight": 3.4,
	},
	"MP7": {
		"name": "H&K MP7",
		"inventory": "MP7",
		"weight": 2.0,
	},
	"P320": {
		"name": "SIG Sauer P320",
		"inventory": "P320",
	},
	"Remington_870": {
		"name": "Remington 870 Police Magnum",
		"inventory": "870",
		"weight": 3.2,
	},
	"RK_62": {
		"name": "Valmet RK-62",
		"inventory": "RK-62",
		"weight": 3.5,
	},
	"RK_62M": {
		"name": "Millog RK-62M3",
		"inventory": "RK-62M3",
		"weight": 4.1,
	},
	"RK_95": {
		"name": "Sako RK-95 TP",
		"inventory": "RK-95",
		"weight": 3.7,
	},
	"SVD": {
		"name": ["SVD \"Dragunov\"", "СВД \"Драгунов\""],
		"grau_index": "6В1",
		"inventory": "SVD",
		"weight": 3.7,
	},
	"VSS": {
		"name": ["VSS \"Vintorez\"", "ВСС \"Винторез\""],
		"grau_index": "6П29",
		"inventory": "VSS",
		"weight": 1.8,
	},
	"AK_12_Magazine": {
		"name": "AK-12 mag",
		"grau_index": "6Л34",
		"display": "AK-12 mag",
		"weight": 0.19,
	},
	"AKM_Magazine": {
		"name": "AKM \"Banana\"",
		"grau_index": "57-A-231",
		"display": "AKM mag",
		"weight": 0.43,
	},
	"AKS_74U_Magazine": {
		"name": "AK-74 \"Bakelite\"",
		"grau_index": "6Л23",
		"display": "AK-74 mag",
		"weight": 0.23,
	},
	"Colt_1911_Magazine": {
		"name": "Colt 1911 mag",
		"display": "1911 mag",
		"weight": 0.08,
	},
	"Glock_17_Magazine": {
		"name": "Glock mag",
		"display": "Glock mag",
		"weight": 0.08,
	},
	"KAR_21_223_Magazine": {
		"name": "Magpul PMAG M3",
		"model": "MAG557",
		"display": "PMAG",
		"weight": 0.14
	},
	"KAR_21_308_Magazine": {
		"name": "Magpul PMAG LR/SR M3",
		"model": "MAG291",
		"display": "PMAG 308",
		"weight": 0.18,
		"defaultAmount": 20,
		"maxAmount": 20,
	},
	"KP_31_Drum": {
		"name": "KP-31 Drum",
		"display": "KP-31 Drum",
		"weight": 1.1,
	},
	"M78_Magazine": {
		"name": "M78 mag",
		"display": "M78 mag",
		"weight": 0.3,
	},
	"Makarov_Magazine": {
		"name": "PM mag",
		"display": "PM mag",
		"weight": 0.05,
	},
	"MP5_Magazine": {
		"name": "MP5 mag",
		"display": "MP5 mag",
		"weight": 0.18,
	},
	"MP7_Magazine": {
		"name": "MP7 mag",
		"display": "MP7 mag",
		"weight": 0.1,
		"defaultAmount": 40,
		"maxAmount": 40,
	},
	"P320_Magazine": {
		"name": "P320 mag",
		"display": "P320 mag",
		"weight": 0.075,
	},
	"RK_Magazine": {
		"name": "Sako RK mag",
		"display": "RK mag",
		"weight": 0.17,
	},
	"STANAG_Magazine": {
		"name": "USGI STANAG mag",
		"display": "USGI mag",
		"weight": 0.17,
	},
	"SVD_Magazine": {
		"name": "SVD \"Waffle\"",
		"grau_index": "6Л10",
		"display": "SVD mag",
		"weight": 0.21,
	},
	"VSS_Magazine": {
		"name": "VSS \"Plum\"",
		"grau_index": "6Л24",
		"display": "VSS mag",
		"weight": 0.18,
	},
}


static func apply(lib) -> void:
	var idx = 0 if ModConfig.force_english_names else 1
	for file in DATA:
		var fields := {}
		for key in DATA[file]:
			if !(key in EXTRAS):
				var value = DATA[file][key]
				fields[key] = value[idx] if value is Array else value

		if "inventory" in fields:
			var inv: String = fields["inventory"]
			if !("rotated" in fields):
				fields["rotated"] = inv
			if !("display" in fields):
				fields["display"] = inv
			if !("equipment" in fields):
				fields["equipment"] = inv

		if !lib.patch(lib.Registry.ITEMS, file, fields):
			Out.warning("patch failed for %s" % file)
