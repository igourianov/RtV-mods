extends "./WeaponRig_Base.gd"

const AudioChunkPlayer = preload("../../Lib/AudioChunkPlayer.gd")

const _CLICK_AUDIO = preload("res://Audio/UI/Files/UI_Stack_01.wav")
const _CLICK_START := 25
const _CLICK_END := 55
const _CLICK_VOLUME_OFFSET := 15.0

var _dry_click_sound


func _ready() -> void:
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if is_engine_busy() || gameData.isReloading || gameData.isClearing || gameData.isInserting || gameData.isInspecting || gameData.isChecking:
		return

	var rig = get_parent()
	_fire_input(rig)
	rig.FireTimer(delta)
	rig.FireImpulse(delta)


func _fire_input(rig) -> void:
	var slotData = rig.slotData
	var data = rig.data

	if slotData.state == "Jammed":
		return

	if !ModConfig.negligent_discharge && !gameData.weaponPosition == 2 && !gameData.isAiming && !gameData.isCanted:
		return

	var cocked: bool = slotData.chamber || slotData.get_meta("cocked", true)
	var triggered := false
	
	if slotData.mode == 1:
		triggered = Input.is_action_just_pressed("fire")
	elif slotData.mode == 2:
		triggered = Input.is_action_pressed("fire")

	if !triggered || !cocked:
		return

	if !slotData.chamber:
		slotData.set_meta("cocked", false)
		_play_dry_click(rig)
		return

	rig.FireEvent()
	if slotData.mode == 1:
		rig.fireImpulse = 0.1
		rig.fireRate = 0.1
	else:
		rig.fireImpulse = data.fireRate
		rig.fireRate = data.fireRate

	if (data.weaponAction == "Manual" || data.weaponAction == "Single") && !slotData.chamber:
		slotData.set_meta("cocked", false)

	if !data.insert && slotData.amount < data.magazineSize * 0.3:
		Out.protip("low-mag-ammo", "Hold [%s] to check the mag" % Inputs.get_binding("reload"))
	elif data.insert && slotData.amount <= data.magazineSize * 0.4:
		Out.protip("low-internal-ammo", "Hold [%s] to load more ammo" % Inputs.get_binding("prepare"))


func _play_dry_click(rig) -> void:
	Out.debug("_play_dry_click")
	if !is_instance_valid(_dry_click_sound):
		_dry_click_sound = AudioChunkPlayer.new(_CLICK_AUDIO, _CLICK_VOLUME_OFFSET)
		rig.add_child(_dry_click_sound)
	_dry_click_sound.play_chunk(_CLICK_START / 1000.0, (_CLICK_END - _CLICK_START) / 1000.0)
