extends "../Lib/Main.gd"

const Catalog = preload("./Catalog.gd")
const Tooltip = preload("./Tooltip.gd")


var _tooltip


func setup(lib) -> void:
	Catalog.apply(lib)

	_tooltip = Tooltip.new(lib)
	register_hook("tooltip-update-post", _tooltip.on_update_post)
