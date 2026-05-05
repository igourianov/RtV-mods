extends Node

const _PREFIX = "[likhos]"

var _lib
var _hooks: Array[int] 

func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	await _lib.frameworks_ready
	_hooks = []

	setup(_lib)

	var registered = _hooks.filter(func(id): return id > -1)
	if registered.size() == _hooks.size():
		print(_PREFIX, "all hooks registered successfully")
		return

	push_warning(_PREFIX, "mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)

func setup(lib):
	pass

func register_hook(hookName: String, callback: Callable):
	var id = _lib.hook(hookName, callback)
	if id != -1:
		print(_PREFIX, "hook(%s):%s registered" % [hookName, id])
	else:
		push_warning(_PREFIX, "hook(%s) failed" % hookName)
	return id
