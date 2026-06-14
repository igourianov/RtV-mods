extends CanvasLayer

const ModConfig = preload("../ModConfig.gd")
const Out = preload("../../Lib/Out.gd")
const ZoomAccelerator = preload("../ZoomAccelerator.gd")
const _SHADER = preload("res://mods/likhos-weapon-handling-fixes/Shaders/Binoculars.gdshader")
const _RETICLE_PATH = "res://mods/likhos-weapon-handling-fixes/Textures/binos_reticle.png"
const _GRIME_PATH = "res://mods/likhos-weapon-handling-fixes/Textures/binos_grime.jpg"
const _CAMERA_PATH = "/root/Map/Core/Camera"
const _HUD_PATH = "/root/Map/Core/UI/HUD"
const UIClickPlayer = preload("../Audio/UIClickPlayer.gd")

var gameData = preload("res://Resources/GameData.tres")
var _click_audio: UIClickPlayer

enum State { INACTIVE, RAISING, ACTIVE, LOWERING }

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

var _rect: ColorRect
var _mat: ShaderMaterial
var _camera: Camera3D
var _state := State.INACTIVE
var _progress := 0.0
var _index := 0
var _zoom := ZoomAccelerator.new()
var _base_fov := 70.0
var _current_fov := 70.0
var _hold_elapsed := 0.0


func _ready() -> void:
	layer = 1
	process_priority = 500
	_build_overlay()
	_rect.visible = false

	_click_audio = UIClickPlayer.new()
	add_child(_click_audio)


func _build_overlay() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = _SHADER
	_mat.set_shader_parameter("reticle_tex", _load_texture(_RETICLE_PATH))
	_mat.set_shader_parameter("grime_tex", _load_texture(_GRIME_PATH))

	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("binoculars") && (_state == State.INACTIVE || _state == State.LOWERING) && _can_raise():
		_state = State.RAISING
		_hold_elapsed = 0.0
		return

	if event.is_action_released("binoculars") && (_state == State.RAISING || _state == State.ACTIVE):
		if _hold_elapsed > _HOLD_THRESHOLD:
			_state = State.LOWERING
		return

	if _state != State.RAISING && _state != State.ACTIVE:
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
	return !(gameData.menu || gameData.freeze || gameData.isDead || gameData.isOccupied
		|| gameData.isReloading || gameData.isInspecting || gameData.isInserting
		|| gameData.isChecking || gameData.isPlacing || gameData.isDrawing
		|| gameData.isTransitioning || gameData.NVG || gameData.isRunning)


func _process(delta: float) -> void:
	if _state == State.RAISING || _state == State.ACTIVE:
		_hold_elapsed += delta

	if _state == State.INACTIVE:
		return

	if _state == State.LOWERING:
		_progress -= delta / _RAISE_TIME

	if !_resolve_camera() || gameData.isDead || gameData.menu || gameData.freeze || gameData.isRunning || _progress < 0.0:
		_state = State.INACTIVE
		_progress = 0.0
		_rect.visible = false
		ModConfig.binoculars_active = false
		gameData.isOccupied = false
		return

	if !ModConfig.binoculars_active:
		_progress = 0.0
		_rect.visible = true
		_base_fov = gameData.baseFOV
		_current_fov = _camera.fov
		ModConfig.binoculars_mag = _MAGS[_index]
		ModConfig.binoculars_active = true
		gameData.isOccupied = true
		gameData.isFiring = false

	if _state == State.RAISING:
		_progress = min(_progress + delta / _RAISE_TIME, 1.0)
		if _progress >= 1.0:
			_state = State.ACTIVE

	_apply(smoothstep(0.0, 1.0, _progress), delta)


func _apply(t: float, delta: float) -> void:
	_mat.set_shader_parameter("radius", lerp(_START_RADIUS, _END_RADIUS, t))
	_mat.set_shader_parameter("separation", lerp(_START_SEP, _END_SEP, t))
	_mat.set_shader_parameter("center_y", lerp(_START_CY, _END_CY, t))

	var eff_mag: float = lerp(1.0, _MAGS[_index], t)
	var target_fov := rad_to_deg(2.0 * atan(tan(deg_to_rad(_base_fov) * 0.5) / eff_mag))
	_current_fov = lerp(_current_fov, target_fov, clampf(delta * _FOV_LERP_SPEED, 0.0, 1.0))
	_camera.fov = _current_fov
