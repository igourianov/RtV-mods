extends RefCounted

const ModConfig = preload("../ModConfig.gd")
const Out = preload("../../Lib/Out.gd")
const BreathHoldPlayer = preload("../Audio/BreathHoldPlayer.gd")

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
const ARM_STAMINA_HOLD_BREATH_MOD: float = 2.0

const HOLD_BREATH_INTRO_DURATION: float = 0.5
const HOLD_BREATH_OUTRO_MIN_HOLD: float = 3.0

var _lib
var _interface
var gameData = preload("res://Resources/GameData.tres")
var _body_recovery_delay: float = 0.0
var _arm_recovery_delay: float = 0.0
var _hold_breath_time: float = 0.0
var _breath_sound


func _init(lib) -> void:
	_lib = lib


func on_stamina(delta: float) -> void:
	var chr: Node = _lib._caller as Node
	if !chr:
		return
	_lib.skip_super()

	_hold_breath(chr, delta)
	_body_stamina(chr, delta)
	_arm_stamina(chr, delta)


func _hold_breath(chr: Node, delta: float) -> void:

	if !is_instance_valid(_breath_sound):
		_breath_sound = BreathHoldPlayer.new()
		chr.add_child(_breath_sound)

	var intent: bool = Input.is_action_pressed("sprint")
	var allowed: bool = gameData.isAiming && gameData.armStamina > 0.0
	var holding: bool = ModConfig.hold_breath_state > 0.0

	if holding:
		_hold_breath_time += delta
	else:
		_hold_breath_time = 0.0

	if !holding && intent && allowed:
		_breath_sound.hold()
		ModConfig.hold_breath_state = 0.001
	elif holding && (!intent || !allowed):
		if _hold_breath_time > HOLD_BREATH_OUTRO_MIN_HOLD:
			_breath_sound.release()
		ModConfig.hold_breath_state = 0.0
	elif holding:
		ModConfig.hold_breath_state = clampf(_hold_breath_time / HOLD_BREATH_INTRO_DURATION, 0.0, 1.0)


func _body_stamina(chr: Node, delta: float) -> void:

	if !is_instance_valid(_interface):
		_interface = chr.get_node("/root/Map/Core/UI/Interface")
	
	var inv_cap: float = _interface.currentInventoryCapacity if _interface.currentInventoryCapacity else _interface.baseCarryWeight
	var weight_factor: float = maxf(BODY_STAMINA_FACTOR_MIN, _interface.currentInventoryWeight / inv_cap)
	var stamina: float = 0.0

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


func _arm_stamina(chr: Node, delta: float) -> void:
	var stamina: float = 0.0
	var weight_factor: float = ModConfig.current_weapon_weight / ModConfig.BASE_WEAPON_WEIGHT
	if gameData.isCanted:
		stamina = ARM_STAMINA_CANTED * weight_factor
		_arm_recovery_delay = 0.0
	elif gameData.isAiming:
		stamina = ARM_STAMINA_AIM_ZOOM if ModConfig.current_scope_mag >= 2.0 else ARM_STAMINA_AIM
		stamina *= weight_factor
		if ModConfig.hold_breath_state > 0.0:
			stamina *= ARM_STAMINA_HOLD_BREATH_MOD
		elif gameData.isCrouching:
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
