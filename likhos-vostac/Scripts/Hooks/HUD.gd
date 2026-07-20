extends RefCounted

const ModConfig := preload("../ModConfig.gd")
const InspectCard := preload("../InspectCards/InspectCard.gd")
const FireModeCard := preload("../InspectCards/FireModeCard.gd")
const AmmoCardReplacer := preload("../InspectCards/AmmoCardReplacer.gd")
const ChamberCardReplacer := preload("../InspectCards/ChamberCardReplacer.gd")
const KillCounterCard := preload("../InspectCards/KillCounterCard.gd")
const Crosshair := preload("../Nodes/Crosshair.gd")
var gameData := preload("res://Resources/GameData.tres")

var _lib
var _crosshair: Crosshair

const _WRIST_BONE := "Wrist_R"
const _KILL_BONE_OFFSET := Vector2(0.0, -10.0)
const _KILL_CARD_SEP := 6

var _kill_cards: Array = []
var _kill_container: VBoxContainer
var _firemode_card: FireModeCard
var _ammo_replacer: AmmoCardReplacer
var _chamber_replacer: ChamberCardReplacer
var _camera: Camera3D
var _rig_manager: Node3D
var _att_cards: Dictionary = {}


func _init(lib) -> void:
	_lib = lib


func on_ready_post() -> void:
	var hud = _lib._caller
	if !hud:
		return
	_setup_crosshair(hud)
	_setup_firemode_card(hud)
	_setup_kill_cards(hud)
	_setup_ammo_replacer(hud)
	_setup_chamber_replacer(hud)


func _setup_crosshair(hud: Node) -> void:
	if is_instance_valid(_crosshair) && _crosshair.get_parent() == hud:
		return
	_crosshair = Crosshair.new()
	hud.add_child(_crosshair)


func _setup_firemode_card(hud: Node) -> void:
	if is_instance_valid(_firemode_card) && _firemode_card.get_parent() == hud:
		return
	_firemode_card = FireModeCard.new()
	hud.add_child(_firemode_card)


func _setup_kill_cards(hud: Node) -> void:
	if is_instance_valid(_kill_container) && _kill_container.get_parent() == hud:
		return
	_kill_cards.clear()

	_kill_container = VBoxContainer.new()
	_kill_container.name = "KillCounter"
	_kill_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_container.add_theme_constant_override("separation", _KILL_CARD_SEP)
	hud.add_child(_kill_container)


func _setup_ammo_replacer(hud) -> void:
	if !hud.magazine || hud.magazine.get_child_count() == 0:
		return
	var panel: Node = hud.magazine.get_child(0)
	if is_instance_valid(_ammo_replacer) && _ammo_replacer.get_parent() == panel:
		return
	_ammo_replacer = AmmoCardReplacer.new()
	panel.add_child(_ammo_replacer)


func _setup_chamber_replacer(hud) -> void:
	if !hud.chamber || hud.chamber.get_child_count() == 0:
		return
	var panel: Node = hud.chamber.get_child(0)
	if is_instance_valid(_chamber_replacer) && _chamber_replacer.get_parent() == panel:
		return
	_chamber_replacer = ChamberCardReplacer.new()
	panel.add_child(_chamber_replacer)


func on_physics_process_post(delta: float) -> void:
	var hud = _lib._caller
	if !is_instance_valid(hud):
		return

	if !is_instance_valid(_camera):
		_camera = hud.get_node_or_null("/root/Map/Core/Camera")
	if !is_instance_valid(_rig_manager):
		_rig_manager = hud.get_node_or_null("/root/Map/Core/Camera/Manager")

	var rig: WeaponRig = _rig_manager.get_child(0) as WeaponRig if _rig_manager && _rig_manager.get_child_count() > 0 else null

	if is_instance_valid(_crosshair):
		_crosshair.update(hud, delta)

	_update_ammo_cards(hud, rig)
	_update_attachment_cards(hud, rig)
	_update_firemode_card(rig)
	_update_kill_cards(rig)


func _update_ammo_cards(hud, rig: WeaponRig) -> void:
	var enabled := false
	if gameData.isChecking && ModConfig.ammo_check_view:
		enabled = ModConfig.ammo_cards_check
	elif gameData.isInspecting:
		enabled = ModConfig.ammo_cards_inspect
	elif gameData.isInserting:
		enabled = ModConfig.ammo_cards_manual_reload

	var has_mag: bool = rig && (!rig.magazine || rig.magazine.visible)
	var is_manual: bool = rig && rig.data && rig.data.weaponAction == "Manual"
	var show_chamber: bool = ModConfig.chamber_card_mode == "enabled" || (ModConfig.chamber_card_mode == "manual" && is_manual)

	hud.magazine.visible = enabled && has_mag
	hud.chamber.visible = enabled && show_chamber

	if rig && rig.slotData && (hud.chamber.visible || hud.magazine.visible):
		rig.UpdateHUD()

	if is_instance_valid(_ammo_replacer):
		_ammo_replacer.set_rig(rig)

	if is_instance_valid(_chamber_replacer):
		_chamber_replacer.set_rig(rig)


func _update_attachment_cards(hud: Node, rig: WeaponRig) -> void:
	for card in _att_cards.values():
		if is_instance_valid(card):
			card.hide()

	if !ModConfig.attachment_cards || !gameData.isInspecting || !_camera || !rig || !rig.slotData || !rig.attachments:
		return

	for nested in rig.slotData.nested:
		if !nested || nested.type != "Attachment" || nested.subtype == "Magazine":
			continue

		var attachment: Node3D = rig.attachments.get_node_or_null(nested.file) as Node3D
		if !is_instance_valid(attachment) || !attachment.visible:
			continue

		var card: InspectCard = _att_cards.get(nested.subtype)
		if !is_instance_valid(card):
			card = InspectCard.new()
			hud.add_child(card)
			_att_cards[nested.subtype] = card

		card.set_text(nested.name)
		card.point_at(_camera.unproject_position(_world_center(attachment)))


func _update_firemode_card(rig: WeaponRig) -> void:
	if !is_instance_valid(_firemode_card):
		return

	if !ModConfig.firemode_card || !gameData.isInspecting || !_camera || !rig || !rig.skeleton || !rig.data || rig.data.weaponAction != "Semi-Auto":
		_firemode_card.hide()
		return

	var skeleton: Skeleton3D = rig.skeleton
	if rig.selectorIndex < 0 || rig.selectorIndex >= skeleton.get_bone_count():
		_firemode_card.hide()
		return

	_firemode_card.set_mode(rig.slotData.mode if rig.slotData else 1)

	var bone_origin := skeleton.get_bone_global_pose(rig.selectorIndex).origin
	_firemode_card.point_at(_camera.unproject_position(skeleton.to_global(bone_origin)))


func _update_kill_cards(rig: WeaponRig) -> void:
	if !is_instance_valid(_kill_container):
		return

	var kills := ModConfig.kills
	if !ModConfig.kill_counter_card || !gameData.isInspecting || kills.is_empty() || !_camera || !rig || !rig.skeleton:
		_kill_container.hide()
		return

	var skeleton: Skeleton3D = rig.skeleton
	var bone := skeleton.find_bone(_WRIST_BONE)
	if bone < 0:
		_kill_container.hide()
		return

	var groups: int = ceili(kills.size() / 10.0)

	while _kill_cards.size() < groups:
		var card := KillCounterCard.new()
		_kill_cards.append(card)
		_kill_container.add_child(card)
		_kill_container.move_child(card, 0)

	for i in _kill_cards.size():
		var card: KillCounterCard = _kill_cards[i]
		if i >= groups:
			card.hide()
			continue
		card.set_group(kills.slice(i * 10, i * 10 + 10))
		card.show()

	var origin := skeleton.get_bone_global_pose(bone).origin
	var screen := _camera.unproject_position(skeleton.to_global(origin))
	var size := _kill_container.get_combined_minimum_size()
	_kill_container.position = Vector2(screen.x - size.x * 0.5, screen.y - size.y) + _KILL_BONE_OFFSET
	_kill_container.show()


static var _local_center_cache: Dictionary = {}


# the subtree is rigid relative to its root, so the local-space center is computed once
# and only the per-frame transform is applied
static func _world_center(node: Node3D) -> Vector3:
	var id := node.get_instance_id()
	if !_local_center_cache.has(id):
		_local_center_cache[id] = _compute_local_center(node)
	return node.global_transform * _local_center_cache[id]


static func _compute_local_center(node: Node3D) -> Vector3:
	var inv := node.global_transform.affine_inverse()
	var merged: AABB
	var found := false
	var stack: Array = [node]
	while !stack.is_empty():
		var n: Node3D = stack.pop_back()
		if n.name == "Laser":
			continue
		if n is VisualInstance3D:
			var local: AABB = (inv * n.global_transform) * n.get_aabb()
			merged = merged.merge(local) if found else local
			found = true
		for child in n.get_children():
			if child is Node3D:
				stack.append(child)
	return merged.get_center() if found else Vector3.ZERO
