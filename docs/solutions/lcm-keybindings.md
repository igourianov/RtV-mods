# LCM key bindings

## Intent

The key binding code moves out of mod-lib into Likho's Config Manager (LCM). LCM becomes the single owner of the hooks on the vanilla bindings screen and offers action registration through its public API. mod-lib carries no binding code any more. VosTac and TacMed register their actions through LCM and require it to be installed.

## Constraints and assumptions

Constraints:

* Vanilla `Inputs.gd` `CreateActions` and `ResetActions` reload the `InputMap` from project settings and rebuild the list from the screen's own `inputs` table. An action that is not in project settings is gone after either of them runs, unless a hook adds it back.
* The vanilla remap in `Inputs.gd` works on any row whose button is connected to `_on_input_pressed` with an action name. It writes the new event into `Preferences.actionEvents` under that name and saves.
* Vanilla `ResetActions` saves the preferences before a post hook runs and leaves the saved bindings of actions outside its `inputs` table in place.
* `Inputs.gd` is the script of the bindings screen in the main menu and in every map. Each scene has its own instance, and its `_ready` waits 0.1 s before `CreateActions`.
* Reading the state of an action that is missing from the `InputMap` logs an error on every call.
* A script loaded by the same path from several scripts is one cached script, so its static state is shared.
* `preload` of a path that does not exist fails the parse of the script that holds it. `load` of the same path returns `null`.
* A hook fires only when the mod that registers it declares the vanilla method under `[hooks]` in its own `mod.txt`.
* The Mod Loader reads `[dependencies]` `required=` from `mod.txt`, since v3.3.0. A mod whose required mod is missing or disabled is not loaded, and the loader's Mods tab says which mod it needs. A required mod loads before its dependent.
* The declaration carries no version, and the player can override it per mod with `Load anyway`. A dependent still has to cope with the required mod being absent or too old at runtime.
* The loader's `INPUTS` registry only adds an action to the `InputMap` with a default event. It does not put the action back after the vanilla reload, gives it no row, does not apply a saved binding and needs a default event.

Ruled out:

* The loader's `INPUTS` registry. Every part of the binding code would still be needed on top of it.

* Bindings on a mod's page in LCM's menu and bindings in LCM's store. Rows, remap and storage stay vanilla's, so a player's saved bindings carry over untouched.
* A fallback copy of the binding code in mod-lib for when LCM is missing.
* Running VosTac or TacMed partially without LCM. Their actions cannot survive a rebuild of the bindings list without the hooks, and every read of a missing action logs an error.
* Action names scoped by mod. An action name is the global `InputMap` name.
* Headers or grouping per mod in the vanilla bindings list.
* Making LCM required for Eventuality, Tag and Radiola. They register no actions and keep LCM optional.

Assumptions, unverified:

* A static function of the API script can be checked for by name on the loaded script, so a consumer can tell an LCM build with the actions API from one without.

## Scope

Owned:

* `likhos-config-manager/`: `Scripts/LCM.gd`, `Scripts/Main.gd`, `mod.txt` and `README.md`.
* `mod-lib/Main.gd` and `mod-lib/Inputs.gd`.
* `likhos-vostac/`: `Scripts/Main.gd`, `mod.txt`, `README.md` and the weapon rig nodes that read binding text for protips: `WeaponRig_Base.gd`, `WeaponRig_Fire.gd`, `WeaponRig_Reload.gd`, `WeaponRig_ManualReload.gd` and `WeaponRig_Inspect.gd` under `Scripts/Nodes/`.
* `likhos-tacmed/`: `Scripts/Main.gd`, `mod.txt` and `README.md`.
* `Scripts/Main.gd` of `likhos-eventuality`, `likhos-tag` and `likhos-radiola`: only how they reach LCM.

Context only:

* Vanilla `src/Scripts/Inputs.gd`, `Preferences` and `RemapButton.tscn`.
* Everything else in `likhos-eventuality`, `likhos-tag` and `likhos-radiola`. They are consumers of `register_config` only, and what they register stays as it is.
* `build.ps1`, `CLAUDE.md`, `CODE_GUIDE.md`, the changelogs and the older solution docs.

## Solution

### API

The actions API is five static functions on LCM's public script, `res://mods/likhos-config-manager/Scripts/LCM.gd`, next to `register_config`.

`register_action(action: String, label: String, default: Variant = null) -> void`

* `action` is the `InputMap` name the mod reads input by.
* `label` is the text of the action's row in the vanilla bindings list. An action with an empty label gets no row. It is bound to its default and the player cannot rebind it.
* `default` is the binding the action has while the player has not saved one: an `InputEvent`, the name of another action or `null`. A name takes that action's binding as it is when the list is built. `null` leaves the action unbound, and its row shows `[unbound]`.
* The action exists in the `InputMap` from the moment of the call, without events, so a read before the first bindings screen is built is not an error.
* A second registration under the same action name replaces the first with a warning.

`remove_action(action: String) -> void`

* Hides a vanilla action's row from the bindings list. The action itself stays in the `InputMap` on its project default.

`get_binding(action: StringName) -> String`

* The text of the action's binding as the vanilla list shows it, or `[unbound]`.

`create_key_input(keycode: int, ctrl_pressed: bool = false, shift_pressed: bool = false) -> InputEventKey` and `create_mouse_input(button: int) -> InputEventMouseButton`

* Builders for the pressed events used as defaults. The key event is matched by physical keycode.

The registered actions and the hidden vanilla actions are static state of the API script, like the registered configs. A consumer can register at any point of startup, before or after LCM's `Main` runs. A registration made after a bindings screen has built its list takes effect the next time one is built.

### Bindings screen

LCM's `Main.gd` hooks the vanilla bindings screen before and after `CreateActions` and after `ResetActions`, and applies the registry to the screen instance the hook fires for.

* Before vanilla builds the list, the hidden actions leave the screen's `inputs` table.
* After vanilla has built the list, every registered action is put back into the `InputMap` and bound to the player's saved binding from `Preferences.actionEvents`, or to its default without one. A labeled action gets a row at the end of the list, wired to the vanilla remap handler. Rebinding, the prompt and saving are vanilla's from there on.
* After a vanilla reset, the saved bindings of the registered actions are dropped, the actions return to their defaults and the preferences are saved again.
* Mod rows follow the vanilla rows in registration order, across all mods.
* The bindings hooks and the settings screen hook are independent. A failure to register one is logged and leaves the other feature working.

### mod-lib

* `mod-lib/Main.gd` has no binding code: no action registration, no input builders and no hooks on `Inputs.gd`. `mod-lib/Inputs.gd` does not exist.
* `mod-lib/Main.gd` is the one place that knows LCM's path. It loads the API script at runtime, never by `preload`, and holds it in a member that is `null` without LCM. Every mod's `Main` reaches LCM through that member and none loads the script on its own.

### Consumers

Eventuality, Tag and Radiola register their config through the mod-lib member when it is set. LCM stays optional for them.

VosTac and TacMed require LCM.

* Their `mod.txt` declares LCM under `[dependencies]` `required=`. Without LCM the loader does not load them and names the missing mod in its Mods tab.
* `Main` checks for LCM before anything else in `setup`, which covers a player who overrode the loader's check and an LCM build that has no actions API. In either case the mod logs one warning that names LCM as required and sets nothing up: no hooks, nodes, patches or registry entries. The game runs as if the mod was not installed.
* Scripts other than `Main` that need the API load it at runtime as well, so every script of the mod parses without LCM.
* VosTac registers `optic_zoom_in` on wheel up, `optic_zoom_out` on wheel down, `binoculars` on `B`, `hold_breath` on whatever `sprint` is bound to and `canted_standalone` without a default. It hides `ammo_check` and `insert`. Its weapon rig nodes take the binding text for protips from `get_binding`.
* TacMed registers `tacmed` on `Z` under the label `IFAK/AFAK`, and the unlabeled `hurt_myself` and `hurt_myself_more` on `Ctrl+Shift+O` and `Ctrl+Shift+P`.

### mod.txt and READMEs

* LCM's `mod.txt` declares hooks on `Inputs.gd` `CreateActions` and `ResetActions` next to `Settings.gd` `_ready`. VosTac's and TacMed's do not declare them, and declare LCM as a required dependency.
* LCM's README documents the actions API for mod authors, lists the `Inputs.gd` hooks under compatibility and says that a mod registering actions needs LCM installed, while a mod that only registers a config runs on its defaults without it.
* VosTac's and TacMed's READMEs list LCM as required and do not list the `Inputs.gd` hooks.

### Observable result

* With LCM installed, the vanilla bindings list shows the same mod rows as before, rebinding and reset behave the same and a player's saved bindings are kept.
* VosTac or TacMed without LCM: the loader's Mods tab marks the mod as not loading and names LCM, and the game runs without the mod.
* VosTac or TacMed loaded anyway, or with an LCM build older than the actions API: one warning in the log, and the mod does nothing.
* LCM without any mod that registers actions: the bindings screen is vanilla.
* Eventuality, Tag and Radiola behave as before in every combination.

## Tradeoffs

* LCM as a hard dependency of VosTac and TacMed over a fallback in mod-lib. The cost is that a player who updates either mod without installing or updating LCM loses the whole mod until they do. The gain is one copy of the binding code and one owner of the hooks, so a fix ships once in LCM.
* A check for the actions API at runtime over a minimum LCM version. The cost is that the loader cannot tell the player their LCM is too old, only the log does. The gain is no version number of LCM hardcoded in its consumers.
* LCM's path held by mod-lib over a `load` in every mod. The cost is that mod-lib, shipped in every mod, knows about LCM.
* The whole mod off without LCM over a partial run. The cost is that features unrelated to bindings are off too. The gain is no guard per feature and no `InputMap` errors.
* Vanilla rows and `Preferences` over LCM's menu and store. The cost is that bindings and settings of a mod live on two screens. The gain is no remap capture of LCM's own and no migration of saved bindings.
* Global action names over names scoped by mod. The cost is that two mods registering the same name collide, with the later one winning.
* The actions API on the public script that can never move. The cost is five more functions held as a contract, and hooks on `Inputs.gd` for every player with LCM, with or without a mod that uses them.
