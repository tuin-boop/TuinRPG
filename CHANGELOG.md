# Changelog

## 0.7.01

- Fixed silent Quad Shotgun secondary fire by registering all three Project Brutality half-blast samples as explicit sound aliases before random selection.

## 0.7.00
- Replaced the Doom Guy quad shotgun audio with Project Brutality's quieter dedicated set: its four-barrel blast, randomized two-barrel blasts, and matching pickup/open/load/close sounds.
- Tightened level-15 Hell Director promotion priority to Baron-or-stronger first, then Hell Knight-or-stronger, with Cacodemons and lower monsters used only when the complete preferred pool is empty.

- Rebuilt the Doom Guy Quad Shotgun around a persistent four-shell chamber. Secondary fire now consumes one two-barrel pair at a time, reloads after the second shot, and continues firing across the reload while the right button remains held.
- Shortened the Quad Shotgun's firing/recovery animations by approximately 25% and its break-open reload by approximately 40%.
- Replaced the Quad Shotgun's plain wall puff with TuinRPG's `XtremeSGPuff`, matching the impact particles and decals used by the other integrated shotguns.

## 0.6.99

- Changed the level-15 Hell Director preference from Cacodemon strength (400 base HP) to Hell Knight strength (500 base HP). It scans the complete living roster and promotes Cacodemons, Demons, Imps or other lighter monsters only when no eligible Hell Knight-or-stronger candidate exists.
- Increased the combat progress required to earn both Heavy abilities by 30%. Overdrive now needs `1040 + 65 × player level`, while Radio Support needs 4,095 actual monster damage before Class Training reductions.
- Heavy ability strength and duration are unchanged.
- Added Complex Doom v27f's Quad Shotgun as a Doom Guy-exclusive slot-3 class weapon, automatically granted to new and existing Doom Guy characters with eight shells.
- Quad primary fire spends four shells for 52 pellets and uses Complex Doom's ordinary double-barrel blast sound in place of the louder quad-fire sound. Secondary fire retains the source weapon's two-shell, 20-pellet behavior and sound.
- Imported the original Quad Shotgun animations, reload sounds, pickup sound and `QSGP` world sprite. Once owned, it participates in RPG weapon-variant drops; non-Doom Guy players receive a class-only warning in multiplayer.

## 0.6.98

- Removed the Heavy's permanent 50% weapon-damage penalty. Ordinary Heavy attacks now deal full damage, while Overdrive still raises weapon damage by 25% and firing speed by 150%.
- Softened the Heavy's movement penalty from 30% to 20%.
- Removed the obsolete 100% Heavy ammunition-pickup compensation. Triple bullet capacity and the starting Minigun remain unchanged.
- Corrected the Heavy character screen, live damage statistic, Overdrive HUD and guides to match the new balance.

## 0.6.97

- Increased Heavy support-marine ground speed from 3 to 6 and added a proactive seven-tic scan for the nearest visible hostile within 1,536 units. New targets receive an immediate reaction and the marines use missile attacks more readily.
- Added FriendJohn-style forward recoil while closing on a distant enemy, making the squad push into combat instead of merely following its Heavy quickly.
- Reduced Heavy base maximum health from 300 to 175. Strength still adds 5 maximum health per point and Vitality/perk health continue stacking normally, so 175 is the class base rather than an absolute hard cap.

## 0.6.96

- Reworked Heavy support-marine movement to follow the supplied FriendJohn behavior: marines settle near their owner, use smooth lunging and strafing impulses during combat, slide along walls, handle taller steps/drop-offs, and teleport back with fog if badly separated or unable to see their Heavy. FriendJohn's vertical hops were deliberately removed because standard marine sprites made them look bouncy rather than floaty.
- Restricted support-marine translations to the four clean Doom player-color ranges—gray, brown, red and blue—removing the experimental gold/purple rolls that could produce an odd palette.
- Replaced Radio Support's passive time countdown with a damage-powered recharge. Rank 0 requires 3,150 actual monster damage after a call; Heavy Class Training reduces that requirement by 10% per rank. Waiting no longer restores the radio.
- Changed the Heavy HUD and cooldown message to show the exact remaining damage instead of seconds.
- Slowed the handheld radio to the original JohnnyDoom sequence: the complete call now lasts about 5.6 seconds, with voice, static, confirmation, reinforcement arrival and hang-up synchronized to their original frame timings.

## 0.6.95

- Renamed Tank to **Heavy** and rebalanced the class to 25% innate damage resistance, 30% slower movement, 300 base health, half weapon damage, triple bullet capacity, and a starting Minigun.
- Heavy now gains an additional 5 maximum health for every Strength point, on top of Strength's normal 2% outgoing-damage bonus.
- Added **Radio Support** on `B`: a full handheld-radio animation and call sequence summons two or three strong, invulnerable friendly marines for 30 seconds. Each marine uses a randomly colored player model and randomly receives a Shotgun, Super Shotgun, Chaingun, Rocket Launcher, or Plasma Rifle.
- Radio Support has a 90-second per-player cooldown. Heavy Class Training retains its 3% resistance per rank and now also shortens this cooldown by 10% per rank.
- Added a second Heavy HUD line for Radio Support state/cooldown and the `netevent tuin_test_heavy_radio` test command.
- Imported the supplied JohnnyDoom radio sprites and sounds; the support AI uses UZDoom's native Scripted Marine implementation for cleaner multiplayer ownership and compatibility.

## 0.6.94

- Venom Bow defense-shattering now applies to every Rare-or-higher upgraded monster, as well as native and iconic bosses, instead of requiring an RPG boss.
- Renamed the feedback to `DEFENSES SHATTERED` so it also reads naturally when Armored, Regenerating or Healer is removed from an elite.

## 0.6.93

- Venom Bow bolts now deal additional damage equal to 10% of the target's scaled maximum health. Iconic episode-end bosses instead take 5%; this defining health strike is not reduced by the generic RPG burst limiter.
- Direct bow hits permanently strip Armored, Regenerating and Healer affixes from RPG bosses, native bosses and iconic finale bosses, with a one-time `BOSS DEFENSES SHATTERED` notification when applicable.
- The bow keeps its one-shot magazine, rare two-bolt pickups, stacking venom, full reload and triple Shadow Veil charge from direct damage.

## 0.6.92

- Recast the Rogue Venom Bow as a scarce high-health hunter: it now has a one-shot magazine, restores the full reload after every bolt, and no longer fires automatically while attack is held.
- Raised direct bolt damage from 45 to 70 and added maximum-health damage: 4% up to 300 against ordinary enemies, 2% up to 200 against RPG bosses, and 1% up to 120 against iconic finale bosses. Normal RPG bonus-damage safeguards still apply.
- Bow hits now provide triple Shadow Veil charge from their direct damage; poison damage itself still does not generate charge.
- Venom-bolt bundles now contain two bolts instead of six, maximum reserves were halved, starting bow ammo was reduced from 12 to 6, and kill-drop odds now range from 2% to 10% based on monster rarity.

## 0.6.91

- The Rogue Venom Bow now keeps firing while the attack button is held.
- Removed its three-shot magazine and reload sequence; each shot now draws directly from the bolt-ammo reserve.
- Venom remains stackable: every bolt adds 50% of that hit as six-second poison, within the existing monster-type health caps.

## 0.6.90

- Halved the Rogue Venom Bow's oversized world-loot billboard while preserving its first-person weapon animation.
- Halved the venom-bolt inventory/HUD icon so it fits the compact ammo display cleanly; the in-world bolt pickup remains unchanged.

## 0.6.89

- Reduced the Rogue's incoming-damage penalty from 40% to 10%; the existing 20% maximum-health and 50% final ammo-capacity penalties remain.
- Shadow Charge now grows only from direct weapon damage. Grenades, secondary elemental effects, Bleed and other damage-over-time sources no longer recharge Shadow Veil.
- Slightly strengthened the Rogue Knife's Shadow Veil strike from x10/x15 to x11/x16, with iconic finale-boss limits raised from x5/x7 to x5.5/x8.
- Added the Rogue-exclusive Venom Bow to weapon slot 3, adapted from the supplied Doom Deluxe slot-9 crossbow. It carries a three-shot magazine, has no alt-fire, and uses dedicated venom bolts.
- Venom bolts add stackable six-second poison equal to 50% of each hit, capped at 15% of normal monster health, 8% of RPG boss health, and 4% of iconic finale-boss health. Poison damage appears in green.
- Added the supplied bow and compact bolt-bundle pickup art. Rogues who own the bow can receive six-bolt drops from kills, with better odds from rarer monsters; non-Rogues cannot consume Rogue weapons or bolt pickups.

## 0.6.88

- Increased the Rogue Knife's base reach by 25%, from 64 to 80 units. Each Rogue Class Training rank now adds another 20% knife reach and 25% knife attack speed.
- Rogue now takes 40% more incoming damage from all sources and has 50% lower maximum ammunition, applied after normal level progression and backpack capacity.
- Rogue's +5% innate critical chance and +2% per Class Training rank now apply only while the Rogue Knife or Silenced Pistol is equipped; universal Luck, Killer Instinct and weapon-affix critical chance remain available to other weapons.

## 0.6.87

- Rebalanced Shadow Veil by giving the Rogue Knife x10 Ambush damage normally and x15 with the Class Ultimate. Fists, knuckles and other melee weapons receive no special Ambush damage bonus; ranged Ambush remains x4/x6.
- Iconic episode-end bosses retain reduced knife Ambush multipliers of x5 normally and x7 with the Ultimate.
- Added the supplied compact, gently bobbing bomb marker above living Volatile enemies so their dangerous death explosion is clearly visible before close combat.

## 0.6.86

- Rogue Knife Bleed continues stacking and refreshing from repeated knife hits, including criticals.
- Iconic episode-end bosses now cap accumulated knife Bleed at 10% of scaled maximum health normally or 15% for a Shadow Veil ambush, instead of the ordinary 24%/36% ceilings.
- The knife's powerful direct Shadow Veil ambush critical is unchanged; only its additional stacked damage-over-time is boss-limited.

## 0.6.85

- Reworked Shadow Veil around a true fake-death decoy. Pursuing monsters receive an invisible dead target and let their native Doom AI process the target's death naturally, replacing the forced idle/dormant changes that could still produce a brief twitch or scramble.

## 0.6.84

- Shadow Veil now puts monsters actively hunting the Rogue into a true dormant idle state for the Veil's duration, making them stop immediately as though their target died or vanished. They wake normally when Veil ends, while monsters fighting other players remain active.
- Shadow Veil now lasts three times as long: 18 seconds base, plus 6 seconds per Class Training rank.

## 0.6.83

- Further stabilized Shadow Veil disengagement: only monsters actively targeting the Rogue are changed, their exact facing is preserved, and their horizontal chase momentum is stopped. Passive monster memories and tracer state are no longer rewritten map-wide.

## 0.6.82

- Shadow Veil no longer repeatedly forces monsters to wander and turn in random directions. Monsters calmly forget the hidden Rogue while keeping their current facing, and multiplayer monsters targeting somebody else are left undisturbed.

## 0.6.81

- The Rogue Silenced Pistol can now critical-hit only while its target is unaware of that Rogue (including a Shadow Veil ambush); it cannot roll ordinary criticals once the monster is fighting that player.
- Every Rogue Knife strike now applies Bleed, including ordinary visible attacks. Knife Bleed stacks and refreshes up to its cap, deals double the triggering hit normally, and quadruple on a stealth ambush with a higher 36% health ceiling.

## 0.6.80

- Fixed grenades inheriting the Rogue Silenced Pistol's once-per-target opening critical merely because the pistol was equipped.
- Rogue pistol and knife opening criticals are now granted only by their respective weapon damage types.

## 0.6.79

- Rogue grenade recovery now returns the Silenced Pistol directly to its normal idle frame instead of briefly replaying its unusual equip animation.

## 0.6.78

- Restored the Rogue Silenced Pistol to its original unmirrored orientation so its visible barrel and perfectly accurate hitscan share the expected sightline.
- Rogue quick-grenade throws now hide and restore the silenced pistol exactly like the knife, preventing extra hands without mirroring the gun.

## 0.6.77

- Restored immediate late-start catch-up on direct starts such as E2M1; it no longer waits for class selection before awarding levels, points, and three weapon choices.
- Catch-up choices now remember which multiplayer player they belong to. If that player subsequently chooses Rogue, one of their existing choices is converted into a level-appropriate Rogue Knife or Silenced Pistol without disturbing another player's rewards.

## 0.6.76

- Made the Rogue Silenced Pistol perfectly accurate so its hitscan lands on the crosshair; native visual mirroring does not alter its aim.
- Added the supplied dedicated pistol and knife artwork to their raw pickups and RPG weapon drops.
- Half of a Rogue killer's successful weapon-drop rolls now select a Rogue Knife or Rogue Silenced Pistol, making class weapon variants meaningfully discoverable without increasing the global drop rate.
- Late-start catch-up now waits for a new player's permanent class selection. Rogues are then guaranteed one level-appropriate Rogue Knife or Silenced Pistol among their three catch-up weapon choices.
- Rogue weapon drops remain shared and multiplayer-safe: non-Rogues cannot consume them, while any Rogue teammate can inspect and equip them.

## 0.6.75

- Fixed the invisible Rogue Silenced Pistol by restoring its original visible sprites and mirroring the live weapon layer with UZDoom's native first-person mirror support.
- The mirror is applied only while the silenced pistol is equipped and is cleared automatically for every other weapon.

## 0.6.74

- The quick-grenade system now recognizes every weapon flagged as melee, including the Rogue Knife, and hides it during the throw so the grenade animation cannot produce three hands.
- Mirrored the Rogue Silenced Pistol into the left hand, leaving the right hand visually free for quick-grenade throws.
- Removed the post-shot upward/equip motion from both Rogue weapons by returning attacks directly to their steady ready state.

## 0.6.73

- Assigned the Rogue Knife and Rogue Silenced Pistol to weapon slots 1 and 2, so both can be selected normally.
- Corrected both weapons' raise/ready state flow. Their equip animation now plays once after the weapon finishes rising instead of repeatedly interrupting weapon switching.

## 0.6.72

- Added the Rogue Knife and Rogue Silenced Pistol, adapted from the user-supplied DOOM Revitalized 1.3. Choosing Rogue replaces only that player's fists and pistol; other classes retain their normal weapons.
- The knife is silent, deals 28-42 base melee damage versus the pistol's 8, guarantees its own first hit on each monster as a critical, and inflicts bleed based on 200% of that critical damage (still capped at 24% of monster maximum health). It fully participates in Shadow Veil's much stronger melee Ambush, and subsequent knife drops can roll new levels, rarities, and affixes.
- The silenced pistol fires quietly and guarantees a critical hit the first time each Rogue hits each monster. That critical causes the Rogue's normal bleed, and first-hit tracking is separate for every player in multiplayer.
- Rogue weapons are multiplayer-safe: their inspection panel reads `ROGUE CLASS ONLY`, and both RPG drops and raw weapon pickups reject non-Rogues without consuming the item.

## 0.6.71

- Reduced the explosive-supply crate's visual size by 50% while retaining its forgiving pickup radius.

## 0.6.70

- Replaced dropped grenade models with a class-neutral explosive-supply crate supplied by Tuin. The pickup still feeds the shared reserve: grenades for normal classes and proximity mines for the Engineer.
- Renamed its pickup message to `Picked up explosive supplies.` so it describes both uses correctly.

## 0.6.69

- Lowered the Engineer mine's first-person arm animation so it remains anchored below the bottom edge of the screen, matching the corrected melee grenade positioning.

## 0.6.68

- Fixed an Engineer mine crash when its first-person overlay tried to execute a mine-owned sound action through the currently equipped weapon. The overlay is now visual-only and its arming cue is safely played by the quick-use handler.

## 0.6.67

- Added an Engineer-only proximity mine adapted from Doom Deluxe's slot-0 mine. Pressing the normal grenade key throws it onto the ground, where it settles, arms after about one second, and watches a 130-unit radius for visible hostile monsters.
- Integrated the mine's original first-person/world artwork and throw, flight, bounce, and arming sounds; detonation uses TuinRPG's established quick-grenade explosion sound, visual effects, quake, and multi-band damage.
- Engineers now see the mine icon in the quick-explosive HUD counter and receive a mine-specific empty-ammo message. Every other class retains the normal quick grenade.
- The owning Engineer can face an armed, untriggered mine and press Use to disarm it and recover one explosive charge, provided the reserve is not full.
- Added the supplied dedicated mine and grenade icons and rebuilt the quick-explosive counter as a larger, higher black panel with a subtle bronze border. Both icons preserve their intended proportions.

## 0.6.66

- Prevented Cacodemon-tier and tougher enemies (400+ base health) from rolling Armored once the highest active player reaches level 15, including promoted finale Bosses.
- Reduced the Riot Shotgun's firing and action sounds by 40%.
- Reduced Engineer sentry firing, impact, deployment, packing, and destruction sounds by 40%.

## 0.6.65

- Reworded John's unclear critical-chance tip to state the 50% cap directly and recommend raw damage afterward.

## 0.6.64

- Fixed the new John tip cues being silent by routing the local HUD event through UZDoom's direct UI sound function at full volume.
- Moved Tuin Coin audio into the engine's normal pickup-sound callback and enabled overlapping playback, preventing simultaneous pickups from discarding the randomized coin cue.
- Corrected the physical sound mappings for John tips, Tuin Coins, and ordinary Boss victories to use their resolvable eight-character lump names.
- Added a 320-unit line-of-sight magnet to world Tuin Coins. Nearby untouched coins accelerate toward the nearest living player, while walls block their attraction.

## 0.6.63

- Replaced John's barely audible generic chat cue with three supplied randomized ROTT notification sounds whenever his lower-right combat tip appears.
- Raised the tip cue to a clear UI volume and moved it to an automatic local channel so unrelated pickup sounds cannot silence it.
- Added two supplied randomized victory cues when an ordinary promoted level Boss is defeated; iconic episode finales retain their separate John sequence.

## 0.6.62

- Reduced the extra-life heart's world sprite by one third so it remains noticeable without obscuring nearby combat.
- Reworked Life Essence into stackable temporary overhealth: each pickup immediately adds 30 current and maximum health, loses one untouched point per second, and lets incoming damage consume the temporary pool without double-draining it afterward.
- Made Life Essence play its randomized custom pickup cue explicitly on a dedicated sound channel, preventing simultaneous pickups from silencing it.
- Added two supplied randomized Tuin Coin pickup sounds on their own channel, replacing the ordinary Doom item cue.
- Rebuilt the Explosive monster affix death blast with the quick grenade's visible explosion, sound, quake, and direct sight-checked radius damage with distance falloff.

## 0.6.61

- Expanded the Hell Director's high-level preferred pool to include Cacodemons alongside Hell Knights, Barons, and stronger monsters (400+ original health).
- From player level 15 onward, the Director scans the complete living roster, including dormant and unseen monsters, and promotes lighter monsters such as Imps only when no eligible heavy candidate exists.

## 0.6.60

- Reworked Engineer into a recoverable sentry-management class with 15% less maximum health and 10% less personal weapon damage.
- Removed the deployment timer. Turrets now persist until broken or out of ammunition, and pressing the Class Ability key near a healthy turret packs it while preserving its exact health and rounds.
- Added Fabrication: an unavailable sentry is rebuilt by kills and ammunition pickups. Stronger monsters grant more progress, ammo types are weighted by value, and Class Training increases Fabrication gains by 10% per rank.
- Replaced Sentry Protocol with **Twin Sentries**, giving the Ultimate two independent turret slots that must each be maintained and rebuilt.
- Added level scaling to turret rounds and a deployment-time snapshot of 50% of the held weapon variant's item-level Power, Power, Haste, and critical bonuses.
- Expanded the Engineer HUD to show each slot as active, packed, or rebuilding, together with current HP, rounds, or Fabrication percentage.

## 0.6.59

- Added Engineer as a sixth permanent class, with a placeable auto-turret on the Class Ability key.
- Integrated the supplied Aliens auto-turret sprites and sounds, and Doomtopmode's moving MD3 tracer model for its physical rounds.
- The sentry has 400 health, 250 rounds, a 1,280-unit engagement range, one-active-turret limit, and a 30-second deployment recharge.
- Engineer Class Training adds 10% turret damage and shortens redeployment by 10% per rank. Sentry Protocol upgrades the turret to 600 health, 400 rounds, faster fire, and a shorter recharge.
- Turret damage and kills are credited to its Engineer for RPG statistics and rewards, while equipped weapon traits cannot leak into turret shots.
- Added an Engineer HUD readout for sentry health, ammunition, and redeployment readiness, plus a one-command turret test option.
- Fixed Life Essence playing Doom's ordinary item pickup sound alongside its randomized custom sounds.

## 0.6.58

- Integrated the supplied handmade Life Essence KVX model, its sprite fallback, and all five randomized pickup sounds.
- Added a configurable 10% chance for every counted monster to drop a floating, spinning Life Essence.
- Life Essence regenerates 30 health smoothly over ten seconds. Multiple pickups combine their remaining healing without erasing one another.
- Added subtle green light, pickup particles, regeneration particles, and a test command under the Player RPG options.
- Kept Life Essence free of counters, 50-pickup milestones, and collection rewards from its old implementation.

## 0.6.57

- Added a quiet Doom chat notification sound when John's milestone portrait and comment appear.

## 0.6.56

- Removed the visible kill percentage from John's combat-tip popup. Milestones still trigger the system internally, while the dialogue panel now simply identifies John.

## 0.6.55

- Added John combat commentary at every 10% kill milestone, with an independent 50% chance to speak at each milestone.
- Added 50 distinct gameplay tips, class reminders, tactical observations, and encouraging remarks.
- Reused the floating revival portrait in a smaller lower-right presentation with gentle bobbing, fade animation, and a compact black dialogue panel.
- Added the user option **John's combat tips** and a settings-menu test command for previewing a random comment immediately.

## 0.6.54

- Fixed Blood Drinker on low-damage bullets, pellets, and rapid-fire weapons by carrying fractional healing forward until it becomes a full health point.
- Combined perk and equipped weapon leech into the same damage-based calculation, including found weapon variants, without rounding every small hit up to one health.
- Improved minimap Hunt cleanup so living counted monsters remain visible while dormant or temporarily non-shootable.
- Made the minimap K/I/S/HUNT status line scale to its panel width instead of clipping on narrow HUD layouts.

## 0.6.53

- Added a persistent minimap Hunt phase once the player reaches 85% kills on a map.
- Revealed every remaining hostile during Hunt. Ordinary monsters use bright yellow pulsing markers, while special enemies retain their rarity colors.
- Added edge-clamped Hunt markers for surviving monsters outside the minimap range and a visible HUNT label beside the minimap statistics.

## 0.6.52

- Tripled the protected life-revival scene from 1.4 seconds to 4.2 seconds before returning the player to the map start.
- Added slow vertical bobbing and subtle sideways drift to John's floating revival portrait.
- Added the supplied full-screen Tuin Doom RPG guide as the F1 help page.

## 0.6.51

- Reworked life revival into a dramatic 1.4-second protected sequence at the defeat location. Movement pauses beneath a pulsing red screen effect, red particles, light, sound, and one of five John encouragement lines before the player returns to the map start.
- Added a short red fade after revival while the existing three-second protection begins.
- Added the supplied transparent floating John face to the revival sequence, with a gentle pulse above his encouragement line.

## 0.6.50

- Moved the life count onto its own clearly visible third row beneath the minimap instead of appending it to the XP row where wide values could run beyond the screen edge.
- Expanded the player HUD panel and repositioned every class ability and target panel to prevent overlap with the new life row.

## 0.6.49

- Replaced Doom's single-player tally screen with a framed TuinRPG **Mission Report** while retaining the normal intermission controls and map transition.
- Added animated completion bars for kills, items, and secrets, plus mission time, par time, and a pace bonus.
- Added a weighted 0-1000 mission score and E-through-S rating: kills award up to 300 points, items 150, secrets 150, pace 100, and preserving lives up to 300. Full kills, perfect pace, and no deaths reach C when items and secrets are ignored.
- Added an RPG Record for per-level damage dealt, damage taken, XP earned, coins collected, special and Boss kills, critical hits, and class ability uses.
- Damage records count actual health removed, including lethal hits, while excluding overkill and console damage without a player source.
- Added a rating-aware John verdict in a separate dialogue font at the end of every Mission Report.
- Added the player's current RPG level, chosen class, coin balance, and clearer calculating/continue prompts to the report.
- Added a limited-lives system. Players begin with three lives; lethal damage consumes one, returns the same player to the map start at full health, and grants three seconds of protection without resetting map progress or inventory.
- Rare, Elite, Legendary, Mythic, and Boss enemies can drop an extra-life heart at increasingly generous rates. The supplied transparent heart art floats, pulses, emits small particles, and can raise the player to the configurable nine-life default maximum.
- Added the current life count to the HUD and Mission Report. Lives used during a map now have a major effect on the final mission rating.

## 0.6.48

- Removed the Executioner's 10% increased incoming-damage penalty. The class retains its 25% lower maximum health as its defensive tradeoff.
- Added a visible **Fodder** debuff that makes every Lost Soul take 50% more player damage, including Rare, Mythic, and Pain Elemental-spawned variants.
- Crowds of eleven or more living hostile monsters within 512 map units also receive Fodder, helping ammunition economy on dense slaughter maps without weakening sparse encounters.
- Applied Fodder after elite bonus-damage limiting so high rarity cannot weaken the intended 50% vulnerability.

## 0.6.47

- Reworked Death Sentence into a one-press setup: full Judgment is armed with `V`, then the next qualifying weapon hit sentences the monster it strikes.
- The struck monster becomes the primary target and Judgment spreads to the two nearest visible hostiles within 384 map units, for a maximum of three sentenced targets.
- Missing, hitting scenery, grenade damage, Blood Punch, Final Verdict, bleeding, burning, poison, and plasma-arc damage do not consume armed Judgment.
- Updated the Executioner HUD, notifications, class card, testing cheat, and automated gameplay regression for the new armed-next-hit flow.

## 0.6.46

- Replaced Death Sentence's exact crosshair line trace with a forgiving 70-degree forward Judgment cone reaching at least 3,072 map units.
- One activation now selects up to three visible monsters, prioritizing crosshair alignment and then distance, so fast lateral targets no longer make the ability feel unreliable.
- Every sentenced target receives its own red skull, damage bonus, timer, and Final Verdict explosion. Killing one does not remove the sentence from the others.
- No Appeals refunds 25% Judgment only once per multi-target cast, preventing three executions from tripling the refund.
- Updated the Executioner HUD, target panel, notifications, and class description for plural sentenced targets.

## 0.6.45

- Added a custom blood-red demonic skull sprite that bobs and pulses above the monster carrying Death Sentence, including moving and flying targets.
- The skull marker is centered in world space and disappears immediately when the target dies, the sentence expires, or a level transition invalidates the target.
- Reworded the full-Judgment HUD and notifications to clearly instruct the Executioner to **choose a target**.

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
