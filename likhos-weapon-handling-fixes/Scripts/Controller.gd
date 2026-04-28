extends RefCounted

var _lib
var _weapon_rig
var _preferences: Preferences
var _config


func _init(lib, weapon_rig, preferences: Preferences, config) -> void:
	_lib = lib
	_weapon_rig = weapon_rig
	_preferences = preferences
	_config = config

func on_movement_states_pre(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	ctrl.crouchSpeed = _config.crouch_speed
	ctrl.walkSpeed = _config.walk_speed
	ctrl.sprintSpeed = _config.sprint_speed



func on_movement_states_post(_delta: float) -> void:
	var ctrl = _lib._caller
	if ctrl == null:
		return

	var gd = ctrl.gameData

	if gd.isWalking && gd.isAiming && gd.isScoped:
		var rig = _weapon_rig.active_rig if _weapon_rig != null else null
		var optic = rig.activeOptic if rig != null else null
		if optic != null && optic.attachmentData.variable && rig.slotData.zoom == 1:
			ctrl.currentSpeed = ctrl.walkSpeed * _config.aim_speed_mult
		else:
			ctrl.currentSpeed = ctrl.walkSpeed * _config.scope_speed_mult
	elif gd.isWalking && gd.isAiming:
		ctrl.currentSpeed = ctrl.walkSpeed * _config.aim_speed_mult
	elif gd.isWalking && gd.isCanted:
		ctrl.currentSpeed = ctrl.walkSpeed * _config.cant_speed_mult
