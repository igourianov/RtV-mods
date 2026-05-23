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
	if !caller.itemDragged || !caller.canCombine: return
	if !_is_wrk(caller.hoverItem) || !_is_weapon(caller.itemDragged): return
	_combine(caller, caller.hoverItem, caller.itemDragged)


func _combine(caller, wrkItem, weaponItem) -> void:
	if wrkItem.slotData.condition <= 0 || weaponItem.slotData.condition >= 100:
		caller.Return(weaponItem)
		caller.Reset()
		caller.PlayError()
		return

	caller.Return(weaponItem)
	caller.PlayStack()
	caller.Reset()

	var wrkGrid = wrkItem.get_parent()

	await _use_anim(caller, wrkItem, REPAIR_TIME)

	if gameData.isDead: return

	var repairAmount = min(100.0 - weaponItem.slotData.condition, wrkItem.slotData.condition)
	weaponItem.slotData.condition += repairAmount
	wrkItem.slotData.condition -= repairAmount

	weaponItem.UpdateDetails()
	wrkItem.UpdateDetails()

	if wrkItem.slotData.condition <= 0:
		Out.debug("WRK depleted, consuming")
		if wrkGrid && wrkGrid.has_method("Pick"):
			wrkGrid.Pick(wrkItem)
		wrkItem.queue_free()


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


func _is_wrk(item) -> bool:
	return item && item.slotData && item.slotData.itemData && item.slotData.itemData.file == WRK_FILE


func _is_weapon(item) -> bool:
	return item && item.slotData && item.slotData.itemData && item.slotData.itemData.type == "Weapon"
