# Ammo check and inventory lock

## Intent

Fix a VosTac soft lock. Pressing Tab (inventory) while R is held for an ammo check, before the check starts, opens the inventory and leaves the gun frozen in the ammo check pose. The inventory cannot be closed.

## Constraints and assumptions

* Cause: during the hold window (`PENDING`, 0.3s) `gameData.isChecking` is still false, so vanilla `UIManager._input` opens the inventory and sets `gameData.freeze`. The ammo check then starts regardless. The R release arrives while `freeze` is set and is dropped by `is_engine_busy()`, so the state never leaves `PULLING`/`PAUSED`. `isChecking` stays true, which makes `UIManager` ignore Tab and Escape.
* When the inventory opens during the hold, the inventory wins. The pending ammo check or reload is abandoned.
* Ruled out: blocking the inventory during the hold window. Setting `isChecking` at press time would show the ammo HUD on every tap reload (`HUD.gd` ties mag/chamber visibility to `isChecking`) and drop aim on a Mosin/870 tap reload (`Handling.gd`). Hooking `UIManager` widens scope for no user benefit.
* Once the ammo check has started, `isChecking` blocks `UIManager`, so the inventory or settings cannot open mid-check. No other path is known to raise `freeze` during `PULLING`/`PAUSED`.

## Scope

Owned: `likhos-vostac/Scripts/Nodes/WeaponRig_Reload.gd`, the R hold state machine.

Context only: vanilla `UIManager.gd` (`UIOpen` sets `freeze`, `_input` gated on `isChecking`), `WeaponRig_Base.is_engine_busy()`.

## Solution

`WeaponRig_Reload` treats the hold window as abandonable. While in `PENDING`, if `is_engine_busy()` becomes true at any frame, the state returns to `NONE` with no reload and no ammo check. The ammo check starts only when the hold threshold elapses with the engine not busy.

All other states and transitions are unchanged.

Observable result: holding R and pressing Tab opens the inventory with the gun in its normal pose. Tab closes it. Pressing R afterwards behaves as a fresh press.

## Tradeoffs

* A hold interrupted by any busy condition (inventory, placing, drawing) is lost and must be restarted. Chosen over resuming it, because the release event may be dropped while busy and resuming would reintroduce the stuck state.
