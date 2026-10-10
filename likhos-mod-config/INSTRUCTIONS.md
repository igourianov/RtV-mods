# Likho's Mod Config: instructions for mod authors

A mod describes its settings as a `Resource` with `@export` fields and registers it with one call. LMC builds the settings page from the fields, loads the player's saved values into the object and saves changes. The mod never deals with files or Mod Loader profiles.

## Prerequisites

- Metro Mod Loader v3.4.1 or later.
- LMC is an optional dependency. When it is not installed the config object keeps its default values.

## 1. Config script

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
- Settings appear in declaration order. `@export_group` starts a section.
- A setting's label is its field name turned into words: `walk_speed` shows as `Walk Speed`. There are no tooltips.

## 2. Config resource

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

## 3. Registration

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

### With mod-lib

A `Main.gd` that extends `Lib/Main.gd` overrides two methods instead:

```gdscript
extends "../Lib/Main.gd"

var config := preload("../Config.tres")


func get_config() -> Resource:
	return config


func config_applied() -> void:
	pass
```

A mod that returns a config object from `get_config()` does not go through `create_config` and `load_config`.

## Supported fields

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

## Good to know

- Values are written into the config object when the player leaves the mod's page or closes the menu, not while a control is being moved.
- Only values that differ from the default are saved. A default you change in an update reaches every player who has not changed that setting.
- A saved value is dropped when its field is removed or changes its type.
- Key bindings are not supported.

## Hooks

LMC itself hooks `Settings.gd`: `_ready` (post) to put its button on the settings screen.
