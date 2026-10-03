# Stance intent resolution

## Intent

Make aim, canted aim, binoculars, sprint and crouch in VosTac resolve predictably when the player asks for more than one at once.

* Stances live on two axes, each holding one state at a time. Pose: neutral, sprinting, crouched. Arms: neutral, aim, canted, binoculars.
* Asking for a state replaces what it conflicts with. There is no return to a previous state: aim on, canted on, canted off ends in neutral, not in aim.
* The last user action wins. A held key keeps acting every frame, so it overrides a toggled state, and among held keys the last pressed wins.
* The one exception: sprint requested while aiming is not a conflict. It holds breath instead of sprinting.
* A sprint key does not change meaning when aim starts or ends. A sprint does not turn into hold breath and hold breath does not turn into a sprint.
* No mixed states. The reported one: crouch, hold aim, hold sprint to hold breath, release aim. The player ended up crouched with sprint footsteps and headbob.
* Stance input is read and its conflicts are resolved in one place, an input bus. Each hook consumes only its own resolved state, validates it against its own domain and acts on it.

## Constraints and assumptions

* A toggled state that loses a conflict is cleared, not suspended. Ruled out: suspended toggles that come back when the winner ends. They are state the player cannot see, and they need press order for toggles plus a rule for presses on a suppressed toggle.
* Two things still come back, and both are cheap. A held key, because it is still down. An aim or canted state after a lock, because the player asked for nothing else and the bus only has to ignore it while the lock lasts. A sprint made during the lock is such a request, and ends them. Ruled out: clearing aim or canted when a lock starts. A lock is a polled condition, so the bus would have to detect the change.
* The bus knows nothing about domain constraints: stamina, movement, ceilings, weapon collisions. Hooks do not report anything to it before it resolves. Ruled out: hooks reporting whether their stance can act, so the bus resolves only among those. It closes more gaps, but couples every domain to the resolve step.
* The bus does consult existing global state to know which inputs are stance inputs right now: `ModConfig.gated()`, `ModConfig.locked()` and whether a firearm is in hand. Without them a key used for something else (canted rotates the weapon during inspect) or an aim left on while unarmed would suppress sprint.
* A domain can withdraw its own state through the bus when it has to end it without the user asking. An optic strike (`ModConfig.optic_shiner`) withdraws aim, and a held aim key has to come up before it can aim again. A cleared rig (holster, weapon switch, swim start, death) withdraws a latched aim or canted. `BinocularsOverlay.gd` withdraws binoculars when it cannot raise them or has to drop them.
* Hold states follow the live key state, checked every tick, not press and release events. A hold state never outlives its key, also when the release never arrives as an event. A key pressed during a gate or a lock starts its state once that ends, if it is still down.
* The game has no height restricted areas at present, so the interplay of the ceiling check with the crouch latch is not a concern.
* Crouch is on the bus, because it conflicts with sprint. It is a toggle only.
* Swimming and jumping are domain states of `Controller.gd`. They are not requested through the bus.
* Binoculars are an arms state on the bus. Their key stays a latch with one extra: a press held longer than a short threshold lowers them on release. It never counts as a held key that overrides toggles, so an aim or canted press always replaces the binoculars.
* Binoculars need no firearm in hand.
* Hold breath is always a hold, in both sprint modes. A sprint key keeps the meaning it had when it was pressed: pressed while aim is in effect it is hold breath until released, otherwise it is a sprint action.
* Vanilla `ClearRig` resets `gameData.isAiming` but not `gameData.isCanted`.
* Vanilla does not run its movement state step while the player swims or flies, so `Controller.gd` resolves no stance then. The crouch flag keeps its value through a swim, as in vanilla, and catches up with the bus on the first frame after it.
* `gameData.primary || gameData.secondary` is true exactly while a firearm rig is in hand. Vanilla `RigManager` sets them on draw and `ClearRig` clears them.
* A node under the mod's `Main` autoload receives these input events during gameplay, the way `BinocularsOverlay` does.

## Scope

Owned:

* `likhos-vostac/Scripts/Nodes/InputBus.gd`: stance input, latches, held keys and conflict resolution.
* `likhos-vostac/Scripts/Main.gd`: creates the bus, hands it to the hooks that read it, routes scene loads and rig clears and keeps the vanilla weapon rig input suppressed.
* `likhos-vostac/Scripts/Hooks/Handling.gd`: `_resolve_aim_intent` and the reset of the canted flag when the rig is cleared.
* `likhos-vostac/mod.txt`: the hook declaration for `RigManager.ClearRig`.
* `likhos-vostac/Scripts/Hooks/Controller.gd`: `on_input` and `_update_state`.
* `likhos-vostac/Scripts/Hooks/Character.gd`: the source of `_hold_breath`.
* `likhos-vostac/Scripts/Nodes/BinocularsOverlay.gd`: its input handling and the transitions of its raise state.
* `likhos-vostac/Scripts/ModConfig.gd`: holds no stance state.

Context only:

* `ModConfig.gated()`, `ModConfig.locked()`, `ModConfig.optic_shiner`.
* `ModConfig.binoculars_active`: published by `BinocularsOverlay.gd` while the binoculars are actually up, read by the hooks that pose the weapon, scale look sensitivity and block night vision.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Inspect.gd`: uses the canted key while inspecting, which is a lock.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd`: raises `ModConfig.optic_shiner`.
* Vanilla `src/Scripts/Controller.gd` and `src/Scripts/Handling.gd`, where sprint cancels both aim and canted.
* Vanilla `Loader.LoadScene`, already hooked by the mod. `Death.gd` and `Menu.gd` call `gameData.Reset()` when their scenes load.

## Solution

### The bus

`InputBus` is a node created by `Main`, like `BinocularsOverlay`. It reads the aim, canted, binoculars, sprint and crouch input itself and is the only place that does. It exposes six resolved values: aim, canted, binoculars, sprint, crouch and hold breath. It resolves once per physics tick and around every input event, and the hooks read that result.

Each action has a mode, hold or toggle. Aim takes it from `gameData.aimMode`, sprint from `gameData.sprintMode`, canted from `ModConfig.cant_mode`, where `default` follows the aim mode. Crouch and binoculars are toggles.

The bus outlives every scene. It drops all its state whenever the game loads a scene, the way vanilla starts each scene with fresh aim and sprint toggles. A key that is still down starts its state again after the load.

### Conflicts

* Same axis: aim, canted and binoculars against each other, sprint against crouch.
* Across the axes: sprint against canted, sprint against binoculars.
* Sprint against aim is not a conflict while aim is in effect: a sprint key pressed then holds breath. A sprint action made while no aim is in effect wins over an aim that is asked for but not in effect, such as an aim key held under a winning canted or through a lock.
* Crouch coexists with every arms state.

### Toggles are latches

Each axis has one latch, which is either empty or holds one state of that axis.

* A toggle press clears the latch when its state is in effect. Otherwise it sets the latch to its state.
* Setting a latch clears what it conflicts with. The other state of its axis is replaced. Sprint clears canted and binoculars, and each of them clears sprint.
* While aim is in effect, a sprint latch is cleared.
* A toggle press is dropped when a held key would override it at once.
	* A held key that cannot take effect does not count. A canted key held through a lock or a holster does not drop a sprint press. A sprint key suspended under aim does not drop a crouch press. It does drop a canted press, because canted would end the aim and release the sprint.
	* Two simplifications are accepted. A held key counts even while a later held key overrides it. A binoculars press is dropped while an aim or canted key is down, also with no firearm in hand. Ruled out: resolving these exactly. They need three inputs at once or a key held through a holster.
* A binoculars press raises them and never lowers them. The release lowers them, unless it comes within a short threshold of the press that raised them. So a tap raises, a second tap lowers and a long hold lowers on release.

### Holds are live

* A hold state follows its key. It starts when the key is down and its input is accepted, and ends when the key comes up.
* While a held key is in effect, every latch it conflicts with is cleared. So nothing comes back when the key is released.
* Among held keys in conflict, the one pressed last wins. Releasing it falls back to the one still down. A sprint key that started as a sprint counts here against an aim key too: it started while that aim was not in effect, so it was pressed later and keeps the aim down until it is released.
* A held sprint key under aim is suspended, not hold breath. It sprints again when aim ends, because it is still down.

### Hold breath

* A sprint key pressed while aim is in effect is hold breath until it is released, in both sprint modes. It sets and clears nothing.
* Hold breath is on while such a key is down and aim is in effect.
* When aim ends with the key still down, nothing happens. The key does not become a sprint.

### Suspension

* While gated, toggle presses are not recorded and hold states do not start.
* While locked, aim, canted and binoculars toggle presses are not recorded, and aim and canted hold states do not start. The same goes for aim and canted with no firearm in hand.
* While locked, aim and canted are kept but not in effect.
* A sprint that takes effect during a lock clears a latched aim or canted, both alike.
* When the rig is cleared, a latched aim or canted is cleared with it. A held aim or canted key is not in effect while no firearm is in hand. They come back afterwards. A sprint key pressed meanwhile is a sprint action, not hold breath.

### Hooks

* `Handling.gd` reads aim and canted and writes `gameData.isAiming` and `gameData.isCanted` from them. On an optic strike it withdraws aim through the bus. When vanilla clears the rig it resets `gameData.isCanted`, the same way vanilla resets `gameData.isAiming` there, and withdraws a latched aim or canted through the bus. It handles no input. The vanilla weapon rig input stays suppressed by a hook that does nothing, registered in `Main.gd`.
* `Controller.gd` reads sprint and crouch. It validates sprint against its movement constraints: movement input, stamina, overweight, injuries and actually being crouched. It validates crouch against the ceiling, which forces a crouch and blocks standing up. It then writes `gameData.isRunning` and `gameData.isCrouching`. Its `on_input` keeps mouse look only.
* `Character.gd` reads hold breath and validates it against actually aiming and arm stamina.
* `BinocularsOverlay.gd` reads binoculars and drives its raise state from it. It validates against its own domain: a camera to attach to, night vision off and nothing else occupying the hands. When it cannot raise them or has to drop them, it withdraws binoculars through the bus. Its `_input` keeps the zoom keys only. It publishes `ModConfig.binoculars_active` as before.

### Observable result

Toggles:

* Aim on, canted on: the weapon goes canted. Canted off: neutral. The same holds the other way around.
* Aim on, canted on, sprint on: the player sprints. Sprint off: neutral arms, no canted and no aim.
* Sprint on, canted on: sprint stops and the weapon goes canted. Canted off: the player walks.
* Sprint on, aim on: the weapon aims. Aim off: the player walks.
* Crouch on, sprint on: the player stands up and sprints. Sprint off: the player stays standing.
* Sprint on, crouch on: the player crouches. Crouch off: the player walks.
* Aiming, sprint pressed: breath is held while the key is down. Nothing else changes.
* Binoculars up, aim or canted on: the binoculars drop and the weapon aims. Aim on, binoculars raised: aim is gone, also after the binoculars drop.
* Sprint on, binoculars raised: sprint stops. Binoculars up, sprint on: the binoculars drop with their lowering animation.

Holds:

* Two held keys in conflict: the later one wins, and releasing it falls back to the one still held.
* Held aim, held canted on top, then sprint held: the player sprints. Releasing sprint goes back to canted.
* A key held through a reload, a menu or a map load takes effect when that ends, without pressing it again.
* Aiming, then sprint held: hold breath, no sprint. When aim ends with the key still down, the player walks.
* Sprinting with the key held, then aim: the weapon aims and no breath is held. When aim ends with the key still down, the player sprints again.
* Crouched and aiming, then sprint held: the player stays crouched and holds breath. When aim is released with sprint still held, the player stays crouched and walks.

Mixed:

* A toggled state on, then a conflicting key held: the held state takes over and the toggled one is gone for good.
* A key held, then a conflicting toggle pressed: the press is lost.

Suspension:

* During a reload or other lock, an aim or canted left on does not block sprint. It comes back afterwards, unless the player sprinted meanwhile.
* Holstering or switching the weapon ends a toggled aim or canted. Drawing a weapon brings it up neutral.

## Tradeoffs

* An input bus over the two hooks arbitrating between themselves. The cost is a new node and every stance consumer depending on it.
* Clearing the loser over suspending it. The cost: after a sprint the player has to ask for canted or crouch again, and a toggled sprint does not resume after aiming.
* Held keys overriding toggles. The cost is two habits from today. A crouch press during a held sprint is lost, where it interrupts the sprint now. With held aim and a toggled canted, canted cannot come up while the aim key is down.
* Resolving before domain validation over hooks reporting what can act. The cost: a winner its domain then rejects still clears the loser. A sprint that takes over but cannot run, standing still or out of stamina, still ends a canted or a crouch. Binoculars the overlay refuses to raise still end the aim, canted or sprint they replaced. That includes a binoculars press during their own lowering animation, which is accepted as is.
* The bus reading the gates and the firearm state over a bus of raw input only. The cost is game state inside the bus. Without it an aim left on blocks sprint during a reload and while unarmed.
* Suspending aim and canted through a lock over clearing them. The cost is the one case where a state returns without the player asking: a toggled aim comes back after a reload.
* Binoculars on the bus over their own input handling. The cost is two habits from today. Binoculars can be raised with a toggled sprint on, which ends the sprint, where the press is ignored while running now. With no firearm in hand an aim or canted press does nothing, so it no longer lowers the binoculars either. A sprint that takes over lowers them with the animation, where running cuts them off at once now.
* Crouch on the bus over crouch input staying in `Controller.gd`. The cost: a player forced to crouch by a low ceiling stands up on leaving it unless they pressed crouch, where they stay crouched now.
