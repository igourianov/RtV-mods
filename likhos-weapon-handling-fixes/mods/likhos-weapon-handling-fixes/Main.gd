extends Node

const _META_LASER_LATCH = "likho_laser_latch"
const _LASER_SOUND_VOLUME_DB = -12.0
const _CLICK_IN_PATH = "res://mods/likhos-weapon-handling-fixes/click-in.wav"
const _CLICK_OUT_PATH = "res://mods/likhos-weapon-handling-fixes/click-out.wav"

var _lib
var _click_in: AudioStreamWAV
var _click_out: AudioStreamWAV


func _ready() -> void:
	if not Engine.has_meta("RTVModLib"):
		push_error("[likho] RTVModLib meta not available")
		return
	_lib = Engine.get_meta("RTVModLib")
	_click_in = _load_wav(_CLICK_IN_PATH)
	_click_out = _load_wav(_CLICK_OUT_PATH)
	_lib.hook("handling-weaponhandling", _on_weapon_handling)
	_lib.hook("weaponrig-ads-post", _on_ads_post)
	_lib.hook("weaponrig-ammocheck", _on_ammo_check)
	print("[likho] hooks registered")


func _load_wav(path: String) -> AudioStreamWAV:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("[likho] failed to open %s" % path)
		return null
	var bytes = f.get_buffer(f.get_length())
	f.close()
	var stream = AudioStreamWAV.load_from_buffer(bytes)
	if stream == null:
		push_warning("[likho] failed to parse wav at %s" % path)
	return stream


func _on_weapon_handling(delta: float) -> void:
	var h = _lib._caller
	if h == null:
		return
	_lib.skip_super()
	_weapon_handling(h, delta)


func _on_ads_post(_delta: float) -> void:
	var rig = _lib._caller
	if rig == null or not rig.gameData.PIP:
		return
	var optic = rig.activeOptic
	if optic == null or not optic.attachmentData.variable:
		return
	if rig.slotData == null or rig.slotData.zoom != 1:
		return
	rig.gameData.isScoped = true
	optic.camera.fov = rig.gameData.baseFOV - 45


func _on_ammo_check() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	if rig.gameData.isChecking:
		_lib.skip_super()
		return
	_ammo_check_preserve_position(rig)
	_lib.skip_super()


func _ammo_check_preserve_position(rig) -> void:
	var prev_position = rig.gameData.weaponPosition
	await rig._rtv_vanilla_AmmoCheck()
	rig.gameData.weaponPosition = prev_position


func _weapon_handling(h, delta: float) -> void:
	var gd = h.gameData
	var data = h.data

	if gd.freeze:
		return

	var speed: float = delta * h.handlingSpeed
	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), speed)
	h.rotation_degrees = lerp(h.rotation_degrees, h.targetRotation, speed)

	if gd.isClearing:
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if h.collision.is_colliding():
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		gd.isColliding = true
		gd.isAiming = false
		gd.isCanted = false
		return

	gd.isColliding = false

	if gd.isPlacing:
		gd.weaponPosition = 1
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if gd.isInspecting:
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return

	var ready_pos = data.highPosition if gd.weaponPosition == 2 else data.lowPosition
	var ready_rot = data.highRotation if gd.weaponPosition == 2 else data.lowRotation

	if gd.isRunning || gd.isChecking || (gd.isReloading && data.weaponAction != "Manual"):
		h.aimToggle = false
		h.canted = false
		gd.isAiming = false
		gd.isCanted = false
		h.targetPosition = ready_pos
		h.targetRotation = ready_rot
		return

	if gd.aimMode == 1:
		h.canted = Input.is_action_pressed("canted")
	elif gd.aimMode == 2 && Input.is_action_just_pressed("canted"):
		h.canted = !h.canted

	if h.canted:
		if gd.aimMode == 1:
			_laser_activate(h)
		gd.isCanted = true
		gd.isAiming = false
		h.targetPosition = data.cantedPosition - Vector3(0.0, 0.05, 0.0)
		h.targetRotation = data.cantedRotation
		return

	_laser_deactivate(h)
	gd.isCanted = false

	if gd.aimMode == 2 && Input.is_action_just_pressed("aim"):
		h.aimToggle = !h.aimToggle

	if gd.aimMode == 2:
		gd.isAiming = h.aimToggle
	else:
		gd.isAiming = Input.is_action_pressed("aim")

	if not gd.isAiming:
		h.targetPosition = ready_pos
		h.targetRotation = ready_rot
		return

	var parent = h.get_parent()
	h.targetPosition = Vector3(0.0, -parent.aimOffset, data.aimPosition.z) if parent.activeOptic else data.aimPosition
	h.targetRotation = data.aimRotation

	if gd.isScoped && gd.PIP:
		h.targetPosition += Vector3(0.0, 0.0, 0.05)


func _find_laser(h) -> Node:
	var rig = h.get_parent()
	if rig == null:
		return null
	var atts = rig.get("attachments")
	if atts == null:
		return null
	for child in atts.get_children():
		if child.visible and child.has_method("PlayLaser"):
			return child
	return null


func _laser_activate(h) -> void:
	if h.get_meta(_META_LASER_LATCH, false):
		return
	var node = _find_laser(h)
	if node == null or node.active:
		return
	node.active = true
	node.raycast.global_position = node.owner.raycast.global_position
	node.laser.show()
	_play_laser_sound(node, _click_in)
	h.set_meta(_META_LASER_LATCH, true)


func _laser_deactivate(h) -> void:
	if not h.get_meta(_META_LASER_LATCH, false):
		return
	h.set_meta(_META_LASER_LATCH, false)
	var node = _find_laser(h)
	if node == null:
		return
	node.active = false
	node.laser.hide()
	_play_laser_sound(node, _click_out)


func _play_laser_sound(node, stream: AudioStreamWAV) -> void:
	var audio = node.audioInstance2D.instantiate()
	node.add_child(audio)
	if stream != null:
		audio.stream = stream
		audio.volume_db = _LASER_SOUND_VOLUME_DB
		audio.play()
	else:
		audio.PlayInstance(node.audioLibrary.UIClick)
		audio.volume_db += _LASER_SOUND_VOLUME_DB
