extends RefCounted


const BOB_MULT_SPRINT: float = 2.0
const WOBBLE_MULT: float = 3.0
const WOBBLE_MULT_HOLD_BREATH: float = 0.5
const WOBBLE_FREQ_MULT_EXHAUSTED: float = 2.0
# the weight factor is the line through (light, light mult) and (base, 1.0), floored at light mult and open above
const WOBBLE_WEIGHT_BASE: float = 5.0
const WOBBLE_WEIGHT_LIGHT: float = 3.0
const WOBBLE_WEIGHT_LIGHT_MULT: float = 0.3

var config := preload("../Config.gd").instance
var _lib
var _controller

var _bob: Vector2 = Vector2.ZERO
var _wobble_frequency: float = 0.0
var _wobble_amplitude: float = 0.0
var _wobble_offset: Vector3 = Vector3.ZERO


func _init(lib, controller) -> void:
	_lib = lib
	_controller = controller


func on_physics_process_post(delta: float) -> void:
	var noise = _lib._caller
	if !noise:
		return

	var gd = noise.gameData

	_apply_bob(noise, gd, delta)
	_apply_wobble(noise, gd, delta)


func _apply_bob(noise: Node, gd: GameData, delta: float) -> void:
	# vanilla advances a phase of its own at a fixed rate per state, the controller's phase keeps the weapon in step with the footsteps
	var target := Vector2.ZERO
	if gd.isMoving && gd.isGrounded && !gd.freeze:
		# sprinting runs the weapon at half the footstep rate, so it bobs on every second step
		var phase: float = _controller.bob_phase * (0.5 if gd.isRunning else 1.0)
		# a step plays a third of a cycle after the dip of sin(phase), vanilla's canted offset puts the dip just before it, so both modes use it
		var vertical: float = sin(phase - 1.5)
		var curve: Vector2 = Vector2(sin(phase + 1.5), vertical) if gd.isCanted else Vector2(sin(phase / 2), vertical * 2)
		target = curve * noise.headbobIntensity * (BOB_MULT_SPRINT if gd.isRunning else 1.0)

	# vanilla has already overwritten the previous position by now, so the hook eases its own copy
	_bob = _bob.lerp(target, delta * noise.bobLerpSpeed)
	if gd.isAiming && gd.isScoped && gd.PIP:
		_bob *= _calculate_speed_factor(gd)
	noise.position.x = _bob.x
	noise.position.y = _bob.y


func _apply_wobble(noise: Node, gd: GameData, delta: float) -> void:
	var frequency_mult: float = 1.0
	var amplitude_mult: float = 1.0

	if gd.isAiming && !gd.isFiring:
		amplitude_mult = lerp(WOBBLE_MULT, WOBBLE_MULT_HOLD_BREATH, config.hold_breath_state)

	# a weight of 0 means no weapon is resolved, the floor would give it the light mult
	if (gd.isAiming || gd.isCanted) && !gd.isFiring && config.current_weapon_weight > 0.0:
		amplitude_mult *= maxf(WOBBLE_WEIGHT_LIGHT_MULT, remap(config.current_weapon_weight, WOBBLE_WEIGHT_LIGHT, WOBBLE_WEIGHT_BASE, WOBBLE_WEIGHT_LIGHT_MULT, 1.0))

	if gd.armStamina <= 0.0:
		frequency_mult = WOBBLE_FREQ_MULT_EXHAUSTED
		amplitude_mult *= WOBBLE_FREQ_MULT_EXHAUSTED

	_wobble_frequency = lerp(_wobble_frequency, noise.targetFrequency * frequency_mult, delta * noise.targetLerpSpeed)
	_wobble_amplitude = lerp(_wobble_amplitude, noise.targetAmplitude * amplitude_mult, delta * noise.targetLerpSpeed)

	var scroll: float = delta * _wobble_frequency
	_wobble_offset += Vector3(scroll, scroll, scroll)

	noise.rotation = Vector3(
		noise.noise.get_noise_2d(_wobble_offset.x, 0.0),
		noise.noise.get_noise_2d(_wobble_offset.y, 1.0),
		noise.noise.get_noise_2d(_wobble_offset.z, 2.0)
	) * _wobble_amplitude


func _calculate_speed_factor(gd: GameData) -> float:
	if gd.isRunning:
		return 1.0
	if gd.isCrouching:
		return 0.5
	if gd.isWalking:
		return 0.8
	return 0.0
