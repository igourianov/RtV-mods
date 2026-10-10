extends RefCounted

var _lib
var _battery


func _init(lib, battery) -> void:
	_lib = lib
	_battery = battery


func on_value() -> int:
	_lib.skip_super()
	var item = _lib._caller
	var slotData: SlotData = item.slotData
	var value: int = item._rtv_vanilla_Value()

	# Vanilla exempts all Electronics from condition pricing.
	# A device is priced as itself plus one full battery, so a battery and a device both lose the same amount for the charge they are missing.
	if slotData.itemData.file == _battery.data.file || _battery.powers(slotData.itemData):
		# A draining device can end a frame slightly below 0.
		var missing: float = 1.0 - clampf(slotData.condition, 0.0, 100.0) * 0.01
		value -= roundi(_battery.data.value * missing)

	return value
