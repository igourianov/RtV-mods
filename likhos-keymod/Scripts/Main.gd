extends Node

const _PREFIX = "[likho-keymod]"
var _lib


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	apply(_lib)


static func apply(lib) -> void:
	_patch_key(lib, "Key_Cellar", { "doctor": true, "value": 5000 })
	_patch_key(lib, "Key_Gymnasium", { "gunsmith": true , "value": 5000})
	_patch_key(lib, "Key_Tunnel", { "generalist": true, "value": 5000 })

static func _patch_key(lib, key: String, fields: Dictionary):
	if lib.patch(lib.Registry.ITEMS, key, fields):
		print(_PREFIX, "patched key", key, " with ", fields)
	else:
		push_warning(_PREFIX, "Key patch failed for ", key)
