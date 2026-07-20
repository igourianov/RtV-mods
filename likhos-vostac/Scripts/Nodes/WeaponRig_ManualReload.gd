extends "./WeaponRig_Base.gd"

enum ManualLoadState {
	NONE,
	OPEN,
	IDLE,
	INSERT,
	CLOSE,
}

var _state := ManualLoadState.NONE
var _busy := false


func _ready() -> void:
	set_process(true)
	set_process_input(true)
	_inject_mosin_casing_eject() # BUGFIX for Mosin not playing casing animation when opening bolt for insertion


func _inject_mosin_casing_eject() -> void:
	var rig: WeaponRig = get_parent()
	if rig.data.file != "Mosin":
		return

	var player := rig.animations
	var tree := rig.animator
	if !player || !tree:
		return

	var anim_name := "Mosin_Insert_Start"
	if !player.has_animation(anim_name):
		return

	var anim := player.get_animation(anim_name)
	if anim.has_meta("likho_eject_injected"):
		return

	var base := tree.get_node(tree.root_node)
	if !base:
		return

	var track := anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(track, base.get_path_to(rig))
	anim.track_insert_key(track, 0.9, {"method": &"CasingEject", "args": []})
	anim.set_meta("likho_eject_injected", true)


func _input(event: InputEvent) -> void:
	if is_engine_busy() || gameData.isInspecting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var rig: WeaponRig = get_parent()
	if rig.data.weaponAction != "Manual":
		return

	if _state == ManualLoadState.NONE && event.is_action_pressed("prepare"):
		_state = ManualLoadState.OPEN
		return
	if _state == ManualLoadState.IDLE && event.is_action_pressed("fire"):
		_state = ManualLoadState.INSERT
		return
	if _state in [ManualLoadState.OPEN, ManualLoadState.IDLE, ManualLoadState.INSERT] && event.is_action_released("prepare"):
		_state = ManualLoadState.CLOSE
		return


func _process(_delta: float) -> void:
	if _state == ManualLoadState.NONE || _state == ManualLoadState.IDLE || _busy:
		return

	var rig: WeaponRig = get_parent()

	if _state == ManualLoadState.OPEN:
		gameData.isInserting = true
		if rig.data.weaponType == "Bolt" && rig.slotData.chamber: # hack - CasingEject() only checks slotData.casing==true
			rig.slotData.casing = true
		if (await _play("Insert_Start", rig.data.insertStart)) && _state == ManualLoadState.OPEN:
			_state = ManualLoadState.IDLE
			Out.protip("ammo-manual-insert", "Press [%s] to start reloading" % Inputs.get_binding("fire"))
		return

	if _state == ManualLoadState.INSERT:
		if rig.slotData.amount >= rig.data.maxAmount || !rig.interface.GetAmmo(rig.data):
			_state = ManualLoadState.IDLE
			_audio_player.play_event(rig.audioLibrary.UIError)
			return
		_insert_delayed(rig)
		if (await _play("Insert", rig.data.insert, -0.1)) && _state == ManualLoadState.INSERT:
			_state = ManualLoadState.IDLE
		return

	if _state == ManualLoadState.CLOSE:
		if rig.data.weaponType == "Bolt":
			_close_bolt_delayed(rig)
		if (await _play("Insert_End", rig.data.insertEnd, -1.0)) && _state == ManualLoadState.CLOSE:
			_state = ManualLoadState.NONE
		gameData.isInserting = false	
		return


func _play(animation_state: String, audio_event, wait_offset: float = -0.5) -> bool:
	_busy = true
	await play(animation_state, audio_event, wait_offset)
	if !is_instance_valid(self):
		return false
	_busy = false
	return true


func _insert_delayed(rig: WeaponRig):
	await get_tree().create_timer(0.5, false).timeout
	if is_instance_valid(rig):
		rig.slotData.amount += 1


func _close_bolt_delayed(rig: WeaponRig):
	await get_tree().create_timer(0.25, false).timeout
	if is_instance_valid(rig) && rig.slotData.amount:
		rig.slotData.chamber = true
		rig.slotData.amount -= 1
