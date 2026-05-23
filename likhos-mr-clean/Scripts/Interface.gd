const Out = preload("../Lib/Out.gd")

const WRK_FILE := "Weapon_Repair_Kit"
const REPAIR_TIME := 10.0

const audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
const craftAudio = preload("res://Audio/Crafting/Craft_Metal.tres")

var _lib
var gameData = preload("res://Resources/GameData.tres")


func _init(lib) -> void:
	_lib = lib


func on_release_pre() -> void:
	var caller = _lib._caller
	if !caller.itemDragged || !caller.canCombine:
		return
	var target = caller.hoverItem.slotData if caller.hoverItem else null
	if !target || !target.itemData || target.itemData.file != WRK_FILE:
		return
	var source = caller.itemDragged.slotData
	if !source || !source.itemData || source.itemData.type != "Weapon":
		return

	_combine(caller, caller.hoverItem, caller.itemDragged) # no await deliberate
	caller.Return(caller.itemDragged)
	caller.Reset()


func _combine(caller, kitItem, weaponItem) -> void:
	var kitSlotData = kitItem.slotData
	var weaponSlotData = weaponItem.slotData

	if kitSlotData.condition <= 0 || weaponSlotData.condition >= 100:
		caller.PlayError()
		return

	await _use_anim(caller, kitItem, REPAIR_TIME)

	if gameData.isDead: return

	var repairAmount = min(100.0 - weaponSlotData.condition, kitSlotData.condition)
	weaponSlotData.condition += repairAmount
	kitSlotData.condition -= repairAmount

	weaponItem.UpdateDetails()
	kitItem.UpdateDetails()

	if kitSlotData.condition <= 0:
		Out.debug("WRK depleted, consuming")
		var grid = kitItem.get_parent()
		if grid && grid.has_method("Pick"):
			grid.Pick(kitItem)
		kitItem.queue_free()


func _use_anim(caller, targetItem, timer: float):
	gameData.isOccupied = true
	var prog = caller.progress.instantiate()
	caller.add_child(prog)

	prog.global_position = targetItem.global_position
	prog.size = targetItem.size
	prog.audioCycle = 100000.0

	var audio = audioInstance2D.instantiate()
	caller.add_child(audio)
	audio.PlayInstance(craftAudio)

	prog.Use(timer)

	await prog.completed
	prog.queue_free()
	gameData.isOccupied = false
