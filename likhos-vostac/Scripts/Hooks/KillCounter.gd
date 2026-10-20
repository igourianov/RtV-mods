extends RefCounted

var config := preload("../Config.gd").instance
var _lib
# Vanilla Death takes no killer, so the damage call that leads into it records the source.
var _player_source := false


func _init(lib) -> void:
	_lib = lib


func on_ai_weapon_damage(_hitbox = null, _damage = null, _vector = null, id = null) -> void:
	_player_source = _is_player(id)


func on_ai_explosion_damage(_direction = null, id = null) -> void:
	_player_source = _is_player(id)


func on_ai_death(_direction = null, _force = null) -> void:
	var ai = _lib._caller
	var player_source := _player_source
	_player_source = false
	if !ai || ai.dead:
		return
	var faction: int = ai.variant.faction if ai.variant else AIData.Faction.Bandit
	config.kills.append(faction)
	if player_source:
		config.player_kills.append(faction)


func on_load_scene_pre(_scene = null) -> void:
	config.kills.clear()
	config.player_kills.clear()


func _is_player(id) -> bool:
	return is_instance_valid(id) && id.is_in_group("Player")
