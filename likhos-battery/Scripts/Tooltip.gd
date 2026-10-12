extends "../Lib/Tooltip.gd"

const BatteryUtil := preload("./BatteryUtil.gd")

# A row keeps the title it was created with, so every attachment gets a row of its own.
const ROW_PREFIX := "likho_charge_row_"

# Rows shown by the last update.
var _rows: Array[String]


# Vanilla Update resets first, so this also clears the rows of the item hovered before.
func on_reset_post() -> void:
	var tooltip: Node = _lib._caller
	for row: String in _rows:
		_hide_row(tooltip, row)
	_rows.clear()


func on_update_post(item: Item) -> void:
	var tooltip: Node = _lib._caller
	if !item || !item.slotData || !item.slotData.itemData:
		return

	# A device shows its own charge through vanilla's condition line. Only attachments need a row.
	var slotData: SlotData = item.slotData
	for nested: ItemData in slotData.nested:
		if BatteryUtil.powers(nested):
			var row := ROW_PREFIX + nested.file
			var charge: float = BatteryUtil.attachment_holder(slotData, nested).condition
			_show_row(tooltip, row, nested.display + ":", str(roundi(charge)) + "%")
			_rows.append(row)

	# Vanilla Update sized the panel and centered the tooltip before these rows were shown.
	if !_rows.is_empty():
		tooltip.panel.size = Vector2(256, 0)
		tooltip.interface.tooltipOffset = tooltip.panel.size.y / 2.0
