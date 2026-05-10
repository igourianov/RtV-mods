
const Out = preload("../Lib/Out.gd")
const FlashlightDriver = preload("./FlashlightDriver.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_physics_process(delta: float) -> void:
	_lib.skip_super()
	var caller = _lib._caller

	caller.ResetCheck()
	if !caller.gameData.freeze && caller.gameData.flashlight:
		caller.Consumption(delta)

	if !caller.has_node("FlashlightDriver"):
		var driver = FlashlightDriver.new()
		driver.name = "FlashlightDriver"
		caller.add_child(driver)
		Out.debug("flashlight input driver attached to", caller)
