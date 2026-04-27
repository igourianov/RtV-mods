extends RefCounted

var _lib
var _preferences: Preferences

const _AIM_SPEED_MULT = 0.6
const _CANT_SPEED_MULT = 0.75 


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences

func on_movement_states_pre(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	ctrl.crouchSpeed = 0.7
	ctrl.walkSpeed = 3.0
	ctrl.sprintSpeed = 7.0



func on_movement_states_post(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	var gd = ctrl.gameData

	if gd.isWalking && gd.isAiming && gd.isScoped:
		ctrl.currentSpeed = ctrl.crouchSpeed
	elif gd.isWalking && gd.isAiming:
		ctrl.currentSpeed = ctrl.walkSpeed * _AIM_SPEED_MULT
	elif gd.isWalking && gd.isCanted:
		ctrl.currentSpeed = ctrl.walkSpeed * _CANT_SPEED_MULT

