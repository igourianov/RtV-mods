extends "../Lib/Main.gd"

const LCM := preload("./LCM.gd")
const ModMenu := preload("../Scenes/ModMenu.tscn")

# the size of MCM's own button, which sits in the corner 30px off the edges
const BUTTON_SIZE := Vector2(55, 55)
const BUTTON_MARGIN := Vector2(30, 30)
const BUTTON_GAP := 10


func setup(lib) -> void:
	register_hook("settings-_ready-post", _on_settings_ready_post)


# a lambda kept in static state past the scene tree crashes the engine on exit
func _exit_tree() -> void:
	LCM.mods.clear()


# the settings screen is its own instance in the main menu and in every map
func _on_settings_ready_post() -> void:
	var settings: Control = _lib._caller
	var menu := ModMenu.instantiate()
	menu.settings = settings
	settings.get_parent().add_child(menu)

	# MCM creates its button a frame later, so it cannot be looked up here.
	# Its autoload renames itself to this in _ready. With it loaded the corner slot is MCM's and ours is the next one to the left.
	var right := BUTTON_MARGIN.x
	if get_tree().root.has_node("MCM"):
		right += BUTTON_SIZE.x + BUTTON_GAP

	var button := Button.new()
	button.text = "LCM"
	button.tooltip_text = "Likho's Config Manager"
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -right - BUTTON_SIZE.x
	button.offset_right = -right
	button.offset_top = BUTTON_MARGIN.y
	button.offset_bottom = BUTTON_MARGIN.y + BUTTON_SIZE.y
	button.pressed.connect(menu.open)
	settings.add_child(button)
	# under the exit confirmation and the blocker that swallows clicks while the scene unloads
	settings.move_child(button, settings.get_node("Warning").get_index())
	# the exit confirmation replaces the options without hiding the screen itself
	var options: Control = settings.get_node("Settings")
	options.visibility_changed.connect(func() -> void: button.visible = options.visible)
