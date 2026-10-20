# Explicit registration failures

## Intent

Mods built on mod-lib register hooks and registry changes one at a time inside `setup()`. The rollback in `mod-lib/Main.gd` unhooks the registered hooks when one fails but leaves every registry change in place, so it doesn't undo a partial setup either.

The user wants no rollback. A rejected hook is reported with a mod-prefixed warning that names it, and the rest of the setup carries on.

## Constraints and assumptions

* The loader has no batch registration with rollback. `hook_many`, the registry `*_many` verbs, the aggregator helpers and `lib.setup(plan)` all apply entries one at a time and keep the successful ones (`vostok-mod-loader/src/hooks_api.gd:154`, `src/registry.gd:533-648`, `docs/wiki/Setup-Plans.md` "Failure isolation").
* `lib.hook()` returns -1 only for a bare name (no `-pre`, `-post` or `-callback` suffix) whose replace slot already has a live owner (`hooks_api.gd:96-103`). Pre, post and callback hooks always register. A misspelled name or an unwrapped target registers fine and never fires. Neither is detectable.
* `lib.get_replace_owner(name)` returns the owning hook's id. It identifies no mod.
* Registry verbs fail only on narrow validation cases, mainly an id that no longer resolves after a game update. Every path that returns false already logs a `[Registry]` warning naming the id (`src/registry/items.gd`, `src/registry/recipes.gd`, `src/registry/shared.gd`). A misspelled patch field warns but still returns true.
* Ruled out: mod-side warnings or a mod-lib wrapper for registry calls. The loader's own warning already names the id, so a wrapper would only add the mod prefix.
* Ruled out: rollback of any kind. `lib.revert()` doesn't track which mod made a patch (`registry.gd:47-52`), so reverting one mod's patch would also drop another mod's patch on the same field.
* Ruled out: checking or queuing registrations before applying them. The extra complexity isn't worth it.
* `mod-lib/Tooltip.gd` and battery's priority-200 `laser-_process-post` hook call `lib.hook` directly. Both are post hooks, which can't fail, so they need no check.

## Scope

Owned:

* `mod-lib/Main.gd`
* `likhos-battery/Scripts/Main.gd`, its direct `laser-_process-post` registration only

Context only: loader `hooks_api.gd` and `registry.gd`, `mod-lib/Out.gd`, `mod-lib/Tooltip.gd`.

Not owned: registry call sites in any mod, `likhos-config-manager` (its `Main` doesn't extend mod-lib `Main` and already checks its one hook), the loader, hook handler logic.

## Solution

### `mod-lib/Main.gd`

* `register_hook(name, callback)` registers immediately. On a -1 result it logs a warning naming the hook and the current owner's id from `lib.get_replace_owner`. Nothing is tracked or undone.
* `_init_setup` awaits `frameworks_ready` and runs `setup(lib)`. It does no registration bookkeeping.

### Battery laser hook

Battery registers `laser-_process-post` through `lib.hook` at priority 200 so it runs after VosTac's handler on the same hook. It isn't tracked by mod-lib.

### Observable result

Each rejected hook adds one mod-prefixed warning to `godot.log` naming the hook and the id of the hook that owns its slot. Failed registry calls show only the loader's own `[Registry]` warning. Everything that succeeded stays applied.

## Tradeoffs

* Partial operation over all-or-nothing: a mod with a rejected hook keeps running with that hook missing. For VosTac this can mean a hook pair where only one half fires. The warning names the exact hook so it can be traced.
* Warnings over rollback: no code exists to undo a setup, and rollback could never cleanly cover registry changes anyway.
* Registry failures carry no mod prefix. They have to be traced by id.
