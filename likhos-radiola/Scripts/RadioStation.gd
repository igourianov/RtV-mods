extends Resource

const RadioTrack = preload("RadioTrack.gd")

static var REGISTRY: Array = []

@export var label: String = ""
@export var tracks: Array[RadioTrack] = []

var _total := 0.0
var _load_task := -1
var _ready := false


func load() -> void:
	if _ready || _load_task != -1:
		return
	_load_task = WorkerThreadPool.add_task(_decode)


func is_ready() -> bool:
	if _ready:
		return true
	if _load_task == -1 || !WorkerThreadPool.is_task_completed(_load_task):
		return false
	WorkerThreadPool.wait_for_task_completion(_load_task)
	_ready = true
	return true


func now_playing() -> RadioTrack:
	if _total <= 0.0:
		return null
	var cursor := fmod(Time.get_unix_time_from_system(), _total)
	for track in tracks:
		if !track.stream:
			continue
		if cursor < track.duration:
			var live := RadioTrack.new()
			live.source = track.source
			live.title = track.title
			live.stream = track.stream
			live.start = track.start + cursor
			live.duration = track.duration - cursor
			return live
		cursor -= track.duration
	return null


func _decode() -> void:
	var decoded: Dictionary = {}
	for track in tracks:
		var key := _resolved_source(track.source)
		if !decoded.has(key):
			decoded[key] = _load_stream(key)
		track.stream = decoded[key]
		if track.stream:
			if track.duration <= 0.0:
				track.duration = track.stream.get_length() - track.start
			_total += track.duration
	_shuffle(tracks)


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


# Runs on a worker thread, so it uses a local RNG instead of Array.shuffle()'s global one.
func _shuffle(deck: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(deck.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp
