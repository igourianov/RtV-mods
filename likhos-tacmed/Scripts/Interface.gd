extends Node

const Out = preload("../Lib/Out.gd")
const INTERFACE_NODE := "/root/Map/Core/UI/Interface"
const CHARACTER_NODE := "/root/Map/Core/Controller/Character"

const TACMED = {
	"IFAK": {
		"healTime": 3.0,
		"replenishTime": 1.0,
		"replenishDefault": 10.0
	},
	"AFAK": {
		"healTime": 5.0
	}
}

const CONDITIONS = [
	"bleeding",
	"fracture",
	"burn",
	"frostbite",
	"insanity",
	"poisoning",
	"rupture",
	"headshot"
]

var _lib
var gameData = preload("res://Resources/GameData.tres")



func _init(lib) -> void:
	_lib = lib


func on_use(targetItem, targetGrid) -> void:
	var itemData = targetItem.slotData.itemData
	var extraData = TACMED[itemData.file]
	if extraData:
		Out.debug("custom heal logic")
		_use(_lib._caller, get_node(CHARACTER_NODE), targetItem, extraData)
		_lib.skip_super()


func _use(iface, character, targetItem, extraData) -> void:
	var slotData = targetItem.slotData
	if !slotData.condition || gameData.health >= 100:
		iface.PlayError()
		return

	iface.PlayUse(slotData.itemData)

	await _use_anim(iface, targetItem, extraData.healTime)

	if gameData.isDead: return

	var totalHeal = slotData.itemData.health
	var healRate = totalHeal / 100.0
	var heal = min(slotData.condition * healRate, 100.0 - gameData.health)
	slotData.condition -= round(heal / healRate)
	slotData.itemData.health = heal
	character.Consume(slotData.itemData)
	slotData.itemData.health = totalHeal
	targetItem.UpdateDetails()

	iface.Reset()


func _use_anim(caller, targetItem, timer: float):
	gameData.isOccupied = true
	var prog = caller.progress.instantiate()
	caller.add_child(prog)

	prog.global_position = targetItem.global_position
	prog.size = targetItem.size
	prog.audioCycle = 100000.0 # effectivelly disable AmmoLoad audio

	prog.Use(timer) # start the timer

	await prog.completed
	prog.queue_free()
	gameData.isOccupied = false


func on_release_pre() -> void:
	var caller = _lib._caller
	var sourceItem = caller.itemDragged
	var targetItem = caller.hoverItem
	if !caller.canCombine || !sourceItem || !targetItem || !sourceItem.slotData || !targetItem.slotData:
		return

	var extraData = TACMED[targetItem.slotData.itemData.file]
	if !extraData || !extraData.replenishTime:
		return

	Out.debug("custom heal item reload")
	_combine(caller, targetItem, sourceItem, extraData) # no await deliberate


func _combine(caller, targetItem, sourceItem, extraData):
	if targetItem.slotData.condition >= 100.0:
		caller.Return(sourceItem)
		caller.Reset()
		caller.PlayError()
		return

	caller.Reset()
	caller.PlayStack()
	sourceItem.hide()

	await _use_anim(caller, targetItem, extraData.replenishTime)

	if gameData.isDead: return

	var replenish = sourceItem.slotData.itemData.health
	if !replenish:
		replenish = extraData.replenishDefault

	targetItem.slotData.condition = min(targetItem.slotData.condition + replenish, 100.0)
	targetItem.UpdateDetails()

	sourceItem.queue_free()


func _input(ev):
	if ev.is_action_pressed("tacmed"):
		Out.debug("action pressed: tacmed")
		_tacmed_heal(get_node(INTERFACE_NODE), get_node(CHARACTER_NODE))
		return

	if ev.is_action_pressed("hurt_myself"):
		_hurt_myself(get_node(CHARACTER_NODE), true)
	elif ev.is_action_pressed("hurt_myself_more"):
		_hurt_myself(get_node(CHARACTER_NODE), false)
		

func _hurt_myself(caller, bleedOnly: bool):
	if bleedOnly:
		Out.debug("I hurt myself, today...")
		caller.Bleeding(true)
	else:
		Out.debug("To see if I still feel...")
		match randi_range(1,4):
			1: caller.Fracture(true)
			2: caller.Rupture(true)
			3: caller.Burn(true)
			4: caller.Headshot(true)

	gameData.impact = true
	gameData.damage = true
	gameData.health -= randf_range(10.0, 20.0)


func _tacmed_heal(iface, character):
	if gameData.isOccupied:
		return
	
	var tacmedItems = iface.inventoryGrid.get_children().filter(func(i):
		return TACMED[i.slotData.itemData.file] && i.slotData.condition > 0
	)
	Out.debug("usable tacmed items:", tacmedItems.size())
	if !tacmedItems.size():
		iface.PlayError()
		return

	if tacmedItems.size() > 1:
		var sortable = tacmedItems.map(func(i):
			return {
				"item": i, # original item ref
				"conditions_remove": _cond_heal_count(i),
				"waste": max(0.0, i.slotData.itemData.health * i.slotData.condition / 100.0 - (100.0 - gameData.health)),
				"condition": i.slotData.condition,
				"value": i.slotData.itemData.value * i.slotData.condition / 100.0
			}
		)
	
		# ORDER BY [number of conditions would be removed] DESC, [heal waste] ASC, [condition] ASC, [adjusted value] ASC
		sortable.sort_custom(func(a, b):
			if a.conditions_remove > b.conditions_remove:
				return true
			elif a.conditions_remove < b.conditions_remove:
				return false
			elif a.waste < b.waste:
				return true
			elif a.waste > b.waste:
				return false
			elif a.condition < b.condition:
				return true
			elif a.condition > b.condition:
				return false
			return a.value < b.value
		)
		tacmedItems = sortable.map(func(i): return i.item)

		Out.debug("prioritized tacmed:", tacmedItems.map(func(i): return {
			"file": i.slotData.itemData.file,
			"condition": i.slotData.condition
		}))
	
	var tacmedToUse = tacmedItems[0]
	_use(iface, character, tacmedToUse, TACMED[tacmedToUse.slotData.itemData.file])


func _cond_heal_count(item) -> int:
	var heal: int = 0
	for cond in CONDITIONS:
		if gameData[cond] && item.slotData.itemData[cond]:
			heal += 1
	return heal 