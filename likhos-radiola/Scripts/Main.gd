extends "../Lib/Main.gd"

const ModConfig = preload("./ModConfig.gd")
const RadioHook = preload("./Hooks/Radio.gd")
const RadioBus = preload("./RadioBus.gd")

var _radio


func setup(lib) -> void:
	RadioBus.apply()
	_radio = RadioHook.new(lib)
	register_hook("radio-interact", _radio.on_interact)
	register_hook("radio-updatetooltip-post", _radio.on_update_tooltip_post)


func create_config(config: ConfigFile) -> void:
	ModConfig.create_template(config)


func load_config(config: ConfigFile) -> void:
	ModConfig.apply_config(config)
