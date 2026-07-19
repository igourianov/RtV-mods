extends RefCounted

const _WINDOW_MS := 175
const _ACCEL_MAX := 3

var _last_msec := 0
var _last_dir := 0
var _accel := 1


func step(dir: int, current: int, count: int) -> int:
	var now := Time.get_ticks_msec()
	if dir == _last_dir && now - _last_msec <= _WINDOW_MS:
		_accel = min(_accel + 1, _ACCEL_MAX)
	else:
		_accel = 1
	_last_dir = dir
	_last_msec = now
	return clampi(current + dir * _accel, 0, count - 1)
