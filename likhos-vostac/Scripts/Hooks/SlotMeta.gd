extends RefCounted

# SaveCharacter copies slot data with SlotData.Update, which drops metadata, and SlotData itself can't be hooked.
# Equipment metadata is held here across the save and put back when the next map loads the slot.
# Session only: it never reaches the save file.

# Metadata names VosTac stores on SlotData.
# Vanilla keeps the secondary sight choice in one global flag that every weapon draw resets, so each weapon's choice is kept here.
const SECONDARY_OPTIC := "likho_secondary_optic"

var _lib
# slot name -> {"item": ItemData, "meta": {name: value}}
var _carried := {}


func _init(lib) -> void:
	_lib = lib


func on_save_character_pre() -> void:
	_carried.clear()
	var interface = _lib._caller.get_tree().current_scene.get_node_or_null("/root/Map/Core/UI/Interface")
	if !interface:
		return
	for slot in interface.equipment.get_children():
		if !(slot is Slot) || slot.get_child_count() == 0:
			continue
		var slotData: SlotData = slot.get_child(0).slotData
		var meta := {}
		for meta_name in slotData.get_meta_list():
			meta[meta_name] = slotData.get_meta(meta_name)
		if !meta.is_empty():
			_carried[String(slot.name)] = {"item": slotData.itemData, "meta": meta}


func on_load_slot_item_post(slotData, slotName) -> void:
	var entry = _carried.get(slotName)
	if !entry:
		return
	_carried.erase(slotName)
	# a stale entry from an earlier save belongs to another weapon
	if entry["item"] != slotData.itemData:
		return
	var slot: Node = _lib._caller.equipment.get_node_or_null(NodePath(slotName))
	if !slot || slot.get_child_count() == 0:
		return
	var loaded: SlotData = slot.get_child(0).slotData
	for meta_name in entry["meta"]:
		loaded.set_meta(meta_name, entry["meta"][meta_name])
