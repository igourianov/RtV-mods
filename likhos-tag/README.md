# Likho's Tag

Real names, damage and weight for guns and attachments.

## Features

* Rebalanced damage and penetration values across the board to align closer with the real world.
	* Overall damage went up, while penetration went down, making the player more survivable and AI less so.
	* Plates and helmets will last a bit longer.
* All weapons, attachments and magazines now have real life names
* Russian items got Russian names (switch to English in LCM, takes a game restart)
* Real life item weights (it matters for VosTac)
* KAR-21 (308) magazine size 30 -> 20
* Item tooltip is now slightly less verbose and more useful

## Out of scope / Will not fix

The recipe names retain vanilla weapon names. The name is used as a look up key, and I can't change it without breaking every other mod touching recipes. Not worth it to just change the name. My `Likho's No.9` mod replaces them with a more elegant repair kit solution.

## Ballistics

A round is stopped by armor of the same or higher level. Armor levels: plate II and SSh-39 are 1, plate IIIA and police helmet are 2, plate III is 3, plate III+ is 4, plate IV is 5.

The game only checks penetration for shots that hit the player. It has no effect on the damage your own guns deal to enemies.

Changed values are shown as vanilla → override. A single value means unchanged from vanilla and is listed for comparison only. The same applies to all tables below.

| Vanilla Name | Override Name | Penetration | Damage | Weight |
|--------------|---------------|-------------|--------|--------|
| 9x18 | GECO 9x18 FMJ | 1 | 25 → 20 | 0.3 → 0.5 |
| 9x19 | GECO 9mm 124gr FMJ | 1 | 25 | 0.4 → 0.6 |
| .45 ACP | GECO .45 Auto FMJ | 1 | 25 → 35 | 0.5 → 1.05 |
| 12/70 | Hubertus 00 Buck | 2 → 1 | 40 | 0.3 → 0.44 |
| 4.6x30 | Fiocchi 46EXA 4.6x30mm | 2 | 25 → 35 | 0.5 → 0.35 |
| .223 | Fiocchi 223A | 4 → 3 | 40 | 0.5 → 0.35 |
| 5.45x39 | Barnaul 5.45 FMJ | 3 | 40 | 0.4 → 0.33 |
| 7.62x39 | Lapua 7.62 Ball | 4 → 3 | 40 → 45 | 0.6 → 0.49 |
| .308 | Lapua S374 .308Win | 4 | 50 → 70 | 0.6 → 0.65 |
| 7.62x54R | TulAmmo 7.62x54R FMJ | 4 | 50 → 70 | 0.6 → 0.46 |
| 9x39 | WOLF 9x39 Subsonic | 3 | 30 → 50 | 0.3 → 0.46 |

## Weapons

| Vanilla Name | Override Name | Weight |
|--------------|---------------|--------|
| KA-12 | AK-12 Gen 1 | 3.5 |
| KA-M | AKM | 3.4 → 3.3 |
| KAS-74U | AKS-74U | 2.8 → 2.7 |
| C1911 | Colt 1911 | 1.1 |
| G7 | Glock 17 | 0.65 |
| K416 | H&K 416 | 3.8 → 3.5 |
| HP-DA | FN High Power Double-Action | 0.9 |
| KAR-21 (.223) | KAR-21 .223 | 3.7 |
| KAR-21 (.308) | KAR-21 .308 | 3.8 |
| KP-31 | Suomi KP-31 | 4.6 |
| M4A1 | Colt M4A1 | 3.0 → 2.9 |
| M78 | Valmet M78 | 4.8 → 5.0 |
| Karov | Makarov | 0.75 |
| KM18 | Mk 18 Mod 1 | 2.75 |
| Mosin | Mosin M91/30 | 4.0 |
| PM5 | H&K MP5A3 | 2.6 |
| PM5-K | H&K MP5K | 2.0 |
| PM5-SD | H&K MP5SD | 2.8 → 3.4 |
| PM7 | H&K MP7 | 2.1 → 2.0 |
| P3 | SIG Sauer P320 | 0.8 |
| RM-870 | Remington 870 Police Magnum | 3.6 → 3.2 |
| RK-62 | Valmet RK-62 | 3.8 → 3.5 |
| RK-62M | Millog RK-62M3 | 3.8 → 4.1 |
| RK-95 | Sako RK-95 TP | 3.8 → 3.7 |
| VSD | Dragunov | 5.3 → 3.7 |
| SSV | Vintorez | 2.8 → 2.6 |

## Magazines
| Vanilla Name | Override Name | Weight |
|--------------|---------------|--------|
| KA-12 Magazine | AK-12 mag | 0.2 → 0.19 |
| KA-M Magazine | AKM mag | 0.3 → 0.43 |
| KAS-74U Magazine | AK-74 Bakelite mag | 0.2 → 0.23 |
| C1911 Magazine | Colt 1911 mag | 0.1 → 0.08 |
| G7 Magazine | Glock mag | 0.1 → 0.08 |
| KAR-21 Magazine (.223) | Magpul PMAG M3 | 0.2 → 0.14 |
| KAR-21 Magazine (.308) | Magpul PMAG LR/SR M3 | 0.2 → 0.18 |
| KP-31 Drum | KP-31 Drum | 1.1 |
| M78 Magazine | M78 mag | 0.3 |
| Karov Magazine | PM mag | 0.1 → 0.05 |
| MP5 Magazine | MP5 mag | 0.2 → 0.18 |
| MP7 Magazine | MP7 mag | 1.0 → 0.1 |
| P3 Magazine | P320 mag | 0.1 → 0.075 |
| RK Magazine | Sako RK mag | 0.2 → 0.17 |
| STANAG Magazine | USGI STANAG mag | 0.2 → 0.17 |
| VSD Magazine | SVD Waffle mag | 1.0 → 0.21 |
| SS Magazine | VSS Plum mag | 0.2 → 0.18 |

## Attachments
| Vanilla Name | Override Name | Weight |
|--------------|---------------|--------|
| ATOG | Trijicon ACOG TA31 | 0.6 → 0.5 |
| HMR | Leupold HAMR 4x | 0.6 → 0.5 |
| POSP | Zenit-BelOMO POSP | 0.6 → 0.9 |
| PU Scope | PU 3.5x | 0.6 → 0.4 |
| VDU | EOTech Vudu 1-10x | 0.6 → 0.75 |
| Leopard | Leupold Mark 8 CQBSS | 0.7 → 0.85 |
| MRM | Trijicon RMR | 0.1 → 0.035 |
| EXP | EOTech EXPS3-0 | 0.5 → 0.4 |
| Kobra | Axion Kobra | 0.4 |
| Micro | Aimpoint T2 | 0.2 |
| RMO | Trijicon MRO | 0.3 → 0.2 |
| PRO | Aimpoint PRO | 0.5 → 0.35 |
| RSO | Trijicon SRO | 0.1 → 0.045 |
| AN-15 | L3 Insight AN/PEQ-15 | 0.2 → 0.21 |
| Hybrid | SilencerCo Hybrid 46 | 0.5 → 0.4 |
| Monster | SureFire SOCOM556 Monster | 0.5 |
| Navy | KAC MP5-N Suppressor | 0.4 → 0.43 |
| OZ5 | Swiss Arms Pro Laser | 0.2 → 0.21 |
| PBS | PBS-1 | 0.6 → 0.62 |
| PTN | Resilient Suppressors Putnik | 0.6 → 0.59 |
| Rider | SureFire Ryder 9M-Ti | 0.2 → 0.31 |
| SLV | SilencerCo Salvo 12 | 0.9 → 0.97 |
| SOCOM | SureFire SOCOM556 RC2 | 0.5 → 0.48 |
| Thor | AWC Thor PSR | 0.7 → 0.51 |

## Other
| Vanilla Name | Override Name | Weight |
|--------------|---------------|--------|
| PV7 | AN/PVS-7 | 1.2 → 0.9 |
| Armor Plate (II) | | 1.5 → 0.3 |
| Armor Plate (IIIA) | | 2.0 → 0.5 |

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later
- [Likho's Config Manager (LCM)](https://vostokmods.net/mod/likhos-config-manager). Optional, the mod runs on its default settings without it.
