extends Node

# Numpad binds that nudge the held rig's pose while the free camera has the world frozen.
# Values use the Handling target convention (targetPosition: +X is left, +Z is forward; targetRotation in degrees), so they paste straight into pose tables.
# KP7/KP4, KP8/KP5, KP9/KP6: X, Y, Z plus/minus. KP 1: switch position/rotation. KP 2: switch fine/coarse step. KP 3: back to the frozen pose.
# No numpad key is bound to a vanilla action. KP Enter is avoided, Profiler.gd reads it directly.

const Out := preload("../Lib/Out.gd")

const _MANAGER_PATH := "/root/Map/Core/Camera/Manager"
const _AXIS_KEYS: Dictionary[Key, Vector3] = {
	KEY_KP_7: Vector3.RIGHT,
	KEY_KP_4: Vector3.LEFT,
	KEY_KP_8: Vector3.UP,
	KEY_KP_5: Vector3.DOWN,
	KEY_KP_9: Vector3.BACK,
	KEY_KP_6: Vector3.FORWARD,
}
const _POS_STEP: float = 0.005
const _ROT_STEP: float = 1.0
const _COARSE_MULT: float = 5.0

var _handling: Node3D
var _frozen_pos: Vector3
var _frozen_rot: Vector3
var _pos: Vector3
var _rot: Vector3
var _rotation_mode := false
var _coarse := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var manager := get_node_or_null(_MANAGER_PATH)
	var rig: Node = manager.get_child(manager.get_child_count() - 1) if manager && manager.get_child_count() else null
	_handling = rig.get_node_or_null("Handling") as Node3D if rig else null
	if !_handling:
		return

	# the target, not the current transform, since the rig may have frozen mid-blend
	_frozen_pos = _handling.targetPosition
	_frozen_rot = _handling.targetRotation
	_pos = _frozen_pos
	_rot = _frozen_rot


func _input(evt: InputEvent) -> void:
	var key := evt as InputEventKey
	if !_handling || !key || !key.pressed:
		return

	var code := key.physical_keycode
	var step: float = _COARSE_MULT if _coarse else 1.0
	var axis := _AXIS_KEYS.has(code)
	# held axis keys repeat, the toggles do not
	if key.echo && !axis:
		return

	if axis:
		if _rotation_mode:
			_rot += _AXIS_KEYS[code] * _ROT_STEP * step
		else:
			_pos += _AXIS_KEYS[code] * _POS_STEP * step
	elif code == KEY_KP_1:
		_rotation_mode = !_rotation_mode
	elif code == KEY_KP_2:
		_coarse = !_coarse
	elif code == KEY_KP_3:
		_pos = _frozen_pos
		_rot = _frozen_rot
	else:
		return

	get_viewport().set_input_as_handled()

	# the same mapping vanilla and VosTac Handling apply from the target each tick
	_handling.position = Vector3(-_pos.x, _pos.y, -_pos.z)
	_handling.rotation_degrees = _rot

	var dpos := _pos - _frozen_pos
	var drot := _rot - _frozen_rot
	print(Out.prefix, " rig tune target pos Vector3(%.3f, %.3f, %.3f) rot Vector3(%.1f, %.1f, %.1f) | delta pos Vector3(%.3f, %.3f, %.3f) rot Vector3(%.1f, %.1f, %.1f) | %s %s" % [
		_pos.x, _pos.y, _pos.z, _rot.x, _rot.y, _rot.z,
		dpos.x, dpos.y, dpos.z, drot.x, drot.y, drot.z,
		"rot" if _rotation_mode else "pos", "coarse" if _coarse else "fine",
	])
