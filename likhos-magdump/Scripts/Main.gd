extends "../Lib/Main.gd"

const CompatTable = preload("./CompatTable.gd")
const Interface = preload("./Interface.gd")
const RigVisual = preload("./RigVisual.gd")

var _interface
var _rig_visual


func setup(lib) -> void:
	CompatTable.apply(lib)

	_rig_visual = RigVisual.new(lib, CompatTable.COMPAT, CompatTable.MAG_PICKUPS)
	_interface = Interface.new(lib, _rig_visual)

	register_hook("interface-getmagazine", _interface.on_get_magazine)
	register_hook("weaponrig-_ready-post", _rig_visual.on_ready_post)
	register_hook("rigmanager-updaterig-pre", _rig_visual.on_update_rig_pre)
