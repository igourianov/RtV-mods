# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Mods for the Godot game **Road to Vostok** (`config/name="Road to Vostok"`, version 0.2.0.0, Godot 4.6.3).

## Code guide

`CODE_GUIDE.md` at the repo root is a guide to code architecture, syntax rules, state machines, function/variable definitions and guards. Consult and follow it when authoring or reviewing state-driven `_process`/`_input` logic.

## Mods

Mods live at the repo root, one folder per mod. Can be identified by having `mod.txt` at the root of the mod folder.

* `likhos-config-manager/` (LCM) - library mod used by other mods to manage their settings.
* `likhos-vostac/` - tactical realism and weapon mechanics mod. Major game overhaul. Includes many features nd fixes. Also known as `VosTac`.
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
* `LightProbe.gd` - SubViewport that measures the light the renderer puts on a point of the world, read back asynchronously

mod-lib has it's own set of hooks and dependencies, that should be included with every mod and noted in the INSTRUCTIONS.md file.

## `src/` is the decompiled game (reference only, gitignored)

`src/` holds the extracted original project pulled from `RTV.pck` with GDRE Tools v2.5.0-beta.5 (see `src/gdre_export.log`). It is the authoritative reference for the game's scripts, scenes, resources and UIDs, but it is **not** part of this repo and must not be committed. Treat it as read-only when planning mod changes.

`src/` has it's own Git repo inside. ***DO NOT DELETE*** `src/.git` when regenerating source from compiled game.

Key facts when reading `src/`:
- Scripts are GDScript under `src/Scripts/` (e.g. `AI.gd`, `Actions.gd`, `AudioEvent.gd`).
- Autoloads defined in `src/project.godot`: `Loader`, `Database`, `Simulation` (all from `res://Resources/`).
- Global groups and other engine config live in `src/project.godot`.
- `.gd.uid` files are Godot's UID sidecars, keep them paired with their `.gd` when referenced.

### Reading source files
* Always ask permission to read .tscn files. They're huge - reading them burns ungodly amount of tokens.
* If you have to read them, and I give permission - grep them for specific lines instead fo reading whole file. 


### Regenerating source

GDRE numbers `ext_resource` ids sequentially, so one added resource renumbers every id and reference after it. `tools/normalize-src.js` rewrites each id to the resource uid and sorts the `ext_resource` block by path. Committed `src/` content is normalized this way.

* Run `node tools/normalize-src.js` after every decompile, before staging in `src/`. A fresh decompile is un-normalized again, so skipping the run produces a diff touching thousands of files.
* Running it on already normalized files changes nothing.
* This script is the only allowed way to modify files under `src/`.


## `vostok-mod-loader/` holds the loader source + docs (read-only reference)

A clone of the Metro Mod Loader repo lives at `vostok-mod-loader/`. This mod loader is what is used to inject mods into the game.

Built vostok-mod-loader lives in `<game>/modloader.gd` and it's API surface avilable via `RTVModLib` class. 

Summary instructions on using RTVModLib live in the `RTVModLib.md` file. Detailed instructions live under `vostok-mod-loader/docs/wiki/`.

Browse it (only after confirming with user) whenever the loader's behavior is unclear or when debugging an unfamiliar log line. Do not edit anything inside it.

## `MCM/` holds the Mod Configuration Menu source (read-only reference, gitignored)

`MCM/` is a clone of DoinkOink's MCM repo (`doinkoink-mcm`), the in-game config menu mods register settings with. It has its own Git repo inside and is not part of this repo.

Consult it when a mod integrates with MCM or when MCM behavior is unclear. `README.md` and `docs/` describe the API, `ExampleModConfig.gd` shows registration. Do not edit anything inside it.

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

`build.ps1` bumps the patch version in `mod.txt` on every build of a mod whose folder has uncommitted changes (`git status` not clean). A clean folder builds at its current version.

### `CHANGELOG.md`

Each mod has `<mod-id>/CHANGELOG.md`. It ships at the archive root and `publish.ps1` posts its new sections to Nexus.

Format:

```
# Unreleased
* new entry

# 2.1.40
* fixed batteries on the ground all taking the charge of the last battery dropped
```

* Sections are newest first. Each heading is `# ` followed by a version (`X.Y.Z`) or `Unreleased`. No other text in a heading.
* Entries are `* ` bullets, one line each. Do not hard wrap them.
* Write entries for players: what changed in game, not how the code changed. Start lowercase, no trailing period (match the existing file).
* Add new entries under a `# Unreleased` section at the top, creating it when absent. Use a specific version heading only when asked to.
* Edit an existing entry in place when the change only amends something not yet published, rather than adding a corrective entry.

### Publishing to Nexus

Publish only when asked. It uploads to a public mod page and cannot be undone from here.

Inputs:
* `nexus-api.key` at the repo root (personal Nexus API key), or `-ApiKey`.
* `publish.config.json`: `mods.<mod-id>` needs `mod_id` (from the mod page URL) and `file_id` (from the mod's file URL). Optional `category` (`main`, `optional`, `miscellaneous`, default `main`) and `update_mod_version` (default `true`).
* `build.config.json`: game dir, used to find `<game>/mods/<mod-id>.vmz`.

Steps:
1. Stamp the changelog. `publish.ps1` throws on any heading that is not a version, so rename `# Unreleased` to the next patch version: the current `mod.txt` version with patch + 1. The rename makes the folder dirty, so the next build bumps `mod.txt` to exactly that version.
2. `.\build.ps1 -Mod <mod-id>`. Confirm the printed `built: <mod-id> vX.Y.Z` matches the stamped heading.
3. `.\publish.ps1 -Mod <mod-id> -DryRun`. Check the version and the changelog text it would send.
4. `.\publish.ps1 -Mod <mod-id>`.

What `publish.ps1` does:
* Reads `id` and `version` from `mod.txt` inside the built `.vmz`, wraps the `.vmz` in `<mod-id>.zip` and uploads it as a new version of `file_id`. Uploads over 100 MiB are not supported.
* Refuses a version equal to or older than the live one on Nexus unless `-Force`.
* Archives the previous file version unless `-NoArchive`. Updates the mod page version unless `-NoBumpModVersion` or `update_mod_version: false`.
* Posts a Nexus changelog built from the repo's `<mod-id>/CHANGELOG.md` (not the archived copy): every section newer than the live version, up to and including the published version, merged into one list. Bullet markers and blank lines are dropped. A missing file or no new sections only gives a warning.
* `-Vmz <path>` publishes a given archive in place of the built one. `-Category` overrides the config category.

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


