extends RefCounted

const Out = preload("../Lib/Out.gd")
const Catalog = preload("./Catalog.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_ready_pre():
	var tooltip = _lib._caller
	_create_row(tooltip, "likho_model", "Model:")
	#_create_row(tooltip, "likho_grau", "GRAU index:")


func on_reset_post():
	var tooltip = _lib._caller
	var row = tooltip.get_meta("likho_model")
	row.hide()


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

	var extra_data = Catalog.DATA.get(itemData.file, {})
	var grau_index = extra_data.get("grau_index", "")
	var model_name = extra_data.get("model", "")
	var model_row = tooltip.get_meta("likho_model", null)
	if model_row && (grau_index || model_name):
		model_row.get_child(0).text = "GRAU index:" if grau_index else "Model:"
		model_row.get_child(1).text = grau_index if grau_index else model_name
		model_row.show()

	tooltip.panel.size = Vector2(256, 0)
	tooltip.interface.tooltipOffset = tooltip.panel.size.y / 2.0


func _create_row(tooltip, meta_key: String, title_text: String) -> Control:

	var sibling: Label = tooltip.weight
	var parent: Node = sibling.get_parent()

	var row := HBoxContainer.new()
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
