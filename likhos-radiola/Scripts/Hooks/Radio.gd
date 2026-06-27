extends RefCounted

const RadioStation = preload("../RadioStation.gd")
const RadioPlayer = preload("../Nodes/RadioPlayer.gd")
const ModConfig = preload("../ModConfig.gd")
const META_PLAYER := "radio_player"
const META_AUTOROLL := "radio_autoroll"

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


func on_physics_process_pre(_delta) -> void:
	var radio = _lib._caller
	if radio.has_meta(META_AUTOROLL):
		return
	radio.set_meta(META_AUTOROLL, true)

	if randf() * 100.0 >= ModConfig.on_chance:
		return

	var stations := RadioStation.REGISTRY
	var pick := randi() % (stations.size() + 1)
	if pick == 0:
		radio.active = true
		return

	_player(radio).start(stations[pick - 1])


func on_update_tooltip_post() -> void:
	if RadioStation.REGISTRY.is_empty():
		return
	var radio = _lib._caller
	var state: String
	if radio.active:
		state = "Area 05"
	elif !radio.has_meta(META_PLAYER):
		state = "Off"
	else:
		var player = radio.get_meta(META_PLAYER)
		state = player.station.label if player.playing else "Off"

	radio.gameData.tooltip = "Radio [%s]" % state


func _player(radio) -> RadioPlayer:
	if radio.has_meta(META_PLAYER):
		return radio.get_meta(META_PLAYER)
	var p = RadioPlayer.new()
	p.name = "RadioPlayer"
	radio.add_child(p)
	radio.set_meta(META_PLAYER, p)
	return p
