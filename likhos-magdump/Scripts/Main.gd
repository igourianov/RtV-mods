extends Node

const _PREFIX = "[likho-magdump]"
const CompatTable = preload("res://mods/likhos-magdump/Scripts/CompatTable.gd")
const _Interface = preload("res://mods/likhos-magdump/Scripts/Interface.gd")

var _lib
var _interface


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	CompatTable.apply(_lib)

	if _lib._is_ready:
		_register_hooks()
	else:
		_lib.frameworks_ready.connect(func(): _register_hooks())


func _register_hooks() -> void:
	_interface = _Interface.new(_lib)

	var hooks: Array[int] = [
		_register_hook(_lib, "interface-getmagazine", _interface.on_get_magazine)
	]

	var registered = hooks.filter(func(id): return id > -1)
	if registered.size() == hooks.size():
		print(_PREFIX, "all hooks registered successfully")
		return

	push_warning(_PREFIX, "mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)


func _register_hook(lib, hookName: String, callback: Callable):
	var id = lib.hook(hookName, callback)
	if id != -1:
		print(_PREFIX, "hook(%s):%s registered" % [hookName, id])
	else:
		push_warning(_PREFIX, "hook(%s) failed" % hookName)
	return id
