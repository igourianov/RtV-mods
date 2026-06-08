
const ModConfig = preload("./ModConfig.gd")

const _IN_START = 0.0
const _IN_DURATION = 0.015
const _OUT_START = 0.120
const _OUT_DURATION = 0.0
const _AUTO_ON_LATCH := &"likho_laser_latch"
const _RECOLOR_LATCH := &"likho_laser_recolor"
const _POINTING_CHANNEL_PATH := "/root/Map/Core/Controller/Character/LikhoPointingDeviceSound"
const _PEQ15_NAME := &"ANPEQ"
const _PEQ15_COLOR := Color(1, 0, 0, 1)

var _lib
var gameData = preload("res://Resources/GameData.tres")
var _auto_on_latch := false


func _init(lib) -> void:
	_lib = lib


func on_input(event: InputEvent) -> void:
	_lib.skip_super()
	__input(_lib._caller, event)


func on_process_post(_delta: float) -> void:
	_recolor(_lib._caller)
	__process_post(_lib._caller)


func __input(caller, event: InputEvent) -> void:
	if !caller.visible:
		return

	if event.is_action_pressed("laser"):
		caller.active = !caller.active
		caller.PlayLaser()
		if caller.active:
			caller.laser.show()
		else:
			caller.laser.hide()
			caller.set_meta(_AUTO_ON_LATCH, gameData.isCanted)


func __process_post(caller) -> void:
	if !caller.visible:
		return

	var latch: bool = caller.get_meta(_AUTO_ON_LATCH, false)
	if gameData.isCanted && !gameData.isInspecting && ModConfig.laser_auto_on && !caller.active && !latch:
		caller.set_meta(_AUTO_ON_LATCH, true)
		caller.active = true
		caller.laser.show()
		_play_click(caller, _IN_START, _IN_DURATION)
	elif !gameData.isCanted && latch:
		caller.set_meta(_AUTO_ON_LATCH, false)
		if caller.active:
			caller.active = false
			caller.laser.hide()
			_play_click(caller, _OUT_START, _OUT_DURATION)


func _recolor(caller) -> void:
	if caller.get_meta(_RECOLOR_LATCH, false):
		return
	caller.set_meta(_RECOLOR_LATCH, true)

	if caller.name != _PEQ15_NAME:
		return

	_tint_mesh(caller.laser.get_node_or_null("Beam"))
	_tint_mesh(caller.laser.get_node_or_null("Point"))

	var light = caller.laser.get_node_or_null("Point/Light")
	if light:
		light.light_color = _PEQ15_COLOR


func _tint_mesh(mesh) -> void:
	if !mesh:
		return

	var material = mesh.get_surface_override_material(0)
	if !material:
		return

	material = material.duplicate()
	material.set_shader_parameter("tint", _PEQ15_COLOR)
	mesh.set_surface_override_material(0, material)


func _play_click(caller, start: float, duration: float) -> void:
	var channel = caller.get_node_or_null(_POINTING_CHANNEL_PATH)
	if channel:
		channel.play_stream(null, start, duration)
