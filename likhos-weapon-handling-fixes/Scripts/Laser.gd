
const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

const _SOUND_VOLUME_DB = -10.0
const _IN_START = 0.0
const _IN_DURATION = 0.015
const _OUT_START = 0.120
const _OUT_DURATION = 0.0
const _AUTO_ON_LATCH := &"likho_laser_latch"
const _SOUND_NODE_NAME := "LikhoLaserSound"
const _PLAY_INDEX_META := &"likho_laser_play_index"

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
			caller.set_meta(_AUTO_ON_LATCH, gameData.isCanted)

func __process_post(caller):
	if !caller.visible:
		return

	var latch: bool = caller.get_meta(_AUTO_ON_LATCH, false)
	if gameData.isCanted && !gameData.isInspecting && ModConfig.laser_auto_on && !caller.active && !latch:
		caller.set_meta(_AUTO_ON_LATCH, true)
		caller.active = true
		caller.laser.show()
		_play_sound(caller, _flashlight_stream, _IN_START, _IN_DURATION)
	elif !gameData.isCanted && latch:
		caller.set_meta(_AUTO_ON_LATCH, false)
		if caller.active:
			caller.active = false
			caller.laser.hide()
			_play_sound(caller, _flashlight_stream, _OUT_START, _OUT_DURATION)


func _play_sound(caller, stream: AudioStream, start: float, duration: float) -> void:
	if !stream:
		return
	var audio: AudioStreamPlayer = caller.get_node_or_null(_SOUND_NODE_NAME)
	if !audio:
		audio = AudioStreamPlayer.new()
		audio.name = _SOUND_NODE_NAME
		audio.bus = &"SFX"
		audio.volume_db = _SOUND_VOLUME_DB
		caller.add_child(audio)
	else:
		audio.stop()
	audio.stream = stream
	var play_index: int = audio.get_meta(_PLAY_INDEX_META, 0) + 1
	audio.set_meta(_PLAY_INDEX_META, play_index)
	audio.play(start)
	if duration > 0.0:
		await caller.get_tree().create_timer(duration, false).timeout
		if is_instance_valid(audio) && audio.get_meta(_PLAY_INDEX_META, 0) == play_index:
			audio.stop()

