extends RefCounted

# Tunable: blur radius in viewport texels for the NVG scope blur. 0 disables.
# Larger = blurrier. If raised substantially, also raise STEPS in PIP_NVG.gdshader.
const BLUR_RADIUS := 12.0

const _NVG_PIP_SHADER := preload("res://mods/likhos-vostac/Shaders/PIP_NVG.gdshader")
const ModConfig := preload("../ModConfig.gd")
const Out := preload("../../Lib/Out.gd")
var gameData := preload("res://Resources/GameData.tres")

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
		viewport.msaa_3d = _msaa_from_pref(_preferences.antialiasing) if ModConfig.pip_anti_aliasing else _VANILLA_PIP_MSAA
		viewport.screen_space_aa = _ssaa_from_pref(_preferences.smaa) if ModConfig.pip_anti_aliasing else _VANILLA_PIP_SSAA

	var pip_mat: ShaderMaterial = optic.PIP
	if pip_mat && pip_mat.shader:
		if !("shader_parameter/blur_radius" in pip_mat):
			pip_mat.shader = _NVG_PIP_SHADER
		var blur_on: bool = gameData.isScoped && gameData.PIP && gameData.NVG && ModConfig.nvg_pip_blur
		var radius: float = BLUR_RADIUS if blur_on else 0.0
		pip_mat.set_shader_parameter("blur_radius", radius)


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
