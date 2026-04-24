extends "res://Scripts/WeaponRig.gd"


func AmmoCheck():
	if gameData.isChecking:
		return

	var previousPosition = gameData.weaponPosition

	await super()

	gameData.weaponPosition = previousPosition
