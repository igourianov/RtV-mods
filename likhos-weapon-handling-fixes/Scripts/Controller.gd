extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")
var gameData = preload("res://Resources/GameData.tres")

var _lib
var _weapon_rig


func _init(lib, weapon_rig) -> void:
	_lib = lib
	_weapon_rig = weapon_rig


func on_movement_states_pre(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	if ModConfig.override_movement_speeds:
		ctrl.crouchSpeed = ModConfig.crouch_speed
		ctrl.walkSpeed = ModConfig.walk_speed
		ctrl.sprintSpeed = ModConfig.sprint_speed



func on_movement_states_post(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	if gameData.isWalking && gameData.isAiming && gameData.isScoped && ModConfig.current_scope_mag >= 2.0:
		ctrl.currentSpeed = ctrl.walkSpeed * ModConfig.walk_scope_mult
	elif gameData.isWalking && gameData.isAiming:
		ctrl.currentSpeed = ctrl.walkSpeed * ModConfig.walk_aim_mult
	elif gameData.isWalking && gameData.isCanted:
		ctrl.currentSpeed = ctrl.walkSpeed * ModConfig.walk_cant_mult


func on_input(evt) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return
	
	if evt is InputEventMouseMotion:
		_lib.skip_super()
		_mouse_input(ctrl, evt)
		return


func _mouse_input(ctrl, evt) -> void:
	if gameData.freeze || gameData.isCaching:
		return

	var sensitivity: float
	if gameData.isCanted:
		sensitivity = gameData.aimSensitivity
	elif !gameData.isAiming:
		sensitivity = gameData.lookSensitivity
	elif ModConfig.current_scope_mag < 2.0:
		sensitivity = gameData.aimSensitivity
	elif ModConfig.current_scope_mag > 4.0:
		sensitivity = gameData.scopeSensitivity * 0.5
	else:
		sensitivity = gameData.scopeSensitivity

	var factor = deg_to_rad(clampf(sensitivity, 0.1, 2.0) / 10.0)
	var y_sign = 1.0 if gameData.mouseMode == 2 else -1.0

	ctrl.rotate_y(-evt.relative.x * factor)
	ctrl.head.rotate_x(y_sign * evt.relative.y * factor)
	ctrl.head.rotation.x = clamp(ctrl.head.rotation.x, -PI / 2, PI / 2)
