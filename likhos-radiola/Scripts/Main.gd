extends "../Lib/Main.gd"

const Config = preload("./Config.gd")
const RadioHook = preload("./Hooks/Radio.gd")
const RadioBus = preload("./RadioBus.gd")

var _radio


func setup(lib) -> void:
	RadioBus.apply()
	_radio = RadioHook.new(lib)
	register_hook("radio-interact", _radio.on_interact)
	register_hook("radio-updatetooltip-post", _radio.on_update_tooltip_post)
	register_hook("radio-_physics_process-pre", _radio.on_physics_process_pre)


func get_config() -> Resource:
	return Config.instance
