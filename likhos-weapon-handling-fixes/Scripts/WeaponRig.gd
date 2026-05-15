extends RefCounted

const Out = preload("../Lib/Out.gd")
const WeaponRig_Reload = preload("./WeaponRig_Reload.gd")
const WeaponRig_ManualReload = preload("./WeaponRig_ManualReload.gd")
const WeaponRig_Optic = preload("./WeaponRig_Optic.gd")
const WeaponRig_Inspect = preload("./WeaponRig_Inspect.gd")

const _CLICK_AUDIO = preload("res://Audio/UI/Files/UI_Stack_01.wav")
const _CLICK_AUDIO_PLAYER := "Likho_DryClickAudio"
#const _CLICK_SEGMENTS := [0,25,25,55,80,115,160,195] # sound file segment tuples (ms)
const _CLICK_START := 25
const _CLICK_END := 55
const _CLICK_VOLUME_OFFSET := 15.0

var gameData = preload("res://Resources/GameData.tres")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_ready_post() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	Out.debug("WeaponRig: injecting handlers")
	_inject_handler(rig, WeaponRig_Reload, "Likho_WeaponRig_Reload")
	_inject_handler(rig, WeaponRig_ManualReload, "Likho_WeaponRig_ManualReload")
	_inject_handler(rig, WeaponRig_Optic, "Likho_WeaponRig_Optic")
	_inject_handler(rig, WeaponRig_Inspect, "Likho_WeaponRig_Inspect")

	if rig.slotData != null && !rig.slotData.has_meta("cocked"):
		rig.slotData.set_meta("cocked", rig.slotData.chamber)


func _inject_handler(rig, klass, node_name: String) -> void:
	var h = klass.new()
	h.name = node_name
	rig.add_child(h)
	h.owner = rig
	h.set_process_input(true)
	h.set_process(true)


func on_physics_process(delta: float) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	if _is_busy() || gameData.isReloading || gameData.isClearing || gameData.isInserting || gameData.isInspecting || gameData.isChecking:
		return

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
	if audio == null:
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


func _is_busy() -> bool:
	return (gameData.freeze
		|| gameData.isDead
		|| gameData.isPlacing
		|| gameData.isDrawing
		|| gameData.isCaching
		|| gameData.isTransitioning
		|| gameData.isOccupied)
