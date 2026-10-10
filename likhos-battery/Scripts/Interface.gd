extends RefCounted

var _lib
var _battery
var gameData := preload("res://Resources/GameData.tres")


func _init(lib, battery) -> void:
	_lib = lib
	_battery = battery


func on_charge(targetItem: Item, sourceItem: Item) -> void:
	_lib.skip_super()
	_charge(_lib._caller, targetItem, sourceItem) # no await deliberate


func _charge(iface: Node, device: Item, battery: Item) -> void:
	var charge: float = battery.slotData.condition
	var previous: float = device.slotData.condition

	gameData.isOccupied = true

	# Vanilla Combine resets the drag state as soon as this yields, so the battery goes back to where it was dragged from now.
	# It stays there untouched until the progress completes.
	var grid: Grid = iface.returnGrid
	iface.Return(battery)

	var prog = iface.progress.instantiate()
	iface.add_child(prog)
	prog.global_position = device.global_position
	prog.size = device.size

	prog.Use(2.0)
	iface.activeProgress = prog

	await prog.completed
	if gameData.isDead: return

	if previous > 0:
		battery.slotData.condition = previous
		battery.UpdateDetails()
	else:
		grid.Pick(battery)
		battery.queue_free()

	device.slotData.condition = charge
	device.UpdateDetails()
	iface.PlayAttach()

	prog.queue_free()
	iface.activeProgress = null
	gameData.isOccupied = false
	iface.Reset()


func on_context_unload() -> void:
	var iface = _lib._caller
	var device = iface.contextItem
	if !is_instance_valid(device) || !_battery.is_removable(device.slotData):
		return

	_lib.skip_super()

	var slotData := SlotData.new()
	slotData.itemData = _battery.data
	slotData.condition = device.slotData.condition
	device.slotData.condition = 0.0
	device.UpdateDetails()

	# An equipped device has no grid. Its battery goes to the inventory, as in vanilla ContextRemove.
	iface.Create(slotData, iface.contextGrid if iface.contextGrid else iface.inventoryGrid, true)
	iface.HideContext()
	iface.PlayAttach()
