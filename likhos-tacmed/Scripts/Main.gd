extends Node

const _PREFIX = "[likhos-tacmed]"
const Interface = preload("res://mods/likhos-tacmed/Scripts/Interface.gd")

var _lib
var _interface


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	_lib.patch(_lib.Registry.ITEMS, "IFAK", {
		"showCondition": true,
		#"healConditionRate": 1.0,
		#"healTime": 3.0,
		"value": 1000,
		"weight": 2.0,
		"health": 0.0,
		"fracture": false,
		"rupture": false,
		"headshot": false,
		"doctor": true
	})

	if _lib._is_ready:
		_register_hooks()
	else:
		_lib.frameworks_ready.connect(func(): _register_hooks())

	print(_PREFIX, "initialized")



func _register_hooks() -> void:
	_interface = Interface.new(_lib)
	add_child(_interface)

	var use_hook = _lib.hook("interface-use", _interface.on_use)
	if use_hook != -1:
		print(_PREFIX, "hook(interface-use):%s registered" % use_hook)
	else:
		push_warning(_PREFIX, "hook(interface-use) failed")

