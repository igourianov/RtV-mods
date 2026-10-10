extends "../Lib/Main.gd"

const LMC := preload("./LMC.gd")
const ModMenu := preload("./ModMenu.gd")

const BUTTON_SIZE := Vector2(170, 40)
# clears the corner MCM puts its own 55px button in, 30px off the edges
const BUTTON_MARGIN := Vector2(95, 30)


func setup(lib) -> void:
	register_hook("settings-_ready-post", _on_settings_ready_post)


# a lambda kept in static state past the scene tree crashes the engine on exit
func _exit_tree() -> void:
	LMC.mods.clear()


# the settings screen is its own instance in the main menu and in every map
func _on_settings_ready_post() -> void:
	var settings: Control = _lib._caller
	var menu := ModMenu.new(settings)
	settings.get_parent().add_child(menu)

	var button := Button.new()
	button.text = "Mod Config"
	button.tooltip_text = "Likho's Mod Config"
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -BUTTON_MARGIN.x - BUTTON_SIZE.x
	button.offset_right = -BUTTON_MARGIN.x
	button.offset_top = BUTTON_MARGIN.y
	button.offset_bottom = BUTTON_MARGIN.y + BUTTON_SIZE.y
	button.pressed.connect(menu.open)
	settings.add_child(button)
	# under the exit confirmation and the blocker that swallows clicks while the scene unloads
	settings.move_child(button, settings.get_node("Warning").get_index())
	# the exit confirmation replaces the options without hiding the screen itself
	var options: Control = settings.get_node("Settings")
	options.visibility_changed.connect(func() -> void: button.visible = options.visible)
