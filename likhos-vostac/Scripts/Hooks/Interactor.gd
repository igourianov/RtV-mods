extends RefCounted

var gameData := preload("res://Resources/GameData.tres")

var _lib: Variant


func _init(lib) -> void:
	_lib = lib


func on_physics_process_pre(_delta: float) -> void:
	# BUGFIX: prevent interaction while in Ammo Check
	if gameData.isChecking:
		gameData.interaction = false
		gameData.transition = false
	# BUGFIX: clear stale transition prompt when the raycast early-returns
	elif gameData.freeze || gameData.isReloading || gameData.isInserting || gameData.isInspecting || gameData.isPlacing || gameData.isOccupied:
		gameData.transition = false
