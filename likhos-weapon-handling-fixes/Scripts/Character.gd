extends RefCounted

var _lib

func _init(lib) -> void:
	_lib = lib

func on_stamina(delta: float) -> void:
	var c = _lib._caller
	if c == null:
		return
	_lib.skip_super()

	var gd = c.gameData

	if gd.bodyStamina > 0 && (gd.isRunning || gd.overweight || (gd.isSwimming && gd.isMoving)):
		if gd.overweight || gd.starvation || gd.dehydration:
			gd.bodyStamina -= delta * 4.0
		else:
			gd.bodyStamina -= delta * 2.0
	elif gd.bodyStamina < 100:
		if gd.starvation || gd.dehydration:
			gd.bodyStamina += delta * 5.0
		else:
			gd.bodyStamina += delta * 10.0

	if gd.armStamina > 0 && ((gd.primary || gd.secondary) && (gd.weaponPosition == 2 || gd.isAiming || gd.isCanted || gd.overweight) || (gd.isSwimming && gd.isMoving)):
		if gd.overweight || gd.starvation || gd.dehydration:
			gd.armStamina -= delta * 4.0
		else:
			gd.armStamina -= delta * 2.0
	elif gd.armStamina < 100:
		if gd.starvation || gd.dehydration:
			gd.armStamina += delta * 10.0
		else:
			gd.armStamina += delta * 20.0
