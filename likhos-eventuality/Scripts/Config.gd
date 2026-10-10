extends RefCounted

const Out = preload("../Lib/Out.gd")

var _probabilities: Dictionary = {}

const PROB_MIN := 0.0
const PROB_MAX := 100.0

static var EVENTS := {
	"FighterJet": {"label": "Fighter Jets (Area 05)", "default": 25.0},
	"Police": {"label": "Punisher (Area 05)", "default": 10.0},
	"Airdrop": {"label": "Airdrops (Area 05)", "default": 10.0},
	"CrashSite": {"label": "Helicopter Crash Sites (any zone)", "default": 10.0},
	"BTR": {"label": "BTR Patrols (Vostok / Outpost map)", "default": 25.0},
	"Helicopter": {"label": "Attack Helicopters (Border Zone)", "default": 25.0},
	"Bogeyman": {"label": "Bogeyman (Area 05, night only)", "default": 10.0}
}


func apply_config(config: ConfigFile) -> void:
	Out.debug_enabled = config.get_value("Bool", "debug_enabled", {}).get("value", false)
	for cfgKey in EVENTS:
		var entry: Dictionary = EVENTS[cfgKey]
		_probabilities[cfgKey] = config.get_value("Float", cfgKey, {}).get("value", entry.default)


func create_template(config: ConfigFile) -> void:
	var pos := [0]
	var next_pos := func(): pos[0] += 1; return pos[0]

	config.set_value("Category", "General", { "menu_pos": 0 })
	config.set_value("Category", "Probabilities", { "menu_pos": 1 })

	config.set_value("Bool", "debug_enabled", {
		"name": "Debug",
		"tooltip": "Writing this mod's debug into stdout",
		"default": false,
		"value": false,
		"menu_pos": next_pos.call(),
		"category": "General"
	})

	for cfgKey in EVENTS:
		var entry: Dictionary = EVENTS[cfgKey]
		config.set_value("Float", cfgKey, {
			"name": entry.label,
			"tooltip": "",
			"default": entry.default,
			"value": entry.default,
			"minRange": PROB_MIN,
			"maxRange": PROB_MAX,
			"menu_pos": next_pos.call(),
			"category": "Probabilities"
		})


func get_probability(function_name: String, fallback: float) -> float:
	return _probabilities.get(function_name, fallback)
