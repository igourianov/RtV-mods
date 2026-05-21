extends RefCounted


var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_post(item) -> void:
	var tooltip = _lib._caller
	if !tooltip:
		return

	if !item || !item.slotData || !item.slotData.itemData:
		return

	var itemData = item.slotData.itemData
	if itemData.compatible.size() == 0:
		return

	var parts: Array[String] = []
	for element in itemData.compatible:
		if element.type == "Armor":
			continue
		var label: String = element.inventory if element.inventory else element.name
		parts.append(String(label))

	if itemData.carrier:
		parts.append("Armor Plates")

	tooltip.compatibleList.text = ", ".join(parts)
