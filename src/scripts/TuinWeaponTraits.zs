// Weapon traits use reserved high affix bits so every existing variant transfer,
// chest, save, shop and drop preserves the same roll automatically.
class TuinWeaponTraits : Object play
{
    const INITIALIZED = 536870912;
    const MASK = 16776960;

    clearscope static int Bit(int trait) { return 1 << (8 + trait); }
    clearscope static int Tier(int quality) { return clamp(quality - 1, 1, 5); }
    clearscope static int Slots(int quality)
    {
        return quality < 2 ? 0 : quality < 4 ? 1 : quality < 6 ? 2 : 3;
    }
    clearscope static int Compatible(int flags, class<Weapon> kind)
    {
        if (TuinRPGHandler.ClassesEnabled() || !kind || !(flags & Bit(6))) return flags;
        let def = GetDefaultByType(kind);
        if (def && ((def.AmmoType1 && def.AmmoUse1 > 0) || (def.AmmoType2 && def.AmmoUse2 > 0))) return flags;
        flags &= ~Bit(6);
        // Preserve the number of rolled traits. Prefer Vampire's for melee.
        for (int i = 0; i < 12; i++)
        {
            int replacement = (5 + i) % 12;
            if (replacement != 6 && !(flags & Bit(replacement))) return flags | Bit(replacement);
        }
        return flags;
    }
    clearscope static int Roll(int flags, int quality, int seed, class<Weapon> kind = null)
    {
        if (TuinRPGHandler.ClassesEnabled()) return flags;
        if (flags & INITIALIZED) return Compatible(flags, kind);
        flags |= INITIALIZED;
        // Deterministic sampling without replacement also upgrades old saves
        // once without rerolling their traits on every map or load.
        int choices[16];
        for (int i = 0; i < 16; i++) choices[i] = i;
        seed = abs(seed % 1000003);
        for (int i = 0; i < Slots(quality); i++)
        {
            seed = (seed * 73 + 19) % 1000003;
            int selected = seed % (16 - i);
            flags |= Bit(choices[selected]);
            choices[selected] = choices[15 - i];
        }
        return Compatible(flags, kind);
    }
    clearscope static string NameOf(int trait)
    {
        switch (trait)
        {
        case 0: return "GUARD'S";
        case 1: return "MEDIC'S";
        case 2: return "HUNTER'S";
        case 3: return "SURVIVOR'S";
        case 4: return "EXECUTIONER'S";
        case 5: return "VAMPIRE'S";
        case 6: return "SCAVENGER'S";
        case 7: return "DUELIST'S";
        case 8: return "LAST STAND";
        case 9: return "FORTUNE'S";
        case 10: return "AVENGER'S";
        case 11: return "BULWARK'S";
        case 12: return "SECOND WIND";
        case 13: return "MOMENTUM";
        case 14: return "PROSPECTOR'S";
        case 15: return "QUARTERMASTER'S";
        }
        return "";
    }
    clearscope static bool Passive(int trait)
    {
        return trait == 0 || trait == 1 || trait == 3 || trait == 9 || trait == 12 || trait == 14 || trait == 15;
    }
    clearscope static int Nth(int flags, int index)
    {
        for (int i = 0; i < 16; i++) if (flags & Bit(i))
        {
            if (index-- == 0) return i;
        }
        return -1;
    }
    clearscope static string Description(int trait, int quality)
    {
        int t = Tier(quality);
        switch (trait)
        {
        case 0: return String.Format("RESTORES ARMOR TO %d; REFILLS AFTER 5s SAFE", t * 10);
        case 1: return String.Format("+1 HP / %ds; UP TO NORMAL MAX HEALTH", 6 - t);
        case 2: return String.Format("+%d%% DAMAGE TO FULL-HEALTH TARGETS", 20 + (t - 1) * 30 / 4);
        case 3: return String.Format("SURVIVE AT 1 HP ONCE / MAP; %ds PROTECTION", t);
        case 4: return String.Format("+%d%% DAMAGE BELOW 25%% ENEMY HEALTH", 15 + t * 10);
        case 5: return String.Format("WEAPON KILLS RESTORE %d HP", t * 2);
        case 6: return String.Format("%d%% KILL CHANCE: REFUND ONE SHOT", 10 + t * 10);
        case 7: return String.Format("REPEAT HITS +2%%; MAX +%d%%; RESET: SWITCH / NEW TARGET / 3S IDLE", t * 4);
        case 8: return String.Format("BELOW 30%% HP: +%d%% DAMAGE / +%d%% SPEED", 10 + t * 10, t * 5);
        case 9: return String.Format("+%d%% COINS COLLECTED", t * 10);
        case 10: return String.Format("AFTER HURT: NEXT HIT +%d%% DAMAGE WITHIN 5s", 20 + t * 10);
        case 11: return String.Format("STAND STILL 2s: %d%% LESS DAMAGE TAKEN", 5 + t * 3);
        case 12: return String.Format("BELOW 25%% HP: +%d HP / 5s, +20%% MOVE; 90s CD", (1 + t) * 5);
        case 13: return "+2% DAMAGE / KILL, MAX 50%; DECAYS AFTER 8s; SWITCH RESETS";
        case 14: return String.Format("+%d%% RELATIVE NON-BOSS LOOT RARITY; MAX 20%%", t * 4);
        case 15: return String.Format("+1 AMMO / %ds IDLE (HEAVY: %ds); CAPS AT 25%%", 13 - t, (13 - t) * 2);
        }
        return "";
    }
    ui static string Shimmer(int trait)
    {
        string text = NameOf(trait);
        string tint = trait == 0 || trait == 11 ? "\c[lightblue]" :
            trait == 1 || trait == 6 || trait == 12 || trait == 15 ? "\c[green]" : trait == 2 || trait == 7 || trait == 13 ? "\c[cyan]" :
            trait == 3 || trait == 9 || trait == 14 ? "\c[gold]" : trait == 5 ? "\c[purple]" : "\c[red]";
        int sweep = int(gametic / 4) % (text.Length() + 9);
        string result;
        for (int i = 0; i < text.Length(); i++)
            result = result .. ((i == sweep || i == sweep - 1) ? "\c[white]" : tint) .. text.Mid(i, 1);
        return result .. "\c[white]";
    }
    // Per-glyph motion inspired by FluidWeapons' animated submenu labels.
    // Wall-clock phase stays smooth while menus pause the game; no gameplay state is touched.
    ui static void FluidText(Font font, int tint, double x, double y, string text,
        double scale, double maxWidth, bool godly = false, bool animated = true, bool mythic = false, int rarity = 0, double alpha = 1)
    {
        // All callers use the same quality profile, even when only a rarity is supplied.
        godly = godly || rarity == 6;
        mythic = mythic || rarity == 5;
        scale = min(scale, maxWidth / max(1, font.StringWidth(text)));
        if (!animated || TuinRPGHandler.ClassesEnabled())
        {
            Screen.DrawText(font, tint, x, y, text, DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Alpha, alpha);
            return;
        }
        double phase = MSTimeF() * 0.065;
        double motion = godly ? .60 : mythic ? .38 : rarity == 4 ? .12 : rarity == 3 ? .04 : rarity == 2 ? .07 : .35;
        double glowStrength = godly ? 1. : mythic ? .85 : rarity == 4 ? .7 : rarity == 3 ? .25 : rarity == 2 ? .3 : 1.;
        double cursor = x;
        for (int i = 0; i < text.Length();)
        {
            int code, next;
            [code, next] = text.GetNextCodePoint(i);
            string glyph = text.Mid(i, next - i);
            double wave = sin(phase * 1.5 - i * 19) * motion * scale;
            double shine = (sin(phase * 2 - i * 24) + 1) * 0.5;
            // Elite stays copper-orange; Legendary gets a distinct pale-gold
            // traveling glint instead of sharing the same broad orange shimmer.
            double goldGlint = shine * shine * shine * shine;
            double copperPulse = (sin(phase * .6) + 1) * .5;
            Color overlay = godly ? Color(255,
                int(178 + 77 * sin(phase + i * 12)),
                int(178 + 77 * sin(phase + i * 12 + 120)),
                int(178 + 77 * sin(phase + i * 12 + 240))) : mythic ?
                Color(255, int(180 + 65 * shine), int(65 + 120 * shine), 255) :
                rarity == 4 ? Color(255, 255, int(220 + 35 * goldGlint), int(45 + 165 * goldGlint)) :
                rarity == 3 ? Color(255, int(220 + 25 * copperPulse), int(65 + 20 * copperPulse), 12) :
                rarity == 2 ? Color(255, int(55 + 65 * shine), int(165 + 55 * shine), 255) : Color(0, 0, 0, 0);
            for (int glow = -1; glow <= 1; glow += 2)
                Screen.DrawText(font, tint, cursor + glow * scale * 0.65, y + wave,
                    glyph, DTA_ScaleX, scale, DTA_ScaleY, scale,
                    DTA_ColorOverlay, overlay, DTA_Alpha, alpha * (0.10 + shine * 0.09) * glowStrength);
            Screen.DrawText(font, tint, cursor, y + wave, glyph,
                DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_ColorOverlay, overlay, DTA_Alpha, alpha);
            cursor += font.StringWidth(glyph) * scale;
            i = next;
        }
    }
    ui static string Label(int trait, int quality)
    {
        return Shimmer(trait) .. (Passive(trait) ? "  [PASSIVE] " : "  [EQUIPPED] ") .. Description(trait, quality);
    }
    ui static string DisplayName(class<Weapon> kind, int flags, int quality, int id)
    {
        string plain = TuinRPGHandler.WeaponVariantName(kind, flags, quality, id);
        // Rare-and-up names use rarity styling throughout, not the trait's green/cyan
        // inline color. Trait descriptions keep their own semantic colors.
        if (TuinRPGHandler.ClassesEnabled() || quality >= 2) return plain;
        int trait = Nth(flags, 0);
        return trait < 0 ? plain : Shimmer(trait) .. " " .. TuinRPGHandler.WeaponBaseName(kind);
    }
    clearscope static int ActiveIndex(TuinPlayerData data)
    {
        if (TuinRPGHandler.ClassesEnabled() || !data || !data.Owner || !data.Owner.player ||
            !data.Owner.player.ReadyWeapon) return -1;
        return data.FindEquippedVariant((class<Weapon>)(data.Owner.player.ReadyWeapon.GetClass()));
    }
    clearscope static int Strength(TuinPlayerData data, int trait)
    {
        if (TuinRPGHandler.ClassesEnabled() || !data || !data.Owner) return 0;
        int best;
        int active = ActiveIndex(data);
        for (int i = 0; i < data.WeaponVariantCount; i++)
        {
            if (!data.VariantEquipped[i] || !(data.VariantAffixFlags[i] & Bit(trait)) ||
                !data.Owner.FindInventory(data.VariantWeaponType[i])) continue;
            if (!Passive(trait) && i != active) continue;
            best = max(best, Tier(data.VariantQuality[i]));
        }
        return best;
    }
    static void ResetMap(TuinPlayerData data)
    {
        if (!data) return;
        data.TraitSurvivorUsed = false;
        data.TraitGrace = 0;
        data.TraitAvenger = 0;
        data.TraitAvengerBurst = -1;
        data.TraitDuelTarget = null;
        data.TraitDuelStacks = 0;
        data.TraitStill = 0;
        data.TraitMomentumStacks = 0;
        data.TraitMomentumTime = 0;
        data.TraitQuarterClock = 0;
        data.TraitWindTime = 0;
    }
    static void Tick(TuinPlayerData data)
    {
        if (!data || !data.Owner || TuinRPGHandler.ClassesEnabled()) return;
        Actor pawn = data.Owner;
        for (int i = 0; i < data.WeaponVariantCount; i++)
            data.VariantAffixFlags[i] = Roll(data.VariantAffixFlags[i], data.VariantQuality[i], data.VariantID[i], data.VariantWeaponType[i]);
        if (data.TraitGrace > 0) data.TraitGrace--;
        if (data.TraitAvenger > 0) data.TraitAvenger--;
        if (data.TraitHurtDelay > 0) data.TraitHurtDelay--;
        if (data.TraitWindCooldown > 0) data.TraitWindCooldown--;
        if (pawn.Health <= 0 || data.LifeRevivePending) return;
        int active = ActiveIndex(data);
        int variantID = active >= 0 ? data.VariantID[active] : 0;
        if (data.TraitDuelTarget && level.Time - data.TraitDuelTime >= 3 * 35)
        {
            data.TraitDuelStacks = 0;
            data.TraitDuelTarget = null;
        }
        // Clamp stacks restored from saves made before the Duelist rebalance.
        if (active >= 0) data.TraitDuelStacks = min(data.TraitDuelStacks, Tier(data.VariantQuality[active]) * 2);
        if (data.TraitActiveID != variantID)
        {
            data.TraitActiveID = variantID;
            data.TraitDuelStacks = 0;
            data.TraitDuelTarget = null;
            data.TraitStill = 0;
            data.TraitMomentumStacks = 0;
            data.TraitMomentumTime = 0;
            data.TraitQuarterClock = 0;
        }
        if (pawn.Vel.Length() > 0.1 || (pawn.Pos - data.TraitPosition).Length() > 0.1)
            data.TraitStill = 0;
        else data.TraitStill = min(70, data.TraitStill + 1);
        data.TraitPosition = pawn.Pos;
        UpdateNewTraits(data);
        int cap = Strength(data, 0) * 10;
        let armor = BasicArmor(pawn.FindInventory('BasicArmor'));
        int currentArmor = armor ? armor.Amount : 0;
        if (cap > currentArmor && (cap > data.TraitGuardCap ||
            (data.TraitHurtDelay <= 0 && level.Time % 35 == 0)))
        {
            int amount = cap > data.TraitGuardCap ? cap - currentArmor : min(cap - currentArmor, max(1, cap / 5));
            pawn.GiveInventory('TuinGuardArmorBonus', amount);
        }
        data.TraitGuardCap = cap;
        armor = BasicArmor(pawn.FindInventory('BasicArmor'));
        data.TraitGuardArmor = min(cap, armor ? armor.Amount : 0);
        int medic = Strength(data, 1);
        if (!medic) data.TraitMedicClock = 0;
        else if (++data.TraitMedicClock >= (6 - medic) * 35)
        {
            data.TraitMedicClock = 0;
            Heal(data, 1);
        }
    }
    static void Heal(TuinPlayerData data, int amount)
    {
        if (!data || !data.Owner || data.Owner.Health <= 0 || data.LifeRevivePending) return;
        int cap = max(1, data.Owner.GetMaxHealth(true) - data.AppliedLifeEssenceOverhealth);
        if (data.Owner.Health < cap) data.Owner.A_SetHealth(min(cap, data.Owner.Health + amount));
    }
    static void UpdateNewTraits(TuinPlayerData data)
    {
        Actor pawn = data.Owner;
        int wind = Strength(data, 12);
        int normalMax = max(1, pawn.GetMaxHealth(true) - data.AppliedLifeEssenceOverhealth);
        if (wind && data.TraitWindCooldown <= 0 && pawn.Health * 4 < normalMax)
        {
            data.TraitWindCooldown = 90 * 35;
            data.TraitWindTime = 175;
            data.TraitWindHeal = 1 + wind;
            pawn.GiveInventoryType('TuinSecondWindSpeed');
        }
        if (data.TraitWindTime > 0)
        {
            if (data.TraitWindTime % 35 == 0) Heal(data, data.TraitWindHeal);
            data.TraitWindTime--;
        }
        if (!Strength(data, 13)) data.TraitMomentumStacks = 0;
        if (data.TraitMomentumTime > 0) data.TraitMomentumTime--;
        else if (data.TraitMomentumStacks > 0)
        {
            data.TraitMomentumStacks--;
            data.TraitMomentumTime = 34;
        }
        int quarter = Strength(data, 15);
        Weapon weapon = pawn.player ? pawn.player.ReadyWeapon : null;
        if (!quarter || !weapon || (pawn.player.cmd.buttons & (BT_ATTACK | BT_ALTATTACK)))
        { data.TraitQuarterClock = 0; return; }
        int family = TuinRPGHandler.WeaponFamily(weapon);
        int interval = (13 - quarter) * 35 * (family == 6 || family == 7 || family == 8 || weapon.AmmoUse1 > 1 ? 2 : 1);
        if (++data.TraitQuarterClock < interval) return;
        data.TraitQuarterClock = 0;
        class<Ammo> kind = weapon.AmmoType1;
        if (!kind || weapon.AmmoUse1 <= 0) return;
        let ammo = Ammo(pawn.FindInventory(kind));
        if (ammo && ammo.Amount < ammo.MaxAmount / 4) ammo.Amount++;
    }
    static int Defend(TuinPlayerData data, int damage, Name damageType, int flags)
    {
        if (!data || !data.Owner || TuinRPGHandler.ClassesEnabled() || damage <= 0) return damage;
        if (data.LifeRevivePending || data.LifeGraceTics > 0) return damage;
        if (data.TraitGrace > 0 && !(flags & DMG_FORCED)) return 0;
        if (flags & DMG_FORCED) return damage;
        int bulwark = Strength(data, 11);
        if (bulwark && data.TraitStill >= 70)
            damage = max(1, int(damage * (1.0 - (5 + bulwark * 3) * 0.01)));
        // BasicArmor absorbs damage once, through the engine's normal armor path.
        data.TraitHurtDelay = 175;
        if (Strength(data, 10)) data.TraitAvenger = 175;
        int survivor = Strength(data, 3);
        if (survivor && !data.TraitSurvivorUsed && data.Owner.Health > 0 && damage >= data.Owner.Health)
        {
            data.TraitSurvivorUsed = true;
            data.TraitGrace = survivor * 35;
            data.Owner.A_Print("SURVIVOR'S: FATAL HIT SURVIVED!");
            return max(0, data.Owner.Health - 1);
        }
        return damage;
    }
    clearscope static bool Direct(Name damageType)
    {
        return damageType != 'TuinBleed' && damageType != 'TuinRocketBurn' &&
            damageType != 'TuinPlasmaArc' && damageType != 'TuinRoguePoison' &&
            damageType != 'TuinWeaponPerkPierce' && damageType != 'TuinEngineerTurret' &&
            damageType != 'TuinFinalVerdict' && damageType != 'Poison';
    }
    static int Attack(TuinMonsterData monster, Actor source, Actor inflictor, Name damageType, int damage)
    {
        if (TuinRPGHandler.ClassesEnabled() || !monster || !monster.Owner) return damage;
        let handler = TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        if (handler && handler.ApplyingBonusDamage) return damage;
        monster.TraitKillSource = null;
        monster.TraitKillFlags = 0;
        if (!source || !source.player || damage <= 0 || !Direct(damageType) ||
            TuinRPGHandler.IsGrenadeDamage(inflictor, damageType)) return damage;
        let data = TuinPlayerData(source.FindInventory('TuinPlayerData'));
        if (!data) return damage;
        int index = ActiveIndex(data);
        int flags = index >= 0 ? data.VariantAffixFlags[index] : 0;
        int t = index >= 0 ? Tier(data.VariantQuality[index]) : 1;
        // A projectile remembers the weapon that fired it even after switching.
        let stamp = inflictor ? TuinTraitProjectileStamp(inflictor.FindInventory('TuinTraitProjectileStamp')) : null;
        if (stamp && !stamp.Initialized) stamp.Capture();
        if (stamp && stamp.Initialized) { flags = stamp.TraitFlags; t = stamp.TraitTier; }
        bool rocketPerk = stamp && stamp.Initialized ? stamp.RocketPerk :
            source.player.ReadyWeapon && TuinRPGHandler.WeaponFamily(source.player.ReadyWeapon) == 8 &&
            TuinRPGHandler.HasWeaponPerk(data, 8);
        if (rocketPerk) damage = max(1, int(damage * 0.70 + 0.5));
        if (stamp && stamp.Overcharge) damage = max(1, int(damage * 1.5 + 0.5));
        if (stamp && stamp.Wildfire && monster.Owner.Health > 0)
        {
            monster.Owner.GiveInventoryType('TuinWildfireBurn');
            let wildfire = TuinWildfireBurn(monster.Owner.FindInventory('TuinWildfireBurn'));
            if (wildfire) wildfire.Ignite(source, damage, true);
        }
        monster.TraitKillFlags = flags;
        monster.TraitKillTier = t;
        monster.TraitKillWeapon = stamp && stamp.Initialized ? stamp.WeaponType :
            index >= 0 ? data.VariantWeaponType[index] : null;
        monster.TraitKillSource = source;
        monster.TraitKillTime = level.Time;
        monster.TraitKillDamageType = damageType;
        double factor = 1.0;
        if (flags & Bit(13))
        {
            factor *= 1.0 + (stamp && stamp.Initialized ? stamp.MomentumBonus : data.TraitMomentumStacks * 2) * 0.01;
            data.TraitMomentumTime = 8 * 35;
        }
        if (flags & Bit(2))
        {
            int player = source.PlayerNumber();
            if (player >= 0 && player < 8 && monster.Owner.Health >= monster.ScaledMaxHealth)
                monster.TraitHunterHitTime[player] = level.Time + 1;
            if (player >= 0 && player < 8 && monster.TraitHunterHitTime[player] == level.Time + 1)
                factor *= 1.0 + (20 + (t - 1) * 30 / 4) * 0.01;
        }
        if ((flags & Bit(4)) && monster.Owner.Health * 4 <= monster.ScaledMaxHealth)
            factor *= 1.0 + (15 + t * 10) * 0.01;
        if (flags & Bit(7))
        {
            if (data.TraitDuelTarget != monster.Owner || level.Time - data.TraitDuelTime >= 3 * 35)
            {
                data.TraitDuelTarget = monster.Owner;
                data.TraitDuelStacks = 0;
                data.TraitDuelTime = level.Time;
            }
            else if (data.TraitDuelTime != level.Time)
            {
                data.TraitDuelTime = level.Time;
                data.TraitDuelStacks = min(t * 2, data.TraitDuelStacks + 1);
            }
            data.TraitDuelStacks = min(data.TraitDuelStacks, t * 2);
            factor *= 1.0 + data.TraitDuelStacks * 0.02;
        }
        else { data.TraitDuelTarget = null; data.TraitDuelStacks = 0; }
        if ((flags & Bit(8)) && source.Health * 100 < source.GetMaxHealth(true) * 30)
            factor *= 1.0 + (10 + t * 10) * 0.01;
        if (flags & Bit(10))
        {
            if (data.TraitAvenger > 0)
            {
                data.TraitAvenger = 0;
                data.TraitAvengerBurst = level.Time;
            }
            if (data.TraitAvengerBurst == level.Time) factor *= 1.0 + (20 + t * 10) * 0.01;
        }
        return max(1, int(damage * factor + 0.5));
    }
    static void Kill(TuinMonsterData monster, Actor source, Name damageType)
    {
        if (TuinRPGHandler.ClassesEnabled() || !monster || !source ||
            monster.TraitKillSource != source || !Direct(damageType)) return;
        let data = TuinPlayerData(source.FindInventory('TuinPlayerData'));
        if (!data) return;
        int flags = monster.TraitKillFlags;
        int t = monster.TraitKillTier;
        if ((flags & Bit(13)) && Strength(data, 13) && source.player && source.player.ReadyWeapon &&
            source.player.ReadyWeapon.GetClass() == monster.TraitKillWeapon)
        {
            data.TraitMomentumStacks = min(25, data.TraitMomentumStacks + 1);
            data.TraitMomentumTime = 8 * 35;
        }
        if (flags & Bit(5)) Heal(data, t * 2);
        if ((flags & Bit(6)) && Random[TuinTraitRefund](1, 100) <= 10 + t * 10)
        {
            let weapon = Weapon(source.FindInventory(monster.TraitKillWeapon));
            if (weapon && (weapon.AmmoType1 || weapon.AmmoType2))
            {
                bool primary = weapon.AmmoType1 && weapon.AmmoUse1 > 0;
                let ammo = Ammo(source.FindInventory(primary ? weapon.AmmoType1 : weapon.AmmoType2));
                if (ammo) ammo.Amount = min(ammo.MaxAmount, ammo.Amount + max(1, primary ? weapon.AmmoUse1 : weapon.AmmoUse2));
            }
        }
    }
    static void Stamp(Actor projectile)
    {
        if (TuinRPGHandler.ClassesEnabled() || !projectile || !projectile.bMISSILE ||
            (projectile.target && !projectile.target.player)) return;
        projectile.GiveInventoryType('TuinTraitProjectileStamp');
        let stamp = TuinTraitProjectileStamp(projectile.FindInventory('TuinTraitProjectileStamp'));
        if (stamp) stamp.Capture();
    }
}

class TuinSecondWindSpeed : PowerSpeed
{
    Default { Powerup.Duration -5; Speed 1.2; PowerSpeed.NoTrail 1; }
}

class TuinGuardArmorBonus : BasicArmorBonus
{
    Default
    {
        Armor.SaveAmount 1;
        Armor.MaxSaveAmount 200;
        Armor.SavePercent 33.335;
        Inventory.Icon "ARM1A0";
        +INVENTORY.IGNORESKILL
    }
}

class TuinTraitProjectileStamp : Inventory
{
    int TraitFlags;
    int TraitTier;
    class<Weapon> WeaponType;
    bool Initialized;
    bool RocketPerk;
    bool Wildfire;
    bool Overcharge;
    int MomentumBonus;
    void Capture()
    {
        if (Initialized || !Owner || !Owner.target) return;
        Initialized = true;
        let data = TuinPlayerData(Owner.target.FindInventory('TuinPlayerData'));
        RocketPerk = data && Owner.target.player &&
            TuinRPGHandler.WeaponFamily(Owner.target.player.ReadyWeapon) == 8 &&
            TuinRPGHandler.HasWeaponPerk(data, 8);
        if (data && Owner.target.player)
        {
            Weapon fired = Owner.target.player.ReadyWeapon;
            Wildfire = fired && TuinRPGHandler.WeaponFamily(fired) == 9 &&
                TuinRPGHandler.HasWeaponPerk(data, 9) && Owner is 'ID24IncineratorFlame';
            Overcharge = fired && TuinRPGHandler.WeaponFamily(fired) == 10 &&
                TuinRPGHandler.HasWeaponPerk(data, 10) && Owner is 'ID24IncineratorProjectile';
            if (Wildfire)
            {
                data.RustFuelRemainder += max(1, fired.AmmoUse1);
                int extra = data.RustFuelRemainder / 4;
                data.RustFuelRemainder %= 4;
                if (extra > 0 && fired.AmmoType1) Owner.target.TakeInventory(fired.AmmoType1, extra);
            }
            if (Overcharge)
            {
                Owner.A_SetSize(Owner.Radius * 1.5, Owner.Height);
                Owner.Scale = (Owner.Scale.X * 1.5, Owner.Scale.Y);
            }
        }
        int index = TuinWeaponTraits.ActiveIndex(data);
        if (index < 0) return;
        MomentumBonus = data.TraitMomentumStacks * 2;
        TraitFlags = data.VariantAffixFlags[index];
        TraitTier = TuinWeaponTraits.Tier(data.VariantQuality[index]);
        WeaponType = data.VariantWeaponType[index];
    }
    override void Tick() { Super.Tick(); Capture(); }
    Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE }
}

// Combine one tic's pellets, but replace (not stack) the burn on later hits.
class TuinShotgunBurn : Inventory
{
    int Remaining;
    int Pulses;
    int Clock;
    int HitTime;
    int HitDamage;
    Actor Source;
    void Refresh(Actor attacker, int damage)
    {
        if (Pulses == 0 || HitTime != level.Time || Source != attacker) HitDamage = 0;
        HitTime = level.Time;
        HitDamage += max(0, damage);
        Remaining = max(1, int(HitDamage * 0.5 + 0.5));
        if (Pulses == 0) Clock = 35;
        Pulses = 3;
        Source = attacker;
    }
    override void Tick()
    {
        Super.Tick();
        if (!Owner || Owner.Health <= 0 || TuinRPGHandler.ClassesEnabled()) { Destroy(); return; }
        if (--Clock > 0) return;
        let handler = TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        if (!handler) return;
        int damage = (Remaining + Pulses - 1) / Pulses;
        Remaining -= damage;
        Pulses--;
        Clock = 35;
        bool previous = handler.ApplyingBonusDamage;
        handler.ApplyingBonusDamage = true;
        let monster = TuinMonsterData(Owner.FindInventory('TuinMonsterData'));
        if (monster) monster.TraitKillSource = null;
        Actor victim = Owner;
        int before = victim.Health;
        if(!TuinRPGHandler.ClassesEnabled())
            damage=max(1,int(damage*TuinRPGHandler.NativeBossResistance(victim,Source,Source,'TuinShotgunBurn')+.5));
        victim.DamageMobj(Source, Source, damage, 'TuinShotgunBurn', DMG_FORCED);
        handler.ApplyingBonusDamage = previous;
        int dealt = min(before, max(0, before - victim.Health));
        if (dealt > 0 && Source && Source.player)
            handler.SpawnDamageNumber(Source.PlayerNumber(), victim, dealt, false, false, 1);
        if (Pulses <= 0 || !Owner || Owner.Health <= 0) Destroy();
    }
    Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE }
}

// Every critical rocket owns its own five-second damage schedule.
class TuinHellfireBurn : Inventory
{
    Array<int> Remaining;
    Array<int> Pulses;
    Array<int> Clocks;
    Array<Actor> Sources;
    void AddStack(Actor source, int damage)
    {
        Remaining.Push(max(1, int(damage * 0.5 + 0.5)));
        Pulses.Push(5);
        Clocks.Push(35);
        Sources.Push(source);
    }
    override void Tick()
    {
        Super.Tick();
        if (!Owner || Owner.Health <= 0 || TuinRPGHandler.ClassesEnabled()) { Destroy(); return; }
        let handler = TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        if (!handler) return;
        for (int i = int(Remaining.Size()) - 1; i >= 0; i--)
        {
            Clocks[i]--;
            if (Clocks[i] > 0) continue;
            int damage = (Remaining[i] + Pulses[i] - 1) / Pulses[i];
            Remaining[i] -= damage;
            Pulses[i]--;
            Clocks[i] = 35;
            bool previous = handler.ApplyingBonusDamage;
            handler.ApplyingBonusDamage = true;
            let monster = TuinMonsterData(Owner.FindInventory('TuinMonsterData'));
            if (monster) monster.TraitKillSource = null;
            Actor victim = Owner;
            int healthBefore = victim.Health;
            if(!TuinRPGHandler.ClassesEnabled())
                damage=max(1,int(damage*TuinRPGHandler.NativeBossResistance(Owner,Sources[i],Sources[i],'TuinHellfireBurn')+.5));
            Owner.DamageMobj(Sources[i], Sources[i], damage, 'TuinHellfireBurn', DMG_FORCED);
            handler.ApplyingBonusDamage = previous;
            int dealt = min(healthBefore, max(0, healthBefore - victim.Health));
            if (dealt > 0 && Sources[i] && Sources[i].player)
                handler.SpawnDamageNumber(Sources[i].PlayerNumber(), victim, dealt, false, false, 1);
            if (!Owner || Owner.Health <= 0) { Destroy(); return; }
            if (Pulses[i] <= 0)
            {
                Remaining.Delete(i); Pulses.Delete(i); Clocks.Delete(i); Sources.Delete(i);
            }
        }
        if (Remaining.Size() == 0) Destroy();
    }
    Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE }
}
