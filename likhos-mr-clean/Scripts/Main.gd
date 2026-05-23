extends "../Lib/Main.gd"

const Interface = preload("./Interface.gd")
const ItemData = preload("res://Scripts/ItemData.gd")

const WRK_ID := "Weapon_Repair_Kit"
const RECIPES_PATH := "res://Crafting/Recipes.tres"

var _interface


func setup(lib) -> void:
	_strip_repair_recipes()
	_patch_wrk(lib)

	_interface = Interface.new(lib)

	register_hook("interface-release-pre", _interface.on_release_pre)


func _strip_repair_recipes() -> void:
	var recipes = load(RECIPES_PATH)
	if !recipes || !("weapons" in recipes):
		Out.warning("Recipes.tres unavailable, cannot strip repair recipes")
		return

	var weapons = recipes.weapons
	var removed: int = 0
	for i in range(weapons.size() - 1, -1, -1):
		var r = weapons[i]
		if r && r.get("repair"):
			weapons.remove_at(i)
			removed += 1

	Out.debug("stripped %d weapon repair recipes" % removed)


func _patch_wrk(lib) -> void:
	var matches: Array = lib.find(lib.Registry.ITEMS, func(it): return it.get("type") == "Weapon")
	var compatible: Array[ItemData] = []
	for m in matches:
		compatible.append(m.entry)
	Out.debug("found %d weapons for WRK compatibility" % compatible.size())

	lib.patch(lib.Registry.ITEMS, WRK_ID, {
		"name": "Weapon Cleaning Kit",
		"inventory": "Weapon Cleaning Kit",
		"rotated": "Cleaning Kit",
		"equipment": "Cleaning Kit",
		"display": "Cleaning Kit",
		"showCondition": true,
		"compatible": compatible,
	})
