extends RefCounted

var _lib
var _config

var extraActions = [
	{
		"name": "optic_zoom_in",
		"label": "Optic Zoom In",
		"button_index": MOUSE_BUTTON_WHEEL_UP,
	},
	{
		"name": "optic_zoom_out",
		"label": "Optic Zoom Out",
		"button_index": MOUSE_BUTTON_WHEEL_DOWN,
	}
]


func _init(lib, config) -> void:
	_lib = lib
	_config = config


func on_create_actions_post() -> void:
	attach_extra_actions(_lib._caller, false)

func on_reset_actions_post() -> void:
	attach_extra_actions(_lib._caller, true)


func attach_extra_actions(caller, reset: bool) -> void:
	var savedEvents = caller.preferences.actionEvents if caller.preferences else null

	for a in extraActions:
		if !InputMap.has_action(a.name):
			InputMap.add_action(a.name)
		else:
			InputMap.action_erase_events(a.name)

		var event = savedEvents[a.name] if savedEvents else null
		if reset || !event:
			event = InputEventMouseButton.new()
			event.button_index = a.button_index
			event.pressed = true
			#print(_config.PREFIX, "new event: ", event, " | as_text: ", event.as_text())

		InputMap.action_add_event(a.name, event)
		_create_input_button(caller, a.name, a.label, event)


func _create_input_button(caller, name, label, event) -> void:
	var button = caller.remapButton.instantiate()
	caller.actions.add_child(button)
	button.pressed.connect(caller._on_input_pressed.bind(button, name))

	var actionLabel = button.find_child("LabelAction")
	actionLabel.text = label

	var inputLabel = button.find_child("LabelInput")
	inputLabel.text = event.as_text().trim_suffix("- Physical") if event else "[unbound]"