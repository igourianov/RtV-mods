extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

var gameData = preload("res://Resources/GameData.tres")
var _lib


func _init(lib) -> void:
	_lib = lib


func on_movement_states(delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return
	_lib.skip_super()

	_update_state(ctrl)
	_apply_speed(ctrl, delta)


func _update_state(ctrl) -> void:
	gameData.isIdle = !gameData.isMoving
	gameData.isMoving = ctrl.inputDirection != Vector2.ZERO

	if !gameData.isMoving:
		gameData.isWalking = false
		gameData.isRunning = false
		return

	if gameData.bodyStamina <= 0.0 || gameData.overweight || gameData.fracture:
		gameData.isRunning = false
	elif gameData.sprintMode == 1:
		gameData.isRunning = Input.is_action_pressed("sprint")
	elif Input.is_action_just_pressed("sprint"):
		gameData.isRunning = !gameData.isRunning

	gameData.isWalking = !gameData.isRunning
	if gameData.isRunning:
		gameData.isCrouching = false


func _apply_speed(ctrl, delta: float) -> void:
	var target: float
	var rate: float
	var crouchSpeed: float = ctrl.crouchSpeed if !ModConfig.override_movement_speeds else ModConfig.crouch_speed
	var walkSpeed: float = ctrl.walkSpeed if !ModConfig.override_movement_speeds else ModConfig.walk_speed
	var sprintSpeed: float = ctrl.sprintSpeed if !ModConfig.override_movement_speeds else ModConfig.sprint_speed

	if !gameData.isMoving:
		target = 0.0
		rate = 5.0
	elif gameData.isCrouching:
		target = crouchSpeed
		rate = 2.5
	elif gameData.isRunning:
		target = sprintSpeed
		rate = 1.0
	elif gameData.isAiming && gameData.isScoped && ModConfig.current_scope_mag >= 2.0:
		target = walkSpeed * ModConfig.walk_scope_mult
		rate = 2.5
	elif gameData.isAiming:
		target = walkSpeed * ModConfig.walk_aim_mult
		rate = 2.5
	elif gameData.isCanted:
		target = walkSpeed * ModConfig.walk_cant_mult
		rate = 2.5
	else:
		target = ctrl.walkSpeed
		rate = 2.5

	ctrl.currentSpeed = lerp(ctrl.currentSpeed, target, delta * rate)


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
