extends CanvasLayer

const ModConfig = preload("../ModConfig.gd")
const Out = preload("../../Lib/Out.gd")
const ZoomAccelerator = preload("../ZoomAccelerator.gd")
const _LENS_SHADER = preload("res://mods/likhos-weapon-handling-fixes/Shaders/BinocularsLens.gdshader")
const _READOUT_SHADER = preload("res://mods/likhos-weapon-handling-fixes/Shaders/BinocularsReadout.gdshader")
const _RETICLE_SHADER = preload("res://mods/likhos-weapon-handling-fixes/Shaders/BinocularsReticle.gdshader")
const _RETICLE_PATH = "res://mods/likhos-weapon-handling-fixes/Textures/binos_reticle.png"
const _GRIME_PATH = "res://mods/likhos-weapon-handling-fixes/Textures/binos_grime.jpg"
const _CAMERA_PATH = "/root/Map/Core/Camera"
const _HUD_PATH = "/root/Map/Core/UI/HUD"
const ZoomClickPlayer = preload("../Audio/ZoomClickPlayer.gd")

var gameData = preload("res://Resources/GameData.tres")
var _click_audio: ZoomClickPlayer

enum State { INACTIVE, ACTIVE, LOWERING }

const _RAISE_TIME := 0.3
const _FOV_LERP_SPEED := 12.0
const _HOLD_THRESHOLD := 0.25
const _MAGS := [6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0] #[6.0, 8.0, 10.0, 12.0]

const _START_RADIUS := 0.12
const _END_RADIUS := 0.60
const _START_SEP := 0.0
const _END_SEP := 0.55
const _START_CY := 0.66
const _END_CY := 0.5

const _RANGE_MAX := 2000.0
const _RANGE_CADENCE := 0.5
const _RANGE_MASK := 1117  # weapon bullet mask (layers 1,3,4,5,7) plus foliage obstruction (layer 11); skips layer-6 player-block collider that seals window openings
const _RANGE_COLOR := Color(1.0, 0.5, 0.05, 0.6)
const _RANGE_LINE := 0.275
const _RANGE_FONT_SIZE := 28
const _REVEAL_RAISE := 0.8
const _PLAYER_PATH := "/root/Map/Core/Controller"

var _rect: ColorRect
var _mat: ShaderMaterial
var _camera: Camera3D
var _state := State.INACTIVE
var _raise_state := 0.0
var _index := 0
var _zoom := ZoomAccelerator.new()
var _base_fov := 70.0
var _current_fov := 70.0
var _hold_timer := 0.0
var _loot_light
var _loot_light_not_found: bool
var _ray: RayCast3D
var _range_label: Label
var _range_timer := 0.0
var _reticle_rect: ColorRect
var _reticle_mat: ShaderMaterial


func _ready() -> void:
	layer = 1
	process_priority = 500
	_build_overlay()
	_rect.visible = false

	_click_audio = ZoomClickPlayer.new()
	add_child(_click_audio)


func _build_overlay() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = _LENS_SHADER
	_mat.set_shader_parameter("reticle_tex", _load_texture(_RETICLE_PATH))
	_mat.set_shader_parameter("grime_tex", _load_texture(_GRIME_PATH))

	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)

	_reticle_mat = ShaderMaterial.new()
	_reticle_mat.shader = _RETICLE_SHADER
	_reticle_mat.set_shader_parameter("aim_dot_color", _RANGE_COLOR)
	_reticle_rect = ColorRect.new()
	_reticle_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reticle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle_rect.material = _reticle_mat
	_reticle_rect.visible = false
	add_child(_reticle_rect)

	_range_label = Label.new()
	_range_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_range_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_range_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_range_label.add_theme_color_override("font_color", _RANGE_COLOR)
	_range_label.add_theme_color_override("font_outline_color", Color(_RANGE_COLOR.r, _RANGE_COLOR.g, _RANGE_COLOR.b, 0.5))
	_range_label.add_theme_constant_override("outline_size", 7)
	_range_label.add_theme_font_size_override("font_size", _RANGE_FONT_SIZE)
	var led_mat := ShaderMaterial.new()
	led_mat.shader = _READOUT_SHADER
	_range_label.material = led_mat
	_range_label.visible = false
	add_child(_range_label)


func _load_texture(path: String) -> Texture2D:
	var img := Image.new()
	img.load(path)
	return ImageTexture.create_from_image(img)


func _resolve_camera() -> bool:
	if is_instance_valid(_camera):
		return true
	var scene = get_tree().current_scene
	if !scene:
		return false
	_camera = scene.get_node_or_null(_CAMERA_PATH)
	if !is_instance_valid(_camera):
		return false
	_apply_layer(scene)
	return true


func _apply_layer(scene) -> void:
	var effective := 0
	var n = scene.get_node_or_null(_HUD_PATH)
	while n:
		if n is CanvasLayer:
			effective = n.layer
			break
		n = n.get_parent()
	layer = effective - 1


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return

	if event.is_action_pressed("binoculars") && (_state == State.INACTIVE || _state == State.LOWERING) && _can_raise():
		_state = State.ACTIVE
		_hold_timer = _HOLD_THRESHOLD
		_range_timer = 0.0
		_rect.visible = true
		_base_fov = gameData.baseFOV
		_current_fov = _camera.fov
		ModConfig.binoculars_mag = _MAGS[_index]
		gameData.isOccupied = true
		gameData.isFiring = false
		return

	if event.is_action_released("binoculars") && _state == State.ACTIVE:
		if _hold_timer <= 0.0:
			_state = State.LOWERING
		return

	if _state != State.ACTIVE:
		return

	if event.is_action_pressed("aim") || event.is_action_pressed("canted"):
		_state = State.LOWERING
		return

	if event.is_action_pressed("optic_zoom_in"):
		_change_zoom(1)
	elif event.is_action_pressed("optic_zoom_out"):
		_change_zoom(-1)


func _change_zoom(dir: int) -> void:
	var next := _zoom.step(dir, _index, _MAGS.size())
	if next != _index:
		_index = next
		ModConfig.binoculars_mag = _MAGS[_index]
		_click_audio.click()


func _can_raise() -> bool:
	if !_resolve_camera():
		return false
	return !(ModConfig.gated() || ModConfig.locked()
		|| gameData.isOccupied || gameData.NVG || gameData.isRunning)


func _process(delta: float) -> void:
	if _state == State.INACTIVE:
		_raise_state = 0.0
		_range_label.visible = false
		_reticle_rect.visible = false
		return

	if _state == State.LOWERING && _raise_state > 0.0:
		_raise_state -= delta / _RAISE_TIME
	elif _state == State.ACTIVE && _raise_state < 1.0:
		_raise_state += delta / _RAISE_TIME

	if _state == State.ACTIVE && _hold_timer > 0.0:
		_hold_timer -= delta

	if !_resolve_camera() || ModConfig.gated() || gameData.isRunning || _raise_state < 0.0:
		_state = State.INACTIVE
		_rect.visible = false
		_reticle_rect.visible = false
		_range_label.visible = false
		ModConfig.binoculars_active = false
		gameData.isOccupied = false
		_apply_loot_light(false)
		return

	ModConfig.binoculars_active = _state == State.ACTIVE

	_apply(smoothstep(0.0, 1.0, _raise_state), delta)
	_apply_loot_light(true)

	var revealed := _state == State.ACTIVE && _raise_state > _REVEAL_RAISE
	_range_label.visible = revealed
	_reticle_rect.visible = revealed
	if revealed:
		_update_rangefinder(delta)


# integration with LootLight mod
func _apply_loot_light(on: bool):
	if _loot_light_not_found:
		return
	if !is_instance_valid(_loot_light):
		_loot_light = get_node_or_null("/root/LootLightMain")
		if !is_instance_valid(_loot_light) || !_loot_light.has_method("Set_Highlight"):
			_loot_light_not_found = true
			return
	if on:
		_loot_light.Set_Highlight(true, 200, 10, _current_fov * 1.2)
	else:
		_loot_light.Set_Highlight(false)


func _ensure_ray() -> void:
	if is_instance_valid(_ray):
		return
	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0.0, 0.0, -_RANGE_MAX)
	_ray.collision_mask = _RANGE_MASK
	_ray.enabled = true
	_camera.add_child(_ray)
	var player = _camera.get_node_or_null(_PLAYER_PATH)
	if player:
		_ray.add_exception(player)


func _update_rangefinder(delta: float) -> void:
	_range_timer -= delta
	if _range_timer > 0.0:
		return
	_range_timer = _RANGE_CADENCE

	_ensure_ray()
	_ray.force_raycast_update()
	if _ray.is_colliding():
		var dist := _camera.global_position.distance_to(_ray.get_collision_point())
		_range_label.text = "%d m" % roundi(dist)
	else:
		_range_label.text = "---"


func _apply(t: float, delta: float) -> void:
	var radius: float = lerp(_START_RADIUS, _END_RADIUS, t)
	var center_y: float = lerp(_START_CY, _END_CY, t)
	_mat.set_shader_parameter("radius", radius)
	_mat.set_shader_parameter("separation", lerp(_START_SEP, _END_SEP, t))
	_mat.set_shader_parameter("center_y", center_y)
	_reticle_mat.set_shader_parameter("center_y", center_y)

	# track the reticle in normalized space so the label holds across resolutions and aspects
	var line_y := center_y + _RANGE_LINE * radius
	_range_label.offset_top = (2.0 * line_y - 1.0) * get_viewport().get_visible_rect().size.y

	var eff_mag: float = lerp(1.0, _MAGS[_index], t)
	var target_fov := rad_to_deg(2.0 * atan(tan(deg_to_rad(_base_fov) * 0.5) / eff_mag))
	_current_fov = lerp(_current_fov, target_fov, clampf(delta * _FOV_LERP_SPEED, 0.0, 1.0))
	_camera.fov = _current_fov
