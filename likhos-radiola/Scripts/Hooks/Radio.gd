extends RefCounted

const RadioStation = preload("../RadioStation.gd")
const RadioPlayer = preload("../Nodes/RadioPlayer.gd")

var _lib
var _static_enabled := true


func _init(lib, static_enabled := true) -> void:
	_lib = lib
	_static_enabled = static_enabled


func on_interact() -> void:
	var radio = _lib._caller
	var stations := RadioStation.REGISTRY
	if stations.is_empty():
		return

	var player := _player(radio)

	# OFF -> Vanilla: let vanilla turn itself on.
	if !radio.active && !player.playing:
		return

	# Vanilla -> first station: let vanilla turn off, start ours.
	if radio.active:
		player.start(stations[0])
		return

	# On a station: advance, or stop after the last. Keep vanilla off.
	_lib.skip_super()
	var i := stations.find(player.station)
	if i + 1 < stations.size():
		player.start(stations[i + 1])
		return

	player.stop()
	radio.InteractAudio()


func on_update_tooltip_post() -> void:
	var radio = _lib._caller
	if !radio.has_meta("radio_player"):
		return
	var stations := RadioStation.REGISTRY
	if stations.is_empty():
		return
	var player = radio.get_meta("radio_player")
	var i := _tuned_index(player, stations)
	if i != -1:
		radio.gameData.tooltip = "Radio [%s]" % stations[i].label
	elif radio.active:
		radio.gameData.tooltip = "Radio [Vostoc]"
	else:
		radio.gameData.tooltip = "Radio [Off]"


func _player(radio) -> RadioPlayer:
	if radio.has_meta("radio_player"):
		return radio.get_meta("radio_player")
	var p = RadioPlayer.new()
	p.name = "RadioPlayer"
	p.static_enabled = _static_enabled
	radio.add_child(p)
	radio.set_meta("radio_player", p)
	return p


func _tuned_index(player: RadioPlayer, stations: Array[RadioStation]) -> int:
	if !player.playing:
		return -1
	return stations.find(player.station)
