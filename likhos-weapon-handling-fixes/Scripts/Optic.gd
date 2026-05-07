extends RefCounted

# Tunable: blur radius in viewport texels at 1x magnification.
# Scales linearly with optic magnification (BLUR_RADIUS_BASE * current_scope_mag).
# 0 disables.
const BLUR_RADIUS_BASE := 3.0

const _NVG_PIP_SHADER := preload("res://mods/likhos-weapon-handling-fixes/Shaders/PIP_NVG.gdshader")
const ModConfig = preload("./ModConfig.gd")
var gameData = preload("res://Resources/GameData.tres")

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
	if optic == null:
		return

	var viewport: SubViewport = optic.viewport
	if viewport == null:
		return

	var msaa: int
	var ssaa: int
	if ModConfig.pip_anti_aliasing:
		msaa = _msaa_from_pref(_preferences.antialiasing)
		ssaa = _ssaa_from_pref(_preferences.smaa)
	else:
		msaa = _VANILLA_PIP_MSAA
		ssaa = _VANILLA_PIP_SSAA

	if viewport.msaa_3d != msaa:
		viewport.msaa_3d = msaa
	if viewport.screen_space_aa != ssaa:
		viewport.screen_space_aa = ssaa

	var pip_mat: ShaderMaterial = optic.PIP
	if pip_mat == null:
		return

	if pip_mat.shader != _NVG_PIP_SHADER:
		pip_mat.shader = _NVG_PIP_SHADER

	var blur_active: bool = (
		ModConfig.nvg_pip_blur
		&& gameData.NVG
		&& gameData.isAiming
		&& !gameData.secondaryOptic
	)
	var radius: float = 0.0
	if blur_active:
		var mag: float = max(1.0, ModConfig.current_scope_mag)
		radius = BLUR_RADIUS_BASE * mag
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
