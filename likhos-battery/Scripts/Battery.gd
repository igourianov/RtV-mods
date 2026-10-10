extends RefCounted

var data: ItemData


func _init(lib) -> void:
	data = lib.get_entry(lib.Registry.ITEMS, "Batteries")


# Same test vanilla Interface.CombineCheck uses to offer charging.
func powers(itemData: ItemData) -> bool:
	return itemData.type == "Electronics" && itemData.compatible.any(func(element: ItemData) -> bool: return element.file == data.file)


# A device holds a battery only while it has charge. At 0% there is nothing to take out.
func is_removable(slotData: SlotData) -> bool:
	return slotData.condition > 0 && powers(slotData.itemData)
