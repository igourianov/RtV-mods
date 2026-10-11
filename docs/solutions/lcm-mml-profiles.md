# LCM settings per Mod Loader profile

## Intent

Likho's Config Manager keeps a separate set of values for every Metro Mod Loader (MML) profile. The values of all profiles of one mod stay in that mod's one store file, each profile under its own section. A profile that has nothing stored runs on the config's defaults. It never takes values from the `Default` profile or from any other section.

## Constraints and assumptions

Constraints:

* MML has no public accessor for the active profile. It persists the name as `active_profile` under `[settings]` in `user://mod_config.cfg`, and treats a missing key as `Default`.
* `_run_pass_1` in `vostok-mod-loader/src/lifecycle.gd` saves that file after the launcher closes and before any mod is loaded or the game restarts into pass 2. By the time any mod script runs, early autoloads included, the file names the profile of this run.
* The loader's own `_active_profile` variable still holds its initial `Default` while early autoloads run in pass 2, so it is not a safe source for a consumer that registers there.
* MCM takes the profile the same way: `GetCurrentModLoaderProfile` in `MCM/Main.gd` reads the same key once at startup.
* A profile name holds cased letters of any script, digits, spaces, hyphens and underscores (`_sanitize_profile_name` in `vostok-mod-loader/src/profiles.gd`). It never holds a dot or a bracket.
* While a modpack is applied the active profile is its managed slot, `modpack__<name>`. To LCM that is a profile name like any other.
* A profile switch restarts the game. Renaming the active profile, or copying it into a new one, from the main menu's Mods button changes the active profile without a restart.
* MML renames, copies and deletes profiles in its launcher, mostly before any mod code runs. LCM gets no signal for any of it.
* LCM stores only the values that differ from the default, so a missing key means the default. With a fallback to another section a profile could not hold a default value where the other section holds a changed one.
* `ConfigFile.save` writes the whole file. Sections of other profiles survive a save only when the file is loaded before it is written.

Ruled out:

* Falling back to the `Default` profile's section, or to any other section, for a profile without a section or for a key missing in its section.
* Seeding a new profile from another profile's values, the way MCM copies its default file into a new profile's file.
* Following a profile rename, copy or delete. Accepted by the user.
* Pruning sections of profiles MML no longer lists.
* Giving the pre-profile values to whichever profile is active, copying them into every profile, or dropping them. They belong to `Default`.
* A prefix on the section names, such as `profile.<name>`.
* Reading the loader's `_active_profile` variable.
* One store file per profile.
* Any change to the menu. It does not show the profile.
* Any change to the consumer API. `register_config` keeps its signature.

Assumptions, unverified:

* `ConfigFile` reads back a section whose name holds spaces and non-ASCII letters exactly as written. MML's own `[profile.<name>.enabled]` sections rely on the same.

## Scope

Owned:

* `likhos-config-manager/Scripts/LCM.gd`: the store.
* `likhos-config-manager/README.md`: what it tells players and mod authors about where and how settings are saved.

Context only:

* `likhos-config-manager/Scripts/Main.gd` and `ModMenu.gd`. The menu applies a page through `LCM._apply` and does not know about profiles.
* `likhos-config-manager/CHANGELOG.md` and `README.bbcode`.
* The consumers: `mod-lib/` and the mods that call `register_config`.
* `vostok-mod-loader/` and `MCM/`.
* `docs/solutions/likhos-config-manager.md`. This solution supersedes its store section and its ruling against per-profile settings.

## Solution

### Active profile

* LCM resolves the active profile name once per game run, on the first store access, from `active_profile` under `[settings]` in `user://mod_config.cfg`. It holds the name in the static state of the API script for the rest of the run.
* A missing file or key resolves to `Default`, the name MML itself uses in that case.
* The name is used as read. LCM does not check it against MML's profile list.

### Store

One file per mod, `user://LCM/<mod_uid>.cfg`, as before. Inside it, one section per profile, named with the profile name as it is. A section holds the settings of that profile whose value differs from the default, keyed by field name.

```
[Default]
sway_scale=0.5

[My Hardcore Build]
sway_scale=1.2
lean_enabled=false
```

* Registration reads the active profile's section only. With a section, LCM writes its values into the config object and calls `on_applied` once. Without one the object stays on its defaults and `on_applied` is not called, whatever other sections the file holds.
* Applying a page writes the active profile's section and leaves every other section of the file as it was.
* A profile whose values all equal the defaults has no section, unless values of removed fields keep it there.
* A save touches the active profile's section one field at a time: it stores the value of a field that differs from the default and erases what is stored for a field that equals it. It never clears the section as a whole.
* A stored value whose type no longer matches its field is ignored on load, and the next save replaces or erases it like any other field's.
* A stored value whose field is gone is ignored on load and stays in the file. No save removes it.

### Pre-profile values

A store file written before this solution holds one `[values]` section shared by all profiles.

* A pre-profile file is recognized by `[values]` being its only section. In a file with any other section, `[values]` is the section of a profile named `values` and is left alone.
* In a pre-profile file, `[values]` is the `Default` profile's section under its old name. Whenever such a file is read, under any profile, its `[values]` section is taken as its `[Default]` section.
* A profile other than `Default` still never reads those values. They are in `[Default]`, which is not its section.
* The file is written under actual profile names only. The mod's next save, under any profile, writes the old values as `[Default]` and leaves no `[values]` behind.
* Reading alone never rewrites the file. `[values]` stays in it until that save.
* The translation is temporary code, to be deleted once old store files are no longer expected. It is one self-contained step in `LCM.gd`, applied to a store file as it is read and before the regular load or save looks at it. The regular load and save know nothing about `[values]` and share no state or branches with the step, so deleting the step and its call leaves them untouched.

### Observable result

* Two profiles hold different values for the same mod. Switching the profile in MML switches the values.
* A new profile starts every LCM mod on its defaults. So does a renamed profile and a copy of an existing one.
* After the update, the `Default` profile keeps the values the player had. Every other profile starts on the defaults, also when it is the one in use.
* The menu and the consumer API look and behave as before.

## Tradeoffs

* Reading `mod_config.cfg` over the loader's `_active_profile` variable. The cost is a dependency on the loader's settings file. The gain is a documented key that is correct at any point of startup, which LCM's promise that a consumer can register at any time needs.
* Sections in the mod's one file over a file per profile. The cost is that every save loads and rewrites the values of all profiles. The gain is one file per mod, as before.
* No fallback and no seeding over starting a new profile from existing values. The cost is that a player sets a mod up again in every profile. The gain is that a stored default cannot be shadowed and a default changed by a mod update reaches every profile that never touched the setting.
* Ignoring the profile lifecycle over tracking it. The cost is that a renamed profile loses its LCM values, which stay in the file under the old name, and that a profile created under the name of a deleted one picks up the deleted one's values.
* Resolving the profile once per run over reading it on every store access. The cost is that after a rename or copy from the main menu's Mods button, changes made in the rest of that run are saved under the previous name. The gain is that all mods load and save under the same profile within a run.
* Reading the pre-profile values as `Default` over giving them to the active profile or to every profile. The cost is that a player who is on another profile at the update starts on the defaults there, with the old values waiting in `Default`. The gain is that nothing is written at registration and the outcome does not depend on which profile happens to be active first.
* Bare profile names as section names over a prefix. The cost is that a profile named `values` is taken for the pre-profile section in a mod's file where it is the only section, and its values end up as `[Default]` on the next save. That lasts while the pre-profile step exists. The file also has no section name left that could not be a profile.
* Erasing per field over rewriting the section on save. The cost is that a value of a removed field stays in the file for good. The gain is that a save removes only what it has a reason to remove.
* LCM values are outside MML's modpack and profile snapshot machinery. A shared modpack carries its MCM settings and no LCM settings.
