extends "../Lib/Main.gd"

const Interface = preload("./Interface.gd")
const ItemData = preload("res://Scripts/ItemData.gd")
const CleaningKitRefill = preload("../Recipes/Cleaning_Kit_Refill.tres")

const WRK_ID := "Weapon_Repair_Kit"
const RECIPES_PATH := "res://Crafting/Recipes.tres"
const ICON_PATH := "res://mods/likhos-mr-clean/Assets/Cleaning_kit.png"
const TETRIS_PATH := "res://Items/Misc/Weapon_Repair_Kit/Weapon_Repair_Kit_3x2.tscn"

var _interface


func setup(lib) -> void:
	_strip_repair_recipes()
	_patch_wrk(lib)
	_localize_wrk_slotdata()

	lib.register(lib.Registry.RECIPES, "likhos_cleaning_kit_refill", {
		"recipe": CleaningKitRefill,
		"category": "weapons",
	})

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
		if r && r.repair:
			weapons.remove_at(i)
			removed += 1

	Out.debug("stripped %d weapon repair recipes" % removed)


func _patch_wrk(lib) -> void:
	var matches: Array = lib.find(lib.Registry.ITEMS, func(it): return it.get("type") == "Weapon")
	var compatible: Array[ItemData] = []
	for m in matches:
		compatible.append(m.entry)
	Out.debug("found %d weapons for WRK compatibility" % compatible.size())

	var icon: ImageTexture = ImageTexture.create_from_image(Image.load_from_file(ICON_PATH))
	lib.patch(lib.Registry.ITEMS, WRK_ID, {
		"name": "Likho's No.9 Gun Cleaning Kit",
		"inventory": "Cleaning Kit",
		"rotated": "Cleaning Kit",
		"equipment": "Cleaning Kit",
		"display": "C. Kit",
		"showCondition": true,
		"compatible": compatible,
		"icon": icon,
		"tetris": _rebuild_tetris(TETRIS_PATH, icon),
		"repairs": true,
	})


func _localize_wrk_slotdata() -> void:
	var scene: PackedScene = Database.get(WRK_ID)
	if !scene:
		Out.warning("Weapon_Repair_Kit scene unavailable, cannot fix shared slotData")
		return

	var probe = scene.instantiate()
	if !probe.slotData:
		Out.warning("Weapon_Repair_Kit pickup has no slotData, cannot fix sharing")
		probe.queue_free()
		return

	probe.slotData.resource_local_to_scene = true
	probe.queue_free()


func _rebuild_tetris(tetris:String, icon: ImageTexture) -> PackedScene:
	var src: PackedScene = load(tetris)
	if !src:
		Out.warning("failed to load tetris scene from %s" % tetris)
		return null

	var inst := src.instantiate()
	var sprite := _find_sprite(inst)
	if !sprite:
		Out.warning("no Sprite2D in tetris scene %s" % tetris)
		inst.queue_free()
		return null

	sprite.texture = icon

	var packed := PackedScene.new()
	if packed.pack(inst) != OK:
		Out.warning("failed to pack tetris scene")
		inst.queue_free()
		return null

	inst.queue_free()
	return packed


func _find_sprite(node: Node) -> Sprite2D:
	if node is Sprite2D:
		return node
	for child in node.get_children():
		var found := _find_sprite(child)
		if found:
			return found
	return null
