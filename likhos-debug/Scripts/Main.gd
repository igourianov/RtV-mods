extends "../Lib/Main.gd"

const FreeCam := preload("./FreeCam.gd")

var gameData := preload("res://Resources/GameData.tres")
var _free_cam: FreeCam


func _ready() -> void:
	# the toggle is read while the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	super()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if !key || !key.pressed || key.echo || key.physical_keycode != KEY_F7 || !key.alt_pressed:
		return
	get_viewport().set_input_as_handled()

	if is_instance_valid(_free_cam):
		_free_cam.queue_free()
		return

	var view_camera := get_node_or_null("/root/Map/Core/Camera") as Camera3D
	if !view_camera || get_tree().paused || gameData.settings || gameData.interface || gameData.isDead || gameData.isTransitioning || gameData.isCaching:
		return

	_free_cam = FreeCam.new(view_camera)
	get_tree().current_scene.add_child(_free_cam)
