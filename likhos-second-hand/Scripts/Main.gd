extends Node

const _PREFIX = "[likho-second-hand]"
const Patches = preload("res://mods/likhos-second-hand/Scripts/Patches.gd")
const Item = preload("res://mods/likhos-second-hand/Scripts/Item.gd")

var _lib
var _item


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	Patches.apply(_lib)

	if _lib._is_ready:
		_register_hooks(_lib)
	else:
		_lib.frameworks_ready.connect(func(): _register_hooks(_lib))


func _register_hooks(lib) -> void:
	_item = Item.new(lib)
	var hooks: Array[int] = [
		_register_hook(lib, "item-updatesprite-pre", _item.on_update_sprite_pre),
		_register_hook(lib, "item-updatesprite-post", _item.on_update_sprite_post)
	]

	var registered = hooks.filter(func(id): return id > -1)
	if registered.size() == hooks.size():
		print(_PREFIX, "all hooks registered successfully")
		return

	push_warning(_PREFIX, "mod registration failed, rolling back")
	for id in registered:
		lib.unhook(id)


func _register_hook(lib, hookName: String, callback: Callable):
	var id = lib.hook(hookName, callback)
	if id != -1:
		print(_PREFIX, "hook(%s):%s registered" % [hookName, id])
	else:
		push_warning(_PREFIX, "hook(%s) failed" % hookName)
	return id
	