extends Node

const Out = preload("../Lib/Out.gd")
const Inputs = preload("../Lib/Inputs.gd")
const SoundChannel = preload("./SoundChannel.gd")


var gameData = preload("res://Resources/GameData.tres")
var _audio_channel


func is_engine_busy() -> bool:
	return (gameData.freeze
		|| gameData.isDead
		|| gameData.isPlacing
		|| gameData.isDrawing
		|| gameData.isCaching
		|| gameData.isTransitioning
		|| gameData.isOccupied)


func play(animation_state: String, audio_event, wait_offset: float = -0.5) -> void:
	Out.debug("play:", animation_state)
	start_audio(audio_event)
	var playback = start_animation(animation_state)
	await await_animation(wait_offset, playback)
	Out.debug("play done")


func await_animation(wait_offset: float = 0.0, playback = null) -> void:
	if !playback:
		playback = get_parent().animator.get("parameters/playback")
	await get_tree().create_timer(0.1, false).timeout
	if !is_instance_valid(self):
		return
	var wait_time: float = playback.get_current_length() - playback.get_current_play_position() + wait_offset
	if wait_time > 0.0:
		Out.debug("awaiting animation:", wait_time)
		await get_tree().create_timer(wait_time, false).timeout


func start_animation(state_name: String):
	Out.debug("start_animation:", state_name)
	var playback = get_parent().animator.get("parameters/playback")
	playback.start(state_name)
	return playback


func start_audio(event) -> AudioStreamPlayer:
	if !is_instance_valid(_audio_channel):
		_audio_channel = SoundChannel.new()
		add_child(_audio_channel)
	_audio_channel.play_event(event)
	return _audio_channel
