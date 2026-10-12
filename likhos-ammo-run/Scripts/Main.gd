extends "../Lib/Main.gd"

# item path -> rounds to deliver in one stack
const DELIVER := {
	"res://Items/Ammo/Ammo_762x39/Ammo_762x39.tres": 300,
	"res://Items/Ammo/Ammo_223/Ammo_223.tres": 300,
}
# item path -> boxes received
const RECEIVE := {
	"res://Items/Ammo/Ammo_46x30/Ammo_46x30.tres": 3,
	"res://Items/Ammo/Ammo_9x39/Ammo_9x39.tres": 3,
}
# the ammo the task asks for in vanilla, sold by the Gunsmith instead
const GUNSMITH_STOCK := ["Ammo_46x30", "Ammo_9x39", "Ammo_762x54R"]

# held for the whole session, so the trader loads this patched instance from the resource cache.
# The registry keys the patch by instance id and does not keep the task alive.
var _task: TaskData
# ItemData -> rounds
var _amounts := {}


func setup(lib) -> void:
	for file in GUNSMITH_STOCK:
		if !lib.patch(lib.Registry.ITEMS, file, {"gunsmith": true}):
			Out.warning("patch failed for %s" % file)

	var deliver: Array[ItemData] = []
	for path in DELIVER:
		var ammo: ItemData = load(path)
		deliver.append(ammo)
		_amounts[ammo] = DELIVER[path]

	# a task has no per-item amounts, every entry of the reward is one box
	var receive: Array[ItemData] = []
	for path in RECEIVE:
		var ammo: ItemData = load(path)
		for i in RECEIVE[path]:
			receive.append(ammo)

	_task = load("res://Traders/Gunsmith/Tasks/05_Ammo_Delivery.tres")
	if !lib.patch(lib.Registry.TRADER_TASKS, _task, {"deliver": deliver, "receive": receive}):
		Out.warning("patch failed for %s" % _task.name)

	register_hook("task-initialize-post", _on_task_initialize_post)


func _on_task_initialize_post(task: TaskData, _interface) -> void:
	if task != _task:
		return

	# vanilla sets every slot to defaultAmount (one box)
	for element in _lib._caller.inputGrid.get_children():
		# the placeholders Initialize has just freed are still in the tree
		if !element.is_queued_for_deletion():
			element.slotData.amount = _amounts[element.slotData.itemData]
			element.amount.text = str(element.slotData.amount)
