extends RefCounted

var _lib
var gameData := preload("res://Resources/GameData.tres")


func _init(lib) -> void:
	_lib = lib


func on_create_loot_post(_item: ItemData) -> void:
	# Vanilla leaves tutorial loot at full charge.
	if gameData.tutorial:
		return

	_roll(_lib._caller.loot.back())


func on_spawn_items_post() -> void:
	for child in _lib._caller.get_children():
		if child is Pickup && child.slotData:
			_roll(child.slotData)


# Replaces the vanilla 25-100 roll for the two battery powered subtypes it covers. Weapons share that roll and keep it.
func _roll(slotData: SlotData) -> void:
	var subtype: String = slotData.itemData.subtype
	if subtype == "Light":
		slotData.condition = randi_range(20, 75)
