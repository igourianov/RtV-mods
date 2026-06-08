extends "./WeaponRig_Base.gd"

const ModConfig = preload("./ModConfig.gd")

const _HOLD_THRESHOLD = 300
const _AMMO_CHECK_INTRO_TIME_DEFAULT = 1.0
const _VIEW_DELAY = 0.5

const AMMO_CHECK_INTRO_TIMES = {
	"AKM": 1.65,
	"AK_12": 1.45,
	"AKS_74U": 1.40,
	"RK_62": 1.35,
	"RK_62M": 1.35,
	"RK_95": 1.35,
	"M4A1": 1.15,
	"MK18": 1.2,
	"HK416": 1.2,
	"KAR_21_223": 1.05,
	"KAR_21_308": 1.05,
	"M78": 1.25,
	"MP5": 1.0,
	"MP5K": 1.0,
	"MP5SD": 1.0,
	"MP7": 1.3,
	"KP_31": 1.2,
	"VSS": 1.45,
	"SVD": 2.0,
	"Mosin": 1.5,
	"Remington_870": 1.2,
	"Makarov": 1.75,
	"P320": 1.15,
	"Glock_17": 1.15,
	"Colt_1911": 1.15,
}

enum State {
	NONE,
	PENDING_CHECK,
	CHECK_PULL,
	CHECK_PULL_RELEASED,
	CHECK_PAUSED,
	RELOAD_FROM_CHECK,
	RETURN,
	BUSY,
}

var _state: State = State.NONE
var _timer: float = 0.0
var _audio: AudioStreamPlayer = null


func _ready() -> void:
	set_process_input(true)
	set_process(true)


func _exit_tree() -> void:
	_cleanup()


func _input(event: InputEvent) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading:
		return

	var rig = get_parent()

	if _state == State.NONE && event.is_action_pressed("reload"):
		if rig.magazine.visible || rig.data.weaponAction == "Manual":
			_state = State.PENDING_CHECK
			_timer = _HOLD_THRESHOLD / 1000.0
			gameData.isFiring = false
		else:
			_do_reload()
	elif _state == State.PENDING_CHECK && event.is_action_released("reload"):
		_do_reload()
	elif _state == State.CHECK_PULL && event.is_action_released("reload"):
		_state = State.CHECK_PULL_RELEASED
	elif _state == State.CHECK_PAUSED && event.is_action_released("reload"):
		_state = State.RETURN
	elif _state == State.CHECK_PAUSED && event.is_action_pressed("fire") && rig.data.weaponAction != "Manual":
		_state = State.RELOAD_FROM_CHECK


func _process(delta: float) -> void:
	_timer -= delta
	var timer_expired: bool = _timer <= 0.0
	var rig = get_parent()

	if _state == State.PENDING_CHECK && timer_expired:
		_state = State.CHECK_PULL
		gameData.isChecking = true
		ModConfig.ammo_check_view = false
		_set_view_delayed(true)
		rig.UpdateBullets()
		rig.UpdateHUD()
		start_animation("Ammo_Check")
		_audio = start_audio(rig.data.ammoCheck)
		_timer = AMMO_CHECK_INTRO_TIMES.get(rig.data.file, _AMMO_CHECK_INTRO_TIME_DEFAULT)
		return

	if _state == State.CHECK_PULL_RELEASED && timer_expired:
		_state = State.RETURN
		return

	if _state == State.CHECK_PULL && timer_expired:
		_state = State.CHECK_PAUSED
		rig.animator.process_mode = Node.PROCESS_MODE_DISABLED
		_audio.stream_paused = true
		if rig.data.weaponAction != "Manual":
			Out.protip("ammo-check-reload", "Press [%s] to reload" % Inputs.get_binding("fire"))
		return

	if _state == State.RETURN:
		_state = State.BUSY
		rig.animator.process_mode = Node.PROCESS_MODE_INHERIT
		_audio.stream_paused = false
		_set_view_delayed(false)
		await await_animation(-0.5)
		if is_instance_valid(self):
			_cleanup()
		return

	if _state == State.RELOAD_FROM_CHECK:
		rig.animator.process_mode = Node.PROCESS_MODE_INHERIT
		_audio.stop()
		ModConfig.ammo_check_view = false
		_do_reload(true)
		return


func _set_view_delayed(shown: bool) -> void:
	await get_tree().create_timer(_VIEW_DELAY, false).timeout
	if is_instance_valid(self):
		ModConfig.ammo_check_view = shown


func _do_reload(ammo_check: bool = false) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading:
		_cleanup()
		return

	_state = State.BUSY
	var rig = get_parent()
	var data = rig.data
	var slotData = rig.slotData
	var magAttach: bool = ammo_check || !rig.magazine.visible

	gameData.isFiring = false

	if slotData.state == "Jammed":
		gameData.isClearing = true
		start_audio(rig.audioLibrary.malfunctionClearRifle)
		await get_tree().create_timer(2.0, false).timeout
		gameData.isClearing = false
		slotData.state = ""
		_cleanup()
		return

	if data.weaponAction == "Manual":
		if slotData.chamber:
			slotData.chamber = false
			slotData.casing = true
		await _play_reload("Reload", data.reload, -0.2)
		slotData.casing = false
		slotData.set_meta("cocked", true)
		if slotData.amount:
			slotData.chamber = true
			slotData.amount -= 1
		rig.UpdateBullets()
		_cleanup()
		return

	if !magAttach && !rig.magazine.visible:
		_cleanup()
		return

	var empty: bool = !slotData.chamber
	var anim_state: String
	var audio_event

	if magAttach:
		anim_state = "Magazine_Attach_Empty" if empty else "Magazine_Attach_Tactical"
		audio_event = data.magazineAttachEmpty if empty else data.magazineAttachTactical
	else:
		anim_state = "Reload_Empty" if empty else "Reload_Tactical"
		audio_event = data.reloadEmpty if empty else data.reloadTactical

	if !rig.interface.GetMagazine(data, rig.weaponSlot, rig.magazine.visible):
		_cleanup()
		return

	if magAttach:
		_show_mag_delayed(rig)
		rig.UpdateBullets()
	else:
		_update_bullets_delayed(rig)

	await _play_reload(anim_state, audio_event)
	slotData.chamber = true
	slotData.set_meta("cocked", true)
	_cleanup()


func _play_reload(animation_state: String, audio_event, wait_offset: float = -0.5) -> void:
	gameData.isReloading = true
	await play(animation_state, audio_event, wait_offset)
	gameData.isReloading = false


func _show_mag_delayed(rig) -> void:
	await rig.get_tree().create_timer(0.1, false).timeout
	if is_instance_valid(rig):
		rig.magazine.show()


func _update_bullets_delayed(rig) -> void:
	await rig.get_tree().create_timer(1.2, false).timeout
	if is_instance_valid(rig):
		rig.UpdateBullets()


func _cleanup() -> void:
	gameData.isChecking = false
	gameData.isReloading = false
	ModConfig.ammo_check_view = false
	_state = State.NONE
