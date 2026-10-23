extends "../Lib/Main.gd"

const Interface = preload("./Interface.gd")
const ItemData = preload("res://Scripts/ItemData.gd")
const CleaningKitRefill = preload("../Recipes/Cleaning_Kit_Refill.tres")

const WRK_ID := "Weapon_Repair_Kit"
const RECIPES_PATH := "res://Crafting/Recipes.tres"

var _interface


func setup(lib) -> void:
	_patch_wrk(lib)
	localize_pickup_slotdata(WRK_ID)

	lib.register(lib.Registry.RECIPES, "likhos_cleaning_kit_refill", {
		"recipe": CleaningKitRefill,
		"category": "weapons",
	})

	_strip_repair_recipes()

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
		# The refill recipe is also repair=true and must survive.
		if r && r.repair && r != CleaningKitRefill:
			weapons.remove_at(i)
			removed += 1

	Out.debug("stripped %d weapon repair recipes" % removed)


func _patch_wrk(lib) -> void:
	var compatible: Array[ItemData] = []
	compatible.assign(lib.find(lib.Registry.ITEMS, func(it): return it.type == "Weapon").map(func(m): return m.entry))

	Out.debug("found %d weapons for WRK compatibility" % compatible.size())

	lib.patch(lib.Registry.ITEMS, WRK_ID, {
		"name": "Likho's No.9 Cleaning Kit",
		"inventory": "Cleaning Kit",
		"rotated": "Cleaning Kit",
		"equipment": "Cleaning Kit",
		"display": "C. Kit",
		"showCondition": true,
		"compatible": compatible,
		"repairs": true,
	})
