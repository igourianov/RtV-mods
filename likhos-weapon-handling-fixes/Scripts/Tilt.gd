extends RefCounted

var _lib


func _init(lib) -> void:
	_lib = lib


func on_physics_process_pre(_delta: float) -> void:
	var tilt = _lib._caller
	if tilt == null:
		return

	tilt.hipPushForward = 0.005
