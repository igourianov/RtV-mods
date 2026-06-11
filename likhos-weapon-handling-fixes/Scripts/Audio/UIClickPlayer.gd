extends "./AudioChunkPlayer.gd"

const _CLICK_AUDIO = preload("res://Audio/UI/Files/UI_Click.wav")
const _CLICK_VOLUME := 0.0


func _init() -> void:
	super(_CLICK_AUDIO, _CLICK_VOLUME)


func click() -> void:
	play_chunk()
