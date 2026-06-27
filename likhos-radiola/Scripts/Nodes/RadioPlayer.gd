extends Node3D

const AudioChunkPlayer3D = preload("../../Lib/AudioChunkPlayer3D.gd")
const RadioBus = preload("../RadioBus.gd")
const RadioStation = preload("../RadioStation.gd")

const MUSIC_VOLUME := 0.0
const UNIT_SIZE := 6.0
const MAX_DISTANCE := 15.0

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

var static_enabled := true
var playing := false
var station: RadioStation

var _music: AudioChunkPlayer3D
var _static_player: AudioStreamPlayer3D
var _static_pb: AudioStreamGeneratorPlayback
var _static_level := STATIC_BASE_LEVEL
var _static_target := STATIC_BASE_LEVEL
var _on_air := false


func start(to_station: RadioStation) -> void:
	_ensure_music()
	_music.stop()
	_stop_tuning()
	_stop_static()
	station = to_station
	playing = true
	_on_air = false
	if station:
		station.load()
	_try_go_on_air()


func stop() -> void:
	playing = false
	station = null
	_on_air = false
	if _music:
		_music.stop()
	_stop_tuning()
	_stop_static()


func _process(_delta: float) -> void:
	if !playing:
		return
	if !_on_air:
		_pump_tuning()
		_try_go_on_air()
	elif !_music.is_playing():
		_play_current()
	if static_enabled:
		_fill_static()


func _try_go_on_air() -> void:
	if !station || !station.is_ready():
		return
	_on_air = true
	_stop_tuning()
	if static_enabled:
		_start_static()
	_play_current()


func _play_current() -> void:
	var track := station.now_playing()
	if !track:
		return
	_music.stream = track.stream
	_music.play_chunk(track.start, track.duration)


func _ensure_music() -> void:
	if _music:
		return
	_music = AudioChunkPlayer3D.new(null, MUSIC_VOLUME, RadioBus.BUS)
	_music.unit_size = UNIT_SIZE
	_music.max_distance = MAX_DISTANCE
	add_child(_music)


func _radio() -> Node:
	return get_parent()


func _pump_tuning() -> void:
	var r := _radio()
	if !r || !r.tuning:
		return
	if !r.tuning.is_playing():
		r.tuning.stream = r.GetRandomTuningClip()
		r.tuning.play()


func _stop_tuning() -> void:
	var r := _radio()
	if r && r.tuning:
		r.tuning.stop()


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
	if randf() < STATIC_DRIFT_CHANCE:
		_static_target = randf_range(STATIC_FLOOR, STATIC_BASE_LEVEL)
	_static_level = lerpf(_static_level, _static_target, STATIC_SMOOTH)
	if randf() < STATIC_CRACKLE_CHANCE:
		_static_level = randf_range(STATIC_CRACKLE_MIN, STATIC_CRACKLE_MAX)
	var frames := _static_pb.get_frames_available()
	for i in frames:
		var s := (randf() * 2.0 - 1.0) * _static_level
		_static_pb.push_frame(Vector2(s, s))
