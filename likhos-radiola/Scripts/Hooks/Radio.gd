extends RefCounted

# Hooks the shelter radio. Interact is replaced so the on/off toggle becomes a
# cycle through the vanilla station and every registered custom station:
#   Off -> Vanilla -> Station 0 -> Station 1 -> ... -> Off
# Vanilla runs on the two presses where its own on/off toggle is what we want (we
# simply don't skip_super); it is suppressed on every station-to-station hop and
# the final station-to-off press. UpdateTooltip is post-patched to relabel the
# prompt with the next station's name.
#
# Stations are global: one instance of each broadcasts to every radio (they turn
# the wall clock into the schedule, so all radios stay in sync). Each radio gets
# one RadioPlayer for positional playback. State is single-sourced: vanilla owns
# `active`, the player owns `playing` + which station it is tuned to. Stations come
# ready-made from RadioStation.REGISTRY, populated by separately-installed station packs.

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
		return     # no custom stations: vanilla owns the whole Off <-> Vanilla toggle
	var player := _player(radio)
	var i := _tuned_index(player, stations)
	if radio.active:
		# Vanilla -> first station: start ours, let vanilla turn its station off.
		player.start(stations[0])
	elif i != -1:
		# Station -> next station, or -> off on the last one.
		if i + 1 < stations.size():
			player.start(stations[i + 1])
		else:
			player.stop()
			radio.InteractAudio()
		_lib.skip_super()
	# Off -> Vanilla: do nothing, let vanilla turn its station on.


func on_update_tooltip_post() -> void:
	var radio = _lib._caller
	if !radio.has_meta("radio_player"):
		return
	var stations := RadioStation.REGISTRY
	if stations.is_empty():
		return
	var player = radio.get_meta("radio_player")
	var i := _tuned_index(player, stations)
	if radio.active:
		radio.gameData.tooltip = "Radio [%s]" % stations[0].label
	elif i != -1 && i + 1 < stations.size():
		radio.gameData.tooltip = "Radio [%s]" % stations[i + 1].label
	elif i != -1:
		radio.gameData.tooltip = "Radio [Turn Off]"


# This radio's playback node, created on first use and cached on the radio.
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
