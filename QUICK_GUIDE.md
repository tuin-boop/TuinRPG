# TuinRPG Quick Guide

TuinRPG adds RPG progression, rare monsters, weapon variants, bosses, loot and a merchant to Doom. Its release includes the complete ProjectSIDE compatibility-edition weapon/effect set and quick grenades, while leaving maps, monsters and the player class intact.

Press **F1** at any time to open the illustrated Tuin Doom RPG help page.

## Controls

- **K:** Character screen and stat spending
- **L:** Arsenal and equipped weapon variants
- **F:** Flashlight
- **N:** Minimap
- **Tap E / Use:** Inspect and equip nearby weapon drops or talk to John
- **Q:** Open the weapon wheel; move the mouse, then press Q, click or Enter to equip
- **G:** Throw a quick grenade
- **V:** Use the selected class ability; Doom Guy holds it to ready Blood Punch and releases it to strike

The keys can be changed under **Customize Controls > Tuin RPG**.

## Levelling and stats

Killing monsters awards XP. Every level grants one stat point:

- **Vitality:** +5 maximum health
- **Strength:** +2% damage
- **Luck:** Better bonus-XP and weapon-drop chances, plus +0.5% critical chance per point
- **Agility:** +2% firing speed; Agility plus weapon speed is capped at +75%
- **Endurance:** 1% less damage taken, up to 75%

Monsters also scale with the map and can appear as **Uncommon, Rare, Elite, Legendary, Mythic**, or the special **Boss** tier. Higher rarities have more health, damage, XP and affixes. Legendary and Mythic enemies may use special attacks, so watch for their warning glow.

Every five levels grants a perk point. The first point permanently chooses Tank, Healer, Executioner, Doom Guy, or Rogue under **K > Class and Perks**. Later points buy ranked health, ammunition, critical, protection, leech, and class perks. Class Ultimates unlock at level 20 after Class Training II.

Each class has a distinct V ability. Tank charges Overdrive by dealing and taking damage. Healer throws Field Supplies. Executioner arms Death Sentence and judges up to three targets with the next weapon hit. Doom Guy holds V to ready Blood Punch and releases it to strike. Rogue charges Shadow Veil by dealing weapon damage, then uses it to become untargetable until an ambush or the veil expires.

## Weapon loot

Enemies occasionally drop colored variants of weapons you already own. Look toward a drop to compare every bonus with your current weapon, then move close and press **E** to swap. Your old version drops onto the floor, and only one variant of each weapon type is equipped at a time.

Press **Q** once for the paused weapon wheel. Move the mouse to select, then press Q again, left-click or Enter to equip; Escape or right-click cancels. Its ammo bars run from red (low), through yellow, to green (high), and it supports weapons supplied by replacement mods.

Ammo capacity and pickup amounts increase with player/map progression so high-level enemies do not exhaust the arsenal. Backpacks stack with the bonus; the curve can be changed under **Ammo progression**.

Choose **Easy, Normal, Hard, or Crazy** in Tuin RPG Options, available directly from the Escape menu. Hard is the original balance; Normal halves monster health gained per level. Difficulty also controls damage, rarity pressure, Boss strength, and the maximum number of monster buffs. Changing it immediately rebalances living monsters after the menu closes and reports the effective values.

Weapon bonuses include firing speed, damage, life leech, execution damage against enemies below 30% health, critical chance, and extra kill XP. Critical hits deal double damage. Item level improves the strength of these rolls. Finale Bosses and, very rarely, native boss monsters can drop named **Godly** weapons—the highest tier. Equipped Godly weapons emit an icy-white pulse.

## Minimap, bosses and John

The minimap tracks explored geometry, special monsters, exits and weapon drops. Near the end of a suitable map, one surviving monster becomes a powerful finale Boss and is marked on the map. Defeating it guarantees a high-quality weapon reward.

John appears near the end of the level. Press **E** while facing him to buy health, armor, ammo, backpacks or weapons with coins dropped by monsters.

Ultimate Doom has special continuous finales:

- **E1M8:** Defeat both Boss Barons, then use John to travel to E2M1.
- **E2M8:** Defeat the Boss Cyberdemon, then use John to travel to E3M1.
- **E3M8:** Defeat the Boss Spider Mastermind, then use John to travel to E4M1.
- **E4M8:** Remains the true ending.

John carries your health, weapons, variants, coins and RPG progress into the next episode.

## Lives and mission ratings

You begin with three lives. When lethal damage spends a life, a short red revival scene freezes the action while John appears with an encouragement line. You then return to the map start at full health with brief protection while keeping your weapons, progression, and completed map actions. Rare and stronger enemies can drop a floating red heart that grants one extra life, up to nine by default.

The Mission Report scores kills, items, secrets, completion pace, and lives preserved. Avoiding deaths contributes up to 300 of the 1000 available points, so survival matters as much as clearing the map. The report also records damage, XP, coins, special enemies, Bosses, critical hits, class abilities, and John's verdict on the run.

## Useful advice

- Spend stat points regularly; late-map monsters become much stronger.
- Compare individual bonuses, not only gear score—a lower score may suit your build better.
- Legendary, Mythic and Boss glows reveal dangerous enemies before they attack.
- TuinRPG options let you adjust monster scaling, rarity, loot frequency, HUD styles, minimap size and menu pause behavior.
- Load TuinRPG after map and visual/content packs. Do not load the separate `ProjectSIDE_WeaponsEffects_Compat.pk3`; it is built into TuinRPG.
