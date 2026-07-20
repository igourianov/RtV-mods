extends RefCounted

var McmHelpers := preload("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

var _probabilities: Dictionary = {}

const MOD_ID := "likhos-eventuality"
const FILE_PATH := "user://MCM/likhos-eventuality"
const FILE_NAME := "config.ini"
const PROB_MIN := 0.0
const PROB_MAX := 100.0

static var EVENTS := {
	"FighterJet": {"label": "Fighter Jets (Area 05)", "default": 25.0},
	"Police": {"label": "Punisher (Area 05)", "default": 10.0},
	"Airdrop": {"label": "Airdrops (Area 05)", "default": 10.0},
	"CrashSite": {"label": "Helicopter Crash Sites (any zone)", "default": 10.0},
	"BTR": {"label": "BTR Patrols (Vostok / Outpost map)", "default": 25.0},
	"Helicopter": {"label": "Attack Helicopters (Border Zone)", "default": 25.0}
}


func _init():
	var config: ConfigFile = _create_config_template()

	var fullPath := FILE_PATH + "/" + FILE_NAME
	if !FileAccess.file_exists(fullPath):
		DirAccess.open("user://").make_dir(FILE_PATH)
		config.save(fullPath)
	else:
		McmHelpers.CheckConfigurationHasUpdated(MOD_ID, config, fullPath)
		config.load(fullPath)

	_apply_config(config)

	McmHelpers.RegisterConfiguration(
		MOD_ID,
		"Likho's Eventuality",
		FILE_PATH,
		"Per-event probability overrides for dynamic events",
		{
			FILE_NAME: _apply_config
		}
	)


func _apply_config(config: ConfigFile):
	for cfgKey in EVENTS:
		var entry: Dictionary = EVENTS[cfgKey]
		_probabilities[cfgKey] = config.get_value("Float", cfgKey, {}).get("value", entry.default)


func _create_config_template():
	var config := ConfigFile.new()
	var pos := [0]
	var next_pos := func(): pos[0] += 1; return pos[0]

	config.set_value("Category", "Probabilities", { "menu_pos": 1 })

	for cfgKey in EVENTS:
		var entry: Dictionary = EVENTS[cfgKey]
		config.set_value("Float", cfgKey, {
			"name": entry.label,
			"default": entry.default,
			"value": entry.default,
			"minRange": PROB_MIN,
			"maxRange": PROB_MAX,
			"menu_pos": next_pos.call(),
			"category": "Probabilities"
		})

	return config


func get_probability(function_name: String, fallback: float) -> float:
	return _probabilities.get(function_name, fallback)
