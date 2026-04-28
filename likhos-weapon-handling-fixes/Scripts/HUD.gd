extends RefCounted

var _lib

const _CROSSHAIR_COLOR := Color(1.0, 0.4, 0.0, 0.65)
const _CROSSHAIR_SHADOW := Color(0, 0, 0, 0.7)
const _ARM_LENGTH := 6.0
const _ARM_THICKNESS := 2.0
const _CENTER_GAP := 8.0

func _init(lib) -> void:
	_lib = lib

func on_ready_post() -> void:
	var hud = _lib._caller
	if !hud:
		return
	if hud.has_meta("hud_tweaks_crosshair"):
		return
	var crosshair := Control.new()
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12
	crosshair.offset_top = -12
	crosshair.offset_right = 12
	crosshair.offset_bottom = 12
	crosshair.draw.connect(_draw_crosshair.bind(crosshair))
	hud.add_child(crosshair)
	hud.set_meta("hud_tweaks_crosshair", crosshair)
	crosshair.hide()

	hud.tooltip.offset_top += 32
	hud.tooltip.offset_bottom += 32

func on_physics_process_post(_delta: float) -> void:
	var hud = _lib._caller
	if !hud:
		return
	var gd = hud.gameData
	var isAimingMode = gd.isAimin || gd.isCanted || gd.weaponPosition == 2
	hud.tooltip.visible = gd.interaction && !gd.transition && !isAimingMode
	var crosshair = hud.get_meta("hud_tweaks_crosshair", null)
	if !crosshair:
		return
	if gd.menu || gd.isDead || gd.isInspecting || gd.transition || gd.isTransitioning:
		crosshair.hide()
		return
	var aimable = gd.primary || gd.secondary
	crosshair.visible = !isAimingMode || !aimable

func _draw_crosshair(c: Control) -> void:
	var center := c.size * 0.5
	_draw_arms(c, center + Vector2(1, 1), _CROSSHAIR_SHADOW)
	_draw_arms(c, center, _CROSSHAIR_COLOR)

func _draw_arms(c: Control, center: Vector2, color: Color) -> void:
	var t := _ARM_THICKNESS
	var l := _ARM_LENGTH
	var g := _CENTER_GAP
	c.draw_rect(Rect2(center.x - t * 0.5, center.y - g - l, t, l), color, true)
	c.draw_rect(Rect2(center.x - t * 0.5, center.y + g, t, l), color, true)
	c.draw_rect(Rect2(center.x - g - l, center.y - t * 0.5, l, t), color, true)
	c.draw_rect(Rect2(center.x + g, center.y - t * 0.5, l, t), color, true)
