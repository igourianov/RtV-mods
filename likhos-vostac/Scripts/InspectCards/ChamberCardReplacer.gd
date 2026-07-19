extends Control

const ModConfig = preload("../ModConfig.gd")

const _BULLET_W := 8.0
const _BULLET_BODY_H := 14.0
const _BULLET_TIP_H := 8.0
const _PLACEHOLDER := Color(0.3, 0.3, 0.3)
const _CHAMBER_GAP := 4.0
const _CHAMBER_TOP_OFFSET := 2.0
const _CHAMBER_HEIGHT_FACTOR := 0.7
const _CHAMBER_THICKNESS := 2.0

var _rig
var _label: Label
var _chambered := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH


func _ready() -> void:
	_label = get_parent().get_child(0)


func set_rig(rig) -> void:
	_rig = rig


func _process(_delta: float) -> void:
	if !ModConfig.ammo_icons:
		_label.show()
		visible = false
		return

	_label.hide()
	visible = true

	var chambered: bool = _rig && _rig.slotData && _rig.slotData.chamber
	if chambered != _chambered:
		_chambered = chambered
		queue_redraw()


func _content_color() -> Color:
	return _label.get_theme_color("font_color") * _label.self_modulate * _label.modulate


func _draw() -> void:
	var color := _content_color() if _chambered else _PLACEHOLDER
	var center := size * 0.5
	var top := center.y - (_BULLET_BODY_H + _BULLET_TIP_H) * 0.5
	draw_rect(Rect2(center.x - _BULLET_W * 0.5, top + _BULLET_TIP_H, _BULLET_W, _BULLET_BODY_H), color, true)
	var tip := PackedVector2Array([
		Vector2(center.x - _BULLET_W * 0.5, top + _BULLET_TIP_H),
		Vector2(center.x + _BULLET_W * 0.5, top + _BULLET_TIP_H),
		Vector2(center.x, top)
	])
	draw_colored_polygon(tip, color)
	_draw_chamber(center, top)


func _draw_chamber(center: Vector2, top: float) -> void:
	var color := _content_color()
	var line_top := top - _CHAMBER_TOP_OFFSET
	var line_bottom := top + (_BULLET_BODY_H + _BULLET_TIP_H) * _CHAMBER_HEIGHT_FACTOR
	var left_x := center.x - _BULLET_W * 0.5 - _CHAMBER_GAP
	var right_x := center.x + _BULLET_W * 0.5 + _CHAMBER_GAP
	draw_line(Vector2(left_x, line_top), Vector2(left_x, line_bottom), color, _CHAMBER_THICKNESS, true)
	draw_line(Vector2(right_x, line_top), Vector2(right_x, line_bottom), color, _CHAMBER_THICKNESS, true)
