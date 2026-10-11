extends Node

const LCM := preload("./LCM.gd")
const Out := preload("./Out.gd")
const ModMenu := preload("../Scenes/ModMenu.tscn")

# the size of MCM's own button, which sits in the corner 30px off the edges
const BUTTON_SIZE := Vector2(55, 55)
const BUTTON_MARGIN := Vector2(30, 30)
const BUTTON_GAP := 10
# narrower than the button, so the icon keeps clear of its left and right edges
const BUTTON_ICON_WIDTH := 45
# shipped without an .import file, so it is read as a raw image instead of a resource
const BUTTON_ICON := "../Textures/lcm_icon.png"


var _lib


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib", null)
	if _lib == null:
		Out.warning("RTVModLib not available")
		return

	await _lib.frameworks_ready
	if _lib.hook("settings-_ready-post", _on_settings_ready_post) < 0:
		Out.warning("failed to hook the settings screen, the LCM button is unavailable")
		return
	Out.debug("settings screen hooked")


# a lambda kept in static state past the scene tree crashes the engine on exit
func _exit_tree() -> void:
	LCM._mods.clear()


# the settings screen is its own instance in the main menu and in every map
func _on_settings_ready_post() -> void:
	var settings: Control = _lib._caller
	# In a map the settings screen fills the UI root, so the menu replaces the screen itself.
	# In the main menu it sits in a zero size node at the screen centre, next to a header and a return button, so the menu replaces that whole node.
	# Either way the parent of what is replaced is a full screen control.
	var in_main_menu: bool = settings.gameData.menu
	var screen: Control = settings.get_parent() if in_main_menu else settings
	var root: Control = screen.get_parent()
	var menu := ModMenu.instantiate()
	menu.settings = settings
	menu.screen = screen
	root.add_child(menu)

	# MCM creates its button a frame later, so it cannot be looked up here.
	# Its autoload renames itself to this in _ready. With it loaded the corner slot is MCM's and ours is the next one to the left.
	var right := BUTTON_MARGIN.x
	if get_tree().root.has_node("MCM"):
		right += BUTTON_SIZE.x + BUTTON_GAP

	var button := Button.new()
	var icon_path: String = get_script().resource_path.get_base_dir().path_join(BUTTON_ICON).simplify_path()
	button.icon = ImageTexture.create_from_image(Image.load_from_file(icon_path))
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", BUTTON_ICON_WIDTH)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = "Likho's Config Manager"
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -right - BUTTON_SIZE.x
	button.offset_right = -right
	button.offset_top = BUTTON_MARGIN.y
	button.offset_bottom = BUTTON_MARGIN.y + BUTTON_SIZE.y
	button.pressed.connect(menu.open)
	if in_main_menu:
		# the settings screen has no corner there and is scaled down
		root.add_child(button)
	else:
		settings.add_child(button)
		# under the exit confirmation and the blocker that swallows clicks while the scene unloads
		settings.move_child(button, settings.get_node("Warning").get_index())
	# The exit confirmation replaces the options without hiding the screen itself.
	# In the main menu the button is outside the screen, so it does not hide with it either.
	var options: Control = settings.get_node("Settings")
	button.visible = options.is_visible_in_tree()
	options.visibility_changed.connect(func() -> void: button.visible = options.is_visible_in_tree())
