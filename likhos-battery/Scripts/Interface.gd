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
	gameData.isOccupied = true

	# Vanilla Combine resets the drag state as soon as this yields, so the battery goes back to where it was dragged from now.
	var grid: Grid = iface.returnGrid
	iface.Return(battery)

	var prog = iface.progress.instantiate()
	iface.add_child(prog)
	prog.global_position = device.global_position
	prog.size = device.size

	prog.Use(2.0)
	iface.activeProgress = prog

	await prog.completed
	# Same guard as vanilla Charge. Vanilla has no cancel path today, so this only covers one being added.
	if gameData.isDead || !iface.activeProgress: return

	# Read only now: a switched-on device keeps draining while the progress runs.
	var charge: float = battery.slotData.condition
	var previous: float = device.slotData.condition
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


func on_context_remove(nestedIndex: int) -> void:
	var iface = _lib._caller
	var device = iface.contextItem
	# Only the button one past the nested items is the battery entry. Vanilla owns the indexes below it.
	if !is_instance_valid(device) || nestedIndex != device.slotData.nested.size():
		return

	# Vanilla would index past the nested items, so it never runs for this button.
	_lib.skip_super()

	# A switched-on device can drain to 0 while the menu is open.
	if !_battery.is_removable(device.slotData):
		iface.HideContext()
		iface.Reset()
		iface.PlayError()
		return

	var slotData := SlotData.new()
	slotData.itemData = _battery.data
	slotData.condition = device.slotData.condition
	device.slotData.condition = 0.0
	device.UpdateDetails()

	# An equipped device has no grid. Vanilla ContextRemove falls back to the inventory the same way.
	iface.Create(slotData, iface.contextGrid if iface.contextGrid else iface.inventoryGrid, true)
	iface.HideContext()
	iface.PlayAttach()
