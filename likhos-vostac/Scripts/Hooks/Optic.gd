extends RefCounted

const _PIP_SHADER := preload("res://mods/likhos-vostac/Shaders/PIP.gdshader")
var config := preload("../Config.gd").instance

# Vanilla scene defaults for the optic's SubViewport, applied when AA mirror is off.
const _VANILLA_PIP_MSAA := 0
const _VANILLA_PIP_SSAA := 1


var _lib
var _preferences: Preferences


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_physics_process_pre(_delta: float) -> void:
	var optic = _lib._caller
	if !optic:
		return

	var viewport: SubViewport = optic.viewport
	if viewport:
		viewport.msaa_3d = _msaa_from_pref(_preferences.antialiasing) if config.PIP_anti_aliasing else _VANILLA_PIP_MSAA
		viewport.screen_space_aa = _ssaa_from_pref(_preferences.smaa) if config.PIP_anti_aliasing else _VANILLA_PIP_SSAA

	var pip_mat: ShaderMaterial = optic.PIP
	if pip_mat && pip_mat.shader:
		if !("shader_parameter/exposure" in pip_mat):
			pip_mat.shader = _PIP_SHADER
		# The PIP camera renders with the shared world environment, so its picture already carries the exposure NVG raises.
		# The main pass applies that exposure again when it tonemaps the lens, and the shader takes the second one back out.
		var world: World3D = optic.get_world_3d()
		var env: Environment = world.environment if world else null
		pip_mat.set_shader_parameter("exposure", env.tonemap_exposure if env else 1.0)


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
