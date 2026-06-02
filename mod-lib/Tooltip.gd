extends RefCounted

var _lib


func _init(lib) -> void:
	_lib = lib


func _show_row(tooltip, node_name: String, title: String, text) -> void:
	var row := _get_row(tooltip, node_name)
	if !row:
		row = _create_row(tooltip, node_name, title)
	row.get_child(1).text = text
	row.show()


func _hide_row(tooltip, node_name: String) -> void:
	var row := _get_row(tooltip, node_name)
	if row:
		row.hide()


func _get_container(tooltip) -> Node:
	return tooltip.weight.get_parent()


func _get_row(tooltip, node_name: String) -> Node:
	return _get_container(tooltip).get_node_or_null(node_name)


func _create_row(tooltip, node_name: String, title_text: String) -> Control:

	var sibling: Label = tooltip.weight
	var container: Node = _get_container(tooltip)

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

	container.add_child(row)
	return row
