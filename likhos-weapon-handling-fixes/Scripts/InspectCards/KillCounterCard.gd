extends "./InspectCard.gd"

const _MAX_BARS := 10
const _TICK_SPACING := 7.0
const _TICK_LENGTH := 28.0
const _TICK_THICKNESS := 3.0
const _PAD := 10.0
const _SEGMENTS := 4
const _JITTER := 1.6
const _SLANT := 0.12
const _LEN_JITTER := 3.0
const _THICK_JITTER := 1.0
const _SLASH_OVERHANG := 9.0
const _SLASH_RISE := 0.55
const _WIDTH := (_MAX_BARS - 1) * _TICK_SPACING + _PAD * 2.0
const _HEIGHT := _TICK_LENGTH + _PAD * 2.0

const _RED := Color(0.85, 0.12, 0.12)
const _PURPLE := Color(0.62, 0.2, 0.85)
const _PLACEHOLDER := Color(0.3, 0.3, 0.3)

var _slice: PackedByteArray
var _seed: int
var _slashed := false


func _init() -> void:
	super()
	label.hide()
	panel.draw.connect(_paint)
	_resize(_WIDTH, _HEIGHT)
	custom_minimum_size = Vector2(_WIDTH, _HEIGHT)
	_seed = randi()
	hide()


func set_group(slice: PackedByteArray) -> void:
	if slice == _slice:
		return
	_slice = slice
	_slashed = slice.size() >= _MAX_BARS
	redraw()


func _paint() -> void:
	var cy := panel.size.y * 0.5
	for i in _MAX_BARS:
		_draw_tick(_PAD + i * _TICK_SPACING, cy, _seed + i, _slot_color(i))
	if _slashed:
		_draw_slash(cy)


func _slot_color(i: int) -> Color:
	if i >= _slice.size():
		return _PLACEHOLDER
	return _PURPLE if _slice[i] == 1 else _RED


func _draw_tick(x: float, cy: float, seed_val: int, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var half := _TICK_LENGTH * 0.5
	var slant := rng.randf_range(-_SLANT, _SLANT)
	var thickness := _TICK_THICKNESS + rng.randf_range(-_THICK_JITTER, _THICK_JITTER)
	var top_y := cy - half - rng.randf_range(-_LEN_JITTER, _LEN_JITTER)
	var bot_y := cy + half + rng.randf_range(-_LEN_JITTER, _LEN_JITTER)
	var length := bot_y - top_y
	var pts := PackedVector2Array()
	for s in _SEGMENTS + 1:
		var t := float(s) / float(_SEGMENTS)
		var jx := x + slant * (t - 0.5) * length + rng.randf_range(-_JITTER, _JITTER)
		pts.append(Vector2(jx, top_y + t * length))
	panel.draw_polyline(pts, color, thickness, true)


func _draw_slash(cy: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + _MAX_BARS
	var rise := _TICK_LENGTH * 0.5 * _SLASH_RISE
	var thickness := _TICK_THICKNESS + rng.randf_range(-_THICK_JITTER, _THICK_JITTER)
	var left := Vector2(_PAD - _SLASH_OVERHANG, cy + rise)
	var right := Vector2(_PAD + (_MAX_BARS - 1) * _TICK_SPACING + _SLASH_OVERHANG, cy - rise)
	var pts := PackedVector2Array()
	for s in _SEGMENTS + 1:
		var t := float(s) / float(_SEGMENTS)
		var p := left.lerp(right, t)
		p.y += rng.randf_range(-_JITTER, _JITTER)
		pts.append(p)
	panel.draw_polyline(pts, _RED, thickness, true)
