# Iron sights toggle

## Intent

Mosin and M28 have iron sights that stay usable under the PU scope. With such a pair in hand the secondary optic key switches the aim between the scope and the iron sights, the same way it switches the HAMR between its scope and its top red dot.

## Constraints and assumptions

* The weapon and scope pairs are named by the user, who states that the irons are usable under them. The build does not check sight line obstruction. It shows in game.
* M28 MOD is excluded by the user, although it accepts the PU.
* Ruled out: SVD and VSS under the POSP. The POSP model in game is incorrect and blocks their irons.
* Mosin and M28 accept only the PU, so a toggled state can never carry over from one optic to another through a direct swap.
* VosTac replaces vanilla `WeaponRig` input, ADS and physics processing with no-op hooks, so the whole secondary flow is VosTac's.
* `gameData.secondaryOptic` is the one flag for "aiming past the main optic". Vanilla `Optic.gd` reads it to switch the PIP off. VosTac reads it for `gameData.isScoped`, the magnification, the reticle fade and the idle cue. Vanilla `WeaponRig._ready` clears it for every new rig.
* The HAMR's top dot is a `secondary` node inside the optic scene. The PU has none, so a rig never has both a top dot and toggled irons.
* The PU is a fixed scope like the HAMR, so what VosTac already does for a toggled HAMR scope applies to it as is: no PIP, no magnification and a faded reticle.
* `Hooks/Handling.gd` poses an aim with an optic at the height of `rig.aimOffset` and the depth of `data.aimPosition`, pulled closer only while `isScoped` under PIP. An aim without an optic is posed at `data.aimPosition`, whose sideways component is zero on both weapons. So the no-optic aim height in `rig.aimOffset` gives the no-optic pose without `Handling.gd` knowing about irons.
* Neither weapon has foldable sights (`foldSights`), so mounting an optic leaves their irons up.

## Scope

Owned:

* `likhos-vostac/Scripts/ScopeCatalog.gd`: which rigs have a secondary sight line, where it sits and the optic state that follows from the toggle.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd`: the secondary optic input.
* `likhos-vostac/README.md` and `likhos-vostac/CHANGELOG.md`: the lines about the iron sights toggle.

Context only:

* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd` beyond the input: what a fixed scope shows while the aim is on the secondary sight line.
* `likhos-vostac/Scripts/Hooks/Handling.gd`: the aim pose from `rig.aimOffset`, the handling speed tiers and the idle cue rotation.
* Vanilla `src/Scripts/Optic.gd`, `src/Scripts/WeaponRig.gd` and the weapon and attachment resources under `src/Items/`.
* `FEATURES.md`. The user writes it.

## Solution

### Secondary sight line

A rig has at most one secondary sight line. `ScopeCatalog` resolves it from the rig, and it is the only place that knows the rule.

| Source | Condition | Aim height |
|---|---|---|
| The optic's own | The active optic has a `secondary` node | The optic's height plus the node's height scaled by the optic's scale |
| Iron sights | The weapon and its active optic are a listed pair | The weapon's no-optic aim height, from `data.aimPosition` |

The pairs are listed in `ScopeCatalog` by `data.file` and the optic's `attachmentData.file`:

| Weapon | Optic |
|---|---|
| `Mosin` | `PU` |
| `M28` | `PU` |

A rig without an optic has no secondary sight line.

### Toggle

* A `secondary_optic` press flips `gameData.secondaryOptic` whenever the rig has a secondary sight line, in or out of aim and under the gates the handler has today.
* `sync_optic_state` clears the flag when the rig has no secondary sight line, so removing the optic or the rig ends the state.
* While the flag is set, `rig.aimOffset` is the aim height of the secondary sight line. Otherwise it is the optic's height.

### On the secondary sight line

The scope is not looked through:

* `gameData.isScoped` is false and the magnification is 1, so there is no PIP, no narrowed main camera and no scoped sensitivity or sway.
* The scope's reticle is faded out, and fades back in when the aim returns to the scope.
* On irons the weapon sits in the no-optic aim pose.
* Handling speed is that of a non-magnified optic, as with the HAMR's dot.
* Out of aim, the weapon shows the same tilted idle cue as a toggled HAMR.

### Release notes

* The README lists the toggle under Aiming & Optics, next to the secondary optic line.
* The changelog entry names the two rifles, the PU and the `Secondary Optic` binding, and says the M28 MOD is not covered.

### Observable result

* Mosin or M28 with a PU: the secondary optic key while aiming drops the rifle to the irons with no magnification and no reticle. Pressing again returns to the scope.
* The key pressed out of aim on any of the above: the weapon tilts in idle and the next aim comes up on the irons.
* A HAMR on any weapon: the key switches between the scope and the top dot, as today.
* M28 MOD with a PU, SVD or VSS with a POSP, and every other weapon with an optic that has no top dot: the key does nothing.
* Removing the scope while toggled, or switching weapons: the next optic starts on its main sight line.

## Tradeoffs

* A list of pairs in code over deriving usable irons from rig geometry. The cost is that a weapon or scope added by the game or another mod gets the toggle only when listed.
* One shared `gameData.secondaryOptic` flag over a separate irons state. The cost is that no other code can tell irons from the HAMR's dot.
* The handling speed of a non-magnified optic over the plain iron sights tier. The cost is that irons under a scope come up slightly faster than irons on a bare rifle.
