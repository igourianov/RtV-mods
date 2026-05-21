extends RefCounted

const Out = preload("../Lib/Out.gd")

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
	var parts: Array[String] = []
	var has_armor := false
	var caliber_name: String

	tooltip.type.text = itemData.subtype if itemData.type == "Attachment" && itemData.subtype else itemData.type

	for element in itemData.compatible:
		if element.type == "Ammo":
			caliber_name = element.name
		elif element.type == "Armor":
			has_armor = true
		else:
			parts.append(element.display)

	if has_armor:
		parts.append("Armor Plates")

	if parts.size():
		tooltip.compatibleList.text = ", ".join(parts)
		tooltip.subpanel.show()
	else:
		tooltip.subpanel.hide()

	if caliber_name || itemData.caliber:
		tooltip.caliber.get_child(0).text = caliber_name if caliber_name else itemData.caliber
		tooltip.caliber.show()
	else:
		tooltip.caliber.hide()

	if itemData.maxAmount || itemData.capacity:
		tooltip.capacity.get_child(0).text = itemData.maxAmount if itemData.maxAmount else "+%dkg" % itemData.capacity
		tooltip.capacity.show()
	else:
		tooltip.capacity.hide()

	tooltip.panel.size = Vector2(256, 0)
	tooltip.interface.tooltipOffset = tooltip.panel.size.y / 2.0

