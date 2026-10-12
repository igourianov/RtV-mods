extends RefCounted

const BatteryUtil := preload("./BatteryUtil.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_value() -> int:
	_lib.skip_super()
	var item = _lib._caller
	var slotData: SlotData = item.slotData

	# Vanilla scales every item but Electronics by condition, and exempts Electronics from condition pricing altogether.
	# On a device the condition is its charge, which is priced below, so a laser is valued at full condition here.
	var value: int
	if BatteryUtil.powers(slotData.itemData):
		var charge: Variant = slotData.condition
		slotData.condition = 100
		value = item._rtv_vanilla_Value()
		slotData.condition = charge
	else:
		value = item._rtv_vanilla_Value()

	# Every charge the item carries is priced as one full battery, so a battery, a device and a weapon with a powered attachment all lose the same amount for the charge they are missing.
	var holders := BatteryUtil.holders(slotData)
	if slotData.itemData.file == BatteryUtil.FILE:
		holders.append(slotData)

	for holder: SlotData in holders:
		# A draining device can end a frame slightly below 0.
		var missing: float = 1.0 - clampf(holder.condition, 0.0, 100.0) * 0.01
		value -= roundi(BatteryUtil.data.value * missing)

	return value


func on_combine_post(itemDragged: Item) -> void:
	var dragged: SlotData = itemDragged.slotData
	if BatteryUtil.powers(dragged.itemData):
		BatteryUtil.attachment_holder(_lib._caller.slotData, dragged.itemData).condition = dragged.condition


func on_remove_pre(nestedIndex: int) -> void:
	var slotData: SlotData = _lib._caller.slotData
	BatteryUtil.detach(slotData, slotData.nested[nestedIndex])


func on_combine_swap_pre(itemDragged: Item) -> void:
	var slotData: SlotData = _lib._caller.slotData

	# On a weapon vanilla swaps out the first attachment of the dragged item's subtype.
	var subtype: String = itemDragged.slotData.itemData.subtype
	for nested: ItemData in slotData.nested:
		if nested.subtype == subtype:
			BatteryUtil.detach(slotData, nested)
			return
