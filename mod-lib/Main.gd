extends Node


var _lib
var _hooks: Array[int] 
var _printer

func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		_printer.warning("RTVModLib not available")
		return

	await _lib.frameworks_ready
	_hooks = []

	setup(_lib)

	var registered = _hooks.filter(func(id): return id > -1)
	if registered.size() == _hooks.size():
		_printer.debug("all hooks registered successfully")
		return

	_printer.warning("mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)

func setup(lib):
	pass

func register_hook(hookName: String, callback: Callable):
	var id = _lib.hook(hookName, callback)
	if id != -1:
		_printer.debug("hook(%s):%s registered" % [hookName, id])
	else:
		_printer.warning("hook(%s) failed" % hookName)
	return id
