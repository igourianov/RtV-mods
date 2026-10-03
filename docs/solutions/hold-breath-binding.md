# Hold breath binding

## Intent

Give hold breath in VosTac its own key binding, separate from sprint.

* Hold breath is an action of its own in the game's key binding list.
* By default it sits on the same key as sprint. Most players are expected to keep it there.
* The footprint in the input bus stays small. Hold breath is the key being down under aim, and a sprint under aim is whatever is left.
* A player who gives the two actions different keys gets a plain hold breath key and a sprint key that behaves under aim like it does under canted and binoculars: it ends the aim.

## Constraints and assumptions

* The stance rules of the input bus stay as they are, apart from sprint against aim and hold breath. Two axes with one state each, toggles as latches that are cleared when they lose, held keys followed live with the last pressed winning, a toggle press dropped when a held key would override it at once, gates and locks.
* Hold breath is always a hold, whatever the sprint mode.
* The bus never compares bindings. One set of rules covers a shared key and separate keys. Ruled out: a rule set per case, picked by comparing the two bindings. It makes every case exact, at the cost of a binding comparison, extra state and two sets of cases to keep correct.
* A key does not keep the meaning it started with. Ruled out: a press that remembers whether it started as a sprint or as hold breath. It costs state in the bus, and the transitions it prevents are acceptable.
* Vanilla's remap screen accepts the same key for two actions and leaves both bound. One key press then reports both actions as pressed.
* Vanilla saves a binding only when the player rebinds it or resets the list. A registered action that was never rebound has no saved binding.
* When the list of actions is built, vanilla has already applied the saved sprint binding to the input map. After a reset the input map holds the project defaults, so sprint is on Shift.
* Vanilla `ResetActions` rewrites the saved bindings of its own actions only. A saved binding of a registered action survives it unless `mod-lib` drops it.
* `mod-lib` is copied into every mod by the build. Its contract for the existing callers of `register_action` stays as it is.

## Scope

Owned:

* `likhos-vostac/Scripts/Nodes/InputBus.gd`: the sprint and hold breath input and how they resolve against aim.
* `likhos-vostac/Scripts/Main.gd`: the registration of the hold breath action.
* `mod-lib/Main.gd`: `register_action`.
* `mod-lib/Inputs.gd`: `attach_extra_actions`.

Context only:

* `likhos-vostac/Scripts/Hooks/Character.gd`: reads hold breath from the bus and validates it against arm stamina.
* `likhos-vostac/Scripts/Hooks/Controller.gd`: reads sprint from the bus.
* Vanilla `src/Scripts/Inputs.gd`: `CreateActions`, `ResetActions` and the remap in `_input`.
* `likhos-tacmed/Scripts/Main.gd`: the other caller of `register_action`.

## Solution

### The action

`Main.gd` registers a `hold_breath` action, labeled `Hold Breath`, next to the other VosTac actions. Its default is the sprint action, not a fixed key.

### Default binding in mod-lib

* A registered action's default is either a fixed event, as before, or another action.
* With another action as the default, the registered action takes that action's binding as it is in the input map when the default is applied.
* The default is applied when the list is built and the action has no saved binding, and on a reset.
* A reset drops the saved binding of every registered action.

So hold breath follows sprint until the player binds it. A player who rebound sprint before gets hold breath on that key. A player who rebinds sprint later gets hold breath on the new key from the next time the list is built. Once the player binds hold breath, it stays where they put it. A reset puts both on Shift.

### The bus

`InputBus` reads the `hold_breath` action next to the `sprint` action and still exposes one resolved hold breath value. Hold breath has no state of its own.

* Hold breath is on while its key is down and aim is in effect. It sets and clears nothing.
* While hold breath is on, a sprint key starts nothing, in both sprint modes.

A sprint action that does start while aim is in effect is a conflict with aim, and the later action wins.

* Sprint in toggle mode, aim latched: the press latches sprint and clears the aim.
* Sprint in toggle mode, aim key held: the press is lost.
* Sprint in hold mode, aim latched: the sprint key clears the aim latch when it starts.
* Sprint in hold mode, aim key held: the sprint key was pressed later, so it wins. Releasing it falls back to the aim key.
* A sprint key that was already down when aim took effect is suspended and comes back when aim ends.

On a shared key that makes a press under aim hold breath and no sprint, and a press outside aim a sprint. The key follows the aim from there: it turns into a sprint key when the aim stops being in effect, and into hold breath when aim takes effect over it.

### Observable result

Shared binding, the default:

* Aiming, then the key held: breath is held, no sprint. When aim ends with the key still down, the player sprints in hold mode and walks in toggle mode.
* Sprinting with the key held, then aim: the weapon aims and breath is held. When aim ends with the key still down, the player sprints again.
* Sprint in toggle mode, aiming, key pressed: breath is held while the key is down. The sprint toggle does not change.
* Sprint in hold mode, aim and breath held into a reload or another lock: the key becomes a sprint key when the lock starts. A latched aim is ended. A held aim key stays overridden after the lock until the key comes up, because the sprint started later.

Separate bindings:

* Aiming, hold breath key held: breath is held. Released: breath ends, aim stays.
* Hold breath key held, then aim: breath is held once the weapon aims.
* Hold breath key pressed without aim: nothing.
* Holding breath, sprint pressed: nothing.
* Toggled aim, sprint pressed or held: the aim ends and the player sprints. It does not come back.
* Held aim, sprint held on top: the player sprints. Releasing sprint goes back to aim.
* Held aim, sprint toggle pressed: nothing.
* Sprinting with the key held, then aim: the weapon aims. When aim ends, the player sprints again.

Bindings:

* A fresh install has sprint and hold breath on Shift, both listed in the remap screen.
* A player with sprint on another key and no hold breath binding has hold breath on that key.
* Reset to defaults puts both on Shift, also after a restart.

## Tradeoffs

* One rule set without a binding comparison over exact rules per case. The cost: with separate bindings the sprint key does nothing while breath is held.
* Hold breath without state over a press that keeps its meaning. The cost is on a shared key:
	* Releasing aim with the key still down starts a sprint in hold mode.
	* Aiming out of a held sprint holds breath at once and drains arm stamina.
	* A lock that suspends the aim turns the key into a sprint key, which ends a latched aim and keeps a held aim key overridden until the key comes up.
* A default taken from another action over a fixed Shift default. The cost is a wider `register_action` contract in `mod-lib`, which ships with every mod.
* Applying the sprint default whenever the list is built over saving it once. The cost: after rebinding sprint, hold breath stays on the old key until the list is built again. Saving it once would leave hold breath behind for good.
