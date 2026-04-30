extends RefCounted

var _lib

const _EXCLUSIONS := {
	"BTR": "Police",
	"Police": "BTR",
	"Airdrop": "CrashSite",
	"CrashSite": "Airdrop"
}

var _activated: Dictionary = {}


func _init(lib) -> void:
	_lib = lib


func on_activate_dynamic_event() -> void:
	var es = _lib._caller
	_lib.skip_super()
	if es == null:
		return
	_activate_dynamic_event(es)


func _activate_dynamic_event(es) -> void:
	if es.dynamicEvents.size() == 0:
		return

	var events := es.dynamicEvents.duplicate()
	events.shuffle()

	var rollbonus: float = 0.0
	for e in events:
		var partner = _EXCLUSIONS.get(e.function, null)
		if partner != null && _activated.has(partner):
			rollbonus += e.possibility * 0.5
			print("[likho] event skipped (mutex): " + e.name + " | Rollbonus: +" + str(rollbonus))
			continue

		var threshold: float = e.possibility + rollbonus
		var roll = randi_range(1, 100)
		rollbonus = 0.0

		if roll > threshold:
			print("[likho] event missed (Dynamic): " + e.name + " | Roll: " + str(roll) + "/" + str(threshold))
			continue

		print("[likho] event selected (Dynamic): " + e.name + " | Roll: " + str(roll) + "/" + str(threshold))
		_activated[e.function] = true

		if e.instant:
			print("[likho] event activated (Dynamic): " + e.name)
			Callable(es, e.function).call()
		else:
			_delayed_call(es, e)


func _delayed_call(es, selected_event) -> void:
	var event_delay = randi_range(0, 300)
	var minutes = floor(event_delay / 60.0)
	var seconds = event_delay % 60
	print("[likho] event activated (Dynamic): " + selected_event.name + " | Delay: " + "%02d:%02d" % [minutes, seconds])
	await es.get_tree().create_timer(event_delay, false).timeout
	Callable(es, selected_event.function).call()


func on_fighter_jet_post() -> void:
	var es = _lib._caller
	if es == null:
		return
	_schedule_fighter_jet(es)


func _schedule_fighter_jet(es) -> void:
	var delay = randi_range(60, 300)
	var minutes = floor(delay / 60.0)
	var seconds = delay % 60
	print("[likho] FighterJet re-trigger scheduled | Delay: " + "%02d:%02d" % [minutes, seconds])
	await es.get_tree().create_timer(delay, false).timeout
	if !is_instance_valid(es):
		return
	Callable(es, "FighterJet").call()
