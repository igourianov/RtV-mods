extends "./WeaponRig_Base.gd"


func _input(event) -> void:
	if is_engine_busy() || gameData.isInserting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var rig = owner
	if rig == null:
		return

	if event.is_action_pressed("inspect"):
		_inspect_toggle()
		return

	if !gameData.isInspecting:
		return

	if event.is_action_pressed("canted"):
		if gameData.inspectPosition == 1:
			rig.PlayInspectRotate()
			rig.animator["parameters/conditions/Inspect_Front"] = false
			rig.animator["parameters/conditions/Inspect_Back"] = true
			gameData.inspectPosition = 2
		elif gameData.inspectPosition == 2:
			rig.PlayInspectRotate()
			rig.animator["parameters/conditions/Inspect_Front"] = true
			rig.animator["parameters/conditions/Inspect_Back"] = false
			gameData.inspectPosition = 1
		return

	var optic = rig.activeOptic
	var zoomIn = event.is_action_pressed("optic_zoom_in", true)
	var zoomOut = event.is_action_pressed("optic_zoom_out", true)

	if (zoomIn || zoomOut) && optic && optic.railMovement:
		if zoomIn && optic.position.z < optic.maxPosition:
			optic.position.z += 0.01
			rig.slotData.position += 0.01
			rig.PlayRailMove()
		elif zoomOut && optic.position.z > optic.minPosition:
			optic.position.z -= 0.01
			rig.slotData.position -= 0.01
			rig.PlayRailMove()
		return


func _inspect_toggle():
	var rig = owner
	gameData.isInspecting = !gameData.isInspecting
	gameData.isFiring = false

	if gameData.isInspecting:
		gameData.inspectPosition = 1
		rig.PlayInspectStart()
		rig.animator["parameters/conditions/Inspect_Front"] = true
		rig.animator["parameters/conditions/Inspect_Idle"] = false
		rig.UpdateBullets()
		rig.UpdateHUD()
		Out.protip("inspect-rotate", "Press [%s] to rotate or [%s] / [%s] to move optic" % [
			Inputs.get_binding("canted"),
			Inputs.get_binding("optic_zoom_in"),
			Inputs.get_binding("optic_zoom_out")
		])
	elif gameData.inspectPosition == 1:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Front"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
	elif gameData.inspectPosition == 2:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Back"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
		gameData.inspectPosition = 1
