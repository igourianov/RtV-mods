extends Node

const _PREFIX = "[likhos-tacmed]"

#@onready var character = $"/root/Map/Core/Controller/Character"

var _lib


func _init(lib) -> void:
	_lib = lib


func on_use(targetItem, targetGrid) -> void:
	var itemData = targetItem.slotData.itemData
	if itemData.type == "Medical" && itemData.showCondition:
		print(_PREFIX, "custom heal logic")
		_lib.skip_super()
		return

func _input(ev):
	if ev is InputEventKey && ev.pressed && ev.ctrl_pressed && ev.shift_pressed && ev.keycode == KEY_O:
		print(_PREFIX, "hurt myself")
		var character = _lib._caller.get_node("../../Controller/Character")
		var gameData = character.gameData
		if character:
			character.Fracture(true)
			character.Bleeding(true)
			gameData.impact = true
			gameData.damage = true
			gameData.health -= 20.0
			
		
		