extends RefCounted

const FILE := "Batteries"
# Tunable: charge of a looted device and of a powered attachment first seen on a weapon, in whole percent.
const ROLL_MIN := 20
const ROLL_MAX := 75
# Power tiers of this mod's own, the ItemData.power values after the ones vanilla names: a red dot, and the illumination of a scope reticle.
const POWER_DOT := 4
const POWER_ILLUMINATION := 5
# Tunable: charge drained per second while a device is on, indexed by ItemData.power. The first four are the vanilla flashlight rates.
const DRAIN: Array[float] = [0.0, 0.05, 0.1, 0.2, 0.005, 0.02]

static var gameData := preload("res://Resources/GameData.tres")
static var data: ItemData
# The charge of the attachment vanilla is detaching, on its way to the item made of it.
static var _detached: SlotData


# Vanilla Interface.CombineCheck also asks for type Electronics. Lasers are attachments, so the list alone decides here.
static func powers(itemData: ItemData) -> bool:
	for element: ItemData in itemData.compatible:
		if element.file == FILE:
			return true
	return false


# Charge a device of that power tier drains per second while it is on.
static func drain_rate(power: int) -> float:
	# Same season test as vanilla Flashlight.Consumption.
	var cold := 2.0 if gameData.season == 2 else 1.0
	return DRAIN[power] * cold


# A device holds a battery only while it has charge. At 0% there is nothing to take out.
static func is_removable(slotData: SlotData) -> bool:
	return slotData.condition > 0 && powers(slotData.itemData)


# The charge of a powered attachment on a weapon.
# An attached item is a bare ItemData in `nested`, so its charge is kept as a SlotData of its own in the weapon's `storage`, which vanilla copies and saves with the weapon.
# Found by item, never by position: every powered attachment has its own entry.
static func attachment_holder(weapon: SlotData, attachment: ItemData) -> SlotData:
	for entry: SlotData in weapon.storage:
		# Other mods keep entries of their own here, some of them without an item.
		if entry.itemData && entry.itemData.file == attachment.file:
			return entry

	# AI drops, looted weapons and saves older than the entries carry a powered attachment without one.
	var created := SlotData.new()
	created.itemData = attachment
	created.condition = randi_range(ROLL_MIN, ROLL_MAX)
	weapon.storage.append(created)
	return created


# Every SlotData whose condition is a battery charge the item carries: its own for a device, one per powered attachment for a weapon.
static func holders(slotData: SlotData) -> Array[SlotData]:
	var result: Array[SlotData] = []
	if powers(slotData.itemData):
		result.append(slotData)

	for nested: ItemData in slotData.nested:
		if powers(nested):
			result.append(attachment_holder(slotData, nested))

	return result


# The holder a battery dropped on the item exchanges charge with. With several the emptiest one takes it.
# Polled on every hover tick while a battery is dragged over an item.
static func charge_target(slotData: SlotData) -> SlotData:
	var target: SlotData
	for holder: SlotData in holders(slotData):
		if !target || holder.condition < target.condition:
			target = holder
	return target


# Takes the charge of an attachment that is about to leave the weapon. `claim` hands it to the item vanilla makes of it.
static func detach(weapon: SlotData, attachment: ItemData) -> void:
	if !powers(attachment):
		return

	_detached = attachment_holder(weapon, attachment)
	weapon.storage.erase(_detached)


# Vanilla builds the detached item at full condition and creates it in the same call that removed it.
static func claim(slotData: SlotData) -> void:
	if !_detached:
		return

	if slotData.itemData.file == _detached.itemData.file:
		slotData.condition = _detached.condition
	_detached = null
