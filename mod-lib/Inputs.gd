extends RefCounted

var _lib

var extra_actions := []
var remove_actions := []


func _init(lib) -> void:
	_lib = lib


func on_create_actions_pre():
	for a in remove_actions:
		_lib._caller.inputs.erase(a)
		

func on_create_actions_post() -> void:
	attach_extra_actions(_lib._caller, false)


func on_reset_actions_post() -> void:
	attach_extra_actions(_lib._caller, true)


func attach_extra_actions(caller: Node, reset: bool) -> void:
	var savedEvents = caller.preferences.actionEvents if caller.preferences else null

	for a in extra_actions:
		if !InputMap.has_action(a.action):
			InputMap.add_action(a.action)
		else:
			InputMap.action_erase_events(a.action)

		if reset:
			savedEvents.erase(a.action)

		var event: InputEvent = savedEvents.get(a.action) if savedEvents else null
		if !event && a.event:
			# a default that names another action takes that action's binding as it is now
			event = a.event if a.event is InputEvent else InputMap.action_get_events(a.event)[0]

		if event:
			InputMap.action_add_event(a.action, event)
		if a.label:
			_create_input_button(caller, a.action, a.label, event)

	# vanilla saved its reset before this ran, and it leaves the bindings of the extra actions in place
	if reset:
		caller.preferences.Save()


func _create_input_button(caller: Node, name: String, label: String, event: InputEvent) -> void:
	var button: Button = caller.remapButton.instantiate()
	caller.actions.add_child(button)
	button.pressed.connect(caller._on_input_pressed.bind(button, name))

	var actionLabel: Label = button.find_child("LabelAction")
	actionLabel.text = label

	var inputLabel: Label = button.find_child("LabelInput")
	inputLabel.text = event.as_text().trim_suffix("- Physical") if event else "[unbound]"


static func get_binding(action: StringName) -> String:
	var events = InputMap.action_get_events(action)
	if !events || events.is_empty():
		return "[unbound]"
	return events[0].as_text().trim_suffix("- Physical")

