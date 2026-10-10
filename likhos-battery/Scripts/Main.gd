extends "../Lib/Main.gd"

const Battery := preload("./Battery.gd")
const Interface := preload("./Interface.gd")
const Context := preload("./Context.gd")
const Item := preload("./Item.gd")

var _interface
var _context
var _item


func setup(lib) -> void:
	lib.patch(lib.Registry.ITEMS, "Batteries", { "showCondition": true })

	var battery := Battery.new(lib)
	_interface = Interface.new(lib, battery)
	_context = Context.new(lib, battery)
	_item = Item.new(lib, battery)

	register_hook("interface-charge", _interface.on_charge)
	register_hook("interface-contextunload", _interface.on_context_unload)
	register_hook("context-update-post", _context.on_update_post)
	register_hook("item-value", _item.on_value)
