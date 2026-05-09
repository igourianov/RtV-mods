
const Out = preload("../Lib/Out.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_input(event: InputEvent) -> void:
	_lib.skip_super()
	__input(_lib._caller, event)
	

func __input(caller, event: InputEvent):
	if Input.is_action_just_pressed("laser") && caller.visible:
		caller.active = !caller.active

		if caller.active:
			Out.bugfix("do not reset laser raycast to owner raycast - they're not supposed to align")
			#raycast.global_position = owner.raycast.global_position
			caller.laser.show()
		else:
			caller.laser.hide()
		caller.PlayLaser()

