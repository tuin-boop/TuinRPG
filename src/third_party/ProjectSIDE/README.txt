PROJECTSIDE - WEAPONS AND EFFECTS COMPATIBILITY EDITION
=======================================================

Purpose
-------
This package isolates ProjectSIDE's weapon animations and weapon effects for
use alongside Doom RTX and other content/visual mods.

Quick grenade
-------------
- Press G by default (bindable as "Throw quick grenade" under the
  "ProjectSIDE Quick Grenade" section in Controls).
- It can be thrown during a reload; starting the throw cancels that reload.
- Players begin with 2 grenades and can carry 5 (8 with a backpack).
- Monsters have a 1-in-12 chance to drop one.
- Loose Clip, Shell, RocketAmmo, or Cell pickups have a 1-in-10 chance to
  become a grenade pickup.
- Grenade visuals and sounds are adapted from Doom Deluxe Beta 1.
- The HNDG hand and GPIN pin layers retain Doom Deluxe's original far-throw
  frame timing; the grenade leaves the hand on frame L.
- Grenade reserve is displayed as a larger icon/count above the lower-right
  ammunition display, clear of the health and armor HUD.
- Fists and chainsaw are hidden for the complete throw animation, preventing
  their arms from drawing beneath the grenade hand. Their grenade hand/pin are
  shifted downward at full size; other weapon throws remain unchanged.
- The thrown grenade and blast use Brutal Doom 22's GRND grenade, EXP3 flames,
  SM9K smoke, SB17 smoke column, FLAR flashes, and near/distant GRENEXP sounds.
- Damage uses Brutal's five concentric shrapnel bands: roughly 200 combined
  close-range damage, falling off through 160/240/320/400/480 map units.
- Throw speed is 35 with a stronger upward arc and momentum-aware running boost.

Included
--------
- Fist, chainsaw, pistol, rifle, shotgun, super shotgun, chaingun, rocket
  launcher, plasma rifle and BFG definitions from ProjectSIDE.
- Weapon sprites, draw/fire sounds, casings, bullet puffs, smoke, impact
  particles, and player rocket/plasma/BFG projectile effects.
- Only the small ACS helpers directly required by those weapon states.
- A minimal event handler that swaps the base starting fist/pistol for exactly
  one ProjectSIDE replacement without replacing DoomPlayer.

Excluded
--------
- Monster replacements and monster sprites.
- DoomPlayer replacement and KEYCONF player-class override.
- Monster projectile replacements.
- Gore, death variants, decorations, items, terrain, footsteps and ambience.
- HUD, menu, movement sway/tilt, color grading, maps and gameplay rebalancing.

Compatibility and load order
----------------------------
Load Doom RTX first, then this PK3 last. This package still replaces the
vanilla weapon actor classes so that ProjectSIDE's animations can be used, but
it does not replace the player class or any monster class.

Credits
-------
Derived from ProjectSIDE.pk3. See Credits.txt for its original contributor
credits. This compatibility assembly does not claim ownership of those assets.
