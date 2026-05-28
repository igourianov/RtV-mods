extends RefCounted

var gameData = preload("res://Resources/GameData.tres")

var _lib


func _init(lib) -> void:
	_lib = lib

# BUGFIX: prevent interaction while in Ammo Check
func on_physics_process_pre(_delta) -> void:
	if gameData.isChecking:
		gameData.interaction = false
		gameData.transition = false
