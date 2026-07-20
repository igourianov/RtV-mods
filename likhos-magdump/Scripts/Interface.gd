extends RefCounted

var _lib
var _rig_visual


func _init(lib, rig_visual) -> void:
	_lib = lib
	_rig_visual = rig_visual


# Replace hook for Interface.GetMagazine. Reimplements the vanilla function in
# full, but on the swap path, when the inventory mag's identity differs from
# the gun's currently-attached mag, performs a real object swap (free the
# inventory mag, spawn a fresh one in its slot representing the gun's old mag)
# instead of vanilla's in-place ammo-count swap.
func on_get_magazine(weaponData: WeaponData, weaponSlot: Node, swapMagazine: bool) -> bool:
	_lib.skip_super()
	var iface = _lib._caller
	if iface == null:
		return false

	var picked = null
	var highest_amount := 0
	for m in iface.inventoryGrid.get_children():
		if m.slotData.itemData.subtype == "Magazine" \
				&& m.slotData.amount != 0 \
				&& weaponData.compatible.has(m.slotData.itemData):
			if m.slotData.amount > highest_amount:
				highest_amount = m.slotData.amount
				picked = m

	if picked == null:
		return false

	var weapon_item = weaponSlot.get_child(0)
	var weapon_ammo: int = weapon_item.slotData.amount
	var magazine_ammo: int = picked.slotData.amount

	# Detect cross-mag scenario for swap path.
	var gun_mag_idx := -1
	var gun_mag_data = null
	for i in weapon_item.slotData.nested.size():
		if weapon_item.slotData.nested[i].subtype == "Magazine":
			gun_mag_idx = i
			gun_mag_data = weapon_item.slotData.nested[i]
			break

	var cross_mag_swap:bool = swapMagazine \
			&& gun_mag_data != null \
			&& gun_mag_data != picked.slotData.itemData

	if !cross_mag_swap:
		# Vanilla flow.
		if swapMagazine:
			weapon_item.slotData.amount = magazine_ammo
			picked.slotData.amount = weapon_ammo
			picked.UpdateSprite()
			if weapon_item.slotData.amount != 0 && !weapon_item.slotData.chamber:
				weapon_item.slotData.chamber = true
				weapon_item.slotData.amount -= 1
		else:
			weapon_item.Combine(picked)
			iface.inventoryGrid.Pick(picked)
			picked.queue_free()
			_rig_visual.refresh_after_attach(iface)
		return true

	# Cross-mag swap: real object swap.
	var picked_pos: Vector2 = picked.position
	var picked_rotated: bool = picked.rotated
	var inv_mag_data = picked.slotData.itemData

	# Update gun: replace nested mag identity, load amount, chamber bump.
	weapon_item.slotData.nested[gun_mag_idx] = inv_mag_data
	weapon_item.slotData.amount = magazine_ammo
	if weapon_item.slotData.amount != 0 && !weapon_item.slotData.chamber:
		weapon_item.slotData.chamber = true
		weapon_item.slotData.amount -= 1
	weapon_item.UpdateAttachments()
	weapon_item.UpdateDetails()

	# Free the consumed inventory mag.
	iface.inventoryGrid.Pick(picked)
	picked.queue_free()

	# Spawn a replacement representing the gun's old mag at the same slot.
	var new_slot := SlotData.new()
	new_slot.itemData = gun_mag_data
	new_slot.amount = weapon_ammo
	new_slot.gridRotated = picked_rotated
	iface.LoadGridItem(new_slot, iface.inventoryGrid, picked_pos)

	_rig_visual.refresh_after_cross_swap(iface)

	return true
