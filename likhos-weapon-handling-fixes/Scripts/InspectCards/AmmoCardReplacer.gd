extends Control

const ModConfig = preload("../ModConfig.gd")

const _DURATION := 1.0
const _DELAY := 0.5
const _MAX_BARS := 10
const _BAR_WIDTH_FACTOR := 0.5
const _BAR_THICKNESS := 3
const _BAR_GAP := 3
const _PLACEHOLDER := Color(0.4, 0.30, 0.2)

var _rig
var _label: Label
var _prev_visible := false
var _delay := 0.0
var _fill_progress := 0.0
var _fill_target := 0.0
var _capacity := 0


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


func _process(delta: float) -> void:
	if !ModConfig.replace_ammo_count:
		_label.show()
		visible = false
		_prev_visible = false
		return

	_label.hide()
	visible = true

	if !is_visible_in_tree():
		_prev_visible = false
	elif !_prev_visible:
		_prev_visible = true
		_capacity = _get_mag_cap()
		var amount: int = _rig.slotData.amount if _rig && _rig.slotData else 0
		_fill_target = clampf(float(amount) / float(_capacity), 0.0, 1.0) if _capacity > 0 else 0.0
		_fill_progress = 0.0
		_delay = _DELAY
		queue_redraw()
	elif _delay > 0.0:
		_delay -= delta
	elif _fill_progress < 1.0:
		_fill_progress = min(_fill_progress + delta / _DURATION, 1.0)
		queue_redraw()


func _get_mag_cap() -> int:
	if !_rig || !_rig.data || !_rig.slotData:
		return 0
	if !_rig.magazine: # magazine mesh - built-in mag if null
		return _rig.data.maxAmount
	for nested in _rig.slotData.nested:
		if nested && nested.subtype == "Magazine":
			return nested.maxAmount
	return 0


func _content_color() -> Color:
	return _label.get_theme_color("font_color") * _label.self_modulate * _label.modulate


func _draw() -> void:
	if _capacity <= 0:
		return
	var bar_count: int = min(_capacity, _MAX_BARS)
	var displayed: float = lerp(0.0, _fill_target, _fill_progress)
	var filled: int = clampi(int(round(displayed * bar_count)), 0, bar_count)

	var bar_w: float = size.x * _BAR_WIDTH_FACTOR
	var bar_x: float = (size.x - bar_w) * 0.5
	var stack_h: int = bar_count * _BAR_THICKNESS + (bar_count - 1) * _BAR_GAP
	var start_y: float = (size.y - stack_h) * 0.5
	var fill_color := _content_color()

	for i in bar_count:
		var y: float = start_y + i * (_BAR_THICKNESS + _BAR_GAP)
		var is_filled: bool = i >= bar_count - filled
		var color := fill_color if is_filled else _PLACEHOLDER
		draw_rect(Rect2(bar_x, y, bar_w, _BAR_THICKNESS), color, true)
