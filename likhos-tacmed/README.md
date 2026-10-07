# Likho's TacMed

Rework high end medical consumables. Reloadable, reusable. Lore friendly.

## IFAK/AFAK keybind

Added a new binding (default to `Z`) under vanilla settings to quick access your IFAK/AFAK without opening inventory. 

The associated logic will intelligently pick item to use to minimize waste. 

## IFAK

IFAK has been reworked from an exotic, safe queen to a healing workhorse.

* IFAK is now **NOT CONSUMED** on use, but instead loses condition.
* Heals for the exact value, no overflow - 100 healing pool.
* Refilled by basic healing items like bandages - see compatible list.
* It is slightly faster to use than basic bandage (3sec vs 4sec default).
* It now only removes bleeding, burning and poisoning conditions.
* Increased in weight from 0.5kg to 1kg.
* It can now be sold by Doctor for measly 1000€ + tip.

Replenishment works 1:1 - consumed item's healing value vs IFAK condition. Tourniquet replenish 10%. So you effectively get 150% healing from the items you would've otherwise used separately.

## AFAK

AFAK got similar treatment to IFAK. It is now effectively an advanced version of a Medkit.

* Reusable, consumes condition on heal
* Refilled by a new recipe under Medical section: Used AFAK + 2x Medkit => AFAK (100%)
* 150 HP healing pool
* Removed Energy/Hydration/Mental (why was it even doing that?)
* Weight increase 1.2 -> 3.0kg
* Price 2850 -> 5000€
* Use speed 4.0 -> 3.0sec
* Can now be sold by Doctor

## Testing

You can now hurt yourself in the Tutorial room by pressing:
* `Ctrl+Shift+O`- a bit of damage and apply bleed
* `Ctrl+Shift+P`- a bit of damage and one of [Fracture, Rupture, Burn, Headshot, Poisoning]

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item definitions):
- `lib.patch()` on IFAK and AFAK items
- `lib.register()` new recipe for AFAK refill

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Use` (replace)
- `Interface.Combine` (replace)
- `Interface.Hover` (post)

## Install / Uninstall

Drop `likhos-tacmed.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-tacmed.vmz` from the `mods/` folder and relaunch the game.
