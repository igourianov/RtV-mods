extends AudioStreamPlayer


func _init(audio_stream: AudioStream = null, volume := 0.0) -> void:
	stream = audio_stream
	volume_db = volume
	max_polyphony = 10


func play_chunk(start := 0.0, duration := 0.0) -> void:
	if !stream:
		return
	play(start)
	if duration <= 0.0:
		return
	get_tree().create_timer(duration).timeout.connect(_stop_playback.bind(get_stream_playback()))


func _stop_playback(playback: AudioStreamPlayback) -> void:
	if playback && playback.is_playing():
		playback.stop()
