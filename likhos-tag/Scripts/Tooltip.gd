extends RefCounted

const Out = preload("../Lib/Out.gd")
const Catalog = preload("./Catalog.gd")
const ROW_PATH = "Panel/Margin/Elements/"

var _lib


func _init(lib) -> void:
	_lib = lib


func on_ready_pre():
	var tooltip = _lib._caller
	_create_row(tooltip, "likho_model", "Model:")
	_create_row(tooltip, "likho_grau", "GRAU index:")


func on_reset_post():
	var tooltip = _lib._caller
	tooltip.get_node(ROW_PATH + "likho_model").hide()
	tooltip.get_node(ROW_PATH + "likho_grau").hide()


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
	var extra_data = Catalog.DATA.get(itemData.file, {})

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

	if caliber_name:
		tooltip.caliber.get_child(0).text = caliber_name
		tooltip.caliber.show()

	if itemData.maxAmount:
		tooltip.capacity.get_child(0).text = itemData.maxAmount
		tooltip.capacity.show()

	var grau_index = extra_data.get("grau_index", "")
	if grau_index:
		var row = tooltip.get_node(ROW_PATH + "likho_grau")
		row.get_child(1).text = grau_index
		row.show()

	var model_name = extra_data.get("model", "")
	if model_name:
		var row = tooltip.get_node(ROW_PATH + "likho_model")
		row.get_child(1).text = model_name
		row.show()

	tooltip.panel.size = Vector2(256, 0)
	tooltip.interface.tooltipOffset = tooltip.panel.size.y / 2.0


func _create_row(tooltip, node_name: String, title_text: String) -> Control:

	var sibling: Label = tooltip.weight
	var parent: Node = sibling.get_parent()

	var row := HBoxContainer.new()
	row.name = node_name
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
	return row
