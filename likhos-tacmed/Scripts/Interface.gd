extends Node

const _PREFIX = "[likhos-tacmed]"

const MEDICAL = {
	"IFAK": {
		"healTime": 3.0,
		"replenishTime": 1.0,
		"replenishDefault": 10.0
	}
}

var _lib


func _init(lib) -> void:
	_lib = lib


func on_use(targetItem, targetGrid) -> void:
	var itemData = targetItem.slotData.itemData
	var extraData = MEDICAL[itemData.file]
	if extraData:
		print(_PREFIX, "custom heal logic")
		_use(_lib._caller, _lib._caller.get_node("../../Controller/Character"), targetItem, targetGrid, extraData)
		_lib.skip_super()


func _use(caller, character, targetItem, targetGrid, extraData) -> void:
	var slotData = targetItem.slotData
	if !slotData.condition || caller.gameData.health >= 100:
		caller.PlayError()
		return

	caller.gameData.isOccupied = true
	caller.PlayUse(slotData.itemData)

	var newProgress = caller.progress.instantiate()
	caller.add_child(newProgress)
	newProgress.global_position = targetItem.global_position
	newProgress.size = targetItem.size
	newProgress.Use(extraData.healTime)

	await newProgress.completed
	newProgress.queue_free()

	if caller.gameData.isDead: return

	var totalHeal = slotData.itemData.health
	var healRate = totalHeal / 100.0
	var heal = min(slotData.condition * healRate, 100.0 - caller.gameData.health)
	slotData.condition -= round(heal / healRate)
	slotData.itemData.health = heal
	character.Consume(slotData.itemData)
	slotData.itemData.health = totalHeal
	targetItem.UpdateDetails()

	caller.gameData.isOccupied = false
	caller.Reset()


func on_hover_post():
	var caller = _lib._caller
	if caller.itemDragged && caller.hoverItem:
		_hover_post(caller, caller.hoverItem, caller.itemDragged)


func _hover_post(caller, targetItem, sourceItem):
	var targetItemData = targetItem.slotData.itemData
	var sourceItemData = sourceItem.slotData.itemData
	var extraData = MEDICAL[targetItemData.file]
	if extraData && targetItemData.compatible.any(func(i): return i.file == sourceItemData.file):
		caller.canCombine = true


func on_combine(targetItem):
	var caller = _lib._caller
	var itemData = targetItem.slotData.itemData
	var extraData = MEDICAL[itemData.file]
	if extraData && caller.canCombine:
		print(_PREFIX, "custom heal item reload")
		_combine(caller, targetItem, caller.itemDragged, extraData)
		_lib.skip_super()


func _combine(caller, targetItem, sourceItem, extraData):
	if targetItem.slotData.condition >= 100.0:
		caller.Return(sourceItem)
		caller.Reset()
		caller.PlayError()
		return

	var replenish = sourceItem.slotData.itemData.health
	if !replenish:
		replenish = extraData.replenishDefault

	targetItem.slotData.condition += replenish
	targetItem.slotData.condition = min(targetItem.slotData.condition, 100.0)
	targetItem.UpdateDetails()

	sourceItem.queue_free()

	#caller.PlayStack()
	caller.Reset()


func _input(ev):
	if ev is InputEventKey && ev.pressed && ev.ctrl_pressed && ev.shift_pressed && ev.keycode == KEY_O:
		print(_PREFIX, "I hurt myself, today...")
		var character = _lib._caller.get_node("../../Controller/Character")
		var gameData = character.gameData
		if character:
			#character.Fracture(true)
			character.Bleeding(true)
			gameData.impact = true
			gameData.damage = true
			gameData.health -= 20.0
			
		
		