extends "./WeaponRig_Base.gd"

const _CLICK_AUDIO = preload("res://Audio/UI/Files/UI_Stack_01.wav")
const _CLICK_AUDIO_PLAYER := "Likho_DryClickAudio"
const _CLICK_START := 25
const _CLICK_END := 55
const _CLICK_VOLUME_OFFSET := 15.0


func _ready() -> void:
	set_physics_process(true)
	var rig = get_parent()
	if rig.slotData && !rig.slotData.has_meta("cocked"):
		rig.slotData.set_meta("cocked", rig.slotData.chamber)


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

	var triggered := false
	if slotData.mode == 1:
		triggered = Input.is_action_just_pressed("fire")
	elif slotData.mode == 2:
		triggered = Input.is_action_pressed("fire")
	if !triggered:
		return

	var cocked: bool = slotData.get_meta("cocked", false)

	if slotData.chamber && cocked:
		rig.FireEvent()
		if slotData.mode == 1:
			rig.fireImpulse = 0.1
			rig.fireRate = 0.1
		else:
			rig.fireImpulse = data.fireRate
			rig.fireRate = data.fireRate
		if (data.weaponAction == "Manual" || data.weaponAction == "Single") && !slotData.chamber:
			slotData.set_meta("cocked", false)
	elif !slotData.chamber && cocked:
		slotData.set_meta("cocked", false)
		_play_dry_click(rig)


func _play_dry_click(rig) -> void:
	Out.debug("_play_dry_click")
	var audio = rig.get_node_or_null(_CLICK_AUDIO_PLAYER)
	if !audio:
		audio = AudioStreamPlayer.new()
		audio.name = _CLICK_AUDIO_PLAYER
		audio.bus = &"SFX"
		audio.stream = _CLICK_AUDIO
		audio.volume_db = _CLICK_VOLUME_OFFSET
		rig.add_child(audio)
	else:
		audio.stop()
	audio.play(_CLICK_START / 1000.0)
	await rig.get_tree().create_timer((_CLICK_END - _CLICK_START) / 1000.0, false).timeout
	if is_instance_valid(audio):
		audio.stop()
