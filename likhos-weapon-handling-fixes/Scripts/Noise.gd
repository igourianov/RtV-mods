extends RefCounted

var _lib
var _preferences: Preferences


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_physics_process_post(_delta: float) -> void:
	var noise = _lib._caller
	if noise == null:
		return
	
	var gd = noise.gameData

	if gd.isAiming && gd.isScoped && gd.PIP:
		noise.position *= _calculate_speed_factor(gd)


func _calculate_speed_factor(gd) -> float:
	if gd.isRunning:
		return 1.0
	if gd.isCrouching:
		return 0.5
	if gd.isWalking:
		return 0.8
	return 0.0

