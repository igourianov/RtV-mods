extends RefCounted

const RadioStation = preload("RadioStation.gd")
const RadioTrack = preload("RadioTrack.gd")
const Out = preload("../Lib/Out.gd")

static var STATIONS: Array[RadioStation] = []
static var _track_prefix := RegEx.create_from_string("^\\s*\\d+\\s*-\\s*")


static func register_dir(station_name: String, audio_dir: String) -> bool:
	var dir := DirAccess.open(audio_dir)
	if !dir:
		Out.warning("cannot open audio directory:", audio_dir)
		return false

	var tracks: Array[RadioTrack] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		var ext := fname.get_extension().to_lower()
		if ext == "mp3" || ext == "ogg":
			var stream := _load_stream(audio_dir.path_join(fname))
			if stream:
				var track := RadioTrack.new()
				track.title = _title_from_filename(fname)
				track.stream = stream
				track.duration = stream.get_length()
				tracks.append(track)
		fname = dir.get_next()

	if tracks.is_empty():
		Out.warning("no playable tracks in:", audio_dir)
		return false

	STATIONS.append(RadioStation.new(station_name, tracks))
	return true


static func _load_stream(path: String) -> AudioStream:
	if !FileAccess.file_exists(path):
		return null
	match path.get_extension().to_lower():
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
	return null


static func _title_from_filename(fname: String) -> String:
	return _track_prefix.sub(fname.get_basename(), "")
