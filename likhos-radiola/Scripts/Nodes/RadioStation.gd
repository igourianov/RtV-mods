extends Node3D

# Base class for custom radio stations. A self-contained playback component: it
# owns a 3D music player and an optional static bed, and exposes start() /
# stop() / playing. Subclasses supply the track data (get_tracks) and a display
# label (get_label); all playback behavior lives here. The Radio hook drives the
# station cycle and calls start() / stop(); stations know nothing about vanilla.

const AudioChunkPlayer3D = preload("../../Lib/AudioChunkPlayer3D.gd")
const RadioBus = preload("../RadioBus.gd")

const MUSIC_VOLUME := 0.0
const UNIT_SIZE := 6.0
const MAX_DISTANCE := 15.0

# --- Static (radio hiss). Gated by static_enabled so it is easy to disable. --
const STATIC_VOLUME := -16.0
const STATIC_MIX_RATE := 22050.0
const STATIC_BUFFER := 0.2
const STATIC_FLOOR := 0.04
const STATIC_BASE_LEVEL := 0.18
const STATIC_DRIFT_CHANCE := 0.05
const STATIC_CRACKLE_CHANCE := 0.02
const STATIC_CRACKLE_MIN := 0.3
const STATIC_CRACKLE_MAX := 0.4
const STATIC_SMOOTH := 0.12

# Set from mod config by the Radio hook when the station is created.
var static_enabled := true
var playing := false

var _music: AudioChunkPlayer3D
var _static_player: AudioStreamPlayer3D
var _static_pb: AudioStreamGeneratorPlayback
var _static_level := STATIC_BASE_LEVEL
var _static_target := STATIC_BASE_LEVEL
var _tracks: Array = []
var _last_index := -1
var _streams: Dictionary = {}
var _files: Dictionary = {}


# --- Overridable by subclasses -----------------------------------------------

# path -> ordered track start offsets in seconds. The last track in a file runs
# to the file's end.
func get_tracks() -> Dictionary:
	return {}


func get_label() -> String:
	return "Station"


# --- Playback ----------------------------------------------------------------

func start() -> void:
	_ensure_music()
	if static_enabled:
		_start_static()
	playing = true
	_play_next()


func stop() -> void:
	playing = false
	if _music:
		_music.stop()
	_stop_static()


func _process(_delta: float) -> void:
	if !playing:
		return
	if !_music.is_playing():
		_play_next()
	if static_enabled:
		_fill_static()


func _ensure_music() -> void:
	if _music:
		return
	_music = AudioChunkPlayer3D.new(null, MUSIC_VOLUME, RadioBus.BUS)
	_music.unit_size = UNIT_SIZE
	_music.max_distance = MAX_DISTANCE
	add_child(_music)


func _play_next() -> void:
	if _tracks.is_empty():
		_build_tracks()
	if _tracks.is_empty():
		return

	var index := randi() % _tracks.size()
	while _tracks.size() > 1 && index == _last_index:
		index = randi() % _tracks.size()
	_last_index = index

	var entry: Array = _tracks[index]
	var path: String = entry[0]
	var track: int = entry[1]
	var stream := _get_stream(path)
	if !stream:
		return

	var starts: Array = _files[path]
	var start := float(starts[track])
	_music.stream = stream
	if track + 1 < starts.size():
		_music.play_chunk(start, starts[track + 1] - start)
	else:
		_music.play_chunk(start)


func _build_tracks() -> void:
	_files = get_tracks()
	for path in _files:
		var starts: Array = _files[path]
		for i in starts.size():
			_tracks.append([path, i])


func _get_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var stream: AudioStream = null
	if FileAccess.file_exists(path):
		stream = AudioStreamMP3.load_from_file(path)
		stream.loop = false
		_streams[path] = stream
	return stream


# --- Static ------------------------------------------------------------------

func _start_static() -> void:
	if !_static_player:
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = STATIC_MIX_RATE
		gen.buffer_length = STATIC_BUFFER
		_static_player = AudioStreamPlayer3D.new()
		_static_player.stream = gen
		_static_player.bus = RadioBus.BUS
		_static_player.volume_db = STATIC_VOLUME
		_static_player.unit_size = UNIT_SIZE
		_static_player.max_distance = MAX_DISTANCE
		add_child(_static_player)
	_static_level = STATIC_BASE_LEVEL
	_static_target = STATIC_BASE_LEVEL
	_static_player.play()
	_static_pb = _static_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _stop_static() -> void:
	if _static_player:
		_static_player.stop()
	_static_pb = null


func _fill_static() -> void:
	if !_static_pb:
		return
	# Slow swells: wander the floor toward fresh targets in the quiet band.
	if randf() < STATIC_DRIFT_CHANCE:
		_static_target = randf_range(STATIC_FLOOR, STATIC_BASE_LEVEL)
	_static_level = lerpf(_static_level, _static_target, STATIC_SMOOTH)
	# Sharp pops kick instantly above the swell, then decay back.
	if randf() < STATIC_CRACKLE_CHANCE:
		_static_level = randf_range(STATIC_CRACKLE_MIN, STATIC_CRACKLE_MAX)
	var frames := _static_pb.get_frames_available()
	for i in frames:
		var s := (randf() * 2.0 - 1.0) * _static_level
		_static_pb.push_frame(Vector2(s, s))
