extends RefCounted

var data: ItemData


func _init(lib) -> void:
	data = lib.get_entry(lib.Registry.ITEMS, "Batteries")


# The device test is the one vanilla Interface.CombineCheck uses to offer charging.
# A device holds a battery only while it has charge. At 0% there is nothing to take out.
func is_removable(slotData: SlotData) -> bool:
	var itemData := slotData.itemData
	return slotData.condition > 0 && itemData.type == "Electronics" && itemData.compatible.any(func(element: ItemData) -> bool: return element.file == data.file)
