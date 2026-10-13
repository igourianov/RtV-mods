extends RefCounted

const Config := preload("./Config.gd")
const BatteryUtil := preload("./BatteryUtil.gd")
const Flicker := preload("./Flicker.gd")

var config := Config.instance

var _lib
var _flicker := Flicker.new()
# Physics frame of the last flicker step, and whether that step was a dip.
var _step_frame: int
var _dip: bool


func _init(lib) -> void:
	_lib = lib


# Polls instead of owning the toggle: VosTac replaces Laser._input and also switches the laser on by itself.
func on_process_post(delta: float) -> void:
	var caller = _lib._caller

	# A rig holds a node for every laser it can mount and vanilla shows the attached one only.
	if !caller.visible || !caller.active:
		return

	if config.laser_power_draw == Config.LaserPowerDraw.DISABLED:
		# Nothing else shows the beam again when the setting changes in the middle of a dip.
		if _dip:
			_dip = false
			caller.laser.show()
		return

	var rig = caller.owner
	if !rig || !rig.slotData:
		return

	# The node is named after its item's file.
	var weapon: SlotData = rig.slotData
	var laser: ItemData
	for nested: ItemData in weapon.nested:
		if nested.file == caller.name:
			laser = nested
			break

	if !laser || !BatteryUtil.powers(laser):
		return

	var holder := BatteryUtil.attachment_holder(weapon, laser)
	if holder.condition > 0:
		holder.condition -= delta * BatteryUtil.drain_rate(laser.power)

	if holder.condition <= 0:
		caller.active = false
		caller.laser.hide()
		return

	var frame := Engine.get_physics_frames()
	if frame - _step_frame >= Flicker.STEP_FRAMES:
		_step_frame = frame
		_dip = _flicker.step(holder.condition)

	# Outside a dip this matches what the toggle left: an active laser is shown.
	caller.laser.visible = !_dip
