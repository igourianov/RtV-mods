extends RefCounted

const ModConfig = preload("../ModConfig.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_details_post() -> void:
	var item = _lib._caller
	if !item:
		return

	if item.slotData.itemData.type == "Weapon" && ModConfig.replace_ammo_count:
		item.amount.hide()
