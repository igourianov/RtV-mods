# Empty container tooltip

## Intent

In VosTac the interaction prompt of a loot container ("Crate [Open]") is not shown when the container holds no items and the player is outside a shelter. Looking at a container tells the player whether it is worth opening. An LCM toggle turns the behavior off and restores the vanilla prompt.

## Constraints and assumptions

* Vanilla `Interactor._physics_process` calls `UpdateTooltip` on the looked-at interactable every 5 physics frames and sets `gameData.interaction` to true right after the call. `LootContainer.UpdateTooltip` only writes `gameData.tooltip`. A hook on `UpdateTooltip` therefore cannot clear `gameData.interaction`, and does not need to.
* Vanilla `HUD._physics_process` copies `gameData.tooltip` into the prompt label and sets the prompt visible from `gameData.interaction` every 10 physics frames. It is the only reader of `gameData.tooltip`.
* VosTac already forces the prompt hidden after vanilla, every frame, in `Crosshair._update_tooltip`, which runs from the `hud-_physics_process-post` hook.
* A container serves `storage` once `storaged` is set and `loot` before that. Vanilla `LootContainer.AILoot` and the container grid fill in `Interface` select the list the same way. `storaged` is set when the player closes the container UI.
* AI corpses are `LootContainer` nodes (`AI.container`), and so are trader displays and player furniture with storage.
* `gameData.shelter` is true on the six shelter maps only. The tutorial map is not a shelter.
* Decided: the prompt is hidden, the interaction is not. Interact still opens an empty container, so the player can put items into it.
* Decided: a container that was never opened and rolled no loot counts as empty. The missing prompt reveals that before the player opens it.
* Decided: corpses follow the same rule as any other container.
* Decided: a locked container keeps its "[Locked]" prompt whatever it holds. The prompt reports a state the player can act on, and a locked container is not openable anyway.
* Decided: the tutorial map counts as outside the shelter, the rule applies there.
* Ruled out: blocking the interaction on empty containers. An emptied container could never be opened again.
* Ruled out: limiting the rule to containers the player already opened.
* Decided: the changelog entry goes under the existing top section, 3.7.2072. The feature gets no version section of its own.
* Ruled out: moving the prompt visibility rules out of `Crosshair.gd` into `Hooks/HUD.gd`. They share `_is_interaction_blocked` with the crosshair's own visibility, so the move relocates the lines and adds a dependency between the two files without removing any code.
* Assumption, unverified: `LootContainer` is wrapped by the mod loader's hook codegen like any other vanilla script, so `lootcontainer-updatetooltip-post` dispatches. It is on none of the loader's skip lists.
* Assumption, unverified: LCM lists an ungrouped `@export` bool of `Config.gd` as a toggle without further registration, as it does for `show_protips`.

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/LootContainer.gd`: the empty container rule.
* `likhos-vostac/Scripts/Config.gd`: the setting.
* `likhos-vostac/Scripts/Main.gd`: the hook wiring.
* `likhos-vostac/Scripts/Nodes/Crosshair.gd`: `_update_tooltip` only.
* `likhos-vostac/mod.txt`: the `[hooks]` section.
* `likhos-vostac/INSTRUCTIONS.md`: the hook list.
* `likhos-vostac/README.md`: the Controls & HUD section.
* `likhos-vostac/CHANGELOG.md`: the entry for this feature in the 3.7.2072 section.

Context only:

* `likhos-vostac/Scripts/Hooks/HUD.gd`: calls `Crosshair.update` from the HUD post hook.
* `likhos-vostac/Scripts/Hooks/Interactor.gd`.
* `likhos-vostac/Scripts/Hooks/Pickup.gd`: the pattern for a hook class that reads `_lib._caller`.
* `likhos-vostac/README.bbcode`: generated from the README, not edited by hand here.
* `likhos-vostac/mod.txt`: the version.
* Vanilla `src/Scripts/LootContainer.gd`, `Interactor.gd`, `HUD.gd`, `Loader.gd`.

## Solution

### Setting

`Config.gd` carries a boolean setting, `hide_empty_container_prompt`, enabled by default. It sits with the ungrouped general settings next to `show_protips`, since no existing group covers the HUD prompt. LCM lists it as a toggle and its changes take effect on the next prompt update, with no restart.

### Empty container rule

`Hooks/LootContainer.gd` is a hook class in the shape of `Hooks/Pickup.gd`. Its post hook on `LootContainer.UpdateTooltip` clears `gameData.tooltip` to an empty string when all of these hold:

* the setting is enabled
* `gameData.shelter` is false
* the container is not locked
* the list the container currently serves, `storage` once `storaged` and `loot` before that, has no entries

In every other case it leaves the text vanilla wrote. `Main.gd` creates the hook object and registers it on `lootcontainer-updatetooltip-post`, and `mod.txt` enrolls `LootContainer.UpdateTooltip` under `[hooks]`.

### Prompt visibility

An empty `gameData.tooltip` means there is no prompt to show. `Crosshair._update_tooltip` hides the HUD prompt while `gameData.tooltip` is empty, beside the aiming and blocked-interaction cases it already covers. It reads `gameData.tooltip` rather than the label, so the prompt disappears on the next frame instead of waiting for vanilla's 10 frame label refresh. The contract is not specific to containers: any source that clears the text gets the prompt hidden.

`gameData.interaction` stays as vanilla set it, so Interact opens the container as before and the crosshair behaves as before.

### Flow

The player looks at a container. The interactor calls `UpdateTooltip`, vanilla writes the container's prompt text, the post hook clears it when the rule applies. The HUD post hook then hides the prompt. When the player looks at another interactable, its `UpdateTooltip` writes a non-empty text and the prompt returns on vanilla's next HUD refresh.

### Docs

The README's Controls & HUD section says that empty containers show no prompt outside shelters and that LCM turns this off. `INSTRUCTIONS.md` lists `LootContainer.UpdateTooltip` (post) among the pre and post hooks. The changelog's 3.7.2072 section carries an entry that says the same as the README line.

### Observable result

* Outside a shelter, looking at a container with no items shows no prompt. Pressing Interact still opens it.
* Looking at a container with at least one item shows the vanilla "[Open]" prompt.
* A container the player empties loses its prompt once its UI is closed. Putting an item back into it brings the prompt back.
* An AI corpse with no items shows no prompt. A corpse that an AI looter filled shows it.
* A locked container shows "[Locked]" whether it holds items or not.
* In a shelter every container shows its prompt, empty or not.
* With the LCM toggle off, every container shows the vanilla prompt everywhere.
* Prompts of doors, items, switches and other interactables are unchanged.

## Tradeoffs

* **Prompt hidden with the interaction kept over a blocked interaction.** An empty container stays usable as storage. The cost is an interactable with no visible prompt, which the player has to know about.
* **Emptiness shown before opening over only after.** The player skips containers with nothing in them. The cost is that part of vanilla's search loop is gone: opening a container never reveals an empty grid.
* **Clearing the prompt text and one HUD rule for empty text over a dedicated flag in `Config`.** No new shared state, and the hook stays unaware of the HUD. The cost is that the container's name is no longer in `gameData.tooltip` for anything else that might read it. Vanilla reads it in the HUD only.
* **The rule in the tutorial over treating the tutorial as a shelter.** One condition, `gameData.shelter`. The cost is that a new player in the tutorial sees no prompt on empty containers.
