# Likho's TacMed

Road to Vostok mod that modifies medical consumables to be more useful. Keeps with realism. Lore friendly.

## IFAK/AFAK keybind

Added a new binding (default to `Z`) under vanilla settings to quick access your IFAK/AFAK without opening inventory. 

The associated logic will intelligently pick item to use to minimize waste. 

## IFAK

IFAK has been reworked from an excotic, safe queen to a healing workhorse.

* IFAK is now **NOT CONSUMED** on use, but instead loses condition.
* Heals for the exact value, no overflow - 150 healing pool.
* Refilled by basic healing items like bandages - see compatible list.
* It is slightly faster to use than basic bandage (3sec vs 4sec default).
* It now only removes bleeding and burning conditions.
* Increased in weight from 0.5kg to 2kg.
* It can now be sold by Doctor for measly 1000€ + tip.

Replenishment works 1:1 - consumed item's healing value vs IFAK condition. Tourniquet replenish 10%. So you effectivelly get 150% healing from the items you would've otherwise used separately.

## AFAK

AFAK got similar treatment to IFAK. It is now effectivelly an advanced version of a Medkit.

* Reusable, consumes condition on heal
* Refilled by a new recipe under Medical section: Used AFAK + 2x Medkit => AFAK (100%)
* 200 HP healing pool (vs 150 of 2 medkits)
* Removed Energy/Hydration/Mental (why was it even doing that?)
* Weight increase 1.2 -> 5.0kg
* Price 2850 -> 5000€
* Use speed 4.0 -> 3.0sec
* Can now be sold by Doctor

## Testing

You can now hurt yourself in the Tutorial room by pressing:
* `Ctrl+Shift+O`- a bit of damage and apply bleed
* `Ctrl+Shift+P`- a bit of damage and one of [Fracture, Rupture, Burn, Headshot]

## [Check out my other mods](https://modworkshop.net/search/mods?query=%22Likho%27s%22&sort=likes)

*Feedback and likes are welcome!*
