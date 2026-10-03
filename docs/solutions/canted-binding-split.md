# Canted binding split

## Intent

Separate VosTac's canted aim from the vanilla one, each on its own action.

* The vanilla `canted` action goes back to what it does in vanilla: pressed while aiming, it switches that aim between the sights and canted.
* A new action carries what the canted key does in VosTac today: canted as its own arms state, independent of aim, held or toggled.
* A player uses one of the two, not both.
* The vanilla action keeps its name in the game settings. The new one is named after it with a qualifier, so a player can tell them apart.
* Saved bindings are not migrated. The new action starts unbound for everyone, and the release notes tell existing users to bind it.

## Constraints and assumptions

* Either/or. The two actions get no conflict rules against each other. Using both is an invalid case, at once or one after the other, and whatever falls out of the rules below is accepted. That includes an aim variant left on canted by the vanilla key changing how the quick action behaves against sprint.
* Vanilla `Handling.gd` flips a `canted` flag on a canted press while aim is active, and poses the weapon canted instead of aimed while the flag is set. The flag is never reset, so the next aim comes up canted. It lives on the rig's `Handling` node and is gone with the rig.
* Vanilla ignores the canted press while looking at an interactable (`gameData.interaction`). VosTac does not, and that stays for both actions.
* Vanilla defaults: `canted` is on middle mouse, and both mouse side buttons are taken by flashlight and NVG. So the new action has no sensible free default.
* The vanilla settings screen can rebind an action but not unbind it. A bound action stays bound until the bindings are reset.
* Ruled out: moving a saved `canted` binding to the new action on the first run. An existing VosTac user cannot be told apart from a vanilla player who rebound canted, a user on the default middle mouse cannot be recognized at all, and running once needs a marker that outlives a reset of the bindings.
* `ModConfig.cant_mode` governs the new action only. The vanilla action has no mode: it is always a press that flips.
* Everything downstream reads `gameData.isCanted` and does not care which action produced it: the weapon pose, handling speed, walk speed, crosshair, arm stamina and laser auto-on.
* `mod-lib` gives a registered action its default whenever it has no saved binding, and a reset drops the saved binding of every registered action.
* Hold breath is an action of its own, on the sprint key by default. It is on while its key is down and the sights aim is in effect. While it is on, a sprint key starts nothing. A key does not keep the meaning it started with.
* Ruled out: renaming the vanilla entry in the settings list, e.g. to "Canted Aim (vanilla)". The mod does not touch vanilla labels.
* Ruled out: an in game notice for a `canted` press that does nothing. The release notes cover it.
* Ruled out: listing the new action directly below the vanilla one. It sits at the end of the settings list with the other registered actions, and its label is enough to find it.

## Scope

Owned:

* `likhos-vostac/Scripts/Nodes/InputBus.gd`: the canted input of both actions.
* `likhos-vostac/Scripts/Main.gd`: registers the new action.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Inspect.gd`: the rotation key and its protip.
* `likhos-vostac/Scripts/ModConfig.gd`: the wording of the canted mode entry.
* `mod-lib/Main.gd` and `mod-lib/Inputs.gd`: registering an action without a default binding.
* `likhos-vostac/README.md` and `likhos-vostac/CHANGELOG.md`: the lines about the canted binding and the release note.

Context only:

* The arms and pose rules of the bus as they stand in `InputBus.gd`, including sprint against aim and hold breath. Only where canted input comes from changes.
* How `mod-lib` applies defaults and handles a reset for registered actions.
* The hooks and nodes that read `gameData.isCanted`.
* Vanilla `src/Scripts/Inputs.gd` and `src/Scripts/Handling.gd`.
* `likhos-vostac/README.bb.txt`, generated from the README.

## Solution

### Actions

| Action | Label | Default | Meaning |
|---|---|---|---|
| `canted` | Canted Aim | middle mouse (vanilla) | Switches an aim in effect between sights and canted |
| `canted_standalone` | Canted Aim (quick) | none | Canted as its own arms state |

The two share the `canted` stem in their ids and the "Canted Aim" stem in their labels. The vanilla entry keeps its vanilla label. The standalone entry sits at the end of the settings list with the other registered actions.

### The bus

The arms axis is unchanged: neutral, aim, canted, binoculars.

`canted_standalone` is the only input that asks for the canted arms state. Every rule the canted key has today applies to it as is: its mode from `ModConfig.cant_mode`, latch or held key, press order among held keys, the conflict with sprint, suspension through locks and with no firearm in hand.

`canted` is not an arms request. The bus holds one more piece of state, the aim variant: sights or canted.

* A `canted` press flips the variant when an aim request is in effect and input is neither gated nor locked. At any other time the press does nothing.
* While the variant is canted, an aim request that wins the arms axis resolves to canted instead of aim. From there every rule treats it as canted: `canted()` is true, `aim()` is false, there is no hold breath, and sprint conflicts with it the way it conflicts with canted. A latched aim switched over to canted yields to a sprint key held from before it, where one on the sights suspends that sprint.
* Hold breath needs the sights aim, so it ends when the variant flips to canted.
* While the hold breath key is down, a sprint key in hold mode starts nothing under an aim request in effect, on the sights or canted. So on the default shared key the flip leaves the weapon canted whichever of the two held keys went down first, and the key does nothing until the aim ends or flips back. A sprint key of its own is not held back by this.
* The variant stays across aim sessions, as in vanilla. It returns to sights when the rig is cleared and when a scene loads.

### Registered actions in mod-lib

* `register_action` accepts an action with no default. While it has no saved binding the action exists in the `InputMap` without events and shows as `[unbound]` in the settings list. It can be bound there like any other.
* A reset leaves such an action unbound, since it drops the saved binding and there is no default to apply.

### Inspect

A press of either action rotates the weapon in inspect mode. The protip names the `canted_standalone` binding when it has one and the `canted` binding otherwise.

### MCM

The canted mode entry names the standalone action in its label and tooltip. Laser auto-on is unchanged and applies to canted from either action.

### Release notes

* The README describes the two actions and says that either one rotates the weapon in inspect mode.
* The changelog entry says what changed and that a player who wants canted as it was has to bind Canted Aim (quick) in the game settings.

### Observable result

* The settings list shows Canted Aim in its vanilla place and Canted Aim (quick) at the end.
* Fresh install: middle mouse while aiming switches between sights and canted. Middle mouse while not aiming does nothing. Canted Aim (quick) is listed as `[unbound]`.
* Aim, press `canted`, release aim, aim again: the weapon comes up canted. Press `canted` again: back to the sights.
* Aiming on the sights and holding breath on the shared key, then `canted` pressed: breath ends and the weapon goes canted, in either order of the two held keys and in both sprint modes. Pressing `canted` again holds breath again.
* Aim held with the variant canted, then the shared key held in sprint hold mode: nothing. Releasing aim with the key still down starts a sprint.
* Aim held with the variant canted, then a sprint key of its own held: the player sprints. Releasing sprint goes back to canted.
* Sprint toggle mode, variant canted, sprint pressed: lost under a held aim key, and the crouch stays. Under a toggled aim it ends the aim in a sprint.
* Aiming with the variant canted, hold breath key pressed on a key of its own: nothing.
* Sprint held, then Canted Aim (quick) held: the weapon goes canted. Aim held on top: the weapon aims on the sights and breath is held on the shared key.
* Switching or holstering the weapon: the next aim comes up on the sights.
* Canted Aim (quick) bound: it raises canted without aim, held or toggled per MCM, exactly as the canted key does today.
* Existing user: the key they had canted on, default or rebound, stays on Canted Aim and only works while aiming. Canted Aim (quick) is `[unbound]` until they bind it.
* Reset bindings: Canted Aim (quick) is unbound again, also after a restart.
* Inspect mode: whichever canted key the player has rotates the weapon.

## Tradeoffs

* No default binding for the new action over a default key. The cost is that every player who wants standalone canted has to bind it once, and `mod-lib` has to support an action without a default.
* No migration over moving a rebound canted key to the new action. The cost is that every existing user has to bind the new action once, and until then their canted key only works while aiming.
* The canted variant of aim counting as canted for every rule over a flip of the pose only. The cost is on the default shared sprint and hold breath key in sprint hold mode: under the canted variant the key does nothing, so the player has to end the aim to sprint. With a pose-only flip the key would keep holding breath under a canted weapon.
* The shared key starting no sprint under the canted variant over the key turning into a sprint key when breath ends. The cost is that the two sprint modes differ there: in toggle mode a sprint press still ends a toggled canted aim.
* Keeping the variant across aim sessions as vanilla does over starting each aim on the sights. The cost is state the player cannot see until they aim.
* Either action rotating in inspect over one fixed action. The cost is that a player who does use both has two rotation keys.
