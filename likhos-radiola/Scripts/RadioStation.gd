extends Resource

const RadioTrack = preload("RadioTrack.gd")

var name: String = ""
var tracks: Array[RadioTrack] = []

var _total := 0.0


class Cue extends "RadioTrack.gd":
	var start: float = 0.0


func _init(station_name: String = "", station_tracks: Array[RadioTrack] = []) -> void:
	name = station_name
	tracks = station_tracks
	tracks.shuffle()
	for track in tracks:
		_total += track.duration


func now_playing() -> Cue:
	if tracks.is_empty():
		return null
	var cursor := fmod(Time.get_unix_time_from_system(), _total)
	for track in tracks:
		if cursor < track.duration:
			var cue := Cue.new()
			cue.stream = track.stream
			cue.title = track.title
			cue.start = cursor
			cue.duration = track.duration - cursor
			return cue
		cursor -= track.duration
	return null
