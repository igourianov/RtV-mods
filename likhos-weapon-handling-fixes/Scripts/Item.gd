extends RefCounted


var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_details_post() -> void:
	var item = _lib._caller
	if !item || !item.slotData || !item.slotData.itemData:
		return
	if item.slotData.itemData.type != "Weapon" || !item.amount:
		return
	item.amount.text = "%s + %d" % [
		"?" if item.slotData.amount else "0",
		1 if item.slotData.chamber && !item.slotData.casing else 0
	]
