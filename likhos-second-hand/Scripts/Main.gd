extends Node

const _PREFIX = "[likho-second-hand]"
const Patches = preload("res://mods/likhos-second-hand/Scripts/Patches.gd")
const Hooks = preload("res://mods/likhos-second-hand/Scripts/Hooks.gd")

var _lib
var _hooks


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	Patches.apply(_lib)

	if _lib._is_ready:
		_register_hooks()
	else:
		_lib.frameworks_ready.connect(func(): _register_hooks())


func _register_hooks() -> void:
	_hooks = Hooks.new(_lib)
	var pre_id: int = _lib.hook("item-updatesprite-pre", _hooks.on_update_sprite_pre)
	var post_id: int = _lib.hook("item-updatesprite-post", _hooks.on_update_sprite_post)
	if pre_id == -1:
		push_warning(_PREFIX, "hook(item-updatesprite-pre) failed")
	else:
		print(_PREFIX, "hook(item-updatesprite-pre):", pre_id, " registered")
	if post_id == -1:
		push_warning(_PREFIX, "hook(item-updatesprite-post) failed")
	else:
		print(_PREFIX, "hook(item-updatesprite-post):", post_id, " registered")
