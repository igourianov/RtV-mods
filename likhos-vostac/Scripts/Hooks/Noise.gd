extends RefCounted


# bob settings per mode: horizontal and vertical size relative to vanilla's intensity, then sharpness
# sharpness 0 is a sine sway with a smooth dip, 1 a triangle sway that reverses sharply at the edges with a sharp dip
const BOB_WALK := Vector3(0.7, 0.9, 0.0)
const BOB_CANTED := Vector3(0.0, 0.6, 0.0)
# negative sprint sway puts the weapon opposite the head bob's sideways shift, so it lags the body like a held weapon
const BOB_SPRINT := Vector3(-2.5, 0.5, 0.7)
# each step's dip depth varies by up to this fraction either way
const BOB_DIP_RANDOM: float = 0.4
# a step plays where sin of the controller's phase rises through 0.5, which is a twelfth of a turn into the half rate stride
const BOB_STEP_PHASE: float = PI / 12
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

# horizontal size and vertical size in meters, then sharpness
var _bob: Vector3 = Vector3.ZERO
var _dip_step: int = 0
var _dip_depth: float = 1.0
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
	# vanilla eases the position toward its curve, which lags the bob behind the steps
	# here the curve runs straight off the controller's phase, so it stays on the footsteps, and only its settings are eased between modes
	var target := Vector3.ZERO
	if gd.isMoving && gd.isGrounded && !gd.freeze:
		var mode: Vector3 = BOB_WALK
		if gd.isRunning:
			mode = BOB_SPRINT
		elif gd.isCanted:
			mode = BOB_CANTED
		var size: float = noise.headbobIntensity
		if gd.isAiming && gd.isScoped && gd.PIP:
			size *= _calculate_speed_factor(gd)
		target = Vector3(mode.x * size, mode.y * size, mode.z)
	_bob = _bob.lerp(target, delta * noise.bobLerpSpeed)

	# one stride covers two steps, so the sway edges alternate sides and the dips land on every step
	var stride: float = _controller.bob_phase / 2 - BOB_STEP_PHASE
	var sway: float = cos(stride)
	sway = lerp(sway, asin(sway) * 2 / PI, _bob.z)
	# a new depth is drawn midway between steps, where the dip is zero and the change can't jump the weapon
	var step: int = floori(stride / PI + 0.5)
	if step != _dip_step:
		_dip_step = step
		_dip_depth = randf_range(1.0 - BOB_DIP_RANDOM, 1.0 + BOB_DIP_RANDOM)
	var lift: float = absf(sin(stride))
	var dip: float = 1.0 - 2.0 * (1.0 - lerp(lift * lift, lift, _bob.z)) * _dip_depth
	# poses like the sprint one turn the parent frame so far that its x points mostly into the screen, so the curve is built in camera space and brought into that frame
	var to_parent: Basis = noise.get_parent().global_basis.inverse() * noise.get_viewport().get_camera_3d().global_basis
	noise.position = to_parent * Vector3(sway * _bob.x, dip * _bob.y, 0.0)


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


# these used to multiply the eased position every tick, which compounded to about these fractions of the regular bob
func _calculate_speed_factor(gd: GameData) -> float:
	if gd.isRunning:
		return 1.0
	if gd.isCrouching:
		return 0.15
	if gd.isWalking:
		return 0.4
	return 0.0
