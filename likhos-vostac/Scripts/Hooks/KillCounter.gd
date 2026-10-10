extends RefCounted

const Config := preload("../Config.gd")

var config := Config.instance
var _lib


func _init(lib) -> void:
	_lib = lib


func on_ai_death(_direction = null, _force = null) -> void:
	var ai = _lib._caller
	if !ai || ai.dead:
		return
	config.kills.append(ai.variant.faction if ai.variant else AIData.Faction.Bandit)


func on_load_scene_pre(_scene = null) -> void:
	config.kills.clear()
