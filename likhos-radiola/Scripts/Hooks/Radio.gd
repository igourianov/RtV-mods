extends RefCounted

const RadioStation = preload("../RadioStation.gd")
const RadioPlayer = preload("../Nodes/RadioPlayer.gd")
const META_PLAYER := "radio_player"

var _lib


func _init(lib) -> void:
	_lib = lib


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
	if !radio.has_meta(META_PLAYER) || RadioStation.REGISTRY.is_empty():
		return
	var player = radio.get_meta(META_PLAYER)
	var label := "Off"
	if radio.active:
		label = "Area 05"
	elif player.playing:
		label = player.station.label
	radio.gameData.tooltip = "Radio [%s]" % label


func _player(radio) -> RadioPlayer:
	if radio.has_meta(META_PLAYER):
		return radio.get_meta(META_PLAYER)
	var p = RadioPlayer.new()
	p.name = "RadioPlayer"
	radio.add_child(p)
	radio.set_meta(META_PLAYER, p)
	return p
