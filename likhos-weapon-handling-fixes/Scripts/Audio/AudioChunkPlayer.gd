extends AudioStreamPlayer


func _init(audio_stream: AudioStream, volume := 0.0) -> void:
	stream = audio_stream
	volume_db = volume
	max_polyphony = 10


func play_chunk(start := 0.0, duration := 0.0) -> AudioStreamPlayback:
	if !stream:
		return null
	play(start)
	var playback := get_stream_playback()
	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(_stop_playback.bind(playback))
	return playback


func _stop_playback(playback: AudioStreamPlayback) -> void:
	if playback && playback.is_playing():
		playback.stop()
