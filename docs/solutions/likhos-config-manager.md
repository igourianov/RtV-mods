# Likho's Config Manager

## Intent

A new mod, Likho's Config Manager (LCM), replaces MCM as the way these mods expose settings to the player. A mod describes its settings as a typed config object, the way the game describes its state in `GameData`, and hands it to LCM through one call. LCM derives the menu from the object's fields and export hints, keeps the object's values in sync with what the player saved and hides where and how the values are stored.

## Constraints and assumptions

Constraints:

* Godot's export annotations carry a field's type, range, enum options and group. None of them carries a label or a tooltip.
* The property list of a config object's script reports `@export` fields with their hint and hint string, and `@export_group` entries, in declaration order. Checked in Godot 4.6.2.
* The object's own property list is not usable for this. It opens with the engine's built-in `Resource` group, and the category entry that separates it from the script's fields exists in the editor build but not in the game, where the first ungrouped settings then show under a `Resource` header.
* A `.tres` pointing at a script loads through `preload` as one shared instance for every script that preloads it.
* A script loaded by the same path from several scripts is one cached script, so its static state is shared.
* A lambda kept in a script's static state until the engine exits crashes it. A method callable does not. The registry is therefore emptied when LCM's autoload leaves the tree.
* `Settings.gd` is the script of the settings screen both in the main menu, under `Menu/Settings`, and in game, under the `UIManager` node. Each scene has its own instance.
* A node later in the tree receives `_input` before `UIManager`, so a menu added after the settings screen can consume the `settings` action first.

Ruled out:

* Any integration with MCM: hosting LCM pages in MCM's menu or registering through `MCM_Config`. Shelved by the user. LCM and MCM run side by side without knowing about each other.
* Settings per Mod Loader profile. LCM does not read the loader's settings file, so it does not know the active profile and never shows or uses one.
* Tooltips and explicit labels for settings.
* MCM's template dictionaries, `menu_pos`, per value change callbacks and the `Create*Value` builder. Declaration order and export hints replace them.
* Keycode, array and dictionary settings. Key bindings go through mod-lib `Inputs` and the vanilla bindings screen.
* Import and export of settings.
* Carrying over values a player saved through MCM.
* Moving the existing mods (`likhos-vostac`, `likhos-eventuality`, `likhos-tag`, `likhos-radiola`) onto config objects.

Assumptions, unverified:

* The property list, shared instance and shared static state constraints above hold the same way in the exported game on Godot 4.6.3, with scripts and a `.tres` mounted from a mod archive.
* A mod that is not installed or is disabled in the Mod Loader has none of its files under `res://`, so the existence of the API script tells whether LCM is active.
* A post hook on `Settings.gd` `_ready` fires for every instance of the settings screen, after its awaited start, with the instance as the hook's caller.
* LCM's button and MCM's button fit in the top right corner of the vanilla settings screen together.

## Scope

Owned:

* `likhos-config-manager/`: the new mod. Its `mod.txt`, scripts and `README.md`. The README covers both players and mod authors, and does not mention mod-lib, which is private to these mods.
* `mod-lib/Main.gd`: handing a mod's config object to LCM.

Context only:

* `MCM/`: the menu LCM copies the look of.
* Vanilla settings UI under `src/`.
* The existing mods and their `ModConfig.gd`. They stay on mod-lib's MCM template bridge.
* `build.ps1`, `CLAUDE.md` and the other project docs.

## Solution

### Config object

A config object is one instance of a `Resource` script with `@export` fields. Scripts that need settings read its fields directly. LCM only needs the instance and does not care how the mod creates or shares it. The README documents three ways as equal options:

* Created with `new()` where the mod registers it, and passed on by the mod.
* Held in a static variable of the config script, so every script that preloads the script reaches the same instance.
* A `.tres` of the script shipped in the mod and preloaded, as vanilla scripts do with `GameData.tres`.

* An `@export` field is a setting. Its value in the `.tres`, or the script initializer, is its default.
* A field without `@export` is not a setting. LCM never reads, shows or stores it, so the object can carry runtime state next to settings.
* The mod owns its config object's lifecycle and manages it where that is needed. LCM keeps a reference to the object for the run and never frees, copies or validates it.
* Settings appear in the menu in declaration order, except that fields outside any group come first.

### Registration

LCM's API is one script of static functions at `res://mods/likhos-config-manager/Scripts/LCM.gd`. That path is the contract with consumers and does not change. A consumer checks that the script exists, loads it and calls its one function:

`register_config(mod_uid: String, mod_name: String, config: Resource, on_applied: Callable = Callable()) -> bool`

* The registered mods are static state of the API script, not of LCM's autoload. A consumer can register at any point of startup, before or after LCM's `Main` runs.
* It returns whether the config got registered.
* `mod_uid` is the mod's id from `mod.txt`. It keys the store and names the store file, so it can only contain `a-z`, `0-9`, `-` and `_`. A registration under any other id is rejected with a warning. A second registration under the same id replaces the first with a warning.
* `mod_name` is the name of the mod's entry in the menu.
* LCM takes the object's values at the time of the call as the defaults.
* When the mod has a stored file, LCM writes its values into the object before returning and then calls `on_applied` once. Without a stored file the object stays on its defaults and `on_applied` is not called.
* `on_applied` takes no arguments. Besides registration, LCM calls it every time the player's changes are applied.

### Field mapping

LCM builds a mod's settings page from the config object's property list alone.

| Field | Row |
|---|---|
| `bool` | On and off toggle |
| `int`, `float` with `@export_range` | Slider with a number box, limits and step from the hint |
| `int`, `float` without a range | Number box |
| `String` | Text box |
| `String` or `int` with `@export_enum`, or a field typed as a script enum | Dropdown, options in declared order |
| `Color` | Color picker |
| `Vector2`, `Vector3` | One number box per component |
| `@export_group` | Category header above the fields that follow it |

* Fields outside any group lead the page without a header, the way a page without groups looks. That covers fields declared before the first group and fields after `@export_group("")`, which move up to join them. The groups follow in declaration order, each under its header.
* A field of any other type is skipped with a warning naming the mod and the field.
* A setting's label is its field name cleaned up into words. There is no tooltip.
* Every row has a revert control that restores the default, shown only while the value differs from it.

### Store

* LCM keeps one file per mod under its own folder in `user://`, shared by every Mod Loader profile. Consumers never see a path or a file.
* A file holds only the settings whose value differs from the default, keyed by field name. A default changed in a mod update reaches every player who never touched that setting.
* A stored value whose field is gone, or whose type no longer matches the field, is ignored and dropped on the next save.
* A mod without a file starts from the defaults.

### Menu

The menu copies MCM's layout: a searchable list of registered mods on the left, the selected mod's settings page on the right and a back control.

* It opens from a button LCM puts on the vanilla settings screen, in the main menu and in game, and replaces that screen while open. Back or the `settings` action returns to it.
* The button and the menu are there whether or not MCM is installed.
* The page edits pending values. The config object does not change while the player moves a control.
* Leaving a page applies it. Leaving is selecting another mod or closing the menu. Apply writes the changed values into the config object, saves the store and calls `on_applied` once. A page left without changes does none of that.
* LCM reaches the vanilla UI through loader hooks, not through script takeover.

### mod-lib

`mod-lib/Main.gd` gives a mod one place to supply its config object and one overridable method that runs when settings are applied.

* A mod that supplies a config object is registered with LCM under its `mod_id` and `mod_name`, with the overridable method as `on_applied`. mod-lib finds LCM by the API script's path, the way it finds MCM today.
* Without LCM installed the object keeps its defaults, the overridable method does not run and a warning is logged.
* A mod that supplies no config object goes through `create_config` and `load_config` and the MCM template bridge, as today. A mod that supplies one does not.

### Observable result

* A mod with a config object and LCM installed: the vanilla settings screen has an LCM button. The menu lists the mod under the name it registered with, shows its settings grouped and ordered as declared, and changes take effect when the page is left.
* The same with MCM installed: both buttons and both menus are there. The mod is listed in LCM's menu only.
* Without LCM: the mod runs on its defaults.
* Switching the Mod Loader profile: the mod keeps the same values.
* An existing mod on the template bridge behaves as today in every combination.

## Tradeoffs

* A static API script loaded by path over an instance published as engine meta. The cost is a path every consumer hardcodes, so the script can never move or be renamed. The gain is no dependency on autoload order.
* One store for all Mod Loader profiles over a store per profile. The cost is that two profiles cannot hold different settings for the same mod. The gain is no dependency on the loader's settings file.
* A separate menu next to MCM's over hosting pages inside MCM's menu. The cost is that a player with both installed has two config menus.
* Labels from field names over explicit labels and tooltips. The cost is that a label such as `Fighter Jets (Area 05)` cannot be expressed and a setting cannot be explained in the menu. The field has to be named for what the player should read.
* Applying on leaving the page over writing through on every change. The cost is no live preview while dragging a slider.
* Storing only changed values over a full snapshot. The cost is that a player's setting equal to the old default follows a changed default.
* `on_applied` at registration only when a stored file exists. The cost is that a mod deriving state from its settings has to derive it from the defaults on its own.
