extends Control

const LMC := preload("./LMC.gd")

const ROW_HEIGHT := 36
const INPUT_WIDTH := 380
const FLOAT_STEP := 0.001
const DIMMED := Color(1, 1, 1, 0.47)
const AXES := "XYZ"

# the vanilla settings screen this menu is opened from and returns to
var _settings: Control
var _mod_uid: String
# pending value per field of the shown mod, written into its config object when the page is left
var _values: Dictionary[String, Variant]
var _reverts: Dictionary[String, Button]

var _title: Label
var _mod_list: VBoxContainer
var _rows: VBoxContainer


func _init(settings: Control) -> void:
	_settings = settings
	theme = load("res://UI/Themes/Theme.tres")
	# the settings screen is shown while the game is paused
	process_mode = PROCESS_MODE_ALWAYS
	set_anchors_preset(PRESET_FULL_RECT)
	hide()

	var backdrop := TextureRect.new()
	backdrop.texture = load("res://Editor/RTV_Background.png")
	backdrop.material = load("res://UI/Effects/MT_Menu.tres")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_preset(PRESET_FULL_RECT)
	add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.8)
	shade.set_anchors_preset(PRESET_FULL_RECT)
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 40)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var caption := Label.new()
	caption.text = "Likho's Mod Config"
	caption.theme_type_variation = &"HeaderLarge"
	caption.add_theme_font_size_override("font_size", 24)
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(caption)

	var back := Button.new()
	back.text = "← Return"
	back.custom_minimum_size = Vector2(256, 40)
	back.pressed.connect(close)
	header.add_child(back)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 32)
	layout.add_child(columns)

	var mods_column := _add_column(columns, 1.0)
	_add_column_title(mods_column, "Mods")
	var search := LineEdit.new()
	search.placeholder_text = "Search mods..."
	search.clear_button_enabled = true
	search.custom_minimum_size.y = 32
	search.text_changed.connect(_on_search_text_changed)
	mods_column.add_child(search)
	_mod_list = _add_scroll_list(mods_column)

	var page_column := _add_column(columns, 4.0)
	_title = _add_column_title(page_column, "Settings")
	_rows = _add_scroll_list(page_column)
	_rows.add_theme_constant_override("separation", 10)

	var entries: Array[LMC.Entry] = []
	entries.assign(LMC.mods.values())
	entries.sort_custom(func(a: LMC.Entry, b: LMC.Entry) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	var mod_buttons := ButtonGroup.new()
	for entry in entries:
		var button := Button.new()
		button.text = entry.name
		button.toggle_mode = true
		button.button_group = mod_buttons
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.custom_minimum_size.y = 32
		button.pressed.connect(_on_mod_pressed.bind(entry.uid))
		_mod_list.add_child(button)
	if entries:
		_mod_uid = entries[0].uid
		_mod_list.get_child(0).button_pressed = true


func _input(event: InputEvent) -> void:
	if !is_visible_in_tree() || !event.is_action_pressed("settings"):
		return
	# this node gets the event ahead of the vanilla UI, which would close the hidden settings screen on it
	get_viewport().set_input_as_handled()
	close()


func open() -> void:
	_build_page()
	_settings.hide()
	show()
	_settings.PlayClick()


func close() -> void:
	_apply_page()
	hide()
	_settings.show()
	_settings.PlayClick()


func _apply_page() -> void:
	if _mod_uid:
		LMC.apply(_mod_uid, _values)


func _build_page() -> void:
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	_values.clear()
	_reverts.clear()
	if !_mod_uid:
		return

	var entry := LMC.mods[_mod_uid]
	_title.text = entry.name + " Settings"
	# fields outside any group lead the page without a header, wherever they are declared
	# filter keeps the declaration order within both parts
	var fields: Array[Dictionary] = entry.fields.filter(func(field: Dictionary) -> bool: return field.group == "")
	fields.append_array(entry.fields.filter(func(field: Dictionary) -> bool: return field.group != ""))
	var group: String = ""
	for field in fields:
		var field_name: String = field.name
		_values[field_name] = entry.config.get(field_name)
		if field.group != group:
			_add_group_header(field.group)
		group = field.group

		var row := HBoxContainer.new()
		row.custom_minimum_size.y = ROW_HEIGHT
		_rows.add_child(row)

		var label := Label.new()
		label.text = field_name.capitalize()
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(label)

		var revert := Button.new()
		revert.text = "Reset"
		revert.tooltip_text = "Revert to default value"
		revert.pressed.connect(_on_revert_pressed.bind(field, row))
		_reverts[field_name] = revert
		_set_value(field_name, _values[field_name])

		row.add_child(_create_input(field))
		row.add_child(revert)


func _set_value(field_name: String, value: Variant) -> void:
	_values[field_name] = value
	var is_default: bool = value == LMC.mods[_mod_uid].defaults[field_name]
	var revert := _reverts[field_name]
	revert.disabled = is_default
	# hidden rather than removed, so the inputs of every row stay aligned
	revert.modulate.a = 0.0 if is_default else 1.0


# builds the input of a field from its pending value
func _create_input(field: Dictionary) -> Control:
	var field_name: String = field.name
	var value: Variant = _values[field_name]
	var input: Control

	if field.hint == PROPERTY_HINT_ENUM:
		var dropdown := OptionButton.new()
		var options: Array[Variant] = []
		var next_value: int = 0
		for option: String in field.hint_string.split(","):
			# an option is "Label" or "Label:value", and an int option without a value follows the previous one
			var parts := option.split(":")
			if parts.size() > 1:
				next_value = int(parts[1])
			options.append(next_value if field.type == TYPE_INT else parts[0])
			next_value += 1
			dropdown.add_item(parts[0])
		dropdown.select(options.find(value))
		dropdown.item_selected.connect(func(index: int) -> void: _set_value(field_name, options[index]))
		input = dropdown

	elif field.type == TYPE_BOOL:
		var states := ButtonGroup.new()
		input = HBoxContainer.new()
		for state: bool in [false, true]:
			var button := Button.new()
			button.text = "On" if state else "Off"
			button.toggle_mode = true
			button.button_group = states
			button.button_pressed = value == state
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.pressed.connect(_set_value.bind(field_name, state))
			input.add_child(button)

	elif field.type == TYPE_INT || field.type == TYPE_FLOAT:
		var is_int: bool = field.type == TYPE_INT
		var on_changed := func(number: float) -> void: _set_value(field_name, int(number) if is_int else number)
		if field.hint == PROPERTY_HINT_RANGE:
			# "min,max" or "min,max,step", possibly followed by flags
			var limits: PackedStringArray = field.hint_string.split(",")
			var step: float = 1.0 if is_int else FLOAT_STEP
			if limits.size() > 2 && limits[2].is_valid_float():
				step = float(limits[2])
			var spin_box := _create_spin_box(value, step, on_changed, float(limits[0]), float(limits[1]))
			var slider := HSlider.new()
			slider.size_flags_horizontal = SIZE_EXPAND_FILL
			slider.size_flags_vertical = SIZE_FILL
			slider.size_flags_stretch_ratio = 4.0
			slider.scrollable = false
			spin_box.share(slider)
			input = HBoxContainer.new()
			input.add_theme_constant_override("separation", 12)
			input.add_child(slider)
			input.add_child(spin_box)
		else:
			input = _create_spin_box(value, 1.0 if is_int else FLOAT_STEP, on_changed)

	elif field.type == TYPE_STRING:
		var line_edit := LineEdit.new()
		line_edit.text = value
		line_edit.text_changed.connect(func(text: String) -> void: _set_value(field_name, text))
		input = line_edit

	elif field.type == TYPE_COLOR:
		var picker := ColorPickerButton.new()
		picker.color = value
		picker.color_changed.connect(func(color: Color) -> void: _set_value(field_name, color))
		input = picker

	else:
		input = HBoxContainer.new()
		input.add_theme_constant_override("separation", 12)
		for axis: int in (2 if field.type == TYPE_VECTOR2 else 3):
			var axis_label := Label.new()
			axis_label.text = AXES[axis] + ":"
			input.add_child(axis_label)
			var on_axis_changed := func(number: float) -> void:
				var vector: Variant = _values[field_name]
				vector[axis] = number
				_set_value(field_name, vector)
			input.add_child(_create_spin_box(value[axis], FLOAT_STEP, on_axis_changed))

	input.custom_minimum_size.x = INPUT_WIDTH
	return input


# without limits the box takes any number
func _create_spin_box(value: float, step: float, on_changed: Callable, min_value: float = 0.0, max_value: float = 0.0) -> SpinBox:
	var spin_box := SpinBox.new()
	var unlimited: bool = min_value == max_value
	spin_box.allow_lesser = unlimited
	spin_box.allow_greater = unlimited
	if !unlimited:
		spin_box.min_value = min_value
		spin_box.max_value = max_value
	spin_box.step = step
	spin_box.value = value
	spin_box.custom_minimum_size.x = 100
	spin_box.size_flags_horizontal = SIZE_EXPAND_FILL
	# connected last, so setting the box up does not count as a change by the player
	spin_box.value_changed.connect(on_changed)
	return spin_box


func _add_group_header(text: String) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = ROW_HEIGHT
	header.add_theme_constant_override("separation", 16)
	_rows.add_child(header)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", DIMMED)
	header.add_child(label)

	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.09)
	line.custom_minimum_size.y = 1
	line.size_flags_horizontal = SIZE_EXPAND_FILL
	line.size_flags_vertical = SIZE_SHRINK_CENTER
	header.add_child(line)


func _add_column(parent: Control, stretch_ratio: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = stretch_ratio
	column.add_theme_constant_override("separation", 10)
	parent.add_child(column)
	return column


func _add_column_title(column: VBoxContainer, text: String) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 50
	column.add_child(panel)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return label


func _add_scroll_list(column: VBoxContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list)
	return list


func _on_mod_pressed(mod_uid: String) -> void:
	_apply_page()
	_mod_uid = mod_uid
	_build_page()
	_settings.PlayClick()


func _on_revert_pressed(field: Dictionary, row: HBoxContainer) -> void:
	var field_name: String = field.name
	_set_value(field_name, LMC.mods[_mod_uid].defaults[field_name])
	# a fresh input shows the default, which spares every input type a way to be set from outside
	var stale := row.get_child(1)
	row.remove_child(stale)
	stale.queue_free()
	var input := _create_input(field)
	row.add_child(input)
	row.move_child(input, 1)
	_settings.PlayClick()


func _on_search_text_changed(text: String) -> void:
	var search := text.strip_edges()
	for button: Button in _mod_list.get_children():
		button.visible = !search || button.text.containsn(search)
