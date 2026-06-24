extends Control

const Out = preload("../../Lib/Out.gd")

const _THEME = preload("res://UI/Themes/Theme.tres")
const _ACCENT := Color(0, 1, 0)
const _FONT_SIZE := 16
const _NATIVE := 64.0

const _PAD_X := 16.0
const _PAD_Y := 8.0
const _MIN_W := 32.0
const _MIN_H := 24.0

const _COND_GAP := 8
const _COND_YELLOW := Color(1, 1, 0)
const _COND_RED := Color(1, 0, 0)

var panel: PanelContainer
var label: Label
var condition: Label
var _row: HBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Anchored to a single point (0.5) with grow BOTH, a PanelContainer expands
	# symmetrically around self's origin to fit its content, so it stays centered
	# on point_at()'s screen position and resizes itself when the text changes.
	panel = PanelContainer.new()
	panel.theme = _THEME
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(_MIN_W, _MIN_H)
	panel.add_theme_stylebox_override("panel", _padded_panel_style())
	add_child(panel)

	_row = HBoxContainer.new()
	_row.theme = _THEME
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", _COND_GAP)
	panel.add_child(_row)

	label = _make_label()
	label.modulate = _ACCENT

	condition = _make_label()
	condition.hide()

	hide()


func _make_label() -> Label:
	var lbl := Label.new()
	lbl.theme = _THEME
	lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	lbl.add_theme_font_size_override("font_size", _FONT_SIZE)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row.add_child(lbl)
	return lbl


func set_text(text: String) -> void:
	label.text = text


func set_condition(value: float) -> void:
	condition.text = "(%d%%)" % roundi(value)
	condition.modulate = _condition_color(value)
	condition.show()


func clear_condition() -> void:
	condition.hide()


func point_at(screen_pos: Vector2) -> void:
	global_position = screen_pos
	show()


func redraw() -> void:
	panel.queue_redraw()


func content_color() -> Color:
	return label.get_theme_color("font_color") * label.self_modulate * label.modulate


func _condition_color(value: float) -> Color:
	if value > 50.0:
		return _ACCENT
	if value > 25.0:
		return _COND_YELLOW
	return _COND_RED


func _padded_panel_style() -> StyleBox:
	# Reuse the theme's Panel stylebox so the background matches, but force the
	# content margins so the PanelContainer pads the text by _PAD_X / _PAD_Y.
	var style: StyleBox
	if _THEME.has_stylebox("panel", "Panel"):
		style = _THEME.get_stylebox("panel", "Panel").duplicate()
	else:
		style = StyleBoxEmpty.new()
	style.content_margin_left = _PAD_X
	style.content_margin_right = _PAD_X
	style.content_margin_top = _PAD_Y
	style.content_margin_bottom = _PAD_Y
	return style
