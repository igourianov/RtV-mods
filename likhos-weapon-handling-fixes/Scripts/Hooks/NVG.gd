
const Out = preload("../../Lib/Out.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_physics_process(delta: float) -> void:
	_lib.skip_super()
	var caller = _lib._caller

	caller.ResetCheck()
	if !caller.gameData.freeze && caller.gameData.NVG:
		caller.Consumption(delta)

	if !caller.has_node("NVGDriver"):
		var driver = NVGDriver.new()
		driver.name = "NVGDriver"
		caller.add_child(driver)
		Out.debug("nvg input driver attached to", caller)


class NVGDriver extends Node:
	const HOLD_THRESHOLD = 0.25
	const ModConfig = preload("../ModConfig.gd")

	var gameData = preload("res://Resources/GameData.tres")
	var _hold_elapsed := 0.0


	func _physics_process(delta: float):
		if gameData.NVG:
			_hold_elapsed += delta


	func _input(evt: InputEvent) -> void:
		var parent = get_parent()
		var slot = parent.NVGSlot
		var device = slot.get_child(0) if slot && slot.get_child_count() else null

		if !device:
			return

		if !gameData.NVG && !ModConfig.binoculars_active && evt.is_action_pressed("nvg", false) && !gameData.freeze:
			_hold_elapsed = 0.0
			parent.Activate()
			parent.NVGAudio()
		elif gameData.NVG && evt.is_action_released("nvg") && _hold_elapsed > HOLD_THRESHOLD:
			parent.Deactivate()
			parent.NVGAudio()
