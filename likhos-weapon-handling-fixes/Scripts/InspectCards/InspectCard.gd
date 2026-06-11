extends Control

const Out = preload("../../Lib/Out.gd")

const _THEME = preload("res://UI/Themes/Theme.tres")
const _ACCENT := Color(0, 1, 0)
const _FONT_SIZE := 24
const _NATIVE := 64.0

const _PAD_X := 16.0
const _PAD_Y := 8.0
const _MIN_W := 32.0
const _MIN_H := 24.0

var panel: Panel
var label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel = Panel.new()
	panel.theme = _THEME
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	label = Label.new()
	label.theme = _THEME
	label.modulate = _ACCENT
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	label.add_theme_font_size_override("font_size", _FONT_SIZE)
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)

	_resize(_NATIVE, _NATIVE)
	hide()


func set_font_size(size: int) -> void:
	label.add_theme_font_size_override("font_size", size)


func set_text(text: String) -> void:
	if text == label.text:
		return
	label.text = text
	var min_size := label.get_minimum_size()
	_resize(max(min_size.x + _PAD_X * 2.0, _MIN_W), max(min_size.y + _PAD_Y * 2.0, _MIN_H))


func point_at(screen_pos: Vector2) -> void:
	global_position = screen_pos
	show()


func redraw() -> void:
	panel.queue_redraw()


func content_color() -> Color:
	return label.get_theme_color("font_color") * label.self_modulate * label.modulate


func _resize(w: float, h: float) -> void:
	panel.offset_left = -w / 2.0
	panel.offset_top = -h / 2.0
	panel.offset_right = w / 2.0
	panel.offset_bottom = h / 2.0
