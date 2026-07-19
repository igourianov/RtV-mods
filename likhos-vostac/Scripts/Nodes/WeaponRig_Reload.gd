extends "./WeaponRig_Base.gd"

const _HOLD_THRESHOLD = 0.3
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
	PENDING,
	PULLING,
	RELEASED,
	PAUSED,
	RETURNING,
}

var _state: State = State.NONE
var _state_timer: float = 0.0


func _ready() -> void:
	set_process_input(true)
	set_process(true)


func _exit_tree() -> void:
	gameData.isReloading = false
	gameData.isChecking = false
	ModConfig.ammo_check_view = false


func _input(event: InputEvent) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading:
		return

	var rig = get_parent()

	if _state == State.NONE && event.is_action_pressed("reload"):
		if rig.magazine.visible || rig.data.weaponAction == "Manual":
			_state = State.PENDING
			_state_timer = _HOLD_THRESHOLD
		else:
			_do_reload(false)
	elif _state == State.PENDING && event.is_action_released("reload"):
		_state = State.NONE
		_do_reload(false)
	elif (_state == State.PULLING || _state == State.PAUSED) && event.is_action_released("reload"):
		_state = State.RELEASED
	elif _state == State.PAUSED && event.is_action_pressed("fire") && rig.data.weaponAction != "Manual":
		if await _do_reload(true):
			_state = State.NONE
			gameData.isChecking = false


func _process(delta: float) -> void:
	if _state_timer > 0.0:
		_state_timer -= delta
	var timer_expired: bool = _state_timer <= 0.0
	var rig = get_parent()

	if _state == State.PENDING && timer_expired:
		_state = State.PULLING
		gameData.isChecking = true
		gameData.isFiring = false
		ModConfig.ammo_check_view = false
		_set_view_delayed(true)
		rig.UpdateBullets()
		rig.UpdateHUD()
		start_animation("Ammo_Check")
		_audio_player.play_event(rig.data.ammoCheck)
		_state_timer = AMMO_CHECK_INTRO_TIMES.get(rig.data.file, _AMMO_CHECK_INTRO_TIME_DEFAULT)
		return

	if _state == State.PULLING && timer_expired:
		_state = State.PAUSED
		rig.animator.process_mode = Node.PROCESS_MODE_DISABLED
		_audio_player.stream_paused = true
		if rig.data.weaponAction != "Manual":
			Out.protip("ammo-check-reload", "Press [%s] to reload" % Inputs.get_binding("fire"))
		return

	if _state == State.RELEASED && timer_expired:
		_state = State.RETURNING
		rig.animator.process_mode = Node.PROCESS_MODE_INHERIT
		_audio_player.stream_paused = false
		_set_view_delayed(false)
		await await_animation(-0.5)
		if is_instance_valid(self):
			gameData.isChecking = false
			_state = State.NONE
		return



func _set_view_delayed(shown: bool) -> void:
	await get_tree().create_timer(_VIEW_DELAY, false).timeout
	if is_instance_valid(self):
		ModConfig.ammo_check_view = shown


func _do_reload(ammo_check: bool = false) -> bool:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading:
		return false

	var rig = get_parent()
	var data = rig.data
	var slotData = rig.slotData

	gameData.isFiring = false

	if slotData.state == "Jammed":
		gameData.isClearing = true
		_audio_player.play_event(rig.audioLibrary.malfunctionClearRifle)
		await get_tree().create_timer(2.0, false).timeout
		gameData.isClearing = false
		slotData.state = ""
		return true

	if data.weaponAction == "Manual":
		if slotData.chamber: # hack - reload only animates ejecting casing but not live round
			slotData.casing = true
		await _play_reload("Reload", data.reload, -0.2)
		slotData.set_meta("cocked", true)
		if slotData.amount:
			slotData.chamber = true
			slotData.amount -= 1
		rig.UpdateBullets()
		return true

	var anim_state: String
	var audio_event

	if ammo_check || !rig.magazine.visible:
		anim_state = "Magazine_Attach_Tactical" if slotData.chamber else "Magazine_Attach_Empty"
		audio_event = data.magazineAttachTactical if slotData.chamber else data.magazineAttachEmpty
	else:
		anim_state = "Reload_Tactical" if slotData.chamber else "Reload_Empty"
		audio_event = data.reloadTactical if slotData.chamber else data.reloadEmpty

	if !rig.interface.GetMagazine(data, rig.weaponSlot, rig.magazine.visible):
		return false

	if ammo_check || !rig.magazine.visible:
		_show_mag_delayed(rig)
		rig.UpdateBullets()
	else:
		_update_bullets_delayed(rig)

	await _play_reload(anim_state, audio_event)
	slotData.chamber = true
	slotData.set_meta("cocked", true)
	return true


func _play_reload(animation_state: String, audio_event, wait_offset: float = -0.5) -> void:
	gameData.isReloading = true
	get_parent().animator.process_mode = Node.PROCESS_MODE_INHERIT # reset paused state
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

