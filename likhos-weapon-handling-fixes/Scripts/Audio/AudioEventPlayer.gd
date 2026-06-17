extends AudioStreamPlayer


func play_event(event) -> AudioStreamPlayback:
	if !event || !event.audioClips || event.audioClips.is_empty():
		return null
	#stream_paused = false
	stream = event.audioClips.pick_random()
	volume_db = event.volume
	play()
	return get_stream_playback()
