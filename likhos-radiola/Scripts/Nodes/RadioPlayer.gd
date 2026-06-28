extends Node3D

const AudioChunkPlayer3D = preload("../../Lib/AudioChunkPlayer3D.gd")
const StaticNoisePlayer3D = preload("StaticNoisePlayer3D.gd")
const ModConfig = preload("../ModConfig.gd")
const RadioBus = preload("../RadioBus.gd")
const RadioStation = preload("../RadioStation.gd")

const MUSIC_VOLUME := 0.0
const UNIT_SIZE := 3.0
const MAX_DISTANCE := 20.0
const STATIC_VOLUME := -10.0

var playing := false
var station: RadioStation

var _music: AudioChunkPlayer3D
var _static: StaticNoisePlayer3D


func _init() -> void:
	_music = AudioChunkPlayer3D.new(null, MUSIC_VOLUME, RadioBus.BUS)
	_music.unit_size = UNIT_SIZE
	_music.max_distance = MAX_DISTANCE
	add_child(_music)

	_static = StaticNoisePlayer3D.new(RadioBus.BUS, STATIC_VOLUME, UNIT_SIZE * 1.5, MAX_DISTANCE)
	add_child(_static)


func start(to_station: RadioStation = null) -> void:
	if to_station:
		station = to_station
		station.load()
	playing = true
	_play_current()


func stop() -> void:
	playing = false
	station = null
	_music.stop()
	_static.stop()


func _process(_delta: float) -> void:
	if !playing:
		return
	if !_music.is_playing():
		_play_current()
	_sync_static()


func _play_current() -> void:
	var track := station.now_playing()
	if !track:
		return
	_music.stream = track.stream
	_music.play_chunk(track.start, track.duration)


func _sync_static() -> void:
	if ModConfig.static_enabled && !_static.playing:
		_static.start()
	elif !ModConfig.static_enabled && _static.playing:
		_static.stop()
