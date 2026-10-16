TUIN RPG - NO CLASSES / WEAPON-MOD COMPATIBILITY BUILD
========================================================

Use TuinRPG_NoClasses.pk3 instead of TuinRPG.pk3. Never load both together.

PACKAGE CLEANUP
- The compatibility build excludes legacy casing/gore sound definitions and
  blood-decal overrides, leaving those to the engine or your gore mod.
- Unreferenced sprite families, brightmaps and sounds are omitted at build time.
  Shared source assets and compiled classes are retained for recovery and saves.
- The build writes noclasses-pruned-assets.txt beside the PK3 as an audit list.

NEW GAME MODES
- TuinRPG: normal campaign, engine skill fixed to Ultra-Violence.
- Hell's Gambit: single-player run on the currently loaded MAP01-MAP29 maps.
  Not tied to Hellbound. Missing maps are skipped; maps do not repeat until
  the available pool has been used. Requires Doom II-style MAPxx map names.
- Gambit locks RPG difficulty to Hard and starts with three distinct random
  Mythic (80%) or Godly (20%) weapons, full ammo, fists, and one life.
- Compatible former humans, demon/spectre, and flying-monster pools are
  shuffled. Replacements cannot be larger than the source; bosses and
  boss-death actors are preserved. Other monsters keep their original type.
- Each clear increases monster base level by 2, health scaling by 8%, damage
  scaling by 4%, and raises the chance of higher rarity monsters.
- Death ends the run. Top ten scores are stored in your engine configuration:
  1000 per map cleared, plus 10 + 10 per rarity tier for each monster kill.
- Open New Game or TuinRPG > New Game / Modes; high scores also have a hub card.
- Run progress is carried by the player token and server settings in saves.
  This is a local personal scoreboard, not an anti-cheat system.
- Immediate restarts reset the previous run's death state before initialization.
- Stage clears show an animated score report and the next stage's health,
  damage and rarity escalation, with a short reminder after map travel.
- No Classes menus and HUD surfaces use the original dark-blue palette.
  Tilted animated lettering is retained, including in the game-mode menu.
  Rarity, trait, key, health and armor colors stay distinct.

This build keeps:
- Monster levels, rarity, affixes and signature attacks
- Player XP, attributes and universal perks
- Permanent weapon perks earned once every 5 levels
- Weapon variants and support for custom weapon/ammunition classes
- Minimap, HUD, lives, coins, bosses, chests and John encounters

This build disables:
- The starting class-selection screen
- Class bonuses, penalties, training and ultimates
- Class abilities and automatically granted class weapons
- Class-specific perk-point awards (21 universal-perk points by level 30)
- ProjectSIDE player-weapon, projectile, puff and weapon-sound replacements
- The bundled quick-grenade/loadout handler and its class-oriented controls

Recommended load order:
1. Maps
2. Monster/content mods
3. Your weapon mod
4. TuinRPG_NoClasses.pk3

The compatibility build does not replace Doom's fist, chainsaw, guns,
projectiles, impact puffs or weapon sounds. The external weapon mod remains in
full control of the player's arsenal. Internal support definitions required by
the shared RPG scripts are never granted or selected while this edition runs.

Existing saves are handled safely. If a character already has a TuinRPG class,
the compatibility build temporarily parks it. Loading the normal TuinRPG.pk3
again restores that saved class rather than deleting it.

WEAPON PERKS (NO-CLASSES BUILD ONLY)
------------------------------------
Open the Character Screen with K and choose WEAPON PERKS. One permanent weapon-
perk point is awarded at levels 5, 10, 15, 20, 25 and 30. There are ten choices
but only six points by level 30. The two Rust perks need native ID24 resources.

- Pistol: double damage, but half firing speed
- Fist: permanent Berserk-strength damage plus another 50%; each hit costs 5% health
- Shotgun: 15% less direct damage; hits ignite enemies within 176 units for
  50% of hit damage over 3 seconds. Pellets combine; later blasts refresh
  the burn instead of stacking it. Walls block the area effect.
- Super Shotgun: piercing, armor-ignoring blasts, but 25% less direct damage
- Chaingun: triple damage, triple ammo use and triple ammunition capacity
- Plasma: guided projectiles seek nearby visible enemies
- BFG: four times the firing speed, but one quarter damage
- Rocket launcher (Hellfire Rockets): 30% less damage, 25% total critical chance.
  Critical hits also burn for 50% of their total damage over five seconds.
  Each burn stacks independently and keeps its own duration.
  Ordinary rocket hits no longer add automatic fire damage without this perk.
- Incinerator (Wildfire): refreshing 3-second burn, half of triggering damage,
  spreads to up to three nearby enemies within 128 units and line of sight.
  Secondary burns do not spread. Costs one extra fuel per four shots (+25%).
- Calamity Blade (Overcharge): +50% damage and projectile width; each native
  charge stage takes 26 rather than 20 tics (30% longer). Still pierces.

LEGACY OF RUST DISCOVERIES
-------------------------
Requires the engine's native ID24 weapons and the player's own id24res.wad;
no commercial weapon resources are bundled. With resources loaded, Legendary
and Mythic enemies have a 10% Incinerator selection chance AFTER a successful
weapon-drop roll. Boss chests have a 5% Calamity Blade and 20% Incinerator
selection chance. These can introduce weapons not yet owned. Quality still
uses the existing rarity roll; discovery does not guarantee a Godly item.
Once owned, either weapon also joins normal owned-weapon variant rolls.
New weapons grant their native starting fuel. While owning either weapon,
monster kills have a 15% chance to drop a 10-fuel can. Weapon loot tuning has
a Legacy of Rust discovery toggle (tuin_rust_discovery); disabling it stops
new discovery rolls but preserves existing weapons, perks and fuel support.
Rust rewards respect loaded weapon replacements, including FluidWeapons' own
replacement settings. Existing native Rust weapon rolls migrate to the active
replacement without changing IDs, rarity, bonuses or fuel. When FluidWeapons
is installed, leave its weapon replacement and Legacy of Rust weapons enabled.

Arsenal and perk panels use a larger layout with width-fitting text. Godly names
have smooth per-letter rainbow glow and motion inspired by FluidWeapons menus;
trait and selected perk names have gentler motion. Stat values remain still.

The system recognizes common weapon class names, tags and ammunition types so it
can work with replacement weapon mods. Unusual total conversions may use names
that cannot be classified automatically; the Character Screen reports that case.

SPECIAL LOOT TRAITS (NO-CLASSES BUILD ONLY)
-----------------------------------------
Scavenger's only rolls on weapons that consume ammunition. Existing ammo-less
Scavenger's rolls are repaired, preferring Vampire's if it is not already present.
Rare and Epic weapons roll 1 special trait, Legendary and Mythic roll 2, and
Godly roll 3. Traits are separate from permanent weapon perks and ordinary stat
affixes. Higher quality strengthens each trait. Existing variants and floor
drops gain a stable roll once when loaded; trading or reloading cannot reroll it.

PASSIVE means the selected variant for an owned weapon grants the effect while
holstered. Only the strongest copy of each passive applies. EQUIPPED means the
weapon making the attack, or currently held for defensive effects. Projectile
traits remember the weapon that fired them. Bonuses are personal in multiplayer.

Values below show Rare -> Godly; intermediate rarities improve between them:
- Guard's [Passive]: grants real armor up to a 10 -> 50 point floor, visible on
  the normal armor HUD. After 5 seconds without a hit it refills over 5 seconds.
  Stronger existing armor is preserved; damage is absorbed only once by armor.
- Medic's [Passive]: +1 HP every 5 -> 1 seconds, capped at normal maximum health.
- Hunter's [Equipped]: +20% -> +50% damage against a full-health enemy. All pellets
  in that opening tick qualify, even when the blast hits multiple monsters.
- Survivor's [Passive]: survive one fatal hit at 1 HP per map, with 1 -> 5 seconds
  of protection. All Survivor weapons share the charge; swapping cannot reset it.
  Saves preserve the charge. Forced engine kills are excluded.
- Executioner's [Equipped]: +25% -> +65% damage to enemies at or below 25% HP.
- Vampire's [Equipped]: weapon kills restore 2 -> 10 HP, capped at normal maximum.
- Scavenger's [Equipped]: 20% -> 60% chance on a weapon kill to refund one primary
  shot's ammunition, without exceeding capacity.
- Duelist's [Equipped]: repeated hits on one target build +5% damage per hit,
  capped at +20% -> +60%. Changing targets or weapons resets it. Pellets from
  one tick do not build extra stacks.
- Last Stand [Equipped]: below 30% health, +20% -> +60% damage and +5% -> +25%
  firing speed. The usual combined haste cap still applies to ordinary weapons.
- Fortune's [Passive]: +10% -> +50% coins collected. Fractional bonuses carry over
  so small coin pickups benefit too.
- Avenger's [Equipped]: taking a hit primes your next hit for +30% -> +70% damage
  for 5 seconds. The bonus covers a full pellet burst and is then consumed.
- Bulwark's [Equipped]: standing still for 2 seconds gives 8% -> 20% damage
  reduction. Moving, teleporting or changing weapon resets the stance.

- Second Wind [Passive]: below 25% normal maximum HP, heals 10 -> 30 HP over
  five seconds and grants +20% movement speed for five seconds. Shared 90-second
  cooldown; switching weapons or maps does not reset the cooldown.
- Momentum [Equipped]: +2% damage per weapon kill, capped at +50%. After eight
  seconds without a hit or kill, loses 2% per second. Switching weapons resets
  stacks. Projectiles remember the bonus present when fired.
- Prospector's [Passive]: +4% -> +20% relative non-boss loot-rarity chance,
  not percentage points. Does not increase drop count, boss rewards, or Godly
  eligibility. Only the strongest owned selected copy applies.
- Quartermaster's [Passive]: one primary-ammo unit per 12 -> 8 seconds while
  not firing. Plasma, BFG, rockets and multi-ammo shots take twice as long.
  Stops at 25% ammo capacity; firing or switching resets progress. No alt-ammo
  generation, whole-magazine refunds, or stacking from duplicate traits.

Press L to inspect traits: colored names have an animated white shimmer, and each
row explains the scope and exact strength. Floor-drop inspection shows the same
information. K shows live Guard armor, Medic regeneration, Survivor charge and
Fortune bonus. Godly weapon titles retain their rainbow text.
