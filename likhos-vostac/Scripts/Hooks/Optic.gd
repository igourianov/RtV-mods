extends RefCounted

# Tunable: blur radius in viewport texels for the NVG scope blur. 0 disables.
# Larger = blurrier. If raised substantially, also raise STEPS in PIP_NVG.gdshader.
const BLUR_RADIUS := 12.0

const _NVG_PIP_SHADER := preload("res://mods/likhos-vostac/Shaders/PIP_NVG.gdshader")
const ScopeCatalog := preload("../ScopeCatalog.gd")
var config := preload("../Config.gd").instance
var gameData := preload("res://Resources/GameData.tres")

# Vanilla scene defaults for the optic's SubViewport, applied when AA mirror is off.
const _VANILLA_PIP_MSAA := 0
const _VANILLA_PIP_SSAA := 1

# Eye pupil diameter in mm: contracted in daylight, fully dilated at night.
const _EYE_PUPIL_DAY := 2.5
const _EYE_PUPIL_NIGHT := 7.0

# Simulation.time values at which vanilla World.TOD swaps the sun for the moon.
const _SUNRISE := 600.0
const _SUNSET := 1800.0
# Half-width of the dusk and dawn ramps in Simulation.time units, 100 being one hour.
const _TWILIGHT := 100.0


var _lib
var _preferences: Preferences


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_physics_process_pre(delta: float) -> void:
	var optic = _lib._caller
	if !optic:
		return

	var viewport: SubViewport = optic.viewport
	if viewport:
		viewport.msaa_3d = _msaa_from_pref(_preferences.antialiasing) if config.PIP_anti_aliasing else _VANILLA_PIP_MSAA
		viewport.screen_space_aa = _ssaa_from_pref(_preferences.smaa) if config.PIP_anti_aliasing else _VANILLA_PIP_SSAA

	var pip_mat: ShaderMaterial = optic.PIP
	if pip_mat && pip_mat.shader:
		if !("shader_parameter/blur_radius" in pip_mat):
			pip_mat.shader = _NVG_PIP_SHADER
			pip_mat.set_shader_parameter("transmission", 1.0)
		var scoped: bool = gameData.isScoped && gameData.PIP
		var blur_on: bool = scoped && gameData.NVG && config.NVG_PIP_blur
		var radius: float = BLUR_RADIUS if blur_on else 0.0
		pip_mat.set_shader_parameter("blur_radius", radius)
		# The rig's unmounted optics run this hook too, and current_scope_mag belongs to the mounted one.
		if scoped && optic.visible:
			var current: float = pip_mat.get_shader_parameter("transmission")
			pip_mat.set_shader_parameter("transmission", lerpf(current, _low_light_transmission(optic), delta * 10.0))


# Share of the scene's brightness that reaches the eye: the area of the exit pupil over the area of the eye pupil.
# An exit pupil wider than the eye pupil adds nothing, so every scope is at full brightness in daylight.
func _low_light_transmission(optic: Node3D) -> float:
	# 1 in full daylight, 0 at night, ramping through dusk and dawn. Shelters are lit from the inside and never run the day cycle.
	var time: float = Simulation.time
	var daylight: float = 1.0 if gameData.shelter else smoothstep(_SUNRISE - _TWILIGHT, _SUNRISE + _TWILIGHT, time) - smoothstep(_SUNSET - _TWILIGHT, _SUNSET + _TWILIGHT, time)
	var eye_pupil: float = lerpf(_EYE_PUPIL_NIGHT, _EYE_PUPIL_DAY, daylight)
	var exit_pupil: float = ScopeCatalog.get_objective(optic.attachmentData) / config.current_scope_mag
	var transmission: float = minf(1.0, (exit_pupil / eye_pupil) ** 2)
	return lerpf(1.0, transmission, config.scope_low_light_dimming)


# preferences.antialiasing 1..4 -> Viewport.MSAA enum (0..3)
func _msaa_from_pref(level: int) -> int:
	match level:
		2: return 1
		3: return 2
		4: return 3
		_: return 0


# preferences.smaa 1..2 -> Viewport.SCREEN_SPACE_AA enum (0 disabled, 2 SMAA)
func _ssaa_from_pref(level: int) -> int:
	match level:
		2: return 2
		_: return 0
