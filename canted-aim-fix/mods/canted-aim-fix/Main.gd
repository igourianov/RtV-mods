extends Node

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
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		return

	if collision.is_colliding():
		h.targetPosition = data.collisionPosition
		h.targetRotation = data.collisionRotation
		gd.isColliding = true
		gd.isAiming = false
		gd.isCanted = false
		return
	else:
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

	if gd.isRunning || gd.isChecking || (gd.isReloading && data.weaponAction != "Manual"):
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

	if Input.is_action_just_pressed("canted"):
		h.canted = !h.canted

	if h.canted:
		gd.isCanted = true
		gd.isAiming = false
		h.targetPosition = data.cantedPosition
		h.targetRotation = data.cantedRotation
		return

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
