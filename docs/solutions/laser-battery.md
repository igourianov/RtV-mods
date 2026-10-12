# Laser battery

## Intent

Likho's Battery (`likhos-battery`) manages batteries for weapon laser modules the way it does for flashlights. A laser has a charge, drains by its power tier while its beam is on and stops working at 0%. A battery can be dropped on a detached laser or straight on the gun that carries one. The battery can be taken back out only while the laser is detached. A laser that is running low flickers by the same rules as a flashlight. The flashlight flicker moves from VosTac into Likho's Battery, so one mod owns the low charge flicker for both.

## Constraints and assumptions

* Vanilla lasers have no charge. `Laser.gd` flips `active` on the `laser` action and shows or hides the beam. Nothing drains and nothing switches it off.
* A laser is an item with `subtype == "Laser"`. Vanilla has two, `OZ5` and `ANPEQ`. Both are `AttachmentData` of type `Attachment`, not `Electronics`, with an empty `compatible` list and no `showCondition`.
* Lasers inherit `ItemData.power` and leave it at `None`. Only `Flashlight.gd` and `NVG.gd` read it.
* An attached attachment has no state of its own. `SlotData.nested` is an `Array[ItemData]`, so the laser on a weapon is the shared item definition, not an instance. `Item.Combine` keeps the dragged item's `itemData` and discards its `SlotData`, condition included.
* Vanilla allows one attachment per subtype on a weapon, so a weapon carries at most one laser and no two powered attachments of the same item. Lasers are the only powered attachments today. The charge storage does not rely on that: it is keyed by item, so a second kind of powered attachment gets its own charge.
* Every path that moves an item (grid, slot, pickup, container, save and load) copies its `SlotData` through `SlotData.Update`, which copies the named fields only. Resource metadata on a `SlotData` does not survive. `storage` is one of the copied fields and vanilla uses it for furniture only.
* `SlotData.Update` duplicates the `storage` array, not its entries. Two copies of a weapon's `SlotData` share the charge entries until one of them is discarded.
* Vanilla `Interface.CombineCheck` returns 5 (charge) only for the `Batteries` item on an `Electronics` target that lists it in `compatible`. A battery on a weapon returns 0. A battery on a non `Electronics` item that lists it returns 1, which nests the battery as an attachment.
* Code 5 is honoured for a target in a grid and for a target in an equipment slot, so a battery can be dropped on a weapon in the inventory and on an equipped one.
* Vanilla detaches an attachment in two places, `Interface.ContextRemove` and the swap branch of `Interface.Combine`. Both build a fresh `SlotData` at condition 100 and hand it to `Interface.Create` in the same call. Both go through `Item.Remove` or `Item.CombineSwap`. Attaching goes through `Item.Combine`.
* Vanilla `Item.Value` scales every non `Electronics` item by condition, so a laser with a charge below 100 would lose a share of its own price.
* VosTac replaces `Laser._input` and has a post hook on `Laser._process` that switches the laser on by itself in canted aim. Replace hooks are single-owner, so this mod does not hook `Laser._input` and does not depend on who toggles `active`.
* Vanilla `Flashlight.Activate` rewrites the energy of both lights every time it runs, and `ResetCheck` re-runs it every 10 physics frames while the light is on, 83 ms at 120 physics ticks per second. It writes energy only for an equipped light with a power tier. VosTac replaces `Flashlight._physics_process` but still calls `ResetCheck` every tick, so the cadence is the same with and without VosTac.
* VosTac's post hook on `Flashlight.Activate` writes the beam's range and cone only. A second post hook that writes energy does not interact with it, in either order.
* The low charge flicker lives in Likho's Battery only and works without VosTac. VosTac holds none of it.
* The flicker is a visual cue. No sound, no HUD element, no change to drain, range, cone or color. `Sensor.gd` reads `gameData.flashlight` only, so AI detection is unaffected.
* A device at 0% holds nothing to remove. A battery drained to 0% inside a laser is gone.
* Looted detached lasers are rolled in the same 20-75% range as looted flashlights. Lasers bought from traders are full, as vanilla creates them.
* The registry enumerates items through `lib.find`, which walks the master loot table for vanilla items, and extends a list field through `lib.append`. Both vanilla lasers are in that table. Both methods exist in loader 3.4.2.
* In vanilla only `Electronics` items list `Batteries` in `compatible`, so a device test on the list alone matches the same items as before plus the patched lasers.
* `Item.Remove` is called only from `Interface.ContextRemove` and `Item.CombineSwap` only from the swap branch of `Interface.Combine`. On a weapon `CombineSwap` takes out the first attachment of the dragged item's subtype.
* A `WeaponRig`'s `slotData` is the equipped weapon item's own `SlotData`, not a copy.
* Vanilla `Tooltip.Update` calls `Reset` first.
* Ruled out: removing the battery from a laser while it is attached to a weapon. The weapon's context menu gets no battery entry.
* Ruled out: dimming the laser during a dip. A laser dip hides the beam and the dot.
* Ruled out: showing the charge of an attached laser on the weapon's grid label. That label is the weapon's condition.
* Ruled out: telling a drain apart from another change in charge that lands exactly one whole percent lower, such as a swapped battery. It plays one stray burst.
* Ruled out: flicker for the NVG and for the weapon-mounted light driven by `RigManager.gd`.
* Ruled out: AI lasers. `AI.gd` attaches lasers to its weapons but never runs `Laser.gd`.
* Assumption, unverified: nothing in vanilla misreads a non-empty `storage` on a weapon, and the entries survive drop, pickup, container transfer, decor placement, save and load. Seen so far: `Item.UpdateDetails` reads it for `Furniture` only and `Interface` forwards it to the pickup in decor mode. If this fails the design needs revisiting.
* Assumption, unverified: `Interface.CombineCheck`, `Interface.Create`, `Item.Combine`, `Item.Remove`, `Item.CombineSwap`, `Laser._process`, `Flashlight.Activate`, `Tooltip.Update` and `Tooltip.Reset` can be hooked from this mod. `Interface.gd` and `Item.gd` are already hooked by it for other methods, the rest are hooked by VosTac.
* Assumption, unverified: hooks dispatch on a script's internal calls, so `Interface.Create` called from inside `ContextRemove` and `Combine` reaches the pre hook. VosTac's hook on `Flashlight.Activate` relies on the same for calls from `ResetCheck`.
* Assumption, unverified: every `Laser.gd` node has a `WeaponRig` as `owner`. VosTac sets the owner on the lasers it mounts at runtime.
* Assumption, unverified: a post hook registered with a higher priority value runs after VosTac's on `Laser._process`. If it runs before, a dead laser switched on by canted aim shows for one frame.
* Assumption, unverified: adding `Batteries` to a laser's `compatible` list and setting its `power` have no effect beyond the tooltip's compatibility line, `CombineCheck` and this mod's drain.

## Scope

Owned in `likhos-battery/`:

* `mod.txt`
* `Scripts/Main.gd`
* `Scripts/BatteryUtil.gd`, the shared contract
* `Scripts/Flicker.gd`, the burst rules
* `Scripts/Interface.gd`, `Scripts/Item.gd`, `Scripts/Loot.gd`, `Scripts/Context.gd`
* `Scripts/Laser.gd`, `Scripts/Flashlight.gd` and `Scripts/Tooltip.gd`, one handler script per hooked vanilla script as the others
* `README.md`, `INSTRUCTIONS.md`

Owned in `likhos-vostac/`:

* `Scripts/Hooks/Flashlight.gd`. It holds the beam shaping, the `_physics_process` replacement and the input driver. It holds no flicker.
* `README.md`. The line about the flashlight flicker.

Owned in `mod-lib/`:

* `Tooltip.gd`. The row helpers shared by every mod.

Context only, not modified:

* Vanilla `src/Scripts/Laser.gd`, `Flashlight.gd`, `Interface.gd`, `Item.gd`, `Tooltip.gd`, `Context.gd`, `SlotData.gd`, `RigManager.gd`, `WeaponRig.gd`, `LootContainer.gd`, `LootSimulation.gd`.
* `likhos-vostac/Scripts/Main.gd` and `likhos-vostac/mod.txt`. The `Flashlight.Activate` post hook stays registered for the beam shaping.
* `likhos-vostac/Scripts/Hooks/Laser.gd` and `Scripts/AttachmentMounts.gd`. The other writer of `active` and the runtime laser mounts.
* `mod-lib/Main.gd`.
* `likhos-vostac/Scripts/Hooks/Tooltip.gd`. The other user of the row helpers.

Not owned: other mods, the rest of `mod-lib/`, repo documentation and the `CHANGELOG.md` of both mods.

## Solution

### Tunables

| tunable | value |
|---|---|
| laser drain by power tier | Low 0.05, Medium 0.1, High 0.2 percent per second while the beam is on, doubled in winter. The vanilla flashlight rates |
| power tier of a laser that has none | Medium |
| looted and first-seen charge | random, 20% to 75% |
| flicker threshold | 5% |
| burst points | 5%, 4%, 3%, 2% |
| continuous phase | at or below 1% |
| dips in a burst | 1 to 3 |
| dip length and pause before each dip | 1 or 2 steps of 10 physics frames, about 0.08 to 0.17 s |
| flashlight dim factor during a dip | random, 0.3 to 0.7 |

A full Medium laser lasts 16 minutes 40 seconds of beam time, half that in winter.

### Where the charge lives

A detached laser is an inventory item with its own `SlotData`. Its charge is that `SlotData`'s `condition`, exactly as for a flashlight.

Attaching a laser throws that `SlotData` away. The weapon keeps only the laser's item definition in `nested`, which has no room for a charge. So while a laser is attached, its charge is kept in a second list on the weapon, `storage`, as a small `SlotData` that names the laser and holds the charge:

```
weapon SlotData
	itemData:  AK-12
	condition: 87                  the weapon's wear, never touched by this mod
	nested:    [Magazine, OZ5]     what is attached, vanilla
	storage:   [SlotData { itemData: OZ5, condition: 60 }]     the OZ5's charge
```

* Attaching a 60% laser adds that entry. Detaching the laser takes the entry out and gives the laser item its 60% back.
* While attached, everything that concerns the laser's charge reads and writes the entry's `condition`: drain, a battery dropped on the weapon, the tooltip and the price.
* An entry belongs to one attachment and is found by its `itemData`, never by its position in the list. A weapon with two powered attachments has two entries, and each attachment drains its own.
* Entries that do not name a powered attachment of that weapon are left alone.
* The entries move and save with the weapon through vanilla's own copying.

A weapon that carries a powered attachment but has no entry for it gets one the first time that charge is needed, with a charge rolled in the first-seen range. This is the single path for AI drops, looted weapons and saves made before this feature.

### Shared contract: `Scripts/BatteryUtil.gd`

* The battery-powered device test: an item that lists `Batteries` in `compatible`. It does not require type `Electronics`, so it holds for lasers once `Main.gd` has patched them.
* The charge holders of an item: every `SlotData` whose `condition` is a battery charge that item carries. A device has one, its own `SlotData`. A weapon has one per powered attachment in `nested`, the attachment's entry in the weapon's `storage`, created on demand as described above. Anything else has none.
* The charge holder of one attachment on a weapon, looked up by the attachment's item. The laser handler, the attach and detach hooks and the tooltip use it.
* The charge holder a dropped battery goes to: the item's only holder, or on a weapon with several the one with the lowest charge.
* Removability is unchanged: the item is itself a device and its own charge is above 0. A weapon is never removable.
* The charge range shared by the loot roll and the first-seen roll.

### `Scripts/Main.gd`

In `setup`, next to the existing `Batteries` patch, every laser item found in the items registry is patched:

* `showCondition` is true, so vanilla shows the charge of a detached laser in the grid and in the tooltip with the usual colour thresholds.
* `Batteries` is appended to `compatible`, so the laser passes the device test and its tooltip lists batteries.
* `power` is `Medium` when the laser has no tier. A laser that already has a tier keeps it.

`Main.gd` creates the handlers and registers the hooks below.

### Insert: `Interface.CombineCheck` and `Interface.Charge`

`CombineCheck` is a replace hook that returns the vanilla result, except that the `Batteries` item dragged onto any item with a charge holder returns 5. That covers a detached laser, where vanilla would nest the battery, and a weapon carrying a laser, where vanilla refuses. A weapon without a powered attachment still refuses.

The `Charge` replace hook exchanges charge between the battery and the charge holder the contract picks for the target, with the 2 second progress and these rules: the holder takes the battery's charge, the battery survives with the holder's previous charge or is destroyed if that was 0. On a weapon the progress bar covers the weapon item and the weapon's own condition is untouched.

### Remove: detached laser only

A detached laser with charge above 0 passes the removability test and shows `Remove (Batteries)` through the `Context.Update` and `Interface.ContextRemove` handlers like any other device. A weapon does not, with or without a laser.

### Attach and detach: `Item.Combine`, `Item.Remove`, `Item.CombineSwap`, `Interface.Create`

The charge follows the laser on and off the weapon.

* Attach: a post hook on `Item.Combine`. When the dragged item is a powered attachment, the weapon's `storage` gets an entry for that item with the dragged item's charge.
* Detach: pre hooks on `Item.Remove` and `Item.CombineSwap`. When the attachment about to leave `nested` is powered, the entry for that item leaves the weapon's `storage`. Other entries stay. A pre hook on `Interface.Create` then writes that charge onto the `SlotData` vanilla creates for the detached item in the same call.
* Swapping one laser for another on a weapon is a detach followed by an attach, so the old laser comes out with its charge and the new one keeps its own.

No vanilla method is replaced for this, so magazine and optic handling in `Interface.Combine` and `Interface.ContextRemove` stays vanilla.

### Price: `Item.Value`

The replace hook prices every device as itself plus one full battery:

* A battery, a flashlight or another `Electronics` device is worth its vanilla value minus the missing share of charge priced at the `Batteries` value.
* A detached laser is worth its full item value minus the same missing share. Vanilla's condition scaling of the laser's own price does not apply.
* A weapon is worth its vanilla value, which already includes the full value of every attachment, minus the missing share of charge of each of its charge holders.

Attaching, detaching, inserting or removing a battery therefore never changes the combined price.

### Loot: `Scripts/Loot.gd`

The loot roll covers lasers next to flashlights: a detached laser from a container or a world spawn gets a charge in the shared range. Weapons are not touched here. Their lasers are covered by the first-seen roll.

### Burst rules: `Scripts/Flicker.gd`

One object per light source holds the flicker state: the last whole percent seen and the dips and pauses left in the running burst. Its owner calls it once per step with the current charge and gets back whether this step is inside a dip. A step is 10 physics frames. The object knows nothing about lights, lasers or how a dip looks.

* A burst starts when the charge has drained from one whole percent into the next one down and the new one is at or below the threshold. It is laid out in full at that moment: 1 to 3 dips, each 1 or 2 steps long and each preceded by a pause of 1 or 2 steps.
* Only a step down of exactly one whole percent counts as draining. A first sighting, or a charge that lands more than one whole percent lower, starts nothing.
* At or below 1% a new burst starts on the first step after the previous one ends, whether or not the charge drained into it. Every dip comes after its pause, so the bursts form one unbroken strobe.
* A running burst is dropped when the charge comes back higher. Otherwise a burst cut short finishes the next time the source is stepped.

### Flashlight: post hook on `Flashlight.Activate`

`Scripts/Flashlight.gd` owns one `Flicker`. Vanilla `Activate` runs first and writes the equipped light's full energy on both lights. The handler steps the flicker with the charge of the item in the light slot and, inside a dip, multiplies both energies by a dim factor picked at random for that step. The light never goes fully dark before vanilla switches it off at 0%.

* The activation is the step. The handler has no node, no timer and no per-frame processing.
* When vanilla returned without writing energy, the handler does nothing. The energy standing there is the one dimmed last time and dimming it again would compound.
* No restore step exists. Vanilla rewrites the full energy on the next activation.
* Every light in the slot flickers, with no test for battery compatibility.

### Laser: post hook on `Laser._process`

`Scripts/Laser.gd` owns one `Flicker`. It acts on a laser node only while the node is shown on a rig, which is how vanilla marks the laser attached. The node is named after its item's `file`, and the handler reads and drains the charge holder of that item on the rig's weapon, never another attachment's. It polls, so it works the same whether vanilla or VosTac toggled the laser.

* Drain. While `active`, the charge drops at the rate of the laser's power tier, doubled in winter by the same season test vanilla `Flashlight.Consumption` uses.
* Cut-off. At 0% the laser is switched off: `active` is false and the beam is hidden. A laser at 0% that anything switches on is switched off again in the same frame, so it never lights. The vanilla and VosTac click sounds still play.
* Flicker. While `active`, the handler steps the flicker every 10 physics frames, since the laser has no vanilla activation tick. During a dip the beam and the dot are hidden. Outside a dip they are shown.

One laser is live at a time, so the flicker state is kept once and not per node.

### Tooltip: post hooks on `Tooltip.Update` and `Tooltip.Reset`

`Scripts/Tooltip.gd` extends `Lib/Tooltip.gd` and uses its row helpers, the way VosTac adds optic rows. The tooltip of a weapon shows one row per powered attachment, titled with the attachment's display name and holding its charge as a whole percent. The rows are hidden for every other item and on reset.

Vanilla `Tooltip.Update` fits the panel to its content and centers the tooltip on it as its last step, so a row shown from a post hook lands in a panel already sized without it. `mod-lib/Tooltip.gd` owns the correction: showing a row through its helper fits and centers the panel again, the way vanilla does. Handlers in the mods do no sizing of their own, and VosTac's optic rows get the same correction.

### VosTac

`Hooks/Flashlight.gd` shapes the beam in the `Activate` post hook and replaces `_physics_process`, as before. It keeps no charge or burst state and never writes light energy. The README does not list the flashlight flicker.

### `mod.txt`, `INSTRUCTIONS.md`, `README.md` of Likho's Battery

`mod.txt` declares the hooks, `INSTRUCTIONS.md` lists them under Compatibility:

| script | methods | kind |
|---|---|---|
| `Interface.gd` | `Charge`, `ContextRemove`, `CombineCheck` | replace |
| `Interface.gd` | `Create` | pre |
| `Item.gd` | `Value` | replace |
| `Item.gd` | `Remove`, `CombineSwap` | pre |
| `Item.gd` | `Combine` | post |
| `Context.gd` | `Update` | post |
| `Laser.gd` | `_process` | post |
| `Flashlight.gd` | `Activate` | post |
| `Tooltip.gd` | `Update`, `Reset` | post |
| `LootContainer.gd` | `CreateLoot` | post |
| `LootSimulation.gd` | `SpawnItems` | post |

`INSTRUCTIONS.md` also lists the registry changes on the laser items. The README's feature list covers laser charge and drain, the battery drop on the gun, removal from a detached laser only and the low charge flicker of flashlights and lasers. Its requirements name Metro Mod Loader 3.4.2 or later, the version the registry calls were confirmed in.

### Observable result

* A detached OZ5 or AN-15 shows a charge percentage in the grid and in the tooltip and lists Batteries as compatible.
* Dropping a 60% battery on a detached laser at 20% leaves the laser at 60% and the battery at 20%. Dropping it on a rifle that carries that laser does the same, in the inventory or in the weapon slot.
* Dropping a battery on a rifle without a laser is refused, as in vanilla.
* Right clicking a detached, charged laser offers `Remove (Batteries)`. Right clicking the rifle never does.
* Detaching a laser from a rifle yields a laser with the charge it had on the rifle. Attaching it again carries the charge back.
* The rifle's tooltip shows `OZ5: 60%`.
* With the beam on, the charge drops by 1% every 10 seconds, every 5 in winter.
* At 5%, 4%, 3% and 2% the beam and dot blink off one to three times in quick succession. From 1% they blink without a break until the laser switches off at 0%.
* A laser at 0% does not light, by key or by VosTac's canted aim.
* A rifle taken from an AI or loaded from an older save has its laser at a random 20-75%, fixed from the first time it is hovered or used.
* An OZ5 is worth 1250 at full charge, 1190 at 40% and 1150 at 0%. A rifle carrying it loses the same 60 and 100.
* A flashlight flickers as it did under VosTac: both lights dip to between 30% and 70% brightness at 5%, 4%, 3% and 2%, and strobe from 1% until the light switches off. The warnings are 20 s apart on the Narva, 10 s on the Polaris and 5 s on the Phoenix, half that in winter.
* With Likho's Battery and without VosTac, flashlights and lasers flicker. With VosTac and without Likho's Battery, nothing flickers.

## Tradeoffs

* **The weapon's `storage` over a new saved field or metadata.** No save format change and vanilla's own copying carries the charge everywhere the weapon goes. The cost is a vanilla field used for something it was not meant for, which a game patch or another mod reading `storage` on weapons could break.
* **A charge rolled on first need over a hook on every source of weapons.** One path covers AI drops, loot, traders and old saves. The cost is that the roll happens on hover or first use and not at spawn, and that lasers already attached in an existing save lose their implicit full charge.
* **Item-level attach and detach hooks plus a pre hook on `Interface.Create` over replacing `Interface.Combine` and `Interface.ContextRemove`.** Vanilla keeps its attachment logic and other mods can still replace those methods. The cost is a charge handed from one hook to another within a single vanilla call.
* **Polling in a `Laser._process` post hook over owning the toggle.** No conflict with VosTac's replace of `Laser._input` and no dependency on it. The cost is that a dead laser still clicks when toggled and that the cut-off relies on running after VosTac's hook.
* **Blink on the laser over dim.** No restore step and no fight with VosTac, which rewrites the dot's transparency every frame. The cost is that the laser is fully dark during a dip, unlike the flashlight.
* **The flashlight flicker moved into Likho's Battery over a copy of its rules.** One set of burst rules, owned by the mod that makes charge matter, and players without VosTac get the flashlight flicker. The cost is that VosTac alone no longer flickers, and a second post hook on `Flashlight.Activate` next to VosTac's.
* **Drain by the vanilla power tiers over a rate of its own for lasers.** One table for flashlights and lasers, and another mod can tier its laser through `power`. The cost is that a Medium laser empties as fast as a Polaris, which is quicker than a real laser module.
* **A battery dropped on a weapon goes to its lowest powered attachment over asking which one.** No extra UI and it is what the player wants in most cases. The cost is that with several powered attachments the player cannot pick the target without detaching one. Only one exists per weapon today.
* **A replace hook on `Interface.CombineCheck`.** Pre and post hooks cannot change the return value. The cost is a single-owner hook on a method every drag and drop goes through.
* **A tooltip row over a charge on the weapon's grid label.** The label keeps meaning weapon condition. The cost is that the attached laser's charge is one hover away.
* **Lasers made devices by a registry patch over a subtype test in every handler.** The device test, context entry and vanilla charge display apply to lasers unchanged.
