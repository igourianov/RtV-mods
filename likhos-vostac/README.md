# Likho's VosTac

Comprehensive RtV overhaul that modifies weapon positions, handling mechanics, optics and stamina. Fixes a number of vanilla weapon bugs.

Formerly `Likho's Weapon Handling Fixes`.

## Novel features

* **Binoculars!** Added tactical [6-12x binos](https://www.youtube.com/watch?v=6d0zPQRmM3s) for observation. Hold 'B' to activate (remap in game's vanilla bindings)
* **Hold breath** Function to steady aim at the expense of increased stamina drain (hold Sprint while aiming)
* **Kill counter** Appear as scratch list in weapon inspect mode (when you have kills). Purple = boss.

## Weapons & Handling

* Reworked lowered weapon mode into [Adaptive Free Look](https://www.youtube.com/watch?v=I1lY93vEe-s) mode (disable in MCM)
* Canted aim is now an action independent from aim with optional laser auto-activation (recommend using mouse side button for it)
* Weapon handling speed (how fast you transition into the desired state) now scales with stance and optic: red dot and LPVO 1x **115%**, canted **130%**, magnified scope **80%**
* Reworked insert and ammo check mechanics to use hold action instead of toggle + can now reload directly from ammo check
* Reworked the inspect mode and associated bindings + QoL flashlight fix
* Reworked manual action guns reload animations to be more fluid (reduced animation lock out time)
* Mosin and 870 can now cycle the bolt on both full and empty mag, like the real guns do (you will lose ammo) + dry fire click on empty chamber
* Negligent discharge (firing out of aim) is allowed (disable in MCM)

## Aiming & Optics

* Mouse sensitivity scales with stance and progressively with zoom level + lerp() on transition instead of snapping
* Ability to toggle the secondary optic out of aim, with a visual cue of the toggle
* Reworked the PIP scope mode for realism
* Reworked all optics with real eye relief (only in PIP) and magnification values.
* LPVO zoom is now accessible without aiming - gated by the Rail movement modifier by default to avoid collision with lower/raise weapon (change in MCM)
* Added explicit bindings to the base game settings for optic zoom in/out (it was hardcoded to mouse wheel)

## Movement & Stamina

* Reworked arm and leg stamina mechanics to drain based on weight and recover based on vitals.
* Changed movement speed Crouch/walk/sprint from vanilla **1 / 2.5 / 5** to **0.7 / 3 / 7** (editable in MCM)
* New movement breakpoints walk-canted/walk-aiming-1×/walk-scoped as multiplier of the walk speed **0.6 / 0.75 / 0.3** (editable in MCM)

## Controls & HUD

* Reworked input priority for Crouch/Sprint/Aim/Canted actions. Last action wins instead of following hardcoded order (exception: sprint while aiming = hold breath)
* Crosshair in idle mode for interactions - auto-disabled when aiming/canted/raised (configure in MCM)
* Flashlight now supports both toggle and hold actions on the same binding, and will shine the light on the inspected weapon
* Additional weapon cards in Inspect/Ammo Check/Insert modes + icon replacers for ammo count and chamber status (check MCM settings)
* Likho's protips in-game to make the user aware of the changed bindings

## Vanilla Bug Fixes

* Ammo check no longer forces weapon into raised position (prior stance preserved)
* Canted aim activation no longer blocked by interactables
* Disabled interactable tooltip while aiming, so it doesn't blocks vision when aiming around doorways
* Fixed Mosin ending up in weird state (mag + 0) after opening+closing the bolt
* Fixed Mosin round/casing not ejecting when opening the bolt to reload/insert and missing animations
* Fixed HAMR's secondary optic switch permanently killing PIP plane on other scopes (state wasn't being properly reset)
* Fixed HAMR's secondary optic vertical offset on all AK rifles (not RK), SVD and Vintorez (missing scale calc)
* Fixed HAMR causing major flickering when toggling secondary on M4A1 (bug with foldable iron sights)
* Fixed laser ray misaligned with collision dot. You may notice that bullet holes are now very slightly offset from the laser dot - that's how real lasers work.
* Fixed flashlight draining battery while the game world is frozen
* Fixed bugs with optic rail movement due to incorrect limits and errors in floating point math

## More details

### PIP mode
Vanilla PIP is completely unusable - every scope feels like a "scout" scope. This mod addresses that:
- *Realistic eye relief:* optics placed too close/far on the rail will get scope shadow (ACOG will suck the most!) Scope shadow no longer wobbles as you move and appears behind the reticle.
- *Main camera FOV no longer narrows when scoped* — only the inside of the optic magnifies
- *LPVOs stay "scoped" at 1x* — realistic lens distortion and DOF even at 1x
- *Scope DOF reworked:* scales with magnification, near-DOF enabled for foreground/background softening
- *PIP MSAA matches main viewport:* the optic's SubViewport now mirrors the antialiasing settings used by the rest of the game - vanilla left it disabled (disable in MCM if it causes performance issues)
- *NVG-aware PIP blur:* when night vision is active and you aim a magnified optic, the PIP image will now blur. Real scopes cannot work under NVG because of eye relief differences (disable in MCM)

### Optics
* All optics now have eye relief values and create scope shadow if mounted outside ideal eye relief (ACOG will suck on Combloc rifles!)
* Changed Mark 8 ("Leopard") to 1.1-8x zoom and fixed reticle size at 1x
* Changed Vudu to 1-10x zoom and made it legendary rarity
* Changed POSP to be the 2-6x variant and fixed reticle size
* Allowed POSP to move on the dovetail
* HAMR is now legendary
* PU moved back on the gun and it is now real 3.5x zoom
* Input acceleration for zoom bindings to quick flick from min to max or vice versa
* MCM setting for magnification control schema
	- *Short:* 3 zoom level spread evenly along scope's magnification range - like vanilla but mid-point is visually middle. Choose this if you're more CoD than Tarkov guy.
	- *Discrete:* literal, physical zoom levels. E.g. for Vudu: 1, 2, 3, 4,...,10. Input acceleration makes this setting tolerable.
	- *Normalized:* a comfortable middle ground between the two options above.

### Stamina
Both stamina bars are now dynamic and much more realistic. 
* There is now a dynamic delay for beginning recovery after use.
* Arm stamina drain scales with the weight of the gun held and position it is held in (canted=slower; aiming=faster)
* Arm stamina recovery and recovery delay scales with the Energy stat
* Leg stamina drain scales with the inventory weight
* Leg stamina recovery and recovery delay scales with the Hydration stat
* Overweight, Fracture and Leg Stamina=0 now block sprinting completely
* Sprint now overrides crouch, so you can panic GTFO when discovered sneaking about

### Inspect mode
* Fixed and rewrote several overlapping and dangling key bindings and states.
* Rail movement now works only in inspect mode. Rail movement binding is now unused.
* Weapon rotation in inspect mode is now done with the Canted aim binding instead of mouse wheel.
* Stamina drain removed
* Added ammo and attachment cards to the inspect mode (disable via MCM menu)
* Flashlight will now shine on the weapon while inspecting

### Ammo check & insert
Ammo check receives much needed love. 
* Reload binding (default R) will now perform ammo check when held down for longer than 300ms.
* Old ammo check binding removed.
* Perform reload directly from the ammo check state by clicking fire button (detachable mag guns only)
* Ammo check is now responsive - it will show ammo as long as you hold it.
* Mosin and 870 use the same hold-to-check, fire-to-insert scheme for loading rounds

## Why this is one mod and not several

These changes started out as separate mods. The catch is that Road to Vostok's scripts have a handful of "god" methods that fold a lot of unrelated behavior into a single function and mix state mutation with rendering side effects in the same call. Hooking a method through the mod loader is all-or-nothing, you can't override only part of a function. So as soon as one fix needed to touch, say, `Handling.WeaponHandling`, every other tweak that also lives in that method had to ship in the same mod or get clobbered by it. That's how the ammo-check, canted, laser and PIP changes ended up bundled together.

## MCM toggles

*Because people keep asking to add more...* I don't want to add any more toggles. In fact I will likely reduce them to just core subsystems or critical compatibility points in the near future.

**Why?** Because code complexity scales **exponentially** with the number of config switches. And I am already burning most of my time on this mod with just fixing things that broke previously instead of doing things I like. 

Imagine a very simple change that touches a code path with just one MCM toggle (assuming binary on/off state). To implement it properly I need to run minimum of 2 tests: one with the setting on, and one with it off. Two toggles - 4 tests. Three toggles - 8 tests. Ad infinitum. And this is just to run it once, not counting all the intermediate debugging runs and multi-state settings.
