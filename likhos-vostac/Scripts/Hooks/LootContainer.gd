extends RefCounted

const Config := preload("../Config.gd")

var config := Config.instance
var gameData := preload("res://Resources/GameData.tres")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_tooltip_post() -> void:
	var container := _lib._caller as LootContainer
	# a locked container keeps its [Locked] prompt whatever it holds
	if !container || !config.hide_empty_container_prompt || gameData.shelter || container.locked:
		return

	var contents: Array[SlotData] = container.storage if container.storaged else container.loot
	if contents.is_empty():
		# Crosshair hides the prompt on an empty text, the interaction itself stays available
		gameData.tooltip = ""
