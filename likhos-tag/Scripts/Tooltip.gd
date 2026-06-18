extends "../Lib/Tooltip.gd"

const Out = preload("../Lib/Out.gd")
const Catalog = preload("./Catalog.gd")

const BULLET_WEIGHT := "likho_bullet_weight"


func on_reset_post():
	var tooltip = _lib._caller
	_hide_row(tooltip, BULLET_WEIGHT)


func on_update_post(item) -> void:
	var tooltip = _lib._caller
	if !tooltip:
		return

	if !item || !item.slotData || !item.slotData.itemData:
		return

	var itemData = item.slotData.itemData
	var parts: Array[String] = []
	var has_armor := false
	var caliber_name: String = _get_caliber(itemData)
	var extra_data = Catalog.DATA.get(itemData.file, {})

	tooltip.type.text = itemData.subtype if itemData.type == "Attachment" && itemData.subtype else itemData.type

	for el in itemData.compatible:
		if el.type == "Armor":
			has_armor = true
		else:
			parts.append(el.display)

	if has_armor:
		parts.append("Armor Plates")

	if parts.size():
		tooltip.compatibleList.text = ", ".join(parts)
		tooltip.subpanel.show()
	else:
		tooltip.subpanel.hide()

	if caliber_name:
		tooltip.caliber.get_child(0).text = caliber_name
		tooltip.caliber.show()
	else:
		tooltip.caliber.hide()

	if itemData.maxAmount && itemData.subtype == "Magazine":
		tooltip.capacity.get_child(0).text = itemData.maxAmount
		tooltip.capacity.show()

	if extra_data.load:
		_show_row(tooltip, BULLET_WEIGHT, "Load:", "%dgr" % extra_data.load)

	tooltip.panel.size = Vector2(256, 0)
	tooltip.interface.tooltipOffset = tooltip.panel.size.y / 2.0


func _get_caliber(data: ItemData) -> String:
	if data.type == "Ammo":
		return data.equipment
	if data.type == "Weapon":
		#return _get_caliber(data.ammo)
		return data.caliber
	return ""