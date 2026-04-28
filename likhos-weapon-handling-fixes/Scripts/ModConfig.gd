extends RefCounted

var McmHelpers = preload("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

var crosshair_style: String
var crosshair_color: Color

const MOD_ID = "likhos-weapon-handling-fixes"
const FILE_PATH = "user://MCM/likhos-weapon-handling-fixes"
const FILE_NAME = "config.ini"
const DEFAULT_CROSSHAIR_COLOR = Color(1.0, 0.4, 0.0, 0.65)
const DEFAULT_CROSSHAIR = "2dot"

func _init():
	var config = _create_config_template()

	var fullPath = FILE_PATH + "/" + FILE_NAME
	if !FileAccess.file_exists(fullPath):
		DirAccess.open("user://").make_dir(FILE_PATH)
		config.save(fullPath)
	else:
		McmHelpers.CheckConfigurationHasUpdated(MOD_ID, config, fullPath)
		config.load(fullPath)

	_apply_config(config)

	McmHelpers.RegisterConfiguration(
		MOD_ID,
		"Likho's Weapon Handling Fixes",
		FILE_PATH,
		"Likho's collection of game fixes and realism improvements",
		{
			FILE_NAME: _apply_config
		}
	)

func _apply_config(config: ConfigFile):
	crosshair_style = config.get_value("Dropdown", "crosshair", {}).get("value", DEFAULT_CROSSHAIR).substr(1)
	crosshair_color = config.get_value("Color", "crosshairColor", {}).get("value", DEFAULT_CROSSHAIR_COLOR)

func _create_config_template():
	var config := ConfigFile.new()

	config.set_value("Dropdown", "crosshair", {
		"name" = "Crosshair",
		"tooltip" = "Used for exploration only", # (picking up items and interacting with objects)",
		"default" = DEFAULT_CROSSHAIR,
		"value" = DEFAULT_CROSSHAIR,
		"options" = {
			"1off": "Off",
			"2dot": "Dot",
			"3seg-cross": "Segmented cross"
		}
	})

	config.set_value("Color", "crosshairColor", {
		"name" = "Crosshair Color",
		"tooltip" = "Crosshair Color",
		"default" = DEFAULT_CROSSHAIR_COLOR,
		"value" = DEFAULT_CROSSHAIR_COLOR
	})

	return config

