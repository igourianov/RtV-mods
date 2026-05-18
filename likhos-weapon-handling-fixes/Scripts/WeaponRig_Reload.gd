extends "./WeaponRig_Base.gd"

const ModConfig = preload("./ModConfig.gd")

const _HOLD_THRESHOLD = 300
const _AMMO_CHECK_INTRO_TIME_DEFAULT = 1.0

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

enum AmmoCheckState {
	NONE,
	PENDING,
	PULL,
	PAUSED,
	RETURN,
	RELOAD,
}

var _ammo_check_state: AmmoCheckState = AmmoCheckState.NONE


func _ready() -> void:
	set_process_input(true)


func _input(event) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isInserting || gameData.isClearing || gameData.isReloading:
		return

	var rig = get_parent()

	if _ammo_check_state == AmmoCheckState.NONE && event.is_action_pressed("reload"):
		_ammo_check_state = AmmoCheckState.PENDING
		if rig.magazine.visible || rig.data.weaponAction == "Manual":
			_do_ammo_check()
	elif _ammo_check_state == AmmoCheckState.PENDING && event.is_action_released("reload"):
		_ammo_check_state = AmmoCheckState.NONE
		_do_reload()
	elif _ammo_check_state in [AmmoCheckState.PULL, AmmoCheckState.PAUSED] && event.is_action_released("reload"):
		_ammo_check_state = AmmoCheckState.RETURN
	elif _ammo_check_state == AmmoCheckState.PAUSED && event.is_action_pressed("fire") && rig.data.weaponAction != "Manual":
		_ammo_check_state = AmmoCheckState.RELOAD


# wrapper to cleanup after multiple exits
func _do_ammo_check() -> void:
	await _do_ammo_check_inner()
	gameData.isChecking = false
	ModConfig.ammo_check_view = false
	_ammo_check_state = AmmoCheckState.NONE


func _do_ammo_check_inner() -> void:
	var rig = get_parent()

	gameData.isFiring = false

	var hold_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - hold_start < _HOLD_THRESHOLD:
		if _ammo_check_state != AmmoCheckState.PENDING || !is_instance_valid(self):
			return
		await get_tree().process_frame

	_ammo_check_state = AmmoCheckState.PULL
	gameData.isChecking = true
	ModConfig.ammo_check_view = false

	rig.UpdateBullets()
	rig.UpdateHUD()

	start_animation("Ammo_Check")
	var audio = start_audio(rig.data.ammoCheck)

	var pull_time: float = AMMO_CHECK_INTRO_TIMES.get(rig.data.file, _AMMO_CHECK_INTRO_TIME_DEFAULT)
	await get_tree().create_timer(pull_time * 0.6, false).timeout
	if !is_instance_valid(self):
		return

	ModConfig.ammo_check_view = true
	await get_tree().create_timer(pull_time * 0.4, false).timeout
	if !is_instance_valid(self):
		return

	if _ammo_check_state == AmmoCheckState.PULL:
		_ammo_check_state = AmmoCheckState.PAUSED
		rig.animator.process_mode = Node.PROCESS_MODE_DISABLED
		audio.stream_paused = true
		if rig.data.weaponAction != "Manual":
			Out.protip("ammo-check-reload", "Press [%s] to reload" % Inputs.get_binding("fire"))

	while _ammo_check_state == AmmoCheckState.PAUSED:
		await get_tree().process_frame
		if !is_instance_valid(self):
			return

	rig.animator.process_mode = Node.PROCESS_MODE_INHERIT
	audio.stream_paused = false

	await get_tree().create_timer(0.5, false).timeout
	if !is_instance_valid(self):
		return
	ModConfig.ammo_check_view = false

	if _ammo_check_state == AmmoCheckState.RETURN:
		await await_animation(-0.5)
	elif _ammo_check_state == AmmoCheckState.RELOAD:
		await _do_reload(true)


func _do_reload(ammoCheck: bool = false) -> void:
	var rig = get_parent()
	var data = rig.data
	var slotData = rig.slotData
	var magAttach = ammoCheck || !rig.magazine.visible

	if is_engine_busy() || gameData.isReloading || gameData.isClearing:
		return

	gameData.isFiring = false

	if slotData.state == "Jammed":
		if !gameData.isClearing:
			gameData.isClearing = true
			start_audio(rig.audioLibrary.malfunctionClearRifle)
			await get_tree().create_timer(2.0, false).timeout
			gameData.isClearing = false
			slotData.state = ""
		return

	if data.weaponAction == "Manual" && !gameData.isInserting:
		await _play_reload("Reload", data.reload, -0.2)
		slotData.casing = false
		slotData.chamber = false
		if slotData.amount:
			slotData.chamber = true
			slotData.amount -= 1
		slotData.set_meta("cocked", true)
		rig.UpdateBullets()
		return

	if magAttach && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, rig.magazine.visible):
			_show_mag_delayed(rig)
			await _play_reload("Magazine_Attach_Empty", data.magazineAttachEmpty)
			slotData.chamber = true
			slotData.set_meta("cocked", true)
			rig.UpdateBullets()
		return

	if magAttach && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, rig.magazine.visible):
			_show_mag_delayed(rig)
			await _play_reload("Magazine_Attach_Tactical", data.magazineAttachTactical)
			slotData.set_meta("cocked", true)
			rig.UpdateBullets()
		return

	if rig.magazine.visible && !slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			await _play_reload("Reload_Empty", data.reloadEmpty)
			slotData.chamber = true
			slotData.set_meta("cocked", true)
		return

	if rig.magazine.visible && slotData.chamber:
		if rig.interface.GetMagazine(data, rig.weaponSlot, true):
			await _play_reload("Reload_Tactical", data.reloadTactical)
			slotData.set_meta("cocked", true)
		return


func _play_reload(animation_state: String, audio_event, wait_offset: float = -0.5) -> void:
	gameData.isReloading = true
	await play(animation_state, audio_event, wait_offset)
	gameData.isReloading = false


func _show_mag_delayed(rig):
	await rig.get_tree().create_timer(0.1, false).timeout;
	if is_instance_valid(rig):
		rig.magazine.show()
