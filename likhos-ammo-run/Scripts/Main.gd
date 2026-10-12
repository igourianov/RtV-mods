extends "../Lib/Main.gd"

# item path -> rounds to deliver in one stack
const DELIVER := {
	"res://Items/Ammo/Ammo_762x39/Ammo_762x39.tres": 300,
	"res://Items/Ammo/Ammo_223/Ammo_223.tres": 300,
}
# item path -> rounds received in one stack
const RECEIVE := {
	"res://Items/Ammo/Ammo_46x30/Ammo_46x30.tres": 150,
	"res://Items/Ammo/Ammo_9x39/Ammo_9x39.tres": 60,
}
# items sold by the Gunsmith: the ammo the task asks for in vanilla, plus VSS and MP7 magazines
const GUNSMITH_STOCK := ["Ammo_46x30", "Ammo_9x39", "Ammo_762x54R", "VSS_Magazine", "MP7_Magazine"]

# held for the whole session, so the trader loads this patched instance from the resource cache.
# The registry keys the patch by instance id and does not keep the task alive.
var _task: TaskData
# ItemData -> rounds
var _amounts := {}


func setup(lib) -> void:
	for file in GUNSMITH_STOCK:
		if !lib.patch(lib.Registry.ITEMS, file, {"gunsmith": true}):
			Out.warning("patch failed for %s" % file)

	_task = load("res://Traders/Gunsmith/Tasks/05_Ammo_Delivery.tres")
	if !lib.patch(lib.Registry.TRADER_TASKS, _task, {"deliver": _load_stacks(DELIVER), "receive": _load_stacks(RECEIVE)}):
		Out.warning("patch failed for %s" % _task.name)

	register_hook("task-initialize-post", _on_task_initialize_post)


# a task has no per-item amounts, so the rounds are kept aside for the slots
func _load_stacks(stacks: Dictionary) -> Array[ItemData]:
	var items: Array[ItemData] = []
	for path in stacks:
		var ammo: ItemData = load(path)
		items.append(ammo)
		_amounts[ammo] = stacks[path]
	return items


func _on_task_initialize_post(task: TaskData, _interface) -> void:
	if task != _task:
		return

	# vanilla sets every slot to defaultAmount (one box)
	var caller = _lib._caller
	for element in caller.inputGrid.get_children() + caller.outputGrid.get_children():
		# the placeholders Initialize has just freed are still in the tree
		if !element.is_queued_for_deletion():
			element.slotData.amount = _amounts[element.slotData.itemData]
			element.amount.text = str(element.slotData.amount)
