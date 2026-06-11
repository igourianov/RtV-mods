extends "./AudioChunkPlayer.gd"

const _CLICK_AUDIO = preload("res://Audio/Interaction/Files/Flashlight.wav")
const _CLICK_VOLUME := -10.0
const _IN_START := 0.0
const _IN_DURATION := 0.015
const _OUT_START := 0.120
const _OUT_DURATION := 0.0


func _init() -> void:
	super(_CLICK_AUDIO, _CLICK_VOLUME)


func click_in() -> void:
	play_chunk(_IN_START, _IN_DURATION)


func click_out() -> void:
	play_chunk(_OUT_START, _OUT_DURATION)
