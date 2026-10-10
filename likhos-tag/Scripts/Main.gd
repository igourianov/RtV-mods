extends "../Lib/Main.gd"

var LCM = load("res://mods/likhos-config-manager/Scripts/LCM.gd")
const Catalog = preload("./Catalog.gd")
const Tooltip = preload("./Tooltip.gd")
const Config = preload("./Config.gd")


var _tooltip


func setup(lib) -> void:
	if LCM:
		LCM.register_config(mod_id, mod_name, Config.instance)

	Catalog.apply(lib)

	_tooltip = Tooltip.new(lib)
	register_hook("tooltip-reset-post", _tooltip.on_reset_post)
	register_hook("tooltip-update-post", _tooltip.on_update_post)
