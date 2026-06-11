extends "./InspectCard.gd"

const _BULLET_W := 8.0
const _BULLET_BODY_H := 10.0
const _BULLET_TIP_H := 8.0
const _BULLET_STAGGER := Vector2(7, 4)

var _mode := 0


func _init() -> void:
	super()
	label.hide()
	panel.draw.connect(_paint)


func set_mode(mode: int) -> void:
	if mode == _mode:
		return
	_mode = mode
	redraw()


func _paint() -> void:
	var center := panel.size * 0.5
	var color := content_color()
	if _mode == 2:
		_draw_bullet(panel, center + Vector2(-_BULLET_STAGGER.x, _BULLET_STAGGER.y), color)
		_draw_bullet(panel, center + Vector2(_BULLET_STAGGER.x, -_BULLET_STAGGER.y), color)
	else:
		_draw_bullet(panel, center, color)


func _draw_bullet(c: Control, center: Vector2, color: Color) -> void:
	var top := center.y - (_BULLET_BODY_H + _BULLET_TIP_H) * 0.5
	c.draw_rect(Rect2(center.x - _BULLET_W * 0.5, top + _BULLET_TIP_H, _BULLET_W, _BULLET_BODY_H), color, true)
	var tip := PackedVector2Array([
		Vector2(center.x - _BULLET_W * 0.5, top + _BULLET_TIP_H),
		Vector2(center.x + _BULLET_W * 0.5, top + _BULLET_TIP_H),
		Vector2(center.x, top)
	])
	c.draw_colored_polygon(tip, color)
