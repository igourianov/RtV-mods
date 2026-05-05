extends Node

const _PREFIX = "[likhos-tacmed]"
const Interface = preload("res://mods/likhos-tacmed/Scripts/Interface.gd")
const ItemData = preload("res://Scripts/ItemData.gd")

var _lib
var _interface


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	_patch_items()

	if _lib._is_ready:
		_register_hooks()
	else:
		_lib.frameworks_ready.connect(func(): _register_hooks())

	print(_PREFIX, "initialized")


func _register_hooks() -> void:
	_interface = Interface.new(_lib)
	add_child(_interface)

	var hooks: Array[int] = [
		_register_hook("interface-use", _interface.on_use),
		_register_hook("interface-combine", _interface.on_combine),
		_register_hook("interface-hover-post", _interface.on_hover_post)
	]

	var registered = hooks.filter(func(id): return id > -1)
	if registered.size() == hooks.size():
		print(_PREFIX, "all hooks registered successfully")
		return

	push_warning(_PREFIX, "mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)


func _register_hook(hookName: String, callback: Callable):
	var id = _lib.hook(hookName, callback)
	if id != -1:
		print(_PREFIX, "hook(%s):%s registered" % [hookName, id])
	else:
		push_warning(_PREFIX, "hook(%s) failed" % hookName)
	return id


func _patch_items():
	var compatible: Array[ItemData] = [
		_lib.get_entry(_lib.Registry.ITEMS, "Bandage"),
		_lib.get_entry(_lib.Registry.ITEMS, "Bandage_Improvised"),
		_lib.get_entry(_lib.Registry.ITEMS, "Painkillers"),
		_lib.get_entry(_lib.Registry.ITEMS, "Antibiotics"),
		_lib.get_entry(_lib.Registry.ITEMS, "Cold_Medicine"),
		_lib.get_entry(_lib.Registry.ITEMS, "Tourniquet"),
		_lib.get_entry(_lib.Registry.ITEMS, "Tourniquet_Improvised")
	]
	print(_PREFIX, "compatible: ", compatible.map(func(i): return i.file))
	_lib.patch(_lib.Registry.ITEMS, "IFAK", {
		"showCondition": true,
		"compatible": compatible,
		"value": 1000,
		"weight": 2.0,
		"health": 150.0,
		"fracture": false,
		"rupture": false,
		"headshot": false,
		"doctor": true
	})