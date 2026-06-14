extends "./InspectCard.gd"

const _MAX_BARS := 10
const _TICK_SPACING := 9.0
const _TICK_LENGTH := 28.0
const _TICK_THICKNESS := 2.0
const _PAD := 14.0
const _SEGMENTS := 4
const _SEG_LEN := _TICK_LENGTH / _SEGMENTS
const _JITTER := 1.3
const _SLANT := 0.12
const _LEN_JITTER := 3.0
const _THICK_JITTER := 1.0
const _SLASH_OVERHANG := 9.0
const _SLASH_RISE := 0.55
const _SHADOW_GROW := 2.0
const _TAPER_LEN := 8.0
const _END_TAPER := 0.18
const _WIDTH_JITTER := 0.6
const _WIDTH := (_MAX_BARS - 1) * _TICK_SPACING + _PAD * 2.0
const _HEIGHT := _TICK_LENGTH + _PAD * 2.0

const _KILL_COLOR := Color(1, 1, 1)
const _BOSS_KILL_COLOR := Color(0.62, 0.2, 0.85)
const _PLACEHOLDER_COLOR := Color(0.25, 0.25, 0.25, 0.2)
const _SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)

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
		return _PLACEHOLDER_COLOR
	return _BOSS_KILL_COLOR if _slice[i] == 1 else _KILL_COLOR


func _draw_tick(x: float, cy: float, seed_val: int, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var half := _TICK_LENGTH * 0.5
	var slant := rng.randf_range(-_SLANT, 0.0)
	var thickness := _TICK_THICKNESS + rng.randf_range(-_THICK_JITTER, _THICK_JITTER)
	var top_y := cy - half - rng.randf_range(-_LEN_JITTER, _LEN_JITTER)
	var bot_y := cy + half + rng.randf_range(-_LEN_JITTER, _LEN_JITTER)
	var pts := _build_centerline(Vector2(x, top_y), Vector2(x, bot_y), slant, rng)
	_draw_stroke(pts, color, thickness, rng)


func _draw_slash(cy: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + _MAX_BARS
	var rise := _TICK_LENGTH * 0.5 * _SLASH_RISE
	var thickness := _TICK_THICKNESS + rng.randf_range(-_THICK_JITTER, _THICK_JITTER)
	var a := Vector2(_PAD - _SLASH_OVERHANG, cy + rise)
	var b := Vector2(_PAD + (_MAX_BARS - 1) * _TICK_SPACING + _SLASH_OVERHANG, cy - rise)
	var pts := _build_centerline(a, b, 0.0, rng)
	var saved := rng.state
	_draw_stroke(pts, _SHADOW_COLOR, thickness + _SHADOW_GROW, rng)
	rng.state = saved
	_draw_stroke(pts, _KILL_COLOR, thickness, rng)


func _build_centerline(a: Vector2, b: Vector2, bow: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var axis := b - a
	var length := axis.length()
	var seg := maxi(2, roundi(length / _SEG_LEN))
	var normal := Vector2(axis.y, -axis.x).normalized()
	var pts := PackedVector2Array()
	for s in seg + 1:
		var t := float(s) / float(seg)
		var off := bow * (t - 0.5) * length + rng.randf_range(-_JITTER, _JITTER)
		pts.append(a.lerp(b, t) + normal * off)
	return pts


func _taper(edge_dist: float) -> float:
	var t := clampf(edge_dist / _TAPER_LEN, 0.0, 1.0)
	return lerp(_END_TAPER, 1.0, smoothstep(0.0, 1.0, t))


func _draw_stroke(pts: PackedVector2Array, color: Color, thickness: float, rng: RandomNumberGenerator) -> void:
	var n := pts.size()
	var base_half := thickness * 0.5
	var dist := PackedFloat32Array()
	dist.resize(n)
	dist[0] = 0.0
	for i in range(1, n):
		dist[i] = dist[i - 1] + pts[i].distance_to(pts[i - 1])
	var total := dist[n - 1]
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n:
		var dir: Vector2
		if i == 0:
			dir = pts[1] - pts[0]
		elif i == n - 1:
			dir = pts[n - 1] - pts[n - 2]
		else:
			dir = pts[i + 1] - pts[i - 1]
		var normal := Vector2(-dir.normalized().y, dir.normalized().x)
		var half := maxf(base_half * _taper(minf(dist[i], total - dist[i])) + rng.randf_range(-_WIDTH_JITTER, _WIDTH_JITTER), 0.2)
		left.append(pts[i] + normal * half)
		right.append(pts[i] - normal * half)
	for i in n - 1:
		panel.draw_colored_polygon(PackedVector2Array([left[i], left[i + 1], right[i + 1], right[i]]), color)
	var boundary := left.duplicate()
	right.reverse()
	boundary.append_array(right)
	boundary.append(boundary[0])
	panel.draw_polyline(boundary, color, 1.0, true)
