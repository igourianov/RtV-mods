extends RefCounted

# Vanilla Death takes no killer, so each damage call marks its AI with whether the player was the source.
const _PLAYER_HIT_META := &"likhos_vostac_player_hit"

var config := preload("../Config.gd").instance
var _lib


func _init(lib) -> void:
	_lib = lib


func on_ai_weapon_damage(_hitbox = null, _damage = null, _vector = null, id = null) -> void:
	_mark_source(id)


func on_ai_explosion_damage(_direction = null, id = null) -> void:
	_mark_source(id)


func on_ai_death(_direction = null, _force = null) -> void:
	var ai = _lib._caller
	if !ai || ai.dead:
		return
	var faction: int = ai.variant.faction if ai.variant else AIData.Faction.Bandit
	config.kills.append(faction)
	if ai.get_meta(_PLAYER_HIT_META, false):
		config.player_kills.append(faction)


func on_load_scene_pre(_scene = null) -> void:
	config.kills.clear()
	config.player_kills.clear()


func _mark_source(id) -> void:
	var ai = _lib._caller
	if ai:
		ai.set_meta(_PLAYER_HIT_META, is_instance_valid(id) && id.is_in_group("Player"))
