extends RefCounted

var _lib
var _battery


func _init(lib, battery) -> void:
	_lib = lib
	_battery = battery


func on_value() -> int:
	_lib.skip_super()
	var item = _lib._caller
	var value: int = item._rtv_vanilla_Value()

	# Vanilla exempts all Electronics from condition pricing. Only the battery itself is priced by charge, devices keep their value.
	if item.slotData.itemData.file == _battery.data.file:
		value = int(value * item.slotData.condition * 0.01)

	return value
