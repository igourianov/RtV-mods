# Likho's Config Manager

A lightweight settings menu for mods. A simpler alternative to MCM for mod authors.

## Features

- Clean API with minimal footprint for mod makers. No pages of crude metadata required.
- Config files store only the values that differ from the defaults. This keeps migrations simple.
- Opens from the `LCM` button in the top right corner of the game's settings screen (placed next to the MCM button).
- The settings UI mimics the MCM screen (credit to Doink), but the implementation is entirely different.

Without this mod installed, mods that rely on it run on their default settings.

Settings are saved per mod in `%APPDATA%\Road to Vostok\LCM\<mod-id>.cfg`.

Every MML profile has its own section in the settings file. A new profile starts on the defaults.

```ini
[Default]
walk_speed=3.5

[Tester]
walk_speed=2.0
aim_mode=Toggle
```

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later

## Usage (for mod authors)

The consuming mod describes its settings as a class with `@export` fields and registers its instance with one call. LCM builds the settings page from the fields, loads the player's saved values into the object and saves changes. The consuming mod never has to deal with config files or MML profiles or additional metadata.

### 1. Define config class

`Scripts/Config.gd` (could be any name/location you choose) in your mod:

```gdscript
extends RefCounted

@export var debug_enabled := false

@export_group("Movement")
@export_range(0.0, 20.0, 0.1) var walk_speed := 3.0
@export_enum("Hold", "Toggle") var aim_mode: String = "Hold"

# no @export - ignored by LCM
var current_weapon_weight := 0.0
```

- The `@export` hint marks a field as a setting. Its initial value is the default.
- A field without `@export` is ignored by LCM and can hold runtime state.
- Settings appear in declaration order. `@export_group` starts a section with a header. Settings outside any section are shown first, without a header.
- A setting's label is derived from the field name. Example: `walk_speed` shows as `Walk speed` and `NVG_blur` shows as `NVG blur`.

### 2. Set up shared instance

Your mod should use a singleton of the above class. Every script that reads settings has to read that same instance. This can be done by adding a static instance to the config class:

```gdscript
# in Config.gd
extends RefCounted

static var instance := new()

@export var walk_speed := 3.0
```

Any other script gets the same object by preloading the class:

```gdscript
# anywhere else
const config := preload("./Config.gd").instance

func _process(delta: float) -> void:
	position.x += config.walk_speed * delta
```

### 3. Registration

Load LCM and pass it the instance from step 2. Registration can happen at any point during startup. It does not depend on mod load order.

Always check the loaded script with `is_instance_valid` before calling it. When LCM is not installed, `load()` returns `null`, and calling `register_config` on that `null` crashes the script.

```gdscript
# in Main.gd
var config := preload("./Config.gd").instance
var LCM = load("res://mods/likhos-config-manager/Scripts/LCM.gd") # will print error and return null if not installed

func _ready() -> void:
	if is_instance_valid(LCM):
		LCM.register_config("my-mod-id", "My Mod Name", config)
```

A mod that reads its settings straight from the config object needs nothing more. This is the default case.

#### Reacting to changes (special case)

Pass a callback only when config changes need to trigger an immediate action, such as rebuilding a UI element or copying new values somewhere:

```gdscript
const config := preload("./Config.gd").instance

func _ready() -> void:
	if is_instance_valid(LCM):
		LCM.register_config("my-mod-id", "My Mod Name", config, _on_config_applied)

func _on_config_applied() -> void:
	# act on the new settings
```

### API surface

```gdscript
register_config(mod_uid, mod_name, config, on_applied = Callable()) -> bool
```

Returns `true` when the config is registered. Returns `false` and logs a warning when the id is invalid.

- `mod_uid`: Unique mod identifier. Also names the config file, `<mod_uid>.cfg`. Can only contain `a-z`, `0-9`, `-` and `_`. Registering again under the same id replaces the earlier config and logs a warning.
- `mod_name`: The name shown in the menu. Purely cosmetic.
- `config`: The config object defined above. Its values at the time of the call become the defaults.
- `on_applied`: Optional callback, takes no arguments. Called once during registration, after saved values are written into the object. This happens only if the active mod loader profile has saved values. Called again every time the player changes settings in the menu.

### Supported fields

| Field | Shown as |
|---|---|
| `bool` | Off and On buttons |
| `int`, `float` | Number box |
| `int`, `float` with `@export_range(min, max, step)` | Slider with a number box |
| `String` | Text box |
| `String` or `int` with `@export_enum` or `enum` type | Dropdown |
| `Color` | Color picker |
| `Vector2`, `Vector3` | A number box per component |
| `Vector2`, `Vector3` with `@export_custom(PROPERTY_HINT_RANGE, "min,max,step")` | A limited number box per component |

A field of any other type is skipped with a warning in the log.

Note that GDScript does not support `@export_range` hint on `Vector2` or `Vector3` fields. Use `@export_custom(PROPERTY_HINT_RANGE, "min,max,step")` hint to apply its range to every component.

One example per kind of row:

```gdscript
extends RefCounted

# Off and On buttons
@export var show_crosshair := true

# number boxes that take any value
@export var kill_limit := 100
@export var recoil_scale := 1.5

# slider over whole numbers from 1 to 10
@export_range(1, 10) var max_cards := 4

# slider from 0 to 20 in steps of 0.1
@export_range(0.0, 20.0, 0.1) var walk_speed := 3.0

# text box
@export var player_tag := "Likho"

# dropdown over an enum of the script, listed as Default, Rail and Off
enum CantMode { DEFAULT, RAIL, OFF }
@export var cant_mode: CantMode = CantMode.RAIL

# dropdown that stores the text of the option
@export_enum("Cross", "Dot", "None") var crosshair_style: String = "Dot"

# dropdown that stores the index of the option: 0 for Low, 1 for High
@export_enum("Low", "High") var quality: int = 1

# dropdown that stores the number given after the colon
@export_enum("Slow:30", "Average:60", "Fast:200") var tick_rate: int = 60

# color picker
@export var crosshair_color := Color(0, 1, 0.04, 0.55)

# a number box per component
@export var hud_offset := Vector2(16, 24)
@export var weapon_offset := Vector3(0.1, -0.2, 0.3)

# a number box per component, each limited from -1 to 1 in steps of 0.05
# GDScript does not accept @export_range on a vector, so the range goes through @export_custom
@export_custom(PROPERTY_HINT_RANGE, "-1,1,0.05") var sway_scale := Vector2(0.2, 0.1)
```

### Good to know

- Values are written into the config object when the player leaves the mod's page or closes the menu, not while a control is being moved.
- Only values that differ from the default are saved. A default you change in an update reaches every player who has not changed that setting.
- A saved value is ignored when its field is removed or changes its type. A value of a changed type is replaced on the next save. A value of a removed field stays in the file, unused.
- Values are saved per mod loader profile. A profile without saved values runs on your defaults and never takes values from another profile.
- The config object is yours. LCM keeps a reference to it for as long as the game runs and never frees or replaces it.
