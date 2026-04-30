extends RefCounted

var _lib

const _EXCLUSIONS := {
	"BTR": "Police",
	"Police": "BTR",
	"Airdrop": "CrashSite",
	"CrashSite": "Airdrop"
}


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

	var activated: Dictionary = {}
	var events = es.dynamicEvents.duplicate()
	events.shuffle()

	var rollbonus: float = 0.0
	for e in events:
		var partner = _EXCLUSIONS.get(e.function, null)
		if partner != null && activated.has(partner):
			rollbonus += e.possibility * 0.5
			print("[likho] event skipped: \(e.name) | Exclusive with: \(partner) | Next roll bonus: +\(rollbonus)")
			continue

		var threshold: float = e.possibility + rollbonus
		var roll = randi_range(1, 100)

		if roll > threshold:
			print("[likho] event missed: \(e.name) | Roll: \(roll)/\(100 - threshold)")
			continue

		rollbonus = 0.0
		activated[e.function] = true

		if e.instant:
			print("[likho] event activated: \(e.name)")
			Callable(es, e.function).call()
		else:
			_delayed_call(es, e)


func _delayed_call(es, event) -> void:
	var delay = randi_range(10, 300)
	print("[likho] event activated: \(event.name) | Delay: %02d:%02d" % [floor(delay / 60.0), delay % 60])
	await es.get_tree().create_timer(delay, false).timeout
	Callable(es, event.function).call()


func on_fighter_jet_post() -> void:
	var es = _lib._caller
	if es == null:
		return
	_schedule_fighter_jet(es)


func _schedule_fighter_jet(es) -> void:
	var delay = randi_range(60, 300)
	print("[likho] FighterJet re-trigger scheduled | Delay: %02d:%02d" % [floor(delay / 60.0), delay % 60])
	await es.get_tree().create_timer(delay, false).timeout
	if !is_instance_valid(es):
		return
	Callable(es, "FighterJet").call()
