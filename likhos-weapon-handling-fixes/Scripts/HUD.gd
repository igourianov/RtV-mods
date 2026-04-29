extends RefCounted

var _lib
var _config
var _crosshair: Control

const _CROSSHAIR_SHADOW := Color(0, 0, 0, 0.7)
const _DOT_RADIUS := 1.5
const _ARM_LENGTH := 6.0
const _ARM_THICKNESS := 2.0
const _CENTER_GAP := 8.0

const _ATTACHMENT_SUBTYPES := ["Optic", "Muzzle", "Laser"]
const _ATT_PAD_X := 16.0
const _ATT_PAD_Y := 8.0
const _ATT_MIN_W := 32.0
const _ATT_MIN_H := 24.0
const _ATT_FONT_SIZE := 16

var _att_tooltips: Dictionary = {}
var _att_labels: Dictionary = {}
var _att_last_text: Dictionary = {}
var _camera: Camera3D
var _rig_manager: Node3D

func _init(lib, config) -> void:
	_lib = lib
	_config = config

func on_ready_post() -> void:
	var hud = _lib._caller
	if !hud:
		return
	_setup_crosshair(hud)
	_setup_attachment_tooltips(hud)

func on_physics_process_post(_delta: float) -> void:
	var hud = _lib._caller
	if !hud:
		return
	_update_interaction_tooltip(hud)
	_update_ammo_overlays(hud)
	_update_crosshair_visibility(hud)
	_update_attachment_tooltips(hud)

func _draw_crosshair(c: Control) -> void:
	var center := c.size * 0.5
	match _config.crosshair_style:
		"dot":
			c.draw_circle(center + Vector2(1, 1), _DOT_RADIUS, _CROSSHAIR_SHADOW)
			c.draw_circle(center, _DOT_RADIUS, _config.crosshair_color)
		"seg-cross":
			_draw_arms(c, center + Vector2(1, 1), _CROSSHAIR_SHADOW)
			_draw_arms(c, center, _config.crosshair_color)
		_:
			pass

func _draw_arms(c: Control, center: Vector2, color: Color) -> void:
	var t := _ARM_THICKNESS
	var l := _ARM_LENGTH
	var g := _CENTER_GAP
	c.draw_rect(Rect2(center.x - t * 0.5, center.y - g - l, t, l), color, true)
	c.draw_rect(Rect2(center.x - t * 0.5, center.y + g, t, l), color, true)
	c.draw_rect(Rect2(center.x - g - l, center.y - t * 0.5, l, t), color, true)
	c.draw_rect(Rect2(center.x + g, center.y - t * 0.5, l, t), color, true)

func _setup_crosshair(hud) -> void:
	if is_instance_valid(_crosshair) && _crosshair.get_parent() == hud:
		return
	var crosshair := Control.new()
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12
	crosshair.offset_top = -12
	crosshair.offset_right = 12
	crosshair.offset_bottom = 12
	crosshair.draw.connect(_draw_crosshair.bind(crosshair))
	hud.add_child(crosshair)
	crosshair.hide()
	_crosshair = crosshair
	hud.tooltip.offset_top += 32
	hud.tooltip.offset_bottom += 32

func _update_crosshair_visibility(hud) -> void:
	if !is_instance_valid(_crosshair):
		return
	var gd = hud.gameData
	var aimingMode = gd.isAiming || gd.isCanted || gd.weaponPosition == 2
	var aimBlocked = gd.menu || gd.isDead || gd.isInspecting || gd.transition || gd.isTransitioning
	_crosshair.visible = !aimingMode && !aimBlocked && _config.crosshair_style != "off"

func _update_interaction_tooltip(hud) -> void:
	var gd = hud.gameData
	var aimingMode = gd.isAiming || gd.isCanted || gd.weaponPosition == 2
	hud.tooltip.visible = gd.interaction && !gd.transition && !aimingMode

func _update_ammo_overlays(hud) -> void:
	var gd = hud.gameData
	if gd.isInspecting && _config.ammo_tooltips:
		hud.magazine.visible = true
		hud.chamber.visible = true

func _setup_attachment_tooltips(hud) -> void:
	var stale := _att_tooltips.is_empty()
	if !stale:
		var any = _att_tooltips.values()[0]
		stale = !is_instance_valid(any) || any.get_parent() != hud
	if !stale:
		return
	_att_tooltips.clear()
	_att_labels.clear()
	_att_last_text.clear()
	_create_attachment_tooltips(hud)

func _create_attachment_tooltips(hud) -> void:
	if hud.magazine == null:
		return
	for subtype in _ATTACHMENT_SUBTYPES:
		var clone: Control = hud.magazine.duplicate()
		clone.name = "AttachmentTooltip_" + subtype
		var panel = clone.get_child(0)
		var label = panel.get_child(0)
		label.text = ""
		label.add_theme_font_size_override("font_size", _ATT_FONT_SIZE)
		clone.hide()
		hud.add_child(clone)
		_att_tooltips[subtype] = clone
		_att_labels[subtype] = label
		_att_last_text[subtype] = ""

func _update_attachment_tooltips(hud) -> void:
	if _att_tooltips.is_empty():
		return
	var gd = hud.gameData
	if !_config.attachment_tooltips || !gd.isInspecting:
		for tt in _att_tooltips.values():
			tt.hide()
		return

	if _camera == null || !is_instance_valid(_camera):
		_camera = hud.get_tree().current_scene.get_node_or_null("/root/Map/Core/Camera")
	if _rig_manager == null || !is_instance_valid(_rig_manager):
		_rig_manager = hud.get_tree().current_scene.get_node_or_null("/root/Map/Core/Camera/Manager")
	if _camera == null || _rig_manager == null || _rig_manager.get_child_count() == 0:
		for tt in _att_tooltips.values():
			tt.hide()
		return

	var rig = _rig_manager.get_child(0)
	if !(rig is WeaponRig) || rig.slotData == null || rig.attachments == null:
		for tt in _att_tooltips.values():
			tt.hide()
		return

	var by_subtype: Dictionary = {}
	for nested in rig.slotData.nested:
		if nested != null && _ATTACHMENT_SUBTYPES.has(nested.subtype):
			by_subtype[nested.subtype] = nested

	for subtype in _ATTACHMENT_SUBTYPES:
		var tooltip: Control = _att_tooltips[subtype]
		var item = by_subtype.get(subtype, null)
		if item == null:
			tooltip.hide()
			continue
		var attachment = rig.attachments.get_node_or_null(item.file)
		if attachment == null || !is_instance_valid(attachment) || !attachment.visible:
			tooltip.hide()
			continue

		var label: Label = _att_labels[subtype]
		var new_text = str(item.name)
		if new_text != _att_last_text.get(subtype, ""):
			label.text = new_text
			_att_last_text[subtype] = new_text
			var min_size = label.get_minimum_size()
			var w = max(min_size.x + _ATT_PAD_X * 2.0, _ATT_MIN_W)
			var h = max(min_size.y + _ATT_PAD_Y * 2.0, _ATT_MIN_H)
			var panel = tooltip.get_child(0)
			panel.offset_left = -w / 2.0
			panel.offset_top = -h / 2.0
			panel.offset_right = w / 2.0
			panel.offset_bottom = h / 2.0

		tooltip.global_position = _camera.unproject_position(attachment.global_position)
		tooltip.show()
