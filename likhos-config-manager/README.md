# Likho's Config Manager

A lightweight settings menu for mods. Meant to serve as a replacement for MCM.

## Features

* Clean API with minimal footprint for mod makers. No pages of crude metadata required.
* Clean, transparent config files, that save only values and only if they deviate from defaults, making migrations a breeze.
* Opens from the `LCM` button in the top right corner of the game's settings screen (placed next to MCM button).

Without this mod installed, mods that rely on it run on their default settings.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Hooks** (post, vanilla still runs):
- `Settings.gd`: `_ready`

## Install / Uninstall

Drop `likhos-config-manager.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-config-manager.vmz` from the `mods/` folder and relaunch the game.

## For mod authors

A mod describes its settings as a class with `@export` fields and registers an instance of it with one call. LCM builds the settings page from the fields, loads the player's saved values into the object and saves changes. The mod never deals with files.

LCM is an optional dependency. When it is not installed the config object keeps its default values.

### 1. Define config class

`Scripts/Config.gd` (could be any name/location you choose) in your mod:

```gdscript
extends RefCounted

@export var debug_enabled := false

@export_group("Movement")
@export_range(0.0, 20.0, 0.1) var walk_speed := 3.0
@export_enum("Hold", "Toggle") var aim_mode: String = "Hold"

# no @export, so it is not a setting
var current_weapon_weight := 0.0
```

- An `@export` field is a setting. Its initial value is the default.
- A field without `@export` is ignored by LCM and can hold runtime state.
- Settings appear in declaration order. `@export_group` starts a section with a header. Settings outside of any section are shown first, without a header.
- A setting's label is its field name with underscores turned into spaces and the first letter capitalized. The rest keeps the field's capitalization: `walk_speed` shows as `Walk speed` and `NVG_blur` shows as `NVG blur`. Write abbreviations in capitals in the field name. There are no tooltips.

### 2. Set up shared instance

LCM works on a singleton of the above class. Every script that reads settings has to read that same instance. There are three ways to get there. **PICK ONE**.

**A. Create it and pass it everywhere.**

Works best for simple, single file mods.

```gdscript
const Config := preload("./Config.gd")

var config := Config.new()
var myModHook := MyModHook.new(config)
```

**B. A classic singleton.** Best for multi-file, mostly-code mods.

```gdscript
# in Config.gd
extends RefCounted

static var instance := new()

@export var debug_enabled := false
```

```gdscript
# anywhere else
const Config := preload("./Config.gd")


func _process(delta: float) -> void:
	position.x += Config.instance.walk_speed * delta
```

**C. A `.tres` resource.** Best if your mod already manages various resources.

The same way the game shares its own `GameData`. This is the only option that needs the config class to be a resource, since a `.tres` cannot hold anything else. Declare it with `extends Resource` instead of `extends RefCounted`. Everything else about the class stays the same.

`Config.tres` in your mod, with the script path being the absolute path the mod has in game:

```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://mods/my-mod/Scripts/Config.gd" id="1"]

[resource]
script = ExtResource("1")
```

Every script preloads this file and gets the same instance:

```gdscript
var config := preload("res://mods/my-mod/Config.tres")
```

Hold it in a `var`, not a `const`, if the script also writes to it. A value saved in the `.tres` replaces the default written in the script.

### 3. Registration

Pass the instance from step 2, whichever way you made it:

```gdscript
const LCM_PATH := "res://mods/likhos-config-manager/Scripts/LCM.gd"
const Config := preload("./Config.gd")

var config := Config.new()


func _ready() -> void:
	if ResourceLoader.exists(LCM_PATH):
		load(LCM_PATH).register_config("my-mod", "My Mod", config, _on_config_applied)


func _on_config_applied() -> void:
	# you only need this is config changes need to perform immediate action
	# ignore if your mod simply reads settings from the config object
```

`register_config(mod_uid, mod_name, config, on_applied = Callable()) -> bool`

Returns `true` when the config is registered. Returns `false` and logs a warning when the uid is invalid.

- `mod_uid`: the mod's id from `mod.txt`. Can only contain `a-z`, `0-9`, `-` and `_`. Registering again under the same id replaces the earlier config and logs a warning.
- `mod_name`: the name shown in the menu.
- `config`: the config object. Its values at the time of the call are the defaults.
- `on_applied`: optional, takes no arguments. Called once during registration if the player has saved values, after they are written into the object. Called again every time the player changes settings in the menu. It is not called when there is nothing saved.

A mod that reads its settings straight from the config object needs no callback. Leave the argument out:

```gdscript
load(LCM_PATH).register_config("my-mod", "My Mod", config)
```

`Callable()` in its place does the same. `null` is not accepted and fails the call.

Registration can happen at any point of startup. It does not depend on mod load order.

### Supported fields

| Field | Shown as |
|---|---|
| `bool` | Off and On buttons |
| `int`, `float` with `@export_range(min, max, step)` | Slider with a number box |
| `int`, `float` without a range | Number box |
| `String` | Text box |
| `String` or `int` with `@export_enum`, or a field typed as an enum of the script | Dropdown |
| `Color` | Color picker |
| `Vector2`, `Vector3` | A number box per component |

A field of any other type is skipped with a warning in the log.

One example per kind of row:

```gdscript
extends RefCounted

enum CantMode { DEFAULT, RAIL, OFF }

# Off and On buttons
@export var show_crosshair := true

# slider from 0 to 20 in steps of 0.1
@export_range(0.0, 20.0, 0.1) var walk_speed := 3.0

# slider over whole numbers from 1 to 10
@export_range(1, 10) var max_cards := 4

# number boxes that take any value
@export var recoil_scale := 1.5
@export var kill_limit := 100

# text box
@export var player_tag := "Likho"

# dropdown that stores the text of the option
@export_enum("Cross", "Dot", "None") var crosshair_style: String = "Dot"

# dropdown that stores the position of the option: 0 for Low, 1 for High
@export_enum("Low", "High") var quality: int = 1

# dropdown that stores the number given after the colon
@export_enum("Slow:30", "Average:60", "Fast:200") var tick_rate: int = 60

# dropdown over an enum of the script, listed as Default, Rail and Off
@export var cant_mode: CantMode = CantMode.RAIL

# color picker
@export var crosshair_color := Color(0, 1, 0.04, 0.55)

# a number box per component
@export var hud_offset := Vector2(16, 24)
@export var weapon_offset := Vector3(0.1, -0.2, 0.3)
```

Reading them is plain field access on the config object, here with the static holder from step 2:

```gdscript
const Config := preload("res://mods/my-mod/Scripts/Config.gd")

var config := Config.instance


func _process(delta: float) -> void:
	if config.cant_mode == Config.CantMode.RAIL:
		position += config.weapon_offset * config.walk_speed * delta
```

### Good to know

- Values are written into the config object when the player leaves the mod's page or closes the menu, not while a control is being moved.
- Only values that differ from the default are saved. A default you change in an update reaches every player who has not changed that setting.
- A saved value is ignored when its field is removed or changes its type. Dropped on next save.
- Key bindings are not supported.
- The config object is yours. LCM keeps a reference to it for as long as the game runs and never frees or replaces it.
