extends AudioStreamPlayer

var _duration := 0.0


func _init(audio_stream: AudioStream = null, volume := 0.0) -> void:
	stream = audio_stream
	volume_db = volume
	max_polyphony = 10
	set_process(false)


func play_chunk(start := 0.0, duration := 0.0) -> void:
	if !stream:
		return
	play(start)
	if duration > 0.0:
		_duration = duration
		set_process(true)
	else:
		set_process(false)


func _process(delta: float) -> void:
	_duration -= delta
	if _duration <= 0.0:
		set_process(false)
		if playing:
			stop()
