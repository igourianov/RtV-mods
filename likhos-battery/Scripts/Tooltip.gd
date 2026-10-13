extends RefCounted

const BatteryUtil := preload("./BatteryUtil.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_post(item: Item) -> void:
	if !item || !item.slotData || !item.slotData.itemData:
		return

	var slotData: SlotData = item.slotData
	if slotData.nested.is_empty():
		return

	# A device shows its own charge through vanilla's condition line. Only attachments carry theirs in the list.
	# Same order and separator as vanilla CreateNestedString, whose text this replaces.
	var entries: PackedStringArray
	for nested: ItemData in slotData.nested:
		var entry := String(nested.display)
		if BatteryUtil.powers(nested):
			entry += " (%d%%)" % roundi(BatteryUtil.attachment_holder(slotData, nested).condition)
		entries.append(entry)
	_lib._caller.nested.get_child(0).text = ", ".join(entries)
