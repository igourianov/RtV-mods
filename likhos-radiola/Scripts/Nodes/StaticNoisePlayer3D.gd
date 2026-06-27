extends AudioStreamPlayer3D

const MIX_RATE := 22050.0
const BUFFER := 0.2
const FLOOR := 0.04
const BASE_LEVEL := 0.18
# per-sample rates at MIX_RATE; tiny because the loop runs once per audio frame, not per process tick
const DRIFT_CHANCE := 0.00009
const CRACKLE_CHANCE := 0.00001
const CRACKLE_MIN := 0.3
const CRACKLE_MAX := 0.4
const SMOOTH := 0.0006

var _pb: AudioStreamGeneratorPlayback
var _level := BASE_LEVEL
var _target := BASE_LEVEL


func _init(to_bus := &"SFX", volume := 0.0, unit := 1.0, max_dist := 0.0) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = BUFFER
	stream = gen
	bus = to_bus
	volume_db = volume
	unit_size = unit
	max_distance = max_dist


func start() -> void:
	_level = BASE_LEVEL
	_target = BASE_LEVEL
	play()
	_pb = get_stream_playback() as AudioStreamGeneratorPlayback


func stop() -> void:
	super.stop()
	_pb = null


func _process(_delta: float) -> void:
	if !_pb:
		return
	var frames := _pb.get_frames_available()
	for i in frames:
		if randf() < DRIFT_CHANCE:
			_target = randf_range(FLOOR, BASE_LEVEL)
		_level = lerpf(_level, _target, SMOOTH)
		if randf() < CRACKLE_CHANCE:
			_level = randf_range(CRACKLE_MIN, CRACKLE_MAX)
		var s := (randf() * 2.0 - 1.0) * _level
		_pb.push_frame(Vector2(s, s))
