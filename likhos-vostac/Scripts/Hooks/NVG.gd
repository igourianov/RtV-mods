
const Out := preload("../../Lib/Out.gd")

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
		var driver := NVGDriver.new()
		driver.name = "NVGDriver"
		caller.add_child(driver)
		Out.debug("nvg input driver attached to", caller)


class NVGDriver extends Node:
	const HOLD_THRESHOLD := 0.25
	const ModConfig := preload("../ModConfig.gd")
	const AttachmentClickPlayer := preload("../Audio/AttachmentClickPlayer.gd")

	var gameData = preload("res://Resources/GameData.tres")
	var _hold_elapsed := 0.0
	var _click_sound: AttachmentClickPlayer


	func _init() -> void:
		_click_sound = AttachmentClickPlayer.new()
		add_child(_click_sound)


	func _physics_process(delta: float):
		if gameData.NVG:
			_hold_elapsed += delta


	func _input(evt: InputEvent) -> void:
		var parent = get_parent()
		var slot: Node = parent.NVGSlot
		var device = slot.get_child(0) if slot && slot.get_child_count() else null

		if !device || gameData.freeze || ModConfig.binoculars_active:
			return

		if evt.is_action_pressed("nvg", false):
			_click_sound.click_in()
			if !gameData.NVG && device.slotData.condition > 0:
				parent.Activate()
				_hold_elapsed = 0.0
		elif evt.is_action_released("nvg"):
			_click_sound.click_out()
			if gameData.NVG && _hold_elapsed > HOLD_THRESHOLD:
				parent.Deactivate()
