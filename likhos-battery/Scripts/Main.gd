extends "../Lib/Main.gd"

const BatteryUtil := preload("./BatteryUtil.gd")
const Interface := preload("./Interface.gd")
const Context := preload("./Context.gd")
const Item := preload("./Item.gd")
const Loot := preload("./Loot.gd")

var _interface
var _context
var _item
var _loot


func setup(lib) -> void:
	lib.patch(lib.Registry.ITEMS, BatteryUtil.FILE, { "showCondition": true })
	BatteryUtil.data = lib.get_entry(lib.Registry.ITEMS, BatteryUtil.FILE)

	_interface = Interface.new(lib)
	_context = Context.new(lib)
	_item = Item.new(lib)
	_loot = Loot.new(lib)

	register_hook("interface-charge", _interface.on_charge)
	register_hook("interface-contextremove", _interface.on_context_remove)
	register_hook("context-update-post", _context.on_update_post)
	register_hook("item-value", _item.on_value)
	register_hook("lootcontainer-createloot-post", _loot.on_create_loot_post)
	register_hook("lootsimulation-spawnitems-post", _loot.on_spawn_items_post)
