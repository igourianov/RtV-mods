extends RefCounted

# Hooks the shelter radio. Interact is replaced so the on/off toggle becomes a
# cycle through the vanilla station and every registered custom station:
#   Off -> Vanilla -> Station 0 -> Station 1 -> ... -> Off
# Vanilla runs on the two presses where its own on/off toggle is what we want (we
# simply don't skip_super); it is suppressed on every station-to-station hop and
# the final station-to-off press. UpdateTooltip is post-patched to relabel the
# prompt with the next station's name.
#
# State is single-sourced: vanilla owns `active`, each station owns `playing`. At
# most one station plays at a time. To add a station, append its script here.

const STATIONS := [
	preload("../Nodes/DoomerStation.gd"),
]

var _lib
var _static_enabled := true


func _init(lib, static_enabled := true) -> void:
	_lib = lib
	_static_enabled = static_enabled


func on_interact() -> void:
	var radio = _lib._caller
	var stations = _ensure_stations(radio)
	var i := _playing_index(stations)
	if radio.active:
		# Vanilla -> first station: start ours, let vanilla turn its station off.
		stations[0].start()
	elif i != -1:
		# Station -> next station, or -> off on the last one.
		stations[i].stop()
		if i + 1 < stations.size():
			stations[i + 1].start()
		else:
			radio.InteractAudio()
		_lib.skip_super()
	# Off -> Vanilla: do nothing, let vanilla turn its station on.


func on_update_tooltip_post() -> void:
	var radio = _lib._caller
	if radio.has_meta("radio_stations"):
		var stations = radio.get_meta("radio_stations")
		var i := _playing_index(stations)
		if radio.active:
			radio.gameData.tooltip = "Radio [%s]" % stations[0].get_label()
		elif i != -1 && i + 1 < stations.size():
			radio.gameData.tooltip = "Radio [%s]" % stations[i + 1].get_label()
		elif i != -1:
			radio.gameData.tooltip = "Radio [Turn Off]"


func _ensure_stations(radio) -> Array:
	if radio.has_meta("radio_stations"):
		return radio.get_meta("radio_stations")
	var nodes: Array = []
	for i in STATIONS.size():
		var station = STATIONS[i].new()
		station.name = "RadioStation%d" % i
		station.static_enabled = _static_enabled
		radio.add_child(station)
		nodes.append(station)
	radio.set_meta("radio_stations", nodes)
	return nodes


func _playing_index(stations: Array) -> int:
	for i in stations.size():
		if stations[i].playing:
			return i
	return -1
