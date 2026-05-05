extends RefCounted

const ModConfig = preload("./ModConfig.gd")

var _lib
var _weapon_rig
var _preferences: Preferences


func _init(lib, weapon_rig, preferences: Preferences) -> void:
	_lib = lib
	_weapon_rig = weapon_rig
	_preferences = preferences


func on_movement_states_pre(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	ctrl.crouchSpeed = ModConfig.crouch_speed
	ctrl.walkSpeed = ModConfig.walk_speed
	ctrl.sprintSpeed = ModConfig.sprint_speed



func on_movement_states_post(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	var gd = ctrl.gameData

	if gd.isWalking && gd.isAiming && gd.isScoped:
		var rig = _weapon_rig.active_rig if _weapon_rig != null else null
		var optic = rig.activeOptic if rig != null else null
		if optic != null && optic.attachmentData.variable && rig.slotData.zoom == 1:
			ctrl.currentSpeed = ctrl.walkSpeed * ModConfig.aim_speed_mult
		else:
			ctrl.currentSpeed = ctrl.walkSpeed * ModConfig.scope_speed_mult
	elif gd.isWalking && gd.isAiming:
		ctrl.currentSpeed = ctrl.walkSpeed * ModConfig.aim_speed_mult
	elif gd.isWalking && gd.isCanted:
		ctrl.currentSpeed = ctrl.walkSpeed * ModConfig.cant_speed_mult
