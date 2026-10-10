extends RefCounted

const Config := preload("../Config.gd")

var config := Config.instance
var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_details_post() -> void:
	var item = _lib._caller
	if !item:
		return

	if item.slotData.itemData.type == "Weapon" && config.ammo_icons:
		item.amount.hide()
