extends RefCounted

const Out := preload("../../Lib/Out.gd")
const InputBus := preload("../Nodes/InputBus.gd")
# scales the step attenuation in dB, above 1 the steps quieten faster than speed drops
const STEP_VOLUME_EXPONENT: float = 1.2
# footsteps per second while moving, applies to head and weapon bob too
const STEP_RATE_MIN: float = 1.0
const STEP_RATE_MAX: float = 3.5

var config := preload("../Config.gd").instance
var gameData := preload("res://Resources/GameData.tres")
var _lib
var _bus: InputBus
var _current_sensitivity: float
var bob_phase: float = 0.0


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
	var useOverride: bool = config.override_movement_speeds
	var crouchSpeed: float = config.crouch_speed if useOverride else ctrl.crouchSpeed
	var walkSpeed: float = _walk_speed(ctrl)
	var sprintSpeed: float = config.sprint_speed if useOverride else ctrl.sprintSpeed

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
	elif gameData.isAiming && gameData.isScoped && config.current_scope_mag >= 2.0:
		target = walkSpeed * config.walk_scope_mult
	elif gameData.isAiming:
		target = walkSpeed * config.walk_aim_mult
	elif gameData.isCanted:
		target = walkSpeed * config.walk_cant_mult

	ctrl.currentSpeed = lerp(ctrl.currentSpeed, target, delta * rate)


func _walk_speed(ctrl: Node) -> float:
	return config.walk_speed if config.override_movement_speeds else ctrl.walkSpeed


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
	if config.binoculars_active:
		return gameData.lookSensitivity / max(config.binoculars_mag, 1.0)
	if gameData.isCanted:
		return gameData.aimSensitivity
	if gameData.isAiming && gameData.isScoped:
		return gameData.scopeSensitivity / config.current_scope_mag
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


func on_headbob(delta: float) -> void:
	var ctrl = _lib._caller
	# swimming keeps the vanilla bob and stroke sounds
	if !ctrl || gameData.isSwimming:
		return
	_lib.skip_super()

	# vanilla walk and sprint share one stride, crouch has a shorter one
	# isWalking stays set while crouch walking, so crouch is checked first
	var stride: float = ctrl.headbobWalkSpeed / ctrl.walkSpeed
	var intensity: float = ctrl.headbobWalkIntensity
	if gameData.isCrouching:
		stride = ctrl.headbobCrouchSpeed / ctrl.crouchSpeed
		intensity = ctrl.headbobCrouchIntensity
	elif gameData.isRunning:
		intensity = ctrl.headbobSprintIntensity

	# read after Movement has run, so inertia, the overweight slowdown and collisions are in it
	var speed: float = Vector2(ctrl.velocity.x, ctrl.velocity.z).length()
	var rate: float = stride * speed
	if ctrl.is_on_floor() && ctrl.inputDirection != Vector2.ZERO:
		rate = clampf(rate, STEP_RATE_MIN * TAU, STEP_RATE_MAX * TAU)
	var index: float = ctrl.headbobIndex + rate * delta
	ctrl.headbobIndex = index
	bob_phase = index

	var bob: Node3D = ctrl.bob
	var vector: Vector2 = ctrl.headbobVector
	var target := Vector2.ZERO
	if ctrl.is_on_floor() && ctrl.inputDirection != Vector2.ZERO:
		vector = Vector2(sin(index / 2), sin(index))
		ctrl.headbobVector = vector
		target = Vector2(vector.x, vector.y * 2) * intensity * gameData.headbob
	bob.position.x = lerp(bob.position.x, target.x, delta * ctrl.lerpSpeed)
	bob.position.y = lerp(bob.position.y, target.y, delta * ctrl.lerpSpeed)

	if vector.y < -0.5:
		ctrl.canStep = true
	elif vector.y > 0.5 && ctrl.canStep:
		ctrl.canStep = false
		# vanilla adds the footstep player first, then the optional gear and razor players after it
		var footstep: int = ctrl.get_child_count()
		ctrl.PlayFootstep()
		if config.scale_footstep_volume:
			ctrl.get_child(footstep).volume_db += linear_to_db(pow(minf(speed / _walk_speed(ctrl), 1.0), STEP_VOLUME_EXPONENT))
