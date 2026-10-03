extends RefCounted

const ModConfig := preload("../ModConfig.gd")
const Out := preload("../../Lib/Out.gd")
const InputBus := preload("../Nodes/InputBus.gd")

var gameData := preload("res://Resources/GameData.tres")
var _lib
var _bus: InputBus
var _current_sensitivity: float


func _init(lib, bus: InputBus) -> void:
	_lib = lib
	_bus = bus
	_current_sensitivity = gameData.lookSensitivity


func on_movement_states(delta: float) -> void:
	var ctrl = _lib._caller
	if !ctrl:
		return
	_lib.skip_super()

	_update_state(ctrl)
	_apply_speed(ctrl, delta)

	ctrl.standCollider.disabled = gameData.isCrouching
	ctrl.crouchCollider.disabled = !gameData.isCrouching


func _update_state(ctrl: Node) -> void:
	gameData.isMoving = ctrl.inputDirection != Vector2.ZERO
	gameData.isIdle = !gameData.isMoving

	# a ceiling forces the crouch and blocks standing up, whatever the intent says
	var crouching: bool = _bus.crouch() || ctrl.above.is_colliding()
	var fit: bool = gameData.bodyStamina > 0.0 && !gameData.overweight && !gameData.fracture && !gameData.isRazor

	if crouching && !gameData.isCrouching:
		ctrl.crouchImpulse = 0.1
	elif !crouching && gameData.isCrouching:
		ctrl.standImpulse = 0.1

	gameData.isCrouching = crouching
	gameData.isRunning = _bus.sprint() && gameData.isMoving && !crouching && fit

	gameData.isWalking = gameData.isMoving && !gameData.isRunning


func _apply_speed(ctrl: Node, delta: float) -> void:
	var useOverride: bool = ModConfig.override_movement_speeds
	var crouchSpeed: float = ModConfig.crouch_speed if useOverride else ctrl.crouchSpeed
	var walkSpeed: float = ModConfig.walk_speed if useOverride else ctrl.walkSpeed
	var sprintSpeed: float = ModConfig.sprint_speed if useOverride else ctrl.sprintSpeed

	var target: float = walkSpeed
	var rate: float = 2.5

	if !gameData.isMoving:
		target = 0.0
		rate = 5.0
	elif gameData.isCrouching:
		target = crouchSpeed
	elif gameData.isRunning:
		target = sprintSpeed
		rate = 1.0
	elif gameData.isAiming && gameData.isScoped && ModConfig.current_scope_mag >= 2.0:
		target = walkSpeed * ModConfig.walk_scope_mult
	elif gameData.isAiming:
		target = walkSpeed * ModConfig.walk_aim_mult
	elif gameData.isCanted:
		target = walkSpeed * ModConfig.walk_cant_mult

	ctrl.currentSpeed = lerp(ctrl.currentSpeed, target, delta * rate)


func on_input(evt: InputEvent) -> void:
	var ctrl = _lib._caller
	if !ctrl:
		return

	if evt is InputEventMouseMotion:
		_lib.skip_super()
		_mouse_input(ctrl, evt)


func _mouse_input(ctrl: Node, evt: InputEvent) -> void:
	if gameData.freeze || gameData.isCaching:
		return

	var factor := deg_to_rad(clampf(_current_sensitivity, 0.1, 2.0) / 10.0)
	var y_sign := 1.0 if gameData.mouseMode == 2 else -1.0

	ctrl.rotate_y(-evt.relative.x * factor)
	ctrl.head.rotate_x(y_sign * evt.relative.y * factor)
	ctrl.head.rotation.x = clamp(ctrl.head.rotation.x, -deg_to_rad(75.0), PI / 2)


func _target_sensitivity() -> float:
	if ModConfig.binoculars_active:
		return gameData.lookSensitivity / max(ModConfig.binoculars_mag, 1.0)
	if gameData.isCanted:
		return gameData.aimSensitivity
	if gameData.isAiming && gameData.isScoped:
		return gameData.scopeSensitivity / ModConfig.current_scope_mag
	if gameData.isAiming:
		return gameData.aimSensitivity
	return gameData.lookSensitivity


func on_physics_process_post(delta: float) -> void:
	_current_sensitivity = lerp(_current_sensitivity, _target_sensitivity(), delta * 5.0)


func on_crouch(delta: float) -> void:
	var ctrl = _lib._caller
	if !ctrl:
		return
	_lib.skip_super()

	ctrl.pelvis.position.y = lerp(ctrl.pelvis.position.y, (0.5 if gameData.isCrouching else 1.0), delta * 5.0)
