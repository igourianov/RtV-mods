# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Mods for the Godot game **Road to Vostok** (`config/name="Road to Vostok"`, version 0.1.1.3, Godot 4.6.2). Each top-level directory at the repo root (e.g. `ammo-check-fix/`) is an individual mod.

## `src/` is the decompiled game (reference only, gitignored)

`src/` holds the extracted original project pulled from `RTV.pck` with GDRE Tools v2.5.0-beta.5 (see `src/gdre_export.log`). It is the authoritative reference for the game's scripts, scenes, resources and UIDs, but it is **not** part of this repo and must not be committed. Treat it as read-only when planning mod changes.

Key facts when reading `src/`:
- Scripts are GDScript under `src/Scripts/` (e.g. `AI.gd`, `Actions.gd`, `AudioEvent.gd`).
- Autoloads defined in `src/project.godot`: `Loader`, `Database`, `Simulation` (all from `res://Resources/`).
- Global groups and other engine config live in `src/project.godot`.
- `.gd.uid` files are Godot's UID sidecars, keep them paired with their `.gd` when referenced.

## Working on a mod

Mods live at the repo root, one folder per mod. When modifying behavior, first locate the relevant script/scene in `src/` to understand the original implementation, then author the mod files at the root. Do not edit files under `src/`.

## Mod structure

Each mod folder is the zippable tree: its contents are what goes at the root of the distributed `.zip` / `.vmz`. Required layout:

```
<mod-id>/                       ← repo root folder = zip root
├── mod.txt                     ← MUST be at archive root
└── mods/
    └── <mod-id>/               ← namespace to avoid collisions
        ├── Main.gd             ← autoload entry point (registers overrides)
        └── <OverrideScript>.gd ← extends "res://Scripts/<Original>.gd"
```

The `id` in `mod.txt` must match the `mods/<mod-id>/` folder name and use only `a-z`, `-`, `_`.

### `mod.txt` (Godot ConfigFile / INI)

```
[mod]
name="Display Name"
id="my-mod-id"
version="1.0.0"
priority=0                      ; optional, higher loads later

[autoload]
MyModMain="res://mods/my-mod-id/Main.gd"
```

### Script override pattern (`take_over_path`)

Use this to change behavior of an existing game script. The override file extends the game script by path, and `Main.gd` rebinds the original `res://` path to the override at runtime.

`mods/<mod-id>/Main.gd`:

```gdscript
extends Node


func _ready():
    overrideScript("res://mods/<mod-id>/<OverrideScript>.gd")
    queue_free()


func overrideScript(path: String):
    var script: Script = load(path)
    script.reload()
    var parent = script.get_base_script()
    script.take_over_path(parent.resource_path)
```

`mods/<mod-id>/<OverrideScript>.gd`:

```gdscript
extends "res://Scripts/<Original>.gd"


func SomeMethod():
    # ... pre-hook logic ...
    await super()      # call original; use plain super() for non-async methods
    # ... post-hook logic ...
```

Rules and caveats:
- **Extend by path, not by `class_name`.** Use `extends "res://Scripts/Foo.gd"`, never `extends Foo`. `class_name` resolution is unreliable from a mod.
- **Call `super()`** in overridden methods to preserve the original behavior and keep chaining compatibility with other mods. Skipping `super()` is flagged by the loader as `NO SUPER`. Only replace the body entirely when the fix is incompatible with running the original.
- **Async methods:** if the original uses `await`, use `await super()` to wait for it to complete before running post-hook logic.
- **`class_name` scripts can only be overridden by one mod at a time.** Overriding the same `class_name` script from multiple mods triggers a Godot 4 crash (bug #83542). Game scripts like `WeaponRig` (`class_name WeaponRig`) are affected.
- **Cannot redefine parent variables, constants or `_init`** reliably. Add new fields/methods in the override, don't re-declare existing ones.
- **Preloaded scripts cannot be overridden.** If a script is loaded via `preload(...)` it is cached before `take_over_path` runs.
- **Forward slashes in paths.** Zipping with Windows tools that emit backslashes (e.g. some Explorer zips) causes silent load failures; prefer 7-Zip.

### Other mod techniques (reference)

- **Asset replacement:** drop a file at the matching `res://` path inside `mods/<mod-id>/` (or at the original path for direct replacement). No code needed.
- **Autoload-only mods:** declare entries under `[autoload]` in `mod.txt` without any `take_over_path` call, for background systems, overlays or keybinds.
- **Custom scenes (`.tscn`):** require a `.godot/exported/` folder in the archive; export with Godot's Project > Export > Export PCK/Zip.
- **Runtime data:** read mod-shipped files with `FileAccess.open("res://mods/<mod-id>/data.json", ...)`; persist user state under `user://`.

Reference wiki: https://github.com/ametrocavich/vostok-modding-wiki/wiki
