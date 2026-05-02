# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Mods for the Godot game **Road to Vostok** (`config/name="Road to Vostok"`, version 0.1.1.3, Godot 4.6.2). Each top-level directory at the repo root (e.g. `ammo-check-fix/`) is an individual mod.

## Mods

* `likhos-weapon-handling-fixes/` - tactical realism and weapon mechanics mod. Major game overhaul. Includes many features nd fixes. Also known as `VosTac`.
* `likhos-magdump/` - small mod for magazine compatibility between different rifles
* `likhos-eventuality/` - small mod affecting in-game dynamic events. Fxes event probability and provides small enhancements.

## `src/` is the decompiled game (reference only, gitignored)

`src/` holds the extracted original project pulled from `RTV.pck` with GDRE Tools v2.5.0-beta.5 (see `src/gdre_export.log`). It is the authoritative reference for the game's scripts, scenes, resources and UIDs, but it is **not** part of this repo and must not be committed. Treat it as read-only when planning mod changes.

Key facts when reading `src/`:
- Scripts are GDScript under `src/Scripts/` (e.g. `AI.gd`, `Actions.gd`, `AudioEvent.gd`).
- Autoloads defined in `src/project.godot`: `Loader`, `Database`, `Simulation` (all from `res://Resources/`).
- Global groups and other engine config live in `src/project.godot`.
- `.gd.uid` files are Godot's UID sidecars, keep them paired with their `.gd` when referenced.

## `vostok-mod-loader/` holds the loader source + docs (read-only reference)

A clone of the Metro Mod Loader repo lives at `vostok-mod-loader/`. Browse it whenever the loader's behavior is unclear or when debugging an unfamiliar log line. Do not edit anything inside it.

Layout:
- `src/*.gd` — loader implementation. Notable files:
    - `hooks_api.gd` — RTVModLib public surface (`hook`, `unhook`, `skip_super`, etc.) and dispatch internals.
    - `registry.gd` + `registry/<store>.gd` — registry verbs and per-store handlers (items, scenes, loot, ...).
    - `rewriter.gd`, `hook_pack.gd` — codegen pipeline that produces dispatch wrappers around vanilla methods.
    - `mod_loading.gd`, `mod_discovery.gd` — mod scan/mount pipeline.
    - `boot.gd`, `lifecycle.gd` — two-pass restart, override.cfg lifecycle.
    - `constants.gd` — `MODLOADER_VERSION`, `RTV_SKIP_LIST`, `RTV_RESOURCE_*_SKIP`.
- `docs/wiki/*.md` — full reference: `Hooks.md`, `Registry.md`, `Mod-Format.md`, `Architecture.md`, `Limitations.md`, `Modules.md`, etc. Use `Modules.md` to find which file owns a given concern, then jump into `src/`.

When in doubt about behavior or an error message, grep this folder before guessing or asking.

## Working on a mod

Mods live at the repo root, one folder per mod. When modifying behavior, first locate the relevant script/scene in `src/` to understand the original implementation, then author the mod files at the root. Do not edit files under `src/`.

## Syntax rules

* When writing boolean operations - use C-type operators
* Use colon for dictionary {"key": "value"} pairs 

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

Do not modify mod version property unless specifically requested to do so. Build process does it automatically.

### Script override pattern (RTVModLib hooks)

The installed loader is **Metro Mod Loader v3.0.1** (`<game>/modloader.gd`). Despite what the older community wiki documents, neither the autoload + `take_over_path` pattern nor `[script_extend]` reliably overrides game scripts. Here's why:

Game autoloads (`Database`, `Loader`, `Simulation`) do module-scope `const Makarov_Rig = preload(...)` on every weapon scene, knife, fishing rod, etc. Those preloads resolve each scene's ext_resource script references at parse time. Any later `take_over_path("res://Scripts/WeaponRig.gd")` updates the `res://` cache for *future* `load()` calls but **does not** alter the preloaded scenes' already-bound Resource references. So override methods declared that way never fire for preloaded weapons. `[script_extend]` hits this same problem; the loader logs `No user opt-in declarations` to flag it.

The working pattern uses the loader's **hook codegen**. At static init (before any game autoload runs), the loader mounts a generated "hook pack" that rewrites each opt-in vanilla method into a dispatch wrapper. The wrapper looks up registered callbacks on `Engine.get_meta("RTVModLib")` and routes to them. Preloaded scenes bind to the wrapped vanilla, so hook callbacks fire on every instance.

#### Auto-enrollment is the primary path

When your mod source contains a literal `lib.hook("stem-method[-suffix]", cb)` call, the loader source-scans your `.gd` files at load time, sees the call, and enrolls `res://Scripts/<Stem>.gd :: <method>` into the wrap surface automatically. **You do not need a `[hooks]` block in `mod.txt` for the common case.** The scanner is the 95% path.

`mod.txt` (no `[hooks]` needed):

```
[mod]
name="My Mod"
id="my-mod-id"
version="1.0.0"

[autoload]
MyMod="res://mods/my-mod-id/Scripts/Main.gd"
```

`Scripts/Main.gd`:

```gdscript
extends Node

var _lib


func _ready() -> void:
    if not Engine.has_meta("RTVModLib"):
        push_error("RTVModLib not available")
        return
    _lib = Engine.get_meta("RTVModLib")
    if _lib._is_ready:
        _register()
    else:
        _lib.frameworks_ready.connect(func(): _register())


func _register() -> void:
    _lib.hook("weaponrig-ammocheck", _on_replace)


func _on_replace() -> void:
    var rig = _lib._caller   # instance whose method was called
    # ... logic; call rig._rtv_vanilla_AmmoCheck() to invoke the real vanilla body
    _lib.skip_super()  # tell the wrapper not to run vanilla after our replace
```

`frameworks_ready` is emitted once after every mod's autoload finished. Use it whenever your registration logic depends on other mods' overrides being applied (or when in doubt). Connecting via lambda matches the existing pattern in `likhos-weapon-handling-fixes`.

#### `[hooks]` is the escape hatch

Declare `[hooks]` in `mod.txt` only when the scanner can't see your registration:

- Hooks registered via callback indirection (e.g. `register_hook(lib, name, cb)` helper functions where the literal `name` is in a different mod or computed at runtime).
- `ModLoader.add_hook(...)` from a non-`!` autoload — the compat shim runs after pack generation, too late to enroll.
- A whole script you want wrapped without enumerating methods.

Format. Quote both key and value (the path contains `/`/`:`/`.`, the value is a bare identifier that ConfigFile rejects unquoted):

```
[hooks]
"res://Scripts/Interface.gd"="GetMagazine, _ready"   ; specific methods
"res://Scripts/Camera.gd"="*"                        ; wildcard, all methods
"res://Scripts/Camera.gd"=""                         ; empty value also means all
```

Method names are case-insensitive (the loader normalizes to lowercase).

#### Hook variants and dispatch order

```
<stem>-<method>            ← replace
<stem>-<method>-pre        ← runs before vanilla
<stem>-<method>-post       ← runs after vanilla (awaits coroutines)
<stem>-<method>-callback   ← deferred via call_deferred() after post
```

Stem is the lowercase filename without `.gd`. Method is also lowercased. So `Interface.gd :: GetMagazine` → `interface-getmagazine[-pre|-post|-callback]`. The `_input` method becomes `<stem>-_input` (leading underscore preserved).

Behavior:

- **Replace** is single-owner: first registration wins, second `hook()` returns `-1`. Inside the callback, call `_lib.skip_super()` to suppress vanilla. The callback's **return value becomes the method's return value**, so replacing methods that return data works.
- **pre** runs before vanilla, can't prevent it. Return value ignored.
- **post** runs after vanilla completes, including after any internal `await`. Return value ignored.
- **callback** is deferred via `Callable.bindv(args).call_deferred()`. Return value ignored.

Hook callbacks receive the **same arguments as vanilla**. `_lib._caller` is set to the instance the wrapper is running on, refreshed before each pre/replace/post dispatch.

The original vanilla body is renamed to `_rtv_vanilla_<MethodName>` on the wrapped script and is callable via duck-typing: `rig._rtv_vanilla_AmmoCheck()`. Use this to wrap vanilla with before/after logic when a single replace hook is cleaner than pre + post.

Coroutine vanilla methods (with `await`): the wrapper's `_wrapper_active` re-entry guard bypasses dispatch on nested calls and runs the renamed vanilla directly. A replace hook that *itself* uses `await` is not awaited by the wrapper, so keep the replace body synchronous. To wrap an async vanilla, spawn a background coroutine from the replace and `skip_super()`:

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

#### RTVModLib API surface

Beyond `hook` / `skip_super`, the lib exposes (see `vostok-mod-loader/.../src/hooks_api.gd`):

| Method / signal | Purpose |
|---|---|
| `hook(name, cb, priority=100) -> int` | Register, return id. Replace: returns `-1` if already taken. |
| `unhook(id) -> void` | Remove a registration by id. |
| `add_hook(path, method, cb, before=true) -> int` | godot-mod-loader compat wrapper. |
| `has_hooks(name) -> bool` | Any callbacks registered at this name? |
| `has_replace(name) -> bool` | Replace owner present? |
| `get_replace_owner(name) -> int` | Id of the replace owner, or `-1`. |
| `skip_super() -> void` | Inside a replace: suppress vanilla. |
| `seq() -> int` | Monotonic dispatch counter (test instrumentation). |
| `static version() / major_version() / minor_version() / patch_version()` | Read `MODLOADER_VERSION`. |
| `frameworks_ready` (signal) | Emitted after all mod autoloads finish their overrideScript work. |
| `_caller` | Instance the current dispatch is running on. |
| `_is_ready` (bool) | True after `frameworks_ready` fired. |

Lower priority values fire first within the same suffix bucket.

#### Scripts that don't dispatch hooks (skip lists)

The loader refuses to wrap certain scripts because rewriting them breaks runtime semantics. From `constants.gd`:

- **`RTV_SKIP_LIST`**: `TreeRenderer`, `MuzzleFlash`, `Hit`, `ParticleInstance`, `Message`, `Mine`, `Explosion`. Reasons range from `@tool`-only to await-coroutine-killing wrappers to GPUParticles3D `set_script` corruption.
- **`RTV_RESOURCE_SERIALIZED_SKIP`**: save-data scripts (`CharacterSave`, `ContainerSave`, `FurnitureSave`, `ItemSave`, `Preferences`, `ShelterSave`, `SlotData`, `SwitchSave`, `TraderSave`, `Validator`, `WorldSave`). Wrapping them would embed mod-dependent paths into save files.
- **`RTV_RESOURCE_DATA_SKIP`**: data-only resource scripts (`AIWeaponData`, `AttachmentData`, `ItemData`, `LootTable`, `Recipes`, etc., 25 entries). They have no method call sites to intercept; hook the consumers instead.

Hooking a method on any of these is a no-op. If you need to influence behavior in one of those code paths, find the consumer (e.g. for `Hit`, hook the spawner that creates Hit instances).

#### Two-pass restart

When the mod set changes, the loader generates a new hook pack in Pass 1 and immediately restarts the game with `--modloader-restart` so Pass 2 boots with the hook pack mounted at file-scope. The user only launches once; the restart is automatic. Expect to see `Preparing two-pass restart` in the session-stamped log and then a fresh `godot.log` for the Pass 2 session.

### Registry data API (`[registry]` + RTVModLib)

Reversible mutations on game data stores: items, scenes, loot tables, sounds, recipes, events, trader pools/tasks, inputs, scene paths, shelters, AI types, fish species, plus an arbitrary-`.tres` escape hatch. Used for adding, replacing or tweaking content without writing hook callbacks.

Opt in with an empty `[registry]` section in `mod.txt`. Without it, `lib.register(...)` calls silently no-op because the loader skips the `Database.gd` / `Loader.gd` / `AISpawner.gd` / `FishPool.gd` rewrites the registry depends on.

```gdscript
var lib = Engine.get_meta("RTVModLib")
await lib.frameworks_ready  # only if you also depend on hooks being ready

lib.register(lib.Registry.ITEMS, "my_potion", potion_resource)          # add new
lib.override(lib.Registry.SCENES, "Potato", preload("..."))             # replace whole entry
lib.patch(lib.Registry.ITEMS, "Potato", {"weight": 0.1, "value": 500})  # mutate specific fields
lib.remove(lib.Registry.ITEMS, "my_potion")                             # undo register
lib.revert(lib.Registry.SCENES, "Potato")                               # undo override/patch
lib.get_entry(lib.Registry.ITEMS, "Potato")                             # read current state
```

All verbs return `bool`. Failures `push_warning` with the reason.

Registry constants on `lib.Registry`: `SCENES`, `ITEMS`, `LOOT`, `SOUNDS`, `RECIPES`, `EVENTS`, `TRADER_POOLS`, `TRADER_TASKS`, `INPUTS`, `SCENE_PATHS`, `SHELTERS`, `RANDOM_SCENES`, `AI_TYPES`, `FISH_SPECIES`, `RESOURCES`. Each supports a subset of the verbs (some are append-only and reject `override`/`patch`; `RESOURCES` supports only `patch`/`revert`). See `vostok-mod-loader/docs/wiki/Registry.md` for the full per-registry table and example shapes.

**Conflict semantics, applied across every registry:**

- `register` on a colliding id (vanilla const or another mod's prior register) fails, no silent overwrite.
- `override` on an already-overridden id fails; the second mod must `revert` first.
- `patch` on the same field across mods is last-write-wins, but the stash holds the **true vanilla** value, so any later `revert` returns to vanilla and silently drops both mods' patches.
- `patch` on different fields keeps independent stashes per field; multiple mods coexist.
- Array-based registries (`loot`, `recipes`, `events`, `trader_tasks`) accept multiple `register` calls additively.

**Timing.** Register during your mod's `_ready()`. Trader stock, `LootContainer`, `LootSimulation`, `AudioLibrary` `@export` bindings and the keybind UI all cache once during their own `_ready()`; runtime re-registration after that updates the store but consumers won't see it until the next cache refresh.

**`Database.get(name)` vs `Database.NAME`.** The registry routes `SCENES` lookups through an injected `_get()` on `Database`. Property-syntax access to a vanilla `const` (`Database.Potato`) is resolved at compile time and bypasses `_get()`, missing any registry override. Use `Database.get("Potato")` (or `Database["Potato"]`) so registry overrides apply.

**Registry vs. hooks vs. direct mutation.**

- Registry: scalar field tweaks (`weight`, `damage`, `volume`), wholesale replacement (override an item/scene), adding new entries (recipe, event, item, input action). Reversible, isolated from other mods.
- Hooks: intercepting vanilla method calls. Behavior changes; custom logic before/after/instead of vanilla.
- Direct resource mutation (`load(path).field.append(...)` at autoload `_ready()`): **additive list changes**. Registry's `patch` writes whole field values, so two mods patching the same list-field clobber each other; direct `append` lets multiple mods coexist without coordination. `likhos-magdump`'s cross-compat magazine list uses this pattern.

### Other loader features

- **`[autoload]`**: register a singleton node. Prefix path with `!` for early autoloads (loaded via `[autoload_prepend]` in `override.cfg`, before the game's own autoloads). Path must exist in the archive or the loader aborts with `Autoload path not found in archive`.
- **`[hooks]`**: escape hatch for static method enrollment when the `.hook()` scanner can't see your call site. See "Auto-enrollment" above for when you actually need it.
- **`[registry]`**: opt-in to the registry data API. See the "Registry data API" section above.
- **`[script_extend]` / `[script_overrides]`**: declarative `take_over_path`. Works for scripts that aren't preloaded by a game autoload; otherwise use hooks. Extends-chained overrides compose with hooks: the rewritten vanilla ships at the original path and `super.method(...)` from the override lands on the dispatch wrapper.
- **Asset replacement:** all files are namespaced under `mods/<mod-id>/` by the build, so `Resources/Foo.tres` in source resolves at `res://mods/<mod-id>/Resources/Foo.tres`. To override a vanilla asset at its original path you'd need to either change the build to ship that file at the archive root, or hook the load site instead.
- **Class_name collisions are fatal.** A mod that re-declares an existing vanilla `class_name` triggers Godot's `"Class X hides a global script class"` and crashes. Don't reuse vanilla class names; pick a mod-specific name.
- **`take_over_path` on `class_name` scripts is unsafe** (Godot bug #83542). The hook system dodges this since rewritten scripts ship at the original path; mods doing manual `take_over_path` on a `class_name` vanilla can crash unpredictably.
- **Autofix:** the loader silently strips `.reload()` calls from mod source and repairs Godot 3-era syntax (`tool` → `@tool`, `onready var` → `@onready var`, `base()` → `super.<method>()`, bodyless `if X:` blocks get `pass`). Safe to ignore.

References (in order of preference for lookups):
- `vostok-mod-loader/docs/wiki/*.md` — local clone of the loader-specific wiki. Authoritative for v3.0.1 behavior. `Hooks.md`, `Registry.md`, `Mod-Format.md`, `Limitations.md`, `Modules.md` are the most useful.
- `vostok-mod-loader/src/*.gd` — loader source. Grep for log strings, behavior, edge cases.
- `D:\SteamLibrary\steamapps\common\Road to Vostok\modloader.gd` — built single-file loader as installed; matches the repo at the build commit.
- https://github.com/ametrocavich/vostok-mod-loader/wiki — same content as the local wiki, online.
- https://github.com/ametrocavich/vostok-modding-wiki/wiki — older community wiki, slightly out of date for v3.0.1.

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

Existing zips in the target are overwritten. Launch the game after building; check the loader log (see "Debugging") for load errors.
