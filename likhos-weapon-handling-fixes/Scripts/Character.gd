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
const ARM_STAMINA_HOLD_BREATH_MOD: float = 2.0

const HOLD_BREATH_STREAM_PATH: String = "res://mods/likhos-weapon-handling-fixes/Audio/hold_breath.mp3"
const HOLD_BREATH_SOUND_NODE: String = "LikhoHoldBreathSound"
const HOLD_BREATH_VOLUME_DB: float = 0.0
const HOLD_BREATH_PLAY_INDEX_META: StringName = &"likho_hold_breath_play_index"
const HOLD_BREATH_INTRO_DURATION: float = 0.5
const HOLD_BREATH_OUTRO_START: float = 0.5
const HOLD_BREATH_OUTRO_MIN_HOLD: float = 3.0


var _lib
var _interface
var gameData = preload("res://Resources/GameData.tres")
var _body_recovery_delay: float = 0.0
var _arm_recovery_delay: float = 0.0
var _hold_breath_pressed: bool = false
var _hold_breath_time: float = 0.0
var _intro_started_at: int = -1
var _hold_breath_stream: AudioStream


func _init(lib) -> void:
	_lib = lib
	_hold_breath_stream = _load_stream(HOLD_BREATH_STREAM_PATH)


func _load_stream(path: String) -> AudioStream:
	if !FileAccess.file_exists(path):
		Out.warning("hold breath audio missing: %s" % path)
		return null
	var stream := AudioStreamMP3.new()
	stream.data = FileAccess.get_file_as_bytes(path)
	return stream


# removes stamina drain on isInspecting
func on_stamina(delta: float) -> void:
	if _lib._caller == null:
		return
	_lib.skip_super()
	if !_interface:
		_interface = _lib._caller.get_node("/root/Map/Core/UI/Interface")
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
				_play_sound(HOLD_BREATH_OUTRO_START, 0.0)
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
	_play_sound(0.0, HOLD_BREATH_INTRO_DURATION)


func _play_sound(start: float, duration: float) -> void:
	if !_hold_breath_stream:
		return
	var caller = _lib._caller
	if !caller:
		return
	var audio: AudioStreamPlayer = caller.get_node_or_null(HOLD_BREATH_SOUND_NODE)
	if !audio:
		audio = AudioStreamPlayer.new()
		audio.name = HOLD_BREATH_SOUND_NODE
		audio.bus = &"SFX"
		audio.volume_db = HOLD_BREATH_VOLUME_DB
		audio.stream = _hold_breath_stream
		caller.add_child(audio)
	else:
		audio.stop()
	var play_index: int = audio.get_meta(HOLD_BREATH_PLAY_INDEX_META, 0) + 1
	audio.set_meta(HOLD_BREATH_PLAY_INDEX_META, play_index)
	audio.play(start)
	if duration > 0.0:
		await caller.get_tree().create_timer(duration, false).timeout
		if is_instance_valid(audio) && audio.get_meta(HOLD_BREATH_PLAY_INDEX_META, 0) == play_index:
			audio.stop()


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
