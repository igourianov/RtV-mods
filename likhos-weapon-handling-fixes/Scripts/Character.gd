extends RefCounted

const ModConfig = preload("./ModConfig.gd")

const STAMINA_VITAL_BREAKPOINT: float = 50.0
const STAMINA_RECOVERY: float = 30.0
const STAMINA_RECOVERY_DELAY: float = 2

const BODY_STAMINA_RUN: float = -20.0
const BODY_STAMINA_SWIM: float = -35.0

const ARM_STAMINA_AIM: float = -20.0
const ARM_STAMINA_AIM_ZOOM: float = -30.0
const ARM_STAMINA_CANTED: float = -10.0


var _lib
var gameData = preload("res://Resources/GameData.tres")
var _body_recovery_delay: float = 0.0
var _arm_recovery_delay: float = 0.0


func _init(lib) -> void:
	_lib = lib

# removes stamina drain on isInspecting
func on_stamina(delta: float) -> void:
	var c = _lib._caller
	if c == null:
		return
	_lib.skip_super()
	_body_stamina(delta)
	_arm_stamina(delta)


func _body_stamina(delta: float) -> void:
	var hydration_factor: float = (gameData.hydration - STAMINA_VITAL_BREAKPOINT) / STAMINA_VITAL_BREAKPOINT
	var stamina: float = 0.0
	if gameData.isSwimming && gameData.isMoving:
		stamina = BODY_STAMINA_SWIM * (1.0 - hydration_factor)
		_body_recovery_delay = 0.0
	elif gameData.isRunning:
		stamina = BODY_STAMINA_RUN * (1.0 - hydration_factor)
		_body_recovery_delay = 0.0
	elif _body_recovery_delay >= STAMINA_RECOVERY_DELAY:
		stamina = STAMINA_RECOVERY * (1.0 + hydration_factor)
	else:
		_body_recovery_delay += delta

	gameData.bodyStamina = clampf(gameData.bodyStamina + delta * stamina, 0.0, 100.0)


func _arm_stamina(delta: float) -> void:
	var energy_factor: float = (gameData.energy - STAMINA_VITAL_BREAKPOINT) / STAMINA_VITAL_BREAKPOINT
	var weight_factor: float = ModConfig.current_weapon_weight / ModConfig.BASE_WEAPON_WEIGHT
	var stamina: float = 0.0
	if gameData.isCanted:
		stamina = ARM_STAMINA_CANTED
		_arm_recovery_delay = 0.0
	elif gameData.isAiming:
		stamina = ARM_STAMINA_AIM_ZOOM if ModConfig.current_scope_mag >= 2.0 else ARM_STAMINA_AIM
		_arm_recovery_delay = 0.0
	elif _arm_recovery_delay >= STAMINA_RECOVERY_DELAY:
		stamina = STAMINA_RECOVERY
	else:
		_arm_recovery_delay += delta

	if stamina < 0.0:
		stamina *= weight_factor * (1.0 - energy_factor)
	elif stamina > 0.0:
		stamina *= (1.0 + energy_factor)

	gameData.armStamina = clampf(gameData.armStamina + delta * stamina, 0.0, 100.0)
