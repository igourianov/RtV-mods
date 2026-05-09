extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

const STAMINA_RECOVERY: float = 100.0
const STAMINA_RECOVERY_DELAY: float = 2.0
const STAMINA_RECOVERY_DELAY_EMPTY: float = 5.0
const STAMINA_RECOVERY_DELAY_MIN: float = 0.2

const BODY_STAMINA_RUN: float = -15.0
const BODY_STAMINA_SWIM: float = -20.0
const BODY_STAMINA_FACTOR_MIN: float = 0.2

const ARM_STAMINA_CANTED: float = -2.0
const ARM_STAMINA_AIM: float = -3.0
const ARM_STAMINA_AIM_ZOOM: float = -3.5
const ARM_STAMINA_RAISED: float = -2.0
const ARM_STAMINA_AIM_CROUCH_MOD: float = 0.5


var _lib
var _interface
var gameData = preload("res://Resources/GameData.tres")
var _body_recovery_delay: float = 0.0
var _arm_recovery_delay: float = 0.0


func _init(lib) -> void:
	_lib = lib

# removes stamina drain on isInspecting
func on_stamina(delta: float) -> void:
	if _lib._caller == null:
		return
	_lib.skip_super()
	if !_interface:
		_interface = _lib._caller.get_node("/root/Map/Core/UI/Interface")
	_body_stamina(delta, _interface.currentInventoryWeight, _interface.currentInventoryCapacity if _interface.currentInventoryCapacity else _interface.baseCarryWeight)
	_arm_stamina(delta)


func _body_stamina(delta: float, current_inv_weight: float, max_inv_weight: float) -> void:
	var stamina: float = 0.0
	var weight_factor: float = maxf(BODY_STAMINA_FACTOR_MIN, current_inv_weight / max_inv_weight)
	if gameData.isSwimming && gameData.isMoving:
		stamina = BODY_STAMINA_SWIM * weight_factor
		_body_recovery_delay = 0.0
	elif gameData.isRunning:
		stamina = BODY_STAMINA_RUN * weight_factor
		_body_recovery_delay = 0.0
	elif gameData.bodyStamina >= 100.0:
		return
	else:
		var hydration_factor: float = gameData.hydration / 100.0
		if _body_recovery_delay < _recovery_delay_threshold(gameData.bodyStamina, hydration_factor):
			_body_recovery_delay += delta
			return
		stamina = STAMINA_RECOVERY * hydration_factor * hydration_factor

	gameData.bodyStamina = clampf(gameData.bodyStamina + delta * stamina, 0.0, 100.0)


func _arm_stamina(delta: float) -> void:
	var stamina: float = 0.0
	var weight_factor: float = ModConfig.current_weapon_weight / ModConfig.BASE_WEAPON_WEIGHT
	if gameData.isCanted:
		stamina = ARM_STAMINA_CANTED * weight_factor
		_arm_recovery_delay = 0.0
	elif gameData.isAiming:
		stamina = ARM_STAMINA_AIM_ZOOM if ModConfig.current_scope_mag >= 2.0 else ARM_STAMINA_AIM
		stamina *= weight_factor
		if gameData.isCrouching:
			stamina *= ARM_STAMINA_AIM_CROUCH_MOD
		_arm_recovery_delay = 0.0
	elif gameData.weaponPosition == 2:
		stamina = ARM_STAMINA_RAISED * weight_factor
		_arm_recovery_delay = 0.0
	elif gameData.armStamina >= 100.0:
		return
	else:
		var energy_factor: float = gameData.energy / 100.0
		if _arm_recovery_delay < _recovery_delay_threshold(gameData.armStamina, energy_factor):
			_arm_recovery_delay += delta
			return
		stamina = STAMINA_RECOVERY * energy_factor * energy_factor

	gameData.armStamina = clampf(gameData.armStamina + delta * stamina, 0.0, 100.0)


func _recovery_delay_threshold(current_stamina: float, vital_factor: float) -> float:
	var delay_base: float = STAMINA_RECOVERY_DELAY_EMPTY if current_stamina <= 0.0 else STAMINA_RECOVERY_DELAY
	return maxf(STAMINA_RECOVERY_DELAY_MIN, delay_base * (1.0 - vital_factor))

