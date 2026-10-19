extends Camera3D

const BASE_SPEED := 0.5
const SPRINT_FACTOR := 6.0
const PITCH_LIMIT := deg_to_rad(89.0)

var gameData := preload("res://Resources/GameData.tres")
var view_camera: Camera3D
var _yaw: float
var _pitch: float


func _init(source: Camera3D) -> void:
	view_camera = source
	# the world is frozen with a tree pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	fov = source.fov
	near = source.near
	far = source.far
	cull_mask = source.cull_mask
	environment = source.environment
	var euler := source.global_basis.get_euler()
	_pitch = euler.x
	_yaw = euler.y


func _ready() -> void:
	global_position = view_camera.global_position


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if !motion:
		return
	# same scale as vanilla Controller mouse look
	var sensitivity := deg_to_rad(clampf(gameData.lookSensitivity, 0.1, 2.0) / 10)
	_yaw -= motion.relative.x * sensitivity
	# mouseMode 2 is the inverted setting, which vanilla applies to pitch only
	var pitch_sign := 1.0 if gameData.mouseMode == 2 else -1.0
	_pitch = clampf(_pitch + pitch_sign * motion.relative.y * sensitivity, -PITCH_LIMIT, PITCH_LIMIT)


func _process(delta: float) -> void:
	var planar := Input.get_vector("left", "right", "forward", "backward")
	var rise := Input.get_axis("crouch", "jump")
	var speed := BASE_SPEED * (SPRINT_FACTOR if Input.is_action_pressed("sprint") else 1.0)
	global_basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))
	global_position += (global_basis * Vector3(planar.x, 0.0, planar.y) + Vector3.UP * rise) * speed * delta
