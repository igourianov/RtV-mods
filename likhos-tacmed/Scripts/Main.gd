extends "../Lib/Main.gd"

const Interface = preload("./Interface.gd")
const ItemData = preload("res://Scripts/ItemData.gd")

var _interface


func setup(lib) -> void:
	_patch_items(lib)

	_interface = Interface.new(lib)
	add_child(_interface)

	register_hook("interface-use", _interface.on_use)
	register_hook("interface-combine", _interface.on_combine)
	register_hook("interface-hover-post", _interface.on_hover_post)


func _patch_items(lib) -> void:
	var compatible: Array[ItemData] = [
		lib.get_entry(lib.Registry.ITEMS, "Bandage"),
		lib.get_entry(lib.Registry.ITEMS, "Bandage_Improvised"),
		lib.get_entry(lib.Registry.ITEMS, "Painkillers"),
		lib.get_entry(lib.Registry.ITEMS, "Antibiotics"),
		lib.get_entry(lib.Registry.ITEMS, "Cold_Medicine"),
		lib.get_entry(lib.Registry.ITEMS, "Tourniquet"),
		lib.get_entry(lib.Registry.ITEMS, "Tourniquet_Improvised")
	]
	lib.patch(lib.Registry.ITEMS, "IFAK", {
		"showCondition": true,
		"compatible": compatible,
		"value": 1000,
		"weight": 2.0,
		"health": 150.0,
		"fracture": false,
		"rupture": false,
		"headshot": false,
		"doctor": true
	})