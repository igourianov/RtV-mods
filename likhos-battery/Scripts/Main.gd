extends "../Lib/Main.gd"

const BatteryUtil := preload("./BatteryUtil.gd")
const Config := preload("./Config.gd")
const OpticPower := preload("./OpticPower.gd")
const Interface := preload("./Interface.gd")
const Context := preload("./Context.gd")
const Item := preload("./Item.gd")
const Loot := preload("./Loot.gd")
const Flashlight := preload("./Flashlight.gd")
const NVG := preload("./NVG.gd")
const Laser := preload("./Laser.gd")
const Tooltip := preload("./Tooltip.gd")

var LCM = load("res://mods/likhos-config-manager/Scripts/LCM.gd")
var config := Config.instance

var _interface
var _context
var _item
var _loot
var _flashlight
var _nvg
var _laser
var _tooltip


func setup(lib) -> void:
	if is_instance_valid(LCM):
		LCM.register_config(mod_id, mod_name, config)

	lib.patch(lib.Registry.ITEMS, BatteryUtil.FILE, { "showCondition": true })
	BatteryUtil.data = lib.get_entry(lib.Registry.ITEMS, BatteryUtil.FILE)

	for found: Dictionary in lib.find(lib.Registry.ITEMS, func(entry) -> bool: return entry is ItemData && entry.subtype == "Laser"):
		_make_device(lib, found["id"], found["entry"], ItemData.Power.Medium)

	for file: String in OpticPower.SIGHTS:
		var sight := OpticPower.SIGHTS[file]
		# A fiber lit sight draws no power, so it stays the plain item vanilla ships.
		if sight == OpticPower.Sight.FIBER:
			continue
		var tier := BatteryUtil.POWER_DOT if sight == OpticPower.Sight.DOT else BatteryUtil.POWER_ILLUMINATION
		_make_device(lib, file, lib.get_entry(lib.Registry.ITEMS, file), tier)

	_interface = Interface.new(lib)
	_context = Context.new(lib)
	_item = Item.new(lib)
	_loot = Loot.new(lib)
	_flashlight = Flashlight.new(lib)
	_nvg = NVG.new(lib)
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
	register_hook("nvg-activate-post", _nvg.on_activate_post)
	register_hook("tooltip-update-post", _tooltip.on_update_post)
	register_hook("tooltip-reset-post", _tooltip.on_reset_post)
	# Later than VosTac's handler on the same hook, which switches the laser on in canted aim.
	# Running first would let a dead laser show for a frame.
	_hooks.append(lib.hook("laser-_process-post", _laser.on_process_post, 200) as int)

	register_action("reticle_illumination", "Reticle Illumination", create_key_input(KEY_Y))
	add_child(OpticPower.new())


# Vanilla lasers and sights have no charge. These three fields make one a battery powered device with a drain rate.
# An item that already has a power tier keeps it.
func _make_device(lib, id: String, item: ItemData, tier: int) -> void:
	var fields: Dictionary[String, Variant] = { "showCondition": true }
	if item.power == ItemData.Power.None:
		fields["power"] = tier
	lib.patch(lib.Registry.ITEMS, id, fields)
	lib.append(lib.Registry.ITEMS, id, "compatible", BatteryUtil.data)
