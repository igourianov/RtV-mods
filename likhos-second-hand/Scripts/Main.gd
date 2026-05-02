extends Node

const _PREFIX = "[likho-second-hand]"
const Patches = preload("res://mods/likhos-second-hand/Scripts/Patches.gd")

var _lib


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	Patches.apply(_lib)
