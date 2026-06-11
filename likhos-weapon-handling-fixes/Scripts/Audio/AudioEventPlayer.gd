extends AudioStreamPlayer


func play_event(event) -> void:
	if !event || event.audioClips.is_empty():
		return
	if !await _stop_before():
		return
	stream_paused = false
	stream = event.audioClips.pick_random()
	volume_db = event.volume
	play()
	await finished


func _stop_before() -> bool:
	if !playing:
		return true
	stop()
	finished.emit()
	while playing:
		await get_tree().process_frame
		if !is_instance_valid(self):
			return false
	return true
