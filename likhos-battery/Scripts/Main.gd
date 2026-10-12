extends "../Lib/Main.gd"

const BatteryUtil := preload("./BatteryUtil.gd")
const Interface := preload("./Interface.gd")
const Context := preload("./Context.gd")
const Item := preload("./Item.gd")
const Loot := preload("./Loot.gd")
const Flashlight := preload("./Flashlight.gd")
const Laser := preload("./Laser.gd")
const Tooltip := preload("./Tooltip.gd")

var _interface
var _context
var _item
var _loot
var _flashlight
var _laser
var _tooltip


func setup(lib) -> void:
	lib.patch(lib.Registry.ITEMS, BatteryUtil.FILE, { "showCondition": true })
	BatteryUtil.data = lib.get_entry(lib.Registry.ITEMS, BatteryUtil.FILE)

	# Vanilla lasers have no charge. These three fields make one a battery powered device with a drain rate.
	for found: Dictionary in lib.find(lib.Registry.ITEMS, func(entry) -> bool: return entry is ItemData && entry.subtype == "Laser"):
		var laser: ItemData = found["entry"]
		var fields: Dictionary[String, Variant] = { "showCondition": true }
		if laser.power == ItemData.Power.None:
			fields["power"] = ItemData.Power.Medium
		lib.patch(lib.Registry.ITEMS, found["id"], fields)
		lib.append(lib.Registry.ITEMS, found["id"], "compatible", BatteryUtil.data)

	_interface = Interface.new(lib)
	_context = Context.new(lib)
	_item = Item.new(lib)
	_loot = Loot.new(lib)
	_flashlight = Flashlight.new(lib)
	_laser = Laser.new(lib)
	_tooltip = Tooltip.new(lib)

	register_hook("interface-charge", _interface.on_charge)
	register_hook("interface-hover-post", _interface.on_hover_post)
	register_hook("interface-contextremove", _interface.on_context_remove)
	register_hook("interface-create-pre", _interface.on_create_pre)
	register_hook("context-update-post", _context.on_update_post)
	register_hook("item-value", _item.on_value)
	register_hook("item-combine-post", _item.on_combine_post)
	register_hook("item-remove-pre", _item.on_remove_pre)
	register_hook("item-combineswap-pre", _item.on_combine_swap_pre)
	register_hook("lootcontainer-createloot-post", _loot.on_create_loot_post)
	register_hook("lootsimulation-spawnitems-post", _loot.on_spawn_items_post)
	register_hook("flashlight-activate-post", _flashlight.on_activate_post)
	register_hook("tooltip-update-post", _tooltip.on_update_post)
	register_hook("tooltip-reset-post", _tooltip.on_reset_post)
	# Later than VosTac's handler on the same hook, which switches the laser on in canted aim.
	# Running first would let a dead laser show for a frame.
	_hooks.append(lib.hook("laser-_process-post", _laser.on_process_post, 200) as int)
