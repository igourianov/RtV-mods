extends RefCounted

const ModConfig = preload("./ModConfig.gd")

const WOBBLE_MULT: float = 2.0
const WOBBLE_MULT_HOLD_BREATH: float = 0.3

var _lib
var _preferences: Preferences

var _wobble_frequency: float = 0.0
var _wobble_amplitude: float = 0.0
var _wobble_offset: Vector3 = Vector3.ZERO


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_physics_process_post(delta: float) -> void:
	var noise = _lib._caller
	if noise == null:
		return

	var gd = noise.gameData

	if gd.isAiming && gd.isScoped && gd.PIP:
		noise.position *= _calculate_speed_factor(gd)

	_apply_wobble(noise, gd, delta)


func _apply_wobble(noise, gd, delta: float) -> void:
	var mult: float = 1.0
	if gd.isAiming && !gd.isFiring:
		mult = lerp(WOBBLE_MULT, WOBBLE_MULT_HOLD_BREATH, ModConfig.hold_breath_progress)

	_wobble_frequency = lerp(_wobble_frequency, noise.targetFrequency * mult, delta * noise.targetLerpSpeed)
	_wobble_amplitude = lerp(_wobble_amplitude, noise.targetAmplitude * mult, delta * noise.targetLerpSpeed)

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
