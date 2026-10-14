# Likho's TacMed

Reworks high-end medical consumables. Reloadable, reusable. Lore friendly.

## Quick heal keybind

Added a new binding (defaults to `Z`) under vanilla settings to quickly access your IFAK/AFAK without opening inventory. 

The associated logic will intelligently pick item to use to minimize waste. 

## IFAK and AFAK

Both have been reworked from exotic safe queens into an advanced version of a Medkit.

Both kits:

* Are **NOT CONSUMED** on use, but instead lose condition.
* Heal for the exact value, no overflow.
* Are refilled by dragging a compatible item onto them - see compatible list. Replenishment works 1:1 - consumed item's healing value vs the kit's healing pool.
* Are slightly faster to use than a basic bandage (3sec vs 4sec default).
* Can now be sold by Doctor.

| | IFAK | AFAK |
|---|---|---|
| Healing pool | 100 HP | 150 HP |
| Refilled by | basic healing items like bandages 1:1, Tourniquet=10% | Medkit, 50% each |
| Refill time | 1sec | 5sec |
| Removes | bleeding, burning, poisoning | bleeding, fracture, burning, poisoning, rupture, headshot |
| Weight | 0.5 -> 1.0kg | 1.2 -> 3.0kg |
| Price | 440 -> 1000€ | 2850 -> 5000€ |

AFAK no longer restores Energy/Hydration/Mental stats (why was it even doing that?).

## New recipe

An IFAK can be converted into an AFAK by a new recipe under Medical section: IFAK + 2x Medkit => AFAK (100%)

## Testing

You can now hurt yourself in the Tutorial room by pressing:
* `Ctrl+Shift+O` a bit of damage and apply bleed
* `Ctrl+Shift+P` a bit of damage and one of [Fracture, Rupture, Burn, Headshot, Poisoning]

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later
