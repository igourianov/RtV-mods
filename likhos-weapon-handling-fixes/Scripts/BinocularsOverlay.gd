extends CanvasLayer

const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")
const _SHADER = preload("res://mods/likhos-weapon-handling-fixes/Shaders/Binoculars.gdshader")
const _RETICLE_PATH = "res://mods/likhos-weapon-handling-fixes/Textures/binos_reticle.png"
const _GRIME_PATH = "res://mods/likhos-weapon-handling-fixes/Textures/binos_grime.png"
const _CAMERA_PATH = "/root/Map/Core/Camera"

var gameData = preload("res://Resources/GameData.tres")

enum State { INACTIVE, RAISING, ACTIVE, LOWERING }

const _RAISE_TIME := 0.45
const _MIN_MAG := 6.0
const _MAX_MAG := 12.0
const _ZOOM_STEP := 1.0

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
var _mag := _MIN_MAG
var _base_fov := 70.0


func _ready() -> void:
	layer = 128
	process_priority = 500
	_build_overlay()
	_set_visible(false)


func _build_overlay() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = _SHADER
	if ResourceLoader.exists(_RETICLE_PATH):
		_mat.set_shader_parameter("reticle_tex", load(_RETICLE_PATH))
	if ResourceLoader.exists(_GRIME_PATH):
		_mat.set_shader_parameter("grime_tex", load(_GRIME_PATH))

	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)


func _resolve_camera() -> bool:
	if is_instance_valid(_camera):
		return true
	_camera = get_tree().current_scene.get_node_or_null(_CAMERA_PATH) if get_tree().current_scene else null
	return is_instance_valid(_camera)


func _unhandled_input(event) -> void:
	if event.is_action_pressed("binoculars"):
		_toggle()
		return

	if _state == State.INACTIVE:
		return

	if event.is_action_pressed("optic_zoom_in"):
		_mag = clampf(_mag + _ZOOM_STEP, _MIN_MAG, _MAX_MAG)
	elif event.is_action_pressed("optic_zoom_out"):
		_mag = clampf(_mag - _ZOOM_STEP, _MIN_MAG, _MAX_MAG)


func _toggle() -> void:
	match _state:
		State.INACTIVE, State.LOWERING:
			if _can_raise():
				_activate()
				_state = State.RAISING
		State.RAISING, State.ACTIVE:
			_state = State.LOWERING


func _can_raise() -> bool:
	if !_resolve_camera():
		return false
	return !(gameData.menu || gameData.freeze || gameData.isDead || gameData.isOccupied
		|| gameData.isReloading || gameData.isInspecting || gameData.isInserting
		|| gameData.isChecking || gameData.isPlacing || gameData.isDrawing
		|| gameData.isTransitioning)


func _activate() -> void:
	_base_fov = gameData.baseFOV
	_mag = clampf(_mag, _MIN_MAG, _MAX_MAG)
	ModConfig.binoculars_active = true
	gameData.isOccupied = true


func _deactivate() -> void:
	ModConfig.binoculars_active = false
	gameData.isOccupied = false


func _process(delta: float) -> void:
	if _state == State.INACTIVE:
		return

	if !_resolve_camera() || gameData.isDead || gameData.menu || gameData.freeze:
		_abort()
		return

	match _state:
		State.RAISING:
			_progress = min(_progress + delta / _RAISE_TIME, 1.0)
			if _progress >= 1.0:
				_state = State.ACTIVE
		State.LOWERING:
			_progress = max(_progress - delta / _RAISE_TIME, 0.0)
			if _progress <= 0.0:
				_state = State.INACTIVE
				_deactivate()
				_set_visible(false)
				return

	_set_visible(true)
	_apply(smoothstep(0.0, 1.0, _progress))


func _abort() -> void:
	_state = State.INACTIVE
	_progress = 0.0
	_deactivate()
	_set_visible(false)


func _apply(t: float) -> void:
	_mat.set_shader_parameter("radius", lerp(_START_RADIUS, _END_RADIUS, t))
	_mat.set_shader_parameter("separation", lerp(_START_SEP, _END_SEP, t))
	_mat.set_shader_parameter("center_y", lerp(_START_CY, _END_CY, t))

	var eff_mag: float = lerp(1.0, _mag, t)
	var fov := rad_to_deg(2.0 * atan(tan(deg_to_rad(_base_fov) * 0.5) / eff_mag))
	_camera.fov = fov


func _set_visible(value: bool) -> void:
	if _rect:
		_rect.visible = value
