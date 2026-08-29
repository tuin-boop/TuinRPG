# TuinRPG for Doom

<p align="center">
  <img src="src/graphics/TuinMenuTitle.png" alt="TuinRPG for Doom" width="720">
</p>

TuinRPG is a universal RPG layer for **GZDoom and UZDoom**. It adds player levels, classes, perks, rare monsters, affixes, weapon loot, finale bosses, a minimap and an end-level merchant without replacing the monsters, weapons, player class or maps supplied by Doom and most gameplay mods.

The ready-to-play `TuinRPG.pk3` is included in this repository and on the [GitHub Releases page](https://github.com/tuin-boop/TuinRPG/releases). For a compact introduction, see the [Quick Guide](QUICK_GUIDE.md).

## Quick start

1. Install a recent GZDoom or UZDoom build. Development is tested with **UZDoom 4.14.3**.
2. Download `TuinRPG.pk3` from the latest release.
3. Load it after your maps and weapon/gameplay mods:

   ```powershell
   uzdoom.exe -file mymap.wad myweaponmod.pk3 TuinRPG.pk3
   ```

4. Start a game and press `K` for the character screen. TuinRPG settings are also available directly from the Escape menu.

## Contents

- [Controls](#controls)
- [Classes and perks](#classes-and-perks)
- [Core features](#core-features)
- [Difficulty and monster progression](#level-modes)
- [Rarity and affixes](#rarity-and-affixes)
- [Weapon variants](#weapon-variants)
- [Minimap, finale bosses and John](#minimap-finale-bosses-and-john)
- [Compatibility](#compatibility-notes)
- [Building from source](#building-from-source)

## Controls

| Key | Action |
| --- | --- |
| `K` | Character screen, attributes, classes and perks |
| `L` | Arsenal and equipped weapon variants |
| `Q` | Open/close the mouse-controlled weapon wheel |
| `N` | Toggle the minimap |
| `F` | Toggle the flashlight |
| `E` / Use | Equip nearby loot or interact with John |

All bindings can be changed under **Customize Controls > Tuin RPG**.

## Classes and perks

Every five levels awards one perk point. The first point permanently selects a class:

| Class | Core role |
| --- | --- |
| **Tank** | 300 base health, 50% less damage taken and dealt, +50% ammunition gained, a 20%-max-health direct-hit cap, and damage-powered Overdrive |
| **Healer** | Heals the team for 5 HP every two seconds, deals 25% less damage and gains 25% more ammunition |
| **Damage Dealer** | Deals 30% more damage, has 25% less maximum health and takes 10% more damage |
| **Doom Guy** | Deals 10% more damage, takes 10% less damage, regenerates health, and charges a healing cone-shaped Blood Punch |
| **Rogue** | Has 20% less maximum health, +5% critical chance, causes critical hits to bleed enemies, and can actively trigger Shadow Veil for a powerful ambush |

Later points buy three ranks of **Vital Core**, **Scavenger**, **Killer Instinct**, **Iron Skin**, **Blood Drinker** and class-specific training. A permanent class capstone becomes available at level 20 after Class Training II. Rogue Class Training adds +2% critical chance, two seconds of Shadow Veil duration, and 15% more Shadow Charge from damage per rank. The Rogue's ambush deals x4 weapon damage or x20 fist/knuckle damage.

## Core features

- Generic hostile-monster detection (`ISMONSTER`, shootable, alive, not friendly)
- Progressive or fully random monster levels with configurable bounds/variance
- Hybrid progressive scaling that keeps map progression primary while letting monsters partially catch up when the player is far ahead; higher rarities and occasional surge rolls create threatening outliers
- An optional Hell Director that evaluates damage taken at 25%, 50% and 75% kills and can awaken an Elite, Legendary or Mythic threat; rare successful checks can send a translucent Assassin Imp to an older player trail position
- Configurable monster health and outgoing-damage scaling
- Crosshair-targeted monster name, level, health bar, and exact HP
- Optional world-space monster bars with live HP, rarity colors, level/name and compact affix labels
- Player XP, nonlinear levels, XP popups, and one stat point per level
- Optional Doom late-start/warp catch-up with matching levels/points and three Rare-or-better, weapon-mod-aware starting drops
- Vitality (+5 max HP), Strength (+2% outgoing damage), Luck (+0.5% critical chance plus a diminishing bonus-XP proc), Agility (+2% firing speed), and Endurance (-1% damage taken, capped at 75%); combined firing speed is capped at +75% and total critical chance at 50%
- A permanent first-perk class choice: Tank (300 base HP, 50% protection, -50% damage, +50% ammo, and Overdrive), Healer (team-wide 5 HP healing every two seconds, -25% damage, +25% ammo), Damage Dealer (+30% damage, -25% maximum health, +10% damage taken), Doom Guy (+10% damage, 10% protection, regeneration, and Blood Punch), or Rogue (20% lower maximum health and an actively triggered Shadow Veil). The choice costs one perk point.
- Rogues have +5% innate critical chance. Their critical hits, including forced Ambush criticals, inflict eight seconds of bleeding that repeats the triggering critical hit's total damage over eight ticks, capped at 24% of the target's RPG-scaled maximum health. Bleeding cannot refresh or stack, and the monster resists new Bleeding for 12 seconds after it ends. Critical hits still deal normal critical damage during both states. Bleeding appears on the target display and overhead health bar, with red floating damage numbers. Rogue Class Training adds another +2% critical chance per rank.
- Press the configurable **Class Ability** key (`V` by default) for the Tank's Overdrive, Doom Guy's Blood Punch, or the Rogue's Shadow Veil. Tank Overdrive charges from damage dealt plus four times health actually lost; its threshold is `800 + 50 × player level`. At full charge, `V` grants +150% weapon damage and firing speed for ten seconds with a red glow. It cannot recharge while active and empties when it ends. Normal combined firing-speed bonuses remain capped at +75%, while Overdrive safely raises that combined cap to +200%.
- Doom Guy's ordinary damage fills Blood Punch, requiring `500 + 40 × player level` damage for a full charge. Pressing `V` briefly hides the held weapon and muzzle flash while a fast red-tinted first-person fist animation plays, then releases a bright 110-degree crimson cone reaching 240 units. It deals `140 + 14 × player level` base damage (maximum 650) to every visible hostile in the cone and heals Doom Guy for 20% of actual damage dealt, capped at 75 HP per punch. Blood Punch cannot crit, inherit weapon-affix damage, or recharge itself.
- Overdrive firing speed uses the engine's universal weapon-state accelerator, so slow launchers and one-tic custom weapon animations receive the boost consistently. Thrown grenades are tracked through contact, fuse, death animation, and custom cleanup; reaching, exploding near, or disappearing within 192 units of a Cyberdemon or Spider Mastermind adds a controlled boss-impact component of 2% scaled health (minimum 128, maximum 500 raw damage).
- Rogue Shadow Veil makes the Rogue half translucent and untargetable for six seconds, forcing monsters to disengage and wander. Attacking, taking damage, expiry, or pressing the ability again ends it. Its ambush attack deals x4 weapon damage or x20 fist/knuckle damage; iconic finale bosses use reduced x2 ranged and x5 melee multipliers. Shadow Veil begins ready, but after use it can only be restored by dealing ordinary weapon damage. A full charge requires `400 + 60 × player level` damage, before Class Training bonuses. Ambush and Bleeding damage do not refill the ability, preventing immediate loops, but sustained damage to a boss can earn another Veil during that fight. Waiting provides no charge. Each Class Training rank adds two seconds of duration and 15% more charge from damage.
- Later perk points purchase three ranks of Vital Core (+10 HP/rank), Scavenger (+10% ammo/rank), Killer Instinct (+2% critical chance/rank), Iron Skin (-3% incoming damage/rank), Blood Drinker (1% damage leech/rank), and a class-specific specialty. A level-20 capstone requires Class Training II.
- Floating combat damage numbers rise and curl away from hit monsters; rapid pellet hits merge into a readable total, critical hits appear larger and gold, and bleed damage appears separately in red.
- Mouse-operable character menu with pause, 10% slow motion, or no-pause mode
- Progress stored on the individual player as an inventory token, including in normal saves and across map transitions
- A full `Tuin RPG Options` page added to GZDoom's Options menu
- Scalable HUD text and a substantially larger targeted-monster health bar
- Configurable Normal, Uncommon, Rare, Elite, Legendary, and Mythic monsters
- Generated names, tier-colored HUD presentation, rarity health/damage scaling, and rarity XP bonuses
- Warm gold Legendary glows and stronger pulsing violet Mythic glows, with enable/radius options
- Archetype-aware Legendary/Mythic signature attacks with visible warning flashes and configurable cooldowns
- Rare, leveled weapon variants for weapons already owned, with colored/glowing drops, comparison HUD, Use-key pickup, and a persistent Arsenal
- Modular Swift, Armored, Regenerating, Berserker, Explosive, Vampiric, Poisonous, Healer, and Warding affixes
- Optional rotating minimap with explored geometry, rarity-monster tracking, weapon-drop diamonds and level statistics
- A configurable once-per-map level Boss tier above Mythic, with a 5% Godly chance by default
- Iconic E1M8, E2M8 and E3M8 episode Bosses with a guaranteed Godly weapon reward
- Four overall difficulty profiles: Easy, Normal, Hard and Crazy. Hard preserves the original balance; Normal halves health gained from monster levels. Profiles also tune damage growth, special-monster frequency and power, Boss scaling, and maximum affixes (2/3/5/8). Changing difficulty automatically rebalances living monsters when gameplay resumes and prints the effective values.
- Direct **Tuin RPG Options** access from the first Escape menu as well as the full Options menu.
- Boss-sourced Godly named weapons with stronger rolls and a distinct icy-white glow

Individual weapon XP/levelling, a codex and achievements are not included in this release.

## Building from source

PowerShell creates the distributable `TuinRPG.pk3` directly from `src`:

```powershell
.\build.ps1
```

For balance testing, open the console and enter `netevent tuin_give_levels 10` to grant ten player levels. The command accepts 1-100 levels at a time and awards the same stat points and every-fifth-level perk points as ordinary leveling. Open the character screen with `K`, then choose **Class and Perks** to select a permanent class and spend later points.

For predictable load order, put TuinRPG after maps and content packs. If another gameplay mod uses damage-event rewriting, test that combination: TuinRPG applies only the extra level/stat damage through the generic damage event and never changes weapon or monster classes.

## Level modes

- **Progressive:** uses the map's numeric level number where available, falling back to maps visited, then applies the configured random variance.
- **Random:** every detected monster rolls independently between the configured minimum and maximum.

Changing scaling settings affects newly initialized monsters. Existing monsters retain the values saved with them so loading a save cannot scale them twice.

Visible monsters within the configured overhead-bar range receive a compact display above their actor: name and level, a live rarity-colored health bar, exact HP, and short affix labels such as `SWIFT`, `ARMOR`, `REGEN`, `RAGE`, `BOOM`, and `LEECH`. The HUD options control their range and scale, how many nearby monsters may display one simultaneously, and whether the presentation uses the classic targeted bar, overhead bars, both styles, or neither.

With **Late-start/warp catch-up** enabled, beginning a new Doom game on a later map or making a non-sequential map jump raises an under-levelled player above that map's progressive base tier (three bonus levels by default). It preserves existing stats, awards only the missing stat/skill points, and spawns three distinct Rare-or-better weapon choices nearby. Accepting a newly granted catch-up weapon also refills 25% of each carried ammo type. Normal sequential map progression does not trigger it, and weapon classes are resolved through active replacements for compatibility with conventional weapon mods.

Ammo now grows with the campaign's tougher enemies. By default, every progression level after the first adds 2% to carried-ammo capacity (up to 2x) and 1.5% to ammo-pickup quantities (up to 1.75x), using whichever is higher between the player's level and map progression. Backpacks stack with the capacity bonus, and the system discovers custom ammunition classes used by weapon mods automatically. All values can be adjusted or disabled under **Tuin RPG Options > Ammo progression**.

## Rarity and affixes

The default chances follow a descending curve: 15% Uncommon, 7% Rare, 2.5% Elite, 1% Legendary, and 0.5% Mythic. Each chance and the maximum affix count can be changed from **Tuin RPG Options**. Higher tiers gain health, damage, XP, additional affixes, generated names, and distinct HUD colors. Mythics may naturally roll four or five affixes; ordinary late-game finale Bosses can reach higher configurable counts, while the iconic episode encounters retain their smaller hand-balanced limits.

Rare, Elite, Legendary and Mythic enemies whose base health is below a Hell Knight always reserve one trait slot for Armored. Their remaining traits are random. Normal and Uncommon fodder do not receive this guarantee.

Chance values are literal percentages: `1.0` is 1%, while `100` guarantees that tier when higher-priority tier chances are zero. Manual changes normally affect newly spawned monsters, so use **Reroll living monsters now** to update the current map. **Testing preset: all Mythic** and **Reset rarity defaults** both reroll living monsters automatically.

- **Swift:** uses additional `A_FastChase` calls while chasing, reacts immediately, searches for players more frequently, and retains a chosen player target longer.
- **Armored:** reduces incoming damage.
- **Regenerating:** restores a percentage of maximum health each second.
- **Berserker:** deals increased damage below 40% health.
- **Explosive:** creates a level-scaled death explosion.
- **Vampiric:** heals when damaging a player.
- **Poisonous:** applies a level-scaled damage-over-time effect to players.
- **Healer:** restores `5 + monster level` health per second to visible nearby allies. It self-heals for only 25% of that amount, and taking damage disables its self-healing for two seconds.
- **Warding:** grants visible nearby allies temporary damage reduction, but never protects the Warding monster itself.

Rogue Bleeding halves all monster healing while it remains active, including Healer, Regenerating, and Vampiric recovery.

TuinRPG's added player damage uses diminishing overflow during half-second bursts against stronger enemies. Base weapon damage is never reduced. Rare-through-Mythic monsters receive the first 25% of maximum health in RPG bonus damage normally and only 25% of overflow; ordinary RPG bosses use a 15% threshold with 20% overflow, while iconic finale bosses use an 8% threshold with 15% overflow. Grouping damage into a short burst prevents BFG tracers, shotgun pellets, and rapid attacks from receiving a fresh threshold for every individual hit.

Cyberdemons and Spider Masterminds have 75% BFG resistance as an innate species trait. Direct BFG projectiles, tracer/splash damage, and recognizable replacement BFG weapons deal 25% damage to them. Other weapons remain fully effective, encouraging a broader arsenal without making any weapon mandatory.

Affix effect strengths have their own tuning submenu. Forced/scripted damage bypasses Armored and player Endurance so telefrags and mandatory map logic remain reliable.

## Signature attacks

Legendary monsters gain a gold-telegraphed signature attack; Mythic monsters use stronger patterns more often after a violet warning flash. Attacks follow the monster's combat identity: hitscanners fire appropriate bullets, Doom projectile monsters use their native projectile family, and melee monsters charge. Unknown custom ranged monsters repeat their own missile state, while unknown melee monsters receive only a physical charge. Bosses, Archviles, Pain Elementals, and Lost Souls are excluded to avoid disrupting scripted encounters and monster-summoning logic.

## Weapon variants

Every defeated monster has a small chance to drop a variant of a weapon already owned by the killing player. The default base chance is 1.5%; monster rarity and player Luck improve it. Normal enemies can still produce every quality through Mythic, but high-end results remain exceptionally rare. Finale Bosses guarantee a Godly weapon, while native/custom actors carrying the engine's `BOSS` flag receive a separate 5% direct Godly chance. Item level is based on the defeated monster's level (plus a small variance) and improves the rolled affix strengths.

Weapon variants can roll firing speed, damage, damage leech, execution damage, kill XP, or critical chance. Every item level after level 1 also grants +2% inherent damage, capped at +60%, so later drops can compete with exceptional early-game equipment. Critical hits deal double damage; grenade damage cannot critically hit. The player begins with 2% critical chance, Luck adds 0.5% per point, and a Keen Godly weapon can add up to 16% at item level 40. A maximum-level Godly roll can reach roughly +42% firing speed, +42% rolled damage, +60% item-level damage, +43% execution damage, +42% kill XP, or 14% leech depending on its four selected affixes. Equipping a Godly variant also creates an icy-white first-person pulse without replacing the underlying weapon actor.

Look near a drop to see its quality, item level, gear score, and a row-by-row comparison of every stat against the current variant—including bonuses that would be lost. Drops within 80 map units can be inspected from either visible side without aiming at the actor's hidden origin; inspection out to 256 units requires facing the drop, and the card briefly persists when aim moves away. Both distances are configurable. Move within 128 map units and press Use (`E` by default) to equip it. The Arsenal stores only one variant for each weapon class: accepting a replacement immediately places the previous variant on the floor. Press `L` to inspect the persistent Arsenal with Up/Down. The weapon-loot options include a complete reset that clears collected variants and floor drops and restores normal drop settings. The underlying weapon actor is never replaced: TuinRPG applies the active variant's bonuses as an RPG layer for compatibility with custom weapons.

Press `Q` once to open the paused weapon wheel. Move the mouse toward an owned weapon, then press `Q` again, left-click or Enter to equip it; Escape or right-click cancels. Each segment displays the actual active weapon-replacement name and its combined ammunition. Ammo bars transition continuously from red when nearly empty, through yellow, to green when well supplied. Ammo-free melee and infinite-ammo weapons are identified separately.

## Minimap, finale bosses and John

John's partial refill restores 25% of every carried ammo type for 100 coins. The separate 10-coin cache restores only a small amount of one random carried ammo type.

Ordinary promoted bosses reach at least player level +1. A boss originating below Hell Knight base health calculates its health from a 200-HP minimum and reserves one affix slot for full ordinary Armor, reducing damage by 50% by default. Hell Knights and stronger candidates do not receive forced Armor; if they randomly roll it, their Boss Armor defaults to 25% reduction.

The optional minimap draws explored level geometry, player direction, exits, locked doors and kill/item/secret totals. Once a special monster has been seen, its last-known position remains marked with a rarity-colored circle. Legendary, Mythic and Boss threats receive stronger pulsing indicators, while weapon drops appear immediately as quality-colored diamonds and remain marked until collected or expired.

On maps containing at least eight monsters, reaching 85% kills promotes one eligible survivor into a finale **BOSS**, a sixth tier above Mythic. The classic Doom episode finales use their intended encounters instead: both Barons on E1M8, the Cyberdemon on E2M8 and the Spider Mastermind on E3M8 begin as Boss-tier enemies, with no unrelated extra promotion on those maps. These already-tough native bosses use gentler health and damage multipliers than ordinary promoted monsters. E1M8 divides its encounter budget across two Barons and gives each two offensive/mobility affixes; E2M8 and E3M8 receive three. The iconic encounters do not roll Armored or Regenerating, avoiding excessive effective-health combinations. E2M8's Cyberdemon and E3M8's Spider Mastermind are replaced only on those maps by identical TuinRPG finale subclasses, preventing their stock death frame from ending the episode automatically.

Once an iconic encounter is defeated, John remains available for shopping and conversation. Both **So... what now?** and **What comes next?** contain four story parts. Select either question repeatedly to advance its conversation; every part uses multiple lines and restarts the classic RPG letter by letter reveal. E1M8, E2M8, E3M8 and Doom II's MAP06, MAP11 and MAP20 have dedicated conversations. John also offers general four part post battle conversations after other finale Bosses. Choose the gold **Reach out and hold John Romero's hand (Go to next level)** entry when ready. This moves from E1M8 to E2M1, E2M8 to E3M1 or E3M8 to E4M1 while preserving health, inventory, weapons and Tuin RPG progression. E4M8 remains the true ending. Doom II continues from MAP06, MAP11 and MAP20 to MAP07, MAP12 and MAP21 only after John's conversation, retaining the original story intermission. John transitions never grant late-start levels, talent points or three catch-up weapons on the destination map. Other scripted bosses, dormant actors and monster-summoners are excluded. A promoted monster is fully healed with Boss-tier health, damage, XP and affixes, announced to the player, and permanently marked on the minimap. Defeating it guarantees a named Godly variant of an owned weapon. Godly weapons have four stronger affixes, an icy-white pulsing glow and a persistent special name. Native/custom BOSS actors instead have a separate 5% Godly chance.

Monsters can also drop physical Tuin coins. After the finale Boss dies, John appears nearby; face him and press Use (`E`) to open his shop. Arrow keys browse and Enter purchases health, ammo, armor, a backpack, or a 150-coin random variant of one of your currently owned weapons. The gamble always produces Uncommon or better and has a 20% total chance for Rare or better; Godly weapons remain Boss-exclusive. John also offers randomized conversation and gameplay tips. Coin frequency and John's shop can be adjusted or disabled in **Finale Boss Options**. For testing, `netevent tuin_test_john_shop` spawns John and grants 500 coins.

The `K` character screen is intentionally limited to progression, the Arsenal and total combat statistics; balance/configuration controls remain in the normal **Options > Tuin RPG Options** menu.

## Compatibility notes

The mod works automatically with custom actors that correctly identify as hostile monsters using GZDoom's standard monster/shootable flags. Actors that intentionally omit `ISMONSTER`, script all damage outside `DamageMobj`, or clear player inventory during a forced transition may require a future compatibility definition. v0.1 prioritizes stable single-player behavior; data ownership and stat-spending commands are already per-player for later co-op work.
