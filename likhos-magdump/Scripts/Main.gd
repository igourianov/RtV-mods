extends Node

const CompatTable = preload("res://mods/likhos-magdump/Scripts/CompatTable.gd")


func _ready() -> void:
	for weapon_path in CompatTable.COMPAT:
		_apply_for_weapon(weapon_path, CompatTable.COMPAT[weapon_path])


func _apply_for_weapon(weapon_path: String, mag_paths: Array) -> void:
	var weapon = load(weapon_path)
	if weapon == null:
		push_warning("[likhos-magdump] weapon not found: %s" % weapon_path)
		return
	for mag_path in mag_paths:
		var mag = load(mag_path)
		if mag == null:
			push_warning("[likhos-magdump] magazine not found: %s" % mag_path)
			continue
		if mag.subtype != "Magazine":
			push_warning("[likhos-magdump] %s is not a Magazine (subtype=%s)" % [mag_path, mag.subtype])
			continue
		if !weapon.compatible.has(mag):
			weapon.compatible.append(mag)
			print("[likhos-magdump] %s now accepts %s" % [weapon.file, mag.file])
