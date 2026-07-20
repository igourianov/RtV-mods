extends "../Lib/Main.gd"

const CompatTable := preload("./CompatTable.gd")
const Interface := preload("./Interface.gd")
const RigVisual := preload("./RigVisual.gd")
const Pickup := preload("./Pickup.gd")

var _interface
var _rig_visual
var _pickup


func setup(lib) -> void:
	CompatTable.apply(lib)

	_rig_visual = RigVisual.new(lib, CompatTable.COMPAT, CompatTable.MAG_PICKUPS)
	_interface = Interface.new(lib, _rig_visual)
	_pickup = Pickup.new(lib, CompatTable.COMPAT, CompatTable.MAG_STATICS)

	register_hook("interface-getmagazine", _interface.on_get_magazine)
	register_hook("weaponrig-_ready-post", _rig_visual.on_ready_post)
	register_hook("rigmanager-updaterig-pre", _rig_visual.on_update_rig_pre)
	register_hook("pickup-_ready-post", _pickup.on_ready_post)
