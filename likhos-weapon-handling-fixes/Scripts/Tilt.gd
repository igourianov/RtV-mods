extends RefCounted

var _lib
var _config

func _init(lib, config) -> void:
	_lib = lib
	_config = config

func on_physics_process_pre(_delta: float) -> void:
	var tilt = _lib._caller
	if tilt == null:
		return

	tilt.hipPushForward = 0.005
