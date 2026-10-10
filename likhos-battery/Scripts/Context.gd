extends RefCounted

var _lib
var _battery


func _init(lib, battery) -> void:
	_lib = lib
	_battery = battery


func on_update_post(slotData: SlotData) -> void:
	if !_battery.is_removable(slotData):
		return

	# Vanilla gives the nested items the first Remove buttons, in order. The battery takes the next one, which keeps it at the bottom of the menu with them.
	var context = _lib._caller
	var button: Button = context.buttons.get_node_or_null("Remove_" + str(slotData.nested.size()))
	if !is_instance_valid(button):
		return

	button.text = "Remove (" + _battery.data.display + ")"
	button.show()

	# Vanilla Update sized and placed the panel before this button was shown.
	var mouse: Vector2 = context.get_global_mouse_position()
	context.panel.size = Vector2(80.0, 0.0)
	context.panel.global_position = mouse - Vector2(0, context.panel.size.y)
	context.centerPosition = mouse - Vector2(-context.panel.size.x / 2, context.panel.size.y / 2)
