class TuinMonsterData : Inventory
{
	const AFFIX_SWIFT = 1;
	const AFFIX_ARMORED = 2;
	const AFFIX_REGENERATING = 4;
	const AFFIX_BERSERKER = 8;
	const AFFIX_EXPLOSIVE = 16;
	const AFFIX_VAMPIRIC = 32;
	const AFFIX_POISONOUS = 64;
	const AFFIX_HEALER = 128;
	const AFFIX_WARDING = 256;

	int MonsterLevel;
	int MonsterRarity;
	int OriginalMaxHealth;
	int ScaledMaxHealth;
	double DamageMultiplier;
	int XPValue;
	int UniqueID;
	int LastPlayerNumber;
	int AffixFlags;
	int RegenClock;
	int SwiftClock;
	int GlowClock;
	int AppliedGlowRarity;
	int AppliedGlowRadius;
	int SupportClock;
	int WardTics;
	int HealerSelfLockTics;
	int BleedPulsesRemaining;
	int BleedNextTime;
	int BleedPlayerNumber;
	int BleedResistanceTics;
	int BleedDamageRemaining;
	int BurnPulsesRemaining;
	int BurnNextTime;
	int BurnPlayerNumber;
	int BurnDamageRemaining;
	int RPGBonusWindowEndTime;
	int RPGBonusWindowRawDamage;
	int FodderCheckTime;
	bool CrowdFodderDebuffed;
	int SignatureProfile;
	int SignatureCooldown;
	int SignatureWindup;
	bool SignatureInitialized;
	Actor SwiftLockedTarget;
	string GeneratedName;
	bool HealthDisplayInitialized;
	double PreviousDisplayHealth;
	double DisplayHealth;

	void ResetSignatureAttack()
	{
		if (Owner) Owner.A_RemoveLight('TuinSignatureTell');
		SignatureProfile = 0;
		SignatureWindup = 0;
		SignatureInitialized = false;
		SignatureCooldown = Random[TuinRPGSignature](70, 175);
	}

	int DetermineSignatureProfile()
	{
		if (!Owner) return 0;
		// Bosses and monster-summoners are intentionally left alone for map compatibility.
		if (Owner is 'Cyberdemon' || Owner is 'SpiderMastermind' || Owner is 'BossBrain' ||
			Owner is 'Archvile' || Owner is 'PainElemental' || Owner is 'LostSoul') return 0;
		if (Owner is 'ZombieMan') return 1;
		if (Owner is 'ShotgunGuy') return 2;
		if (Owner is 'ChaingunGuy' || Owner is 'WolfensteinSS') return 3;
		if (Owner is 'DoomImp') return 4;
		if (Owner is 'BaronOfHell') return 5;
		if (Owner is 'Cacodemon') return 6;
		if (Owner is 'Revenant') return 7;
		if (Owner is 'Fatso') return 8;
		if (Owner is 'Arachnotron') return 9;
		if (Owner is 'Demon') return 10;
		// Unknown custom monsters only repeat their own ranged attack or gain a physical charge.
		if (Owner.MissileState) return 11;
		if (Owner.MeleeState) return 12;
		return 0;
	}

	bool HasSignatureTarget()
	{
		return Owner && Owner.Target && Owner.Target.player && Owner.Target.Health > 0 &&
			Owner.Target.bSHOOTABLE && Owner.CheckSight(Owner.Target);
	}

	void SpawnSignatureSpread(class<Actor> projectile, int count, double totalSpread)
	{
		if (!Owner || !Owner.Target || !projectile || count <= 0) return;
		Owner.A_FaceTarget();
		for (int i = 0; i < count; i++)
		{
			double offset = count > 1 ? -totalSpread * 0.5 + totalSpread * i / (count - 1) : 0.0;
			Owner.A_SpawnProjectile(projectile, Owner.Height * 0.55, 0, offset);
		}
	}

	void PerformSignatureAttack()
	{
		if (!HasSignatureTarget()) return;
		bool mythic = MonsterRarity >= 5;
		switch (SignatureProfile)
		{
		case 1: Owner.A_PosAttack(); break; // One accurate rifle shot, never an orb volley.
		case 2: Owner.A_SPosAttackUseAtkSound(); break; // One shotgun blast.
		case 3:
			for (int i = 0; i < (mythic ? 3 : 2); i++) Owner.A_CPosAttack();
			break;
		case 4: SpawnSignatureSpread('DoomImpBall', mythic ? 3 : 2, mythic ? 18.0 : 10.0); break;
		case 5: SpawnSignatureSpread('BaronBall', 3, mythic ? 24.0 : 16.0); break;
		case 6: SpawnSignatureSpread('CacodemonBall', mythic ? 5 : 3, mythic ? 50.0 : 28.0); break;
		case 7: SpawnSignatureSpread('RevenantTracer', mythic ? 3 : 2, mythic ? 20.0 : 10.0); break;
		case 8: SpawnSignatureSpread('FatShot', mythic ? 5 : 3, mythic ? 48.0 : 28.0); break;
		case 9: SpawnSignatureSpread('ArachnotronPlasma', mythic ? 5 : 3, mythic ? 36.0 : 20.0); break;
		case 10:
		case 12:
			Owner.A_FaceTarget();
			Owner.Thrust(clamp(Owner.Speed * (mythic ? 2.25 : 1.75), 10.0, 28.0), Owner.Angle);
			break;
		case 11:
			// Preserve the custom monster's own attack instead of inventing an incompatible projectile.
			if (Owner.MissileState) Owner.SetState(Owner.MissileState);
			break;
		}
	}

	void TickSignatureAttack()
	{
		let enabledCV = CVar.FindCVar('tuin_signature_attacks_enabled');
		bool enabled = enabledCV ? enabledCV.GetBool() : true;
		if (!enabled || MonsterRarity < 4)
		{
			if (SignatureWindup > 0 && Owner) Owner.A_RemoveLight('TuinSignatureTell');
			SignatureWindup = 0;
			return;
		}
		if (!SignatureInitialized)
		{
			SignatureProfile = DetermineSignatureProfile();
			SignatureInitialized = true;
		}
		if (SignatureProfile <= 0) return;

		if (SignatureWindup > 0)
		{
			if (!HasSignatureTarget())
			{
				Owner.A_RemoveLight('TuinSignatureTell');
				SignatureWindup = 0;
				SignatureCooldown = 35;
				return;
			}
			SignatureWindup--;
			if (SignatureWindup == 0)
			{
				Owner.A_RemoveLight('TuinSignatureTell');
				PerformSignatureAttack();
				let cooldownCV = CVar.FindCVar(MonsterRarity >= 5 ? 'tuin_mythic_attack_cooldown' : 'tuin_legendary_attack_cooldown');
				double seconds = clamp(cooldownCV ? cooldownCV.GetFloat() : (MonsterRarity >= 5 ? 5.0 : 8.0), 2.0, 30.0);
				SignatureCooldown = int(seconds * 35.0) + Random[TuinRPGSignature](0, 35);
			}
			return;
		}

		if (SignatureCooldown > 0) { SignatureCooldown--; return; }
		if (!HasSignatureTarget()) return;
		double distance = Owner.Distance2D(Owner.Target);
		bool charge = SignatureProfile == 10 || SignatureProfile == 12;
		if ((charge && (distance < 96.0 || distance > 640.0)) || (!charge && (distance < 128.0 || distance > 2048.0))) return;

		let windupCV = CVar.FindCVar('tuin_signature_attack_windup');
		SignatureWindup = clamp(windupCV ? windupCV.GetInt() : 20, 8, 70);
		Color tellColor = MonsterRarity >= 5 ? Color(210, 64, 255) : Color(255, 190, 48);
		Owner.A_AttachLight('TuinSignatureTell', 1, tellColor, 32, MonsterRarity >= 5 ? 128 : 88, 0,
			(0, 0, Owner.Height * 0.5), 0.35);
	}

	void UpdateRarityGlow()
	{
		if (!Owner) return;
		let enabledCV = CVar.FindCVar('tuin_rarity_glow_enabled');
		bool enabled = enabledCV ? enabledCV.GetBool() : true;
		int desiredRarity = enabled && Owner.Health > 0 && MonsterRarity >= 2 ? MonsterRarity : 0;
		int desiredRadius = 0;
		if (desiredRarity == 2)
		{
			let radiusCV = CVar.FindCVar('tuin_rare_glow_radius');
			desiredRadius = clamp(radiusCV ? radiusCV.GetInt() : 36, 16, 128);
		}
		else if (desiredRarity == 3)
		{
			let radiusCV = CVar.FindCVar('tuin_elite_glow_radius');
			desiredRadius = clamp(radiusCV ? radiusCV.GetInt() : 52, 20, 192);
		}
		else if (desiredRarity == 4)
		{
			let radiusCV = CVar.FindCVar('tuin_legendary_glow_radius');
			desiredRadius = clamp(radiusCV ? radiusCV.GetInt() : 72, 24, 256);
		}
		else if (desiredRarity == 5)
		{
			let radiusCV = CVar.FindCVar('tuin_mythic_glow_radius');
			desiredRadius = clamp(radiusCV ? radiusCV.GetInt() : 112, 32, 320);
		}
		else if (desiredRarity == 6)
		{
			let radiusCV = CVar.FindCVar('tuin_boss_glow_radius');
			desiredRadius = clamp(radiusCV ? radiusCV.GetInt() : 160, 48, 384);
		}

		if (desiredRarity == AppliedGlowRarity && desiredRadius == AppliedGlowRadius) return;
		Owner.A_RemoveLight('TuinRarityGlow');
		AppliedGlowRarity = desiredRarity;
		AppliedGlowRadius = desiredRadius;

		if (desiredRarity == 2)
			Owner.A_AttachLight('TuinRarityGlow', 0, Color(40, 180, 255), desiredRadius, desiredRadius, 0, (0, 0, Owner.Height * 0.5));
		else if (desiredRarity == 3)
			Owner.A_AttachLight('TuinRarityGlow', 0, Color(255, 104, 24), desiredRadius, desiredRadius, 0, (0, 0, Owner.Height * 0.5));
		else if (desiredRarity == 4)
			Owner.A_AttachLight('TuinRarityGlow', 0, Color(255, 170, 32), desiredRadius, desiredRadius, 0, (0, 0, Owner.Height * 0.5));
		else if (desiredRarity == 5)
			Owner.A_AttachLight('TuinRarityGlow', 1, Color(190, 40, 255), desiredRadius * 2 / 3, desiredRadius, 0, (0, 0, Owner.Height * 0.5), 1.0);
		else if (desiredRarity == 6)
			Owner.A_AttachLight('TuinRarityGlow', 1, Color(255, 24, 64), desiredRadius * 2 / 3, desiredRadius, 0, (0, 0, Owner.Height * 0.5), 0.55);
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)
	{
		if (passive && newdamage > 0 && !(flags & DMG_FORCED) && Owner &&
			(Owner is 'Cyberdemon' || Owner is 'SpiderMastermind') &&
			TuinRPGHandler.IsBFGDamage(inflictor, source, damageType))
			newdamage = max(1, int(newdamage * 0.25 + 0.5));
		if (passive && newdamage > 0 && !(flags & DMG_FORCED) && (AffixFlags & AFFIX_ARMORED))
		{
			let cv = CVar.FindCVar('tuin_affix_armored_reduction');
			double reduction = clamp(cv ? cv.GetFloat() : 0.20, 0.0, 0.80);
			// Finale bosses already have a large progression-scaled health pool.
			// Give their armor a useful but less extreme effective-health bonus.
			if (MonsterRarity >= 6 && OriginalMaxHealth >= 500)
			{
				let bossCV = CVar.FindCVar('tuin_boss_armored_reduction');
				reduction = clamp(bossCV ? bossCV.GetFloat() : 0.25, 0.0, 0.50);
			}
			newdamage = max(1, int(newdamage * (1.0 - reduction) + 0.5));
		}
		if (passive && newdamage > 0 && !(flags & DMG_FORCED) && WardTics > 0)
		{
			let wardCV = CVar.FindCVar('tuin_affix_warding_reduction');
			double reduction = clamp(wardCV ? wardCV.GetFloat() : 0.15, 0.0, 0.50);
			newdamage = max(1, int(newdamage * (1.0 - reduction) + 0.5));
		}
	}

	void UpdateSupportAffixes()
	{
		if (!(AffixFlags & (AFFIX_HEALER | AFFIX_WARDING))) return;
		SupportClock++;
		if (SupportClock < 35) return;
		SupportClock = 0;
		let radiusCV = CVar.FindCVar('tuin_affix_support_radius');
		double radius = clamp(radiusCV ? radiusCV.GetFloat() : 768.0, 128.0, 2048.0);
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor ally;
		while (ally = Actor(iterator.Next()))
		{
			if (!ally.bISMONSTER || ally.bFRIENDLY || ally.Health <= 0 || Owner.Distance2D(ally) > radius ||
				!Owner.CheckSight(ally)) continue;
			let allyData = TuinMonsterData(ally.FindInventory('TuinMonsterData'));
			if (!allyData) continue;
			if (AffixFlags & AFFIX_HEALER)
			{
				let baseCV = CVar.FindCVar('tuin_affix_healer_base');
				int healing = max(0, (baseCV ? baseCV.GetInt() : 5) + MonsterLevel);
				if (ally == Owner)
					healing = HealerSelfLockTics > 0 ? 0 : max(1, int(healing * 0.25 + 0.5));
				healing = allyData.AdjustHealingReceived(healing);
				if (healing > 0) ally.A_SetHealth(min(allyData.ScaledMaxHealth, ally.Health + healing));
			}
			// Warding is an ally-support aura. It never protects its caster.
			if ((AffixFlags & AFFIX_WARDING) && ally != Owner) allyData.WardTics = 45;
		}
	}

	int AdjustHealingReceived(int healing)
	{
		if (healing <= 0) return 0;
		// Rogue Bleeding is also an anti-healing effect while active.
		if (BleedPulsesRemaining > 0) return max(1, int(healing * 0.50 + 0.5));
		return healing;
	}

	override void Tick()
	{
		Super.Tick();
		if (!Owner) return;
		if (!HealthDisplayInitialized)
		{
			PreviousDisplayHealth = Owner.Health;
			DisplayHealth = Owner.Health;
			HealthDisplayInitialized = true;
		}
		else
		{
			PreviousDisplayHealth = DisplayHealth;
			DisplayHealth += (Owner.Health - DisplayHealth) * 0.28;
			if (abs(Owner.Health - DisplayHealth) < 0.25) DisplayHealth = Owner.Health;
		}
		GlowClock++;
		if (GlowClock >= 35 || AppliedGlowRarity != MonsterRarity || Owner.Health <= 0)
		{
			GlowClock = 0;
			UpdateRarityGlow();
		}
		if (Owner.Health <= 0)
		{
			if (SignatureWindup > 0) Owner.A_RemoveLight('TuinSignatureTell');
			SignatureWindup = 0;
			return;
		}
		if (BleedResistanceTics > 0) BleedResistanceTics--;
		if (WardTics > 0) WardTics--;
		if (HealerSelfLockTics > 0) HealerSelfLockTics--;
		UpdateSupportAffixes();

		if (AffixFlags & AFFIX_SWIFT)
		{
			SwiftClock++;
			Owner.ReactionTime = 0;
			if (Owner.Target && Owner.Target.player && Owner.Target.Health > 0)
			{
				if (SwiftLockedTarget != Owner.Target)
				{
					SwiftLockedTarget = Owner.Target;
					let lockCV = CVar.FindCVar('tuin_affix_swift_lock_tics');
					Owner.A_SetChaseThreshold(clamp(lockCV ? lockCV.GetInt() : 210, 35, 1050));
				}
				let intervalCV = CVar.FindCVar('tuin_affix_swift_chase_interval');
				int interval = clamp(intervalCV ? intervalCV.GetInt() : 3, 1, 10);
				if (Owner.SeeState && Owner.CurState && Owner.CurState.InStateSequence(Owner.SeeState) && (SwiftClock % interval) == 0)
					Owner.A_FastChase();
			}
			else
			{
				SwiftLockedTarget = null;
				if ((SwiftClock & 3) == 0)
				{
					let rangeCV = CVar.FindCVar('tuin_affix_swift_sight_range');
					double sightRange = clamp(rangeCV ? rangeCV.GetFloat() : 2048.0, 128.0, 8192.0);
					Owner.A_LookEx(LOF_NOSOUNDCHECK | LOF_NOSEESOUND, 0.0, sightRange, 0.0, 0.0, 'See');
				}
			}
		}

		TickSignatureAttack();

		if (!(AffixFlags & AFFIX_REGENERATING) || ScaledMaxHealth <= 0) return;
		RegenClock++;
		if (RegenClock >= 35)
		{
			RegenClock = 0;
			if (Owner.Health < ScaledMaxHealth)
			{
				let cv = CVar.FindCVar('tuin_affix_regen_percent');
				double rate = clamp(cv ? cv.GetFloat() : 0.01, 0.001, 0.25);
				int healing = AdjustHealingReceived(max(1, int(ScaledMaxHealth * rate + 0.5)));
				Owner.A_SetHealth(min(ScaledMaxHealth, Owner.Health + healing));
			}
		}
	}

	Default
	{
		Inventory.MaxAmount 1;
		Inventory.InterHubAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNCLEARABLE
		+INVENTORY.KEEPDEPLETED
	}
}

class TuinTankOverdriveFiringSpeed : PowerDoubleFiringSpeed
{
	Default
	{
		Powerup.Duration 0x7FFFFFFF;
		Inventory.InterHubAmount 0;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNCLEARABLE
	}
}

class TuinExecutionerSkullMarker : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		Scale 0.045;
		Alpha 0.94;
		RenderStyle "Translucent";
		+NOINTERACTION
		+NOGRAVITY
		+FORCEXYBILLBOARD
		+BRIGHT
	}

	States
	{
	Spawn:
		EXSK A -1 Bright;
		Stop;
	}
}

class TuinPlayerData : Inventory
{
	class<Weapon> VariantWeaponType[64];
	int VariantID[64];
	int VariantItemLevel[64];
	int VariantQuality[64];
	int VariantAffixFlags[64];
	int VariantHastePercent[64];
	int VariantPowerPercent[64];
	int VariantLeechPercent[64];
	int VariantExecutionPercent[64];
	int VariantProsperityPercent[64];
	bool VariantEquipped[64];
	int WeaponVariantCount;
	int NextWeaponVariantID;
	int PlayerLevel;
	int CurrentXP;
	int UnspentStatPoints;
	int UnspentSkillPoints;
	int LevelDamageDealt;
	int LevelDamageTaken;
	int LevelXPEarned;
	int LevelCoinsEarned;
	int LevelEliteKills;
	int LevelBossKills;
	int LevelCriticalHits;
	int LevelAbilityUses;
	int LevelLivesUsed;
	int Lives;
	bool LivesInitialized;
	bool LifeRevivePending;
	int LifeReviveTics;
	int LifeReviveFadeTics;
	int LifeReviveQuote;
	bool LifeReviveFreezeApplied;
	bool LifeReviveWasFrozen;
	int LifeGraceTics;
	double LifeEssenceHealingPool;
	double LifeEssenceHealingRemainder;
	int LifeEssenceHealingTics;
	int PlayerClass;
	int ClassHealClock;
	int HealerSupplyCooldownTics;
	int EngineerTurretCooldownTics;
	Actor EngineerTurret;
	int PerkVitalCore;
	int PerkScavenger;
	int PerkKillerInstinct;
	int PerkIronSkin;
	int PerkBloodDrinker;
	double LeechHealingRemainder;
	int PerkClassMastery;
	bool PerkCapstone;
	int AppliedPerkHealth;
	Actor PerkHealthOwner;
	int AppliedClassHealthPenalty;
	Actor ClassHealthOwner;
	int RogueStillTics;
	int RogueCooldownTics;
	int RogueVeilTics;
	int RogueAmbushGraceTics;
	int RogueAmbushHitTime;
	int RogueVeilCharge;
	double RogueVeilChargeRemainder;
	bool RogueChargeInitialized;
	bool RogueVeiled;
	Actor RogueVeilOwner;
	int TankOverdriveCharge;
	double TankOverdriveChargeRemainder;
	bool TankChargeInitialized;
	bool TankReadyNotified;
	bool TankOverdriveActive;
	int TankOverdriveTics;
	Actor TankOverdriveOwner;
	int ExecutionerCharge;
	double ExecutionerChargeRemainder;
	bool ExecutionerReadyNotified;
	Actor ExecutionerMarkedTarget;
	Actor ExecutionerMarkVisual;
	int ExecutionerMarkTics;
	Actor ExecutionerExtraMarkedTarget[2];
	Actor ExecutionerExtraMarkVisual[2];
	int ExecutionerExtraMarkTics[2];
	bool ExecutionerRefundGranted;
	bool ExecutionerJudgmentArmed;
	int DoomBloodPunchCharge;
	double DoomBloodPunchChargeRemainder;
	bool DoomBloodPunchInitialized;
	bool DoomBloodPunchReadyNotified;
	int DoomBloodPunchFlashTics;
	bool DoomBloodPunchWeaponHidden;
	bool DoomBloodPunchHolding;
	bool DoomBloodPunchReleaseQueued;
	bool DoomBloodPunchImpactDone;
	int DoomBloodPunchPrepareTics;
	int DoomBloodPunchFistRaiseTics;
	int DoomBloodPunchAttackTics;
	double DoomBloodPunchWeaponStartY;
	class<Ammo> ClassAmmoType[32];
	int ClassAmmoLastAmount[32];
	double ClassAmmoRemainder[32];
	int ClassAmmoCount;
	int LastCampaignMapNumber;
	bool SuppressNextMapCatchup;
	int Vitality;
	int Strength;
	int Luck;
	int Agility;
	int Endurance;
	string ShopDialogue;
	string JohnDialogueMap;
	int JohnWhatNowPage;
	int JohnWhatsNextPage;
	int AppliedVitality;
	Actor VitalityOwner;
	bool FlashlightEnabled;
	Actor FlashlightOwner;
	int AppliedFlashlightRange;
	int AppliedFlashlightIntensity;
	int AppliedFlashlightPitch;
	bool AppliedFlashlightEnabled;

	clearscope int TankOverdriveDamageRequired()
	{
		return 800 + max(1, PlayerLevel) * 50;
	}

	void AddTankOverdriveCharge(int weightedDamage)
	{
		if (PlayerClass != 1 || TankOverdriveActive || weightedDamage <= 0 || TankOverdriveCharge >= 100) return;
		double exact = weightedDamage * 100.0 / TankOverdriveDamageRequired() + TankOverdriveChargeRemainder;
		int gained = int(exact);
		TankOverdriveChargeRemainder = exact - gained;
		TankOverdriveCharge = min(100, TankOverdriveCharge + gained);
		if (TankOverdriveCharge < 100) TankReadyNotified = false;
	}

	clearscope int ExecutionerDamageRequired()
	{
		return 500 + max(1, PlayerLevel) * 50;
	}

	clearscope bool HasActiveExecutionerMark()
	{
		if (ExecutionerMarkedTarget && ExecutionerMarkTics > 0) return true;
		for (int i = 0; i < 2; i++)
			if (ExecutionerExtraMarkedTarget[i] && ExecutionerExtraMarkTics[i] > 0) return true;
		return false;
	}

	void AddExecutionerCharge(int damage)
	{
		if (PlayerClass != 3 || HasActiveExecutionerMark() || damage <= 0 || ExecutionerCharge >= 100) return;
		double chargeRate = 1.0 + PerkClassMastery * 0.10;
		double exact = damage * chargeRate * 100.0 / ExecutionerDamageRequired() +
			ExecutionerChargeRemainder;
		int gained = int(exact);
		ExecutionerChargeRemainder = exact - gained;
		ExecutionerCharge = min(100, ExecutionerCharge + gained);
		if (ExecutionerCharge < 100) ExecutionerReadyNotified = false;
	}

	clearscope int DoomBloodPunchDamageRequired()
	{
		return 500 + max(1, PlayerLevel) * 40;
	}

	void AddDoomBloodPunchCharge(int damage)
	{
		if (PlayerClass != 4 || damage <= 0 || DoomBloodPunchCharge >= 100) return;
		double chargeRate = PerkCapstone ? 1.45 : 1.0 + PerkClassMastery * 0.10;
		double exact = damage * chargeRate * 100.0 / DoomBloodPunchDamageRequired() + DoomBloodPunchChargeRemainder;
		int gained = int(exact);
		DoomBloodPunchChargeRemainder = exact - gained;
		DoomBloodPunchCharge = min(100, DoomBloodPunchCharge + gained);
		if (DoomBloodPunchCharge < 100) DoomBloodPunchReadyNotified = false;
	}

	clearscope int FindEquippedVariant(class<Weapon> weaponType)
	{
		if (!weaponType) return -1;
		for (int i = 0; i < WeaponVariantCount; i++)
			if (VariantWeaponType[i] == weaponType && VariantEquipped[i]) return i;
		return -1;
	}

	clearscope int FindVariantByID(int id)
	{
		for (int i = 0; i < WeaponVariantCount; i++)
			if (VariantID[i] == id) return i;
		return -1;
	}

	clearscope int CountVariantsFor(class<Weapon> weaponType)
	{
		int count = 0;
		for (int i = 0; i < WeaponVariantCount; i++)
			if (VariantWeaponType[i] == weaponType) count++;
		return count;
	}

	bool AddWeaponVariant(int id, class<Weapon> weaponType, int itemLevel, int quality, int affixFlags,
		int haste, int power, int leech, int execution, int prosperity)
	{
		if (!weaponType || WeaponVariantCount >= 64 || CountVariantsFor(weaponType) >= 1) return false;
		if (id <= 0) id = ++NextWeaponVariantID;
		else NextWeaponVariantID = max(NextWeaponVariantID, id);
		int index = WeaponVariantCount++;
		VariantID[index] = id;
		VariantWeaponType[index] = weaponType;
		VariantItemLevel[index] = itemLevel;
		VariantQuality[index] = quality;
		VariantAffixFlags[index] = affixFlags;
		VariantHastePercent[index] = haste;
		VariantPowerPercent[index] = power;
		VariantLeechPercent[index] = leech;
		VariantExecutionPercent[index] = execution;
		VariantProsperityPercent[index] = prosperity;
		VariantEquipped[index] = FindEquippedVariant(weaponType) < 0;
		return true;
	}

	bool ReplaceWeaponVariant(int index, int id, int itemLevel, int quality, int affixFlags,
		int haste, int power, int leech, int execution, int prosperity)
	{
		if (index < 0 || index >= WeaponVariantCount) return false;
		VariantID[index] = id;
		VariantItemLevel[index] = itemLevel;
		VariantQuality[index] = quality;
		VariantAffixFlags[index] = affixFlags;
		VariantHastePercent[index] = haste;
		VariantPowerPercent[index] = power;
		VariantLeechPercent[index] = leech;
		VariantExecutionPercent[index] = execution;
		VariantProsperityPercent[index] = prosperity;
		VariantEquipped[index] = true;
		NextWeaponVariantID = max(NextWeaponVariantID, id);
		return true;
	}

	void ClearWeaponVariants()
	{
		WeaponVariantCount = 0;
		NextWeaponVariantID = 0;
		for (int i = 0; i < 64; i++)
		{
			VariantID[i] = 0;
			VariantWeaponType[i] = null;
			VariantEquipped[i] = false;
		}
	}

	bool EquipWeaponVariant(int id)
	{
		int selected = FindVariantByID(id);
		if (selected < 0) return false;
		class<Weapon> weaponType = VariantWeaponType[selected];
		for (int i = 0; i < WeaponVariantCount; i++)
			if (VariantWeaponType[i] == weaponType) VariantEquipped[i] = i == selected;
		return true;
	}

	bool RemoveWeaponVariant(int id)
	{
		int selected = FindVariantByID(id);
		if (selected < 0) return false;
		class<Weapon> weaponType = VariantWeaponType[selected];
		bool wasEquipped = VariantEquipped[selected];
		for (int i = selected; i < WeaponVariantCount - 1; i++)
		{
			VariantID[i] = VariantID[i + 1]; VariantWeaponType[i] = VariantWeaponType[i + 1];
			VariantItemLevel[i] = VariantItemLevel[i + 1]; VariantQuality[i] = VariantQuality[i + 1];
			VariantAffixFlags[i] = VariantAffixFlags[i + 1]; VariantHastePercent[i] = VariantHastePercent[i + 1];
			VariantPowerPercent[i] = VariantPowerPercent[i + 1]; VariantLeechPercent[i] = VariantLeechPercent[i + 1];
			VariantExecutionPercent[i] = VariantExecutionPercent[i + 1]; VariantProsperityPercent[i] = VariantProsperityPercent[i + 1];
			VariantEquipped[i] = VariantEquipped[i + 1];
		}
		WeaponVariantCount--;
		VariantID[WeaponVariantCount] = 0; VariantWeaponType[WeaponVariantCount] = null; VariantEquipped[WeaponVariantCount] = false;
		if (wasEquipped)
		{
			for (int i = 0; i < WeaponVariantCount; i++)
			{
				if (VariantWeaponType[i] == weaponType)
				{
					VariantEquipped[i] = true;
					break;
				}
			}
		}
		return true;
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)
	{
		// The active pass belongs to the attacker's inventory. Apply the Tank's
		// weapon-output rule here so both stock and custom weapons use the same
		// reliable 50% / 125% factors before the hit reaches its target.
		if (!passive && PlayerClass == 1 && newdamage > 0 && damageType != 'TuinBleed' &&
			damageType != 'TuinRocketBurn' && damageType != 'TuinPlasmaArc')
			newdamage = max(1, int(newdamage * (TankOverdriveActive ? 1.25 : 0.50) + 0.5));
		if (passive && newdamage > 0 && !(flags & DMG_FORCED))
		{
			double multiplier = 1.0;
			if (Endurance > 0) multiplier *= 1.0 - clamp(Endurance * 0.01, 0.0, 0.75);
			if (PerkIronSkin > 0) multiplier *= 1.0 - clamp(PerkIronSkin * 0.03, 0.0, 0.25);
			if (PlayerClass == 1) multiplier *= 0.50;
			else if (PlayerClass == 4) multiplier *= 0.90;
			if (PlayerClass == 1 && PerkClassMastery > 0)
				multiplier *= 1.0 - clamp(PerkClassMastery * 0.03, 0.0, 0.20);
			if (PlayerClass == 1 && PerkCapstone && Owner && Owner.Health * 100 <= Owner.GetMaxHealth(true) * 30)
				multiplier *= 0.75;
			newdamage = max(1, int(newdamage * multiplier + 0.5));
			if (PlayerClass == 1 && Owner)
			{
				bool directHit = (inflictor || source) && damageType != 'Poison' && damageType != 'TuinBleed' &&
					damageType != 'Telefrag' && damageType != 'Crush';
				if (directHit)
				{
					int maximumHit = max(1, int(Owner.GetMaxHealth(true) * 0.20 + 0.5));
					newdamage = min(newdamage, maximumHit);
				}
				AddTankOverdriveCharge(min(newdamage, max(0, Owner.Health)) * 4);
			}
		}
		if (passive && Owner && Owner.player && newdamage > 0)
		{
			if (LifeRevivePending || LifeGraceTics > 0)
			{
				newdamage = 0;
			}
			else if (Lives > 0 && Owner.Health > 0 && newdamage >= Owner.Health)
			{
				Lives--;
				LevelLivesUsed++;
				LifeRevivePending = true;
				LifeReviveTics = 147;
				LifeReviveQuote = Random[TuinLifeReviveQuote](0, 4);
				newdamage = max(0, Owner.Health - 1);
			}
		}
	}
	Default
	{
		Inventory.MaxAmount 1;
		Inventory.InterHubAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNCLEARABLE
		+INVENTORY.KEEPDEPLETED
	}
}

// A real PSprite provider keeps Blood Punch in the same first-person render
// path as weapons. The handler places one of these states on a temporary
// overlay layer without changing the player's equipped weapon.
class TuinBloodPunchOverlayWeapon : Weapon
{
	Default
	{
		Inventory.MaxAmount 0;
		Weapon.SelectionOrder 0;
		+INVENTORY.UNDROPPABLE;
	}

	States
	{
	ProjectSIDEReady:
		PKFS A -1;
		Stop;
	ProjectSIDEPunch:
		PKFS LBCD 1;
		PKFS E 2 Bright;
		PKFS FGHI 2;
		PKFS JKL 1;
		PKFS A 5;
		Stop;
	Enhanced:
		PUN3 A 1 Bright;
		PUN3 B 1 Bright;
		PUN3 D 2 Bright;
		PUN3 E 2 Bright;
		PUN3 G 1 Bright;
		PUN3 H 1 Bright;
		Stop;
	Classic:
		PUNG B 2 Bright;
		PUNG C 2 Bright;
		PUNG D 2 Bright;
		PUNG C 1 Bright;
		PUNG B 1 Bright;
		Stop;
	}
}
