# AFAK medkit refill

## Intent

In TacMed the AFAK is refilled by dragging a Medkit onto it in the inventory, the same way the IFAK is refilled by its components. Each Medkit restores 50% of the AFAK's condition. Today the AFAK can only be refilled through the crafting recipe, which needs two Medkits at once and a full craft.

## Constraints and assumptions

* Vanilla `Interface.CombineCheck` allows a drop of one item onto another when the target's `ItemData.compatible` lists the dragged item. For a Medical target with a Medical source it reports the plain combine case, which sets `canCombine`. This is what makes the IFAK accept its components, and nothing else in vanilla gates the drop.
* The AFAK has no `compatible` entries in vanilla, so a Medkit dragged onto it today falls through to a grid swap or a return.
* Vanilla `Interface.Release` would run its own `Combine` on a `canCombine` drop. TacMed's `interface-release-pre` hook takes the drop over by clearing the drag state before vanilla reads it.
* Item healing values at runtime are the patched ones: Medkit 75 HP (vanilla), AFAK 150 HP and IFAK 100 HP (both set by TacMed's item patches). A Medkit is therefore half of the AFAK's pool.
* A Medkit has no condition of its own. It is always a whole Medkit.
* Decided: the crafting recipe `tacmed_AFAK` (Used AFAK + 2x Medkit gives AFAK at 100%) stays as it is. Both refill paths exist and cost the same.
* Ruled out: any other item refilling the AFAK. Medkit only.
* Ruled out: rejecting a Medkit that would overfill. As with the IFAK, a drop is refused only on a full AFAK. Otherwise the Medkit is consumed and the condition is capped at 100%, the excess lost.
* Ruled out: a refill from the quick heal keybind or the context menu. Drag and drop only.
* Assumption, unverified: `lib.patch` applies a `compatible` list to the AFAK item the same way it does for the IFAK.

## Scope

Owned:

* `likhos-tacmed/Scripts/Interface.gd`: the `TACMED` table and the replenish path (`on_release_pre`, `_combine`).
* `likhos-tacmed/Scripts/Main.gd`: the AFAK item patch in `_patch_items`.
* `likhos-tacmed/README.md`: the AFAK section and the IFAK replenishment sentence.
* `likhos-tacmed/CHANGELOG.md`: the entry for this feature.

Context only:

* `likhos-tacmed/Scripts/Interface.gd` beyond that: the heal path (`on_use`, `_use`, `_use_anim`) and the quick heal keybind.
* `likhos-tacmed/Recipes/AFAK.tres` and `_register_recipes` in `Main.gd`: the recipe that stays.
* `likhos-tacmed/README.bbcode`: generated from the README, not edited by hand here.
* `likhos-tacmed/INSTRUCTIONS.md`.
* Vanilla `src/Scripts/Interface.gd`: `CombineCheck`, `Release`, `Combine`, `Reset`, `Return`.
* Vanilla `src/Items/Medical/Medkit/Medkit.tres` and `AFAK/AFAK.tres`.

## Solution

### AFAK item patch

`Main.gd` patches the AFAK with a `compatible` list holding the Medkit, alongside its existing overrides. This is the only thing that makes the game offer the drop, and it puts the Medkit in the AFAK's compatible list in the tooltip, as the IFAK shows its components.

### Replenish table

The `TACMED` entry of the AFAK carries a replenish time of its own, 5 seconds, the same as the recipe's craft time. The IFAK's stays at 1 second. The presence of a replenish time is what marks an item as refillable by drag and drop, so `on_release_pre` routes a Medkit dropped on an AFAK into `_combine` with no item specific branch.

### Replenish amount

`_combine` serves both kits through one rule: the dropped item's healing value is added to the kit's healing pool 1:1, expressed as condition. The condition gained is the source's healing value as a share of the target's pool.

* Medkit on AFAK: 75 HP of a 150 HP pool, 50% condition.
* IFAK components: unchanged, since the IFAK's pool is 100 HP and the share equals the healing value.
* A source with no healing value (tourniquets on the IFAK) gains the kit's flat default, a condition percentage, as today.

The rest of the flow is the IFAK's: a drop on a kit at 100% is refused with the error sound and the item returns to its place, otherwise the dragged item hides, the progress bar runs on the kit for the replenish time, the condition rises capped at 100%, the kit's details refresh and the dragged item is consumed. A player who dies during the bar gets no refill.

### Docs

The README's AFAK section lists both refill paths: a Medkit dragged onto the AFAK for 50% each, and the recipe. Its replenishment sentence states the 1:1 rule against the kit's pool. The changelog entry says the AFAK can be refilled by dragging a Medkit onto it, 50% per Medkit.

### Observable result

* Dragging a Medkit over an AFAK highlights it as a valid combine target, as a bandage does over an IFAK.
* Dropping a Medkit on an AFAK at 0% plays the stack sound, runs a 5 second bar on the AFAK and leaves it at 50%. The Medkit is gone.
* A second Medkit brings it to 100%.
* A Medkit dropped on an AFAK at 80% brings it to 100%. The Medkit is gone.
* A Medkit dropped on an AFAK at 100% plays the error sound and returns to where it was dragged from.
* A bandage or any other item dropped on an AFAK behaves as in vanilla.
* A Medkit dropped on an IFAK behaves as in vanilla. IFAK refills are unchanged.
* The AFAK tooltip lists the Medkit as compatible.
* The AFAK refill recipe is still in the Medical crafting section and works as before.

## Tradeoffs

* **Both refill paths over drag and drop alone.** The recipe keeps working for players used to it. The cost is two paths to the same result and a recipe that the partial refill makes redundant.
* **One 1:1 rule against the kit's pool over a fixed 50% for the AFAK.** Both kits share one calculation, and the README's 1:1 claim holds for both. The cost is that the 50% is derived: a change to the Medkit's healing value or to the AFAK's pool moves it.
* **A 5 second bar per Medkit over the IFAK's 1 second.** A Medkit is a far larger refill than a bandage and the bar matches the recipe's craft time. The cost is 10 seconds for a full refill by drag and drop against 5 by the recipe.
* **Overfill consumed over refused.** It matches the IFAK and needs no extra rule. The cost is a Medkit partly wasted on an AFAK above 50%.
