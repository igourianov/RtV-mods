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

Each mod folder is the zippable tree. Source layout in this repo:

```
<mod-id>/                       ← repo root folder
├── mod.txt                     ← shipped at archive root
├── README.md                   ← optional, shipped at archive root
└── Scripts/                    ← namespaced mod scripts
    ├── Main.gd                 ← autoload entry point (registers overrides)
    └── <OverrideScript>.gd     ← extends "res://Scripts/<Original>.gd"
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

### Script override pattern (`[hooks]` + RTVModLib)

The installed loader is **Metro Mod Loader v3.0.1** (`<game>/modloader.gd`). Despite what the community wiki documents, neither the autoload + `take_over_path` pattern nor `[script_extend]` reliably overrides game scripts. Here's why:

Game autoloads (`Database`, `Loader`, `Simulation`) do module-scope `const Makarov_Rig = preload(...)` on every weapon scene, knife, fishing rod, etc. Those preloads resolve each scene's ext_resource script references at parse time. Any later `take_over_path("res://Scripts/WeaponRig.gd")` updates the `res://` cache for *future* `load()` calls but **does not** alter the preloaded scenes' already-bound Resource references. So override methods declared that way never fire for preloaded weapons. `[script_extend]` hits this same problem; the loader logs `No user opt-in declarations` to flag it.

The working pattern uses the loader's **hook codegen** instead. At static init (before any game autoload runs), the loader mounts a generated "hook pack" that rewrites each declared vanilla method into a dispatch wrapper. The wrapper looks up registered callbacks on `Engine.get_meta("RTVModLib")` and routes to them. Preloaded scenes bind to the wrapped vanilla, so hook callbacks fire on every instance.

Two things need to line up:

1. `mod.txt` must declare `[hooks]` so the codegen wraps the target method.
2. A mod autoload must call `RTVModLib.hook("<stem>-<method>", callback)` at `_ready()` to register the actual behavior. The stem is the lowercase filename without `.gd` (e.g. `"weaponrig"`); method name is the original casing.

`mod.txt`:

```
[mod]
name="My Mod"
id="my-mod-id"
version="1.0.0"

[hooks]
"res://Scripts/WeaponRig.gd"="AmmoCheck"

[autoload]
MyMod="res://mods/my-mod-id/Scripts/Main.gd"
```

`Scripts/Main.gd` (zipped to `mods/<mod-id>/Scripts/Main.gd`):

```gdscript
extends Node

var _lib


func _ready() -> void:
    if not Engine.has_meta("RTVModLib"):
        push_error("RTVModLib not available")
        return
    _lib = Engine.get_meta("RTVModLib")
    _lib.hook("weaponrig-ammocheck", _on_replace)


func _on_replace() -> void:
    var rig = _lib._caller   # instance whose method was called
    # ... logic; call rig._rtv_vanilla_AmmoCheck() to invoke the real vanilla body
    _lib.skip_super()  # tell the wrapper not to run vanilla after our replace
```

Hook variants:

- `"<stem>-<method>"` — **replace** hook. Single owner; runs *before* vanilla. Call `_lib.skip_super()` to prevent vanilla from running after your callback returns.
- `"<stem>-<method>-pre"` — runs before vanilla, cannot prevent it.
- `"<stem>-<method>-post"` — runs *after* vanilla completes (including after any internal `await`s for coroutines).
- `"<stem>-<method>-callback"` — deferred dispatch after post.

`_lib._caller` is set to the instance the wrapper is running on, refreshed right before each pre/replace/post dispatch.

The original vanilla body is renamed to `_rtv_vanilla_<MethodName>` on the wrapped script and remains callable via duck-typing: `rig._rtv_vanilla_AmmoCheck()`. Use this to wrap vanilla with before/after logic when a single replace hook is cleaner than pre + post.

Caveat for coroutine vanilla methods (with `await`): the wrapper's internal `_wrapper_active` re-entry guard bypasses hook dispatch on nested calls and calls the renamed vanilla directly. A replace hook that *itself* uses `await` is not awaited by the wrapper, so keep the replace body synchronous. If you need to wrap an async vanilla, spawn a background coroutine from the replace and `skip_super()`:

```gdscript
func _on_replace() -> void:
    var rig = _lib._caller
    if rig.gameData.isChecking:
        _lib.skip_super()
        return
    _wrap_async(rig)      # fire-and-forget coroutine
    _lib.skip_super()

func _wrap_async(rig) -> void:
    var prev = rig.gameData.weaponPosition
    await rig._rtv_vanilla_AmmoCheck()
    rig.gameData.weaponPosition = prev
```

Two-pass restart: when the mod set changes, the loader generates a new hook pack in Pass 1 and immediately restarts the game with `--modloader-restart` so Pass 2 boots with the hook pack mounted at file-scope. The user only launches once; the restart is automatic. Expect to see `Preparing two-pass restart` in the session-stamped log and then a fresh `godot.log` for the Pass 2 session.

### Other loader features

- **`[autoload]`**: register a singleton node. Prefix path with `!` for early autoloads. Path must exist in the archive or the loader aborts with `Autoload path not found in archive`.
- **`[hooks]`**: per-method wrap declaration. Quote both key and value since the key contains `/`, `:`, `.` and the value is a bare identifier that Godot's `ConfigFile` parser rejects unquoted (the loader logs `ConfigFile parse error: Unexpected identifier '...'` followed by `Invalid mod -- mod.txt failed to parse`). Formats: `"res://Scripts/X.gd"="methodA, methodB"` (specific), `"res://Scripts/X.gd"="*"` or `"res://Scripts/X.gd"=""` (all methods).
- **`[registry]`**: opt-in to `Database.gd` wrapping; required for `lib.register()` / `lib.override()`.
- **`.hook("<prefix>-<method>[-pre|-post|-callback]", cb)`**: identical effect to `lib.hook(...)` called on `RTVModLib`; the loader source-scans `.hook()` calls and auto-enrolls the target path in the wrap mask, so `[hooks]` in `mod.txt` is only needed when your hook registration goes through a callback indirection the scanner can't see.
- **`[script_extend]` / `[script_overrides]`**: declarative `take_over_path`. Works for scripts that aren't preloaded by a game autoload; otherwise use `[hooks]`.
- **Asset replacement:** all files are namespaced under `mods/<mod-id>/` by the build, so `Resources/Foo.tres` in source resolves at `res://mods/<mod-id>/Resources/Foo.tres`. To override a vanilla asset at its original path, you'd need to either change the build to ship that file at the archive root, or hook the load site instead.
- **Autofix:** the loader silently strips `.reload()` calls from mod source and repairs some Godot 3-era syntax. Safe to ignore.

Reference wiki (community, slightly out of date for v3.0.1): https://github.com/ametrocavich/vostok-modding-wiki/wiki
Authoritative reference: read `D:\SteamLibrary\steamapps\common\Road to Vostok\modloader.gd` directly.

### Debugging

Runtime log lives at `%APPDATA%\Road to Vostok\logs\godot.log` (plus session-stamped rolls in the same folder). `print()` in mod scripts lands there. Useful greps:

- `[ModLoader][Info] Found N mod(s)` confirms discovery.
- `[script_extend] res://... -> res://mods/...` confirms the override mapping parsed.
- `[OverrideVerify]` lines confirm the take-over actually happened post-autoload.
- `No user opt-in declarations` means you shipped a mod with no `[script_extend]` / `[hooks]` / `[registry]` / `.hook()` and no overrides will apply.

Mount cache (unpacked `.vmz`s) is at `%APPDATA%\Road to Vostok\vmz_mount_cache\` - handy for verifying what actually got deployed.

## Build / install

`build.ps1` at the repo root zips each mod folder (any directory containing `mod.txt`) into `<id>.vmz` and drops it into the game's `mods/` directory. `.vmz` is the community convention for a mod archive; it is a plain zip, just renamed. The archive is built from the folder's contents (so `mod.txt` ends up at archive root) using `System.IO.Compression.ZipFile`, which produces the forward-slash paths the loader requires.

Target directory resolution, in order:
1. `-ModsDir <path>` CLI argument.
2. `build.config.json` at repo root, shape: `{ "modsDir": "..." }`.
3. Error out.

Typical setup (create `build.config.json` once per machine; gitignored):

```json
{
  "modsDir": "D:\\SteamLibrary\\steamapps\\common\\Road to Vostok\\mods"
}
```

Usage:

```powershell
.\build.ps1                             # build and install every mod in the repo
.\build.ps1 -Mod ammo-check-fix         # build and install one mod
.\build.ps1 -ModsDir 'X:\path\to\mods'  # one-off override, bypasses config
```

Existing zips in the target are overwritten. Launch the game after building; check the loader log (see "Debugging" below, if documented) for load errors.
