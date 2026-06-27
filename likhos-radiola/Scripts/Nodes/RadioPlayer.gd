extends Node3D

const AudioChunkPlayer3D = preload("../../Lib/AudioChunkPlayer3D.gd")
const StaticNoisePlayer3D = preload("StaticNoisePlayer3D.gd")
const ModConfig = preload("../ModConfig.gd")
const RadioBus = preload("../RadioBus.gd")
const RadioStation = preload("../RadioStation.gd")

const MUSIC_VOLUME := 0.0
const UNIT_SIZE := 6.0
const MAX_DISTANCE := 15.0

const STATIC_VOLUME := -16.0

var playing := false
var station: RadioStation

var _music: AudioChunkPlayer3D
var _static: StaticNoisePlayer3D
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
	_sync_static()


func _try_go_on_air() -> void:
	if !station || !station.is_ready():
		return
	_on_air = true
	_stop_tuning()
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


# reconciles the static bed against live MCM state each frame, so toggling it applies mid-broadcast
func _sync_static() -> void:
	var want := _on_air && ModConfig.static_enabled
	if want && (!_static || !_static.playing):
		_start_static()
	elif !want && _static && _static.playing:
		_stop_static()


func _start_static() -> void:
	if !_static:
		_static = StaticNoisePlayer3D.new(RadioBus.BUS, STATIC_VOLUME, UNIT_SIZE, MAX_DISTANCE)
		add_child(_static)
	_static.start()


func _stop_static() -> void:
	if _static:
		_static.stop()
