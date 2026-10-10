# Battery removal

## Intent

A new mod, Likho's Battery (`likhos-battery`). Every item that accepts batteries gets an option to take the battery back out. The removed battery carries the charge the device had and the device drops to zero. Batteries stop being implicitly 100%: a battery has its own charge, shows it and transfers exactly that charge when inserted. Prices follow charge: a battery is worth its charge and a device loses the value of the charge it is missing, but never the value of the device itself.

## Constraints and assumptions

* Vanilla has no battery entity inside a device. A device's `slotData.condition` is its charge. Dropping `Batteries` on a device runs `Interface.Charge`, which destroys the battery and sets the device to 100 after a 2 second progress.
* A battery-powered device is any item of type `Electronics` whose `itemData.compatible` contains the `Batteries` item. This is the same test vanilla `Interface.CombineCheck` uses to return combine code 5. No device list is hardcoded. In the current game this matches `PV7`, `Polaris`, `Phoenix`, `Narva` and `Casette_Player`, all of which have `showCondition` enabled.
* Only the `Batteries` item is in play. `Battery` (car battery) and `Battery_Cables` are unrelated.
* A device at 0% behaves exactly as in vanilla: it has no power and holds nothing to remove. A battery drained to 0% inside a device is gone.
* A battery's charge is its `slotData.condition`. `SlotData` already persists it, so no new saved state exists. Charge is carried as the exact float value. Display rounds it.
* Batteries from loot, traders and crafting are created with the `SlotData` default of 100, so new batteries are full without any change to those paths.
* Ruled out: trader tasks and recipes that consume `Batteries` keep accepting a battery of any charge.
* Vanilla `Item.Value` exempts `Electronics` from condition scaling, so in vanilla neither batteries nor devices are priced by charge.
* A device's price is treated as the device itself plus one full battery. Every current device is worth more than the `Batteries` item (100): Narva 180, Casette Player 250, Polaris 375, Phoenix 750, PV7 2750. No price floor exists for a device worth less than a battery.
* Ruled out: merging or topping up charge between two batteries.
* Vanilla has four `Remove_N` context buttons, used for a device's nested items in order. A device with four nested items has no button left for the battery and offers no battery entry. No such device exists: the casette player holds one cassette and the other devices hold nothing.
* Assumption, unverified: `Context.gd` `Update` can be wrapped by the loader's hook codegen. It is not on a skip list, but no existing mod hooks it.
* Assumption, unverified: `Item.Value` is the only pricing path for inventory items.
* Assumption, unverified: when the vanilla progress is cancelled, `activeProgress` is null by the time `completed` resumes the caller, as vanilla `Charge` assumes.

## Scope

Owned: the new mod folder `likhos-battery/`.

* `mod.txt`
* `Scripts/Main.gd`
* `Scripts/BatteryUtil.gd`, the shared contract
* hook handler scripts under `Scripts/`, one per hooked vanilla script, following the convention of `likhos-tacmed/Scripts/Interface.gd`

Context only: vanilla `Interface.gd` (`Charge`, `Combine`, `CombineCheck`, `ContextRemove`, `Create`, `Return`), `Context.gd` (`Update`), `Item.gd` (`Value`, `UpdateDetails`), `Tooltip.gd`, `Flashlight.gd`, `NVG.gd`, `mod-lib/Main.gd`.

Not owned: other mods, `mod-lib/`, repo documentation.

## Solution

### `mod.txt`

Declares the mod (`id="likhos-battery"`, name `Likho's Battery`), the autoload for `Scripts/Main.gd`, the `[registry]` opt-in and `[hooks]` for `Interface.gd` (`Charge`, `ContextRemove`), `Context.gd` (`Update`) and `Item.gd` (`Value`).

### `Scripts/Main.gd`

Extends `Lib/Main.gd`. In `setup` it patches the `Batteries` item through the registry so `showCondition` is true, then registers the hooks below. With `showCondition` set, vanilla `Item.UpdateDetails` and `Tooltip` show the battery's charge with the usual colour thresholds.

### Insert: replace hook on `Interface.Charge`

Vanilla drag and drop is untouched: `CombineCheck` still returns code 5 and `Combine` still calls `Charge(targetItem, sourceItem)`. The replace hook takes over from there and suppresses vanilla. It keeps the vanilla 2 second progress and the `isOccupied` handling. Because vanilla `Charge` is a coroutine, the handler follows the `RTVModLib.md` pattern of a synchronous replace that spawns the coroutine.

On completion the device and the battery exchange charge:

* The device's condition becomes the inserted battery's condition.
* If the device had charge above 0, the battery item survives with the device's previous charge, at the grid position it was dragged from.
* If the device was at 0, the battery item is destroyed.

If the progress is cancelled, neither item changes and the battery stays where it was dragged from.

### Remove: post hook on `Context.Update`, replace hook on `Interface.ContextRemove`

The context menu of a battery-powered device with charge above 0 shows a `Remove (Batteries)` entry on the first vanilla `Remove_N` button that the device's nested items leave unused. Vanilla labels those buttons `Remove (<item>)` and keeps them at the bottom of the menu, so the battery entry sits directly below the device's other Remove entries, such as the casette player's cassette. The entry is offered whether the device sits in a grid or in an equipment slot.

`ContextRemove` is replaced only for the battery's button index, which is one past the device's nested items. Every other index falls through to vanilla. If the device has drained to 0 by the time the entry is used, nothing is removed. Otherwise the handler works like vanilla nested item removal, instant and with the attach sound:

* A `Batteries` item is created with the device's condition, in the device's grid, or in the inventory grid when the device is equipped. With no room it drops to the ground, as vanilla `Create` does.
* The device's condition is set to 0 and its details refresh.

An equipped flashlight, NVG or casette player that is switched on turns off by itself, since vanilla already polls for condition at or below 0.

### Price: replace hook on `Item.Value`

For the `Batteries` item and for every battery-powered device, the handler returns the vanilla value minus the missing share of charge priced at the `Batteries` item's value. A battery at 40% is worth 40% of a battery. A device at 40% is worth its vanilla value minus 60% of a battery. A device at 0% is worth its vanilla value minus one battery. Every other item gets the vanilla result unchanged.

Removing or inserting a battery therefore never changes the combined price of the device and the battery.

### Shared contract: `Scripts/BatteryUtil.gd`

A static utility script that the handlers reference directly. `Main.gd` stores the `Batteries` item data in it during setup. Through it the handlers share one test for "battery-powered device" as defined in the constraints, and resolve the `Batteries` item data once. Removal additionally requires charge above 0. Pricing applies at any charge.

### Observable result

* Batteries show a charge percentage in the grid and in the tooltip.
* Right clicking a charged PV7, Polaris, Phoenix, Narva or casette player offers `Remove (Batteries)` at the bottom of the menu, below `Remove (<cassette>)` on a casette player. Using it yields a battery with the device's charge and leaves the device at 0%.
* Dropping a 60% battery on a 20% device leaves the device at 60% and the battery at 20%.
* Dropping a battery on a 0% device consumes it and gives the device that battery's charge.
* A 40% battery sells for 40% of the full battery price.
* A Narva is worth 180 at full charge, 140 at 60% and 80 at 0%.

## Tradeoffs

* 0% means empty, chosen over a tracked "dead battery inside" state. No new saved data and vanilla behaviour at 0% is intact. The cost is that fully drained batteries vanish instead of leaving a dead item.
* The battery entry uses a spare vanilla `Remove_N` button, chosen over adding a button node to the context menu. No UI nodes are created and the entry sits with the other Remove entries. The cost is the four button limit and a collision if another mod uses the same spare button.
* `Charge`, `ContextRemove` and `Item.Value` are replace hooks, which are single-owner. Another mod replacing the same method wins or loses wholesale. Pre and post hooks cannot suppress vanilla or change a return value, so they do not fit.
* The inserted battery item is kept and re-charged on swap, chosen over destroying it and creating a new one. The returned battery needs no free grid space. The cost is that it reappears in its original position, not next to the device.
* Devices are priced by charge, which changes vanilla prices: a looted device below 100% is worth less than in vanilla. Chosen over leaving device prices alone, which would make pulling the battery before a sale pay out the battery's price for free.
* The missing charge is priced at the flat `Batteries` value for every device, chosen over a percentage of the device's own value. The device and battery prices always add up, and an expensive device loses little. The cost is that a device cheaper than a battery would go to zero or below.
