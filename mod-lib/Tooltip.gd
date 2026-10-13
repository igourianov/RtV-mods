extends RefCounted

const LAYOUT_META := &"likho_tooltip_layout"

var _lib


func _init(lib) -> void:
	_lib = lib

	# Every mod ships its own copy of the lib, so a static var would not be shared between them.
	if Engine.has_meta(LAYOUT_META):
		return
	Engine.set_meta(LAYOUT_META, true)
	# Lower priorities fire first and mods register at the default of 100, so this runs after all of them.
	# A Callable does not keep its target alive, so the mod has to hold this instance.
	lib.hook("tooltip-update-post", _on_layout, 1000)


# Vanilla fits the panel as the last step of Update, before a post hook can change a row, and it trims the nested list to one line.
func _on_layout(_item: Item) -> void:
	var tooltip = _lib._caller
	var panel: Control = tooltip.panel
	var row: Label = tooltip.nested
	var value: Label = row.get_child(0)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Trimming must be off, otherwise a wrapping Label reports a minimum height of 1 instead of its line count.
	value.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	# Vanilla's value label has a fixed width that runs past the right edge of its row.
	# The row's own size is stale until the containers sort at the end of the frame, so its width is taken from the panel, less what the containers around the rows add.
	var padding: float = panel.get_combined_minimum_size().x - row.get_parent().get_combined_minimum_size().x
	value.size.x = panel.size.x - padding - value.position.x
	# The value label sits outside container layout, so the row has to be told how tall the wrapped list is.
	row.custom_minimum_size.y = value.get_minimum_size().y

	panel.size = Vector2(256, 0)
	tooltip.interface.tooltipOffset = panel.size.y / 2.0


func _show_row(tooltip: Node, node_name: String, title: String, text: String) -> void:
	var row := _get_row(tooltip, node_name)
	if !row:
		row = _create_row(tooltip, node_name, title)
	row.get_child(1).text = text
	row.show()


func _hide_row(tooltip: Node, node_name: String) -> void:
	var row := _get_row(tooltip, node_name)
	if row:
		row.hide()


func _get_container(tooltip: Node) -> Node:
	return tooltip.weight.get_parent()


func _get_row(tooltip: Node, node_name: String) -> Node:
	return _get_container(tooltip).get_node_or_null(node_name)


func _create_row(tooltip: Node, node_name: String, title_text: String) -> Control:

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

	if tooltip.subpanel:
		var subpanel_index := container.get_children().find(tooltip.subpanel)
		if subpanel_index != -1:
			container.move_child(row, subpanel_index)

	return row
