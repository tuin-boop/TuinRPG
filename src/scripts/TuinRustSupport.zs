// Optional native ID24 integration; never embeds commercial weapon resources.
class TuinRustSupport : Object play
{
    clearscope static class<Weapon> Resolve(class<Weapon> type)
    {
        if (TuinRPGHandler.ClassesEnabled() ||
            (type != 'ID24Incinerator' && type != 'ID24CalamityBlade')) return type;
        class<Weapon> replacement = (class<Weapon>)(Actor.GetReplacement(type));
        return replacement ? replacement : type;
    }

    static void MigratePlayer(Actor pawn, TuinPlayerData data)
    {
        if (!pawn || !pawn.player || pawn.Health <= 0 || !data || TuinRPGHandler.ClassesEnabled()) return;
        for (int family = 9; family <= 10; family++)
        {
            class<Weapon> original = family == 9 ? 'ID24Incinerator' : 'ID24CalamityBlade';
            class<Weapon> replacement = Resolve(original);
            if (replacement == original) continue;
            // Retain every roll and its ID. If both versions had an equipped
            // variant, keep the replacement's selection; the old roll stays selectable.
            bool selected = data.FindEquippedVariant(replacement) >= 0;
            for (int i = 0; i < data.WeaponVariantCount; i++)
            {
                if (data.VariantWeaponType[i] != original) continue;
                data.VariantWeaponType[i] = replacement;
                if (selected) data.VariantEquipped[i] = false;
                else if (data.VariantEquipped[i]) selected = true;
            }
            Weapon old = Weapon(pawn.FindInventory(original));
            if (!old || old.GetClass() != original) continue;
            Weapon updated = Weapon(pawn.FindInventory(replacement));
            if (!updated)
            {
                readonly<Weapon> def = GetDefaultByType(replacement);
                Inventory a1 = def.AmmoType1 ? pawn.FindInventory(def.AmmoType1) : null;
                Inventory a2 = def.AmmoType2 ? pawn.FindInventory(def.AmmoType2) : null;
                int amount1 = a1 ? a1.Amount : 0;
                int amount2 = a2 ? a2.Amount : 0;
                pawn.GiveInventory(replacement, 1);
                updated = Weapon(pawn.FindInventory(replacement));
                a1 = def.AmmoType1 ? pawn.FindInventory(def.AmmoType1) : null;
                a2 = def.AmmoType2 ? pawn.FindInventory(def.AmmoType2) : null;
                if (a1) a1.Amount = amount1;
                if (a2) a2.Amount = amount2;
            }
            if (!updated) continue;
            // Use the engine's equip path to rebind PSprite callers as well as
            // ReadyWeapon; queuing alone can leave a saved native weapon stuck.
            if (pawn.player.ReadyWeapon == old || pawn.player.PendingWeapon == old)
            {
                pawn.player.PendingWeapon = updated;
                pawn.player.mo.BringUpWeapon();
            }
            if (pawn.player.ReadyWeapon != old) pawn.TakeInventory(original, 0x7fffffff);
        }
    }
    clearscope static bool Available(int family)
    {
        if (TuinRPGHandler.ClassesEnabled() || (family != 9 && family != 10)) return false;
        string pickup = family == 9 ? "INCNA0" : "CBLDA0";
        string ready = family == 9 ? "FLMGA0" : "HETGA0";
        string projectile = family == 9 ? "IFLMA0" : "HETBA0";
        return TexMan.CheckForTexture(pickup, TexMan.Type_Any).IsValid() &&
            TexMan.CheckForTexture(ready, TexMan.Type_Any).IsValid() &&
            TexMan.CheckForTexture(projectile, TexMan.Type_Any).IsValid() &&
            TexMan.CheckForTexture("FCPUA0", TexMan.Type_Any).IsValid();
    }
    static class<Weapon> Discovery(int rarity, double roll)
    {
        if (TuinRPGHandler.ClassesEnabled() || !TuinRPGHandler.CVInt('tuin_rust_discovery', 1)) return null;
        if (rarity >= 6)
        {
            if (roll < 5 && Available(10)) return Resolve('ID24CalamityBlade');
            if (roll >= 5 && roll < 25 && Available(9)) return Resolve('ID24Incinerator');
        }
        else if (rarity >= 4 && roll < 10 && Available(9)) return Resolve('ID24Incinerator');
        return null;
    }
    static void DropFuel(Actor corpse, Actor pawn)
    {
        if (!corpse || !pawn || (!Available(9) && !Available(10))) return;
        if (!pawn.FindInventory(Resolve('ID24Incinerator')) && !pawn.FindInventory(Resolve('ID24CalamityBlade'))) return;
        if (Random[TuinRustFuel](0, 99) >= 15) return;
        // Explicit amount avoids the engine's dropped-ammo halving rules.
        let fuel = Ammo(Actor.Spawn('ID24Fuel', corpse.Pos + (0, 0, 12), NO_REPLACE));
        if (fuel) { fuel.Amount = 10; fuel.bDROPPED = false; }
    }
    static bool IsChargeState(Weapon weapon, State current)
    {
        if (!weapon || !current) return false;
        for (int stage = 0; stage < 5; stage++)
        {
            State first = stage == 0 ? weapon.FindState('Hold0') :
                stage == 1 ? weapon.FindState('Hold1') : stage == 2 ? weapon.FindState('Hold2') :
                stage == 3 ? weapon.FindState('Hold3') : weapon.FindState('Hold4');
            if (first && first.NextState && current == first.NextState.NextState) return true;
        }
        return false;
    }
}

// Refreshing burn, one outward spread only; secondary burns cannot chain forever.
class TuinWildfireBurn : Inventory
{
    Actor Source;
    int Remaining;
    int Pulses;
    int Clock;
    bool Spread;
    void Ignite(Actor source, int hitDamage, bool canSpread)
    {
        Source = source;
        Remaining = max(Remaining, max(3, hitDamage / 2));
        if (Pulses == 0) Clock = 35;
        Pulses = 3;
        Spread = Spread || canSpread;
    }
    override void Tick()
    {
        Super.Tick();
        if (!Owner || Owner.Health <= 0 || TuinRPGHandler.ClassesEnabled()) { Destroy(); return; }
        if (--Clock > 0) return;
        let handler = TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        if (!handler) return;
        Actor victim = Owner;
        if (Spread)
        {
            Spread = false;
            int count = 0;
            ThinkerIterator it = ThinkerIterator.Create('Actor');
            Actor other;
            while ((other = Actor(it.Next())) && count < 3)
            {
                if (other == victim || !TuinRPGHandler.IsValidMonster(other) ||
                    victim.Distance3D(other) > 128 || !victim.CheckSight(other, SF_IGNOREWATERBOUNDARY) ||
                    other.FindInventory('TuinWildfireBurn')) continue;
                other.GiveInventoryType('TuinWildfireBurn');
                let burn = TuinWildfireBurn(other.FindInventory('TuinWildfireBurn'));
                if (burn) { burn.Ignite(Source, Remaining * 2, false); count++; }
            }
        }
        int damage = (Remaining + Pulses - 1) / Pulses;
        Remaining -= damage;
        Pulses--;
        Clock = 35;
        bool previous = handler.ApplyingBonusDamage;
        handler.ApplyingBonusDamage = true;
        let monster = TuinMonsterData(victim.FindInventory('TuinMonsterData'));
        if (monster) monster.TraitKillSource = null;
        int before = victim.Health;
        if(!TuinRPGHandler.ClassesEnabled())
            damage=max(1,int(damage*TuinRPGHandler.NativeBossResistance(victim,Source,Source,'TuinWildfire')+.5));
        victim.DamageMobj(Source, Source, damage, 'TuinWildfire', DMG_FORCED);
        handler.ApplyingBonusDamage = previous;
        int dealt = min(before, max(0, before - victim.Health));
        if (dealt > 0 && Source && Source.player)
            handler.SpawnDamageNumber(Source.PlayerNumber(), victim, dealt, false, false, 1);
        victim.A_SpawnParticle(Color(255, 100, 20), SPF_FULLBRIGHT | SPF_FACECAMERA,
            22, 4.0, 0, 0, 0, victim.Height * 0.5, 0, 0, 0.8);
        if (Pulses <= 0 || !Owner || Owner.Health <= 0) Destroy();
    }
    Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE }
}
