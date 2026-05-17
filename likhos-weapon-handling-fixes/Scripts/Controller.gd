extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

var gameData = preload("res://Resources/GameData.tres")
var _lib
var _sprint_intent: bool = false


func _init(lib) -> void:
	_lib = lib


func on_movement_states(delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return
	_lib.skip_super()

	_update_state(ctrl)
	_apply_speed(ctrl, delta)

	ctrl.standCollider.disabled = gameData.isCrouching
	ctrl.crouchCollider.disabled = !gameData.isCrouching


func _update_state(ctrl) -> void:
	
	gameData.isMoving = ctrl.inputDirection != Vector2.ZERO
	gameData.isIdle = !gameData.isMoving

	if gameData.isSwimming:
		gameData.isCrouching = false
		gameData.isRunning = false
	elif !gameData.isCrouching && ctrl.above.is_colliding():
		gameData.isCrouching = true
		gameData.isRunning = false
		_set_impulse(ctrl)
	elif gameData.bodyStamina <= 0.0 || gameData.overweight || gameData.fracture:
		gameData.isRunning = false
	else:
		gameData.isRunning = _sprint_intent && gameData.isMoving

	gameData.isWalking = gameData.isMoving && !gameData.isRunning



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

	if gameData.freeze || gameData.isCaching:
		return

	if evt.is_action_pressed("crouch"):
		if !gameData.isCrouching:
			gameData.isCrouching = true
			_sprint_intent = false
			_set_impulse(ctrl)
		elif !ctrl.above.is_colliding():
			gameData.isCrouching = false
			_set_impulse(ctrl)
	elif evt.is_action_pressed("sprint"):
		if gameData.sprintMode == 1:
			_sprint_intent = true
		else:
			_sprint_intent = !_sprint_intent			
		if _sprint_intent && gameData.isCrouching && !ctrl.above.is_colliding():
			gameData.isCrouching = false
			_set_impulse(ctrl)
	elif evt.is_action_released("sprint") && gameData.sprintMode == 1:
		_sprint_intent = false



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


func on_crouch(delta: float) -> void:
	var ctrl = _lib._caller
	if !ctrl:
		return
	_lib.skip_super()

	ctrl.pelvis.position.y = lerp(ctrl.pelvis.position.y, (0.5 if gameData.isCrouching else 1.0), delta * 5.0)
	

func _set_impulse(ctrl) -> void:
	if gameData.isCrouching:
		ctrl.crouchImpulse = 0.1
	else:
		ctrl.standImpulse = 0.1

