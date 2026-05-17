
const ModConfig = preload("./ModConfig.gd")

const _IN_START = 0.0
const _IN_DURATION = 0.015
const _OUT_START = 0.120
const _OUT_DURATION = 0.0
const _AUTO_ON_LATCH := &"likho_laser_latch"
const _POINTING_CHANNEL_PATH := "/root/Map/Core/Controller/Character/LikhoPointingDeviceSound"

var _lib
var gameData = preload("res://Resources/GameData.tres")
var _auto_on_latch := false


func _init(lib) -> void:
	_lib = lib


func on_input(event: InputEvent) -> void:
	_lib.skip_super()
	__input(_lib._caller, event)


func on_process_post(_delta: float) -> void:
	__process_post(_lib._caller)


func __input(caller, event: InputEvent):
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

func __process_post(caller):
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


func _play_click(caller, start: float, duration: float) -> void:
	var channel = caller.get_node_or_null(_POINTING_CHANNEL_PATH)
	if channel:
		channel.play_stream(null, start, duration)
