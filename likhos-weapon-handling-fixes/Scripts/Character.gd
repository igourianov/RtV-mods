extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const STAMINA_RECOVERY: float = 30.0
const STAMINA_RECOVERY_DELAY: float = 2
const STAMINA_RUN: float = -20.0
const STAMINA_SWIM: float = -40.0
const STAMINA_HYDRATION_STRENGTH: float = 0.5


var _lib
var gameData = preload("res://Resources/GameData.tres")
var _recovery_delay: float = 0.0


func _init(lib) -> void:
	_lib = lib

# removes stamina drain on isInspecting
func on_stamina(delta: float) -> void:
	var c = _lib._caller
	if c == null:
		return
	_lib.skip_super()
	_leg_stamina(delta)


func _leg_stamina(delta: float) -> void:
	var h_factor: float = (gameData.hydration - 50.0) / 50.0
	var stamina: float = 0.0
	if gameData.isSwimming && gameData.isMoving:
		stamina = STAMINA_SWIM * (1.0 - h_factor * STAMINA_HYDRATION_STRENGTH)
		_recovery_delay = 0.0
	elif gameData.isRunning:
		stamina = STAMINA_RUN * (1.0 - h_factor * STAMINA_HYDRATION_STRENGTH)
		_recovery_delay = 0.0
	elif _recovery_delay >= STAMINA_RECOVERY_DELAY:
		stamina = STAMINA_RECOVERY * (1.0 + h_factor * STAMINA_HYDRATION_STRENGTH)
	else:
		_recovery_delay += delta

	gameData.bodyStamina = clampf(gameData.bodyStamina + delta * stamina, 0.0, 100.0)


