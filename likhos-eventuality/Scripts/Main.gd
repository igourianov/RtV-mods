extends Node

const _EventSystem = preload("res://mods/likhos-eventuality/Scripts/EventSystem.gd")
const _Police = preload("res://mods/likhos-eventuality/Scripts/Police.gd")
const _ModConfig = preload("res://mods/likhos-eventuality/Scripts/ModConfig.gd")

var _event_system
var _police
var _config


func _ready() -> void:
	_config = _ModConfig.new()
	if not Engine.has_meta("RTVModLib"):
		push_error("[likho] RTVModLib meta not available")
		return
	var lib = Engine.get_meta("RTVModLib")
	if lib._is_ready:
		_init_hooks(lib)
	else:
		lib.frameworks_ready.connect(func():
			_init_hooks(lib)
		)


func _init_hooks(lib):
	_event_system = _EventSystem.new(lib, _config)
	_police = _Police.new(lib)

	var hooks: Array[int] = [
		_register_hook(lib, "eventsystem-activatedynamicevent", _event_system.on_activate_dynamic_event),
		_register_hook(lib, "eventsystem-fighterjet-post", _event_system.on_fighter_jet_post),
		_register_hook(lib, "police-_ready-post", _police.on_ready_post),
		_register_hook(lib, "police-states-post", _police.on_states_post)
	]

	var registered = hooks.filter(func(id): return id > -1)
	if registered.size() == hooks.size():
		print("[likho] all hooks registered successfully")
		return

	print("[likho] mod registration failed, rolling back")
	for id in registered:
		lib.unhook(id)


func _register_hook(lib, hookName: String, callback: Callable):
	var id = lib.hook(hookName, callback)
	if id != -1:
		print("[likho] hook(%s):%s registered" % [hookName, id])
	else:
		push_error("[likho] hook(%s) failed" % hookName)
	return id
