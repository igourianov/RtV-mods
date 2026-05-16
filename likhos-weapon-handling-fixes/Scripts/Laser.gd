
const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

const _SOUND_VOLUME_DB = -12.0
const _IN_START = 0.0
const _IN_DURATION = 0.015
const _OUT_START = 0.120
const _OUT_DURATION = 0.0
const _AUTO_ON_LATCH_NAME := &"likho_laser_latch"

var _lib
var _flashlight_stream: AudioStream = load("res://Audio/Interaction/Files/Flashlight.wav")
var gameData = preload("res://Resources/GameData.tres")
var _auto_on_latch := false


func _init(lib) -> void:
	_lib = lib
	if _flashlight_stream == null:
		Out.warning("failed to load flashlight audio")


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

func __process_post(caller):
	if !caller.visible:
		return

	var latch: bool = caller.get_meta(_AUTO_ON_LATCH_NAME, false)
	if gameData.isCanted && ModConfig.laser_auto_on && !caller.active && !latch:
		caller.set_meta(_AUTO_ON_LATCH_NAME, true)
		caller.active = true
		caller.laser.show()
		_play_sound(caller, _IN_START, _IN_DURATION)
	elif !gameData.isCanted && latch:
		caller.set_meta(_AUTO_ON_LATCH_NAME, false)
		if caller.active:
			caller.active = false
			caller.laser.hide()
			_play_sound(caller, _OUT_START, _OUT_DURATION)


func _play_sound(caller, start: float, duration: float) -> void:
	if !_flashlight_stream:
		return
	var audio = caller.audioInstance2D.instantiate()
	caller.add_child(audio)
	audio.stream = _flashlight_stream
	audio.volume_db = _SOUND_VOLUME_DB
	audio.play(start)
	if duration > 0.0:
		await caller.get_tree().create_timer(duration, false).timeout
		if is_instance_valid(audio):
			audio.stop()
