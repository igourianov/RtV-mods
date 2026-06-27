extends Resource

const RadioTrack = preload("RadioTrack.gd")

static var REGISTRY: Array = []

@export var label: String = ""
@export var tracks: Array[RadioTrack] = []

var _total := 0.0


func load() -> void:
	if _total > 0.0:
		return
	tracks.shuffle()
	for track in tracks:
		_total += max(track.duration, 0.0)


func now_playing() -> RadioTrack:
	if _total <= 0.0:
		return null
	var cursor := fmod(Time.get_unix_time_from_system(), _total)
	for track in tracks:
		if cursor < track.duration:
			if !track.stream:
				track.stream = _load_stream(_resolved_source(track.source))
			if !track.stream:
				return null
			var live := RadioTrack.new()
			live.source = track.source
			live.title = track.title
			live.stream = track.stream
			live.start = track.start + cursor
			live.duration = track.duration - cursor
			return live
		cursor -= track.duration
	return null


func _resolved_source(source: String) -> String:
	if source.begins_with("res://"):
		return source.simplify_path()
	return resource_path.get_base_dir().path_join(source).simplify_path()


func _load_stream(path: String) -> AudioStream:
	if !FileAccess.file_exists(path):
		return null
	match path.get_extension().to_lower():
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		_:
			return null
