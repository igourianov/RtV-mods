extends RefCounted

const FILE := "Batteries"

static var data: ItemData


# Same test vanilla Interface.CombineCheck uses to offer charging.
static func powers(itemData: ItemData) -> bool:
	return itemData.type == "Electronics" && itemData.compatible.any(func(element: ItemData) -> bool: return element.file == FILE)


# A device holds a battery only while it has charge. At 0% there is nothing to take out.
static func is_removable(slotData: SlotData) -> bool:
	return slotData.condition > 0 && powers(slotData.itemData)
