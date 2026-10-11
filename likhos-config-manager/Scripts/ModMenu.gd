extends Control

const LCM := preload("./LCM.gd")
const SettingRow := preload("../Scenes/SettingRow.tscn")
const GroupHeader := preload("../Scenes/GroupHeader.tscn")

const FLOAT_STEP := 0.001
const AXES := "XYZ"

# the vanilla settings screen this menu is opened from, set by whoever instantiates the menu
var settings: Control
# what the menu replaces while it is open and returns to, set the same way
var screen: Control
var _mod_uid: String
# pending value per field of the shown mod, written into its config object when the page is left
var _values: Dictionary[String, Variant]
var _reverts: Dictionary[String, Button]

@onready var _title: Label = %PageTitle
@onready var _mod_list: VBoxContainer = %ModList
@onready var _rows: VBoxContainer = %Rows


func _ready() -> void:
	var profile: Label = %Profile
	profile.text = "MML Profile: " + LCM._active_profile()

	var entries: Array[LCM.Entry] = []
	entries.assign(LCM._mods.values())
	entries.sort_custom(func(a: LCM.Entry, b: LCM.Entry) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
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
	screen.hide()
	show()
	settings.PlayClick()


func close() -> void:
	_apply_page()
	hide()
	screen.show()
	settings.PlayClick()


func _apply_page() -> void:
	if _mod_uid:
		LCM._apply(_mod_uid, _values)


func _build_page() -> void:
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	_values.clear()
	_reverts.clear()
	if !_mod_uid:
		return

	var entry := LCM._mods[_mod_uid]
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
			var header := GroupHeader.instantiate()
			var header_label: Label = header.get_node("Label")
			header_label.text = field.group
			_rows.add_child(header)
		group = field.group

		var row := SettingRow.instantiate()
		_rows.add_child(row)

		var label: Label = row.get_node("Label")
		var label_text := field_name.replace("_", " ")
		label.text = label_text[0].to_upper() + label_text.substr(1)

		var slot: HBoxContainer = row.get_node("Input")
		var revert: Button = row.get_node("Revert")
		revert.pressed.connect(_on_revert_pressed.bind(field, slot))
		_reverts[field_name] = revert
		_set_value(field_name, _values[field_name])

		slot.add_child(_create_input(field))


func _set_value(field_name: String, value: Variant) -> void:
	_values[field_name] = value
	var is_default: bool = value == LCM._mods[_mod_uid].defaults[field_name]
	var revert := _reverts[field_name]
	revert.disabled = is_default
	# hidden rather than removed, so the inputs of every row stay aligned
	revert.modulate.a = 0.0 if is_default else 1.0


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
			# its share of the row next to the slider is too narrow for a number
			spin_box.custom_minimum_size.x = 100
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
			# the row stretches the label taller than its text
			axis_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			input.add_child(axis_label)
			var on_axis_changed := func(number: float) -> void:
				var vector: Variant = _values[field_name]
				vector[axis] = number
				_set_value(field_name, vector)
			input.add_child(_create_spin_box(value[axis], FLOAT_STEP, on_axis_changed))

	# takes the whole width of the row's input slot
	input.size_flags_horizontal = SIZE_EXPAND_FILL
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
	spin_box.size_flags_horizontal = SIZE_EXPAND_FILL
	# connected last, so setting the box up does not count as a change by the player
	spin_box.value_changed.connect(on_changed)
	return spin_box


func _on_mod_pressed(mod_uid: String) -> void:
	_apply_page()
	_mod_uid = mod_uid
	_build_page()
	settings.PlayClick()


func _on_revert_pressed(field: Dictionary, slot: HBoxContainer) -> void:
	var field_name: String = field.name
	_set_value(field_name, LCM._mods[_mod_uid].defaults[field_name])
	# a fresh input shows the default, which spares every input type a way to be set from outside
	var stale := slot.get_child(0)
	slot.remove_child(stale)
	stale.queue_free()
	slot.add_child(_create_input(field))
	settings.PlayClick()


func _on_search_text_changed(text: String) -> void:
	var search := text.strip_edges()
	for button: Button in _mod_list.get_children():
		button.visible = !search || button.text.containsn(search)
