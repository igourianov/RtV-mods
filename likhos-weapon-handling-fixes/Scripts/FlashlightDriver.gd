extends Node

const Out = preload("../Lib/Out.gd")

const SOUND_VOLUME_DB = -12.0
const IN_START = 0.0
const IN_DURATION = 0.015
const OUT_START = 0.120
const OUT_DURATION = 0.0
const HOLD_THRESHOLD = 0.25

const _flashlight_audio = preload("res://Audio/Interaction/Files/Flashlight.wav")

var gameData = preload("res://Resources/GameData.tres")
var _hold_elapsed := 0.0


func _physics_process(delta: float):
	if gameData.flashlight:
		_hold_elapsed += delta


func _input(evt: InputEvent) -> void:
	var parent = get_parent()
	var slot = parent.lightSlot
	var light = slot.get_child(0) if slot && slot.get_child_count() else null

	if !light:
		return

	if evt.is_action_pressed("flashlight", false) && !gameData.freeze:
		_play_sound(IN_START, IN_DURATION)
		if !gameData.flashlight:
			parent.Activate()
			_hold_elapsed = 0.0
	elif evt.is_action_released("flashlight") && gameData.flashlight:
		_play_sound(OUT_START, OUT_DURATION)
		if _hold_elapsed > HOLD_THRESHOLD:
			parent.Deactivate()


func _play_sound(start: float, duration: float) -> void:
	var audio = get_parent().audioInstance2D.instantiate()
	add_child(audio)
	audio.stream = _flashlight_audio
	audio.volume_db = SOUND_VOLUME_DB
	audio.play(start)
	if duration > 0.0:
		await get_tree().create_timer(duration, false).timeout
		if is_instance_valid(audio):
			audio.stop()
