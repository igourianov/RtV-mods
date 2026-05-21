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

	var capacity = _ensure_row(tooltip, "likho_capacity", "Capacity:")
	if itemData.maxAmount:
		capacity.get_child(1).text = "%dx" % itemData.maxAmount
		capacity.show()
	else:
		capacity.hide()


func _ensure_row(tooltip, meta_key: String, title_text: String) -> Control:
	if tooltip.has_meta(meta_key):
		return tooltip.get_meta(meta_key)

	var sibling: Label = tooltip.weight
	var parent: Node = sibling.get_parent()
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.theme = sibling.theme
	title.add_theme_font_size_override("font_size", 12)
	title.text = title_text
	title.vertical_alignment = VERTICAL_ALIGNMENT_FILL
	row.add_child(title)

	var value := Label.new()
	value.add_theme_color_override("font_color", Color.GREEN)
	value.add_theme_font_size_override("font_size", 12)
	value.vertical_alignment = VERTICAL_ALIGNMENT_FILL
	row.add_child(value)

	parent.add_child(row)
	tooltip.set_meta(meta_key, row)
	return row
