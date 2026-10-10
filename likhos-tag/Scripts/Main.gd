extends "../Lib/Main.gd"

const Catalog = preload("./Catalog.gd")
const Tooltip = preload("./Tooltip.gd")
const Config = preload("./Config.gd")


var _tooltip


func get_config() -> Resource:
	return Config.instance


func setup(lib) -> void:
	Catalog.apply(lib)

	_tooltip = Tooltip.new(lib)
	register_hook("tooltip-reset-post", _tooltip.on_reset_post)
	register_hook("tooltip-update-post", _tooltip.on_update_post)
