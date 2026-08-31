# Changelog

## 0.6.44

- Rebuilt Damage Dealer as the **Executioner**, preserving its +30% weapon damage, 25% lower maximum health, and 10% increased incoming damage while giving the class a complete active playstyle.
- Ordinary weapon damage now fills Judgment, requiring `500 + 50 × player level` damage. Press Class Ability at full charge to place **Death Sentence** on the monster under the crosshair for ten seconds.
- Death Sentence adds 25% damage against ordinary monsters and 10% against Boss-tier targets. The marked monster receives a red pulse/ring and a clearly labeled red target panel.
- Killing the marked monster triggers **Final Verdict**, damaging nearby visible hostiles for 18% of the victim's scaled maximum health within 160 units. It uses the integrated quick grenade's explosion effect, sound, and quake, with red floating damage numbers.
- Executioner Class Training now builds Judgment 10%, 20%, and 30% faster instead of adding passive damage.
- Replaced the old 2.5x-critical Ultimate with **No Appeals**: Death Sentence lasts twelve seconds, deals 35% bonus damage to ordinary monsters and 15% to bosses, expands Final Verdict to 224 units at 25% victim health, and refunds 25% Judgment after a successful execution.
- Added `netevent tuin_test_death_sentence` to select Executioner and fill Judgment for testing.

## 0.6.43

- Increased direct-target rocket burn from 16% to 32% of final impact damage.
- Increased surrounding rocket-explosion burn from 8% to 16% of the damage received by each nearby monster.
- Doubled the Plasma Rifle's arc range from 96 to 192 map units while retaining its 20% secondary-damage value and line-of-sight requirement.

## 0.6.42

- Rocket impacts now ignite damaged monsters for four seconds. The directly struck monster receives a burn worth 16% of its final impact damage, while other monsters caught by the explosion receive an 8% burn based on the damage dealt to each of them.
- Plasma Rifle shots now arc 20% of their final impact damage to other visible monsters within 96 map units of the struck target.
- Elemental follow-up damage cannot critically hit or recursively trigger more elemental damage. Existing Armor and Warding reductions still apply.
- Added distinct floating-number colors: rocket burn pulses are orange and plasma arc damage is plasma blue.

## 0.6.41

- Added a once-per-map emergency ammo rescue for each stock ammo family. If the entire active team reaches zero carried bullets, shells, rockets, or cells while at least four monsters remain, the Hell Director can silently upgrade one matching untouched pickup to its large-box version.
- Emergency rescues work independently of the normal 25%, 50%, and 75% kill checkpoints, including after all three checkpoints have passed.
- The rescue never grants ammunition directly, never changes visible, collected, or dropped pickups, and retries later if the only matching pickup is currently visible. A successful rescue consumes that ammo family's single allowance for the map.
- Empty Miniguns now dry-fire, display `OUT OF BULLETS`, and trigger the normal automatic weapon switch instead of silently doing nothing.

## 0.6.40

- Added the Riot Shotgun as a distinct rare shotgun conversion. It fires five pellets instead of seven with wider spread, consumes one shell, has no magazine reload, and uses its own weapon artwork and randomized firing sound.
- Added the Minigun as a distinct rare chaingun conversion. It uses an eight-tic spin-up, fires one three-damage round every two tics, consumes bullets twice as quickly as the regular chaingun, and reloads its internal 100-round belt with dedicated artwork and sounds.
- Standard Shotgun and Chaingun variant drops each have an independent 8% default chance to become their special counterpart. Both chances are configurable under Weapon Loot, and both weapons have direct testing commands.
- Added attribution for the adapted Lippeth Generic Weapons resources.
- Restored the supplied weapons' deliberate rhythm after play testing: the Riot Shotgun requires a fresh trigger pull and plays its complete pump sequence, while the Minigun spins up before alternating its firing frames and winds down or reloads afterward.
- Restored the Riot Shotgun's missing pump frames and exact interpolated recoil/pump offsets so the weapon remains anchored on screen throughout its animation.
- Slowed the Riot Shotgun's complete firing cycle from 23 to 28 tics, preserving the approved recoil and pump animation while adding roughly 20% more settled recovery time.

## 0.6.39

- Reduced the world-space knuckles weapon-drop sprite by 30% without changing its first-person size, pickup behavior, or glow.

## 0.6.38

- Added a silent Hell Director ammo safety pass at 25%, 50%, and 75% kills. When the team's weakest carried stock-ammo reserve is running low, one remaining small pickup of that family can become its large-box equivalent.
- Supported upgrades are Clip to Bullet Box, Shells to Shell Box, Rocket to Rocket Box, and Cell to Cell Pack. Grenades and unknown custom ammo are deliberately excluded.
- The reserve threshold now considers how many monsters remain: 40% with at least 40 enemies, 35% with 20-39, 25% with 10-19, and 15% with 4-9. No rescue occurs with fewer than four enemies.
- The Director adds no ammo directly to players and performs at most one ammo upgrade per checkpoint. It only changes untouched, map-placed pickups that are currently out of sight of every player; collected and player-dropped ammunition is never considered.

## 0.6.37

- Added the Healer's Field Supply class ability: press V to throw one random Health Bonus, Stimpack, or Medikit forward, with a 2% chance to produce a Soulsphere.
- Field Supply has a 20-second cooldown, reports its remaining time when pressed early, and announces when it is ready again.
- Added a green-and-blue supply-toss effect so the thrown healing item is easy to spot.

## 0.6.36

- Increased the Tank's ammunition pickup bonus from 50% to 100%, matching the class's 50% weapon-damage penalty while preserving ammo management.

## 0.6.35

- Replaced the cramped four-column class comparison with a two-pane RPG layout: a compact selectable class list on the left and a spacious selected-class card on the right.
- Split every class description into clearly aligned Role, Core Bonuses, Tradeoff, Class Ability, Class Training, and Class Ultimate rows.
- Added the complete Doom Guy Blood Punch training and Ultimate values directly to the selection card while keeping all descriptions clear of the Specialty/HUD area.

## 0.6.34

- Refocused Doom Guy Class Training on Blood Punch: its three ranks now build charge 10%, 20%, and 30% faster instead of changing passive regeneration timing.
- Renamed Class Capstone to **Class Ultimate** throughout the interface and notifications.
- Reworked Doom Guy's level-20 Ultimate to build Blood Punch 45% faster and heal 30% of damage dealt up to 110 health, replacing the unrelated heal-per-kill bonus.
- Rebuilt the permanent class-selection comparison into aligned Class, Role, Core Traits, and Specialty columns with shorter, clearer descriptions and a narrower framed panel.

## 0.6.33

- Added a smooth 16-tic fist raise after the equipped weapon finishes lowering; the Blood Punch stance no longer pops abruptly onto the screen.
- Reset the ProjectSIDE fist psprite to the centered native weapon origin and animate it from `WEAPONBOTTOM` to `WEAPONTOP`, preventing the held and attack frames from inheriting an out-of-bounds lowered position.
- Queued an early `V` release until the fists finish raising, preserving the complete switch and punch animations.

## 0.6.32

- Fixed the E2M1 runtime abort caused by UZDoom rejecting key-binding changes outside menu code.
- Replaced binding mutation with a safe legacy-input translator: an old one-shot `V` configuration now sends proper press and release events without modifying the player's controls.
- Retained the corrected native weapon-layer positioning for the held ProjectSIDE fists.

## 0.6.31

- Corrected Blood Punch fist placement by running the ProjectSIDE animation on the native weapon psprite, with its normal centered weapon-space origin and bobbing.
- Migrated `V` to the press/release Class Ability binding automatically so existing one-shot bindings no longer release Blood Punch immediately.
- Preserved the held stance indefinitely until `V` is released, then restored the previous weapon through its normal raise animation.

## 0.6.30

- Reworked Blood Punch into a held first-person stance: hold Class Ability to lower the current weapon and ready the ProjectSIDE fists, then release to strike.
- Restored ProjectSIDE's complete normal-speed punch sequence instead of compressing it into eight tics.
- Moved cone damage, healing, crimson effects and the standard `*fist` impact sound onto the animation's contact frame.
- Restored the previous weapon through its normal raise state after the punch finishes.
- Changed Class Ability to a press/release key command while retaining the old one-shot command as a compatibility fallback for existing binds.

## 0.6.29

- Integrated the complete ProjectSIDE weapons/effects compatibility edition into the main TuinRPG PK3, including its animated weapon replacements, effects, sounds, casings, projectiles and credits.
- Integrated quick grenades as a standard feature bound to `G`, with two starting grenades, pickups/drops, reserve HUD, first-person throw animation and multi-band explosion.
- Changed Doom Guy's Blood Punch to use ProjectSIDE's `PKFS` melee frames in a fast dedicated first-person overlay while TuinRPG retains control of cone damage and healing.
- Merged ProjectSIDE's event handler, controls, CVARs and root definitions so the separate compatibility PK3 is no longer required and must not be loaded alongside TuinRPG.

## 0.6.20

- Gave Cyberdemons and Spider Masterminds 75% resistance to direct BFG projectiles, tracer/splash damage, and recognizable replacement BFG weapons.
- Applied the resistance to both original weapon damage and its derived TuinRPG bonuses while leaving every other weapon and monster unchanged.
- Added class-name, damage-type, projectile-name, and visible weapon-tag recognition for compatibility with BFG replacement mods.
- Displayed `BFG RESIST 75%` in the current-target information for both resistant species.

## 0.6.19

- Added half-second diminishing-overflow windows for TuinRPG bonus damage, preventing critical BFG tracers, shotgun pellets, and rapid bursts from bypassing boss protection as separate hits.
- Left all original weapon damage untouched; only damage added by TuinRPG multipliers is compressed.
- Rare-through-Mythic enemies now use a 25%-health bonus threshold with 25% overflow, normal bosses use 15% with 20% overflow, and iconic finale bosses use 8% with 15% overflow.

## 0.6.18

- Reworked Rogue Bleeding to repeat 100% of the triggering critical hit's damage across eight one-second ticks, strongly rewarding heavy Ambush weapons without disproportionately benefiting rapid-fire weapons.
- Capped each complete Bleeding effect at 24% of the monster's RPG-scaled maximum health and preserved exact damage across integer-sized ticks.
- Retained the no-refresh rule and 12-second post-Bleed resistance period for Rogues and Tuin's Lead Spitter.

## 0.6.17

- Prevented rapid-fire critical hits from refreshing or stacking Rogue Bleeding while it is already active.
- Monsters now gain 12 seconds of Bleed Resistance after the full eight-second Bleeding effect ends; critical hits still deal their normal critical damage during both states.
- Applied the same Bleeding limits to Tuin's Lead Spitter so its fire rate cannot maintain permanent percentage-health damage.

## 0.6.16

- Replaced Shadow Veil's time cooldown with a damage-powered Shadow Charge meter; waiting no longer restores this powerful ability.
- Full charge requires `400 + 60 × player level` ordinary weapon damage, allowing sustained boss combat to earn another Veil without making low-level fodder an instant refill.
- Ambush and Bleeding damage do not generate Shadow Charge, preventing self-refilling Ambush loops.
- Rogue Class Training now increases charge from damage by 15% per rank while retaining its critical-chance and Veil-duration bonuses.
- Updated the Rogue HUD and ability feedback to show charge percentage and announce when Shadow Veil becomes ready.

## 0.6.15

- Replaced Rogue's mandatory stand-still activation with a configurable active Shadow Veil ability, bound to `V` by default.
- Shadow Veil now lasts six seconds, permits movement and use actions, and ends on attack, damage, expiry, or manual cancellation.
- Criticals and kills reduce Shadow Veil's cooldown; Ambush kills refund more, while standing still optionally doubles passive recovery.
- Rogue Class Training now extends Veil duration and reduces its base cooldown in addition to granting critical chance.
- Raised Bleeding from 2% to 4% of scaled maximum health per second and made forced Ambush criticals trigger all critical-hit effects correctly.

## 0.6.14

- Rebalanced support affixes: Warding now protects allies only; Healer retains full ally healing but self-heals at 25%, and damage suppresses self-healing for two seconds.
- Rogue Bleeding now halves all healing received by affected monsters, including Healer, Regenerating, and Vampiric recovery.
- Added a normalized visible floor pickup for fists and brass knuckles whose weapon mods supply unusable first-person sprite offsets.
- Added the secret level-75 Tuin's Lead Spitter chaingun with 75% rolls in every weapon stat, 75% weapon critical chance, bleeding critical hits, and a unique-quality glow.

## 0.6.13

- Excluded grenade projectiles and grenade damage types from critical-hit rolls, including Rogue Bleeding triggers.

## 0.6.12

- Clarified in the character menu that every Luck point adds 0.5% critical chance as well as its bonus-XP proc chance.
- Gave Rogues +5% innate critical chance, with another +2% per Class Training rank.
- Rogue critical hits now inflict an eight-second bleed that removes 2% of the monster's maximum health per second; repeated criticals refresh rather than stack it.
- Added a red `BLEEDING` label beneath affected monsters' overhead health bars, included the status in the current-target panel, and rendered bleed ticks as separate red floating damage numbers.

## 0.6.11

- Prevented Lost Souls and other excluded survivors from stranding level-boss encounters by reserving and promoting the final eligible monster.
- Added a full-clear failsafe that allows John to arrive on unusual maps where no valid boss candidate exists at all.

## 0.6.10

- Rebuilt class selection as a true two-column table with class names on the left and concise role, strength, and tradeoff explanations on the right.
- Added a dedicated opaque black panel, thick black outer border, gold inner frame, and column divider.

## 0.6.9

- Centered all selectable perk category and purchase entries instead of relying on the option menu's right-aligned label column.
- Replaced fragile space-padded pseudo-columns with clean `NAME: EFFECT` lines that remain aligned at different resolutions and UI scales.

## 0.6.8

- Split the perk interface into separate General Perks, Class Training, and Class Capstone pages behind a simple category selector.
- Each page now shows only its own requirements, effects, and purchase action.
- Replaced the oversized multi-section background with one compact framed panel per page.

## 0.6.7

- Reorganized the perk screen into three numbered steps: universal perks, class training, and the level-20 class capstone.
- Added concise cost, rank-limit, requirement, and per-class effect explanations.
- Resized the perk background so it wraps the menu content instead of leaving a large empty lower panel.

## 0.6.6

- Raised John's partial 25%-per-type ammo refill price from 15 to 100 coins.
- Reworked the perk menu into a shorter, aligned layout with separate framed General and Class perk panels.
- At player level 15 and above, successful Hell Director upgrades prioritize living Hell Knight-or-stronger candidates, falling back to lighter enemies when no heavy candidate remains.

## 0.6.5

- Normal-level promoted bosses now reach at least player level +1.
- Promoted bosses originating below Hell Knight base health use a 200-HP health-calculation floor and reserve one affix slot for full ordinary Armor, reducing damage by 50% by default.
- Bosses originating from Hell Knights or stronger actors do not receive forced Armor, while iconic episode bosses retain their separate hand-balanced rules.

## 0.6.4

- Replaced John's dialogue portrait with the new square framed artwork and corrected its display aspect ratio.
- Weapon item levels now grant +2% inherent damage per level after level 1, capped at +60%, and this contribution appears in comparisons, stats and gear score.
- John's full refill is replaced by a 10-coin cache granting a small amount of one random carried ammo type.
- Rare, Elite, Legendary and Mythic enemies below Hell Knight base health always receive Armor; Normal and Uncommon fodder retain their usual traits. Additional traits remain random and respect the difficulty affix cap.
- Rare and higher monster levels roll progressively closer to player level.
- Director Assassin Imps immediately wake and hunt their selected player.

## 0.6.3

- John no longer speaks as though an end-level boss is dead while it is still alive.
- Ordinary levels now offer one concise `SO... WHAT NOW?` story option with live boss status.
- Four-part `SO... WHAT NOW?` and `WHAT COMES NEXT?` stories remain exclusive to completed finale and pre-intermission encounters.

## 0.6.2

- Replaced only the native E2M8 Cyberdemon and E3M8 Spider Mastermind with visually and mechanically identical TuinRPG finale subclasses whose death states omit `A_BossDeath`. Their deaths can no longer trigger Doom's immediate episode ending before John appears.
- Reworked finale travel into an explicit John conversation. On E1M8-E3M8, players may keep shopping, ask what happened, ask what comes next, or select the gold hand-holding option to continue while preserving progression.
- Expanded both John story questions into four part RPG conversations. Each press advances to another multi line passage and restarts the letter by letter reveal. E1M8, E2M8, E3M8, MAP06, MAP11 and MAP20 have dedicated stories, while other finale Bosses receive general post battle conversations.
- Added the same contextual John conversation and explicit transition to Doom II's MAP06, MAP11 and MAP20 story breaks. Doom II transitions retain their intermission text, and every John transition suppresses late-start catch-up rewards on the destination map.
- Added the adaptive Hell Director. At 25%, 50% and 75% map completion it measures party damage taken during that stage and, when the run is going smoothly, upgrades one living monster to Elite, Legendary or Mythic.
- Added a configurable rare Assassin Imp event during successful high-tier Director checks. It appears near an older player trail position as a fast, translucent Mythic ambusher, while invalid or cramped spawn positions safely fall back to upgrading an existing monster.
- Reworked progressive monster levels into hybrid scaling: map progression remains primary, but under-levelled enemies partially catch up to the highest active player based on difficulty. Elite, Legendary and Mythic enemies receive additional level pressure and ordinary monsters retain occasional challenge surges.
- Strengthened all four visible difficulty profiles while preserving custom slider values and migrating the prior stock profile values.
- Replaced John's incompatible missing/variant weapon purchases with a 150-coin owned-weapon gamble: 80% Uncommon, 12% Rare, 5% Elite, 2% Legendary and 1% Mythic. Godly remains Boss-exclusive.
- Removed the probability advertisement beneath John's gamble entry to keep the shop interface clean.
- Expanded special-monster naming from small generic lists to 32 prefixes, 24 titles and 20 legendary names, plus family-specific Doom names for Imps, former humans, Demons, floating horrors, Hell nobles, Revenants, arachnids, Mancubi and Arch-viles.
- Fixed internal coin grants awarding one unintended extra coin when creating a player's first coin stack.

- Made John completely non-solid so players, monsters and projectiles can pass through him without losing shop interaction.
- Prevented Doom's native E1M8-E3M8 boss-death action from ending the episode behind TuinRPG's back; John now remains responsible for the inventory-preserving transition, including when loading an already-promoted finale save.
- John's E1M8-E3M8 episode bridges no longer trigger late-start catch-up rewards on the destination map; player level, stat/perk points, arsenal and ammo now carry across unchanged.
- Fixed Rogue ambushes expiring before slow fist and custom melee animations reached their damage frame. The ambush is now consumed by the first damaging hit, while same-tic shotgun pellets retain the multiplier.
- Reduced Shadow Veil's cooldown to 15 seconds and expanded weapon-mod melee detection for fists, brass knuckles, unarmed weapons, and correctly flagged melee weapons. Rogue fist ambushes now deal x20 damage (x30 with the capstone), with separate finale-boss safeguards.
- Changed Shadow Veil to remain active indefinitely until broken and strengthened invisibility by continuously clearing monster targets, attack states, remembered enemies, and sound targets while affected monsters wander.
- Added Rogue as a fifth permanent class with 20% lower maximum health, stationary-triggered Shadow Veil, true monster untargetability, translucent presentation, minimap-adjacent status display, ranged and melee ambushes, and finale-boss safeguards.
- Added the complete every-five-level perk system: five three-rank general perks, three ranks of class training, permanent save data, purchase validation, character-sheet ranks, and level-20 class capstones for all five classes.
- Added world-space floating damage numbers with rising curled motion, pellet-hit merging, critical-hit styling, and HUD toggles for visibility and size.
- Rebalanced Damage Dealer to +30% outgoing damage, -25% maximum health, and +10% incoming damage.

- Added permanent first-perk classes: Tank, Healer, Damage Dealer, and Doom Guy, including class damage/protection modifiers, class-based ammunition gains, co-op healing, regeneration, maximum-health adjustment, character-screen totals, and save persistence.

- Added a Q-toggle weapon wheel with mouse selection, paused gameplay, current-weapon highlighting, mod-replacement weapon names, and red-to-yellow-to-green ammo bars. Press Q once to open; Q again, left-click or Enter equips; Escape or right-click cancels.

- Enlarged and darkened TuinRPG text backings, raised minimum HUD text sizes, and made the minimap statistics, player status and current-target information beneath the minimap substantially easier to read.
- Added critical hits: 2% base chance, +0.5% per Luck, a Keen weapon affix, double-damage feedback, weapon comparisons, and a 50% total cap.
- Expanded the character screen with effective health, damage, firing speed, critical chance, damage reduction, bonus-XP chance, leech, execution and kill-XP totals; removed the Tuin RPG balance-options shortcut from this progression screen.
- Added Poisonous, Healer and Warding monster affixes with configurable duration, strength and support radius; Mythic and ordinary finale-Boss affix counts can now grow higher, while iconic encounters retain their curated limits.
- Added a configurable 1% direct Godly chance for native/custom actors using the engine BOSS flag; finale Bosses retain their separate 5% default chance.
- Added an icy-white attached pulse while a Godly weapon variant is actively equipped, without replacing or editing custom weapon actors.
- Completed the iconic-finale balance pass: E1M8 Boss Barons now roll two affixes, E2M8/E3M8 roll three, all three encounters exclude Armored and Regenerating, and their native high-damage attacks use gentler custom damage multipliers. Ordinary promoted Bosses are unchanged.
- Reduced the iconic finale health multipliers so E1M8's two Boss Barons share a sensible encounter budget and the Cyberdemon and Spider Mastermind do not multiply their already-large native health excessively.
- Replaced the normal E1M8-E3M8 episode endings with an inventory-preserving John transition: defeat the full iconic encounter, approach John and press Use after “Hold my hand, my son” to continue into the next episode; E4M8 remains unchanged.
- Made Doom's iconic episode finales use their intended monsters as Tuin Bosses: both E1M8 Barons, the E2M8 Cyberdemon and the E3M8 Spider Mastermind; these maps no longer promote an unrelated survivor.

## 0.7.2

- Added optional Doom late-start/warp catch-up: fresh starts on later maps and non-sequential warps raise under-levelled players to the map tier, grant the missing stat/skill points, and spawn three distinct Rare-or-better weapon choices resolved through active weapon replacements.
- Fixed catch-up weapon pickups storing only their RPG variant without granting the underlying weapon, and removed Doom II's Super Shotgun from Doom 1/Chex episode-style reward pools.
- Raised the default late-start catch-up target three levels above the map tier, made that bonus configurable, and added a 25% carried-ammo refill when accepting each new catch-up weapon.
- Fixed catch-up rewards repeating on the next sequential map by tracking transitions in the persistent handler with a once-per-map award guard.
- Added the Boss-exclusive Godly weapon tier: a configurable 5% default Boss-reward chance, stronger four-affix rolls, an icy-white pulse, and twelve persistent special weapon names.
- Added compact world-space health displays above visible monsters, including live HP depletion, level/name, rarity-colored bars and abbreviated affix buffs; distance, size and maximum simultaneous bars are configurable.
- Expanded health-bar colors so Uncommon, Rare and Elite are immediately distinguishable from Normal in both overhead and targeted displays.
- Improved overhead-bar readability and motion: actor positions are now interpolated every rendered frame, the core label/bar/HP elements are about 30% larger with stronger contrast, and affix rows hide at long range to reduce clutter.
- Replaced the competing health-bar toggles with one style selector: Classic targeted, Overhead, Both, or Off; Overhead is the new default.
- Added eased, frame-interpolated HP depletion and healing to both classic and overhead bars while keeping their numeric HP readouts exact.
- Halved weapon-card visibility ranges to keep the comparison panel out of combat: maximum inspection is now 256 units and automatic nearby inspection is 80, with migration of the previous 512/160 defaults.
- Replaced Doom's ESC-menu title graphic with the supplied transparent TuinRPG portrait-and-logo artwork.
- Recentered the ESC-menu artwork above the choices and reduced it by roughly 25% after in-game layout testing.
- Removed the stray blue triangle beneath the Doom logo while preserving the original artwork and transparent background.
- Corrected John's premature past-tense Boss greeting now that he can arrive before the finale Boss dies.
- Enlarged John's dialogue text and expanded its panel beside his portrait.
- Added an "Ask John about Doom and classic games" option with 100 randomized facts covering Doom, Quake, Wolfenstein 3D, and Daikatana.
- Rephrased all 100 classic-game facts as natural sentences with game titles integrated into the wording instead of label-style prefixes.
- John now arrives when only three count-kill monsters remain after the finale Boss has emerged, with Boss death retained as a fallback.
- Reworked John's placement around a living player with collision, headroom and sight validation; removed the unsafe corpse-position fallback.
- Added an always-visible cyan John objective marker to the minimap, including an edge indicator when he is off-map range.
- Lowered John's portrait into a dialogue row, placed his speech to its right, and kept all shop purchases above the portrait.
- Moved player level, XP, points and coins beneath the minimap; moved map completion statistics outside the map and enlarged both displays.
- Fixed John's missing-weapon purchase so it grants the active mod's replacement weapon instead of the underlying Doom weapon.
- Made `N` the default minimap key and replaced the noisy CVAR toggle with a silent event-based toggle.
- Set coin drops to a 25% base chance, retained the +3% rarity bonus, migrated earlier test defaults, and rebalanced shop prices.
- Renamed the ambiguous ammo pack to a partial refill that clearly states it adds 25% of each carried ammo type's capacity.
- Raised coin drops above the floor, moved John farther from the finale Boss reward, and suppressed weapon comparison cards while menus are open.
- Moved John's portrait to the left of a more centrally positioned shop interface.

## 0.7.1

- Reduced the coin sprite to 25% of its original displayed size and John to 75%.
- Changed normal coin drops to a 10% base chance with a modest +3% per monster-rarity tier; finale Bosses still guarantee coins.
- Rebalanced John's prices for the scarcer coin economy.
- Made Use interaction with John much more forgiving and fixed the interface-event filter that prevented his shop from opening.

## 0.7.0

- Fixed finale Boss rewards failing when environmental damage obscured the player killer; a promoted Boss now remembers an eligible reward owner.
- Weapon and coin rewards from flying monsters are placed on the floor beneath the corpse instead of remaining in mid-air.
- Added physical Tuin coin drops with a new project-original gold coin sprite and persistent HUD balance.
- Added John, a friendly merchant who appears after the finale Boss dies; press Use near him for a keyboard/controller shop.
- John's shop sells health, partial/full ammo refills, armor, a backpack, missing standard weapons and Rare owned-weapon variants.
- Added John's portrait dialogue, randomized conversation, Tuin RPG tips, configurable shop/coin settings and a John testing command.

## 0.6.0

- Added a once-per-map finale BOSS rarity above Mythic, promoted from an eligible survivor near the configured kill-completion threshold.
- Finale bosses gain boss-tier health, damage, XP, affixes, a crimson pulse, a global announcement and a permanent minimap objective marker.
- Finale bosses guarantee one weapon drop from Rare through Mythic; a testing command is available in the finale-boss options.
- Weapon drops now appear as quality-colored minimap diamonds immediately and remain until collected or expired.

## 0.5.0

- Integrated an optional rotating minimap with explored geometry, exits, locked doors, player direction and level statistics.
- Special monsters appear as rarity-colored circles after first sight and retain their last-known positions; Legendary/Mythic threats also get edge indicators.
- Added discovered weapon-drop diamonds, discovery pulses, positioning, size, range and visibility controls.
- Increased the default minimap size to 320 pixels, with a one-time migration from the earlier 240-pixel test default.

## 0.4.7

- Made the flashlight follow vertical aim and widened its cone, allowing it to illuminate ceilings without turning the whole room into a flat light bubble.

## 0.4.6

- Added a persistent forward flashlight on `F`, with configurable range and brightness.

## 0.4.5

- Added the `netevent tuin_give_levels <amount>` testing cheat, including normal stat- and skill-point rewards.

## 0.4.4

- Doubled the default base weapon-drop chance from 0.75% to 1.5%, including migration of the previous default.
- Added restrained cyan glows to Rare monsters and slightly stronger orange glows to Elite monsters.
- Added independent Rare and Elite glow-radius controls.

## 0.4.3

- Tightened automatic nearby weapon inspection from 320 to 160 map units and capped default long-range inspection at 512 units.
- Added separate maximum and automatic inspection-distance sliders.

## 0.4.2

- Made every nearby weapon drop inspectable from either side without requiring aim at the actor origin.
- Expanded comparisons to show drop/current/difference values for all five stats, including bonuses that would be lost.
- Added a weapon-loot reset command that clears all variants and floor drops and restores normal loot settings.

## 0.4.1

- Changed the Arsenal to one active variant per weapon class; accepting a replacement immediately drops the old variant into the world.
- Greatly widened close-range drop inspection angles and added a short target grace period for easier diagonal viewing.
- Rebuilt the comparison card with dynamic height, capped text scaling, clearer scores, and explicit swap messaging.
- Replaced overlapping engine pickup/equip messages with one controlled, non-stacking loot notification.

## 0.4.0

- Added rare weapon-variant drops chosen only from weapons already owned by the killing player.
- Added Uncommon, Rare, Elite, Legendary, and Mythic item qualities with colored world sprites and quality-scaled glows.
- Added item levels derived from monster level and quality/level-scaled Haste, Power, Leech, Execution, and Prosperity affixes.
- Added crosshair comparison panels with gear-score upgrade/down-grade indicators and Use-key pickup within 128 map units.
- Added a persistent Arsenal menu on `L`, including per-weapon variant selection, equipping, and discarding.
- Added weapon loot chance/lifetime settings and a Mythic-current-weapon testing drop.

## 0.3.0

- Added telegraphed, archetype-aware signature attacks for Legendary and Mythic monsters.
- Added tailored attacks for Doom hitscanners, Imps, Hell nobles, Cacodemons, Revenants, Mancubi, Arachnotrons, and Demons/Spectres.
- Added conservative ranged-repeat and melee-charge fallbacks for custom monsters; bosses and summoners are excluded.
- Added signature-attack enable, cooldown, and warning-time options.

## 0.2.4

- Added a warm gold glow to Legendary monsters and a stronger pulsing violet glow to Mythic monsters.
- Added glow enable and radius controls; rarity rerolls now immediately replace the old visual effect.
- Matched Legendary and Mythic HUD text, exact HP, and health-bar fills to their gold and violet rarity colors.

## 0.2.3

- Normalized the default rarity curve to 15% Uncommon, 7% Rare, 2.5% Elite, 1% Legendary, and 0.5% Mythic.
- Added one-time migration for the previous Legendary and Mythic defaults.

## 0.2.2

- Expanded every rarity chance slider to the full 0-100% range and clarified percentage values.
- Added an all-Mythic testing preset, rarity-default reset button, and current-map living-monster reroll.
- Increased the default Mythic chance from 0.05% to 0.5%.

## 0.2.1

- Reworked Swift around guarded `A_FastChase`, faster player acquisition, zero reaction delay, and longer target retention instead of a flat speed multiplier.
- Increased Armored damage reduction from 20% to 50%.
- Increased the Berserker low-health damage multiplier from 1.5x to 2x.

## 0.2.0

- Added six configurable monster rarity tiers with health, damage, and XP scaling.
- Added generated rare and legendary names plus tier-colored HUD presentation.
- Added modular Swift, Armored, Regenerating, Berserker, Explosive, and Vampiric affixes.
- Added rarity probability, maximum-affix, affix-effect, and HUD visibility options.
- Preserved runtime actor inspection with no monster or weapon replacements.

## 0.1.1

- Enlarged the RPG HUD/health bar and added a configurable HUD size slider.
- Added Agility firing-speed progression and Endurance damage reduction.

## 0.1.0

- Initial playable MVP with generic monster discovery, levels, health/damage scaling, targeted HUD, XP and player levels, XP notifications, stat points, Vitality, Strength, Luck, persistence, character menu, key binding, and configuration menu.
