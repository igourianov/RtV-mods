extends RefCounted

var _lib
var _battery


func _init(lib, battery) -> void:
	_lib = lib
	_battery = battery


func on_update_post(slotData: SlotData) -> void:
	if !_battery.is_removable(slotData):
		return

	# Vanilla shows Unload only for magazines and weapons, so it is free for devices.
	var context = _lib._caller
	context.unloadButton.text = "Remove (" + _battery.data.display + ")"
	context.unloadButton.show()

	# Vanilla Update sized and placed the panel before this button was shown.
	var mouse: Vector2 = context.get_global_mouse_position()
	context.panel.size = Vector2(80.0, 0.0)
	context.panel.global_position = mouse - Vector2(0, context.panel.size.y)
	context.centerPosition = mouse - Vector2(-context.panel.size.x / 2, context.panel.size.y / 2)
