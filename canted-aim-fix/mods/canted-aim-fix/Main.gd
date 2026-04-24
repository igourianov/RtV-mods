extends Node

const _META_LASER_LATCH = "canted_aim_fix_laser_latch"

var _lib


func _ready() -> void:
	if not Engine.has_meta("RTVModLib"):
		push_error("[canted-aim-fix] RTVModLib meta not available")
		return
	_lib = Engine.get_meta("RTVModLib")
	_lib.hook("handling-weaponhandling", _on_replace)
	print("[canted-aim-fix] hook registered for handling-weaponhandling")


func _on_replace(delta: float) -> void:
	var h = _lib._caller
	if h == null:
		return
	_lib.skip_super()
	_weapon_handling(h, delta)


func _weapon_handling(h, delta: float) -> void:
	var gd = h.gameData
	var data = h.data
	var collision = h.collision

	if gd.freeze:
		return

	h.position = lerp(h.position, Vector3(-h.targetPosition.x, h.targetPosition.y, -h.targetPosition.z), delta * h.handlingSpeed)
	h.rotation_degrees.x = lerp(h.rotation_degrees.x, h.targetRotation.x, delta * h.handlingSpeed)
	h.rotation_degrees.y = lerp(h.rotation_degrees.y, h.targetRotation.y, delta * h.handlingSpeed)
	h.rotation_degrees.z = lerp(h.rotation_degrees.z, h.targetRotation.z, delta * h.handlingSpeed)

	if gd.isClearing:
		_laser_deactivate(h)
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if collision.is_colliding():
		_laser_deactivate(h)
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		gd.isColliding = true
		gd.isAiming = false
		gd.isCanted = false
		return
	else:
		gd.isColliding = false

	if gd.isPlacing:
		_laser_deactivate(h)
		gd.weaponPosition = 1
		h.targetPosition = data.lowPosition
		h.targetRotation = data.lowRotation
		return

	if gd.isInspecting:
		_laser_deactivate(h)
		h.targetPosition = data.inspectPosition
		h.targetRotation = data.inspectRotation
		return

	if gd.isRunning || gd.isChecking || (gd.isReloading && data.weaponAction != "Manual"):
		_laser_deactivate(h)
		if gd.weaponPosition == 1:
			h.aimToggle = false
			h.canted = false
			gd.isAiming = false
			gd.isCanted = false
			h.targetPosition = data.lowPosition
			h.targetRotation = data.lowRotation
			return
		elif gd.weaponPosition == 2:
			h.aimToggle = false
			h.canted = false
			gd.isAiming = false
			gd.isCanted = false
			h.targetPosition = data.highPosition
			h.targetRotation = data.highRotation
			return

	if gd.aimMode == 1:
		h.canted = Input.is_action_pressed("canted")
	elif gd.aimMode == 2:
		if Input.is_action_just_pressed("canted"):
			h.canted = !h.canted

	if h.canted:
		if gd.aimMode == 1:
			_laser_activate(h)
		gd.isCanted = true
		gd.isAiming = false
		h.targetPosition = data.cantedPosition
		h.targetRotation = data.cantedRotation
		return

	_laser_deactivate(h)
	gd.isCanted = false

	var aiming := false
	if gd.aimMode == 1:
		aiming = Input.is_action_pressed("aim")
	elif gd.aimMode == 2:
		if Input.is_action_just_pressed("aim"):
			h.aimToggle = !h.aimToggle
		aiming = h.aimToggle

	if aiming:
		gd.isAiming = true
		var parent = h.get_parent()
		if parent.activeOptic:
			h.targetPosition = Vector3(0.0, 0.0 - parent.aimOffset, data.aimPosition.z)
		else:
			h.targetPosition = data.aimPosition
		h.targetRotation = data.aimRotation

		if gd.isScoped && !gd.PIP:
			h.targetPosition -= Vector3(0.0, 0.0, 0.1)
	else:
		gd.isAiming = false
		if gd.weaponPosition == 2:
			h.targetPosition = data.highPosition
			h.targetRotation = data.highRotation
		elif gd.weaponPosition == 1:
			h.targetPosition = data.lowPosition
			h.targetRotation = data.lowRotation


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
	node.laser.show()
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
