# Cleaning kit recipe

## Intent

No.9 has a crafting recipe that creates a new Cleaning Kit from a Toolbox plus the same consumables the refill recipe takes. The Toolbox is used up. The solution also lists loot items that fit gun cleaning as candidates for future recipe inputs, without using them.

## Constraints and assumptions

* Vanilla `RecipeData` has fixed input and output lists. There are no per-slot alternatives, so an alternative ingredient always means a separate recipe.
* Vanilla `Interface.DestroyInputItems` never destroys an input whose `ItemData` is `tool` or `repairs`, unless the recipe has `upgrade = true`, in which case every selected input is destroyed. The Toolbox is `tool = true`, which is why `Bed_Civilian` keeps it.
* `upgrade` has two effects in vanilla and no others: it destroys tool inputs (`Interface.DestroyInputItems`) and it hides the "returns" marker on the recipe's input icons (`Recipe.Initialize` passes `showReturns = false` to `Item.Display`). The only vanilla user is `KAR-21_Upgrade`.
* A recipe with `repair = false` runs `Interface.GetOutputItems`, which creates the output from a fresh `SlotData`. A fresh `SlotData` has condition 100.
* `Main._strip_repair_recipes` removes only `repair == true` entries from `Recipes.tres`'s weapons array. A non-repair recipe survives it with no exemption.
* The game has no gun oil, solvent, brush or patch item.
* Ruled out: keeping the Toolbox as a reusable tool. The user wants it consumed.
* Ruled out: making the Toolbox non-tool globally. That would also consume it in `Bed_Civilian`.
* Ruled out: using the candidate items below in any recipe now, either as extra inputs, as substitute variants or in the refill recipe.

## Scope

Owned:

* `likhos-no9/Recipes/Cleaning_Kit_Create.tres`: the create recipe.
* `likhos-no9/Scripts/Main.gd`: recipe registration in `setup`.
* `likhos-no9/README.md`: the Weapon Repair Kit feature list.
* `likhos-no9/CHANGELOG.md`: the section for the release that ships this.

Context only:

* `likhos-no9/Recipes/Cleaning_Kit_Refill.tres` and its registration: the refill recipe, unchanged.
* `likhos-no9/Scripts/Main.gd` beyond registration: `_patch_wrk`, `_localize_wrk_slotdata`, `_strip_repair_recipes`.
* `likhos-no9/Scripts/Interface.gd`: the drag and drop cleaning path.
* `likhos-no9/README.bbcode`: generated from the README.
* `likhos-no9/INSTRUCTIONS.md`: the recipe uses the registry API already listed there.
* Vanilla `src/Scripts/Interface.gd` (`Complete`, `DestroyInputItems`, `GetOutputItems`), `src/Scripts/Recipe.gd`, `src/Scripts/RecipeData.gd`, `src/Crafting/Furniture/Bed_Civilian.tres`.

## Solution

### Create recipe

`Cleaning_Kit_Create.tres` is a `RecipeData` resource following the layout of `Cleaning_Kit_Refill.tres`:

* Name "Cleaning Kit".
* Input: Toolbox, Antiseptic, Tissues, Tissues, Work Gloves. This is the refill recipe's input with the Toolbox in place of the kit.
* Output: Weapon_Repair_Kit.
* `repair = false`, `upgrade = true`. `upgrade` is what makes vanilla consume the Toolbox.
* Time 10 seconds, double the refill. Craft audio follows the refill's.
* No proximity requirement, matching the refill.

### Registration

`Main.setup` registers the recipe through `lib.register(lib.Registry.RECIPES, ...)` under the `weapons` category, the same way as the refill, with its own id `likhos_cleaning_kit_create`.

### Candidate items

Loot items that fit gun cleaning, all present in `LT_Master`, recorded for future use:

| Item | Spawns | Value | Fit |
| --- | --- | --- | --- |
| Rags | civilian, industrial | 20 | Wiping cloth and patch material. Strongest fit. Also used by the improvised medical recipes. |
| Coffee Filter | civilian | 75 | Lint-free patch material. Also used by Brewed Coffee. |
| Wipes | civilian | 120 | Degreasing and wiping. |
| Toilet Paper | civilian | 25 | Patch substitute. Weak fit. |
| Oil Filter | industrial, driver | 180 | Only by name. It holds no oil. Weak fit. |

### Docs

The README's Weapon Repair Kit list says a new kit can be crafted from a Toolbox, which is used up, plus the refill consumables. The changelog's section for the release says the same in one line.

### Observable result

* The weapons crafting section shows a "Cleaning Kit" recipe with a 00:10 timer and a "Craft" button, next to "Cleaning Kit Refill".
* Its input icons show no "returns" marker, the Toolbox included.
* Inputting a Toolbox, Antiseptic, two Tissues and Work Gloves and crafting consumes all five and yields a Cleaning Kit at 100% condition.
* `Bed_Civilian` still keeps its Toolbox.
* The refill recipe behaves as before.

## Tradeoffs

* **`upgrade = true` over a hook that destroys the Toolbox.** Pure data, no code, using a vanilla mechanism. The cost is relying on `upgrade` meaning only "consume tools" and "hide returns markers". A future game version that gives `upgrade` more meaning would change this recipe's behavior.
* **Same consumables as the refill.** A new kit costs a Toolbox (value 375) more than refilling one. The cost is that the kit (value 2750) is cheap to craft compared with its trade value.

## Open questions

* Changelog section: the version heading for the release that ships this. The build sets the version in `mod.txt`.
