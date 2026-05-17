extends RefCounted

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")
const SoundChannel = preload("./SoundChannel.gd")

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

const HOLD_BREATH_STREAM_PATH: String = "res://mods/likhos-weapon-handling-fixes/Audio/hold_breath.mp3"
const HOLD_BREATH_INTRO_DURATION: float = 0.5
const HOLD_BREATH_OUTRO_START: float = 0.5
const HOLD_BREATH_OUTRO_MIN_HOLD: float = 3.0

const POINTING_SOUND_NODE := "LikhoPointingDeviceSound"
const POINTING_SOUND_VOLUME := -10.0
const POINTING_SOUND_STREAM = preload("res://Audio/Interaction/Files/Flashlight.wav")


var _lib
var _interface
var gameData = preload("res://Resources/GameData.tres")
var _body_recovery_delay: float = 0.0
var _arm_recovery_delay: float = 0.0
var _hold_breath_pressed: bool = false
var _hold_breath_time: float = 0.0
var _intro_started_at: int = -1
var _hold_breath_stream: AudioStream
var _breath_sound


func _init(lib) -> void:
	_lib = lib
	_hold_breath_stream = AudioStreamMP3.load_from_file(HOLD_BREATH_STREAM_PATH)


func _ensure_channels(host: Node) -> void:
	if !is_instance_valid(_breath_sound):
		_breath_sound = SoundChannel.new(&"SFX", 0.0, _hold_breath_stream)
		host.add_child(_breath_sound)
	if !host.has_node(POINTING_SOUND_NODE):
		var pointing_sound = SoundChannel.new(&"SFX", POINTING_SOUND_VOLUME, POINTING_SOUND_STREAM)
		pointing_sound.name = POINTING_SOUND_NODE
		host.add_child(pointing_sound)


# removes stamina drain on isInspecting
func on_stamina(delta: float) -> void:
	if _lib._caller == null:
		return
	_lib.skip_super()
	if !_interface:
		_interface = _lib._caller.get_node("/root/Map/Core/UI/Interface")
	_ensure_channels(_lib._caller)
	_update_hold_breath(delta)
	_body_stamina(delta, _interface.currentInventoryWeight, _interface.currentInventoryCapacity if _interface.currentInventoryCapacity else _interface.baseCarryWeight)
	_arm_stamina(delta)


func _update_hold_breath(delta: float) -> void:
	var pressed: bool = Input.is_action_pressed("sprint")
	var can_hold: bool = gameData.isAiming && gameData.armStamina > 0.0

	if ModConfig.hold_breath:
		_hold_breath_time += delta
		ModConfig.hold_breath_progress = clampf(_hold_breath_time / HOLD_BREATH_INTRO_DURATION, 0.0, 1.0)
		if !pressed || !can_hold:
			ModConfig.hold_breath = false
			ModConfig.hold_breath_progress = 0.0
			if _hold_breath_time > HOLD_BREATH_OUTRO_MIN_HOLD:
				_breath_sound.play_stream(null, HOLD_BREATH_OUTRO_START, 0.0)
	elif pressed && !_hold_breath_pressed && can_hold:
		ModConfig.hold_breath = true
		ModConfig.hold_breath_progress = 0.0
		_hold_breath_time = 0.0
		_play_intro()

	_hold_breath_pressed = pressed


func _play_intro() -> void:
	var now: int = Time.get_ticks_msec()
	if _intro_started_at >= 0 && now - _intro_started_at < int(HOLD_BREATH_INTRO_DURATION * 1000.0):
		return
	_intro_started_at = now
	_breath_sound.play_stream(null, 0.0, HOLD_BREATH_INTRO_DURATION)


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
		if ModConfig.hold_breath:
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
