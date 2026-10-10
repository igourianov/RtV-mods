# Likho's Mod Config

A lightweight settings menu for mods. Every mod that supports it gets an entry in one list and its own settings page.

* Opens from the `LMC` button in the top right corner of the game's settings screen, in the main menu and in game.
* Changes take effect when you leave a mod's page or close the menu.
* `Reset` next to a setting restores its default.
* Settings are shared by all Mod Loader profiles.
* Runs next to Mod Configuration Menu (MCM). The two menus are separate and each lists its own mods.

Without this mod installed, mods that rely on it run on their default settings.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Hooks** (post, vanilla still runs):
- `Settings.gd`: `_ready`

## Install / Uninstall

Drop `likhos-mod-config.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-mod-config.vmz` from the `mods/` folder and relaunch the game.

## For mod authors

A mod describes its settings as a `Resource` with `@export` fields and registers it with one call. LMC builds the settings page from the fields, loads the player's saved values into the object and saves changes. The mod never deals with files.

LMC is an optional dependency. When it is not installed the config object keeps its default values.

### 1. Config script

`Scripts/Config.gd` in your mod:

```gdscript
extends Resource

@export var debug_enabled := false

@export_group("Movement")
@export_range(0.0, 20.0, 0.1) var walk_speed := 3.0
@export_enum("Hold", "Toggle") var aim_mode: String = "Hold"

# no @export, so it is not a setting
var current_weapon_weight := 0.0
```

- An `@export` field is a setting. Its initial value is the default.
- A field without `@export` is ignored by LMC and can hold runtime state.
- Settings appear in declaration order. `@export_group` starts a section with a header. Settings outside of any section are shown first, without a header.
- A setting's label is its field name turned into words: `walk_speed` shows as `Walk Speed`. There are no tooltips.

### 2. Config resource

`Config.tres` in your mod. The script path has to be the absolute path the mod has in game:

```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://mods/my-mod/Scripts/Config.gd" id="1"]

[resource]
script = ExtResource("1")
```

Every script that needs settings preloads this file and reads the fields directly. All of them get the same instance:

```gdscript
var config := preload("res://mods/my-mod/Config.tres")
```

Hold it in a `var`, not a `const`, if the script also writes to it.

### 3. Registration

```gdscript
const LMC_PATH := "res://mods/likhos-mod-config/Scripts/LMC.gd"

var config := preload("res://mods/my-mod/Config.tres")


func _ready() -> void:
	if ResourceLoader.exists(LMC_PATH):
		load(LMC_PATH).RegisterConfig("my-mod", "My Mod", config, _on_config_applied)


func _on_config_applied() -> void:
	pass
```

`RegisterConfig(mod_uid, mod_name, config, on_applied = Callable())`

- `mod_uid`: the mod's id from `mod.txt`. One registration per id.
- `mod_name`: the name shown in the menu.
- `config`: the config object. Its values at the time of the call are the defaults.
- `on_applied`: optional, takes no arguments. Called once during registration if the player has saved values, after they are written into the object. Called again every time the player changes settings in the menu. It is not called when there is nothing saved.

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
extends Resource

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

Reading them is plain field access on the preloaded object:

```gdscript
const Config := preload("res://mods/my-mod/Scripts/Config.gd")

var config := preload("res://mods/my-mod/Config.tres")


func _process(delta: float) -> void:
	if config.cant_mode == Config.CantMode.RAIL:
		position += config.weapon_offset * config.walk_speed * delta
```

### Good to know

- Values are written into the config object when the player leaves the mod's page or closes the menu, not while a control is being moved.
- Only values that differ from the default are saved. A default you change in an update reaches every player who has not changed that setting.
- A saved value is dropped when its field is removed or changes its type.
- Key bindings are not supported.
