# Optic battery

## Intent

Sights that need power run on batteries. Likho's Battery Powered (`likhos-battery`, BP) takes over reticle illumination from VosTac and ties it to charge: an illuminated scope lights its reticle only while it has charge, and a red dot sight shows its dot only while it has charge. A red dot is always on and is useless once its battery is empty. Scope illumination keeps its key and its LCM setting, both of which move to BP. BP provides all of it without VosTac installed.

## Constraints and assumptions

### Vanilla rendering

* Every sight has one `ShaderMaterial` on its lens surface, drawn by `src/Shaders/Reticle.gdshader`. That one shader draws the glass, the rim, the eye shadow, the reflection and the reticle. `Optic.reticle` points at it.
* The shader reads the reticle texture's alpha and red channel only. A texel authored red glows, a texel authored black is a black line. It has no input that hides the reticle or switches the glow.
* A lens material is a resource shared by every instance of that sight. It cannot hold a per weapon state. Whatever the weapon in hands needs is pushed into it every frame.
* `size` and `opacity` are rewritten every frame, for `activeOptic.reticle` only: by vanilla `WeaponRig` without VosTac and by `WeaponRig_Optic._update_reticle` with VosTac, which suppresses the vanilla writer. The `reticle` texture and `intensity` are written by nobody.
* Both lens shaders fade the reticle with `opacity`, which follows the aim, and leave it unmasked on the rim. The vanilla shader hides the reticle under its own shadow. VosTac's draws the reticle in front of its eye shadow, deliberately.
* Godot orders the transparent passes of one surface by render priority, not by the `next_pass` chain. Confirmed in game.
* The PIP image is drawn by an opaque shader, so it is always behind both transparent passes on the lens.
* All lens materials have render priority 1 and no `next_pass`.

### The sights

Vanilla has 13 optics (`subtype` `Optic`):

| Optic | Lens material | Texture |
|---|---|---|
| `Vudu`, `Leopard` | own | Fully red |
| `HMR` scope | own | Red ring and center dot, black crosshairs |
| `POSP` | own | Fully black |
| `ACOG` | own | Red chevron, black post |
| `PU` | own | Fully black |
| `EXPS`, `Kobra` | own | Red dot sight |
| `SRO`, `RMR`, `PRO`, `MRO`, `Micro` | shared `Common/Optics/MT_RDS.tres` | Red dot sight |
| `HMR` top dot | the same `MT_RDS.tres`, as one more surface of the HMR mesh | Red dot sight |

* The HMR's `Secondary` node is the aim position of the top dot only. The dot itself is a mesh surface, and its material is not `Optic.reticle`, so vanilla and VosTac never push `size` or `opacity` to it.
* The ACOG is lit by fiber optic and the PU has no illumination. Neither draws power.

### VosTac

* VosTac replaces the lens shader of every optic with `attachmentData.scope` or `attachmentData.variable` by its own `Shaders/Reticle.gdshader`. Red dot sights keep the vanilla shader.
* VosTac places a scope reticle from the lens UV, deliberately, and vanilla from the view direction. A fixed factor in VosTac's shader converts the vanilla authored `size` to lens UV. Reticle sizes themselves are data: VosTac patches them into the items and pushes the result as `size`.
* VosTac replaces `WeaponRig._input`, `WeaponRig._physics_process` and `WeaponRig.ADS`. Replace hooks are single-owner, so BP hooks none of them.
* `ScopeCatalog.daylight()` also feeds VosTac's low light dimming in `Hooks/Optic.gd`.

### BP

* BP's charge handling is generic. A device is any item that lists `Batteries` in `compatible`. For such an item attached to a weapon, `BatteryUtil.attachment_holder` keeps its charge in the weapon's `storage`, and the battery drop on the item or on the weapon, the weapon tooltip row, the price, the transfer on attach and detach and `Remove (Batteries)` on the detached item all follow from that test with no code per item kind.
* The loot roll in `Loot.gd` picks its items by subtype (`Light`, `Laser`).
* Laser drain uses a rate table indexed by `ItemData.power`, doubled in winter. A laser drains while its beam is on and the weapon is in hands, aiming or not.
* `ItemData.power` is an untyped variable holding an int, 0 to 3 for the vanilla tiers `None`, `Low`, `Medium` and `High`. Nothing limits it to those. Vanilla reads it in `Flashlight.gd` and `NVG.gd` only, by comparing against the three named tiers, so another value on a sight matches nothing there.
* `Flicker.gd` holds the low charge burst rules for one light source. Its owner steps it every 10 physics frames with the current charge and is told whether that step is inside a dip. Bursts come at 5%, 4%, 3% and 2% and run without a break from 1% down. It knows nothing about what a dip looks like.
* Vanilla `SlotData.Update` copies no meta, so a state kept as meta on a weapon's `slotData` is lost on a map transition, on loading a save and on dropping and picking up the weapon.
* LCM builds a mod's settings from the exported members of a `Config.gd`. VosTac loads LCM at runtime and registers only when it is installed. BP has no `Config.gd` and no LCM link today.

### Ruled out

* Both mods swapping the lens shader. A material holds one shader, so the mods would overwrite each other.
* Illumination uniforms kept in VosTac's lens shader and driven by BP. Red dot sights stay on the vanilla shader and would not be covered.
* A reticle hidden by VosTac's eye shadow. It shows through the shadow, as VosTac alone draws it.
* Derived texture copies (darkened, reddened, blank per state). It needs runtime editing of VRAM compressed textures or shipping copies of vanilla art.
* Power for the ACOG and the PU.
* A switch for red dots. They are always on.
* Draining a holstered weapon. A weapon drains only while it is in hands.
* Draining scope illumination only while aiming. It drains while lit, as a laser does while its beam is on.
* One setting for scopes and red dots together. Each kind of consumer has its own.
* Hiding the charge of a sight whose setting is `Disabled`. It still shows a charge and accepts batteries it never uses.
* Dimming a sight during a flicker dip. A dip takes the power away entirely, as it does for a laser.
* Removing the battery from a sight while it is attached. As for lasers, the weapon's context menu gets no battery entry.
* Brightness levels, a HUD indicator and persisting the manual switch state.
* AI weapons. They carry sights but never run the player's rig.

### Assumptions, unverified

* The weapon rig in hands and its active optic are reachable from a node outside the rig every frame, the way VosTac's HUD hook reaches `RigManager`.
* A lens material's `size` and `opacity` read back in the same frame are the values vanilla or VosTac pushed for that frame, or one frame old at worst.
* Adding `Batteries` to an optic's `compatible` list and setting `showCondition` have no effect beyond the tooltip's compatibility line, the charge display, `CombineCheck` and BP's own handling. The same assumption held for lasers.
* The registry reaches all 11 powered optics through `lib.patch` and `lib.append`, as it does lasers.
* A `power` value outside the vanilla enum survives the registry patch and everything that copies or saves an item definition.
* An action registered by BP under the name VosTac used keeps the player's saved binding.

## Scope

Owned in `likhos-battery/`:

* `Scripts/Config.gd`, new: the settings LCM lists.
* `Scripts/OpticPower.gd`, new: the powered sight catalog, the manual switch, the per frame power and reticle state of the weapon in hands, the drain and the flicker.
* `Shaders/Reticle.gdshader`, new: the reticle drawn as its own pass.
* `Scripts/Main.gd`: the registry patches for sights, LCM registration, the action, creating the optic power node.
* `Scripts/BatteryUtil.gd`: the drain rate table and the winter factor shared by lasers and sights.
* `Scripts/Laser.gd`: only where it takes its drain rate from.
* `Scripts/Loot.gd`: the loot roll for detached sights.
* `README.md`, `INSTRUCTIONS.md`, `CHANGELOG.md`.

Owned in `likhos-vostac/`:

* `Shaders/Reticle.gdshader`: no illumination inputs, and the placement it publishes.
* `Scripts/Nodes/WeaponRig_Optic.gd`: no illumination input, state or push.
* `Scripts/ScopeCatalog.gd`: no illumination data.
* `Scripts/Config.gd`: no illumination setting.
* `Scripts/Main.gd`: no illumination action.
* `README.md`, `CHANGELOG.md`: the lines about reticle illumination.

Context only, not modified:

* `likhos-battery/Scripts/Interface.gd`, `Item.gd`, `Tooltip.gd`, `Context.gd`, `Flicker.gd`, `Flashlight.gd`. They serve sights unchanged through the device test.
* `likhos-vostac/Scripts/Hooks/Optic.gd` and `ScopeCatalog.daylight()`. The low light dimming keeps its own daylight factor.
* `likhos-vostac/Scripts/Audio/AttachmentClickPlayer.gd`.
* `mod-lib/` and `likhos-config-manager/`.
* Vanilla `src/Shaders/Reticle.gdshader`, `src/Scripts/Optic.gd`, `WeaponRig.gd`, `RigManager.gd` and the lens materials under `src/Items/Attachments/`.

## Solution

### Powered sights

BP's catalog lists the sights that draw power and what each one powers:

| Optic | Consumer | Without power |
|---|---|---|
| `Vudu`, `Leopard` | Scope illumination, the whole reticle as authored | Black reticle |
| `HMR` | Scope illumination, the ring and center dot as authored. Top dot | Black ring and dot. No top dot |
| `POSP` | Scope illumination, the whole reticle since its texture authors nothing red | Black reticle |
| `SRO`, `RMR`, `PRO`, `MRO`, `Micro`, `EXPS`, `Kobra` | Dot | No dot |

* A sight has one battery. The HMR's two consumers share it.
* A sight that is not in the catalog (`ACOG`, `PU`, a sight added by another mod) is left exactly as vanilla or VosTac draws it.

### Charge

In `setup`, `Main.gd` patches every catalog sight the way it patches lasers: `Batteries` is appended to `compatible`, `showCondition` is true and `power` is set to the sight's tier when it has none. That makes each sight a device, so the existing handlers apply unchanged:

* A detached sight shows its charge in the grid and the tooltip and offers `Remove (Batteries)` while it has charge.
* Attached, its charge lives in the weapon's `storage` under its own entry and follows it on and off the weapon.
* A battery dropped on the sight or on the weapon that carries it exchanges charge with it. On a weapon with several powered attachments the emptiest one takes it.
* The weapon tooltip shows one row per powered attachment, so a rifle with a laser and a red dot shows two.
* A sight and a weapon carrying it lose the price of the charge they are missing.
* A weapon that carries a powered sight without a charge entry gets one on first need, rolled in the first-seen range. That covers AI drops, looted weapons and saves made before this feature.

`Loot.gd` rolls a looted detached sight from the catalog in the same range as flashlights and lasers.

### Setting

`Config.gd` exports two settings in a `Sights` group, one per kind of consumer, so LCM lists them under BP. `Main.gd` registers the config with LCM when LCM is installed. Without LCM both are at their defaults.

`Red Dot Power Draw` governs every dot, the HMR's top dot included:

| Value | Dot |
|---|---|
| `Disabled` | Draws no power. Always shown, whatever the charge |
| `Always On`, the default | Needs charge and drains it whenever the weapon is in hands |

`Scope Power Draw` governs scope illumination:

| Value | Scope illumination is on when | Key |
|---|---|---|
| `Disabled` | Draws no power. The reticle renders as authored whatever the charge, so the POSP stays black | Does nothing |
| `Manual`, the default | The weapon's switch is on | Flips the weapon's switch |
| `Light Sensor` | It is dark outside | Does nothing |

* `Disabled` is the vanilla behavior of that consumer: it does not drain, does not flicker and does not go dark at 0%. The sight still shows a charge and accepts batteries.
* The two settings are independent. Only the HMR has both consumers, so only there do they combine.
* Dark is the stretch from sunset to sunrise, never in a shelter. BP computes it on its own from `Simulation.time` by the rule VosTac's daylight factor uses.
* A change in LCM shows on the next frame.

### Switch

* `Main.gd` registers the action `reticle_illumination`, labeled `Reticle Illumination`, default `Y`.
* The manual switch is an on or off state of the weapon, kept as meta on its `slotData`. It is off until toggled and is lost on a map transition, a load and a drop and pick up.
* The optic power node handles the press itself as input. No `WeaponRig` method is hooked for it.
* With `Scope Power Draw` on `Manual` a press flips the switch of the weapon in hands when its active optic has scope illumination, in and out of aim, and plays a click. On any other sight, with no optic, or on another value it does nothing. The press is ignored while the inventory or a menu is open.
* The switch still flips on an empty battery. Nothing lights.

### Power, every frame

`OpticPower.gd` is a node owned by BP's `Main`. For the weapon in hands and its active optic it resolves each consumer:

* A consumer whose setting is `Disabled` wants no power and renders as authored.
* Otherwise a dot wants power whenever the weapon is in hands.
* Scope illumination wants power when its setting says it is on, aiming or not.
* A consumer that wants power and whose sight has charge is powered.
* At 0% nothing is powered. A dot disappears and scope illumination goes dark until a battery is put in.

A sight has one battery and one drain rate, taken from its `power` tier. It drains its charge holder, found through `BatteryUtil.attachment_holder`, while its own consumer is powered: the dot of a red dot sight, the illumination of a scope.

A scope that also carries a secondary dot drains by which of its two consumers want power:

* Illumination and dot: its own rate times a fixed multiplier.
* Illumination only, with dots `Disabled`: its own rate.
* Dot only: the rate of the dot tier.

`BatteryUtil` holds the one rate table, indexed by `power`, and the winter factor. The laser handler and the optic power node both take the rate from it. The table covers the vanilla tiers and two tiers of BP's own, stored as the next two int values after `High`:

| Tier | Rate | Full battery lasts | Used by |
|---|---|---|---|
| `Low` | 0.05% per second | 33 min | Vanilla flashlights |
| `Medium` | 0.1% per second | 17 min | Lasers |
| `High` | 0.2% per second | 8 min | Vanilla flashlights |
| Dot tier, BP's own | 0.005% per second | 5 h 33 min | The seven red dot sights |
| Illumination tier, BP's own | 0.02% per second | 83 min | `Vudu`, `Leopard`, `POSP`, `HMR` |

| Tunable | Value |
|---|---|
| Secondary dot multiplier | 1.25. An HMR lasts 67 min lit and 5 h 33 min unlit |
| Winter | Every rate doubled |

A sight that already has a tier keeps it, so another mod can retier a sight through `power`.

### Low charge flicker

The node owns one `Flicker`, since one sight is live at a time. While any consumer of the active optic is powered, it steps the flicker with the sight's charge at the cadence the laser handler uses.

* During a dip every consumer of the sight renders as not powered: a dot disappears and a lit reticle goes unlit. Outside a dip they render as powered.
* Drain is unaffected by a dip.
* A sight with nothing powered is not stepped, so a scope with its illumination off never flickers.
* A consumer whose setting is `Disabled` never dips.
* The HMR's dot and scope illumination dip together when both draw power, as they share the battery.

At the rates above a dot gives its four warnings 200 seconds apart and then blinks without a break for its last 200 seconds. Lit scope illumination does the same on a 50 second scale. Both are halved in winter.

### Rendering

The reticle is drawn by a material of its own, layered with the lens material that vanilla or VosTac owns.

* For each lens material of a catalog sight, BP creates one reticle material the first time it meets that lens material on a weapon in hands. It uses BP's `Shaders/Reticle.gdshader`, takes over the lens material's reticle texture and `intensity`, and is chained to the lens material as its `next_pass`. The lens material is left with a blank reticle texture, so the lens shader draws glass, rim, shadow and reflection and no reticle.
* The HMR has two lens materials, its scope reticle and the top dot surface, and gets a reticle material for each. The five sights sharing `MT_RDS.tres` and the HMR's top dot share one.
* The reticle material has a higher render priority than the lens material, so the reticle is drawn over the lens and over whatever shadow the lens shader draws.
* BP's shader fades the reticle with the aim by the `opacity` it reads from the lens material, as both lens shaders do.
* Placed the vanilla way, the reticle is hidden under the vanilla shader's shadow, which BP's shader repeats. Placed from the lens UV, nothing masks it, so it stays visible through VosTac's eye shadow.
* BP's shader draws the reticle in one of three states: lit as authored (red texels glow, black texels are black), lit whole (every opaque texel glows) and unlit (every opaque texel is black). A fourth state draws nothing. The glow matches vanilla's in strength and color.
* Every frame the node pushes to the reticle materials of the weapon in hands: the state of each consumer, with a flicker dip counting as not powered, and the `size` and `opacity` it reads from the lens material.

| Consumer | Powered | Not powered |
|---|---|---|
| Scope illumination, `Vudu`, `Leopard`, `HMR` | Lit as authored | Unlit |
| Scope illumination, `POSP` | Lit whole | Unlit |
| Dot | Lit as authored | Nothing |
| Any consumer whose setting is `Disabled` | Lit as authored | Lit as authored |

### Placement contract

BP's shader places the reticle from the view direction, as vanilla does, unless the lens material says otherwise.

* VosTac's lens shader takes the factor that converts `size` to lens UV as a shader parameter, and `WeaponRig_Optic` sets it on every lens material VosTac has taken over.
* BP reads that parameter from the lens material. Present, the reticle is placed from the lens UV with that factor. Absent, from the view direction.

This one parameter is the whole contract between the two mods. Neither loads a script of the other.

### VosTac

* `Shaders/Reticle.gdshader` has no illumination inputs. It draws the reticle as authored, which is what shows when BP is not installed, and draws none when BP has blanked the texture.
* `WeaponRig_Optic` handles zoom and the secondary optic and pushes `size`, `opacity`, `shadow` and the placement factor. It has no illumination action, no switch state and no click for it.
* `ScopeCatalog` has no illumination data. `Config.gd` has no illumination mode and `Main.gd` registers no illumination action.
* The README and the changelog say that reticle illumination now comes with Likho's Battery Powered.

### `mod.txt`, `INSTRUCTIONS.md`, `README.md`, `CHANGELOG.md` of BP

* `mod.txt` declares `Inputs.CreateActions` and `Inputs.ResetActions`, the hooks mod-lib uses to register an action. No other hook is new.
* `INSTRUCTIONS.md` lists those two hooks, the registry changes on the 11 sights, LCM as an optional mod and that BP chains a second material to the lens material of every powered sight.
* The README covers powered sights, the illumination key and the two settings with their values, and tells a player who runs VosTac to update it. An older VosTac next to this BP handles the key too and draws its own illumination.

### Observable result

With BP, with or without VosTac:

* A rifle with a red dot shows the dot while the sight has charge. At 0% the lens is clear glass with no dot.
* Dropping a battery on the sight or on the rifle brings the dot back.
* An HMR at 0% has no top dot and a black ring and center dot. Its crosshairs stay usable.
* An HMR in hands drains like a red dot while its illumination is off and five times faster while it is lit.
* With `Scope Power Draw` on `Manual` a Vudu, Leopard, HMR or POSP is unlit on first aim. The key lights it while the scope has charge.
* On `Light Sensor` the four scopes light from sunset to sunrise while they have charge.
* On `Disabled` the four scopes look as in vanilla and their illumination never drains.
* With `Red Dot Power Draw` on `Disabled` every dot shows at any charge and never drains.
* An HMR with dots `Disabled` and scopes on `Manual` drains only while its reticle is lit and keeps its top dot at 0%. With dots `Always On` and scopes `Disabled` it drains like a red dot and keeps its lit ring at 0%.
* At 5%, 4%, 3% and 2% a dot blinks off one to three times in quick succession, and a lit reticle blinks to black. From 1% they blink without a break until the sight is empty.
* The rifle's tooltip shows the sight's charge, e.g. `Micro: 60%`.
* A rifle taken from an AI has its sight at a random 20-75%.
* An ACOG and a PU look and behave as before.

With VosTac only:

* Every reticle looks as in vanilla. The key and the LCM setting are gone.

With both:

* A scope reticle is placed, sized and shown through the eye shadow as VosTac alone draws it. It moves with the weapon body.

## Tradeoffs

* **Illumination in BP over VosTac consuming BP's charge.** One mod owns the switch, the charge and the drain, and red dots work without VosTac. The cost is that VosTac alone loses the illumination switch it has today.
* **A separate reticle material over illumination inputs in the lens shader.** It works on the vanilla shader and on VosTac's without editing either. The cost is a second draw per powered sight, a shader in BP that repeats both reticle placements, and BP rewriting vanilla material resources at runtime.
* **The reticle drawn over the lens rather than under it.** It stays visible through VosTac's eye shadow, as it is without BP. The cost is that BP's shader repeats the aim fade of both lens shaders and the shadow of the vanilla one, where drawing it under the lens would have taken all of that from the lens pass.
* **A placement parameter published by VosTac over BP detecting VosTac's shader.** The contract is one named value. The cost is that a future change to how VosTac places reticles (zeroing, cant, parallax) has to be mirrored in BP's shader.
* **Two tiers of BP's own on `ItemData.power` over a rate table keyed by consumer.** One table serves every powered device and another mod can retier a sight. The cost is `power` values vanilla does not name, which a flashlight or NVG given one would not understand.
* **The laser's flicker rules unchanged over rules scaled to the slower drain.** One set of burst rules for every powered device. The cost is that the last percent, which blinks without a break, lasts 200 seconds on a dot against 10 on a laser.
* **A setting per kind of consumer over one setting for all sights.** A player can keep free red dots and still have switchable scope illumination, or the reverse. The cost is a second setting and an HMR whose two consumers can follow different rules.
* **`Disabled` as a plain opt out over hiding the charge of an opted out sight.** The registry patch runs once at startup and the settings change while the game runs. The cost is that such a sight shows a charge and accepts batteries it never uses.
* **One battery and one tier per sight, with a multiplier for a secondary dot, over a tier per consumer.** The HMR needs no second charge and no second tier. The cost is a rule in code that only the HMR uses: the dot tier's rate for the dot alone, its own rate for the illumination alone and its own rate times the multiplier for both.
* **A battery dropped on a weapon goes to its emptiest powered attachment.** Existing rule. With sights powered, a weapon with a laser and a sight is common, and the player cannot pick the target without detaching one.
* **Charge rolled on first need for sights on weapons.** Existing rule. Sights already mounted in an existing save lose their implicit full charge.