# Attachment card charge

## Intent

VosTac's attachment cards in inspect mode show the charge of a battery powered attachment next to its name, when Likho's Battery Powered (`likhos-battery`, BP) is installed. Today the card shows the name only, and the charge of an attached laser or sight is visible in the weapon tooltip alone.

## Constraints and assumptions

* An attached attachment has no state of its own. `SlotData.nested` is an `Array[ItemData]`, so the laser on a weapon is the shared item definition.
* BP keeps the charge of an attached powered attachment as a `SlotData` in the weapon's `storage`. The entry's `itemData` is the attachment's item and its `condition` is the charge, a float from 0 to 100. Entries are matched by `itemData.file`, never by position.
* Other mods keep entries of their own in `storage`, some of them without an item.
* BP marks an item as battery powered by appending the `Batteries` item to its `compatible` list on setup. No vanilla attachment lists `Batteries`, so an attachment that does is powered by an installed BP. This is the only test VosTac has for BP being present.
* BP creates the entry lazily, with a rolled charge, the first time anything in BP asks for it: the weapon tooltip, the price, a battery dragged over the weapon, the laser switched on, the sight drawing power. A weapon that none of those has touched yet carries a powered attachment without an entry.
* A fiber optic lit sight such as the ACOG is not a powered item in BP and has no charge.
* `rig.slotData` of the rig in hands is the weapon `SlotData` that BP reads and drains, so a charge read from it every frame is live.
* `InspectCard` already holds a second label for a condition value, with `set_condition` and `clear_condition`. It prints a whole percent in parentheses, green above 50, yellow above 25 and red below. Nothing calls them today.
* Attachment cards are pooled by attachment subtype and reused across weapons, so a card that showed a charge can next show an unpowered attachment.
* Ruled out: VosTac loading or calling BP's scripts, or BP's autoload. VosTac reads the weapon's data on its own.
* Ruled out: VosTac creating or rolling a missing entry. The roll is BP's.
* Ruled out: reading BP's power draw settings. The card shows the charge of a laser or sight whose power draw is disabled in BP, as the weapon tooltip does.
* Ruled out: a separate LCM setting. The existing `attachment_cards` setting governs the whole card.
* Ruled out: a charge on any other card (fire mode, ammo, chamber, kill counter).

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/HUD.gd`: the attachment cards only.
* `likhos-vostac/Scripts/InspectCards/InspectCard.gd`: the condition label.
* `likhos-vostac/CHANGELOG.md`: the line about the charge on the cards.
* `likhos-battery/Scripts/BatteryUtil.gd`: only a comment at the charge entry lookup stating that VosTac reads this layout.

Context only:

* `likhos-battery/Scripts/BatteryUtil.gd` beyond that comment: `FILE`, `powers` and `attachment_holder` define the device test and the entry layout that VosTac repeats.
* `likhos-battery/Scripts/Tooltip.gd`: the other place that shows an attachment's charge, and the format the card matches.
* `likhos-battery/Scripts/Main.gd`: where items become powered.
* `likhos-vostac/Scripts/Config.gd`: `attachment_cards`.
* Vanilla `src/Scripts/SlotData.gd` and `ItemData.gd`.

## Solution

### Charge lookup

`Hooks/HUD.gd` resolves the charge of an attachment on the weapon in hands from the weapon's `SlotData` alone. An attachment has a charge when its item lists `Batteries` in `compatible` and the weapon's `storage` holds an entry for that item. Either one missing means no charge: BP is not installed, the attachment draws no power, or BP has not created the entry yet. The lookup only reads. It never adds to `storage` and never writes a `condition`.

The device test and the entry layout are BP's, repeated here. `BatteryUtil.gd` carries a comment at the entry lookup naming VosTac's HUD as a second reader, so a change to the layout is made in both mods.

### Attachment card

While the attachment cards are shown, each card is updated every frame with its attachment's name and its charge. A card whose attachment has a charge shows it after the name through `InspectCard`'s condition label, as a whole percent in the label's colour thresholds. A card whose attachment has none shows the name only, with the condition label hidden, including a pooled card that showed a charge for another attachment before.

The charge is read every frame, so the value on the card follows a laser that drains while the weapon is inspected.

### Release notes

The changelog entry says the attachment cards show the charge of lasers and sights when Likho's Battery Powered is installed.

### Observable result

With VosTac and BP:

* Inspecting a rifle with a laser at 60% shows the laser's card as its name followed by `(60%)` in green. At 40% the value is yellow, at 20% red.
* A rifle with a laser and a red dot shows a charge on both cards, each its own.
* An ACOG, a suppressor or any other unpowered attachment shows its name only.
* A laser left on during inspection counts down on the card.
* A laser at 0% shows `(0%)` in red.
* The value on the card equals the one in the weapon tooltip.
* A looted weapon that has not been hovered, priced or switched on yet can show a powered attachment without a charge. The charge appears once BP has created its entry.
* With `attachment_cards` off no card shows.

With VosTac only:

* Every attachment card shows the name only, as today. A save that still holds BP's entries shows no charge either.

## Tradeoffs

* **VosTac reading `storage` on its own over calling BP.** VosTac has no dependency on BP's scripts, their paths or their load order, and BP's code is untouched. The cost is that the device test and the entry layout exist in two mods and a change in BP has to be mirrored in VosTac, with only a comment to point at it.
* **Read only over creating the missing entry.** The roll and its range stay in BP alone. The cost is a card without a charge on a weapon BP has not touched yet.
* **The `compatible` list as the test for BP over the entry alone.** Leftover entries in a save do not show a charge once BP is uninstalled or stops powering an item. The cost is a second scan per attachment per frame while inspecting.
* **The charge shown whatever BP's power draw settings are.** It matches the weapon tooltip and needs nothing from BP's config. The cost is a charge on the card of a device that currently ignores it.
* **The card's existing colour thresholds over the tooltip's plain text.** The card reads at a glance during inspection. The cost is that the two displays are not styled alike.
