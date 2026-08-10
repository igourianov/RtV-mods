
const ModConfig := preload("../ModConfig.gd")

const _AUTO_ON_LATCH := &"likho_laser_latch"
const _RECOLOR_LATCH := &"likho_laser_recolor"
const _ZERO_LATCH := &"likho_laser_zero"
const _SOUND_NODE := "LikhoLaserSound"
const AttachmentClickPlayer := preload("../Audio/AttachmentClickPlayer.gd")
const _PEQ15_NAME := &"ANPEQ"
const _PEQ15_COLOR := Color(1, 0, 0, 1)
const _POINT_LIGHT_ENERGY: float = 0.1
const ZERO_DISTANCE: float = 30.0
const FADE_DISTANCE: float = 50.0

var _lib
var gameData := preload("res://Resources/GameData.tres")
var _auto_on_latch := false


func _init(lib) -> void:
	_lib = lib


func on_input(event: InputEvent) -> void:
	_lib.skip_super()
	__input(_lib._caller, event)


func on_process_post(_delta: float) -> void:
	var caller: Node = _lib._caller
	_recolor(caller)
	__process_post(caller)
	_converge(caller)
	_fade_point(caller)


func __input(caller: Node, event: InputEvent) -> void:
	if !caller.visible:
		return

	if event.is_action_pressed("laser"):
		caller.active = !caller.active
		caller.PlayLaser()
		if caller.active:
			caller.laser.show()
		else:
			caller.laser.hide()
			caller.set_meta(_AUTO_ON_LATCH, gameData.isCanted)


func __process_post(caller: Node) -> void:
	if !caller.visible:
		return

	var latch: bool = caller.get_meta(_AUTO_ON_LATCH, false)
	if gameData.isCanted && !gameData.isInspecting && ModConfig.laser_auto_on && !caller.active && !latch:
		caller.set_meta(_AUTO_ON_LATCH, true)
		caller.active = true
		caller.laser.show()
		_ensure_click(caller).click_in()
	elif !gameData.isCanted && latch:
		caller.set_meta(_AUTO_ON_LATCH, false)
		if caller.active:
			caller.active = false
			caller.laser.hide()
			_ensure_click(caller).click_out()


# The emitter sits off the fire line, so a parallel beam never meets the point of impact.
# Emitter and fire line hang off the same bone, so the angle is constant once solved.
func _converge(caller: Node) -> void:
	if caller.get_meta(_ZERO_LATCH, false):
		return

	var rig: Node = caller.owner
	if !rig || !rig.raycast:
		return

	# The raycast carries per-shot spread rotation, so the weapon axis comes off its parent.
	var axis: Basis = rig.raycast.get_parent().global_transform.basis
	caller.laser.look_at(rig.raycast.global_position + axis.z * ZERO_DISTANCE, axis.y, true)
	caller.raycast.target_position = Vector3(0.0, 0.0, FADE_DISTANCE)

	caller.set_meta(_ZERO_LATCH, true)


# Past the zero the dot walks back off the point of aim.
func _fade_point(caller: Node) -> void:
	if !caller.point.visible:
		return

	var distance: float = caller.raycast.global_position.distance_to(caller.point.global_position)
	var fade: float = clampf(inverse_lerp(FADE_DISTANCE, ZERO_DISTANCE, distance), 0.0, 1.0)

	caller.point.transparency = 1.0 - fade

	var light: Light3D = caller.point.get_node_or_null("Light")
	if light:
		light.light_energy = _POINT_LIGHT_ENERGY * fade


func _recolor(caller: Node) -> void:
	if caller.name != _PEQ15_NAME:
		return
	if caller.get_meta(_RECOLOR_LATCH, false):
		return
	caller.set_meta(_RECOLOR_LATCH, true)

	_tint_mesh(caller.laser.get_node_or_null("Beam"))
	_tint_mesh(caller.point)

	var light: Light3D = caller.point.get_node_or_null("Light")
	if light:
		light.light_color = _PEQ15_COLOR


func _tint_mesh(mesh: MeshInstance3D) -> void:
	if !mesh:
		return

	var material: ShaderMaterial = mesh.get_surface_override_material(0)
	if !material:
		return

	material = material.duplicate()
	material.set_shader_parameter("tint", _PEQ15_COLOR)
	mesh.set_surface_override_material(0, material)


func _ensure_click(caller: Node) -> AttachmentClickPlayer:
	var player: AttachmentClickPlayer = caller.get_node_or_null(_SOUND_NODE)
	if !player:
		player = AttachmentClickPlayer.new()
		player.name = _SOUND_NODE
		caller.add_child(player)
	return player
