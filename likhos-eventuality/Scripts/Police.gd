extends RefCounted

var _lib


func _init(lib) -> void:
	_lib = lib


func on_ready_post() -> void:
	var p = _lib._caller
	if p == null:
		return
	if p.currentState != p.State.Boss:
		p.currentState = p.State.Boss


func on_states_post(_delta: float) -> void:
	var p = _lib._caller
	if p == null:
		return
	if p.speed > 15.0:
		p.speed = 15.0
