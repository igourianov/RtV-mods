extends "../Lib/Main.gd"

const BatteryUtil := preload("./BatteryUtil.gd")
const Interface := preload("./Interface.gd")
const Context := preload("./Context.gd")
const Item := preload("./Item.gd")

var _interface
var _context
var _item


func setup(lib) -> void:
	lib.patch(lib.Registry.ITEMS, BatteryUtil.FILE, { "showCondition": true })
	BatteryUtil.data = lib.get_entry(lib.Registry.ITEMS, BatteryUtil.FILE)

	_interface = Interface.new(lib)
	_context = Context.new(lib)
	_item = Item.new(lib)

	register_hook("interface-charge", _interface.on_charge)
	register_hook("interface-contextremove", _interface.on_context_remove)
	register_hook("context-update-post", _context.on_update_post)
	register_hook("item-value", _item.on_value)
