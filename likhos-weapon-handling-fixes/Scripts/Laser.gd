
const Out = preload("../Lib/Out.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_input(event: InputEvent) -> void:
	__input(_lib._caller, event)

func __input(parent, event: InputEvent):
	if Input.is_action_just_pressed("laser") && parent.visible:
		parent.active = !parent.active

		if parent.active:
			Out.bugfix("do not reset laser raycast to owner raycast - they're not supposed to align")
			#raycast.global_position = owner.raycast.global_position
			parent.laser.show()
		else:
			parent.laser.hide()
		parent.PlayLaser()
