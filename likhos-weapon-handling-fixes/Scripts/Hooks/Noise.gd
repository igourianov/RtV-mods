extends RefCounted

const ModConfig = preload("../ModConfig.gd")

const WOBBLE_MULT: float = 3.0
const WOBBLE_MULT_HOLD_BREATH: float = 0.5
const WOBBLE_FREQ_MULT_EXHAUSTED: float = 2.0

var _lib

var _wobble_frequency: float = 0.0
var _wobble_amplitude: float = 0.0
var _wobble_offset: Vector3 = Vector3.ZERO


func _init(lib) -> void:
	_lib = lib


func on_physics_process_post(delta: float) -> void:
	var noise = _lib._caller
	if !noise:
		return

	var gd = noise.gameData

	if gd.isAiming && gd.isScoped && gd.PIP:
		noise.position *= _calculate_speed_factor(gd)

	_apply_wobble(noise, gd, delta)


func _apply_wobble(noise, gd, delta: float) -> void:
	var frequency_mult: float = 1.0
	var amplitude_mult: float = 1.0

	if gd.isAiming && !gd.isFiring:
		amplitude_mult = lerp(WOBBLE_MULT, WOBBLE_MULT_HOLD_BREATH, ModConfig.hold_breath_state)

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


func _calculate_speed_factor(gd) -> float:
	if gd.isRunning:
		return 1.0
	if gd.isCrouching:
		return 0.5
	if gd.isWalking:
		return 0.8
	return 0.0
