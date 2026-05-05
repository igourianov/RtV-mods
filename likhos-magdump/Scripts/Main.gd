extends "../Lib/Main.gd"

const CompatTable = preload("./CompatTable.gd")
const Interface = preload("./Interface.gd")

var _interface


func setup(lib) -> void:
	CompatTable.apply(lib)

	_interface = Interface.new(lib)
	register_hook("interface-getmagazine", _interface.on_get_magazine)
