extends "./AudioChunkPlayer.gd"

const STREAM_PATH := "res://mods/likhos-weapon-handling-fixes/Audio/hold_breath.mp3"
const INTRO_DURATION := 0.5
const OUTRO_START := 0.5


func _init() -> void:
	super(AudioStreamMP3.load_from_file(STREAM_PATH))


func hold() -> void:
	if playing:
		return
	play_chunk(0.0, INTRO_DURATION)


func release() -> void:
	play_chunk(OUTRO_START, 0.0)
