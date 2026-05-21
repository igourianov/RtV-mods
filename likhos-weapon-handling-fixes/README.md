# Likho's VosTac

Comprehensive RtV overhaul that modifies weapon positions, handling mechanics, optics and stamina. Fixes a number of vanilla weapon bugs.

Formerly `Likho's Weapon Handling Fixes`.

### Features

* Reworked the PIP scope mode for realism [*(details)*](#pip-mode-realism). Recommended to pair with [ExitPupil](https://modworkshop.net/mod/56890) PIP reshader mod.
* Reworked all optics with real names, weights eye relief and magnification values. [*(details)*](#optics-rework)
* Reworked arm and leg stamina mechanics. [*(details)*](#stamina)
* Reworked reload, insert and ammo check mechanics. [*(details)*](#ammo-check)
* Reworked the inspect mode and associated bindings. [*(details)*](#inspect-mode-rework)
* Hold breath function (hold Sprint while aiming)
* Canted aim is now independent with optional laser auto-activation (disable in MCM)
* Reworked input priority for Couch/Sprint/Aim/Canted actions. Last action wins instead of following hardcoded order (exception: sprint while aiming)
* Mouse sensitivity scales with zoom and stance (canted uses Aim, LPVO 1× uses Aim, mid/high use Scope/Scope×0.5)
* Weapon handling speed (how fast you transition into the desired state) now scales with stance and optic: red dot 115%, canted 130%, LPVO at 1× 105%, magnified scope 80%, default 100% (disable in MCM)
* Movement speeds rescaled with new breakpoints. Crouch/walk/sprint changed from vanilla 1/2.5/5 to 0.7/3/7, with new walk-canted/walk-aiming-1×/walk-scoped breakpoints at 2.25/1.8/0.9× walk speed (all editable in MCM)
* Default weapon position changed to patrol mode (rifle rests across the chest)
* LPVO zoom accessible without aiming - gated by the Rail movement modifier by default to avoid collision with lower/raise weapon (change in MCM)
* Added explicit bindings to the base game settings for optic zoom in/out (it was hardcoded to mouse wheel)
* Crosshair in idle mode for interactions - auto-disabled when aiming/canted/raised (configure in MCM)
* Ability to toggle the secondary optic out of aim, with a visual cue of the toggle
* Flashlight now supports both toggle and hold actions on the same binding, and will shine the light on the inspected weapon. Recommended for use with [LootLight mod](https://modworkshop.net/mod/56422).
* Mosin and 870 can now cycle the bolt on a full or empty mag like real guns (you will lose ammo)
* Cocked state and dry fire click for all guns
* Likho's protips in-game to make the user aware of the changed bindings

### Vanilla Fixes

* Ammo check no longer forces weapon into raised position (prior stance preserved)
* Canted aim activation no longer blocked by interactables
* Interactable tooltip no longer blocks vision when aiming around doorways
* Fixed Mosin ending up in weird state (mag + 0) after closing the bolt. Now both live round and spent casing are always ejected when opening bolt.
* Fixed Mosin and 870 round/casing not ejecting when opening the bolt to load (no animation, but it is cleared)
* Fixed HAMR's secondary optic switch permanently killing PIP plane on other scopes (state wasn't being properly reset)
* Fixed HAMR's secondary optic vertical offset on all AK rifles (not RK), SVD and Vintorez (missing scale calc)
* Fixed HAMR causing major flickering when toggling secondary on M4A1 (bug with foldable iron sights)
* Fixed laser ray misaligned with collision dot. You may notice that bullet holes are now very slightly offset from the laser dot - that's how real lasers work.
* Fixed flashlight draining battery while the game world is frozen

### PIP mode realism
!!!
Vanilla PIP is completely unusable - every scope feels like a "scout" scope. This mod addresses that:
- *Realistic eye relief:* optics placed too close/far on tha rail will get cope shadow (ACOG will suck the most!) Scope shadow no longer wobbles as you move and appears behind the reticle.
- *Main camera FOV no longer narrows when scoped* — only the inside of the optic magnifies
- *LPVOs stay "scoped" at 1x* — realistic lens distortion and DOF even at 1x
- *Scope DOF reworked:* scales with magnification, near-DOF enabled for foreground/background softening
- *PIP MSAA matches main viewport:* the optic's SubViewport now mirrors the antialiasing settings used by the rest of the game - vanilla left it disabled (disable in MCM if it causes performance issues)
- *NVG-aware PIP blur:* when night vision is active and you aim a magnified optic, the PIP image will now blur. Real scopes cannot work under NVG because of eye relief differences (disable in MCM)
!!!
### Optics rework
!!!
* All optics now have eye relief values and create scope shadow if mounted outside ideal eye relief
* Changed Mark 8 ("Leopard") to 1.1-8x zoom and fixed reticle size at 1x
* Changed Vudu to 1-10x zoom and made it legendary rarity
* Changed POSP to be the 2-6x variant and fixed reticle size
* HAMR is now legendary 
* PU: 3.5x zoom
* Input acceleration for zoom bindings to quick flick from min to max or vice versa
* MCM setting for magnification controle schema
	- *Short:* 3 zoom level spread evently along scope's magnification range - like vanilla but mid-point is visually middle. Choose this if you're more CoD than Tarkov guy.
	- *Discrete:* literal, physical zoom levels. E.g. for Vudu: 1, 2, 3, 4,...,10. Input acceleration makes this setting tolerable.
	- *Normalized:* a comfortable middle ground between the two options above.
!!!
### Stamina
!!!
Both stamina bars are now dynamic and much more realistic. 
* There is now a dynamic delay for beginning recovery after use.
* Arm stamina drain scales with the weight of the gun held and position it is held in (canted=slower; aim zoomed=faster)
* Arm stamina recovery and recovery delay scales with the Energy stat
* Crouch halves aim stamina drain, except when holding breath
* Leg stamina drain scales with the inventory weight
* Leg stamina recovery and recovery delay scales with the Hydration stat
* Overweight, Fracture and Leg Stamina=0 now block sprinting completely
* Sprint now overrides crouch, so you can panic GTFO when discovered sneaking about
!!!
### Inspect mode rework
!!!
* Fixed and rewrote several overlapping and dangling key bindings and states.
* Rail movement now works only in inspect mode. Rail movement binding is now unused.
* Weapon rotation in inspect mode is now done with the Canted aim binding.
* Stamina drain removed
* Added ammo and attachment cards to the inspect mode (disable via MCM menu)
* Flashlight will now shine on the wepon while inspecting
!!!
### Ammo check
!!!
Ammo check receives much needed love. 
* Reload binding (default R) will now perform ammo check when held down for longer than 300ms.
* Old ammo check binding removed.
* Perform reload directly from the ammo check state by clicking fire button (detachable mag guns only)
* Ammo check is now responsive - it will show ammo as long as you hold it.
* Mosin and 870 use the same hold-to-check, fire-to-insert scheme for loading rounds
!!!

## Why this is one mod and not several

These changes started out as separate mods. The catch is that Road to Vostok's scripts have a handful of "god" methods that fold a lot of unrelated behavior into a single function and mix state mutation with rendering side effects in the same call. Hooking a method through the mod loader is all-or-nothing, you can't override only part of a function. So as soon as one fix needed to touch, say, `Handling.WeaponHandling`, every other tweak that also lives in that method had to ship in the same mod or get clobbered by it. That's how the ammo-check, canted, laser and PIP changes ended up bundled together.

## [Check out my other mods](https://modworkshop.net/search/mods?query=%22Likho%27s%22&sort=likes)

*Feedback and likes are welcome!*
