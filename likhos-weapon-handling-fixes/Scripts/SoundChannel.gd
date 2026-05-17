extends AudioStreamPlayer

var _play_index := 0
var _default_stream: AudioStream


func _init(audio_bus := &"SFX", volume := 0.0, default_stream: AudioStream = null) -> void:
	bus = audio_bus
	volume_db = volume
	_default_stream = default_stream


func play_stream(audio_stream: AudioStream = null, start := 0.0, duration := 0.0) -> void:
	stream = audio_stream if audio_stream else _default_stream
	if !stream:
		return
	stop()
	stream_paused = false
	pitch_scale = 1.0
	_play_index += 1
	var index := _play_index
	play(start)
	if duration > 0.0:
		await get_tree().create_timer(duration, false).timeout
		if is_instance_valid(self) && _play_index == index:
			stop()


func play_event(event) -> void:
	if !event || event.audioClips.is_empty():
		return
	stop()
	stream_paused = false
	stream = event.audioClips.pick_random()
	if event.randomPitch:
		volume_db = randf_range(event.volume - 1.0, event.volume)
		pitch_scale = randf_range(0.9, 1.0)
	else:
		volume_db = event.volume
		pitch_scale = 1.0
	play()
