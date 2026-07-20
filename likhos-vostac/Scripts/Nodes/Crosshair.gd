extends Control

const ModConfig := preload("../ModConfig.gd")

var gameData := preload("res://Resources/GameData.tres")

const _SHADOW := Color(0, 0, 0, 0.7)
const _DOT_RADIUS := 1.5
const _ARM_LENGTH := 6.0
const _ARM_THICKNESS := 2.0
const _CENTER_GAP := 8.0
const _SHOW_DELAY := 0.2
const _FADE := 0.3
const _TOOLTIP_SHIFT := 32.0

var _alpha := 0.0
var _delay := 0.0
var _tooltip_shifted := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -12
	offset_top = -12
	offset_right = 12
	offset_bottom = 12
	modulate.a = 0.0
	hide()


func _draw() -> void:
	var center := size * 0.5
	match ModConfig.crosshair_style:
		&"dot":
			draw_circle(center + Vector2(1, 1), _DOT_RADIUS, _SHADOW)
			draw_circle(center, _DOT_RADIUS, ModConfig.crosshair_color)
		&"seg-cross":
			_draw_arms(center + Vector2(1, 1), _SHADOW)
			_draw_arms(center, ModConfig.crosshair_color)
		_:
			pass


func _draw_arms(center: Vector2, color: Color) -> void:
	var t := _ARM_THICKNESS
	var l := _ARM_LENGTH
	var g := _CENTER_GAP
	draw_rect(Rect2(center.x - t * 0.5, center.y - g - l, t, l), color, true)
	draw_rect(Rect2(center.x - t * 0.5, center.y + g, t, l), color, true)
	draw_rect(Rect2(center.x - g - l, center.y - t * 0.5, l, t), color, true)
	draw_rect(Rect2(center.x + g, center.y - t * 0.5, l, t), color, true)


func update(hud, delta: float) -> void:
	_update_visibility(delta)
	_update_tooltip(hud)


func _update_visibility(delta: float) -> void:
	var cantedHidden := gameData.isCanted && !ModConfig.crosshair_while_canted
	var runningHidden := gameData.isRunning && !ModConfig.crosshair_while_running
	var raisedHidden := gameData.weaponPosition == 2 && !ModConfig.crosshair_while_raised
	var shouldShow := !gameData.transition && !gameData.isAiming && !cantedHidden && !runningHidden && !raisedHidden && !_is_interaction_blocked() && ModConfig.crosshair_style != "off"

	var target := 0.0
	if shouldShow:
		_delay = min(_delay + delta, _SHOW_DELAY)
		if _delay >= _SHOW_DELAY:
			target = 1.0
	else:
		_delay = 0.0

	_alpha = move_toward(_alpha, target, delta / _FADE)
	modulate.a = _alpha
	visible = _alpha > 0.0


func _update_tooltip(hud) -> void:
	var wantShift := ModConfig.crosshair_style != "off"
	if wantShift != _tooltip_shifted:
		var d := _TOOLTIP_SHIFT if wantShift else -_TOOLTIP_SHIFT
		hud.tooltip.offset_top += d
		hud.tooltip.offset_bottom += d
		_tooltip_shifted = wantShift

	var aimingMode := gameData.isAiming || gameData.isCanted || gameData.weaponPosition == 2
	if aimingMode || _is_interaction_blocked():
		hud.tooltip.visible = false


func _is_interaction_blocked() -> bool:
	return gameData.freeze || gameData.menu \
		|| gameData.isDead || gameData.isTransitioning || gameData.isOccupied || gameData.isPlacing \
		|| gameData.isInspecting || gameData.isChecking || gameData.isInserting || gameData.isReloading
