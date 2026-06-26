extends "../Lib/Main.gd"

const RadioHook = preload("./Hooks/Radio.gd")
const RadioBus = preload("./RadioBus.gd")

var _radio
var _static_enabled := true


func setup(lib) -> void:
	RadioBus.apply()
	_radio = RadioHook.new(lib, _static_enabled)
	register_hook("radio-interact", _radio.on_interact)
	register_hook("radio-updatetooltip-post", _radio.on_update_tooltip_post)


func create_config(config: ConfigFile) -> void:
	config.set_value("Category", "General", { "menu_pos": 0 })
	config.set_value("Bool", "static_enabled", {
		"name": "Radio static",
		"tooltip": "Play the radio hiss/static bed underneath the music",
		"default": true,
		"value": true,
		"menu_pos": 1,
		"category": "General"
	})


func load_config(config: ConfigFile) -> void:
	_static_enabled = bool(config.get_value("Bool", "static_enabled", {}).get("value", true))
