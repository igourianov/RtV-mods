# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Mods for the Godot game **Road to Vostok** (`config/name="Road to Vostok"`, version 0.1.1.3, Godot 4.6.2).

## Syntax rules

* When writing boolean operations - use C-type operators
* Use colon for dictionary {"key": "value"} pairs 
* Enforce two empty lines befween functions
* Enforce Tab identation
* Use `!obj` style for `null` checks instead of `obj == null`
* Do not mix `elif` condition trees with early returns - pick one approach

## Mods

Mods live at the repo root, one folder per mod. Can be identified by having `mod.txt` at the root of the mod folder.

* `likhos-weapon-handling-fixes/` - tactical realism and weapon mechanics mod. Major game overhaul. Includes many features nd fixes. Also known as `VosTac`.
* `likhos-magdump/` - small mod for magazine compatibility between different rifles
* `likhos-eventuality/` - small mod affecting in-game dynamic events. Fxes event probability and provides small enhancements.
* `likhos-second-hand/` - small mod for enabling several guns tobe equipped as in the secondary slot, reduces their render scale 
* `likhos-keymod/` - micro mod that adds loot room keys to the traders
* `likhos-tacmed/` - mod that overhauls functionality of the advanced medical items

When modifying behavior, first locate the relevant script/scene in `src/` to understand the original implementation, then author the mod files at the root. Do not edit files under `src/`.

## Mods lib

`mod-lib/` is a base library containing useful utilities and base classes. Distributed with every mod as `mods/<mod-id>/Lib/` (sibling of Scripts) by the build process.

* `Main.gd` - base class for mod Main's, contains additional hooks
* `Out.gd` - class for printing debug and warning statements in normalized way
* `Inputs.gd` - class to control in-game action bindings

mod-lib has it's own set of hooks and dependencies, that should be included with every mod and noted in the INSTRUCTIONS.md file.

## `src/` is the decompiled game (reference only, gitignored)

`src/` holds the extracted original project pulled from `RTV.pck` with GDRE Tools v2.5.0-beta.5 (see `src/gdre_export.log`). It is the authoritative reference for the game's scripts, scenes, resources and UIDs, but it is **not** part of this repo and must not be committed. Treat it as read-only when planning mod changes.

Key facts when reading `src/`:
- Scripts are GDScript under `src/Scripts/` (e.g. `AI.gd`, `Actions.gd`, `AudioEvent.gd`).
- Autoloads defined in `src/project.godot`: `Loader`, `Database`, `Simulation` (all from `res://Resources/`).
- Global groups and other engine config live in `src/project.godot`.
- `.gd.uid` files are Godot's UID sidecars, keep them paired with their `.gd` when referenced.

### Reading source files
* Always ask permission to read .tscn files. They're huge - reading them burns ungodly amount of tokens.
* If you have to read them, and I give permission - grep them for specific lines instead fo reading whole file. 


## `vostok-mod-loader/` holds the loader source + docs (read-only reference)

A clone of the Metro Mod Loader repo lives at `vostok-mod-loader/`. This mod loader is what is used to inject mods into the game.

Built vostok-mod-loader lives in `<game>/modloader.gd` and it's API surface avilable via `RTVModLib` class. 

Summary instructions on using RTVModLib live in the `RTVModLib.md` file. Detailed instructions live under `vostok-mod-loader/docs/wiki/`.

Browse it (only after confirming with user) whenever the loader's behavior is unclear or when debugging an unfamiliar log line. Do not edit anything inside it.

## Mod structure

Each mod folder is the zippable tree. Source layout in this repo:

```
<mod-id>/                       ← repo root folder
├── mod.txt                     ← shipped at archive root
├── README.md                   ← optional, shipped at archive root (user friendly description of what mod does)
├── INSTRUCTIONS.md             ← optional, shipped at archive root (more technical description - covers prerequisites and compatibility, including hooks)
└── Scripts/                    ← namespaced mod scripts
    ├── Main.gd                 ← autoload entry point (registers overrides)
    └── <OverrideScript>.gd     ← extends "res://Scripts/<Original>.gd" - mapped to `src/Scripts/<Original>.gd`
```

`build.ps1` ships `mod.txt` and `README.md` at the archive root and packages everything else under `mods/<mod-id>/` preserving relative paths, so `Scripts/Main.gd` becomes `mods/<mod-id>/Scripts/Main.gd` in the archive and resolves at runtime as `res://mods/<mod-id>/Scripts/Main.gd`. The `id` in `mod.txt` must match the source folder name and use only `a-z`, `-`, `_`.

### `mod.txt` (Godot ConfigFile / INI)

```
[mod]
name="Display Name"
id="my-mod-id"
version="1.0.0"
priority=0                      ; optional, higher loads later

[autoload]
MyModMain="res://mods/my-mod-id/Scripts/Main.gd"
```

Do not modify mod version property unless specifically requested to do so. Build process does it automatically.

### Debugging

Runtime log lives at `%APPDATA%\Road to Vostok\logs\godot.log` (plus session-stamped rolls in the same folder). `print()` in mod scripts lands there. Useful greps:

- `[ModLoader][Info] Found N mod(s)` confirms discovery.
- `[script_extend] res://... -> res://mods/...` confirms the override mapping parsed.
- `[OverrideVerify]` lines confirm the take-over actually happened post-autoload.
- `No user opt-in declarations` means you shipped a mod with no `[script_extend]` / `[hooks]` / `[registry]` / `.hook()` and no overrides will apply.
- `[RTVCodegen]` lines trace hook pack generation.
- `[ModScan]` lines flag suspicious code patterns (security scanner; informational, never blocks loading).

Mount cache (unpacked `.vmz`s) is at `%APPDATA%\Road to Vostok\vmz_mount_cache\` - handy for verifying what actually got deployed. Hook pack at `%APPDATA%\Road to Vostok\modloader_hooks\framework_pack.zip` is the generated rewrite; vanilla source cache lives next to it under `vanilla/`.

When a behavior is unclear, grep `vostok-mod-loader/src/` for the log string or symptom; the wiki cites source line numbers for every claim.


