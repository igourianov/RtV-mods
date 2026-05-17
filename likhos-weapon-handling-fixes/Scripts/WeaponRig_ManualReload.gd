extends "./WeaponRig_Base.gd"

enum ManualLoadState {
	NONE,
	OPEN,
	IDLE,
	INSERT,
	CLOSE,
}

var _manual_load_state := ManualLoadState.NONE


func _ready() -> void:
	set_process_input(true)


func _input(event) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var rig = owner
	if rig == null || rig.data.weaponAction != "Manual":
		return

	if _manual_load_state == ManualLoadState.NONE && event.is_action_pressed("prepare"):
		_do_insert()
	elif _manual_load_state == ManualLoadState.IDLE && event.is_action_pressed("fire"):
		_manual_load_state = ManualLoadState.INSERT
	elif _manual_load_state == ManualLoadState.IDLE && event.is_action_pressed("prepare"):
		_manual_load_state = ManualLoadState.CLOSE


func _do_insert():
	var rig = owner

	gameData.isInserting = true

	_manual_load_state = ManualLoadState.OPEN
	await play("Insert_Start", rig.data.insertStart)
	if !is_instance_valid(self):
		return
	_manual_load_state = ManualLoadState.IDLE

	rig.slotData.chamber = false
	rig.slotData.casing = false

	Out.protip("ammo-manual-insert", "Press [%s] to start reloading" % Inputs.get_binding("fire"))

	while _manual_load_state != ManualLoadState.CLOSE:
		if _manual_load_state == ManualLoadState.INSERT:
			if rig.slotData.amount < rig.data.maxAmount && rig.interface.GetAmmo(rig.data):
				await play("Insert", rig.data.insert, -0.1)
				if !is_instance_valid(self):
					return
				rig.slotData.amount += 1
			else:
				start_audio(rig.audioLibrary.UIError)
			_manual_load_state = ManualLoadState.IDLE
		await get_tree().process_frame
		if !is_instance_valid(self):
			return

	await play("Insert_End", rig.data.insertEnd, -1.0)
	if !is_instance_valid(self):
		return
	_manual_load_state = ManualLoadState.NONE

	if rig.data.weaponType == "Bolt":
		if rig.slotData.amount:
			rig.slotData.chamber = true
			rig.slotData.amount -= 1
		rig.slotData.set_meta("cocked", true)

	gameData.isInserting = false
