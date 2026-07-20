extends "../Lib/Main.gd"

const Interface := preload("./Interface.gd")
const ItemData := preload("res://Scripts/ItemData.gd")
const AFAK := preload("../Recipes/AFAK.tres")

var _interface: Node


func setup(lib) -> void:
	_patch_items(lib)
	_register_recipes(lib)

	_interface = Interface.new(lib)
	add_child(_interface)

	register_hook("interface-use", _interface.on_use)
	register_hook("interface-release-pre", _interface.on_release_pre)

	register_action("tacmed", "IFAK/AFAK", create_key_input(KEY_Z))
	register_action("hurt_myself", "", create_key_input(KEY_O, true, true))
	register_action("hurt_myself_more", "", create_key_input(KEY_P, true, true))


func _patch_items(lib) -> void:
	var compatible: Array[ItemData] = [
		lib.get_entry(lib.Registry.ITEMS, "Bandage"),
		lib.get_entry(lib.Registry.ITEMS, "Bandage_Improvised"),
		lib.get_entry(lib.Registry.ITEMS, "Painkillers"),
		lib.get_entry(lib.Registry.ITEMS, "Antibiotics"),
		lib.get_entry(lib.Registry.ITEMS, "Cold_Medicine"),
		lib.get_entry(lib.Registry.ITEMS, "Tourniquet"),
		lib.get_entry(lib.Registry.ITEMS, "Tourniquet_Improvised"),
		lib.get_entry(lib.Registry.ITEMS, "Balm"),
		lib.get_entry(lib.Registry.ITEMS, "Lotion")
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

	lib.patch(lib.Registry.ITEMS, "AFAK", {
		"showCondition": true,
		"value": 5000,
		"weight": 5.0,
		"health": 200.0,
		"energy": 0.0,
		"hydration": 0.0,
		"mental": 0.0,
		"temperature": 0.0,
		"insanity": false,
		"doctor": true,
		"repairs": true
	})


func _register_recipes(lib):
	lib.register(lib.Registry.RECIPES, "tacmed_AFAK", {
		"recipe": AFAK,
		"category": "medical",
	})