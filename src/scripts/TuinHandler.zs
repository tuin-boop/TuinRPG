class TuinRPGHandler : EventHandler
{
	const TUIN_MAX_PLAYERS = 8;
	const TUIN_MAX_OVERHEAD_BARS = 32;
	const TUIN_MAX_DAMAGE_NUMBERS = 64;
	const TUIN_DAMAGE_NUMBER_LIFETIME = 42;
	const TUIN_MAX_ROGUE_WANDERERS = 128;
	const TUIN_MAX_TRACKED_GRENADES = 64;
	int NextMonsterID;
	int MapsVisited;
	int PreviousLoadedCampaignMap;
	int CurrentLoadedCampaignMap;
	bool CatchupHandled[TUIN_MAX_PLAYERS];
	bool ApplyingBonusDamage;
	int NextLootID;
	bool FinaleBossPromoted;
	Actor FinaleBoss;
	TuinJohnShopNPC JohnMerchant;
	int EpisodeTravelTics;
	bool EpisodeTravelShowsIntermission;
	int AppliedDifficultyMode;
	bool MonsterLevelsSynchronized;
	int DirectorCheckpoint;
	int DirectorDamageTaken[TUIN_MAX_PLAYERS];
	Vector3 DirectorTrailPosition[TUIN_MAX_PLAYERS];
	bool DirectorTrailValid[TUIN_MAX_PLAYERS];
	int EpisodeTravelPlayer;
	string EpisodeTravelDestination;
	bool UseHeld[TUIN_MAX_PLAYERS];
	TuinWeaponDrop TargetWeaponDrop[TUIN_MAX_PLAYERS];
	int WeaponDropTargetGrace[TUIN_MAX_PLAYERS];
	string LootNotification[TUIN_MAX_PLAYERS];
	int LootNotificationTics[TUIN_MAX_PLAYERS];
	int LootNotificationQuality[TUIN_MAX_PLAYERS];
	string DifficultyNoticeTitle[TUIN_MAX_PLAYERS];
	string DifficultyNoticeStats[TUIN_MAX_PLAYERS];
	int DifficultyNoticeTics[TUIN_MAX_PLAYERS];
	string TargetName[TUIN_MAX_PLAYERS];
	string TargetAffixes[TUIN_MAX_PLAYERS];
	int TargetLevel[TUIN_MAX_PLAYERS];
	int TargetRarity[TUIN_MAX_PLAYERS];
	int TargetHealth[TUIN_MAX_PLAYERS];
	int TargetMaxHealth[TUIN_MAX_PLAYERS];
	double TargetPreviousDisplayHealth[TUIN_MAX_PLAYERS];
	double TargetDisplayHealth[TUIN_MAX_PLAYERS];
	int PopupXP[TUIN_MAX_PLAYERS];
	int PopupTics[TUIN_MAX_PLAYERS];
	int CriticalPopupTics[TUIN_MAX_PLAYERS];
	Actor DamageNumberVictim[TUIN_MAX_DAMAGE_NUMBERS];
	Vector3 DamageNumberPosition[TUIN_MAX_DAMAGE_NUMBERS];
	int DamageNumberAmount[TUIN_MAX_DAMAGE_NUMBERS];
	int DamageNumberTics[TUIN_MAX_DAMAGE_NUMBERS];
	int DamageNumberPlayer[TUIN_MAX_DAMAGE_NUMBERS];
	bool DamageNumberCritical[TUIN_MAX_DAMAGE_NUMBERS];
	bool DamageNumberBleed[TUIN_MAX_DAMAGE_NUMBERS];
	double DamageNumberCurl[TUIN_MAX_DAMAGE_NUMBERS];
	int NextDamageNumber;
	Actor RogueWanderActor[TUIN_MAX_ROGUE_WANDERERS];
	int RogueWanderPlayer[TUIN_MAX_ROGUE_WANDERERS];
	int NextRogueWanderer;
	Actor TrackedGrenade[TUIN_MAX_TRACKED_GRENADES];
	Vector3 TrackedGrenadePosition[TUIN_MAX_TRACKED_GRENADES];
	Actor TrackedGrenadeSource[TUIN_MAX_TRACKED_GRENADES];
	bool TrackedGrenadeActive[TUIN_MAX_TRACKED_GRENADES];
	bool TrackedGrenadeImpactApplied[TUIN_MAX_TRACKED_GRENADES];
	int NextTrackedGrenade;
	int PoisonTics[TUIN_MAX_PLAYERS];
	int PoisonDamage[TUIN_MAX_PLAYERS];
	Actor PoisonSource[TUIN_MAX_PLAYERS];
	Actor GodlyGlowOwner[TUIN_MAX_PLAYERS];
	bool GodlyGlowApplied[TUIN_MAX_PLAYERS];
	int GodlyGlowQuality[TUIN_MAX_PLAYERS];
	double AgilityAccumulator[TUIN_MAX_PLAYERS];
	int OverheadCount;
	Actor OverheadActor[TUIN_MAX_OVERHEAD_BARS];
	Vector3 OverheadPosition[TUIN_MAX_OVERHEAD_BARS];
	double OverheadDistance[TUIN_MAX_OVERHEAD_BARS];
	int OverheadHealth[TUIN_MAX_OVERHEAD_BARS];
	int OverheadMaxHealth[TUIN_MAX_OVERHEAD_BARS];
	double OverheadPreviousDisplayHealth[TUIN_MAX_OVERHEAD_BARS];
	double OverheadDisplayHealth[TUIN_MAX_OVERHEAD_BARS];
	int OverheadLevel[TUIN_MAX_OVERHEAD_BARS];
	int OverheadRarity[TUIN_MAX_OVERHEAD_BARS];
	string OverheadName[TUIN_MAX_OVERHEAD_BARS];
	string OverheadAffixes[TUIN_MAX_OVERHEAD_BARS];
	bool OverheadBleeding[TUIN_MAX_OVERHEAD_BARS];

	const WEAPON_AFFIX_HASTE = 1;
	const WEAPON_AFFIX_POWER = 2;
	const WEAPON_AFFIX_LEECH = 4;
	const WEAPON_AFFIX_EXECUTION = 8;
	const WEAPON_AFFIX_PROSPERITY = 16;
	const WEAPON_AFFIX_CRITICAL = 32;
	const TUIN_LEAD_SPITTER_QUALITY = 7;

	clearscope static int CVInt(Name key, int fallback = 0)
	{
		let cv = CVar.FindCVar(key);
		return cv ? cv.GetInt() : fallback;
	}

	clearscope static double CVFloat(Name key, double fallback = 0.0)
	{
		let cv = CVar.FindCVar(key);
		return cv ? cv.GetFloat() : fallback;
	}

	clearscope static int DifficultyMode()
	{
		return clamp(CVInt('tuin_difficulty', 2), 0, 3);
	}

	clearscope static double DifficultyHealthLevelFactor()
	{
		return 1.0;
	}

	clearscope static double DifficultyDamageLevelFactor()
	{
		return 1.0;
	}

	clearscope static double DifficultyRarityChanceFactor()
	{
		return 1.0;
	}

	clearscope static double DifficultyPlayerLevelInfluence()
	{
		switch (DifficultyMode())
		{
		case 0: return 0.25;
		case 1: return 0.50;
		case 3: return 0.80;
		default: return 0.65;
		}
	}

	clearscope static double DifficultyHealthPowerFactor()
	{
		switch (DifficultyMode())
		{
		case 0: return 0.55;
		case 1: return 0.75;
		case 3: return 1.30;
		default: return 1.00;
		}
	}

	clearscope static double DifficultyDamagePowerFactor()
	{
		switch (DifficultyMode())
		{
		case 0: return 0.65;
		case 1: return 0.80;
		case 3: return 1.20;
		default: return 1.00;
		}
	}

	clearscope static int DifficultyAffixMaximum()
	{
		switch (DifficultyMode())
		{
		case 0: return 2;
		case 1: return 3;
		case 3: return 8;
		default: return 5;
		}
	}

	clearscope static double ScaleHealthPower(double multiplier)
	{
		return 1.0 + (multiplier - 1.0) * DifficultyHealthPowerFactor();
	}

	clearscope static double ScaleDamagePower(double multiplier)
	{
		return 1.0 + (multiplier - 1.0) * DifficultyDamagePowerFactor();
	}

	clearscope static bool IsValidMonster(Actor mo)
	{
		return mo && mo.bISMONSTER && mo.bSHOOTABLE && !mo.bFRIENDLY && mo.Health > 0;
	}

	clearscope static TuinMonsterData GetMonsterData(Actor mo)
	{
		if (!mo) return null;
		return TuinMonsterData(mo.FindInventory('TuinMonsterData'));
	}

	clearscope static TuinPlayerData GetPlayerData(Actor mo)
	{
		if (!mo) return null;
		return TuinPlayerData(mo.FindInventory('TuinPlayerData'));
	}

	clearscope static int CoinBalance(Actor pawn)
	{
		let coins = pawn ? Inventory(pawn.FindInventory('TuinCoinPickup')) : null;
		return coins ? coins.Amount : 0;
	}

	clearscope static string PlayerClassName(int playerClass)
	{
		switch (playerClass)
		{
		case 1: return "TANK";
		case 2: return "HEALER";
		case 3: return "DAMAGE DEALER";
		case 4: return "DOOM GUY";
		case 5: return "ROGUE";
		default: return "UNSELECTED";
		}
	}

	clearscope static int RogueVeilDuration(TuinPlayerData data)
	{
		return 210 + (data ? data.PerkClassMastery : 0) * 70;
	}

	clearscope static int RogueChargeDamageRequired(TuinPlayerData data)
	{
		return 400 + max(1, data ? data.PlayerLevel : 1) * 60;
	}

	clearscope static int TankOverdriveDuration()
	{
		return 350;
	}

	void AddTankDamageCharge(int playerNumber, TuinPlayerData data, int damage)
	{
		if (!data || data.PlayerClass != 1 || data.TankOverdriveActive || damage <= 0) return;
		int oldCharge = data.TankOverdriveCharge;
		data.AddTankOverdriveCharge(damage);
		if (oldCharge < 100 && data.TankOverdriveCharge >= 100)
		{
			data.TankReadyNotified = true;
			SetLootNotification(playerNumber, "OVERDRIVE READY - PRESS V", 4);
		}
	}

	void AddRogueDamageCharge(int playerNumber, TuinPlayerData data, int damage)
	{
		if (!data || data.PlayerClass != 5 || damage <= 0 || data.RogueVeilCharge >= 100) return;
		double exact = damage * 100.0 / RogueChargeDamageRequired(data) *
			(1.0 + data.PerkClassMastery * 0.15) + data.RogueVeilChargeRemainder;
		int gained = int(exact);
		data.RogueVeilChargeRemainder = exact - gained;
		int oldCharge = data.RogueVeilCharge;
		data.RogueVeilCharge = min(100, data.RogueVeilCharge + gained);
		if (oldCharge < 100 && data.RogueVeilCharge >= 100)
			SetLootNotification(playerNumber, "SHADOW VEIL READY", 4);
	}

	void AddDoomBloodPunchCharge(int playerNumber, TuinPlayerData data, int damage)
	{
		if (!data || data.PlayerClass != 4 || damage <= 0 || data.DoomBloodPunchCharge >= 100) return;
		int oldCharge = data.DoomBloodPunchCharge;
		data.AddDoomBloodPunchCharge(damage);
		if (oldCharge < 100 && data.DoomBloodPunchCharge >= 100)
		{
			data.DoomBloodPunchReadyNotified = true;
			SetLootNotification(playerNumber, "BLOOD PUNCH READY - HOLD V", 4);
		}
	}

	TuinPlayerData EnsurePlayerData(int playerNumber)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS) return null;
		if (!playerInGame[playerNumber] || !players[playerNumber].mo) return null;
		Actor pawn = players[playerNumber].mo;
		let data = GetPlayerData(pawn);
		if (!data)
		{
			pawn.GiveInventory('TuinPlayerData', 1);
			data = GetPlayerData(pawn);
			if (data)
			{
				data.PlayerLevel = 1;
				data.CurrentXP = 0;
			}
		}
		ApplyVitality(pawn, data);
		ApplyPerkHealth(pawn, data);
		ApplyClassHealth(pawn, data);
		return data;
	}

	clearscope static int XPRequired(int playerLevel)
	{
		double baseXP = max(1.0, CVFloat('tuin_xp_base', 100.0));
		double exponent = max(1.0, CVFloat('tuin_xp_exponent', 1.5));
		return max(1, int(baseXP * exp(log(double(max(1, playerLevel))) * exponent) + 0.5));
	}

	static void ApplyVitality(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data) return;
		let pp = PlayerPawn(pawn);
		if (!pp) return;
		if (data.VitalityOwner != pawn)
		{
			data.VitalityOwner = pawn;
			data.AppliedVitality = 0;
		}
		int delta = data.Vitality - data.AppliedVitality;
		if (delta != 0)
		{
			pp.Stamina += delta * 5;
			if (delta > 0) pawn.A_SetHealth(pawn.Health + delta * 5);
			data.AppliedVitality = data.Vitality;
		}
	}

	static void ApplyClassHealth(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data) return;
		let pp = PlayerPawn(pawn);
		if (!pp) return;
		if (data.ClassHealthOwner != pawn)
		{
			data.ClassHealthOwner = pawn;
			data.AppliedClassHealthPenalty = 0;
		}
		int unmodifiedMaximum = max(1, pawn.GetMaxHealth(true) + data.AppliedClassHealthPenalty);
		int baseMaximum = max(1, unmodifiedMaximum - data.AppliedVitality * 5 - data.AppliedPerkHealth);
		int desiredModifier = data.PlayerClass == 1 ? 300 - baseMaximum :
			data.PlayerClass == 3 ? -max(1, int(unmodifiedMaximum * 0.25 + 0.5)) :
			data.PlayerClass == 5 ? -max(1, int(unmodifiedMaximum * 0.20 + 0.5)) : 0;
		int currentModifier = -data.AppliedClassHealthPenalty;
		int delta = desiredModifier - currentModifier;
		if (delta != 0)
		{
			pp.Stamina += delta;
			data.AppliedClassHealthPenalty = -desiredModifier;
			if (delta > 0) pawn.A_SetHealth(pawn.Health + delta);
			if (pawn.Health > pawn.GetMaxHealth(true)) pawn.A_SetHealth(pawn.GetMaxHealth(true));
		}
	}

	static void ApplyPerkHealth(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data) return;
		let pp = PlayerPawn(pawn);
		if (!pp) return;
		if (data.PerkHealthOwner != pawn)
		{
			data.PerkHealthOwner = pawn;
			data.AppliedPerkHealth = 0;
		}
		int desired = data.PerkVitalCore * 10;
		int delta = desired - data.AppliedPerkHealth;
		if (delta != 0)
		{
			pp.Stamina += delta;
			if (delta > 0) pawn.A_SetHealth(pawn.Health + delta);
			data.AppliedPerkHealth = desired;
		}
	}

	void ApplyClassAmmoBonus(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		double rate = (data.PlayerClass == 1 ? 0.50 : data.PlayerClass == 2 ? 0.25 : 0.0) +
			data.PerkScavenger * 0.10;
		if (rate <= 0.0) return;
		for (Inventory item = pawn.Inv; item; item = item.Inv)
		{
			let ammo = Ammo(item);
			if (!ammo) continue;
			class<Ammo> ammoType = (class<Ammo>)(ammo.GetClass());
			int index = -1;
			for (int i = 0; i < data.ClassAmmoCount; i++)
				if (data.ClassAmmoType[i] == ammoType) { index = i; break; }
			if (index < 0)
			{
				if (data.ClassAmmoCount >= 32) continue;
				index = data.ClassAmmoCount++;
				data.ClassAmmoType[index] = ammoType;
				data.ClassAmmoLastAmount[index] = 0;
				data.ClassAmmoRemainder[index] = 0.0;
			}
			int gained = ammo.Amount - data.ClassAmmoLastAmount[index];
			if (gained > 0 && ammo.Amount < ammo.MaxAmount)
			{
				double exactBonus = gained * rate + data.ClassAmmoRemainder[index];
				int bonus = int(exactBonus);
				data.ClassAmmoRemainder[index] = exactBonus - bonus;
				if (bonus > 0) ammo.Amount = min(ammo.MaxAmount, ammo.Amount + bonus);
			}
			data.ClassAmmoLastAmount[index] = ammo.Amount;
		}
	}

	void ApplyClassRegeneration(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass == 0) return;
		data.ClassHealClock++;
		if (data.PlayerClass == 2 && data.ClassHealClock >= 70)
		{
			data.ClassHealClock = 0;
			int healing = (5 + data.PerkClassMastery) * (data.PerkCapstone ? 2 : 1);
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
			{
				if (!playerInGame[i] || !players[i].mo || players[i].mo.Health <= 0) continue;
				Actor teammate = players[i].mo;
				teammate.A_SetHealth(min(teammate.GetMaxHealth(true), teammate.Health + healing));
			}
		}
		else if (data.PlayerClass == 4 && data.ClassHealClock >= 350)
		{
			data.ClassHealClock = 0;
			if (pawn.Health > 0) pawn.A_SetHealth(min(pawn.GetMaxHealth(true), pawn.Health + 1));
		}
	}

	void BreakRogueVeil(int playerNumber, TuinPlayerData data, bool preserveAmbush = false)
	{
		if (!data || !data.RogueVeiled) return;
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		data.RogueVeiled = false;
		data.RogueVeilTics = 0;
		data.RogueStillTics = 0;
		data.RogueCooldownTics = 0;
		data.RogueVeilCharge = 0;
		data.RogueVeilChargeRemainder = 0.0;
		// Preserve the ambush until the weapon reaches its actual damage frame.
		// Slow custom fists often connect well after the attack button is pressed.
		if (preserveAmbush) data.RogueAmbushGraceTics = 70;
		if (pawn)
		{
			pawn.bNOTARGET = false;
			pawn.A_SetRenderStyle(1.0, Style_Normal);
		}
		for (int i = 0; i < TUIN_MAX_ROGUE_WANDERERS; i++)
			if (RogueWanderPlayer[i] == playerNumber) RogueWanderActor[i] = null;
	}

	void TrackRogueWanderer(int playerNumber, Actor monster)
	{
		if (!monster) return;
		for (int i = 0; i < TUIN_MAX_ROGUE_WANDERERS; i++)
			if (RogueWanderActor[i] == monster && RogueWanderPlayer[i] == playerNumber) return;
		int slot = NextRogueWanderer;
		NextRogueWanderer = (NextRogueWanderer + 1) % TUIN_MAX_ROGUE_WANDERERS;
		RogueWanderActor[slot] = monster;
		RogueWanderPlayer[slot] = playerNumber;
	}

	void MaintainRogueDisengagement(int playerNumber, Actor pawn)
	{
		if (!pawn) return;
		foreach (sector: level.Sectors)
		{
			for (Actor actor = sector.thinglist; actor; actor = actor.snext)
			{
				if (!actor.bISMONSTER || actor.bFRIENDLY || actor.Health <= 0) continue;
				bool wasHuntingRogue = actor.Target == pawn || actor.Tracer == pawn ||
					actor.LastHeard == pawn || actor.LastEnemy == pawn;
				if (!wasHuntingRogue) continue;
				if (actor.Target == pawn) actor.Target = null;
				if (actor.Tracer == pawn) actor.Tracer = null;
				if (actor.LastHeard == pawn) actor.LastHeard = null;
				if (actor.LastEnemy == pawn) actor.LastEnemy = null;
				actor.SetIdle();
				actor.A_Wander();
				TrackRogueWanderer(playerNumber, actor);
			}
		}
		// Monsters which lost the Rogue continue roaming instead of freezing in place.
		for (int i = 0; i < TUIN_MAX_ROGUE_WANDERERS; i++)
		{
			Actor wanderer = RogueWanderActor[i];
			if (!wanderer || RogueWanderPlayer[i] != playerNumber) continue;
			if (wanderer.Health <= 0 || wanderer.Target)
			{
				RogueWanderActor[i] = null;
				continue;
			}
			if (((level.Time + i) & 7) == 0) wanderer.A_Wander();
		}
	}

	void ActivateRogueVeil(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 5 || data.RogueVeilCharge < 100) return;
		data.RogueVeiled = true;
		data.RogueVeilTics = 0;
		data.RogueStillTics = 0;
		data.RogueAmbushHitTime = -1;
		pawn.bNOTARGET = true;
		pawn.A_SetRenderStyle(0.50, Style_Translucent);
		MaintainRogueDisengagement(playerNumber, pawn);
		SetLootNotification(playerNumber, "SHADOW VEIL - NEXT ATTACK IS AN AMBUSH", 4);
	}

	void ApplyRogueStealth(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		if (!data.RogueChargeInitialized)
		{
			data.RogueChargeInitialized = true;
			data.RogueVeilCharge = 100;
			data.RogueCooldownTics = 0;
		}
		if (data.RogueVeilOwner != pawn)
		{
			data.RogueVeilOwner = pawn;
			data.RogueVeiled = false;
			data.RogueVeilTics = 0;
			data.RogueStillTics = 0;
			data.RogueAmbushGraceTics = 0;
			data.RogueAmbushHitTime = -1;
		}
		if (data.PlayerClass != 5)
		{
			if (data.RogueVeiled) BreakRogueVeil(playerNumber, data);
			return;
		}
		bool attacking = (players[playerNumber].cmd.buttons & (BT_ATTACK | BT_ALTATTACK)) != 0;
		if (data.RogueAmbushGraceTics > 0) data.RogueAmbushGraceTics--;
		if (data.RogueVeiled)
		{
			data.RogueVeilTics++;
			MaintainRogueDisengagement(playerNumber, pawn);
			if (attacking) BreakRogueVeil(playerNumber, data, true);
			else if (data.RogueVeilTics >= RogueVeilDuration(data)) BreakRogueVeil(playerNumber, data);
			return;
		}
		data.RogueStillTics = 0;
	}

	void ActivateTankOverdrive(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 1 || data.TankOverdriveActive || data.TankOverdriveCharge < 100) return;
		data.TankOverdriveActive = true;
		data.TankOverdriveTics = TankOverdriveDuration();
		data.TankOverdriveCharge = 100;
		data.TankReadyNotified = true;
		data.TankOverdriveChargeRemainder = 0.0;
		pawn.A_RemoveLight('TuinTankOverdriveGlow');
		pawn.GiveInventory('TuinTankOverdriveFiringSpeed', 1);
		pawn.A_AttachLight('TuinTankOverdriveGlow', DynamicLight.PulseLight, Color(255, 24, 8), 62, 128,
			DynamicLight.LF_ATTENUATE, (0, 0, pawn.Height * 0.52), 0.45);
		SetLootNotification(playerNumber, "TANK OVERDRIVE - 10 SECONDS", 5);
	}

	void ApplyTankOverdrive(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		if (!data.TankChargeInitialized)
		{
			data.TankChargeInitialized = true;
			data.TankOverdriveCharge = 0;
		}
		if (data.TankOverdriveOwner != pawn)
		{
			bool interrupted = data.TankOverdriveActive;
			if (data.TankOverdriveOwner)
			{
				data.TankOverdriveOwner.A_RemoveLight('TuinTankOverdriveGlow');
				data.TankOverdriveOwner.TakeInventory('TuinTankOverdriveFiringSpeed', 1);
			}
			data.TankOverdriveOwner = pawn;
			data.TankOverdriveActive = false;
			data.TankOverdriveTics = 0;
			if (interrupted)
			{
				data.TankOverdriveCharge = 0;
				data.TankOverdriveChargeRemainder = 0.0;
				data.TankReadyNotified = false;
			}
		}
		if (data.PlayerClass != 1 || pawn.Health <= 0)
		{
			pawn.TakeInventory('TuinTankOverdriveFiringSpeed', 1);
			if (data.TankOverdriveActive || data.TankOverdriveTics > 0)
			{
				data.TankOverdriveActive = false;
				data.TankOverdriveTics = 0;
				data.TankOverdriveCharge = 0;
				data.TankOverdriveChargeRemainder = 0.0;
				data.TankReadyNotified = false;
				pawn.A_RemoveLight('TuinTankOverdriveGlow');
			}
			return;
		}
		if (!data.TankOverdriveActive)
		{
			if (data.TankOverdriveCharge >= 100 && !data.TankReadyNotified)
			{
				data.TankReadyNotified = true;
				SetLootNotification(playerNumber, "OVERDRIVE READY - PRESS V", 4);
			}
			return;
		}
		if (!pawn.FindInventory('TuinTankOverdriveFiringSpeed'))
			pawn.GiveInventory('TuinTankOverdriveFiringSpeed', 1);
		data.TankOverdriveTics--;
		if (data.TankOverdriveTics <= 0)
		{
			data.TankOverdriveActive = false;
			data.TankOverdriveTics = 0;
			data.TankOverdriveCharge = 0;
			data.TankOverdriveChargeRemainder = 0.0;
			data.TankReadyNotified = false;
			pawn.A_RemoveLight('TuinTankOverdriveGlow');
			pawn.TakeInventory('TuinTankOverdriveFiringSpeed', 1);
			SetLootNotification(playerNumber, "OVERDRIVE ENDED - BUILD CHARGE", 0);
		}
	}

	void SpawnBloodPunchCone(Actor pawn)
	{
		if (!pawn) return;
		for (int angleStep = -50; angleStep <= 50; angleStep += 20)
		{
			double particleAngle = pawn.Angle + angleStep;
			for (int distance = 28; distance <= 224; distance += 28)
			{
				double spread = 0.20 + distance / 224.0;
				pawn.A_SpawnParticle((distance / 28) & 1 ? Color(255, 24, 8) : Color(190, 0, 0),
					SPF_FULLBRIGHT | SPF_FACECAMERA, 13, 7.0 + spread * 5.0, 0,
					cos(particleAngle) * distance, sin(particleAngle) * distance,
					pawn.Height * (0.60 + spread * 0.15),
					cos(particleAngle) * 2.8, sin(particleAngle) * 2.8, 0.25,
					0, 0, 0.04, 0.90, 0.09, 0.30);
			}
		}
	}

	void SpawnBloodPunchImpact(Actor victim)
	{
		if (!victim) return;
		for (int i = 0; i < 10; i++)
		{
			double particleAngle = i * 36.0;
			victim.A_SpawnParticle(Color(255, 35, 12), SPF_FULLBRIGHT | SPF_FACECAMERA,
				12, 5.0, 0, 0, 0, victim.Height * 0.55,
				cos(particleAngle) * 4.5, sin(particleAngle) * 4.5,
				1.0 + (i & 3) * 0.5, 0, 0, -0.12, 1.0, 0.08, -0.20);
		}
	}

	void ShowDoomBloodPunchReadyFists(Actor pawn)
	{
		if (!pawn || !pawn.player) return;
		let punchProvider = GetDefaultByType('TuinBloodPunchOverlayWeapon');
		// Use the actual weapon layer so ProjectSIDE's fist sprite offsets are
		// interpreted in normal 320x200 weapon space. A generic overlay layer
		// anchors these wide sprites at the screen edge instead.
		pawn.player.SetPsprite(PSP_WEAPON, punchProvider.FindState('ProjectSIDEReady'));
		let fistSprite = pawn.player.FindPSprite(PSP_WEAPON);
		if (fistSprite)
		{
			fistSprite.x = 0;
			fistSprite.y = WEAPONBOTTOM;
			fistSprite.ResetInterpolation();
		}
	}

	void RestoreDoomBloodPunchWeapon(Actor pawn, TuinPlayerData data, bool raiseWeapon = true)
	{
		if (!pawn || !data) return;
		if (pawn.player)
		{
			pawn.player.SetPsprite(90, null);
			pawn.player.SetPsprite(PSP_FLASH, null);
			if (data.DoomBloodPunchWeaponHidden)
			{
				if (raiseWeapon && pawn.Health > 0 && pawn.player.ReadyWeapon)
				{
					pawn.player.SetPsprite(PSP_WEAPON, pawn.player.ReadyWeapon.GetUpState());
					let raisedSprite = pawn.player.FindPSprite(PSP_WEAPON);
					if (raisedSprite)
					{
						raisedSprite.y = WEAPONBOTTOM;
						raisedSprite.alpha = 1.0;
						raisedSprite.ResetInterpolation();
					}
				}
				else pawn.player.SetPsprite(PSP_WEAPON, null);
			}
			else
			{
				let weaponSprite = pawn.player.FindPSprite(PSP_WEAPON);
				if (weaponSprite)
				{
					weaponSprite.y = data.DoomBloodPunchWeaponStartY;
					weaponSprite.alpha = 1.0;
					weaponSprite.ResetInterpolation();
				}
			}
		}
		data.DoomBloodPunchHolding = false;
		data.DoomBloodPunchReleaseQueued = false;
		data.DoomBloodPunchImpactDone = false;
		data.DoomBloodPunchPrepareTics = 0;
		data.DoomBloodPunchFistRaiseTics = 0;
		data.DoomBloodPunchAttackTics = 0;
		data.DoomBloodPunchFlashTics = 0;
		data.DoomBloodPunchWeaponHidden = false;
		pawn.A_RemoveLight('TuinBloodPunchGlow');
	}

	void BeginDoomBloodPunchHold(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || data.PlayerClass != 4 ||
			data.DoomBloodPunchCharge < 100 || data.DoomBloodPunchHolding ||
			data.DoomBloodPunchPrepareTics > 0 || data.DoomBloodPunchFistRaiseTics > 0 ||
			data.DoomBloodPunchAttackTics > 0) return;
		data.DoomBloodPunchCharge = 0;
		data.DoomBloodPunchChargeRemainder = 0.0;
		data.DoomBloodPunchReadyNotified = false;
		data.DoomBloodPunchHolding = true;
		data.DoomBloodPunchReleaseQueued = false;
		data.DoomBloodPunchImpactDone = false;
		data.DoomBloodPunchPrepareTics = 16;
		data.DoomBloodPunchFistRaiseTics = 0;
		data.DoomBloodPunchAttackTics = 0;
		data.DoomBloodPunchFlashTics = 0;
		data.DoomBloodPunchWeaponHidden = false;
		let weaponSprite = pawn.player.FindPSprite(PSP_WEAPON);
		data.DoomBloodPunchWeaponStartY = weaponSprite ? weaponSprite.y : WEAPONTOP;
		pawn.player.SetPsprite(PSP_FLASH, null);
		SetLootNotification(playerNumber, "BLOOD PUNCH READY - RELEASE V TO STRIKE", 4);
	}

	void StartDoomBloodPunchAttack(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || data.DoomBloodPunchAttackTics > 0) return;
		data.DoomBloodPunchHolding = false;
		data.DoomBloodPunchReleaseQueued = false;
		data.DoomBloodPunchImpactDone = false;
		data.DoomBloodPunchAttackTics = 22;
		data.DoomBloodPunchFlashTics = 22;
		data.DoomBloodPunchFistRaiseTics = 0;
		let punchProvider = GetDefaultByType('TuinBloodPunchOverlayWeapon');
		pawn.player.SetPsprite(PSP_WEAPON, punchProvider.FindState('ProjectSIDEPunch'));
		let fistSprite = pawn.player.FindPSprite(PSP_WEAPON);
		if (fistSprite)
		{
			fistSprite.x = 0;
			fistSprite.y = WEAPONTOP;
			fistSprite.ResetInterpolation();
		}
	}

	void ReleaseDoomBloodPunch(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || (!data.DoomBloodPunchHolding &&
			data.DoomBloodPunchPrepareTics <= 0 && data.DoomBloodPunchFistRaiseTics <= 0)) return;
		data.DoomBloodPunchHolding = false;
		data.DoomBloodPunchReleaseQueued = true;
		if (data.DoomBloodPunchPrepareTics <= 0 && data.DoomBloodPunchFistRaiseTics <= 0)
			StartDoomBloodPunchAttack(pawn, data);
	}

	void ExecuteDoomBloodPunchImpact(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.DoomBloodPunchImpactDone) return;
		data.DoomBloodPunchImpactDone = true;
		SpawnBloodPunchCone(pawn);
		pawn.A_RemoveLight('TuinBloodPunchGlow');
		pawn.A_AttachLight('TuinBloodPunchGlow', DynamicLight.PulseLight, Color(255, 16, 4), 76, 76,
			DynamicLight.LF_ATTENUATE, (32, 0, pawn.Height * 0.62), 0.32);

		int baseDamage = min(650, 140 + max(1, data.PlayerLevel) * 14);
		int totalDamage = 0;
		int targetsHit = 0;
		foreach (sector: level.Sectors)
		{
			for (Actor victim = sector.thinglist; victim; victim = victim.snext)
			{
				if (!victim.bISMONSTER || victim.bFRIENDLY || victim.Health <= 0 ||
					pawn.Distance2D(victim) > 240.0 ||
					abs(Actor.deltaangle(pawn.Angle, pawn.AngleTo(victim, true))) > 55.0) continue;
				double pawnCenter = pawn.Pos.z + pawn.Height * 0.5;
				double victimCenter = victim.Pos.z + victim.Height * 0.5;
				if (abs(pawnCenter - victimCenter) > 128.0 || !pawn.CheckSight(victim, SF_IGNOREWATERBOUNDARY)) continue;
				int healthBefore = max(0, victim.Health);
				victim.DamageMobj(pawn, pawn, baseDamage, 'TuinBloodPunch');
				int dealt = max(0, healthBefore - max(0, victim.Health));
				if (dealt <= 0) continue;
				totalDamage += dealt;
				targetsHit++;
				SpawnBloodPunchImpact(victim);
			}
		}
		double healingRate = data.PerkCapstone ? 0.30 : 0.20;
		int healingCap = data.PerkCapstone ? 110 : 75;
		int healing = min(healingCap, int(totalDamage * healingRate + 0.5));
		if (healing > 0 && pawn.Health > 0)
			pawn.A_SetHealth(min(pawn.GetMaxHealth(true), pawn.Health + healing));
		if (targetsHit > 0)
		{
			pawn.A_StartSound("*fist", CHAN_WEAPON);
			SetLootNotification(playerNumber, String.Format("BLOOD PUNCH! %d HIT - HEALED %d", targetsHit, healing), 5);
		}
		else SetLootNotification(playerNumber, "BLOOD PUNCH MISSED - BUILD CHARGE", 0);
	}

	// Kept for old binds and testing addons: it performs a tap, lowering the
	// weapon first and automatically punching as soon as the fists are ready.
	void ActivateDoomBloodPunch(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		BeginDoomBloodPunchHold(playerNumber, pawn, data);
		ReleaseDoomBloodPunch(pawn, data);
	}

	void ApplyDoomBloodPunch(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		if (!data.DoomBloodPunchInitialized)
		{
			data.DoomBloodPunchInitialized = true;
			data.DoomBloodPunchCharge = 0;
		}
		if (data.PlayerClass != 4 || pawn.Health <= 0)
		{
			if (data.DoomBloodPunchHolding || data.DoomBloodPunchPrepareTics > 0 ||
				data.DoomBloodPunchFistRaiseTics > 0 ||
				data.DoomBloodPunchAttackTics > 0 || data.DoomBloodPunchWeaponHidden)
				RestoreDoomBloodPunchWeapon(pawn, data, false);
			return;
		}
		if (data.DoomBloodPunchCharge >= 100 && !data.DoomBloodPunchReadyNotified)
		{
			data.DoomBloodPunchReadyNotified = true;
			SetLootNotification(playerNumber, "BLOOD PUNCH READY - HOLD V", 4);
		}
		if (data.DoomBloodPunchPrepareTics > 0 && pawn.player)
		{
			let weaponSprite = pawn.player.FindPSprite(PSP_WEAPON);
			if (weaponSprite)
			{
				int loweringStep = 17 - data.DoomBloodPunchPrepareTics;
				weaponSprite.y = min(double(WEAPONBOTTOM), data.DoomBloodPunchWeaponStartY + loweringStep * 6.0);
			}
			pawn.player.SetPsprite(PSP_FLASH, null);
			data.DoomBloodPunchPrepareTics--;
			if (data.DoomBloodPunchPrepareTics <= 0)
			{
				pawn.player.SetPsprite(PSP_WEAPON, null);
				data.DoomBloodPunchWeaponHidden = true;
				ShowDoomBloodPunchReadyFists(pawn);
				data.DoomBloodPunchFistRaiseTics = 16;
			}
		}
		else if (data.DoomBloodPunchWeaponHidden && data.DoomBloodPunchFistRaiseTics > 0 && pawn.player)
		{
			if (!pawn.player.FindPSprite(PSP_WEAPON)) ShowDoomBloodPunchReadyFists(pawn);
			let fistSprite = pawn.player.FindPSprite(PSP_WEAPON);
			if (fistSprite)
			{
				int raisingStep = 17 - data.DoomBloodPunchFistRaiseTics;
				fistSprite.x = 0;
				fistSprite.y = max(double(WEAPONTOP), double(WEAPONBOTTOM) - raisingStep * 6.0);
			}
			data.DoomBloodPunchFistRaiseTics--;
			if (data.DoomBloodPunchFistRaiseTics <= 0)
			{
				if (fistSprite)
				{
					fistSprite.y = WEAPONTOP;
					fistSprite.ResetInterpolation();
				}
				if (data.DoomBloodPunchReleaseQueued) StartDoomBloodPunchAttack(pawn, data);
			}
		}
		else if (data.DoomBloodPunchHolding && data.DoomBloodPunchWeaponHidden && pawn.player)
		{
			if (!pawn.player.FindPSprite(PSP_WEAPON)) ShowDoomBloodPunchReadyFists(pawn);
		}
		if (data.DoomBloodPunchAttackTics > 0)
		{
			data.DoomBloodPunchAttackTics--;
			data.DoomBloodPunchFlashTics = data.DoomBloodPunchAttackTics;
			if (!data.DoomBloodPunchImpactDone && data.DoomBloodPunchAttackTics <= 18)
				ExecuteDoomBloodPunchImpact(playerNumber, pawn, data);
			if (data.DoomBloodPunchAttackTics <= 0)
				RestoreDoomBloodPunchWeapon(pawn, data, true);
		}
	}

	void ChoosePlayerClass(int playerNumber, int chosenClass)
	{
		let data = EnsurePlayerData(playerNumber);
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!data || !pawn || chosenClass < 1 || chosenClass > 5) return;
		if (data.PlayerClass != 0)
		{
			pawn.A_Log(String.Format("Your class is permanently set to %s.", PlayerClassName(data.PlayerClass)));
			SetLootNotification(playerNumber, String.Format("CLASS ALREADY CHOSEN: %s", PlayerClassName(data.PlayerClass)), 0);
			return;
		}
		if (data.UnspentSkillPoints <= 0)
		{
			pawn.A_Log("You need one perk point to choose a class. Perk points are earned every five levels.");
			SetLootNotification(playerNumber, "ONE PERK POINT REQUIRED - EARNED EVERY 5 LEVELS", 0);
			return;
		}
		data.UnspentSkillPoints--;
		data.PlayerClass = chosenClass;
		if (chosenClass == 5)
		{
			data.RogueChargeInitialized = true;
			data.RogueVeilCharge = 100;
		}
		else if (chosenClass == 1)
		{
			data.TankChargeInitialized = true;
			data.TankOverdriveCharge = 0;
			data.TankOverdriveActive = false;
			data.TankOverdriveTics = 0;
			data.TankReadyNotified = false;
		}
		else if (chosenClass == 4)
		{
			data.DoomBloodPunchInitialized = true;
			data.DoomBloodPunchCharge = 0;
			data.DoomBloodPunchChargeRemainder = 0.0;
			data.DoomBloodPunchReadyNotified = false;
			data.DoomBloodPunchFlashTics = 0;
			data.DoomBloodPunchWeaponHidden = false;
			data.DoomBloodPunchHolding = false;
			data.DoomBloodPunchReleaseQueued = false;
			data.DoomBloodPunchImpactDone = false;
			data.DoomBloodPunchPrepareTics = 0;
			data.DoomBloodPunchFistRaiseTics = 0;
			data.DoomBloodPunchAttackTics = 0;
		}
		data.ClassHealClock = 0;
		data.ClassAmmoCount = 0;
		ApplyClassHealth(pawn, data);
		string className = PlayerClassName(chosenClass);
		pawn.A_Log(String.Format("CLASS CHOSEN: %s. This choice is permanent.", className));
		SetLootNotification(playerNumber, String.Format("CLASS CHOSEN: %s", className), 4);
	}

	void BuyPerk(int playerNumber, int perk)
	{
		let data = EnsurePlayerData(playerNumber);
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!data || !pawn) return;
		if (data.PlayerClass == 0)
		{
			SetLootNotification(playerNumber, "CHOOSE A CLASS BEFORE BUYING PERKS", 0);
			return;
		}
		if (data.UnspentSkillPoints <= 0)
		{
			SetLootNotification(playerNumber, "NO PERK POINTS AVAILABLE", 0);
			return;
		}
		int rank;
		switch (perk)
		{
		case 1: rank = data.PerkVitalCore; break;
		case 2: rank = data.PerkScavenger; break;
		case 3: rank = data.PerkKillerInstinct; break;
		case 4: rank = data.PerkIronSkin; break;
		case 5: rank = data.PerkBloodDrinker; break;
		case 6: rank = data.PerkClassMastery; break;
		case 7:
			if (data.PerkCapstone) { SetLootNotification(playerNumber, "CLASS ULTIMATE ALREADY UNLOCKED", 0); return; }
			if (data.PlayerLevel < 20 || data.PerkClassMastery < 2)
			{
				SetLootNotification(playerNumber, "ULTIMATE REQUIRES LEVEL 20 AND CLASS TRAINING II", 0);
				return;
			}
			data.PerkCapstone = true;
			data.UnspentSkillPoints--;
			SetLootNotification(playerNumber, "CLASS ULTIMATE UNLOCKED", 5);
			return;
		default: return;
		}
		if (rank >= 3)
		{
			SetLootNotification(playerNumber, "THAT PERK IS ALREADY RANK III", 0);
			return;
		}
		if (perk == 1) data.PerkVitalCore++;
		else if (perk == 2) { data.PerkScavenger++; data.ClassAmmoCount = 0; }
		else if (perk == 3) data.PerkKillerInstinct++;
		else if (perk == 4) data.PerkIronSkin++;
		else if (perk == 5) data.PerkBloodDrinker++;
		else if (perk == 6) data.PerkClassMastery++;
		data.UnspentSkillPoints--;
		ApplyPerkHealth(pawn, data);
		ApplyClassHealth(pawn, data);
		SetLootNotification(playerNumber, String.Format("PERK UPGRADED TO RANK %d", rank + 1), 3);
	}

	static void ApplyFlashlight(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		int lightRange = clamp(CVInt('tuin_flashlight_range', 384), 128, 1024);
		int lightIntensity = clamp(int(CVFloat('tuin_flashlight_intensity', 1.0) * 100.0 + 0.5), 25, 200);
		int lightPitch = int(pawn.Pitch);
		bool shouldEnable = data.FlashlightEnabled && pawn.Health > 0;
		bool ownerChanged = data.FlashlightOwner != pawn;
		if (ownerChanged && data.FlashlightOwner)
		{
			data.FlashlightOwner.A_RemoveLight('TuinPlayerFlashlight');
		}
		if (!ownerChanged && data.AppliedFlashlightRange == lightRange && data.AppliedFlashlightIntensity == lightIntensity &&
			data.AppliedFlashlightPitch == lightPitch && data.AppliedFlashlightEnabled == shouldEnable) return;
		pawn.A_RemoveLight('TuinPlayerFlashlight');
		data.FlashlightOwner = pawn;
		data.AppliedFlashlightRange = lightRange;
		data.AppliedFlashlightIntensity = lightIntensity;
		data.AppliedFlashlightPitch = lightPitch;
		data.AppliedFlashlightEnabled = shouldEnable;
		if (shouldEnable)
		{
			int flags = DynamicLight.LF_SPOT | DynamicLight.LF_ATTENUATE | DynamicLight.LF_DONTLIGHTSELF;
			// UZDoom 4.14's attached lights have no separate intensity argument.
			// Scale the light radius to provide the same user-facing brightness control.
			int effectiveRadius = clamp(int(lightRange * lightIntensity * 0.01), 64, 1536);
			pawn.A_AttachLight('TuinPlayerFlashlight', DynamicLight.PointLight, Color(255, 244, 214),
				effectiveRadius, effectiveRadius, flags, (12, 0, pawn.Height * 0.72), 0.0, 20.0, 48.0, lightPitch);
		}
	}

	int ProgressiveBaseLevel()
	{
		int mapIndex = level.LevelNum;
		if (mapIndex <= 0) mapIndex = max(1, MapsVisited + 1);
		return 1 + int(max(0, mapIndex - 1) * 0.9);
	}

	double AmmoProgressMultiplier(int progressLevel, Name rateCVar, Name capCVar, double fallbackRate, double fallbackCap)
	{
		if (!CVInt('tuin_ammo_scaling_enabled', 1)) return 1.0;
		double rate = clamp(CVFloat(rateCVar, fallbackRate), 0.0, 10.0) * 0.01;
		double cap = clamp(CVFloat(capCVar, fallbackCap), 1.0, 10.0);
		return min(cap, 1.0 + max(0, progressLevel - 1) * rate);
	}

	void ApplyAmmoCapacity(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || !CVInt('tuin_ammo_scaling_enabled', 1)) return;
		int progressLevel = max(data.PlayerLevel, ProgressiveBaseLevel());
		double multiplier = AmmoProgressMultiplier(progressLevel, 'tuin_ammo_capacity_per_level',
			'tuin_ammo_capacity_max_multiplier', 2.0, 2.0);
		bool hasBackpack = pawn.FindInventory('BackpackItem') != null;
		for (Inventory item = pawn.Inv; item; item = item.Inv)
		{
			let ammo = Ammo(item);
			if (!ammo) continue;
			readonly<Ammo> def = GetDefaultByType((class<Ammo>)(ammo.GetClass()));
			if (!def || def.MaxAmount <= 0) continue;
			int desiredMaximum = max(1, int(def.MaxAmount * multiplier + 0.5));
			if (hasBackpack) desiredMaximum *= 2;
			// Never lower a limit supplied by a custom weapon mod or another power-up.
			ammo.MaxAmount = max(ammo.MaxAmount, desiredMaximum);
		}
	}

	void ScaleSpawnedAmmo(Actor thing)
	{
		if (!thing || !CVInt('tuin_ammo_scaling_enabled', 1)) return;
		let ammo = Ammo(thing);
		if (!ammo || ammo.Owner || ammo.Amount <= 0) return;
		int progressLevel = max(ProgressiveBaseLevel(), HighestActivePlayerLevel());
		double multiplier = AmmoProgressMultiplier(progressLevel, 'tuin_ammo_pickup_per_level',
			'tuin_ammo_pickup_max_multiplier', 1.5, 1.75);
		ammo.Amount = max(1, int(ammo.Amount * multiplier + 0.5));
	}

	int RollMonsterLevel(int rarity = 0)
	{
		int minLevel = max(1, CVInt('tuin_monster_min_level', 1));
		int maxLevel = max(minLevel, CVInt('tuin_monster_max_level', 40));
		int mode = CVInt('tuin_monster_level_mode', 0);
		int playerLevel = HighestActivePlayerLevel();
		if (mode == 1)
		{
			int randomLevel = Random[TuinRPGLevel](minLevel, maxLevel);
			if (rarity >= 2 && playerLevel > 0)
			{
				double rareInfluence = min(0.85, 0.55 + (rarity - 2) * 0.10);
				randomLevel = int(randomLevel * (1.0 - rareInfluence) + playerLevel * rareInfluence + 0.5);
			}
			return clamp(randomLevel, minLevel, maxLevel);
		}
		int variance = max(0, CVInt('tuin_monster_level_variance', 3));
		int baseLevel = ProgressiveBaseLevel();
		if (playerLevel > baseLevel)
			baseLevel += int((playerLevel - baseLevel) * DifficultyPlayerLevelInfluence() + 0.5);
		// Rare and higher enemies lean toward player level without mirroring it.
		if (rarity >= 2 && playerLevel > 0)
		{
			double rareInfluence = min(0.85, 0.55 + (rarity - 2) * 0.10);
			baseLevel = int(baseLevel * (1.0 - rareInfluence) + playerLevel * rareInfluence + 0.5);
			variance = max(1, variance - min(2, rarity - 1));
		}
		int rolledLevel = baseLevel + Random[TuinRPGLevel](-variance, variance);
		// Elite+ enemies naturally sit a little above the local pack, and a small
		// surge roll creates occasional high-level threats without scaling every
		// monster directly to the player.
		if (rarity >= 3) rolledLevel += rarity - 2;
		if (Random[TuinRPGLevel](0, 99) < 12)
			rolledLevel += Random[TuinRPGLevel](1, max(2, variance));
		return clamp(rolledLevel, minLevel, maxLevel);
	}

	clearscope static string RarityName(int rarity)
	{
		switch (rarity)
		{
		case 1: return "UNCOMMON";
		case 2: return "RARE";
		case 3: return "ELITE";
		case 4: return "LEGENDARY";
		case 5: return "MYTHIC";
		case 6: return "BOSS";
		default: return "NORMAL";
		}
	}

	clearscope static int RarityColor(int rarity)
	{
		switch (rarity)
		{
		case 1: return Font.CR_GREEN;
		case 2: return Font.CR_CYAN;
		case 3: return Font.CR_ORANGE;
		case 4: return Font.CR_GOLD;
		case 5: return Font.CR_PURPLE;
		case 6: return Font.CR_RED;
		default: return Font.CR_WHITE;
		}
	}

	clearscope static Color RarityBarColor(int rarity)
	{
		if (rarity == 1) return Color(40, 205, 72);
		if (rarity == 2) return Color(40, 190, 255);
		if (rarity == 3) return Color(255, 128, 24);
		if (rarity == 4) return Color(232, 160, 24);
		if (rarity == 5) return Color(190, 40, 255);
		if (rarity == 6) return Color(255, 28, 72);
		return Color(190, 32, 32);
	}

	clearscope static string WeaponQualityName(int quality)
	{
		switch (quality)
		{
		case 1: return "UNCOMMON";
		case 2: return "RARE";
		case 3: return "ELITE";
		case 4: return "LEGENDARY";
		case 5: return "MYTHIC";
		case 6: return "GODLY";
		case 7: return "TUIN UNIQUE";
		default: return "UNKNOWN";
		}
	}

	clearscope static int WeaponQualityFontColor(int quality)
	{
		switch (quality)
		{
		case 1: return Font.CR_GREEN;
		case 2: return Font.CR_CYAN;
		case 3: return Font.CR_ORANGE;
		case 4: return Font.CR_GOLD;
		case 5: return Font.CR_PURPLE;
		case 6: return Font.CR_ICE;
		case 7: return Font.CR_GOLD;
		default: return Font.CR_WHITE;
		}
	}

	clearscope static string WeaponBaseName(class<Weapon> weaponType)
	{
		if (!weaponType) return "UNKNOWN WEAPON";
		readonly<Weapon> def = GetDefaultByType(weaponType);
		return def ? def.GetTag(def.GetClassName()) : "UNKNOWN WEAPON";
	}

	clearscope static bool IsRogueMeleeWeapon(Weapon weapon)
	{
		if (!weapon) return false;
		if (weapon.bMELEEWEAPON || weapon.GetClassName() == 'Fist') return true;
		// Weapon mods frequently forget +WEAPON.MELEEWEAPON. Recognize the usual
		// unarmed display names so custom fists and knuckles still receive the bonus.
		string label = weapon.GetTag(weapon.GetClassName());
		return label ~== "FIST" || label ~== "FISTS" || label ~== "BRASS KNUCKLES" ||
			label ~== "KNUCKLES" || label ~== "BARE HANDS" || label ~== "UNARMED" ||
			label ~== "PUNCH" || label ~== "PUNCHES" || label ~== "MARTIAL ARTS";
	}

	clearscope static string GodlyWeaponTitle(int variantID)
	{
		switch (abs(variantID) % 12)
		{
		case 0: return "HELLBREAKER";
		case 1: return "THE LAST WORD";
		case 2: return "TYRANT'S BANE";
		case 3: return "WRATH OF PHOBOS";
		case 4: return "ICONOCLAST";
		case 5: return "GODSLAYER";
		case 6: return "ASHES OF SIN";
		case 7: return "THE UNMAKER'S OATH";
		case 8: return "BLOOD COVENANT";
		case 9: return "DOOM'S VERDICT";
		case 10: return "ETERNAL REQUIEM";
		default: return "THE FINAL ARGUMENT";
		}
	}

	clearscope static string WeaponVariantName(class<Weapon> weaponType, int affixFlags, int quality = 0, int variantID = 0)
	{
		if (quality == TUIN_LEAD_SPITTER_QUALITY) return "TUIN'S LEAD SPITTER";
		if (quality >= 6)
			return String.Format("%s (%s)", GodlyWeaponTitle(variantID), WeaponBaseName(weaponType));
		string adjective = "Enchanted";
		if (affixFlags & WEAPON_AFFIX_HASTE) adjective = "Swift";
		else if (affixFlags & WEAPON_AFFIX_POWER) adjective = "Brutal";
		else if (affixFlags & WEAPON_AFFIX_LEECH) adjective = "Vampiric";
		else if (affixFlags & WEAPON_AFFIX_EXECUTION) adjective = "Executioner's";
		else if (affixFlags & WEAPON_AFFIX_PROSPERITY) adjective = "Prosperous";
		else if (affixFlags & WEAPON_AFFIX_CRITICAL) adjective = "Keen";
		return String.Format("%s %s", adjective, WeaponBaseName(weaponType));
	}

	clearscope static int WeaponCriticalPercent(int affixFlags, int quality, int itemLevel)
	{
		if (!(affixFlags & WEAPON_AFFIX_CRITICAL)) return 0;
		if (quality == TUIN_LEAD_SPITTER_QUALITY) return 75;
		return clamp(quality * 2 + max(0, itemLevel) / 10, 1, 20);
	}

	clearscope static int WeaponItemLevelPowerPercent(int itemLevel)
	{
		return clamp(max(0, itemLevel - 1) * 2, 0, 60);
	}

	clearscope static int WeaponTotalPowerPercent(int itemLevel, int rolledPower)
	{
		double levelMultiplier = 1.0 + WeaponItemLevelPowerPercent(itemLevel) * 0.01;
		double rollMultiplier = 1.0 + max(0, rolledPower) * 0.01;
		return int((levelMultiplier * rollMultiplier - 1.0) * 100.0 + 0.5);
	}

	clearscope static double TotalCriticalChance(TuinPlayerData data, int variantIndex = -1)
	{
		if (!data) return 0.0;
		double chance = 2.0 + data.Luck * 0.5 + data.PerkKillerInstinct * 2.0 + RogueCriticalBonus(data);
		if (variantIndex >= 0 && variantIndex < data.WeaponVariantCount)
			chance += WeaponCriticalPercent(data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex],
				data.VariantItemLevel[variantIndex]);
		double cap = variantIndex >= 0 && data.VariantQuality[variantIndex] == TUIN_LEAD_SPITTER_QUALITY ? 100.0 : 50.0;
		return clamp(chance, 0.0, cap);
	}

	clearscope static double RogueCriticalBonus(TuinPlayerData data)
	{
		return data && data.PlayerClass == 5 ? 5.0 + data.PerkClassMastery * 2.0 : 0.0;
	}

	clearscope static bool IsGrenadeDamage(Actor inflictor, Name damageType)
	{
		if (inflictor)
		{
			string projectileName = String.Format("%s", inflictor.GetClassName()).MakeLower();
			if (projectileName.IndexOf("grenade") >= 0) return true;
		}
		string typeName = String.Format("%s", damageType).MakeLower();
		return typeName.IndexOf("grenade") >= 0;
	}

	void ApplyGrenadeBossImpact(Vector3 explosionPosition, Actor source, Actor inflictor = null)
	{
		foreach (bossSector: level.Sectors)
		{
			for (Actor boss = bossSector.thinglist; boss; boss = boss.snext)
			{
				Vector3 offset = boss.Pos - explosionPosition;
				if (boss.Health <= 0 || !(boss is 'Cyberdemon' || boss is 'SpiderMastermind') ||
					offset.Length() > 192.0) continue;
				let bossData = GetMonsterData(boss);
				int scaledHealth = bossData ? max(1, bossData.ScaledMaxHealth) : max(1, boss.GetMaxHealth(true));
				// Iconic bosses may swallow all or nearly all native radius damage. Add a
				// controlled impact component: 2% scaled HP, bounded for balance. Existing
				// armor, Tank output penalties, and other damage rules still apply.
				int impactDamage = clamp(int(scaledHealth * 0.02 + 0.5), 128, 500);
				boss.DamageMobj(inflictor, source, impactDamage, 'TuinGrenadeBossImpact');
			}
		}
	}

	bool GrenadeTouchesIconicBoss(Actor grenade)
	{
		if (!grenade) return false;
		foreach (bossSector: level.Sectors)
		{
			for (Actor boss = bossSector.thinglist; boss; boss = boss.snext)
			{
				if (boss.Health <= 0 || !(boss is 'Cyberdemon' || boss is 'SpiderMastermind')) continue;
				// Fast external grenades can move a full tic and bounce before their
				// origins overlap. Keep one movement-step of tolerance so contact is
				// registered just before the engine reverses their velocity.
				double contactDistance = boss.Radius + grenade.Radius + 48.0;
				bool verticalContact = grenade.Pos.z + grenade.Height >= boss.Pos.z - 8.0 &&
					grenade.Pos.z <= boss.Pos.z + boss.Height + 8.0;
				if (verticalContact && grenade.Distance2D(boss) <= contactDistance) return true;
			}
		}
		return false;
	}

	void UpdateGrenadeBossDamage()
	{
		// Track live grenades before their projectile flag is cleared. Custom grenade
		// actors may skip observable death states entirely, so a vanished tracked
		// grenade is also treated as an explosion at its last known position.
		for (int i = 0; i < TUIN_MAX_TRACKED_GRENADES; i++)
		{
			if (!TrackedGrenadeActive[i]) continue;
			Actor grenade = TrackedGrenade[i];
			if (!grenade)
			{
				if (!TrackedGrenadeImpactApplied[i])
					ApplyGrenadeBossImpact(TrackedGrenadePosition[i], TrackedGrenadeSource[i]);
				TrackedGrenadeActive[i] = false;
				continue;
			}
			TrackedGrenadePosition[i] = grenade.Pos;
			if (grenade.Target) TrackedGrenadeSource[i] = grenade.Target;
			if (!TrackedGrenadeImpactApplied[i] && GrenadeTouchesIconicBoss(grenade))
			{
				ApplyGrenadeBossImpact(grenade.Pos, TrackedGrenadeSource[i], grenade);
				TrackedGrenadeImpactApplied[i] = true;
			}
			if (!TrackedGrenadeImpactApplied[i] && grenade.CurState)
			{
				State deathState = grenade.FindState('Death');
				if (deathState && grenade.CurState.InStateSequence(deathState))
				{
					ApplyGrenadeBossImpact(grenade.Pos, TrackedGrenadeSource[i], grenade);
					TrackedGrenadeImpactApplied[i] = true;
				}
			}
		}

		foreach (sector: level.Sectors)
		{
			for (Actor grenade = sector.thinglist; grenade; grenade = grenade.snext)
			{
				if (!grenade.bMISSILE || !IsGrenadeDamage(grenade, grenade.DamageType)) continue;
				bool alreadyTracked = false;
				for (int i = 0; i < TUIN_MAX_TRACKED_GRENADES; i++)
				{
					if (TrackedGrenadeActive[i] && TrackedGrenade[i] == grenade) { alreadyTracked = true; break; }
				}
				if (alreadyTracked) continue;
				int slot = NextTrackedGrenade;
				NextTrackedGrenade = (NextTrackedGrenade + 1) % TUIN_MAX_TRACKED_GRENADES;
				TrackedGrenade[slot] = grenade;
				TrackedGrenadePosition[slot] = grenade.Pos;
				TrackedGrenadeSource[slot] = grenade.Target;
				TrackedGrenadeActive[slot] = true;
				TrackedGrenadeImpactApplied[slot] = false;
			}
		}
	}

	clearscope static bool IsBFGDamage(Actor inflictor, Actor source, Name damageType)
	{
		string typeName = String.Format("%s", damageType).MakeLower();
		if (typeName.IndexOf("bfg") >= 0) return true;
		if (inflictor)
		{
			string projectileName = String.Format("%s", inflictor.GetClassName()).MakeLower();
			if (projectileName.IndexOf("bfg") >= 0) return true;
		}
		// This fallback supports weapon replacements whose projectile or damage type
		// is custom but whose class name or visible weapon tag still identifies a BFG.
		if (source && source.player)
		{
			let ready = source.player.ReadyWeapon;
			if (ready)
			{
				string weaponClass = String.Format("%s", ready.GetClassName()).MakeLower();
				string weaponTag = ready.GetTag(ready.GetClassName()).MakeLower();
				if (weaponClass.IndexOf("bfg") >= 0 || weaponTag.IndexOf("bfg") >= 0) return true;
			}
		}
		return false;
	}

	clearscope static int StoredWeaponVariantScore(TuinPlayerData data, int index)
	{
		if (!data || index < 0 || index >= data.WeaponVariantCount) return 0;
		return data.VariantQuality[index] * 100 + data.VariantItemLevel[index] * 3 + WeaponItemLevelPowerPercent(data.VariantItemLevel[index]) * 2 + data.VariantHastePercent[index] +
			data.VariantPowerPercent[index] + data.VariantLeechPercent[index] * 2 + data.VariantExecutionPercent[index] +
			data.VariantProsperityPercent[index] + WeaponCriticalPercent(data.VariantAffixFlags[index],
				data.VariantQuality[index], data.VariantItemLevel[index]) * 2;
	}

	clearscope static int DroppedWeaponScore(TuinWeaponDrop lootDrop)
	{
		if (!lootDrop) return 0;
		return lootDrop.Quality * 100 + lootDrop.ItemLevel * 3 + WeaponItemLevelPowerPercent(lootDrop.ItemLevel) * 2 + lootDrop.HastePercent + lootDrop.PowerPercent +
			lootDrop.LeechPercent * 2 + lootDrop.ExecutionPercent + lootDrop.ProsperityPercent +
			WeaponCriticalPercent(lootDrop.AffixFlags, lootDrop.Quality, lootDrop.ItemLevel) * 2;
	}

	clearscope static string WeaponStatComparison(string label, int newValue, int currentValue, bool hasCurrent)
	{
		if (!hasCurrent) return String.Format("%s   %d%%", label, newValue);
		int difference = newValue - currentValue;
		return String.Format("%s   NEW %d%%   CURRENT %d%%   %s%d%%", label, newValue, currentValue,
			difference >= 0 ? "+" : "", difference);
	}

	clearscope static int WeaponStatComparisonColor(int newValue, int currentValue, bool hasCurrent)
	{
		if (!hasCurrent) return newValue > 0 ? Font.CR_GREEN : Font.CR_WHITE;
		if (newValue > currentValue) return Font.CR_GREEN;
		if (newValue < currentValue) return Font.CR_RED;
		return Font.CR_WHITE;
	}

	clearscope static int ActiveWeaponVariantIndex(int playerNumber, TuinPlayerData data)
	{
		if (!data || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS) return -1;
		let ready = players[playerNumber].ReadyWeapon;
		return ready ? data.FindEquippedVariant((class<Weapon>)(ready.GetClass())) : -1;
	}

	int RollWeaponQuality(int monsterRarity)
	{
		double roll = FRandom[TuinRPGLoot](0.0, 100.0);
		double mythic = 0.25 * (1.0 + monsterRarity * 1.40);
		double legendary = 1.00 * (1.0 + monsterRarity * 1.00);
		double elite = 3.00 * (1.0 + monsterRarity * 0.80);
		double rare = 10.00 * (1.0 + monsterRarity * 0.50);
		if (roll < mythic) return 5;
		roll -= mythic;
		if (roll < legendary) return 4;
		roll -= legendary;
		if (roll < elite) return 3;
		roll -= elite;
		if (roll < rare) return 2;
		return 1;
	}

	int RollBossWeaponQuality(bool trueFinale)
	{
		double godlyChance = trueFinale ?
			clamp(CVFloat('tuin_boss_godly_weapon_chance', 100.0), 0.0, 100.0) :
			clamp(CVFloat('tuin_native_boss_godly_chance', 5.0), 0.0, 25.0);
		double godlyRoll = FRandom[TuinRPGLoot](0.0, 100.0);
		if (godlyRoll < godlyChance) return 6;
		int roll = Random[TuinRPGLoot](0, 99);
		if (roll < 10) return 5;
		if (roll < 30) return 4;
		if (roll < 60) return 3;
		return 2;
	}

	int RollWeaponAffixValue(int quality, int itemLevel, int affix)
	{
		int low;
		int high;
		if (affix == WEAPON_AFFIX_LEECH)
		{
			low = max(1, quality * 2 - 1);
			high = quality * 2;
		}
		else if (affix == WEAPON_AFFIX_EXECUTION)
		{
			low = 8 + quality * 4;
			high = low + 4;
		}
		else
		{
			low = quality * 5;
			high = low + 5;
		}
		double levelFactor = 1.0 + max(0, itemLevel - 1) * 0.005;
		return max(1, int(Random[TuinRPGLoot](low, high) * levelFactor + 0.5));
	}

	void RollWeaponAffixes(TuinWeaponDrop lootDrop, int itemLevel, int quality)
	{
		if (!lootDrop) return;
		int affixCount = quality == 1 ? 1 : quality <= 3 ? 2 : quality == 4 ? 3 : 4;
		for (int i = 0; i < affixCount; i++)
		{
			int bit = 1 << Random[TuinRPGLoot](0, 5);
			if (lootDrop.AffixFlags & bit) { i--; continue; }
			lootDrop.AffixFlags |= bit;
			int value = RollWeaponAffixValue(quality, itemLevel, bit);
			if (bit == WEAPON_AFFIX_HASTE) lootDrop.HastePercent = value;
			else if (bit == WEAPON_AFFIX_POWER) lootDrop.PowerPercent = value;
			else if (bit == WEAPON_AFFIX_LEECH) lootDrop.LeechPercent = value;
			else if (bit == WEAPON_AFFIX_EXECUTION) lootDrop.ExecutionPercent = value;
			else if (bit == WEAPON_AFFIX_PROSPERITY) lootDrop.ProsperityPercent = value;
		}
	}

	class<Weapon> PickOwnedWeapon(Actor pawn)
	{
		Array<class<Weapon> > choices;
		if (!pawn) return null;
		for (Inventory item = pawn.Inv; item; item = item.Inv)
		{
			let weapon = Weapon(item);
			if (!weapon || weapon.Amount <= 0) continue;
			class<Weapon> type = (class<Weapon>)(weapon.GetClass());
			bool duplicate = false;
			for (int i = 0; i < choices.Size(); i++) if (choices[i] == type) { duplicate = true; break; }
			if (!duplicate) choices.Push(type);
		}
		return choices.Size() ? choices[Random[TuinRPGLoot](0, choices.Size() - 1)] : null;
	}

	TuinWeaponDrop SpawnRolledWeaponDrop(Vector3 position, class<Weapon> weaponType, int itemLevel, int quality)
	{
		if (!weaponType) return null;
		let lootDrop = TuinWeaponDrop(Actor.Spawn('TuinWeaponDrop', position, NO_REPLACE));
		if (!lootDrop) return null;
		lootDrop.VariantID = ++NextLootID;
		lootDrop.WeaponType = weaponType;
		lootDrop.ItemLevel = itemLevel;
		lootDrop.Quality = quality;
		RollWeaponAffixes(lootDrop, itemLevel, quality);
		lootDrop.DisplayName = WeaponVariantName(weaponType, lootDrop.AffixFlags, quality, lootDrop.VariantID);
		lootDrop.ConfigureVisuals();
		return lootDrop;
	}

	TuinWeaponDrop SpawnLeadSpitterDrop(Vector3 position)
	{
		class<Weapon> weaponType = (class<Weapon>)(Actor.GetReplacement('Chaingun'));
		if (!weaponType) weaponType = 'Chaingun';
		let lootDrop = TuinWeaponDrop(Actor.Spawn('TuinWeaponDrop', position, NO_REPLACE));
		if (!lootDrop) return null;
		lootDrop.VariantID = ++NextLootID;
		lootDrop.WeaponType = weaponType;
		lootDrop.ItemLevel = 75;
		lootDrop.Quality = TUIN_LEAD_SPITTER_QUALITY;
		lootDrop.AffixFlags = WEAPON_AFFIX_HASTE | WEAPON_AFFIX_POWER | WEAPON_AFFIX_LEECH |
			WEAPON_AFFIX_EXECUTION | WEAPON_AFFIX_PROSPERITY | WEAPON_AFFIX_CRITICAL;
		lootDrop.HastePercent = 75;
		lootDrop.PowerPercent = 75;
		lootDrop.LeechPercent = 75;
		lootDrop.ExecutionPercent = 75;
		lootDrop.ProsperityPercent = 75;
		lootDrop.DisplayName = "TUIN'S LEAD SPITTER";
		lootDrop.ConfigureVisuals();
		return lootDrop;
	}

	int RollCatchupWeaponQuality()
	{
		int roll = Random[TuinRPGLoot](0, 99);
		if (roll < 5) return 5;
		if (roll < 20) return 4;
		if (roll < 45) return 3;
		return 2;
	}

	void SpawnCatchupWeaponChoices(Actor pawn, int itemLevel)
	{
		if (!pawn) return;
		Array<class<Weapon> > candidates;
		Array<class<Weapon> > baseChoices;
		baseChoices.Push('Shotgun');
		// Episode-style Doom/Chex maps do not contain Doom II's Super Shotgun.
		if (level.MapName.Left(1) != "E") baseChoices.Push('SuperShotgun');
		baseChoices.Push('Chaingun');
		baseChoices.Push('RocketLauncher');
		baseChoices.Push('PlasmaRifle');
		baseChoices.Push('BFG9000');
		baseChoices.Push('Chainsaw');
		for (int i = 0; i < baseChoices.Size(); i++)
		{
			class<Weapon> resolved = (class<Weapon>)(Actor.GetReplacement(baseChoices[i]));
			if (!resolved) resolved = baseChoices[i];
			bool duplicate = false;
			for (int j = 0; j < candidates.Size(); j++)
				if (candidates[j] == resolved) { duplicate = true; break; }
			if (!duplicate) candidates.Push(resolved);
		}

		Array<class<Weapon> > selected;
		for (int choice = 0; choice < 3 && selected.Size() < candidates.Size(); choice++)
		{
			class<Weapon> weaponType;
			for (int attempt = 0; attempt < 32 && !weaponType; attempt++)
			{
				class<Weapon> candidate = candidates[Random[TuinRPGLoot](0, candidates.Size() - 1)];
				bool alreadySelected = false;
				for (int j = 0; j < selected.Size(); j++)
					if (selected[j] == candidate) { alreadySelected = true; break; }
				if (!alreadySelected) weaponType = candidate;
			}
			if (!weaponType) break;
			selected.Push(weaponType);
			double angle = pawn.Angle - 30.0 + choice * 30.0;
			Vector3 position = (pawn.Pos.x + cos(angle) * 80.0, pawn.Pos.y + sin(angle) * 80.0, pawn.FloorZ + 8.0);
			let reward = SpawnRolledWeaponDrop(position, weaponType, itemLevel, RollCatchupWeaponQuality());
			if (reward) reward.CatchupReward = true;
		}
	}

	void ApplyLateStartCatchup(int playerNumber)
	{
		let data = EnsurePlayerData(playerNumber);
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!data || !pawn) return;
		if (CatchupHandled[playerNumber]) return;
		CatchupHandled[playerNumber] = true;
		int mapNumber = CurrentLoadedCampaignMap;
		if (mapNumber <= 0) mapNumber = level.LevelNum;
		if (mapNumber <= 0) mapNumber = max(1, MapsVisited);
		int previousMap = PreviousLoadedCampaignMap;
		// The player token is authoritative if this handler was reconstructed for a new map.
		if (previousMap <= 0 && data.LastCampaignMapNumber > 0 && data.LastCampaignMapNumber != mapNumber)
			previousMap = data.LastCampaignMapNumber;
		data.LastCampaignMapNumber = mapNumber;
		// John's episode bridge is continuous campaign progression, not a fresh
		// late start or console warp. Preserve the build without awarding levels,
		// stat/perk points, reward weapons, or their accompanying ammo refill.
		if (data.SuppressNextMapCatchup)
		{
			data.SuppressNextMapCatchup = false;
			return;
		}
		if (!CVInt('tuin_late_start_catchup', 1) || !(gameinfo.gametype & GAME_DoomChex)) return;

		int baseLevel = ProgressiveBaseLevel();
		bool freshLateStart = previousMap <= 0 && baseLevel > 1;
		bool nonSequentialJump = previousMap > 0 && mapNumber != previousMap + 1;
		int targetLevel = clamp(baseLevel + clamp(CVInt('tuin_catchup_bonus_levels', 3), 0, 10),
			1, max(1, CVInt('tuin_monster_max_level', 40)));
		if ((!freshLateStart && !nonSequentialJump) || data.PlayerLevel >= targetLevel) return;

		int oldLevel = max(1, data.PlayerLevel);
		for (int newLevel = oldLevel + 1; newLevel <= targetLevel; newLevel++)
		{
			data.UnspentStatPoints++;
			if ((newLevel % 5) == 0) data.UnspentSkillPoints++;
		}
		data.PlayerLevel = targetLevel;
		data.CurrentXP = 0;
		SpawnCatchupWeaponChoices(pawn, targetLevel);
		SetLootNotification(playerNumber, String.Format("LATE-START CATCH-UP: LEVEL %d, +%d STAT POINTS, 3 RARE+ WEAPONS",
			targetLevel, targetLevel - oldLevel), 2);
		pawn.A_Log(String.Format("Tuin RPG catch-up: level %d with %d new stat points. Three Rare-or-better weapon choices spawned nearby.",
			targetLevel, targetLevel - oldLevel));
	}

	TuinWeaponDrop SpawnStoredWeaponDrop(Vector3 position, TuinPlayerData data, int index)
	{
		if (!data || index < 0 || index >= data.WeaponVariantCount) return null;
		let lootDrop = TuinWeaponDrop(Actor.Spawn('TuinWeaponDrop', position, NO_REPLACE));
		if (!lootDrop) return null;
		lootDrop.VariantID = ++NextLootID;
		lootDrop.WeaponType = data.VariantWeaponType[index];
		lootDrop.ItemLevel = data.VariantItemLevel[index];
		lootDrop.Quality = data.VariantQuality[index];
		lootDrop.AffixFlags = data.VariantAffixFlags[index];
		lootDrop.HastePercent = data.VariantHastePercent[index];
		lootDrop.PowerPercent = data.VariantPowerPercent[index];
		lootDrop.LeechPercent = data.VariantLeechPercent[index];
		lootDrop.ExecutionPercent = data.VariantExecutionPercent[index];
		lootDrop.ProsperityPercent = data.VariantProsperityPercent[index];
		lootDrop.DisplayName = WeaponVariantName(lootDrop.WeaponType, lootDrop.AffixFlags, lootDrop.Quality, lootDrop.VariantID);
		lootDrop.ConfigureVisuals();
		return lootDrop;
	}

	void SetLootNotification(int playerNumber, string message, int quality)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS) return;
		LootNotification[playerNumber] = message;
		LootNotificationQuality[playerNumber] = quality;
		LootNotificationTics[playerNumber] = 105;
	}

	void SpawnCoinReward(Actor corpse, TuinMonsterData monsterData)
	{
		if (!corpse || !monsterData || !CVInt('tuin_coins_enabled', 1)) return;
		bool boss = monsterData.MonsterRarity >= 6;
		double chance = clamp(CVFloat('tuin_coin_drop_chance', 25.0) + monsterData.MonsterRarity * 3.0, 0.0, 100.0);
		if (!boss && FRandom[TuinRPGCoins](0.0, 100.0) >= chance) return;
		int maximum = boss ? 30 : max(2, 2 + monsterData.MonsterLevel / 5 + monsterData.MonsterRarity * 2);
		int minimum = boss ? 15 : 1;
		int value = Random[TuinRPGCoins](minimum, maximum);
		Vector3 floorPosition = (corpse.Pos.x, corpse.Pos.y, corpse.FloorZ + 10.0);
		let coins = TuinCoinPickup(Actor.Spawn('TuinCoinPickup', floorPosition, NO_REPLACE));
		if (coins) coins.Amount = value;
	}

	string RandomJohnGreeting()
	{
		switch (Random[TuinRPGJohn](0, 5))
		{
		case 0: return "John: You made it. Spend those coins before the exit.";
		case 1: return "John: Monsters hoard everything. Lucky for you, I sell it back.";
		case 2: return "John: Need shells, armor, or something louder?";
		case 3: return "John: That Boss looks expensive. Make sure it pays for the trouble.";
		case 4: return "John: Browse with the arrow keys. Enter buys. Simple.";
		default: return "John: Welcome, survivor. No refunds after teleporting.";
		}
	}

	string RandomJohnTip()
	{
		switch (Random[TuinRPGJohn](0, 7))
		{
		case 0: return "TIP: Press L to compare your collected weapon variants.";
		case 1: return "TIP: Agility increases firing speed; Endurance reduces damage.";
		case 2: return "TIP: Legendary and Mythic enemies use telegraphed special attacks.";
		case 3: return "TIP: Colored diamonds on the minimap are weapon drops.";
		case 4: return "TIP: Press N to toggle the minimap and F for the flashlight.";
		case 5: return "TIP: Armored monsters reduce incoming damage by 50%.";
		case 6: return "TIP: A lower gear score can still have the stat you need.";
		default: return "TIP: Finale Bosses guarantee a named Godly weapon; other Bosses have a smaller chance.";
		}
	}

	string RandomClassicGameFact()
	{
		Array<string> facts;
		facts.Push("id Software released Doom in 1993.");
		facts.Push("The shareware episode of Doom is called Knee-Deep in the Dead.");
		facts.Push("The first map in Doom is E1M1: Hangar.");
		facts.Push("WAD files in Doom store maps, graphics, sounds, and other lumps.");
		facts.Push("PWAD files let Doom players load additional custom content.");
		facts.Push("The Doom renderer organizes map space with BSP trees.");
		facts.Push("Floors and ceilings in Doom are flat planes, while walls are vertical.");
		facts.Push("Hostile monsters in Doom can hurt one another and begin infighting.");
		facts.Push("Exploding barrels in Doom deal splash damage.");
		facts.Push("The chainsaw in Doom needs no ammunition.");
		facts.Push("The BFG9000 in Doom consumes energy cells.");
		facts.Push("The plasma rifle in Doom also uses energy cells.");
		facts.Push("Both shotguns in Doom use shells.");
		facts.Push("The pistol and chaingun in Doom share bullet ammunition.");
		facts.Push("Rockets in Doom can damage their shooter at close range.");
		facts.Push("The key colors in Doom are blue, yellow, and red.");
		facts.Push("Nightmare difficulty in Doom makes several monsters attack faster.");
		facts.Push("Nightmare difficulty in Doom can respawn slain ordinary monsters.");
		facts.Push("The super shotgun in Doom II fires two shells at once.");
		facts.Push("The Arch-vile in Doom II can resurrect many slain monsters.");
		facts.Push("Revenants in Doom II attack with fists and guided fireballs.");
		facts.Push("The final map in Doom II is named Icon of Sin.");
		facts.Push("Thy Flesh Consumed is the fourth episode of The Ultimate Doom.");
		facts.Push("The status-bar face in Doom reacts to damage and nearby threats.");
		facts.Push("id Software later released the Linux source code for Doom.");

		facts.Push("id Software released Quake in 1996.");
		facts.Push("The environments and enemies in Quake use polygonal 3D models.");
		facts.Push("The game rules in Quake are largely written in the QuakeC language.");
		facts.Push("Compiled QuakeC gameplay code is stored in the progs.dat file.");
		facts.Push("PAK archives in Quake bundle game data into numbered packages.");
		facts.Push("Quake maps use BSP data for visibility and collision structure.");
		facts.Push("Precomputed lightmaps give Quake its famous shadowed look.");
		facts.Push("The start map in Quake contains episode and difficulty portals.");
		facts.Push("The player character in Quake is commonly called Ranger.");
		facts.Push("Slipgates in Quake connect its military and nightmare settings.");
		facts.Push("Shub-Niggurath is the final enemy of the base Quake campaign.");
		facts.Push("The axe is the only standard Quake weapon that needs no ammunition.");
		facts.Push("The shotguns in Quake consume shells.");
		facts.Push("The nailguns in Quake consume nails.");
		facts.Push("The grenade and rocket launchers in Quake share rocket ammunition.");
		facts.Push("The Thunderbolt in Quake consumes cells.");
		facts.Push("Quad Damage in Quake multiplies the player's attack power.");
		facts.Push("The Pentagram of Protection in Quake grants invulnerability.");
		facts.Push("The Ring of Shadows in Quake makes the player partly invisible.");
		facts.Push("Green, yellow, and red armor in Quake provide increasing protection.");
		facts.Push("The original Quake supports cooperative play.");
		facts.Push("Deathmatch was a central multiplayer mode in Quake.");
		facts.Push("QuakeWorld was created to improve online Quake play.");
		facts.Push("Nine Inch Nails created the ambient soundtrack for Quake.");
		facts.Push("id Software later released the Quake engine source under the GPL.");

		facts.Push("id Software released Wolfenstein 3D in 1992.");
		facts.Push("The hero of Wolfenstein 3D is Allied spy B.J. Blazkowicz.");
		facts.Push("The first Wolfenstein 3D episode begins with an escape from Castle Wolfenstein.");
		facts.Push("The Wolfenstein 3D renderer uses ray casting through a tile grid.");
		facts.Push("Walls in Wolfenstein 3D occupy square map tiles.");
		facts.Push("Enemies and pickups in Wolfenstein 3D are billboard-style sprites.");
		facts.Push("The original floors and ceilings in Wolfenstein 3D use solid colors.");
		facts.Push("Doors in Wolfenstein 3D occupy tiles and slide open.");
		facts.Push("Pushwalls in Wolfenstein 3D conceal secret rooms.");
		facts.Push("Treasure items in Wolfenstein 3D increase the player's score.");
		facts.Push("Food and health kits in Wolfenstein 3D restore health.");
		facts.Push("The knife in Wolfenstein 3D requires no ammunition.");
		facts.Push("The pistol in Wolfenstein 3D fires one bullet at a time.");
		facts.Push("The machine gun in Wolfenstein 3D fires automatically.");
		facts.Push("The chaingun is the fastest standard firearm in Wolfenstein 3D.");
		facts.Push("The firearms in Wolfenstein 3D all draw from the same bullet supply.");
		facts.Push("Gold and silver keys in Wolfenstein 3D open locked doors.");
		facts.Push("Guard dogs in Wolfenstein 3D attack at close range.");
		facts.Push("Officers and SS guards in Wolfenstein 3D use different uniforms and weapons.");
		facts.Push("Secret floors in Wolfenstein 3D are reached through hidden elevators.");
		facts.Push("The full version of Wolfenstein 3D contains six episodes.");
		facts.Push("Each full-game episode of Wolfenstein 3D contains ten floors.");
		facts.Push("B.J.'s face in the Wolfenstein 3D HUD changes as he takes damage.");
		facts.Push("Spear of Destiny is a related standalone Wolfenstein adventure.");
		facts.Push("The released Wolfenstein 3D source was built with Borland C++ 3.0.");

		facts.Push("Ion Storm developed Daikatana for the PC.");
		facts.Push("John Romero served as the designer of Daikatana.");
		facts.Push("The PC version of Daikatana was released in 2000.");
		facts.Push("Hiro Miyamoto is the player character in Daikatana.");
		facts.Push("Kage Mishima is the timeline-altering dictator in Daikatana.");
		facts.Push("The story of Daikatana begins in the year 2455.");
		facts.Push("The magical sword in Daikatana can alter history.");
		facts.Push("Hiro travels through time in Daikatana to repair the timeline.");
		facts.Push("Superfly Johnson is one of Hiro's companions in Daikatana.");
		facts.Push("Mikiko Ebihara is one of Hiro's companions in Daikatana.");
		facts.Push("The two companions in Daikatana can fight alongside Hiro.");
		facts.Push("The Daikatana campaign contains 24 large levels.");
		facts.Push("The levels in Daikatana span four different time periods.");
		facts.Push("Daikatana contains 25 collectible weapons.");
		facts.Push("Daikatana features more than 50 enemy types.");
		facts.Push("The first era in Daikatana is a dystopian future.");
		facts.Push("One era in Daikatana visits ancient Greece.");
		facts.Push("One era in Daikatana visits a mythic medieval Norway.");
		facts.Push("The final era in Daikatana visits San Francisco in 2030.");
		facts.Push("Each era in Daikatana introduces a different weapon set.");
		facts.Push("Each era in Daikatana introduces its own enemies and visual style.");
		facts.Push("Character progression in Daikatana awards experience during play.");
		facts.Push("The multiplayer mode in Daikatana supports competitive network matches.");
		facts.Push("The technology in Daikatana was derived from the Quake II engine.");
		facts.Push("A separate Game Boy Color adaptation of Daikatana was also released.");

		return String.Format("John: %s", facts[Random[TuinRPGJohn](0, facts.Size() - 1)]);
	}

	void SpawnJohnMerchant(Actor anchor)
	{
		if (!anchor || !CVInt('tuin_john_shop_enabled', 1) || JohnMerchant) return;
		double baseAngle = anchor.Angle + 135.0;
		for (int attempt = 0; attempt < 24 && !JohnMerchant; attempt++)
		{
			double angle = baseAngle + (attempt % 8) * 45.0;
			double radius = 80.0 + (attempt / 8) * 32.0;
			Vector3 spawnPosition = (anchor.Pos.x + cos(angle) * radius, anchor.Pos.y + sin(angle) * radius, anchor.FloorZ);
			let john = TuinJohnShopNPC(Actor.Spawn('TuinJohnShopNPC', spawnPosition, NO_REPLACE));
			if (!john) continue;
			john.SetZ(john.FloorZ);
			bool enoughHeight = john.CeilingZ - john.FloorZ >= john.Height;
			if (enoughHeight && john.TestMobjLocation() && anchor.CheckSight(john)) JohnMerchant = john;
			else john.Destroy();
		}
		if (JohnMerchant)
		{
			for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
				if (playerInGame[playerNumber] && players[playerNumber].mo)
					SetLootNotification(playerNumber, "JOHN HAS ARRIVED - PRESS USE [E] TO TRADE", 0);
		}
	}

	bool SpendCoins(Actor pawn, int cost)
	{
		let coins = pawn ? Inventory(pawn.FindInventory('TuinCoinPickup')) : null;
		if (!coins || coins.Amount < cost) return false;
		coins.Amount -= cost;
		return true;
	}

	void GiveCoins(Actor pawn, int amount)
	{
		if (!pawn || amount <= 0) return;
		let coins = Inventory(pawn.FindInventory('TuinCoinPickup'));
		if (!coins)
		{
			pawn.GiveInventory('TuinCoinPickup', 1);
			coins = Inventory(pawn.FindInventory('TuinCoinPickup'));
			if (coins)
			{
				// GiveInventory creates the stack with one item; clear that bootstrap
				// amount so grants award exactly the requested number of coins.
				coins.Amount = 0;
				coins.A_RemoveLight('TuinCoinGlow');
			}
		}
		if (coins) coins.Amount = min(coins.MaxAmount, coins.Amount + amount);
	}

	int RefillAmmo(Actor pawn, bool fullRefill)
	{
		int added = 0;
		for (Inventory item = pawn ? pawn.Inv : null; item; item = item.Inv)
		{
			let ammo = Ammo(item);
			if (!ammo || ammo.MaxAmount <= ammo.Amount) continue;
			int oldAmount = ammo.Amount;
			int refill = fullRefill ? ammo.MaxAmount : max(1, ammo.MaxAmount / 4);
			ammo.Amount = min(ammo.MaxAmount, ammo.Amount + refill);
			added += ammo.Amount - oldAmount;
		}
		return added;
	}

	int GiveSmallRandomAmmo(Actor pawn)
	{
		Ammo chosenAmmo;
		int choices = 0;
		for (Inventory item = pawn ? pawn.Inv : null; item; item = item.Inv)
		{
			let ammo = Ammo(item);
			if (!ammo || ammo.MaxAmount <= ammo.Amount) continue;
			choices++;
			if (Random[TuinRPGJohn](1, choices) == 1) chosenAmmo = ammo;
		}
		if (!chosenAmmo) return 0;
		int low = max(1, chosenAmmo.MaxAmount / 20);
		int high = max(low, chosenAmmo.MaxAmount / 10);
		int oldAmount = chosenAmmo.Amount;
		chosenAmmo.Amount = min(chosenAmmo.MaxAmount, chosenAmmo.Amount + Random[TuinRPGJohn](low, high));
		return chosenAmmo.Amount - oldAmount;
	}

	int RollJohnGambleQuality()
	{
		// Godly remains Boss-exclusive. A gamble always returns at least Uncommon,
		// with a 20% combined chance to reach Rare or better.
		int roll = Random[TuinRPGJohn](0, 999);
		if (roll < 10) return 5;   // Mythic: 1%
		if (roll < 30) return 4;   // Legendary: 2%
		if (roll < 80) return 3;   // Elite: 5%
		if (roll < 200) return 2;  // Rare: 12%
		return 1;                  // Uncommon: 80%
	}

	void BuyJohnItem(int playerNumber, int itemNumber)
	{
		let data = EnsurePlayerData(playerNumber);
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!data || !pawn) return;
		int cost;
		switch (itemNumber)
		{
		case 1: cost = 10; break;
		case 2: cost = 100; break;
		case 3: cost = 10; break;
		case 4: cost = 20; break;
		case 5: cost = 50; break;
		case 6: cost = 150; break;
		default: return;
		}
		if (CoinBalance(pawn) < cost)
		{
			data.ShopDialogue = String.Format("John: You need %d coins. Come back after more hunting.", cost);
			return;
		}

		bool success = false;
		if (itemNumber == 1)
		{
			int maximumHealth = pawn.GetMaxHealth(true);
			if (pawn.Health < maximumHealth)
			{
				pawn.A_SetHealth(min(maximumHealth, pawn.Health + 25));
				data.ShopDialogue = "John: Patched you up. Try not to leak on the merchandise.";
				success = true;
			}
			else data.ShopDialogue = "John: You're already at full health.";
		}
		else if (itemNumber == 2)
		{
			int added = RefillAmmo(pawn, false);
			if (added > 0)
			{
				data.ShopDialogue = String.Format("John: Loaded you with %d rounds of assorted ammo.", added);
				success = true;
			}
			else data.ShopDialogue = "John: Your current ammo is already full.";
		}
		else if (itemNumber == 3)
		{
			int added = GiveSmallRandomAmmo(pawn);
			if (added > 0)
			{
				data.ShopDialogue = String.Format("John: A small cache gave you %d rounds for one random ammo type.", added);
				success = true;
			}
			else data.ShopDialogue = "John: Every ammo type you carry is already full.";
		}
		else if (itemNumber == 4)
		{
			let armor = BasicArmor(pawn.FindInventory('BasicArmor'));
			if (armor && armor.Amount >= 200) data.ShopDialogue = "John: That armor cannot take another plate.";
			else
			{
				if (!armor)
				{
					pawn.GiveInventory('GreenArmor', 1);
					armor = BasicArmor(pawn.FindInventory('BasicArmor'));
				}
				if (armor) armor.Amount = min(200, armor.Amount + 25);
				data.ShopDialogue = "John: Twenty-five points of armor. Fitted while you wait.";
				success = true;
			}
		}
		else if (itemNumber == 5)
		{
			if (pawn.FindInventory('BackpackItem')) data.ShopDialogue = "John: You already have a backpack.";
			else
			{
				pawn.GiveInventory('BackpackItem', 1);
				data.ShopDialogue = "John: More capacity, fewer excuses.";
				success = true;
			}
		}
		else if (itemNumber == 6)
		{
			class<Weapon> weaponType = PickOwnedWeapon(pawn);
			if (!weaponType) data.ShopDialogue = "John: Bring me a weapon before gambling on an upgrade.";
			else
			{
				int quality = RollJohnGambleQuality();
				let reward = SpawnRolledWeaponDrop((pawn.Pos.x, pawn.Pos.y, pawn.FloorZ + 8.0),
					weaponType, max(1, data.PlayerLevel), quality);
				if (reward)
				{
					data.ShopDialogue = String.Format("John: The wheel says %s. Press E to inspect your %s.",
						WeaponQualityName(quality), WeaponBaseName(weaponType));
					success = true;
				}
			}
		}

		if (success)
		{
			SpendCoins(pawn, cost);
			SetLootNotification(playerNumber, String.Format("PURCHASED FROM JOHN - %d COINS", cost), 0);
		}
	}

	void ResetWeaponLoot(int playerNumber)
	{
		let data = EnsurePlayerData(playerNumber);
		if (data) data.ClearWeaponVariants();
		ThinkerIterator it = ThinkerIterator.Create('TuinWeaponDrop');
		TuinWeaponDrop lootDrop;
		while (lootDrop = TuinWeaponDrop(it.Next())) lootDrop.Destroy();
		SetServerInt('tuin_weapon_drops_enabled', 1);
		SetServerFloat('tuin_weapon_drop_chance', 1.50);
		SetServerInt('tuin_weapon_drop_lifetime', 90);
		SetServerFloat('tuin_weapon_inspect_distance', 256.0);
		SetServerFloat('tuin_weapon_near_inspect_distance', 80.0);
		TargetWeaponDrop[playerNumber] = null;
		SetLootNotification(playerNumber, "WEAPON LOOT RESET - ALL WEAPONS NORMAL", 0);
	}

	void TryDropWeapon(Actor corpse, TuinMonsterData monsterData, int playerNumber)
	{
		if (!corpse || !monsterData || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS ||
			!playerInGame[playerNumber] || !players[playerNumber].mo || !CVInt('tuin_weapon_drops_enabled', 1)) return;
		double rarityMultiplier;
		switch (monsterData.MonsterRarity)
		{
		case 1: rarityMultiplier = 1.5; break;
		case 2: rarityMultiplier = 2.5; break;
		case 3: rarityMultiplier = 4.0; break;
		case 4: rarityMultiplier = 7.0; break;
		case 5: rarityMultiplier = 12.0; break;
		case 6: rarityMultiplier = 100.0; break;
		default: rarityMultiplier = 1.0; break;
		}
		let playerData = EnsurePlayerData(playerNumber);
		double luckMultiplier = playerData ? min(1.5, 1.0 + playerData.Luck * 0.02) : 1.0;
		double chance = clamp(CVFloat('tuin_weapon_drop_chance', 1.50) * rarityMultiplier * luckMultiplier, 0.0, 100.0);
		bool trueFinale = monsterData.MonsterRarity >= 6 && IsIconicEpisodeBoss(corpse);
		bool nativeBossGodly = monsterData.MonsterRarity < 6 && corpse.bBOSS &&
			FRandom[TuinRPGLoot](0.0, 100.0) < clamp(CVFloat('tuin_native_boss_godly_chance', 5.0), 0.0, 25.0);
		if (monsterData.MonsterRarity < 6 && !nativeBossGodly && FRandom[TuinRPGLoot](0.0, 100.0) >= chance) return;
		class<Weapon> weaponType = PickOwnedWeapon(players[playerNumber].mo);
		if (!weaponType) return;
		int itemLevel = clamp(monsterData.MonsterLevel + Random[TuinRPGLoot](-2, 2), 1, max(1, CVInt('tuin_monster_max_level', 40)));
		int quality = nativeBossGodly ? 6 : monsterData.MonsterRarity >= 6 ? RollBossWeaponQuality(trueFinale) : RollWeaponQuality(monsterData.MonsterRarity);
		SpawnRolledWeaponDrop((corpse.Pos.x, corpse.Pos.y, corpse.FloorZ + 8.0), weaponType, itemLevel, quality);
	}

	int RollRarity()
	{
		if (!CVInt('tuin_rarity_enabled', 1)) return 0;
		double chanceFactor = DifficultyRarityChanceFactor();
		double mythic = max(0.0, CVFloat('tuin_rarity_mythic_chance', 0.50)) * chanceFactor;
		double legendary = max(0.0, CVFloat('tuin_rarity_legendary_chance', 1.00)) * chanceFactor;
		double elite = max(0.0, CVFloat('tuin_rarity_elite_chance', 2.5)) * chanceFactor;
		double rare = max(0.0, CVFloat('tuin_rarity_rare_chance', 7.0)) * chanceFactor;
		double uncommon = max(0.0, CVFloat('tuin_rarity_uncommon_chance', 15.0)) * chanceFactor;
		double roll = FRandom[TuinRPGRarity](0.0, 100.0);
		if (roll < mythic) return 5;
		roll -= mythic;
		if (roll < legendary) return 4;
		roll -= legendary;
		if (roll < elite) return 3;
		roll -= elite;
		if (roll < rare) return 2;
		roll -= rare;
		if (roll < uncommon) return 1;
		return 0;
	}

	clearscope static double RarityHealthMultiplier(int rarity)
	{
		double multiplier;
		switch (rarity)
		{
		case 1: multiplier = 1.15; break;
		case 2: multiplier = 1.35; break;
		case 3: multiplier = 1.75; break;
		case 4: multiplier = 2.50; break;
		case 5: multiplier = 4.00; break;
		case 6: multiplier = 6.00; break;
		default: multiplier = 1.00; break;
		}
		return ScaleHealthPower(multiplier);
	}

	clearscope static double RarityDamageMultiplier(int rarity)
	{
		double multiplier;
		switch (rarity)
		{
		case 1: multiplier = 1.05; break;
		case 2: multiplier = 1.12; break;
		case 3: multiplier = 1.25; break;
		case 4: multiplier = 1.50; break;
		case 5: multiplier = 2.00; break;
		case 6: multiplier = 2.50; break;
		default: multiplier = 1.00; break;
		}
		return ScaleDamagePower(multiplier);
	}

	clearscope static double RarityXPMultiplier(int rarity)
	{
		switch (rarity)
		{
		case 1: return 1.25;
		case 2: return 1.75;
		case 3: return 3.00;
		case 4: return 6.00;
		case 5: return 12.00;
		case 6: return 24.00;
		default: return 1.00;
		}
	}

	string PickNamePrefix()
	{
		switch (Random[TuinRPGNames](0, 31))
		{
		case 0: return "Blood"; case 1: return "Bone"; case 2: return "Hell";
		case 3: return "Ash"; case 4: return "Void"; case 5: return "Skull";
		case 6: return "Flesh"; case 7: return "Black"; case 8: return "Infernal";
		case 9: return "Burning"; case 10: return "Cursed"; case 11: return "Doom";
		case 12: return "Night"; case 13: return "Iron"; case 14: return "Death";
		case 15: return "Grim"; case 16: return "Rot"; case 17: return "Plague";
		case 18: return "Dread"; case 19: return "Blight"; case 20: return "Grave";
		case 21: return "Rage"; case 22: return "Venom"; case 23: return "Storm";
		case 24: return "Chaos"; case 25: return "Sin"; case 26: return "War";
		case 27: return "Corpse"; case 28: return "Rust"; case 29: return "Soul";
		case 30: return "Murder"; default: return "Brimstone";
		}
	}

	string PickNameSuffix()
	{
		switch (Random[TuinRPGNames](0, 23))
		{
		case 0: return "Reaper"; case 1: return "Butcher"; case 2: return "Tyrant";
		case 3: return "Hunter"; case 4: return "Stalker"; case 5: return "Warden";
		case 6: return "Destroyer"; case 7: return "Keeper"; case 8: return "Eater";
		case 9: return "Lord"; case 10: return "Bringer"; case 11: return "Spawn";
		case 12: return "Slayer"; case 13: return "Devourer"; case 14: return "Tormentor";
		case 15: return "Desecrator"; case 16: return "Ravager"; case 17: return "Harvester";
		case 18: return "Executioner"; case 19: return "Defiler"; case 20: return "Warmonger";
		case 21: return "Prowler"; case 22: return "Scourge"; default: return "Bane";
		}
	}

	string PickFamilySuffix(Actor monster)
	{
		int roll = Random[TuinRPGNames](0, 5);
		if (monster is 'DoomImp')
		{
			switch (roll) { case 0: return "Emberclaw"; case 1: return "Firetongue"; case 2: return "Cinder Imp";
			case 3: return "Hellclaw"; case 4: return "Ashspitter"; default: return "Flamefiend"; }
		}
		if (monster is 'ZombieMan' || monster is 'ShotgunGuy' || monster is 'ChaingunGuy' || monster is 'WolfensteinSS')
		{
			switch (roll) { case 0: return "Deadeye"; case 1: return "Rotgunner"; case 2: return "Grave Trooper";
			case 3: return "Hell Rifleman"; case 4: return "Corpse Soldier"; default: return "Blood Sergeant"; }
		}
		if (monster is 'Demon')
		{
			switch (roll) { case 0: return "Fang"; case 1: return "Goremaw"; case 2: return "Flesh Hound";
			case 3: return "Hell Hound"; case 4: return "Bonegnawer"; default: return "Ripper"; }
		}
		if (monster is 'Cacodemon' || monster is 'PainElemental' || monster is 'LostSoul')
		{
			switch (roll) { case 0: return "Dread Eye"; case 1: return "Soulmaw"; case 2: return "Hell Gazer";
			case 3: return "Skullstorm"; case 4: return "Void Orb"; default: return "Doom Eye"; }
		}
		if (monster is 'BaronOfHell' || monster is 'HellKnight')
		{
			switch (roll) { case 0: return "Horned Lord"; case 1: return "Hell Prince"; case 2: return "Brimstone Knight";
			case 3: return "Greenflame"; case 4: return "Hoof of Doom"; default: return "Abyssal Baron"; }
		}
		if (monster is 'Revenant')
		{
			switch (roll) { case 0: return "Bone Archer"; case 1: return "Gravewalker"; case 2: return "Skullfist";
			case 3: return "Death Missile"; case 4: return "Crypt Stalker"; default: return "Rattlebones"; }
		}
		if (monster is 'Arachnotron' || monster is 'SpiderMastermind')
		{
			switch (roll) { case 0: return "Web Tyrant"; case 1: return "Steel Widow"; case 2: return "Brainstalker";
			case 3: return "Plasma Weaver"; case 4: return "Iron Spider"; default: return "Mindcrawler"; }
		}
		if (monster is 'Fatso')
		{
			switch (roll) { case 0: return "Flamebelly"; case 1: return "Corpse Cannon"; case 2: return "Blubberfiend";
			case 3: return "Hell Bombardier"; case 4: return "Goremouth"; default: return "Siege Brute"; }
		}
		if (monster is 'Archvile')
		{
			switch (roll) { case 0: return "Pyre Sage"; case 1: return "Corpsecaller"; case 2: return "Flame Priest";
			case 3: return "Ash Prophet"; case 4: return "Grave Burner"; default: return "Hell Shaman"; }
		}
		return PickNameSuffix();
	}

	string PickLegendaryName()
	{
		switch (Random[TuinRPGNames](0, 19))
		{
		case 0: return "Gorath"; case 1: return "Azrak"; case 2: return "Malgar";
		case 3: return "Vulkan"; case 4: return "Korvax"; case 5: return "Zarith";
		case 6: return "Drogath"; case 7: return "Nexar"; case 8: return "Vharok";
		case 9: return "Mordrath"; case 10: return "Krazul"; case 11: return "Belgor";
		case 12: return "Xareth"; case 13: return "Vorgrim"; case 14: return "Thulgar";
		case 15: return "Nihlath"; case 16: return "Skarvek"; case 17: return "Rhazak";
		case 18: return "Ozul"; default: return "Kharon";
		}
	}

	string GenerateMonsterName(Actor monster, int rarity)
	{
		string suffix = PickFamilySuffix(monster);
		if (rarity >= 4) return String.Format("%s THE %s", PickLegendaryName(), suffix).MakeUpper();
		return String.Format("%s %s", PickNamePrefix(), suffix);
	}

	int AffixCountForRarity(int rarity)
	{
		int count = 0;
		if (rarity == 1) count = 1;
		else if (rarity == 2) count = Random[TuinRPGAffix](1, 2);
		else if (rarity == 3) count = Random[TuinRPGAffix](2, 3);
		else if (rarity == 4) count = Random[TuinRPGAffix](3, 4);
		else if (rarity >= 5) count = Random[TuinRPGAffix](4, 5);
		if (DifficultyMode() == 3 && count > 0) count += 2;
		return min(count, DifficultyAffixMaximum());
	}

	bool IsFinaleBossCandidate(Actor monster)
	{
		if (!IsValidMonster(monster) || !monster.bCOUNTKILL || monster.bDORMANT || monster.bBOSS || monster.bBOSSDEATH) return false;
		if (monster is 'Cyberdemon' || monster is 'SpiderMastermind' || monster is 'BossBrain' ||
			monster is 'Archvile' || monster is 'PainElemental' || monster is 'LostSoul') return false;
		let data = GetMonsterData(monster);
		return data && data.MonsterRarity < 6;
	}

	bool IsIconicEpisodeFinale()
	{
		return level.MapName ~== "E1M8" || level.MapName ~== "E2M8" || level.MapName ~== "E3M8";
	}

	bool IsIconicEpisodeBoss(Actor monster)
	{
		if (!IsValidMonster(monster)) return false;
		if (level.MapName ~== "E1M8") return monster is 'BaronOfHell';
		if (level.MapName ~== "E2M8") return monster is 'Cyberdemon';
		if (level.MapName ~== "E3M8") return monster is 'SpiderMastermind';
		return false;
	}

	bool HasLivingIconicEpisodeBoss()
	{
		if (!IsIconicEpisodeFinale()) return false;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
			if (IsIconicEpisodeBoss(monster)) return true;
		return false;
	}

	bool IsDoom2StoryTransitionMap()
	{
		return level.MapName ~== "MAP06" || level.MapName ~== "MAP11" || level.MapName ~== "MAP20";
	}

	string NextJohnMap()
	{
		if (level.MapName ~== "E1M8") return "E2M1";
		if (level.MapName ~== "E2M8") return "E3M1";
		if (level.MapName ~== "E3M8") return "E4M1";
		if (level.MapName ~== "MAP06") return "MAP07";
		if (level.MapName ~== "MAP11") return "MAP12";
		if (level.MapName ~== "MAP20") return "MAP21";
		return "";
	}

	bool CanOfferJohnTravel()
	{
		if (IsIconicEpisodeFinale()) return !HasLivingIconicEpisodeBoss();
		if (IsDoom2StoryTransitionMap())
			return FinaleBossPromoted && (!FinaleBoss || FinaleBoss.Health <= 0);
		return false;
	}

	void PrepareJohnDialogueSequence(TuinPlayerData data)
	{
		if (!data || data.JohnDialogueMap ~== level.MapName) return;
		data.JohnDialogueMap = level.MapName;
		data.JohnWhatNowPage = 0;
		data.JohnWhatsNextPage = 0;
	}

	string JohnNormalStatusDialogue()
	{
		bool bossAlive = HasLivingIconicEpisodeBoss() ||
			(FinaleBossPromoted && FinaleBoss && FinaleBoss.Health > 0);
		if (bossAlive)
		{
			return "John: The boss is still alive.\nI arrived early so you can prepare for the fight.\nShop, reload and finish the job when you are ready.";
		}
		if (FinaleBossPromoted)
		{
			return "John: The boss is dead.\nInspect its weapon drop and spend any coins you need.\nThen search the map or take the ordinary exit when you are ready.";
		}
		return "John: The map's strongest monster is still out there.\nClear a little more ground and it will reveal itself.\nI can help you prepare while we wait.";
	}

	string JohnWhatNowDialogue(int page = 0)
	{
		page = clamp(page, 0, 3);
		if (level.MapName ~== "E1M8")
		{
			if (page == 0) return "John: Those Barons were the last lock on Phobos.\nThey guarded the anomaly because Hell needed this moon silent.\nYou broke the lock and made enough noise for both of us.";
			if (page == 1) return "John: Phobos was never the real target.\nThe invasion used it as a bridge to reach Deimos.\nWhile you fought here, the whole second moon vanished.";
			if (page == 2) return "John: Deimos was not destroyed.\nIt was pulled out of our sky and suspended above Hell.\nThat open anomaly is the only trail we have left.";
			return "John: You can call this a victory if you need the breath.\nThe truth is that the first battle just ended.\nThe war is waiting on the other side of that light.";
		}
		if (level.MapName ~== "E2M8")
		{
			if (page == 0) return "John: That Cyberdemon was the jailer of Deimos.\nEvery rocket was meant to keep mortals away from the gateway.\nNow its corpse is the last doorstop Hell has.";
			if (page == 1) return "John: Look beyond the base walls.\nDeimos is floating over an endless red world.\nThe moon became a fortress hanging above Hell itself.";
			if (page == 2) return "John: The creatures did not arrive by accident.\nSomething below is feeding troops through the gateway.\nKilling the Cyberdemon only cleared our path to the source.";
			return "John: We could stay here and count the dead.\nSooner or later another army would climb through.\nThe only lasting answer is waiting below us.";
		}
		if (level.MapName ~== "E3M8")
		{
			if (page == 0) return "John: The Spider ruled this part of Hell through fear and machinery.\nYou turned its throne room into a grave.\nFor one quiet moment, the invasion has lost its voice.";
			if (page == 1) return "John: Earth is visible again through the opening.\nThat should feel like the road home.\nInstead it feels like Hell left the door open on purpose.";
			if (page == 2) return "John: Something crossed over while you fought here.\nIt carried Hell back toward the world you saved.\nThe war followed you home before you could return.";
			return "John: This victory bought Earth time, not peace.\nOne final nightmare is gathering beyond the doorway.\nWe finish it before it learns how to grow.";
		}
		if (level.MapName ~== "MAP06")
		{
			if (page == 0) return "John: The starport defenses have finally collapsed.\nThe demons lost the ground they needed to trap the survivors.\nEvery cleared corridor gives another ship room to launch.";
			if (page == 1) return "John: Earth is wounded, but it is not empty yet.\nFamilies are moving toward the evacuation craft right now.\nThey will never know your name, and that means the plan worked.";
			if (page == 2) return "John: The enemy knows the ships are leaving.\nIt is gathering heavier bodies farther inside the city.\nThey want one final chance to close the escape route.";
			return "John: We stay on the ground while everyone else leaves it.\nThat is not a punishment. It is the job.\nWe make enough trouble that Hell forgets to look upward.";
		}
		if (level.MapName ~== "MAP11")
		{
			if (page == 0) return "John: The evacuation ships made it away from Earth.\nHumanity survives because you refused to stop moving.\nFor the first time, this planet is no longer a hostage.";
			if (page == 1) return "John: You are the last living human still fighting down here.\nThe streets belong to mutants, demons and hungry ghosts.\nThat makes every weapon you carry part of the resistance.";
			if (page == 2) return "John: You could sit here and wait for the end.\nNo one would call you a coward after what you saved.\nBut Earth Control just found the source of the invasion.";
			return "John: The signal points back into your own home city.\nThe alien base is close to the starport.\nIf we reach it, we may still seal the way into Earth.";
		}
		if (level.MapName ~== "MAP20")
		{
			if (page == 0) return "John: This is the corrupted heart of the city.\nEverything around us was reshaped to feed the invasion.\nYou fought through the body and reached the wound.";
			if (page == 1) return "John: The gateway cannot be destroyed from this side.\nEarth has no weapon that can reach the machinery beyond it.\nHell built the entrance to survive anything fired from here.";
			if (page == 2) return "John: That leaves one plan, and it is a terrible one.\nWe cross the gateway and attack its roots from inside.\nThe demons will not expect their prey to follow them home.";
			return "John: Behind us is a dead city. Ahead of us is Hell.\nThere is no safe road left to choose.\nThere is only the road that might end the invasion.";
		}
		if (page == 0) return "John: That boss thought this map belonged to it.\nYou proved ownership with ammunition and poor manners.\nTake a moment before the next room starts arguing.";
		if (page == 1) return "John: The strongest monsters gather power from everything nearby.\nThat is why their levels and affixes can turn one body into an army.\nIt is also why their loot is worth the risk.";
		if (page == 2) return "John: Every boss you remove weakens the invasion.\nThe smaller demons lose their shield and their rallying point.\nThe map is safer now, but it is never completely safe.";
		return "John: Spend your coins, inspect the weapon drop and reload.\nA victory is most useful when you survive long enough to use it.\nI will be here until you are ready to move.";
	}

	string JohnWhatsNextDialogue(int page = 0)
	{
		page = clamp(page, 0, 3);
		if (level.MapName ~== "E1M8")
		{
			if (page == 0) return "John: The anomaly leads to Deimos and Episode Two.\nWe will arrive where the moon used to belong.\nDo not expect the base to remember the laws of space.";
			if (page == 1) return "John: Your weapons, levels, perks and coins come with you.\nNothing you earned on Phobos will be rerolled away.\nThis is a journey forward, not a fresh start.";
			if (page == 2) return "John: Deimos has stronger demons and less room for mistakes.\nKeep enough ammunition for whatever moved an entire moon.\nThe shop is open if your backpack feels too light.";
			return "John: When you are ready, choose the gold option below.\nReach out and hold my hand.\nWe will cross into Deimos together.";
		}
		if (level.MapName ~== "E2M8")
		{
			if (page == 0) return "John: Inferno and Episode Three are waiting below.\nWe leave the moon and step onto Hell's own ground.\nEvery monster there will know why we came.";
			if (page == 1) return "John: The shores ahead are built from fire, stone and memory.\nHell likes to turn familiar places into traps.\nTrust your map, but trust your weapon more.";
			if (page == 2) return "John: Your entire Tuin RPG build travels with you.\nNo bonus weapons will appear for crossing normally.\nWhat you carry is what you earned.";
			return "John: Finish shopping before we descend.\nThen choose the gold option and take my hand.\nThis time we invade Hell.";
		}
		if (level.MapName ~== "E3M8")
		{
			if (page == 0) return "John: Thy Flesh Consumed and Episode Four come next.\nEarth survived the first invasion, but the story is not finished.\nA final nest is waiting close to home.";
			if (page == 1) return "John: The next episode is cruel even before Tuin RPG scaling.\nExpect tight spaces, heavy monsters and little mercy.\nBring ammunition for a war, not a victory lap.";
			if (page == 2) return "John: Your character remains exactly who you built.\nYour equipment and progression cross with us.\nThere is no reward for pretending the journey started again.";
			return "John: When the shop is finished, take my hand.\nWe will return to the edge of Earth.\nThen we close the last door together.";
		}
		if (level.MapName ~== "MAP06")
		{
			if (page == 0) return "John: Dead Simple is the next battlefield.\nThe name is a joke told by someone who hates you.\nMancubi and Arachnotrons are waiting to explain it.";
			if (page == 1) return "John: The survivors need one more stretch of open sky.\nOur next fight keeps the enemy looking at us.\nEvery second we buy becomes distance for the ships.";
			if (page == 2) return "John: Your current build continues into MAP07.\nNo catch up weapons or free talent points will appear.\nYou keep only the strength you earned.";
			return "John: The original story message will play before we arrive.\nAfter it ends, we continue into Dead Simple.\nTake my hand when you want to begin.";
		}
		if (level.MapName ~== "MAP11")
		{
			if (page == 0) return "John: The Factory waits in MAP12.\nThe demons turned human industry into part of their invasion.\nWe are going to interrupt production.";
			if (page == 1) return "John: Earth Control marked the source near the starport.\nThe route crosses districts the invasion has already transformed.\nEvery map from here leads closer to the alien base.";
			if (page == 2) return "John: Your arsenal and Tuin RPG progress travel with you.\nThe next map grants no fresh start package.\nYou already have everything the run has earned.";
			return "John: The original intermission comes first.\nThen we wake in the Factory with the mission intact.\nChoose the gold option when you are ready.";
		}
		if (level.MapName ~== "MAP20")
		{
			if (page == 0) return "John: MAP21 begins on Hell's own ground.\nThe gateway is a one way answer to an impossible problem.\nOnce we cross, Earth will be behind us.";
			if (page == 1) return "John: We are not entering Hell to survive it.\nWe are entering to find the source and break it.\nSurvival is simply how we reach the next target.";
			if (page == 2) return "John: Your full build crosses the gateway.\nNo extra levels, talent points or weapon choices will appear.\nHell gets exactly the marine it created.";
			return "John: The story intermission will play before MAP21.\nListen to it, then remember why we crossed.\nTake my hand when you are ready for Hell.";
		}
		if (page == 0) return "John: The level exit is still the next destination.\nSearch for secrets and unclaimed drops before you leave.\nThe minimap can help with anything you missed.";
		if (page == 1) return "John: Check your ammunition before crossing the exit.\nHigher level monsters can consume a full backpack quickly.\nMy shop is cheaper than dying with empty magazines.";
		if (page == 2) return "John: Your build continues unless you deliberately start elsewhere.\nNormal map progression does not grant another catch up package.\nEvery upgrade should come from play, loot or perks.";
		return "John: There is always another map and another boss.\nYou do not need my hand for this ordinary exit.\nFinish your business here, then keep moving.";
	}

	bool BeginEpisodeTravel(int playerNumber)
	{
		if (!CanOfferJohnTravel() || EpisodeTravelTics > 0) return false;
		string destination = NextJohnMap();
		if (!destination.Length()) return false;
		EpisodeTravelPlayer = playerNumber;
		EpisodeTravelDestination = destination;
		EpisodeTravelShowsIntermission = IsDoom2StoryTransitionMap();
		EpisodeTravelTics = 70;
		// Arm this as soon as the player chooses to travel, so saves made during
		// John's short hand-holding delay cannot lose the transition safeguard.
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
		{
			if (!playerInGame[i]) continue;
			let playerData = EnsurePlayerData(i);
			if (playerData) playerData.SuppressNextMapCatchup = true;
		}
		SetLootNotification(playerNumber, "JOHN: HOLD MY HAND. WE MOVE ON TOGETHER.", 5);
		if (players[playerNumber].mo) players[playerNumber].mo.A_Log("John: Hold my hand. We move on together.");
		return true;
	}

	bool TryOpenJohnShop(int playerNumber)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS || !playerInGame[playerNumber]) return false;
		Actor pawn = players[playerNumber].mo;
		if (!pawn) return false;

		TuinJohnShopNPC nearestJohn;
		double nearestDistance = 192.0;
		ThinkerIterator iterator = ThinkerIterator.Create('TuinJohnShopNPC');
		TuinJohnShopNPC john;
		while (john = TuinJohnShopNPC(iterator.Next()))
		{
			double distance = pawn.Distance3D(john);
			if (distance > nearestDistance || !pawn.CheckSight(john)) continue;
			double angleDifference = abs(Actor.deltaangle(pawn.Angle, pawn.AngleTo(john, true)));
			if (distance > 72.0 && angleDifference > 60.0) continue;
			nearestJohn = john;
			nearestDistance = distance;
		}
		if (!nearestJohn) return false;
		JohnMerchant = nearestJohn;
		let data = EnsurePlayerData(playerNumber);
		if (data)
		{
			PrepareJohnDialogueSequence(data);
			data.ShopDialogue = CanOfferJohnTravel()
				? "John: The way forward is open.\nAsk me what happened, ask what comes next, or finish your shopping.\nWhen you are ready to leave, take my hand."
				: RandomJohnGreeting();
		}
		EventHandler.SendInterfaceEvent(playerNumber, CanOfferJohnTravel() ? "tuin_open_john_finale_shop" : "tuin_open_john_shop");
		return true;
	}

	bool PromoteFinaleBossActor(Actor candidate, bool announce = true)
	{
		if (!candidate) return false;
		bool trueFinale = IsIconicEpisodeBoss(candidate);
		// Do this even when loading a save in which the actor was already promoted.
		// Otherwise an older in-progress E2M8/E3M8 save can retain Doom's native
		// episode-ending trigger and bypass John's inventory-preserving transition.
		if (trueFinale)
		{
			candidate.bBOSSDEATH = false;
			if (level.MapName ~== "E1M8") candidate.bE1M8BOSS = false;
			else if (level.MapName ~== "E2M8") candidate.bE2M8BOSS = false;
			else if (level.MapName ~== "E3M8") candidate.bE3M8BOSS = false;
		}
		let data = GetMonsterData(candidate);
		if (!data || data.MonsterRarity >= 6) return false;

		int playerProgress = HighestActivePlayerLevel();
		data.MonsterRarity = 6;
		data.MonsterLevel = clamp(max(data.MonsterLevel + 1, playerProgress + 1), 1,
			max(1, CVInt('tuin_monster_max_level', 40)));
		double levelHealth = 1.0 + (data.MonsterLevel - 1) * max(0.0, CVFloat('tuin_health_scale', 0.05)) * DifficultyHealthLevelFactor();
		double levelDamage = 1.0 + (data.MonsterLevel - 1) * max(0.0, CVFloat('tuin_damage_scale', 0.02)) * DifficultyDamageLevelFactor();
		int bossHealthBase = FinaleBossHealthBase(candidate, data.OriginalMaxHealth);
		data.ScaledMaxHealth = max(data.OriginalMaxHealth, int(bossHealthBase * levelHealth *
			FinaleBossHealthMultiplier(candidate, playerProgress) + 0.5));
		data.DamageMultiplier = levelDamage * FinaleBossDamageMultiplier(candidate, playerProgress);
		data.XPValue = max(1, int((5.0 + sqrt(data.OriginalMaxHealth) * 2.5) *
			(1.0 + (data.MonsterLevel - 1) * 0.08) * RarityXPMultiplier(6) + 0.5));
		data.AffixFlags = RollFinaleBossAffixes(candidate, playerProgress);
		data.GeneratedName = String.Format(trueFinale ? "%s, THE FINAL %s" : "%s, THE DREAD %s",
			PickLegendaryName(), PickNameSuffix()).MakeUpper();
		data.ResetSignatureAttack();
		data.AppliedGlowRarity = -1;
		candidate.A_SetHealth(data.ScaledMaxHealth);
		data.UpdateRarityGlow();
		FinaleBoss = candidate;

		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
			if (data.LastPlayerNumber < 0) data.LastPlayerNumber = playerNumber;
			if (announce)
			{
				if (trueFinale)
				{
					SetLootNotification(playerNumber, String.Format("EPISODE BOSS: %s", data.GeneratedName), 5);
					players[playerNumber].mo.A_Log(String.Format("EPISODE BOSS: %s - guaranteed Godly weapon drop", data.GeneratedName));
				}
				else
				{
					double godlyChance = clamp(CVFloat('tuin_native_boss_godly_chance', 5.0), 0.0, 25.0);
					SetLootNotification(playerNumber, String.Format("LEVEL BOSS EMERGED: %s", data.GeneratedName), 5);
					players[playerNumber].mo.A_Log(String.Format("LEVEL BOSS: %s - %.1f%% Godly weapon chance", data.GeneratedName, godlyChance));
				}
			}
		}
		return true;
	}

	int HighestActivePlayerLevel()
	{
		int highest = 1;
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
			let playerData = EnsurePlayerData(playerNumber);
			if (playerData) highest = max(highest, playerData.PlayerLevel);
		}
		return highest;
	}

	double FinaleBossProgress(int playerProgress)
	{
		int fullPowerLevel = clamp(CVInt('tuin_boss_full_power_level', 30), 10, 100);
		return clamp(double(max(1, playerProgress) - 1) / double(fullPowerLevel - 1), 0.0, 1.0);
	}

	int FinaleBossHealthBase(Actor monster, int originalHealth)
	{
		if (monster && !IsIconicEpisodeBoss(monster) && originalHealth < 500)
			return max(200, originalHealth);
		return max(1, originalHealth);
	}

	double FinaleBossHealthMultiplier(Actor monster, int playerProgress)
	{
		// Native finale monsters begin with much larger health pools than ordinary
		// promotion candidates. E1M8 also divides its encounter across two Barons.
		if (monster && level.MapName ~== "E1M8" && monster is 'BaronOfHell') return ScaleHealthPower(1.75);
		if (monster && level.MapName ~== "E2M8" && monster is 'Cyberdemon') return ScaleHealthPower(1.35);
		if (monster && level.MapName ~== "E3M8" && monster is 'SpiderMastermind') return ScaleHealthPower(1.50);
		double early = clamp(CVFloat('tuin_boss_early_health_multiplier', 2.5), 1.0, 6.0);
		early = ScaleHealthPower(early);
		return early + (RarityHealthMultiplier(6) - early) * FinaleBossProgress(playerProgress);
	}

	double FinaleBossDamageMultiplier(Actor monster, int playerProgress)
	{
		// Iconic actors already have unusually dangerous native attacks. In
		// particular, multiplying the Spider Mastermind's continuous hitscan stream
		// by the full late-game Boss value is excessive.
		if (monster && level.MapName ~== "E1M8" && monster is 'BaronOfHell') return ScaleDamagePower(1.45);
		if (monster && level.MapName ~== "E2M8" && monster is 'Cyberdemon') return ScaleDamagePower(1.60);
		if (monster && level.MapName ~== "E3M8" && monster is 'SpiderMastermind') return ScaleDamagePower(1.70);
		double early = clamp(CVFloat('tuin_boss_early_damage_multiplier', 1.6), 1.0, 2.5);
		early = ScaleDamagePower(early);
		return early + (RarityDamageMultiplier(6) - early) * FinaleBossProgress(playerProgress);
	}

	int RollFinaleBossAffixes(Actor monster, int playerProgress)
	{
		int wanted;
		if (monster && level.MapName ~== "E1M8" && monster is 'BaronOfHell') wanted = 2;
		else if (monster && ((level.MapName ~== "E2M8" && monster is 'Cyberdemon') ||
			(level.MapName ~== "E3M8" && monster is 'SpiderMastermind'))) wanted = 3;
		else wanted = playerProgress < 15 ? 2 : (playerProgress < 25 ? 4 : 6);
		if (DifficultyMode() == 3) wanted += 2;
		wanted = min(wanted, DifficultyAffixMaximum());
		let monsterData = GetMonsterData(monster);
		bool lowBaseBoss = monster && !IsIconicEpisodeBoss(monster) && monsterData &&
			monsterData.OriginalMaxHealth < 500;
		int flags = lowBaseBoss ? TuinMonsterData.AFFIX_ARMORED : 0;
		while (AffixBitCount(flags) < wanted)
		{
			int bit = 1 << Random[TuinRPGAffix](0, 8);
			if (flags & bit) continue;
			// Early bosses rely on attacks and movement, not long effective-HP buffs.
			if ((playerProgress < 15 || IsIconicEpisodeBoss(monster)) && (bit == TuinMonsterData.AFFIX_ARMORED ||
				bit == TuinMonsterData.AFFIX_REGENERATING || bit == TuinMonsterData.AFFIX_HEALER ||
				bit == TuinMonsterData.AFFIX_WARDING)) continue;
			// Armor plus regeneration is a health wall even in the late game.
			if ((bit == TuinMonsterData.AFFIX_ARMORED && (flags & TuinMonsterData.AFFIX_REGENERATING)) ||
				(bit == TuinMonsterData.AFFIX_REGENERATING && (flags & TuinMonsterData.AFFIX_ARMORED))) continue;
			flags |= bit;
		}
		return flags;
	}

	int AffixBitCount(int flags)
	{
		int count = 0;
		for (int bit = 0; bit < 9; bit++) if (flags & (1 << bit)) count++;
		return count;
	}

	bool TryPromoteIconicEpisodeBosses()
	{
		if (FinaleBossPromoted || !CVInt('tuin_finale_boss_enabled', 1) || !IsIconicEpisodeFinale()) return false;
		bool promoted = false;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
		{
			if (!IsIconicEpisodeBoss(monster)) continue;
			if (PromoteFinaleBossActor(monster, true)) promoted = true;
		}
		if (promoted) FinaleBossPromoted = true;
		return promoted;
	}

	bool TryPromoteFinaleBoss(bool forced = false)
	{
		if (FinaleBossPromoted || !CVInt('tuin_finale_boss_enabled', 1)) return false;
		int minimumMonsters = clamp(CVInt('tuin_finale_boss_min_monsters', 8), 1, 100);
		int threshold = clamp(CVInt('tuin_finale_boss_threshold', 85), 50, 99);
		if (!forced && level.total_monsters < minimumMonsters) return false;
		bool reachedThreshold = level.killed_monsters * 100 >= level.total_monsters * threshold;

		Actor candidate;
		int candidateCount = 0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
		{
			if (!IsFinaleBossCandidate(monster)) continue;
			candidateCount++;
			if (Random[TuinRPGFinale](1, candidateCount) == 1) candidate = monster;
		}
		if (!candidate) return false;
		// Do not let excluded survivors such as Lost Souls strand the encounter.
		// Once only one valid candidate remains, reserve it as the level boss even
		// when the ordinary percentage threshold has not quite been reached yet.
		if (!forced && !reachedThreshold && candidateCount > 1) return false;

		if (!PromoteFinaleBossActor(candidate, true)) return false;
		FinaleBossPromoted = true;
		return true;
	}

	int RollAffixes(int count)
	{
		int flags = 0;
		for (int i = 0; i < count; i++)
		{
			int bit = 1 << Random[TuinRPGAffix](0, 8);
			if (flags & bit) { i--; continue; }
			flags |= bit;
		}
		return flags;
	}

	int RollOrdinaryMonsterAffixes(int originalHealth, int rarity)
	{
		int count = AffixCountForRarity(rarity);
		// Hell Knight health is the dividing line. Armor consumes one trait slot;
		// all remaining slots keep their normal random rolls.
		if (rarity >= 2 && rarity < 6 && originalHealth < 500)
		{
			count = max(1, count);
			int flags = TuinMonsterData.AFFIX_ARMORED;
			while (AffixBitCount(flags) < count)
			{
				int bit = 1 << Random[TuinRPGAffix](0, 8);
				if (flags & bit) continue;
				flags |= bit;
			}
			return flags;
		}
		return RollAffixes(count);
	}

	clearscope static string AffixList(TuinMonsterData data)
	{
		if (!data) return "";
		string result = "";
		if (data.AffixFlags & TuinMonsterData.AFFIX_SWIFT) result.AppendFormat("SWIFT");
		if (data.AffixFlags & TuinMonsterData.AFFIX_ARMORED) result.AppendFormat("%sARMORED", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_REGENERATING) result.AppendFormat("%sREGENERATING", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_BERSERKER) result.AppendFormat("%sBERSERKER", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_EXPLOSIVE) result.AppendFormat("%sEXPLOSIVE", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_VAMPIRIC) result.AppendFormat("%sVAMPIRIC", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_POISONOUS) result.AppendFormat("%sPOISONOUS", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_HEALER) result.AppendFormat("%sHEALER", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_WARDING) result.AppendFormat("%sWARDING", result.Length() ? "  |  " : "");
		else if (data.WardTics > 0) result.AppendFormat("%sWARDED", result.Length() ? "  |  " : "");
		if (data.Owner && (data.Owner is 'Cyberdemon' || data.Owner is 'SpiderMastermind'))
			result.AppendFormat("%sBFG RESIST 75%%", result.Length() ? "  |  " : "");
		if (data.BleedPulsesRemaining > 0) result.AppendFormat("%sBLEEDING", result.Length() ? "  |  " : "");
		return result;
	}

	void InitializeMonster(Actor mo)
	{
		if (!CVInt('tuin_enabled', 1) || !IsValidMonster(mo) || GetMonsterData(mo)) return;
		int originalHealth = max(1, mo.Health);
		int rarity = RollRarity();
		int monsterLevel = RollMonsterLevel(rarity);
		double healthMultiplier = (1.0 + (monsterLevel - 1) * max(0.0, CVFloat('tuin_health_scale', 0.05)) * DifficultyHealthLevelFactor()) * RarityHealthMultiplier(rarity);
		double damageMultiplier = (1.0 + (monsterLevel - 1) * max(0.0, CVFloat('tuin_damage_scale', 0.02)) * DifficultyDamageLevelFactor()) * RarityDamageMultiplier(rarity);
		int scaledHealth = max(1, int(originalHealth * healthMultiplier + 0.5));
		mo.GiveInventory('TuinMonsterData', 1);
		let data = GetMonsterData(mo);
		if (!data) return;
		NextMonsterID++;
		data.MonsterLevel = monsterLevel;
		data.MonsterRarity = rarity;
		data.OriginalMaxHealth = originalHealth;
		data.ScaledMaxHealth = scaledHealth;
		data.DamageMultiplier = damageMultiplier;
		data.UniqueID = NextMonsterID;
		data.LastPlayerNumber = -1;
		data.XPValue = max(1, int((5.0 + sqrt(originalHealth) * 2.5) * (1.0 + (monsterLevel - 1) * 0.08) * RarityXPMultiplier(rarity) + 0.5));
		data.GeneratedName = rarity > 0 ? GenerateMonsterName(mo, rarity) : mo.GetTag(mo.GetClassName());
		data.AffixFlags = RollOrdinaryMonsterAffixes(originalHealth, rarity);
		mo.A_SetHealth(scaledHealth);
		data.ResetSignatureAttack();
	}

	void RerollMonster(Actor mo, TuinMonsterData data)
	{
		if (!IsValidMonster(mo) || !data || data.OriginalMaxHealth <= 0) return;
		double healthFraction = clamp(double(mo.Health) / max(1, data.ScaledMaxHealth), 0.0, 1.0);
		int rarity = RollRarity();
		double healthMultiplier = (1.0 + (data.MonsterLevel - 1) * max(0.0, CVFloat('tuin_health_scale', 0.05)) * DifficultyHealthLevelFactor()) * RarityHealthMultiplier(rarity);
		double damageMultiplier = (1.0 + (data.MonsterLevel - 1) * max(0.0, CVFloat('tuin_damage_scale', 0.02)) * DifficultyDamageLevelFactor()) * RarityDamageMultiplier(rarity);
		int scaledHealth = max(1, int(data.OriginalMaxHealth * healthMultiplier + 0.5));

		data.MonsterRarity = rarity;
		data.ScaledMaxHealth = scaledHealth;
		data.DamageMultiplier = damageMultiplier;
		data.XPValue = max(1, int((5.0 + sqrt(data.OriginalMaxHealth) * 2.5) * (1.0 + (data.MonsterLevel - 1) * 0.08) * RarityXPMultiplier(rarity) + 0.5));
		data.GeneratedName = rarity > 0 ? GenerateMonsterName(mo, rarity) : mo.GetTag(mo.GetClassName());
		data.AffixFlags = RollOrdinaryMonsterAffixes(data.OriginalMaxHealth, rarity);
		data.RegenClock = 0;
		data.SwiftClock = 0;
		data.GlowClock = 0;
		data.AppliedGlowRarity = -1;
		data.SwiftLockedTarget = null;
		mo.A_SetHealth(max(1, int(scaledHealth * healthFraction + 0.5)));
		data.UpdateRarityGlow();
		data.ResetSignatureAttack();
	}

	void ApplyOrdinaryMonsterScale(Actor mo, TuinMonsterData data, int monsterLevel, int rarity, bool rerollAffixes)
	{
		if (!IsValidMonster(mo) || !data || data.OriginalMaxHealth <= 0 || rarity >= 6) return;
		double healthFraction = clamp(double(mo.Health) / max(1, data.ScaledMaxHealth), 0.0, 1.0);
		monsterLevel = clamp(monsterLevel, max(1, CVInt('tuin_monster_min_level', 1)),
			max(1, CVInt('tuin_monster_max_level', 40)));
		double healthMultiplier = (1.0 + (monsterLevel - 1) * max(0.0,
			CVFloat('tuin_health_scale', 0.05))) * RarityHealthMultiplier(rarity);
		double damageMultiplier = (1.0 + (monsterLevel - 1) * max(0.0,
			CVFloat('tuin_damage_scale', 0.02))) * RarityDamageMultiplier(rarity);
		data.MonsterLevel = monsterLevel;
		data.MonsterRarity = rarity;
		data.ScaledMaxHealth = max(1, int(data.OriginalMaxHealth * healthMultiplier + 0.5));
		data.DamageMultiplier = damageMultiplier;
		data.XPValue = max(1, int((5.0 + sqrt(data.OriginalMaxHealth) * 2.5) *
			(1.0 + (monsterLevel - 1) * 0.08) * RarityXPMultiplier(rarity) + 0.5));
		data.GeneratedName = rarity > 0 ? GenerateMonsterName(mo, rarity) : mo.GetTag(mo.GetClassName());
		if (rerollAffixes) data.AffixFlags = RollOrdinaryMonsterAffixes(data.OriginalMaxHealth, rarity);
		data.RegenClock = 0;
		data.SwiftClock = 0;
		data.GlowClock = 0;
		data.AppliedGlowRarity = -1;
		data.SwiftLockedTarget = null;
		mo.A_SetHealth(max(1, int(data.ScaledMaxHealth * healthFraction + 0.5)));
		data.UpdateRarityGlow();
		data.ResetSignatureAttack();
	}

	void SynchronizeLivingMonsterLevels()
	{
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
		{
			let data = GetMonsterData(monster);
			if (!IsValidMonster(monster) || !data || data.MonsterRarity >= 6) continue;
			int anchoredLevel = RollMonsterLevel(data.MonsterRarity);
			if (anchoredLevel > data.MonsterLevel)
				ApplyOrdinaryMonsterScale(monster, data, anchoredLevel, data.MonsterRarity, false);
		}
	}

	bool UpgradeDirectorMonster(Actor monster, int targetRarity, bool assassin = false)
	{
		let data = GetMonsterData(monster);
		if (!IsValidMonster(monster) || !data || data.MonsterRarity >= 6) return false;
		targetRarity = clamp(max(targetRarity, data.MonsterRarity), 3, 5);
		int targetLevel = max(data.MonsterLevel, RollMonsterLevel(targetRarity) + (assassin ? 2 : 1));
		ApplyOrdinaryMonsterScale(monster, data, targetLevel, targetRarity, true);
		if (assassin) data.GeneratedName = String.Format("%s THE TRAIL ASSASSIN", PickLegendaryName()).MakeUpper();
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
			string warning = assassin ? "HELL DIRECTOR: A MYTHIC ASSASSIN FOUND YOUR TRAIL" :
				String.Format("HELL DIRECTOR: %s AWAKENED", data.GeneratedName.MakeUpper());
			SetLootNotification(playerNumber, warning, targetRarity);
			players[playerNumber].mo.A_Log(warning);
		}
		return true;
	}

	bool TrySpawnDirectorAssassin()
	{
		int chosenPlayer = -1;
		int choices = 0;
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber] || !players[playerNumber].mo || !DirectorTrailValid[playerNumber]) continue;
			double dx = players[playerNumber].mo.Pos.x - DirectorTrailPosition[playerNumber].x;
			double dy = players[playerNumber].mo.Pos.y - DirectorTrailPosition[playerNumber].y;
			if (dx * dx + dy * dy < 192.0 * 192.0) continue;
			choices++;
			if (Random[TuinRPGDirector](1, choices) == 1) chosenPlayer = playerNumber;
		}
		if (chosenPlayer < 0) return false;

		Vector3 origin = DirectorTrailPosition[chosenPlayer];
		for (int attempt = 0; attempt < 8; attempt++)
		{
			double angle = Random[TuinRPGDirector](0, 359);
			double radius = attempt == 0 ? 0.0 : 32.0 + attempt * 8.0;
			Vector3 position = (origin.x + cos(angle) * radius, origin.y + sin(angle) * radius, origin.z);
			Actor assassin = Actor.Spawn('TuinAssassinImp', position, NO_REPLACE);
			if (!assassin) continue;
			if (!assassin.TestMobjLocation())
			{
				assassin.Destroy();
				continue;
			}
			if (!GetMonsterData(assassin)) InitializeMonster(assassin);
			if (UpgradeDirectorMonster(assassin, 5, true))
			{
				assassin.bDORMANT = false;
				assassin.bAMBUSH = false;
				assassin.Target = players[chosenPlayer].mo;
				if (assassin.SeeState) assassin.SetState(assassin.SeeState);
				return true;
			}
			assassin.Destroy();
		}
		return false;
	}

	void UpdateHellDirector()
	{
		if (!CVInt('tuin_director_enabled', 1) || DirectorCheckpoint >= 3 ||
			level.total_monsters < max(8, CVInt('tuin_director_min_monsters', 12))) return;
		int threshold = (DirectorCheckpoint + 1) * 25;
		if (level.killed_monsters * 100 < level.total_monsters * threshold) return;
		DirectorCheckpoint++;

		int damageTaken = 0;
		int healthBudget = 0;
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			damageTaken += DirectorDamageTaken[playerNumber];
			DirectorDamageTaken[playerNumber] = 0;
			if (playerInGame[playerNumber] && players[playerNumber].mo)
				healthBudget += max(1, players[playerNumber].mo.GetMaxHealth(true));
		}
		if (healthBudget <= 0) return;
		double pressure = damageTaken * 100.0 / healthBudget;
		int targetRarity;
		if (pressure <= 20.0) targetRarity = 5;
		else if (pressure <= 50.0) targetRarity = 4;
		else if (pressure <= 85.0) targetRarity = 3;
		else return;

		double assassinChance = clamp(CVFloat('tuin_director_assassin_chance', 8.0), 0.0, 25.0);
		if (targetRarity >= 4 && FRandom[TuinRPGDirector](0.0, 100.0) < assassinChance && TrySpawnDirectorAssassin()) return;

		Actor candidate;
		Actor heavyCandidate;
		int candidateCount = 0;
		int heavyCandidateCount = 0;
		bool preferHeavy = HighestActivePlayerLevel() >= 15;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
		{
			let data = GetMonsterData(monster);
			if (!IsValidMonster(monster) || !monster.bCOUNTKILL || monster.bDORMANT || monster.bBOSS ||
				monster.bBOSSDEATH || !data || data.MonsterRarity >= targetRarity || IsIconicEpisodeBoss(monster)) continue;
			candidateCount++;
			if (Random[TuinRPGDirector](1, candidateCount) == 1) candidate = monster;
			if (preferHeavy && data.OriginalMaxHealth >= 500)
			{
				heavyCandidateCount++;
				if (Random[TuinRPGDirector](1, heavyCandidateCount) == 1) heavyCandidate = monster;
			}
		}
		if (heavyCandidate) candidate = heavyCandidate;
		if (candidate) UpgradeDirectorMonster(candidate, targetRarity);
	}

	void RerollLivingMonsters(int requestingPlayer)
	{
		int count = 0;
		ThinkerIterator it = ThinkerIterator.Create('Actor');
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			let data = GetMonsterData(mo);
			if (IsValidMonster(mo) && data)
			{
				RerollMonster(mo, data);
				count++;
			}
		}
		if (requestingPlayer >= 0 && requestingPlayer < TUIN_MAX_PLAYERS && players[requestingPlayer].mo)
			players[requestingPlayer].mo.A_Log(String.Format("Rerolled %d living RPG monsters.", count));
	}

	void RebalanceLivingMonstersForDifficulty(int requestingPlayer)
	{
		int count = 0;
		int playerProgress = HighestActivePlayerLevel();
		ThinkerIterator it = ThinkerIterator.Create('Actor');
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			let data = GetMonsterData(mo);
			if (!IsValidMonster(mo) || !data || data.OriginalMaxHealth <= 0) continue;
			double healthFraction = clamp(double(mo.Health) / max(1, data.ScaledMaxHealth), 0.0, 1.0);
			double levelHealth = 1.0 + (data.MonsterLevel - 1) * max(0.0,
				CVFloat('tuin_health_scale', 0.05)) * DifficultyHealthLevelFactor();
			double levelDamage = 1.0 + (data.MonsterLevel - 1) * max(0.0,
				CVFloat('tuin_damage_scale', 0.02)) * DifficultyDamageLevelFactor();
			if (data.MonsterRarity >= 6)
			{
				int bossHealthBase = FinaleBossHealthBase(mo, data.OriginalMaxHealth);
				data.ScaledMaxHealth = max(data.OriginalMaxHealth, int(bossHealthBase * levelHealth *
					FinaleBossHealthMultiplier(mo, playerProgress) + 0.5));
				data.DamageMultiplier = levelDamage * FinaleBossDamageMultiplier(mo, playerProgress);
				data.AffixFlags = RollFinaleBossAffixes(mo, playerProgress);
			}
			else
			{
				data.ScaledMaxHealth = max(1, int(data.OriginalMaxHealth * levelHealth *
					RarityHealthMultiplier(data.MonsterRarity) + 0.5));
				data.DamageMultiplier = levelDamage * RarityDamageMultiplier(data.MonsterRarity);
				data.AffixFlags = RollOrdinaryMonsterAffixes(data.OriginalMaxHealth, data.MonsterRarity);
			}
			data.RegenClock = 0;
			data.SwiftClock = 0;
			data.GlowClock = 0;
			data.SwiftLockedTarget = null;
			mo.A_SetHealth(max(1, int(data.ScaledMaxHealth * healthFraction + 0.5)));
			data.ResetSignatureAttack();
			count++;
		}

		if (requestingPlayer >= 0 && requestingPlayer < TUIN_MAX_PLAYERS &&
			playerInGame[requestingPlayer] && players[requestingPlayer].mo)
		{
			double effectiveHealth = CVFloat('tuin_health_scale', 0.05) * DifficultyHealthLevelFactor() * 100.0;
			double effectiveDamage = CVFloat('tuin_damage_scale', 0.02) * DifficultyDamageLevelFactor() * 100.0;
			string modeName = DifficultyMode() == 0 ? "EASY" : DifficultyMode() == 1 ? "NORMAL" :
				DifficultyMode() == 2 ? "HARD" : "CRAZY";
			string message = String.Format("HEALTH +%.2f%%/LVL  |  DAMAGE +%.2f%%/LVL  |  RARITY x%.2f  |  MAX BUFFS %d",
				effectiveHealth, effectiveDamage, DifficultyRarityChanceFactor(), DifficultyAffixMaximum());
			DifficultyNoticeTitle[requestingPlayer] = String.Format("TUIN RPG DIFFICULTY: %s", modeName);
			DifficultyNoticeStats[requestingPlayer] = message;
			DifficultyNoticeTics[requestingPlayer] = 210;
			players[requestingPlayer].mo.A_Log(String.Format("Tuin RPG difficulty changed. %s (%d monsters rebalanced)",
				String.Format("%s - %s", modeName, message), count));
		}
	}

	static void SetServerFloat(Name key, double value)
	{
		let cv = CVar.FindCVar(key);
		if (cv) cv.SetFloat(value);
	}

	static void SetServerInt(Name key, int value)
	{
		let cv = CVar.FindCVar(key);
		if (cv) cv.SetInt(value);
	}

	void ResetRarityDefaults()
	{
		SetServerInt('tuin_rarity_enabled', 1);
		SetServerFloat('tuin_rarity_uncommon_chance', 15.0);
		SetServerFloat('tuin_rarity_rare_chance', 7.0);
		SetServerFloat('tuin_rarity_elite_chance', 2.5);
		SetServerFloat('tuin_rarity_legendary_chance', 1.00);
		SetServerFloat('tuin_rarity_mythic_chance', 0.50);
		SetServerInt('tuin_affix_maximum', 5);
	}

	void SetAllMythicPreset()
	{
		SetServerInt('tuin_rarity_enabled', 1);
		SetServerFloat('tuin_rarity_uncommon_chance', 0.0);
		SetServerFloat('tuin_rarity_rare_chance', 0.0);
		SetServerFloat('tuin_rarity_elite_chance', 0.0);
		SetServerFloat('tuin_rarity_legendary_chance', 0.0);
		SetServerFloat('tuin_rarity_mythic_chance', 100.0);
	}

	void MigrateBalanceDefaults()
	{
		let migrated = CVar.FindCVar('tuin_balance_migrated_021');
		if (!migrated || migrated.GetBool()) return;
		let armored = CVar.FindCVar('tuin_affix_armored_reduction');
		let berserker = CVar.FindCVar('tuin_affix_berserker_multiplier');
		if (armored && abs(armored.GetFloat() - 0.20) < 0.001) armored.SetFloat(0.50);
		if (berserker && abs(berserker.GetFloat() - 1.50) < 0.001) berserker.SetFloat(2.00);
		migrated.SetBool(true);
	}

	void MigrateRarityDefaults()
	{
		let migrated = CVar.FindCVar('tuin_rarity_migrated_023');
		if (!migrated || migrated.GetBool()) return;
		let legendary = CVar.FindCVar('tuin_rarity_legendary_chance');
		let mythic = CVar.FindCVar('tuin_rarity_mythic_chance');
		if (legendary && abs(legendary.GetFloat() - 0.45) < 0.001) legendary.SetFloat(1.00);
		if (mythic && abs(mythic.GetFloat() - 0.05) < 0.001) mythic.SetFloat(0.50);
		migrated.SetBool(true);
	}

	void MigrateWeaponDropDefaults()
	{
		let migrated = CVar.FindCVar('tuin_weapon_drop_migrated_044');
		if (!migrated || migrated.GetBool()) return;
		let dropChance = CVar.FindCVar('tuin_weapon_drop_chance');
		if (dropChance && abs(dropChance.GetFloat() - 0.75) < 0.001) dropChance.SetFloat(1.50);
		migrated.SetBool(true);
	}

	void MigrateCoinDropDefault()
	{
		let migrated = CVar.FindCVar('tuin_coin_drop_migrated_072');
		if (!migrated || migrated.GetBool()) return;
		let dropChance = CVar.FindCVar('tuin_coin_drop_chance');
		if (dropChance && (abs(dropChance.GetFloat() - 10.0) < 0.001 ||
			abs(dropChance.GetFloat() - 45.0) < 0.001)) dropChance.SetFloat(25.0);
		migrated.SetBool(true);
	}

	void MigrateWeaponInspectionDefaults()
	{
		let migrated = CVar.FindCVar('tuin_weapon_inspect_migrated_083');
		if (!migrated || migrated.GetBool()) return;
		let maximumDistance = CVar.FindCVar('tuin_weapon_inspect_distance');
		let nearbyDistance = CVar.FindCVar('tuin_weapon_near_inspect_distance');
		if (maximumDistance && abs(maximumDistance.GetFloat() - 512.0) < 0.001) maximumDistance.SetFloat(256.0);
		if (nearbyDistance && abs(nearbyDistance.GetFloat() - 160.0) < 0.001) nearbyDistance.SetFloat(80.0);
		migrated.SetBool(true);
	}

	void MigrateExpandedAffixDefaults()
	{
		let migrated = CVar.FindCVar('tuin_affix_migrated_090');
		if (!migrated || migrated.GetBool()) return;
		let maximum = CVar.FindCVar('tuin_affix_maximum');
		if (maximum && maximum.GetInt() == 4) maximum.SetInt(5);
		migrated.SetBool(true);
	}

	void MigrateNativeBossGodlyDefault()
	{
		let migrated = CVar.FindCVar('tuin_native_boss_godly_migrated_110');
		if (!migrated || migrated.GetBool()) return;
		let chance = CVar.FindCVar('tuin_native_boss_godly_chance');
		if (chance && abs(chance.GetFloat() - 1.0) < 0.001) chance.SetFloat(0.25);
		migrated.SetBool(true);
	}

	void MigrateBossGodlyDefaults()
	{
		let migrated = CVar.FindCVar('tuin_boss_godly_migrated_111');
		if (!migrated || migrated.GetBool()) return;
		let finaleChance = CVar.FindCVar('tuin_boss_godly_weapon_chance');
		let nativeChance = CVar.FindCVar('tuin_native_boss_godly_chance');
		if (finaleChance && abs(finaleChance.GetFloat() - 5.0) < 0.001) finaleChance.SetFloat(100.0);
		if (nativeChance && (abs(nativeChance.GetFloat() - 0.25) < 0.001 ||
			abs(nativeChance.GetFloat() - 1.0) < 0.001)) nativeChance.SetFloat(5.0);
		migrated.SetBool(true);
	}

	void MigrateScalingDefaults()
	{
		let migrated = CVar.FindCVar('tuin_scaling_migrated_121');
		if (!migrated || migrated.GetBool()) return;
		let health = CVar.FindCVar('tuin_health_scale');
		let damage = CVar.FindCVar('tuin_damage_scale');
		double oldHealth;
		double oldDamage;
		double newHealth;
		double newDamage;
		switch (DifficultyMode())
		{
		case 0: oldHealth = 0.0175; oldDamage = 0.010; newHealth = 0.025; newDamage = 0.012; break;
		case 1: oldHealth = 0.025; oldDamage = 0.014; newHealth = 0.045; newDamage = 0.020; break;
		case 3: oldHealth = 0.075; oldDamage = 0.027; newHealth = 0.100; newDamage = 0.040; break;
		default: oldHealth = 0.050; oldDamage = 0.020; newHealth = 0.070; newDamage = 0.028; break;
		}
		// Preserve deliberate custom slider values; only migrate a known old profile.
		if (health && damage && abs(health.GetFloat() - oldHealth) < 0.0001 &&
			abs(damage.GetFloat() - oldDamage) < 0.0001)
		{
			health.SetFloat(newHealth);
			damage.SetFloat(newDamage);
		}
		migrated.SetBool(true);
	}

	override void NewGame()
	{
		PreviousLoadedCampaignMap = 0;
		CurrentLoadedCampaignMap = 0;
		MonsterLevelsSynchronized = false;
		DirectorCheckpoint = 0;
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
		{
			DirectorDamageTaken[i] = 0;
			DirectorTrailValid[i] = false;
		}
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++) CatchupHandled[i] = false;
		MigrateBalanceDefaults();
		MigrateRarityDefaults();
		MigrateWeaponDropDefaults();
		MigrateCoinDropDefault();
		MigrateWeaponInspectionDefaults();
		MigrateExpandedAffixDefaults();
		MigrateNativeBossGodlyDefault();
		MigrateBossGodlyDefaults();
		MigrateScalingDefaults();
	}

	override void WorldLoaded(WorldEvent e)
	{
		if (!e.IsSaveGame)
		{
			FinaleBossPromoted = false;
			FinaleBoss = null;
			JohnMerchant = null;
			MonsterLevelsSynchronized = false;
			DirectorCheckpoint = 0;
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
			{
				DirectorDamageTaken[i] = 0;
				DirectorTrailValid[i] = false;
			}
			PreviousLoadedCampaignMap = CurrentLoadedCampaignMap;
			CurrentLoadedCampaignMap = level.LevelNum;
			if (CurrentLoadedCampaignMap <= 0) CurrentLoadedCampaignMap = max(1, MapsVisited + 1);
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++) CatchupHandled[i] = false;
		}
		MigrateBalanceDefaults();
		MigrateRarityDefaults();
		MigrateWeaponDropDefaults();
		MigrateCoinDropDefault();
		MigrateWeaponInspectionDefaults();
		MigrateExpandedAffixDefaults();
		MigrateNativeBossGodlyDefault();
		MigrateBossGodlyDefaults();
		MigrateScalingDefaults();
		AppliedDifficultyMode = DifficultyMode();
		if (!e.IsSaveGame) MapsVisited++;
	}
	override void PlayerEntered(PlayerEvent e) { EnsurePlayerData(e.PlayerNumber); }
	override void PlayerSpawned(PlayerEvent e) { EnsurePlayerData(e.PlayerNumber); }
	override void PlayerRespawned(PlayerEvent e) { EnsurePlayerData(e.PlayerNumber); }
	override void WorldThingSpawned(WorldEvent e)
	{
		InitializeMonster(e.Thing);
		ScaleSpawnedAmmo(e.Thing);
	}

	override void CheckReplacement(ReplaceEvent e)
	{
		// E2M8 and E3M8 normally call A_BossDeath from the stock actor's final
		// death frame, immediately ending the episode. Replace only those exact
		// finale actors with visually identical subclasses whose death animation
		// stops before that call. This leaves every other map and custom boss alone.
		if (level.MapName ~== "E2M8" && e.Replacee == 'Cyberdemon')
		{
			e.Replacement = 'TuinFinaleCyberdemon';
			e.IsFinal = true;
		}
		else if (level.MapName ~== "E3M8" && e.Replacee == 'SpiderMastermind')
		{
			e.Replacement = 'TuinFinaleSpiderMastermind';
			e.IsFinal = true;
		}
	}

	override void WorldThingRevived(WorldEvent e)
	{
		let data = GetMonsterData(e.Thing);
		if (data)
		{
			data.LastPlayerNumber = -1;
			data.BleedPulsesRemaining = 0;
			data.BleedPlayerNumber = -1;
			data.BleedResistanceTics = 0;
			data.BleedDamageRemaining = 0;
			if (e.Thing.Health > 0 && e.Thing.Health < data.ScaledMaxHealth) e.Thing.A_SetHealth(data.ScaledMaxHealth);
		}
		else InitializeMonster(e.Thing);
	}

	static int PlayerNumberFromSource(Actor source, Actor inflictor)
	{
		if (source && source.player) return source.PlayerNumber();
		if (inflictor && inflictor.target && inflictor.target.player) return inflictor.target.PlayerNumber();
		return -1;
	}

	static TuinMonsterData MonsterDataFromSource(Actor source, Actor inflictor)
	{
		let data = GetMonsterData(source);
		if (!data && inflictor) data = GetMonsterData(inflictor.target);
		return data;
	}

	void SpawnDamageNumber(int playerNumber, Actor victim, int amount, bool critical, bool bleeding = false)
	{
		if (!CVInt('tuin_damage_numbers', 1) || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS ||
			!victim || amount <= 0) return;
		// Combine damage delivered during the same short burst. A shotgun should make
		// one useful total, not cover the monster in a number for every pellet.
		for (int i = 0; i < TUIN_MAX_DAMAGE_NUMBERS; i++)
		{
			if (DamageNumberTics[i] >= TUIN_DAMAGE_NUMBER_LIFETIME - 3 &&
				DamageNumberPlayer[i] == playerNumber && DamageNumberVictim[i] == victim &&
				DamageNumberBleed[i] == bleeding)
			{
				DamageNumberAmount[i] += amount;
				DamageNumberCritical[i] = DamageNumberCritical[i] || critical;
				DamageNumberTics[i] = TUIN_DAMAGE_NUMBER_LIFETIME;
				DamageNumberPosition[i] = victim.Pos + (0, 0, victim.Height * 0.72);
				return;
			}
		}
		int slot = NextDamageNumber;
		NextDamageNumber = (NextDamageNumber + 1) % TUIN_MAX_DAMAGE_NUMBERS;
		DamageNumberVictim[slot] = victim;
		DamageNumberPosition[slot] = victim.Pos + (0, 0, victim.Height * 0.72);
		DamageNumberAmount[slot] = amount;
		DamageNumberTics[slot] = TUIN_DAMAGE_NUMBER_LIFETIME;
		DamageNumberPlayer[slot] = playerNumber;
		DamageNumberCritical[slot] = critical;
		DamageNumberBleed[slot] = bleeding;
		DamageNumberCurl[slot] = FRandom[TuinRPGDamageNumber](-1.0, 1.0);
	}

	void ApplyRogueBleed(int playerNumber, TuinMonsterData data, int triggeringCriticalDamage)
	{
		if (!data || !data.Owner || data.Owner.Health <= 0 || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS || triggeringCriticalDamage <= 0) return;
		// Bleeding cannot be refreshed or stacked. This keeps rapid-fire weapons,
		// including Tuin's Lead Spitter, from maintaining permanent percentage damage.
		if (data.BleedPulsesRemaining > 0 || data.BleedResistanceTics > 0) return;
		data.BleedPulsesRemaining = 8;
		data.BleedNextTime = level.Time + 35;
		data.BleedPlayerNumber = playerNumber;
		// Repeat one full critical hit over eight seconds, but never take more than
		// 24% of the monster's scaled maximum health through a single Bleed.
		int healthCap = max(1, int(max(1, data.ScaledMaxHealth) * 0.24 + 0.5));
		data.BleedDamageRemaining = min(triggeringCriticalDamage, healthCap);
		data.LastPlayerNumber = playerNumber;
	}

	int DiminishRPGBonusDamage(Actor victim, TuinMonsterData data, int rawBonusDamage)
	{
		if (!victim || !data || rawBonusDamage <= 0) return max(0, rawBonusDamage);
		// Rarity 6 is the explicit TuinRPG boss state. Do not use Doom's BOSSDEATH
		// flag here: Baron-family actors carry it even during ordinary encounters.
		bool rpgBoss = data.MonsterRarity >= 6;
		bool finaleBoss = data.MonsterRarity >= 6 && IsIconicEpisodeBoss(victim);
		// Common and Uncommon monsters remain completely unrestricted.
		if (!rpgBoss && data.MonsterRarity < 2) return rawBonusDamage;

		double thresholdPercent = finaleBoss ? 0.08 : rpgBoss ? 0.15 : 0.25;
		double overflowFactor = finaleBoss ? 0.15 : rpgBoss ? 0.20 : 0.25;
		int threshold = max(1, int(max(1, data.ScaledMaxHealth) * thresholdPercent + 0.5));
		// One short window catches BFG tracers, shotgun pellets, and rapid bursts as
		// a group instead of allowing every individual damage event a fresh limit.
		if (data.RPGBonusWindowEndTime <= level.Time)
		{
			data.RPGBonusWindowEndTime = level.Time + 18;
			data.RPGBonusWindowRawDamage = 0;
		}
		int unrestricted = min(rawBonusDamage, max(0, threshold - data.RPGBonusWindowRawDamage));
		int overflow = max(0, rawBonusDamage - unrestricted);
		data.RPGBonusWindowRawDamage = min(2000000000,
			data.RPGBonusWindowRawDamage + rawBonusDamage);
		return unrestricted + int(overflow * overflowFactor + 0.5);
	}

	void UpdateMonsterBleeds()
	{
		foreach (sector: level.Sectors)
		{
			for (Actor victim = sector.thinglist; victim; victim = victim.snext)
			{
				let data = GetMonsterData(victim);
				if (!data || data.BleedPulsesRemaining <= 0 || victim.Health <= 0 ||
					level.Time < data.BleedNextTime) continue;
				int attacker = data.BleedPlayerNumber;
				Actor source = attacker >= 0 && attacker < TUIN_MAX_PLAYERS && playerInGame[attacker] ?
					players[attacker].mo : null;
				// Divide the stored critical damage over the pulses without losing integer
				// remainders: a 500-damage crit becomes four 63s and four 62s.
				int damage = max(1, (data.BleedDamageRemaining + data.BleedPulsesRemaining - 1) /
					data.BleedPulsesRemaining);
				data.BleedDamageRemaining = max(0, data.BleedDamageRemaining - damage);
				damage = min(victim.Health, damage);
				SpawnDamageNumber(attacker, victim, damage, false, true);
				ApplyingBonusDamage = true;
				victim.DamageMobj(source, source, damage, 'TuinBleed', DMG_FORCED);
				ApplyingBonusDamage = false;
				data.BleedPulsesRemaining--;
				data.BleedNextTime += 35;
				if (data.BleedPulsesRemaining <= 0)
				{
					data.BleedPlayerNumber = -1;
					data.BleedDamageRemaining = 0;
					data.BleedResistanceTics = 12 * 35;
				}
			}
		}
	}

	override void WorldThingDamaged(WorldEvent e)
	{
		if (!CVInt('tuin_enabled', 1) || !e.Thing || e.Damage <= 0) return;
		int attacker = PlayerNumberFromSource(e.DamageSource, e.Inflictor);
		let victimData = GetMonsterData(e.Thing);
		if (victimData)
		{
			if (attacker >= 0) victimData.LastPlayerNumber = attacker;
			// A healer under fire cannot sustain itself until it has avoided damage for two seconds.
			victimData.HealerSelfLockTics = 70;
		}
		if (e.Thing.player)
		{
			int hurtPlayer = e.Thing.PlayerNumber();
			if (hurtPlayer >= 0 && hurtPlayer < TUIN_MAX_PLAYERS)
				DirectorDamageTaken[hurtPlayer] = min(1000000, DirectorDamageTaken[hurtPlayer] + e.Damage);
			let hurtData = GetPlayerData(e.Thing);
			if (hurtData && hurtData.PlayerClass == 5)
			{
				hurtData.RogueStillTics = 0;
				if (hurtData.RogueVeiled) BreakRogueVeil(hurtPlayer, hurtData);
			}
		}
		if (ApplyingBonusDamage) return;
		double multiplier = 1.0;
		double playerBaseDamageFactor = 1.0;
		double targetBaseDamageFactor = 1.0;
		bool bloodPunchAttack = e.DamageType == 'TuinBloodPunch';
		if ((e.Thing is 'Cyberdemon' || e.Thing is 'SpiderMastermind') &&
			IsBFGDamage(e.Inflictor, e.DamageSource, e.DamageType))
			targetBaseDamageFactor = 0.25;
		bool wasCritical = false;
		bool rogueAmbushAttack = false;
		int victimHealthBefore = e.Thing.Health;
		let sourceMonsterData = MonsterDataFromSource(e.DamageSource, e.Inflictor);
		if (sourceMonsterData)
		{
			multiplier *= sourceMonsterData.DamageMultiplier;
			if ((sourceMonsterData.AffixFlags & TuinMonsterData.AFFIX_BERSERKER) && sourceMonsterData.Owner &&
				sourceMonsterData.Owner.Health * 100 <= sourceMonsterData.ScaledMaxHealth * 40)
				multiplier *= clamp(CVFloat('tuin_affix_berserker_multiplier', 1.50), 1.0, 3.0);

			if ((sourceMonsterData.AffixFlags & TuinMonsterData.AFFIX_VAMPIRIC) && sourceMonsterData.Owner &&
				e.Thing.player && sourceMonsterData.Owner.Health > 0)
			{
				double drain = clamp(CVFloat('tuin_affix_vampiric_percent', 0.20), 0.0, 1.0);
				int healing = sourceMonsterData.AdjustHealingReceived(max(1, int(e.Damage * drain + 0.5)));
				sourceMonsterData.Owner.A_SetHealth(min(sourceMonsterData.ScaledMaxHealth, sourceMonsterData.Owner.Health + healing));
			}
			if ((sourceMonsterData.AffixFlags & TuinMonsterData.AFFIX_POISONOUS) && e.Thing.player)
			{
				int poisonedPlayer = e.Thing.PlayerNumber();
				if (poisonedPlayer >= 0 && poisonedPlayer < TUIN_MAX_PLAYERS)
				{
					bool newlyPoisoned = PoisonTics[poisonedPlayer] <= 0;
					PoisonTics[poisonedPlayer] = clamp(CVInt('tuin_affix_poison_duration', 4), 1, 20) * 35;
					PoisonDamage[poisonedPlayer] = max(PoisonDamage[poisonedPlayer], max(1,
						int(CVFloat('tuin_affix_poison_base_damage', 2.0) + sourceMonsterData.MonsterLevel *
						CVFloat('tuin_affix_poison_damage_per_level', 0.5) + 0.5)));
					PoisonSource[poisonedPlayer] = sourceMonsterData.Owner;
					if (newlyPoisoned) SetLootNotification(poisonedPlayer, "POISONED", 0);
				}
			}
		}
		if (attacker >= 0 && attacker < TUIN_MAX_PLAYERS)
		{
			let playerData = EnsurePlayerData(attacker);
			if (playerData)
			{
				if (playerData.PlayerClass == 1) playerBaseDamageFactor = 1.0;
				else if (playerData.PlayerClass == 2) playerBaseDamageFactor = 0.75;
				else if (playerData.PlayerClass == 3)
					multiplier *= 1.30 + playerData.PerkClassMastery * 0.03;
				else if (playerData.PlayerClass == 4) multiplier *= 1.10;
				bool firstAmbushHit = playerData.PlayerClass == 5 &&
					(playerData.RogueVeiled || playerData.RogueAmbushGraceTics > 0);
				bool rogueAmbush = firstAmbushHit ||
					(playerData.PlayerClass == 5 && playerData.RogueAmbushHitTime == level.Time);
				if (rogueAmbush && victimData)
				{
					rogueAmbushAttack = true;
					let readyWeapon = players[attacker].ReadyWeapon;
					bool melee = IsRogueMeleeWeapon(readyWeapon);
					double ambushMultiplier = melee ? (playerData.PerkCapstone ? 30.0 : 20.0) :
						(playerData.PerkCapstone ? 6.0 : 4.0);
					if (victimData.MonsterRarity >= 6 && IsIconicEpisodeBoss(e.Thing))
						ambushMultiplier = min(ambushMultiplier, melee ?
							(playerData.PerkCapstone ? 7.0 : 5.0) : (playerData.PerkCapstone ? 3.0 : 2.0));
					multiplier *= ambushMultiplier;
					wasCritical = true;
					if (playerData.RogueVeiled) BreakRogueVeil(attacker, playerData, true);
					if (firstAmbushHit)
					{
						playerData.RogueAmbushGraceTics = 0;
						playerData.RogueAmbushHitTime = level.Time;
						SetLootNotification(attacker, String.Format("AMBUSH x%.0f!", ambushMultiplier), 5);
					}
				}
				if (playerBaseDamageFactor < 1.0)
					e.NewDamage = max(1, int(e.Damage * playerBaseDamageFactor + 0.5));
				multiplier *= 1.0 + playerData.Strength * 0.02;
				int variantIndex = bloodPunchAttack ? -1 : ActiveWeaponVariantIndex(attacker, playerData);
				if (victimData && !bloodPunchAttack && !IsGrenadeDamage(e.Inflictor, e.DamageType) &&
					FRandom[TuinRPGCritical](0.0, 100.0) < TotalCriticalChance(playerData, variantIndex))
				{
					multiplier *= playerData.PlayerClass == 3 && playerData.PerkCapstone ? 2.5 : 2.0;
					wasCritical = true;
					CriticalPopupTics[attacker] = 18;
				}
				if (variantIndex >= 0)
				{
					multiplier *= 1.0 + WeaponItemLevelPowerPercent(playerData.VariantItemLevel[variantIndex]) * 0.01;
					if (playerData.VariantPowerPercent[variantIndex] > 0) multiplier *= 1.0 + playerData.VariantPowerPercent[variantIndex] * 0.01;
					if (playerData.VariantExecutionPercent[variantIndex] > 0 && victimData && e.Thing.Health * 100 <= victimData.ScaledMaxHealth * 30)
						multiplier *= 1.0 + playerData.VariantExecutionPercent[variantIndex] * 0.01;
					if (playerData.VariantLeechPercent[variantIndex] > 0 && victimData && players[attacker].mo && players[attacker].mo.Health > 0)
					{
						int healing = max(1, int(e.Damage * targetBaseDamageFactor *
							playerData.VariantLeechPercent[variantIndex] * 0.01 + 0.5));
						players[attacker].mo.A_SetHealth(min(players[attacker].mo.GetMaxHealth(true), players[attacker].mo.Health + healing));
					}
				}
			}
		}
		int bonusDamage = int(e.Damage * playerBaseDamageFactor * (multiplier - 1.0) + 0.5);
		if (victimData && bonusDamage > 0)
			bonusDamage = DiminishRPGBonusDamage(e.Thing, victimData, bonusDamage);
		if (bonusDamage > 0 && e.Thing.Health > 0)
		{
			ApplyingBonusDamage = true;
			e.Thing.DamageMobj(e.Inflictor, e.DamageSource, bonusDamage, e.DamageType, e.DamageFlags, e.DamageAngle);
			ApplyingBonusDamage = false;
		}
		if (victimData && attacker >= 0)
		{
			int baseDamage = max(1, int(e.Damage * playerBaseDamageFactor * targetBaseDamageFactor + 0.5));
			int effectiveBonusDamage = int(max(0, bonusDamage) * targetBaseDamageFactor + 0.5);
			int totalDamage = baseDamage + effectiveBonusDamage;
			SpawnDamageNumber(attacker, e.Thing, totalDamage, wasCritical);
			let attackData = EnsurePlayerData(attacker);
			if (attackData && attackData.PlayerClass == 5 && !rogueAmbushAttack)
				AddRogueDamageCharge(attacker, attackData, min(totalDamage, max(0, victimHealthBefore)));
			if (attackData && attackData.PlayerClass == 1 && !attackData.TankOverdriveActive)
				AddTankDamageCharge(attacker, attackData, min(totalDamage, max(0, victimHealthBefore)));
			if (attackData && attackData.PlayerClass == 4 && !bloodPunchAttack)
				AddDoomBloodPunchCharge(attacker, attackData, min(totalDamage, max(0, victimHealthBefore)));
			int attackVariant = attackData ? ActiveWeaponVariantIndex(attacker, attackData) : -1;
			bool leadSpitterCritical = attackVariant >= 0 &&
				attackData.VariantQuality[attackVariant] == TUIN_LEAD_SPITTER_QUALITY;
			if (wasCritical && attackData && (attackData.PlayerClass == 5 || leadSpitterCritical) && e.Thing.Health > 0)
				ApplyRogueBleed(attacker, victimData, totalDamage);
			let leechData = attackData;
			if (leechData && leechData.PerkBloodDrinker > 0 && players[attacker].mo && players[attacker].mo.Health > 0)
			{
				int perkHealing = int(totalDamage * leechData.PerkBloodDrinker * 0.01);
				if (perkHealing > 0) players[attacker].mo.A_SetHealth(min(players[attacker].mo.GetMaxHealth(true),
					players[attacker].mo.Health + perkHealing));
			}
		}
	}

	void AwardXP(int playerNumber, int amount)
	{
		if (!CVInt('tuin_player_leveling', 1) || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS) return;
		let data = EnsurePlayerData(playerNumber);
		if (!data) return;
		double luckChance = 1.0 - exp(log(0.97) * max(0, data.Luck));
		if (FRandom[TuinRPGLuck](0.0, 1.0) < luckChance) amount += max(1, amount / 4);
		data.CurrentXP += amount;
		PopupXP[playerNumber] += amount;
		PopupTics[playerNumber] = 70;
		while (data.CurrentXP >= XPRequired(data.PlayerLevel))
		{
			data.CurrentXP -= XPRequired(data.PlayerLevel);
			data.PlayerLevel++;
			data.UnspentStatPoints++;
			bool gainedPerk = (data.PlayerLevel % 5) == 0;
			if (gainedPerk) data.UnspentSkillPoints++;
			if (players[playerNumber].mo) players[playerNumber].mo.A_Log(String.Format(
				gainedPerk ? "LEVEL UP! You are now level %d. +1 stat point, +1 perk point" :
				"LEVEL UP! You are now level %d. +1 stat point", data.PlayerLevel));
		}
	}

	void GiveTestLevels(int playerNumber, int amount)
	{
		let data = EnsurePlayerData(playerNumber);
		if (!data) return;
		amount = clamp(amount, 1, 100);
		for (int i = 0; i < amount; i++)
		{
			data.PlayerLevel++;
			data.UnspentStatPoints++;
			if ((data.PlayerLevel % 5) == 0) data.UnspentSkillPoints++;
		}
		if (players[playerNumber].mo)
			players[playerNumber].mo.A_Log(String.Format("TEST CHEAT: gained %d level%s. Now level %d with %d stat points.",
				amount, amount == 1 ? "" : "s", data.PlayerLevel, data.UnspentStatPoints));
	}

	override void WorldThingDied(WorldEvent e)
	{
		let data = GetMonsterData(e.Thing);
		if (!data) return;
		e.Thing.A_RemoveLight('TuinSignatureTell');
		int killer = PlayerNumberFromSource(e.DamageSource, e.Inflictor);
		if (killer < 0) killer = data.LastPlayerNumber;
		if (data.MonsterRarity >= 6 && killer < 0)
		{
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
				if (playerInGame[i] && players[i].mo) { killer = i; break; }
		}
		int xpAward = data.XPValue;
		if (killer >= 0)
		{
			let playerData = EnsurePlayerData(killer);
			int variantIndex = ActiveWeaponVariantIndex(killer, playerData);
			if (variantIndex >= 0)
				xpAward = int(xpAward * (1.0 + playerData.VariantProsperityPercent[variantIndex] * 0.01) + 0.5);
			AwardXP(killer, xpAward);
			TryDropWeapon(e.Thing, data, killer);
		}
		SpawnCoinReward(e.Thing, data);
		if (!IsIconicEpisodeFinale() && !FinaleBossPromoted) TryPromoteFinaleBoss();
		if (data.MonsterRarity >= 6 && !JohnMerchant)
		{
			Actor johnAnchor = killer >= 0 && killer < TUIN_MAX_PLAYERS ? players[killer].mo : null;
			if (johnAnchor && (!IsIconicEpisodeFinale() || !HasLivingIconicEpisodeBoss())) SpawnJohnMerchant(johnAnchor);
		}

		if (data.AffixFlags & TuinMonsterData.AFFIX_EXPLOSIVE)
		{
			int explosionDamage = max(12, int(data.MonsterLevel * CVFloat('tuin_affix_explosive_damage_per_level', 3.0)));
			double radius = clamp(CVFloat('tuin_affix_explosive_radius', 96.0), 32.0, 256.0);
			e.Thing.A_Explode(explosionDamage, radius, 0, false, 0.0, 0, 0, 'BulletPuff', 'Fire');
		}
	}

	void UpdateTarget(int playerNumber)
	{
		TargetName[playerNumber] = "";
		TargetAffixes[playerNumber] = "";
		TargetHealth[playerNumber] = 0;
		TargetMaxHealth[playerNumber] = 0;
		TargetLevel[playerNumber] = 0;
		TargetRarity[playerNumber] = 0;
		int healthBarMode = CVInt('tuin_healthbar_mode', 1);
		if (!CVInt('tuin_enabled', 1) || healthBarMode == 3 || !playerInGame[playerNumber]) return;
		Actor pawn = players[playerNumber].mo;
		if (!pawn || pawn.Health <= 0) return;
		FLineTraceData trace;
		double distance = max(64.0, CVFloat('tuin_healthbar_distance', 2048.0));
		if (!pawn.LineTrace(pawn.Angle, distance, pawn.Pitch, 0, pawn.Height * 0.5, data: trace)) return;
		Actor target = trace.HitActor;
		let data = GetMonsterData(target);
		if (!data || target.Health <= 0 || target.bFRIENDLY) return;
		TargetName[playerNumber] = data.GeneratedName.Length() ? data.GeneratedName : target.GetTag(target.GetClassName());
		TargetAffixes[playerNumber] = AffixList(data);
		TargetHealth[playerNumber] = max(0, target.Health);
		TargetMaxHealth[playerNumber] = max(1, data.ScaledMaxHealth);
		TargetPreviousDisplayHealth[playerNumber] = data.PreviousDisplayHealth;
		TargetDisplayHealth[playerNumber] = data.DisplayHealth;
		TargetLevel[playerNumber] = data.MonsterLevel;
		TargetRarity[playerNumber] = data.MonsterRarity;
	}

	clearscope static string CompactOverheadName(string value)
	{
		if (value.Length() <= 24) return value;
		return String.Format("%s...", value.Left(21));
	}

	clearscope static string CompactAffixList(TuinMonsterData data)
	{
		if (!data) return "";
		string result = "";
		if (data.AffixFlags & TuinMonsterData.AFFIX_SWIFT) result.AppendFormat("SWIFT");
		if (data.AffixFlags & TuinMonsterData.AFFIX_ARMORED) result.AppendFormat("%sARMOR", result.Length() ? " / " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_REGENERATING) result.AppendFormat("%sREGEN", result.Length() ? " / " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_BERSERKER) result.AppendFormat("%sRAGE", result.Length() ? " / " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_EXPLOSIVE) result.AppendFormat("%sBOOM", result.Length() ? " / " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_VAMPIRIC) result.AppendFormat("%sLEECH", result.Length() ? " / " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_POISONOUS) result.AppendFormat("%sPOISON", result.Length() ? " / " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_HEALER) result.AppendFormat("%sHEAL", result.Length() ? " / " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_WARDING) result.AppendFormat("%sWARD", result.Length() ? " / " : "");
		else if (data.WardTics > 0) result.AppendFormat("%sWARDED", result.Length() ? " / " : "");
		if (data.BleedPulsesRemaining > 0) result.AppendFormat("%sBLEED", result.Length() ? " / " : "");
		return result;
	}

	void RefreshOverheadMonsters(int playerNumber)
	{
		OverheadCount = 0;
		int healthBarMode = CVInt('tuin_healthbar_mode', 1);
		if (!CVInt('tuin_enabled', 1) || (healthBarMode != 1 && healthBarMode != 2) ||
			playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS || !playerInGame[playerNumber]) return;
		Actor viewer = players[playerNumber].mo;
		if (!viewer || viewer.Health <= 0) return;
		double maximumDistance = clamp(CVFloat('tuin_overhead_healthbar_distance', 1024.0), 256.0, 4096.0);
		int maximumBars = clamp(CVInt('tuin_overhead_healthbar_maximum', 12), 1, TUIN_MAX_OVERHEAD_BARS);
		foreach (sector: level.Sectors)
		{
			for (Actor actor = sector.thinglist; actor; actor = actor.snext)
			{
				if (!IsValidMonster(actor)) continue;
				let data = GetMonsterData(actor);
				if (!data) continue;
				double distance = viewer.Distance3D(actor);
				if (distance > maximumDistance || !viewer.CheckSight(actor, SF_IGNOREWATERBOUNDARY)) continue;
				if (abs(Actor.deltaangle(viewer.Angle, viewer.AngleTo(actor, true))) > 100.0) continue;

				int insertAt = OverheadCount;
				for (int i = 0; i < OverheadCount; i++)
					if (distance < OverheadDistance[i]) { insertAt = i; break; }
				if (insertAt >= maximumBars) continue;
				if (OverheadCount < maximumBars) OverheadCount++;
				for (int i = OverheadCount - 1; i > insertAt; i--)
				{
					OverheadActor[i] = OverheadActor[i - 1];
					OverheadPosition[i] = OverheadPosition[i - 1];
					OverheadDistance[i] = OverheadDistance[i - 1];
					OverheadHealth[i] = OverheadHealth[i - 1];
					OverheadMaxHealth[i] = OverheadMaxHealth[i - 1];
					OverheadPreviousDisplayHealth[i] = OverheadPreviousDisplayHealth[i - 1];
					OverheadDisplayHealth[i] = OverheadDisplayHealth[i - 1];
					OverheadLevel[i] = OverheadLevel[i - 1];
					OverheadRarity[i] = OverheadRarity[i - 1];
					OverheadName[i] = OverheadName[i - 1];
					OverheadAffixes[i] = OverheadAffixes[i - 1];
					OverheadBleeding[i] = OverheadBleeding[i - 1];
				}
				OverheadActor[insertAt] = actor;
				OverheadPosition[insertAt] = (actor.Pos.x, actor.Pos.y, actor.Pos.z + actor.Height + 10.0);
				OverheadDistance[insertAt] = distance;
				OverheadHealth[insertAt] = max(0, actor.Health);
				OverheadMaxHealth[insertAt] = max(1, data.ScaledMaxHealth);
				OverheadPreviousDisplayHealth[insertAt] = data.PreviousDisplayHealth;
				OverheadDisplayHealth[insertAt] = data.DisplayHealth;
				OverheadLevel[insertAt] = data.MonsterLevel;
				OverheadRarity[insertAt] = data.MonsterRarity;
				OverheadName[insertAt] = CompactOverheadName(data.GeneratedName.Length() ? data.GeneratedName : actor.GetTag(actor.GetClassName()));
				OverheadAffixes[insertAt] = CompactAffixList(data);
				OverheadBleeding[insertAt] = data.BleedPulsesRemaining > 0;
			}
		}
	}

	void UpdateOverheadHealthAnimation()
	{
		for (int i = 0; i < OverheadCount; i++)
		{
			Actor actor = OverheadActor[i];
			let data = GetMonsterData(actor);
			if (!actor || !data) continue;
			OverheadHealth[i] = max(0, actor.Health);
			OverheadPreviousDisplayHealth[i] = data.PreviousDisplayHealth;
			OverheadDisplayHealth[i] = data.DisplayHealth;
		}
	}

	void ApplyAgility(int playerNumber, TuinPlayerData data)
	{
		if (!data || !players[playerNumber].mo) return;
		let weapon = players[playerNumber].ReadyWeapon;
		let psp = players[playerNumber].FindPSprite(PSprite.WEAPON);
		if (!weapon || !psp || !psp.CurState || psp.Tics <= 0) return;

		State fire = weapon.FindState('Fire');
		State hold = weapon.FindState('Hold');
		State altFire = weapon.FindState('AltFire');
		State altHold = weapon.FindState('AltHold');
		bool firing = (fire && psp.CurState.InStateSequence(fire)) ||
			(hold && psp.CurState.InStateSequence(hold)) ||
			(altFire && psp.CurState.InStateSequence(altFire)) ||
			(altHold && psp.CurState.InStateSequence(altHold));
		if (!firing) return;

		double speedBonus = data.Agility * 0.02;
		int variantIndex = data.FindEquippedVariant((class<Weapon>)(weapon.GetClass()));
		if (variantIndex >= 0) speedBonus += data.VariantHastePercent[variantIndex] * 0.01;
		if (data.PlayerClass == 1 && data.TankOverdriveActive) speedBonus += 0.50;
		// The engine power doubles every weapon state, including one-tic rocket states.
		// This manual remainder supplies the other +50%; gear may raise the combined ceiling to +200%.
		double speedCap = data.PlayerClass == 1 && data.TankOverdriveActive ? 1.0 : 0.75;
		AgilityAccumulator[playerNumber] += min(speedCap, speedBonus);
		int extraSteps = 0;
		while (AgilityAccumulator[playerNumber] >= 1.0 && extraSteps < 2 && psp.CurState && psp.Tics > 0)
		{
			AgilityAccumulator[playerNumber] -= 1.0;
			psp.Tics--;
			if (psp.Tics == 0) psp.SetState(psp.CurState.NextState);
			extraSteps++;
		}
	}

	void ApplyHeldGodlyGlow(int playerNumber, TuinPlayerData data)
	{
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!pawn || !data) return;
		if (GodlyGlowOwner[playerNumber] != pawn)
		{
			if (GodlyGlowOwner[playerNumber]) GodlyGlowOwner[playerNumber].A_RemoveLight('TuinHeldGodlyGlow');
			GodlyGlowOwner[playerNumber] = pawn;
			GodlyGlowApplied[playerNumber] = false;
			GodlyGlowQuality[playerNumber] = 0;
		}
		int variantIndex = ActiveWeaponVariantIndex(playerNumber, data);
		bool shouldGlow = variantIndex >= 0 && data.VariantQuality[variantIndex] >= 6;
		int glowQuality = shouldGlow ? data.VariantQuality[variantIndex] : 0;
		if (shouldGlow == GodlyGlowApplied[playerNumber] && glowQuality == GodlyGlowQuality[playerNumber]) return;
		pawn.A_RemoveLight('TuinHeldGodlyGlow');
		GodlyGlowApplied[playerNumber] = shouldGlow;
		GodlyGlowQuality[playerNumber] = glowQuality;
		if (shouldGlow)
		{
			Color glowColor = glowQuality == TUIN_LEAD_SPITTER_QUALITY ? Color(255, 72, 16) : Color(170, 245, 255);
			pawn.A_AttachLight('TuinHeldGodlyGlow', DynamicLight.PulseLight, glowColor,
				glowQuality == TUIN_LEAD_SPITTER_QUALITY ? 60 : 42,
				glowQuality == TUIN_LEAD_SPITTER_QUALITY ? 128 : 88,
				DynamicLight.LF_ATTENUATE, (18, 0, pawn.Height * 0.58),
				glowQuality == TUIN_LEAD_SPITTER_QUALITY ? 0.45 : 0.8);
		}
	}

	void UpdateWeaponDropTarget(int playerNumber)
	{
		TuinWeaponDrop previous = TargetWeaponDrop[playerNumber];
		TargetWeaponDrop[playerNumber] = null;
		if (!playerInGame[playerNumber] || !players[playerNumber].mo) return;
		Actor pawn = players[playerNumber].mo;
		TuinWeaponDrop best;
		double bestScore = 1e9;
		double maximumDistance = clamp(CVFloat('tuin_weapon_inspect_distance', 256.0), 128.0, 2048.0);
		double automaticDistance = clamp(CVFloat('tuin_weapon_near_inspect_distance', 80.0), 64.0, maximumDistance);
		ThinkerIterator it = ThinkerIterator.Create('TuinWeaponDrop');
		TuinWeaponDrop drop;
		while (drop = TuinWeaponDrop(it.Next()))
		{
			double distance = pawn.Distance3D(drop);
			if (distance > maximumDistance) continue;
			if (distance <= automaticDistance)
			{
				double closeScore = distance * 0.25;
				if (closeScore < bestScore) { best = drop; bestScore = closeScore; }
				continue;
			}
			double yawDifference = abs(pawn.AngleTo(drop));
			double allowedAngle = distance <= 320.0 ? 40.0 : 22.0;
			if (yawDifference > allowedAngle || !pawn.CheckSight(drop)) continue;
			double score = yawDifference * 18.0 + distance * 0.25;
			if (score < bestScore) { best = drop; bestScore = score; }
		}
		if (best)
		{
			TargetWeaponDrop[playerNumber] = best;
			WeaponDropTargetGrace[playerNumber] = 12;
		}
		else if (previous && pawn.Distance3D(previous) <= maximumDistance && WeaponDropTargetGrace[playerNumber] > 0)
		{
			TargetWeaponDrop[playerNumber] = previous;
			WeaponDropTargetGrace[playerNumber]--;
		}
	}

	void TryCollectWeaponDrop(int playerNumber)
	{
		let lootDrop = TargetWeaponDrop[playerNumber];
		Actor pawn = players[playerNumber].mo;
		if (!lootDrop || !pawn || pawn.Distance3D(lootDrop) > 128.0) return;
		let data = EnsurePlayerData(playerNumber);
		if (!data) return;
		bool needsWeapon = !pawn.FindInventory(lootDrop.WeaponType);
		int existing = data.FindEquippedVariant(lootDrop.WeaponType);
		bool replaced = existing >= 0;
		if (replaced)
		{
			SpawnStoredWeaponDrop(lootDrop.Pos, data, existing);
			data.ReplaceWeaponVariant(existing, lootDrop.VariantID, lootDrop.ItemLevel, lootDrop.Quality,
				lootDrop.AffixFlags, lootDrop.HastePercent, lootDrop.PowerPercent, lootDrop.LeechPercent,
				lootDrop.ExecutionPercent, lootDrop.ProsperityPercent);
		}
		else if (!data.AddWeaponVariant(lootDrop.VariantID, lootDrop.WeaponType, lootDrop.ItemLevel, lootDrop.Quality,
			lootDrop.AffixFlags, lootDrop.HastePercent, lootDrop.PowerPercent, lootDrop.LeechPercent,
			lootDrop.ExecutionPercent, lootDrop.ProsperityPercent))
		{
			SetLootNotification(playerNumber, "ARSENAL FULL", 0);
			return;
		}
		// Normal monster drops are variants of owned weapons, but late-start rewards
		// deliberately offer new weapon classes and therefore must grant the weapon too.
		if (needsWeapon)
		{
			pawn.GiveInventory(lootDrop.WeaponType, 1);
			if (lootDrop.CatchupReward) RefillAmmo(pawn, false);
		}
		string notice = replaced ? String.Format("EQUIPPED %s - OLD VARIANT DROPPED", lootDrop.DisplayName) : String.Format("EQUIPPED %s", lootDrop.DisplayName);
		SetLootNotification(playerNumber, notice, lootDrop.Quality);
		lootDrop.Destroy();
		TargetWeaponDrop[playerNumber] = null;
	}

	void SelectWeaponFromWheel(int playerNumber, int selectedIndex)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS || selectedIndex < 0 ||
			!playerInGame[playerNumber] || !players[playerNumber].mo) return;
		int weaponIndex;
		let item = players[playerNumber].mo.Inv;
		while (item)
		{
			let weapon = Weapon(item);
			item = item.Inv;
			if (!weapon || weapon.bPowered_Up) continue;
			if (weaponIndex++ != selectedIndex) continue;
			players[playerNumber].PendingWeapon = weapon;
			let data = GetPlayerData(players[playerNumber].mo);
			int variantIndex = data ? data.FindEquippedVariant((class<Weapon>)(weapon.GetClass())) : -1;
			string weaponName = variantIndex >= 0 ? WeaponVariantName(data.VariantWeaponType[variantIndex],
				data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex], data.VariantID[variantIndex]) :
				WeaponBaseName((class<Weapon>)(weapon.GetClass()));
			SetLootNotification(playerNumber, String.Format("SELECTED %s", weaponName),
				variantIndex >= 0 ? data.VariantQuality[variantIndex] : 0);
			return;
		}
	}

	override void WorldTick()
	{
		UpdateGrenadeBossDamage();
		for (int damageNumber = 0; damageNumber < TUIN_MAX_DAMAGE_NUMBERS; damageNumber++)
		{
			if (DamageNumberTics[damageNumber] > 0)
			{
				DamageNumberTics[damageNumber]--;
				if (DamageNumberTics[damageNumber] == 0) DamageNumberVictim[damageNumber] = null;
			}
		}
		int currentDifficulty = DifficultyMode();
		if (currentDifficulty != AppliedDifficultyMode)
		{
			AppliedDifficultyMode = currentDifficulty;
			RebalanceLivingMonstersForDifficulty(consoleplayer);
		}
		if ((level.Time % 35) == 0)
		{
			if (IsIconicEpisodeFinale()) TryPromoteIconicEpisodeBosses();
			else TryPromoteFinaleBoss();
			// Some custom maps may contain no eligible promotion actor at all. Never
			// leave a fully cleared map without John merely because every counted
			// survivor belonged to an excluded class.
			if (!IsIconicEpisodeFinale() && !FinaleBossPromoted && level.total_monsters > 0 &&
				level.killed_monsters >= level.total_monsters)
			{
				FinaleBossPromoted = true;
				FinaleBoss = null;
			}
			if (!IsIconicEpisodeFinale() && FinaleBossPromoted && !JohnMerchant && level.total_monsters - level.killed_monsters <= 3)
			{
				for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
				{
					if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
					SpawnJohnMerchant(players[playerNumber].mo);
					if (JohnMerchant) break;
				}
			}
		}
		if ((level.Time % 7) == 0) UpdateMonsterBleeds();
		if (EpisodeTravelTics > 0)
		{
			EpisodeTravelTics--;
			if (EpisodeTravelTics == 0 && EpisodeTravelDestination.Length())
			{
				string destination = EpisodeTravelDestination;
				EpisodeTravelDestination = "";
				bool showIntermission = EpisodeTravelShowsIntermission;
				EpisodeTravelShowsIntermission = false;
				for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
				{
					if (!playerInGame[playerNumber]) continue;
					let playerData = EnsurePlayerData(playerNumber);
					if (playerData) playerData.SuppressNextMapCatchup = true;
				}
				int travelFlags = CHANGELEVEL_KEEPFACING | CHANGELEVEL_PRERAISEWEAPON;
				if (!showIntermission)
				{
					travelFlags |= CHANGELEVEL_NOINTERMISSION;
				}
				level.ChangeLevel(destination, 0, travelFlags);
				return;
			}
		}
		if ((level.Time & 1) == 0) RefreshOverheadMonsters(consoleplayer);
		else UpdateOverheadHealthAnimation();
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
		{
			if (!playerInGame[i]) continue;
			// Waiting until the world tick avoids checking a newly spawned pawn before
			// its persistent inventory token has transferred from the previous map.
			ApplyLateStartCatchup(i);
			let playerData = EnsurePlayerData(i);
			if ((level.Time % 35) == 0) ApplyAmmoCapacity(players[i].mo, playerData);
			ApplyClassAmmoBonus(players[i].mo, playerData);
			ApplyClassRegeneration(i, players[i].mo, playerData);
			ApplyRogueStealth(i, players[i].mo, playerData);
			ApplyTankOverdrive(i, players[i].mo, playerData);
			ApplyDoomBloodPunch(i, players[i].mo, playerData);
			ApplyFlashlight(players[i].mo, playerData);
			ApplyHeldGodlyGlow(i, playerData);
			ApplyAgility(i, playerData);
			UpdateWeaponDropTarget(i);
			bool useDown = (players[i].cmd.buttons & BT_USE) != 0;
			if (useDown && !UseHeld[i] && !TryOpenJohnShop(i)) TryCollectWeaponDrop(i);
			UseHeld[i] = useDown;
			UpdateTarget(i);
			if (PopupTics[i] > 0)
			{
				PopupTics[i]--;
				if (PopupTics[i] == 0) PopupXP[i] = 0;
			}
			if (CriticalPopupTics[i] > 0) CriticalPopupTics[i]--;
			if (PoisonTics[i] > 0)
			{
				PoisonTics[i]--;
				if ((PoisonTics[i] % 35) == 0 && players[i].mo && players[i].mo.Health > 0)
				{
					ApplyingBonusDamage = true;
					players[i].mo.DamageMobj(PoisonSource[i], PoisonSource[i], PoisonDamage[i], 'Poison');
					ApplyingBonusDamage = false;
				}
				if (PoisonTics[i] == 0)
				{
					PoisonDamage[i] = 0;
					PoisonSource[i] = null;
				}
			}
			if (LootNotificationTics[i] > 0)
			{
				LootNotificationTics[i]--;
				if (LootNotificationTics[i] == 0) LootNotification[i] = "";
			}
			if (DifficultyNoticeTics[i] > 0)
			{
				DifficultyNoticeTics[i]--;
				if (DifficultyNoticeTics[i] == 0)
				{
					DifficultyNoticeTitle[i] = "";
					DifficultyNoticeStats[i] = "";
				}
			}
		}
		if (!MonsterLevelsSynchronized)
		{
			SynchronizeLivingMonsterLevels();
			MonsterLevelsSynchronized = true;
		}
		if (level.Time <= 1 || (level.Time % 105) == 0)
		{
			for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
			{
				if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
				DirectorTrailPosition[playerNumber] = players[playerNumber].mo.Pos;
				DirectorTrailValid[playerNumber] = true;
			}
		}
		UpdateHellDirector();
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || e.Player >= TUIN_MAX_PLAYERS) return;
		if (e.Name ~== "tuin_toggle_flashlight")
		{
			let flashlightData = EnsurePlayerData(e.Player);
			if (flashlightData && players[e.Player].mo)
			{
				flashlightData.FlashlightEnabled = !flashlightData.FlashlightEnabled;
				flashlightData.AppliedFlashlightRange = -1;
				ApplyFlashlight(players[e.Player].mo, flashlightData);
				SetLootNotification(e.Player, flashlightData.FlashlightEnabled ? "FLASHLIGHT ON" : "FLASHLIGHT OFF", 0);
			}
			return;
		}
		if (e.Name ~== "tuin_toggle_minimap")
		{
			EventHandler.SendInterfaceEvent(e.Player, "tuin_toggle_minimap_silent");
			return;
		}
		if (e.Name ~== "tuin_class_ability_up")
		{
			let releaseData = EnsurePlayerData(e.Player);
			let releasePawn = players[e.Player].mo;
			if (releaseData && releasePawn && releaseData.PlayerClass == 4)
				ReleaseDoomBloodPunch(releasePawn, releaseData);
			return;
		}
		if (e.Name ~== "tuin_class_ability_down" || e.Name ~== "tuin_rogue_shadow_veil")
		{
			bool legacyAbilityBind = e.Name ~== "tuin_rogue_shadow_veil";
			let rogueData = EnsurePlayerData(e.Player);
			let pawn = players[e.Player].mo;
			if (rogueData && pawn && rogueData.PlayerClass == 1)
			{
				if (rogueData.TankOverdriveActive)
					SetLootNotification(e.Player, String.Format("OVERDRIVE ACTIVE: %.1f SEC",
						max(0, rogueData.TankOverdriveTics) / 35.0), 0);
				else if (rogueData.TankOverdriveCharge >= 100)
					ActivateTankOverdrive(e.Player, pawn, rogueData);
				else
					SetLootNotification(e.Player, String.Format("OVERDRIVE CHARGE: %d%%", rogueData.TankOverdriveCharge), 0);
				return;
			}
			if (rogueData && pawn && rogueData.PlayerClass == 4)
			{
				if (rogueData.DoomBloodPunchCharge >= 100)
				{
					BeginDoomBloodPunchHold(e.Player, pawn, rogueData);
					if (legacyAbilityBind) ReleaseDoomBloodPunch(pawn, rogueData);
				}
				else
					SetLootNotification(e.Player, String.Format("BLOOD PUNCH CHARGE: %d%% - DEAL DAMAGE",
						rogueData.DoomBloodPunchCharge), 0);
				return;
			}
			if (!rogueData || !pawn || rogueData.PlayerClass != 5)
			{
				SetLootNotification(e.Player, "CLASS ABILITY REQUIRES TANK, DOOM GUY, OR ROGUE", 0);
				return;
			}
			if (rogueData.RogueVeiled)
			{
				BreakRogueVeil(e.Player, rogueData);
				SetLootNotification(e.Player, "SHADOW VEIL CANCELLED", 0);
			}
			else if (rogueData.RogueVeilCharge >= 100)
				ActivateRogueVeil(e.Player, pawn, rogueData);
			else
				SetLootNotification(e.Player, String.Format("SHADOW CHARGE: %d%% - DEAL DAMAGE",
					rogueData.RogueVeilCharge), 0);
			return;
		}
		if (e.Name ~== "tuin_give_levels")
		{
			GiveTestLevels(e.Player, e.Args[0] > 0 ? e.Args[0] : 1);
			return;
		}
		if (e.Name ~== "tuin_test_blood_punch")
		{
			let testData = EnsurePlayerData(e.Player);
			let testPawn = players[e.Player].mo;
			if (testData && testPawn)
			{
				testData.PlayerClass = 4;
				testData.DoomBloodPunchInitialized = true;
				testData.DoomBloodPunchCharge = 100;
				testData.DoomBloodPunchChargeRemainder = 0.0;
				testData.DoomBloodPunchReadyNotified = true;
				ApplyClassHealth(testPawn, testData);
				testPawn.A_Log("BLOOD PUNCH TEST READY. Press V to punch. Repeat this command to refill it.");
				SetLootNotification(e.Player, "BLOOD PUNCH TEST READY - PRESS V", 4);
			}
			return;
		}
		if (e.Name ~== "tuin_test_finale_boss")
		{
			if (!TryPromoteFinaleBoss(true) && players[e.Player].mo)
				players[e.Player].mo.A_Log("No eligible monster is alive for finale-boss testing.");
			return;
		}
		if (e.Name ~== "tuin_test_john_shop")
		{
			Actor pawn = players[e.Player].mo;
			if (pawn)
			{
				SpawnJohnMerchant(pawn);
				GiveCoins(pawn, 500);
				SetLootNotification(e.Player, "JOHN SHOP TEST: +500 COINS", 0);
				EventHandler.SendInterfaceEvent(e.Player, "tuin_open_john_shop");
			}
			return;
		}
		if (e.Name ~== "tuin_shop_buy")
		{
			BuyJohnItem(e.Player, e.Args[0]);
			return;
		}
		if (e.Name ~== "tuin_shop_talk")
		{
			let shopData = EnsurePlayerData(e.Player);
			if (shopData) shopData.ShopDialogue = RandomJohnGreeting();
			return;
		}
		if (e.Name ~== "tuin_shop_tip")
		{
			let shopData = EnsurePlayerData(e.Player);
			if (shopData) shopData.ShopDialogue = RandomJohnTip();
			return;
		}
		if (e.Name ~== "tuin_shop_fact")
		{
			let shopData = EnsurePlayerData(e.Player);
			if (shopData) shopData.ShopDialogue = RandomClassicGameFact();
			return;
		}
		if (e.Name ~== "tuin_john_what_now")
		{
			let shopData = EnsurePlayerData(e.Player);
			if (shopData)
			{
				PrepareJohnDialogueSequence(shopData);
				if (CanOfferJohnTravel())
				{
					shopData.ShopDialogue = JohnWhatNowDialogue(shopData.JohnWhatNowPage);
					shopData.JohnWhatNowPage = (shopData.JohnWhatNowPage + 1) % 4;
				}
				else
				{
					shopData.ShopDialogue = JohnNormalStatusDialogue();
				}
			}
			return;
		}
		if (e.Name ~== "tuin_john_whats_next")
		{
			let shopData = EnsurePlayerData(e.Player);
			if (shopData)
			{
				PrepareJohnDialogueSequence(shopData);
				shopData.ShopDialogue = JohnWhatsNextDialogue(shopData.JohnWhatsNextPage);
				shopData.JohnWhatsNextPage = (shopData.JohnWhatsNextPage + 1) % 4;
			}
			return;
		}
		if (e.Name ~== "tuin_john_travel")
		{
			BeginEpisodeTravel(e.Player);
			return;
		}
		if (e.Name ~== "tuin_test_weapon_drop")
		{
			let pawn = players[e.Player].mo;
			let ready = players[e.Player].ReadyWeapon;
			let testData = EnsurePlayerData(e.Player);
			if (pawn && ready && testData)
			{
				Vector3 position = pawn.Pos + (cos(pawn.Angle) * 64.0, sin(pawn.Angle) * 64.0, 8.0);
				SpawnRolledWeaponDrop(position, (class<Weapon>)(ready.GetClass()), max(1, testData.PlayerLevel), 5);
				SetLootNotification(e.Player, "MYTHIC TEST WEAPON SPAWNED", 5);
			}
			return;
		}
		if (e.Name ~== "tuin_secret_lead_spitter")
		{
			let pawn = players[e.Player].mo;
			if (pawn)
			{
				Vector3 position = pawn.Pos + (cos(pawn.Angle) * 72.0, sin(pawn.Angle) * 72.0, 8.0);
				SpawnLeadSpitterDrop(position);
				SetLootNotification(e.Player, "TUIN'S LEAD SPITTER HAS ARRIVED", TUIN_LEAD_SPITTER_QUALITY);
			}
			return;
		}
		if (e.Name ~== "tuin_reset_weapon_loot")
		{
			ResetWeaponLoot(e.Player);
			return;
		}
		if (e.Name ~== "tuin_weapon_wheel_select")
		{
			SelectWeaponFromWheel(e.Player, e.Args[0]);
			return;
		}
		if (e.Name ~== "tuin_weapon_wheel_closed")
		{
			return;
		}
		if (e.Name ~== "tuin_equip_variant")
		{
			let arsenalData = EnsurePlayerData(e.Player);
			if (arsenalData && arsenalData.EquipWeaponVariant(e.Args[0]) && players[e.Player].mo)
			{
				int index = arsenalData.FindVariantByID(e.Args[0]);
				if (index >= 0) SetLootNotification(e.Player, String.Format("EQUIPPED %s", WeaponVariantName(arsenalData.VariantWeaponType[index], arsenalData.VariantAffixFlags[index], arsenalData.VariantQuality[index], arsenalData.VariantID[index])), arsenalData.VariantQuality[index]);
			}
			return;
		}
		if (e.Name ~== "tuin_discard_variant")
		{
			let arsenalData = EnsurePlayerData(e.Player);
			if (arsenalData && arsenalData.RemoveWeaponVariant(e.Args[0]) && players[e.Player].mo)
				SetLootNotification(e.Player, "WEAPON VARIANT DISCARDED", 0);
			return;
		}
		if (e.Name ~== "tuin_choose_class")
		{
			ChoosePlayerClass(e.Player, e.Args[0]);
			return;
		}
		if (e.Name ~== "tuin_buy_perk")
		{
			BuyPerk(e.Player, e.Args[0]);
			return;
		}
		if (e.Name ~== "tuin_reset_rarity")
		{
			ResetRarityDefaults();
			RerollLivingMonsters(e.Player);
			if (players[e.Player].mo) players[e.Player].mo.A_Log("Rarity defaults restored and living monsters rerolled.");
			return;
		}
		if (e.Name ~== "tuin_all_mythic")
		{
			SetAllMythicPreset();
			RerollLivingMonsters(e.Player);
			if (players[e.Player].mo) players[e.Player].mo.A_Log("All-Mythic preset enabled and living monsters rerolled.");
			return;
		}
		if (e.Name ~== "tuin_reroll_monsters")
		{
			RerollLivingMonsters(e.Player);
			return;
		}
		let data = EnsurePlayerData(e.Player);
		if (!data || data.UnspentStatPoints <= 0) return;
		if (e.Name ~== "tuin_spend_vitality") data.Vitality++;
		else if (e.Name ~== "tuin_spend_strength") data.Strength++;
		else if (e.Name ~== "tuin_spend_luck") data.Luck++;
		else if (e.Name ~== "tuin_spend_agility") data.Agility++;
		else if (e.Name ~== "tuin_spend_endurance") data.Endurance++;
		else return;
		data.UnspentStatPoints--;
		ApplyVitality(players[e.Player].mo, data);
	}

	override void InterfaceProcess(ConsoleEvent e)
	{
		if (e.Name ~== "tuin_toggle_minimap_silent")
		{
			let minimap = CVar.FindCVar('tuin_minimap_enabled');
			if (minimap) minimap.SetBool(!minimap.GetBool());
			return;
		}
		if (e.Name ~== "tuin_open_john_shop")
			Menu.SetMenu('TuinRPGJohnShop');
		else if (e.Name ~== "tuin_open_john_finale_shop")
			Menu.SetMenu('TuinRPGFinaleJohnShop');
	}

	clearscope static bool, Vector2 ProjectOverheadPoint(Vector3 worldPosition, Vector3 viewPosition,
		double viewAngle, double viewPitch, double fieldOfView, int screenWidth, int screenHeight)
	{
		Vector3 delta = worldPosition - viewPosition;
		double forward = delta.x * cos(viewAngle) + delta.y * sin(viewAngle);
		double side = delta.x * sin(viewAngle) - delta.y * cos(viewAngle);
		double depth = forward * cos(viewPitch) - delta.z * sin(viewPitch);
		double up = delta.z * cos(viewPitch) + forward * sin(viewPitch);
		if (depth <= 4.0) return false, (0, 0);
		double focalLength = screenHeight / max(0.01, 1.5 * tan(clamp(fieldOfView, 5.0, 170.0) * 0.5));
		Vector2 screenPosition = (screenWidth * 0.5 + side * focalLength / depth,
			screenHeight * 0.5 - up * focalLength / depth);
		if (screenPosition.x < -160 || screenPosition.x > screenWidth + 160 ||
			screenPosition.y < -80 || screenPosition.y > screenHeight + 80) return false, screenPosition;
		return true, screenPosition;
	}

	ui void DrawOverheadHealthBars(RenderEvent e, int playerNumber, Font font, int screenWidth, int screenHeight)
	{
		int healthBarMode = CVInt('tuin_healthbar_mode', 1);
		if ((healthBarMode != 1 && healthBarMode != 2) || menuactive || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS || !playerInGame[playerNumber]) return;
		double settingScale = clamp(CVFloat('tuin_overhead_healthbar_scale', 1.25), 0.75, 2.0);
		double maximumDistance = clamp(CVFloat('tuin_overhead_healthbar_distance', 1024.0), 256.0, 4096.0);
		double fieldOfView = clamp(players[playerNumber].FOV, 5.0, 170.0);
		for (int i = OverheadCount - 1; i >= 0; i--)
		{
			Actor trackedActor = OverheadActor[i];
			if (!trackedActor || trackedActor.Health <= 0 || OverheadHealth[i] <= 0 || OverheadMaxHealth[i] <= 0) continue;
			Vector3 smoothWorldPosition = trackedActor.Prev + (trackedActor.Pos - trackedActor.Prev) * e.FracTic;
			smoothWorldPosition.z += trackedActor.Height + 12.0;
			bool projected;
			Vector2 anchor;
			[projected, anchor] = ProjectOverheadPoint(smoothWorldPosition, e.ViewPos, e.ViewAngle,
				e.ViewPitch, fieldOfView, screenWidth, screenHeight);
			if (!projected) continue;
			double distanceFactor = clamp(1.12 - (OverheadDistance[i] / maximumDistance) * 0.28, 0.82, 1.12);
			double scale = settingScale * distanceFactor;
			double titleScale = max(1.15, scale * 1.06);
			double detailScale = max(0.95, scale * 0.82);
			int barWidth = int(140 * scale);
			int barHeight = max(11, int(10 * scale));
			int x = int(anchor.x - barWidth * 0.5);
			int titleY = int(anchor.y - 4 * scale);
			string title = OverheadName[i];
			int titleWidth = int(font.StringWidth(title) * titleScale);
			int titleColor = OverheadRarity[i] > 0 ? RarityColor(OverheadRarity[i]) : Font.CR_WHITE;
			Screen.Dim(Color(3, 3, 6), 0.93, int(anchor.x - titleWidth * 0.5 - 6), titleY - 3,
				titleWidth + 12, int(11 * titleScale));
			Screen.DrawText(font, titleColor, anchor.x - titleWidth * 0.5, titleY, title,
				DTA_ScaleX, titleScale, DTA_ScaleY, titleScale);

			int barY = titleY + int(11 * titleScale);
			Screen.Dim(Color(3, 3, 3), 0.96, x - 2, barY - 2, barWidth + 4, barHeight + 4);
			double displayedHealth = OverheadPreviousDisplayHealth[i] +
				(OverheadDisplayHealth[i] - OverheadPreviousDisplayHealth[i]) * e.FracTic;
			double healthFraction = clamp(displayedHealth / OverheadMaxHealth[i], 0.0, 1.0);
			Screen.Dim(RarityBarColor(OverheadRarity[i]), 0.96, x, barY,
				int(barWidth * healthFraction), barHeight);
			Screen.DrawLineFrame(Color(12, 12, 12), x - 2, barY - 2, barWidth + 4, barHeight + 4, 2);

			string healthText = String.Format("%d/%d", OverheadHealth[i], OverheadMaxHealth[i]);
			int healthWidth = int(font.StringWidth(healthText) * detailScale);
			int healthY = barY + max(0, int((barHeight - 8 * detailScale) * 0.5));
			Screen.DrawText(font, Font.CR_WHITE, anchor.x - healthWidth * 0.5, healthY, healthText,
				DTA_ScaleX, detailScale, DTA_ScaleY, detailScale);
			if (OverheadBleeding[i])
			{
				string bleedingText = "BLEEDING";
				int bleedingWidth = int(font.StringWidth(bleedingText) * detailScale);
				Screen.DrawText(font, Font.CR_RED, anchor.x - bleedingWidth * 0.5, barY + barHeight + 4,
					bleedingText, DTA_ScaleX, detailScale, DTA_ScaleY, detailScale);
			}
		}
	}

	ui void DrawDamageNumbers(RenderEvent e, int playerNumber, Font font, int screenWidth, int screenHeight)
	{
		if (!CVInt('tuin_damage_numbers', 1) || menuactive) return;
		double fieldOfView = clamp(players[playerNumber].FOV, 5.0, 170.0);
		double settingScale = clamp(CVFloat('tuin_damage_number_scale', 1.35), 0.75, 2.5);
		for (int i = 0; i < TUIN_MAX_DAMAGE_NUMBERS; i++)
		{
			if (DamageNumberTics[i] <= 0 || DamageNumberPlayer[i] != playerNumber) continue;
			double age = TUIN_DAMAGE_NUMBER_LIFETIME - DamageNumberTics[i] + e.FracTic;
			Vector3 floatingPosition = DamageNumberPosition[i] + (0, 0, age * 1.15);
			bool projected;
			Vector2 anchor;
			[projected, anchor] = ProjectOverheadPoint(floatingPosition, e.ViewPos, e.ViewAngle,
				e.ViewPitch, fieldOfView, screenWidth, screenHeight);
			if (!projected) continue;
			// A steady rightward drift plus a small wave gives the number the requested
			// curling, slightly whirly motion without making it hard to follow.
			anchor.x += age * (0.72 + DamageNumberCurl[i] * 0.12) + sin(age * 24.0) * 4.0;
			anchor.y -= age * 0.18 + cos(age * 19.0) * 2.0;
			double fade = clamp(DamageNumberTics[i] / 14.0, 0.0, 1.0);
			double pop = age < 5.0 ? 0.82 + age * 0.06 : 1.12;
			double scale = settingScale * pop * (DamageNumberCritical[i] ? 1.35 : 1.0);
			string number = String.Format("%d", DamageNumberAmount[i]);
			int width = int(font.StringWidth(number) * scale);
			int x = int(anchor.x - width * 0.5);
			int y = int(anchor.y);
			Screen.DrawText(font, Font.CR_BLACK, x + 2, y + 2, number,
				DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Alpha, fade);
			int numberColor = DamageNumberBleed[i] ? Font.CR_RED :
				(DamageNumberCritical[i] ? Font.CR_GOLD : Font.CR_WHITE);
			Screen.DrawText(font, numberColor, x, y, number,
				DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Alpha, fade);
		}
	}

	ui void DrawCurrentTargetPanel(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		int healthBarMode = CVInt('tuin_healthbar_mode', 1);
		if ((healthBarMode != 1 && healthBarMode != 2) || menuactive || TargetMaxHealth[playerNumber] <= 0) return;
		double scale = clamp(hudScale, 1.4, 2.0);
		int panelWidth = min(screenWidth - 20, int(380 * scale));
		int panelX = screenWidth - panelWidth - 10;
		int panelY = 10;
		if (CVInt('tuin_minimap_enabled', 1))
		{
			int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, screenHeight - 32));
			double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
			double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
			panelX = int(8 + (screenWidth - mapSize - 16) * mapHorizontal);
			int playerStatusY = int(8 + (screenHeight - mapSize - 16) * mapVertical) + mapSize +
				(CVInt('tuin_minimap_show_stats', 1) ? 29 : 7);
			double statusScale = clamp(hudScale * 1.20, 1.75, 2.4);
			panelY = playerStatusY + int(34 * statusScale) + 7;
			let targetPlayerData = GetPlayerData(players[playerNumber].mo);
			if (targetPlayerData && (targetPlayerData.PlayerClass == 1 || targetPlayerData.PlayerClass == 4 ||
				targetPlayerData.PlayerClass == 5))
				panelY += int(22 * statusScale) + 5;
			panelWidth = mapSize;
		}

		string rarity = TargetRarity[playerNumber] > 0 ? RarityName(TargetRarity[playerNumber]) : "NORMAL";
		string stats = String.Format("LEVEL %d    HP %d/%d    %s", TargetLevel[playerNumber],
			TargetHealth[playerNumber], TargetMaxHealth[playerNumber], rarity);
		int line = int(14 * scale);
		int panelHeight = int(42 * scale);
		if (panelY + panelHeight > screenHeight - 8) panelY = screenHeight - panelHeight - 8;
		Screen.Dim(Color(3, 5, 9), 0.94, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawText(font, Font.CR_GOLD, panelX + 7, panelY + 5, "CURRENT TARGET",
			DTA_ScaleX, scale, DTA_ScaleY, scale);
		int targetColor = TargetRarity[playerNumber] > 0 ? RarityColor(TargetRarity[playerNumber]) : Font.CR_WHITE;
		double nameScale = min(scale, double(panelWidth - 14) / max(1, font.StringWidth(TargetName[playerNumber])));
		nameScale = max(1.0, nameScale);
		Screen.DrawText(font, targetColor, panelX + 7, panelY + 5 + line, TargetName[playerNumber],
			DTA_ScaleX, nameScale, DTA_ScaleY, nameScale);
		double statsScale = min(scale * 0.88, double(panelWidth - 14) / max(1, font.StringWidth(stats)));
		statsScale = max(0.9, statsScale);
		Screen.DrawText(font, Font.CR_WHITE, panelX + 7, panelY + 5 + line * 2, stats,
			DTA_ScaleX, statsScale, DTA_ScaleY, statsScale);
	}

	ui void DrawRogueStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 5) return;
		double scale = clamp(hudScale * 1.10, 1.5, 2.2);
		string status;
		int statusColor;
		if (data.RogueVeiled)
		{
			status = String.Format("SHADOW VEIL ACTIVE  %.1f SEC  -  AMBUSH READY",
				max(0, RogueVeilDuration(data) - data.RogueVeilTics) / 35.0);
			statusColor = Font.CR_PURPLE;
		}
		else if (data.RogueVeilCharge < 100)
		{
			status = String.Format("SHADOW CHARGE  %d%%  -  DEAL DAMAGE", data.RogueVeilCharge);
			statusColor = Font.CR_GOLD;
		}
		else
		{
			status = "SHADOW VEIL READY  -  USE ROGUE ABILITY";
			statusColor = Font.CR_GREEN;
		}
		int panelWidth = min(screenWidth - 20, int(font.StringWidth(status) * scale) + 16);
		int panelX = screenWidth - panelWidth - 10;
		int panelY = 10;
		if (CVInt('tuin_minimap_enabled', 1))
		{
			int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, screenHeight - 32));
			double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
			double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
			panelX = int(8 + (screenWidth - mapSize - 16) * mapHorizontal);
			panelY = int(8 + (screenHeight - mapSize - 16) * mapVertical) + mapSize +
				(CVInt('tuin_minimap_show_stats', 1) ? 29 : 7) + int(34 * clamp(hudScale * 1.20, 1.75, 2.4)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(8, 3, 14), 0.94, panelX, panelY, panelWidth, int(20 * scale));
		Screen.DrawLineFrame(Color(150, 70, 220), panelX, panelY, panelWidth, int(20 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
	}

	ui void DrawTankStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 1) return;
		double scale = clamp(hudScale * 1.10, 1.5, 2.2);
		string status;
		int statusColor;
		if (data.TankOverdriveActive)
		{
			status = String.Format("TANK OVERDRIVE  %.1f SEC  -  +150%% DAMAGE / FIRE SPEED",
				max(0, data.TankOverdriveTics) / 35.0);
			statusColor = Font.CR_RED;
		}
		else if (data.TankOverdriveCharge < 100)
		{
			status = String.Format("OVERDRIVE CHARGE  %d%%  -  DEAL OR TAKE DAMAGE", data.TankOverdriveCharge);
			statusColor = Font.CR_GOLD;
		}
		else
		{
			status = "OVERDRIVE READY  -  PRESS V";
			statusColor = Font.CR_GREEN;
		}
		int panelWidth = min(screenWidth - 20, int(font.StringWidth(status) * scale) + 16);
		int panelX = screenWidth - panelWidth - 10;
		int panelY = 10;
		if (CVInt('tuin_minimap_enabled', 1))
		{
			int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, screenHeight - 32));
			double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
			double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
			panelX = int(8 + (screenWidth - mapSize - 16) * mapHorizontal);
			panelY = int(8 + (screenHeight - mapSize - 16) * mapVertical) + mapSize +
				(CVInt('tuin_minimap_show_stats', 1) ? 29 : 7) + int(34 * clamp(hudScale * 1.20, 1.75, 2.4)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(15, 2, 2), 0.94, panelX, panelY, panelWidth, int(20 * scale));
		Screen.DrawLineFrame(Color(235, 42, 18), panelX, panelY, panelWidth, int(20 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
	}

	ui void DrawDoomBloodPunchStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 4) return;
		double scale = clamp(hudScale * 1.10, 1.5, 2.2);
		string status;
		int statusColor;
		if (data.DoomBloodPunchHolding || data.DoomBloodPunchPrepareTics > 0 ||
			data.DoomBloodPunchFistRaiseTics > 0)
		{
			status = "BLOOD PUNCH ARMED  -  RELEASE V TO STRIKE";
			statusColor = Font.CR_GREEN;
		}
		else if (data.DoomBloodPunchAttackTics > 0)
		{
			status = "BLOOD PUNCH!";
			statusColor = Font.CR_RED;
		}
		else if (data.DoomBloodPunchCharge < 100)
		{
			status = String.Format("BLOOD PUNCH CHARGE  %d%%  -  DEAL DAMAGE", data.DoomBloodPunchCharge);
			statusColor = Font.CR_GOLD;
		}
		else
		{
			status = "BLOOD PUNCH READY  -  HOLD V";
			statusColor = Font.CR_GREEN;
		}
		int panelWidth = min(screenWidth - 20, int(font.StringWidth(status) * scale) + 16);
		int panelX = screenWidth - panelWidth - 10;
		int panelY = 10;
		if (CVInt('tuin_minimap_enabled', 1))
		{
			int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, screenHeight - 32));
			double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
			double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
			panelX = int(8 + (screenWidth - mapSize - 16) * mapHorizontal);
			panelY = int(8 + (screenHeight - mapSize - 16) * mapVertical) + mapSize +
				(CVInt('tuin_minimap_show_stats', 1) ? 29 : 7) + int(34 * clamp(hudScale * 1.20, 1.75, 2.4)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(16, 1, 1), 0.94, panelX, panelY, panelWidth, int(20 * scale));
		Screen.DrawLineFrame(Color(210, 20, 12), panelX, panelY, panelWidth, int(20 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
	}

	ui void DrawCurrentTargetAffixes(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !CVInt('tuin_healthbar_show_affixes', 1) ||
			TargetMaxHealth[playerNumber] <= 0 || !TargetAffixes[playerNumber].Length()) return;
		double scale = clamp(hudScale * 1.12, 1.65, 2.55);
		string heading = "TARGET BUFFS";
		string affixes = TargetAffixes[playerNumber];
		double affixScale = min(scale, double(screenWidth - 56) / max(1, font.StringWidth(affixes)));
		affixScale = max(1.35, affixScale);
		int contentWidth = max(int(font.StringWidth(heading) * scale), int(font.StringWidth(affixes) * affixScale));
		int panelWidth = min(screenWidth - 32, contentWidth + int(28 * scale));
		int panelHeight = int(31 * scale);
		int panelX = (screenWidth - panelWidth) / 2;
		int healthBarMode = CVInt('tuin_healthbar_mode', 1);
		int panelY = (healthBarMode == 0 || healthBarMode == 2) ?
			max(int(55 * scale), screenHeight / 10 + int(35 * scale)) : int(12 * scale);
		Screen.Dim(Color(3, 4, 9), 0.95, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(RarityBarColor(TargetRarity[playerNumber]), panelX, panelY, panelWidth, panelHeight, 2);
		Screen.DrawText(font, Font.CR_GOLD, (screenWidth - font.StringWidth(heading) * scale) / 2,
			panelY + int(3 * scale), heading, DTA_ScaleX, scale, DTA_ScaleY, scale);
		int targetColor = TargetRarity[playerNumber] > 0 ? RarityColor(TargetRarity[playerNumber]) : Font.CR_WHITE;
		Screen.DrawText(font, targetColor, (screenWidth - font.StringWidth(affixes) * affixScale) / 2,
			panelY + int(16 * scale), affixes, DTA_ScaleX, affixScale, DTA_ScaleY, affixScale);
	}

	override bool InputProcess(InputEvent e)
	{
		// UZDoom does not permit changing bindings from an event handler. For
		// existing installs where V still carries the old one-shot command,
		// translate the physical key-down/key-up pair without altering config.
		if (gamestate != GS_LEVEL || e.KeyScan != 0x2F ||
			!(Bindings.GetBinding(e.KeyScan) ~== "netevent tuin_rogue_shadow_veil"))
			return false;
		if (e.Type == InputEvent.Type_KeyDown)
		{
			EventHandler.SendNetworkEvent("tuin_class_ability_down");
			return true;
		}
		if (e.Type == InputEvent.Type_KeyUp)
		{
			EventHandler.SendNetworkEvent("tuin_class_ability_up");
			return true;
		}
		return false;
	}

	override void RenderOverlay(RenderEvent e)
	{
		int pnum = consoleplayer;
		if (pnum < 0 || pnum >= TUIN_MAX_PLAYERS || !playerInGame[pnum]) return;
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		Font font = SmallFont;
		double hudScale = clamp(CVFloat('tuin_hud_scale', 1.5), 1.25, 3.0);
		let overlayData = GetPlayerData(players[pnum].mo);
		if (overlayData && overlayData.PlayerClass == 4 && overlayData.DoomBloodPunchFlashTics > 0)
		{
			double flashStrength = 0.08 + 0.18 * overlayData.DoomBloodPunchFlashTics / 22.0;
			Screen.Dim(Color(155, 0, 0), flashStrength, 0, 0, sw, sh);
		}
		DrawOverheadHealthBars(e, pnum, font, sw, sh);
		DrawDamageNumbers(e, pnum, font, sw, sh);
		DrawRogueStatus(pnum, font, sw, sh, hudScale);
		DrawTankStatus(pnum, font, sw, sh, hudScale);
		DrawDoomBloodPunchStatus(pnum, font, sw, sh, hudScale);
		DrawCurrentTargetPanel(pnum, font, sw, sh, hudScale);
		DrawCurrentTargetAffixes(pnum, font, sw, sh, hudScale);
		if (DifficultyNoticeTics[pnum] > 0 && DifficultyNoticeTitle[pnum].Length())
		{
			double difficultyScale = clamp(hudScale * 1.10, 1.5, 2.0);
			string title = DifficultyNoticeTitle[pnum];
			string stats = DifficultyNoticeStats[pnum];
			int titleWidth = int(font.StringWidth(title) * difficultyScale);
			int statsWidth = int(font.StringWidth(stats) * difficultyScale);
			int panelWidth = min(sw - 24, max(titleWidth, statsWidth) + int(32 * difficultyScale));
			int panelHeight = int(38 * difficultyScale);
			int panelX = (sw - panelWidth) / 2;
			int panelY = int(sh * 0.22);
			Screen.Dim(Color(5, 5, 10), 0.94, panelX, panelY, panelWidth, panelHeight);
			Screen.DrawLineFrame(Color(232, 160, 24), panelX, panelY, panelWidth, panelHeight, 2);
			Screen.DrawText(font, Font.CR_GOLD, (sw - titleWidth) / 2, panelY + int(4 * difficultyScale), title,
				DTA_ScaleX, difficultyScale, DTA_ScaleY, difficultyScale);
			Screen.DrawText(font, Font.CR_WHITE, (sw - statsWidth) / 2, panelY + int(19 * difficultyScale), stats,
				DTA_ScaleX, difficultyScale, DTA_ScaleY, difficultyScale);
		}
		let viewedDrop = TargetWeaponDrop[pnum];
		if (viewedDrop && !menuactive)
		{
			double lootScale = clamp(hudScale, 1.0, 1.75);
			let playerData = GetPlayerData(players[pnum].mo);
			int equippedIndex = playerData ? playerData.FindEquippedVariant(viewedDrop.WeaponType) : -1;
			int equippedScore = equippedIndex >= 0 ? StoredWeaponVariantScore(playerData, equippedIndex) : 0;
			int viewedScore = DroppedWeaponScore(viewedDrop);
			int difference = viewedScore - equippedScore;
			bool hasCurrent = equippedIndex >= 0;
			int currentHaste = hasCurrent ? playerData.VariantHastePercent[equippedIndex] : 0;
			int currentPower = hasCurrent ? WeaponTotalPowerPercent(playerData.VariantItemLevel[equippedIndex], playerData.VariantPowerPercent[equippedIndex]) : 0;
			int currentLeech = hasCurrent ? playerData.VariantLeechPercent[equippedIndex] : 0;
			int currentExecution = hasCurrent ? playerData.VariantExecutionPercent[equippedIndex] : 0;
			int currentProsperity = hasCurrent ? playerData.VariantProsperityPercent[equippedIndex] : 0;
			int currentCritical = hasCurrent ? WeaponCriticalPercent(playerData.VariantAffixFlags[equippedIndex],
				playerData.VariantQuality[equippedIndex], playerData.VariantItemLevel[equippedIndex]) : 0;
			int viewedCritical = WeaponCriticalPercent(viewedDrop.AffixFlags, viewedDrop.Quality, viewedDrop.ItemLevel);
			int panelWidth = min(sw - 24, int(440 * lootScale));
			int panelHeight = int(151 * lootScale);
			int panelX = (sw - panelWidth) / 2;
			int panelY = min(int(sh * 0.48), sh - panelHeight - 16);
			int textX = panelX + int(10 * lootScale);
			int line = int(13 * lootScale);
			int color = WeaponQualityFontColor(viewedDrop.Quality);
			Screen.Dim(Color(8, 8, 14), 0.88, panelX, panelY, panelWidth, panelHeight);
			Screen.DrawText(font, color, textX, panelY + 6, viewedDrop.DisplayName, DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(font, color, textX, panelY + 6 + line, String.Format("DROP: %s   LEVEL %d   SCORE %d", WeaponQualityName(viewedDrop.Quality), viewedDrop.ItemLevel, viewedScore), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			string currentLine = hasCurrent ? String.Format("CURRENT: %s   LEVEL %d   SCORE %d", WeaponQualityName(playerData.VariantQuality[equippedIndex]), playerData.VariantItemLevel[equippedIndex], equippedScore) : "CURRENT: NORMAL WEAPON - NO BONUSES";
			Screen.DrawText(font, Font.CR_WHITE, textX, panelY + 6 + line * 2, currentLine, DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			string comparison = equippedIndex < 0 ? "NEW WEAPON VARIANT" : difference > 0 ? String.Format("UPGRADE  +%d SCORE", difference) : difference < 0 ? String.Format("LOWER  %d SCORE", difference) : "EQUAL GEAR SCORE";
			Screen.DrawText(font, difference >= 0 ? Font.CR_GREEN : Font.CR_RED, textX, panelY + 6 + line * 3, comparison, DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(font, WeaponStatComparisonColor(viewedDrop.HastePercent, currentHaste, hasCurrent), textX, panelY + 6 + line * 4, WeaponStatComparison("FIRE SPEED", viewedDrop.HastePercent, currentHaste, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			int viewedPower = WeaponTotalPowerPercent(viewedDrop.ItemLevel, viewedDrop.PowerPercent);
			Screen.DrawText(font, WeaponStatComparisonColor(viewedPower, currentPower, hasCurrent), textX, panelY + 6 + line * 5, WeaponStatComparison("TOTAL DAMAGE", viewedPower, currentPower, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(font, WeaponStatComparisonColor(viewedDrop.LeechPercent, currentLeech, hasCurrent), textX, panelY + 6 + line * 6, WeaponStatComparison("DAMAGE LEECH", viewedDrop.LeechPercent, currentLeech, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(font, WeaponStatComparisonColor(viewedDrop.ExecutionPercent, currentExecution, hasCurrent), textX, panelY + 6 + line * 7, WeaponStatComparison("EXECUTION", viewedDrop.ExecutionPercent, currentExecution, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(font, WeaponStatComparisonColor(viewedDrop.ProsperityPercent, currentProsperity, hasCurrent), textX, panelY + 6 + line * 8, WeaponStatComparison("KILL XP", viewedDrop.ProsperityPercent, currentProsperity, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(font, WeaponStatComparisonColor(viewedCritical, currentCritical, hasCurrent), textX,
				panelY + 6 + line * 9, WeaponStatComparison("CRITICAL", viewedCritical, currentCritical, hasCurrent),
				DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			bool closeEnough = players[pnum].mo.Distance3D(viewedDrop) <= 128.0;
			string prompt = closeEnough ? (equippedIndex >= 0 ? "PRESS USE [E] TO SWAP - OLD WEAPON DROPS" : "PRESS USE [E] TO EQUIP") : "MOVE CLOSER TO INSPECT AND EQUIP";
			Screen.DrawText(font, closeEnough ? Font.CR_GOLD : Font.CR_WHITE, (sw - font.StringWidth(prompt) * lootScale) / 2, panelY + panelHeight - int(15 * lootScale), prompt, DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
		}
		if (LootNotificationTics[pnum] > 0 && LootNotification[pnum].Length())
		{
			double noticeScale = clamp(hudScale, 1.25, 1.75);
			string notice = LootNotification[pnum];
			int noticeColor = LootNotificationQuality[pnum] > 0 ? WeaponQualityFontColor(LootNotificationQuality[pnum]) : Font.CR_WHITE;
			int noticeWidth = int(font.StringWidth(notice) * noticeScale + 20);
			int noticeX = (sw - noticeWidth) / 2;
			int noticeY = int(sh * 0.82);
			Screen.Dim(Color(8, 8, 14), 0.82, noticeX, noticeY, noticeWidth, int(18 * noticeScale));
			Screen.DrawText(font, noticeColor, noticeX + 10, noticeY + 4, notice, DTA_ScaleX, noticeScale, DTA_ScaleY, noticeScale);
		}
		if (CriticalPopupTics[pnum] > 0)
		{
			double criticalScale = clamp(hudScale * 1.15, 1.25, 2.2);
			string criticalText = "CRITICAL!";
			Screen.DrawText(font, Font.CR_GOLD, (sw - font.StringWidth(criticalText) * criticalScale) / 2,
				int(sh * 0.42), criticalText, DTA_ScaleX, criticalScale, DTA_ScaleY, criticalScale);
		}
		if (PoisonTics[pnum] > 0)
		{
			double poisonScale = clamp(hudScale, 1.0, 1.7);
			string poisonText = String.Format("POISONED  %d", (PoisonTics[pnum] + 34) / 35);
			Screen.DrawText(font, Font.CR_GREEN, (sw - font.StringWidth(poisonText) * poisonScale) / 2,
				int(sh * 0.46), poisonText, DTA_ScaleX, poisonScale, DTA_ScaleY, poisonScale);
		}
		int activeHealthBarMode = CVInt('tuin_healthbar_mode', 1);
		if (TargetMaxHealth[pnum] > 0 && (activeHealthBarMode == 0 || activeHealthBarMode == 2))
		{
			int barWidth = clamp(int(CVInt('tuin_healthbar_width', 360) * hudScale), 240, min(1080, sw - 20));
			int x = (sw - barWidth) / 2;
			int y = max(int(30 * hudScale), sh / 10);
			int barHeight = int(14 * hudScale);
			string title = "";
			if (CVInt('tuin_healthbar_show_name', 1)) title = TargetName[pnum];
			if (CVInt('tuin_healthbar_show_level', 1))
			{
				if (title.Length() > 0) title.AppendFormat("  -  LEVEL %d", TargetLevel[pnum]);
				else title = String.Format("LEVEL %d", TargetLevel[pnum]);
			}
			int rarityColor = RarityColor(TargetRarity[pnum]);
			bool drawRarity = CVInt('tuin_healthbar_show_rarity', 1) && TargetRarity[pnum] > 0;
			int titleOffset = drawRarity ? 24 : 12;
			if (title.Length() > 0) Screen.DrawText(font, rarityColor, (sw - font.StringWidth(title) * hudScale) / 2, y - int(titleOffset * hudScale), title, DTA_ScaleX, hudScale, DTA_ScaleY, hudScale);
			if (drawRarity)
			{
				string rarityText = RarityName(TargetRarity[pnum]);
				Screen.DrawText(font, rarityColor, (sw - font.StringWidth(rarityText) * hudScale) / 2, y - int(12 * hudScale), rarityText, DTA_ScaleX, hudScale, DTA_ScaleY, hudScale);
			}
			Screen.Dim(Color(8, 8, 8), 0.90, x, y, barWidth, barHeight);
			double displayedHealth = TargetPreviousDisplayHealth[pnum] +
				(TargetDisplayHealth[pnum] - TargetPreviousDisplayHealth[pnum]) * e.FracTic;
			double fraction = clamp(displayedHealth / TargetMaxHealth[pnum], 0.0, 1.0);
			int border = max(2, int(2 * hudScale));
			Screen.Dim(RarityBarColor(TargetRarity[pnum]), 0.95, x + border, y + border, int((barWidth - border * 2) * fraction), barHeight - border * 2);
			if (CVInt('tuin_healthbar_show_exact', 1))
			{
				string hp = String.Format("%d / %d HP", TargetHealth[pnum], TargetMaxHealth[pnum]);
				int hpColor = TargetRarity[pnum] >= 4 ? rarityColor : Font.CR_WHITE;
				Screen.DrawText(font, hpColor, (sw - font.StringWidth(hp) * hudScale) / 2, y + barHeight + 4, hp, DTA_ScaleX, hudScale, DTA_ScaleY, hudScale);
			}
		}
		if (CVInt('tuin_xp_popup', 1) && PopupTics[pnum] > 0 && PopupXP[pnum] > 0)
		{
			string popup = String.Format("+%d XP", PopupXP[pnum]);
			Screen.DrawText(font, Font.CR_GOLD, (sw - font.StringWidth(popup) * hudScale) / 2, sh / 2 + 36, popup, DTA_ScaleX, hudScale, DTA_ScaleY, hudScale);
		}
		if (CVInt('tuin_player_hud', 1) && players[pnum].mo)
		{
			let pd = GetPlayerData(players[pnum].mo);
			if (pd)
			{
				string progress = String.Format("LV %d   XP %d/%d", pd.PlayerLevel, pd.CurrentXP, XPRequired(pd.PlayerLevel));
				string resources = String.Format("STAT %d   PERK %d   COINS %d", pd.UnspentStatPoints,
					pd.UnspentSkillPoints, CoinBalance(players[pnum].mo));
				double statusScale = clamp(hudScale * 1.20, 1.75, 2.4);
				int statusX = 10;
				int statusY = 10;
				int statusWidth = max(int(font.StringWidth(progress) * statusScale), int(font.StringWidth(resources) * statusScale)) + 14;
				if (CVInt('tuin_minimap_enabled', 1))
				{
					int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, sh - 32));
					double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
					double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
					statusX = int(8 + (sw - mapSize - 16) * mapHorizontal);
					statusY = int(8 + (sh - mapSize - 16) * mapVertical) + mapSize +
						(CVInt('tuin_minimap_show_stats', 1) ? 29 : 7);
					statusWidth = mapSize;
				}
				Screen.Dim(Color(3, 5, 9), 0.93, statusX, statusY - 5, statusWidth, int(34 * statusScale));
				Screen.DrawText(font, Font.CR_GOLD, statusX + 6, statusY, progress,
					DTA_ScaleX, statusScale, DTA_ScaleY, statusScale);
				Screen.DrawText(font, Font.CR_GOLD, statusX + 6, statusY + int(13 * statusScale), resources,
					DTA_ScaleX, statusScale, DTA_ScaleY, statusScale);
			}
		}
	}
}
