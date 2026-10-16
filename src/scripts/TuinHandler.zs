class TuinRPGHandler : EventHandler
{
    TuinLocatorHandler Locator;
    TuinRun Run;
    void EnsureRun() { if(!Run && !ClassesEnabled()) Run=new('TuinRun'); }
    int FullHealthCheckTime;
    bool FullHealthCheckDone;
    Actor FullHealthReinforcement;
    void ScheduleFullHealthCheck()
    {
        if(ClassesEnabled() || FullHealthCheckDone || FullHealthCheckTime>0) return;
        // Old saves already past the window do not receive a late surprise.
        if(level.time>=20*60*35) { FullHealthCheckDone=true; return; }
        FullHealthCheckTime=Random[TuinHealthDirector](max(5*60*35,level.time+1),20*60*35);
    }
    clearscope static bool AtFullHealth(Actor pawn)
    { return pawn && pawn.Health>0 && pawn.Health>=max(1,pawn.GetMaxHealth(true)); }
    bool SpawnFullHealthReinforcement(int pnum,int rarity)
    {
        Actor pawn=players[pnum].mo;
        if(!pawn || pawn.Health<=0 || FullHealthReinforcement) return false;
        rarity=clamp(rarity,2,5);
        class<Actor> kind=rarity>=4?'Revenant':rarity==3?'Demon':'DoomImp';
        double baseAngle=Random[TuinHealthDirector](0,359);
        for(int attempt=0;attempt<32;attempt++)
        {
            double angle=baseAngle+(attempt%16)*22.5;
            double radius=attempt<16?384:640;
            Vector3 pos=(pawn.Pos.X+cos(angle)*radius,pawn.Pos.Y+sin(angle)*radius,pawn.Pos.Z);
            Actor monster=Actor.Spawn(kind,pos,ALLOW_REPLACE);
            if(!monster) continue;
            monster.ClearCounters();
            monster.SetOrigin((monster.Pos.X,monster.Pos.Y,monster.FloorZ),false);
            bool safe=monster.TestMobjLocation() && !monster.bFRIENDLY &&
                abs(monster.Pos.Z-pawn.Pos.Z)<128 && pawn.CheckSight(monster);
            for(int p=0;p<TUIN_MAX_PLAYERS;p++)
                if(playerInGame[p] && players[p].mo && players[p].mo.Distance3D(monster)<256) safe=false;
            if(safe)
            {
                if(!GetMonsterData(monster)) InitializeMonster(monster);
                let data=GetMonsterData(monster);
                if(data)
                {
                    ApplyOrdinaryMonsterScale(monster,data,RollMonsterLevel(rarity),rarity,true);
                    FullHealthReinforcement=monster;
                    monster.bDORMANT=false;monster.bAMBUSH=false;monster.Target=pawn;
                    if(monster.SeeState) monster.SetState(monster.SeeState);
                    Actor.Spawn('TeleportFog',monster.Pos,ALLOW_REPLACE);
                    PromotionBannerStart=0;PromotionBannerStart=NextBannerSlot();
                    PromotionBannerTitle="TOO HEALTHY FOR HELL";
                    PromotionBannerDetail=RarityName(rarity).." REINFORCEMENT - "..data.GeneratedName.MakeUpper();
                    return true;
                }
            }
            monster.Destroy();
        }
        return false;
    }
    void UpdateFullHealthDirector()
    {
        if(ClassesEnabled()) return;
        ScheduleFullHealthCheck();
        if(FullHealthCheckDone || level.time<FullHealthCheckTime) return;
        // Exactly one check, including low-health and blocked-spawn outcomes.
        FullHealthCheckDone=true;
        if(!CVInt('tuin_director_enabled',1) || !CVInt('tuin_rarity_enabled',1)) return;
        for(int p=0;p<TUIN_MAX_PLAYERS;p++)
            if(playerInGame[p] && AtFullHealth(players[p].mo))
            {
                SpawnFullHealthReinforcement(p,PressureRarity(Random[TuinHealthDirector](0,99)));
                return;
            }
    }
    static bool AmmoPressureThreshold(int bullets,int rockets,int cells,int fuel,int shells,bool chaingunPerk)
    {
        return bullets>=(chaingunPerk?800:300) && rockets>=75 &&
            cells>600 && fuel>300 && shells>100;
    }
    bool HasAmmoSurplus(Actor pawn)
    {
        if(!pawn) return false;
        int bullets=0,rockets=0,cells=0,fuel=0,shells=0;
        // Count inventory pools once, not once per weapon sharing that ammo.
        // A missing pool stays zero: ALL five conditions must be satisfied.
        for(Inventory item=pawn.Inv;item;item=item.Inv)
        {
            if(item is 'Clip') bullets+=max(0,item.Amount);
            else if(item is 'RocketAmmo') rockets+=max(0,item.Amount);
            else if(item is 'Cell') cells+=max(0,item.Amount);
            else if(item is 'ID24Fuel') fuel+=max(0,item.Amount);
            else if(item is 'Shell') shells+=max(0,item.Amount);
        }
        return AmmoPressureThreshold(bullets,rockets,cells,fuel,shells,HasWeaponPerk(GetPlayerData(pawn),5));
    }
    bool PromoteAmmoPressureMonster()
    {
        Actor candidate;
        int best=-1,choices=0;
        let it=ThinkerIterator.Create('Actor');
        Actor monster;
        while((monster=Actor(it.Next())))
        {
            let data=GetMonsterData(monster);
            if(!IsHeavyRarityEligible(monster,data) || data.MonsterRarity>=5) continue;
            int priority=SpawnRarityPriority(monster,data);
            if(priority<1) continue;
            if(priority>best) { best=priority;choices=1;candidate=monster; }
            else if(priority==best && Random[TuinRPGDirector](1,++choices)==1) candidate=monster;
        }
        if(!candidate || !UpgradeDirectorMonster(candidate,5)) return false;
        let data=GetMonsterData(candidate);
        data.AffixFlags=(data.AffixFlags & ~TuinMonsterData.AFFIX_REGENERATING) | TuinMonsterData.AFFIX_ARMORED;
        PromotionBannerTitle="HELL ANSWERS YOUR ARSENAL";
        PromotionBannerDetail=data.GeneratedName.MakeUpper().." / MYTHIC + ARMORED";
        return true;
    }
    void UpdateAmmoPressureDirector()
    {
        if(ClassesEnabled() || !CVInt('tuin_director_enabled',1) || !CVInt('tuin_rarity_enabled',1)) return;
        TuinPlayerData clockData;
        for(int i=0;i<TUIN_MAX_PLAYERS;i++)
            if(playerInGame[i] && players[i].mo && players[i].mo.Health>0)
            { clockData=GetPlayerData(players[i].mo); if(clockData) break; }
        if(!clockData) return;
        if(clockData.AmmoPressureCheckRemaining<=0) clockData.AmmoPressureCheckRemaining=35*600;
        clockData.AmmoPressureCheckRemaining--;
        // Keep one shared check cadence, carried by player inventory across maps.
        for(int i=0;i<TUIN_MAX_PLAYERS;i++)
            if(playerInGame[i] && players[i].mo)
            {
                let d=GetPlayerData(players[i].mo);
                if(d && d!=clockData) d.AmmoPressureCheckRemaining=clockData.AmmoPressureCheckRemaining;
            }
        if(clockData.AmmoPressureCheckRemaining>0) return;
        clockData.AmmoPressureCheckRemaining=35*600;
        for(int p=0;p<TUIN_MAX_PLAYERS;p++)
            if(playerInGame[p] && players[p].mo && players[p].mo.Health>0 && HasAmmoSurplus(players[p].mo))
            { PromoteAmmoPressureMonster(); return; }
    }
    void EnsureLocator()
    {
        if (ClassesEnabled() || Locator) return;
        // Adopt the first locator release when loading its saves; older saves
        // have no separate handler, so create state owned by this existing one.
        Locator = TuinLocatorHandler(EventHandler.Find('TuinLocatorHandler'));
        if (!Locator) { Locator = new('TuinLocatorHandler'); Locator.Category = -1; }
        // Also covers unlocking settings on the title screen before a map starts.
        let admin = CVar.FindCVar('tuin_admin_session');
        if (!netgame && admin && admin.GetBool()) Locator.Unlocked = true;
    }
	const TUIN_MAX_PLAYERS = 8;
	const TUIN_MAX_OVERHEAD_BARS = 32;
	const TUIN_MAX_DAMAGE_NUMBERS = 64;
	const TUIN_DAMAGE_NUMBER_LIFETIME = 42;
	const TUIN_LAST_HIT_TARGET_TICS = 175;
	const TUIN_MAX_TRACKED_GRENADES = 64;
	int NextMonsterID;
	int CompletionBannerStart[3];
	bool CompletionAnnounced[3];
	int CoinBannerStart[8], CoinBannerAmount[8];
	bool BootstrappingCoinStack;
	int PressureKills[8], PressureDamage[8], PressureStart[8];
	int PressureNextTime;
	Actor PressureReinforcement;
	int MapsVisited;
	int PreviousLoadedCampaignMap;
	int CurrentLoadedCampaignMap;
	bool CatchupHandled[TUIN_MAX_PLAYERS];
	bool InitialClassMenuRequested[TUIN_MAX_PLAYERS];
	bool ApplyingBonusDamage;
	bool InspectWeapon[8];
	bool ApplyingRogueChainStrike;
	int RogueChainStrikePlayer;
	bool ApplyingRoguePistolBurst;
	int RoguePistolBurstPlayer;
	bool RogueChainTestActive[TUIN_MAX_PLAYERS];
	int RogueChainTestHits[TUIN_MAX_PLAYERS];
	Actor RoguePistolBurstTestTarget[TUIN_MAX_PLAYERS];
	int RoguePistolBurstTestHealth[TUIN_MAX_PLAYERS];
	bool RoguePistolBurstTestPending[TUIN_MAX_PLAYERS];
	int RoguePistolBurstTestReleaseTics[TUIN_MAX_PLAYERS];
	int NextLootID;
	bool FinaleBossPromoted;
	Actor FinaleBoss;
	TuinJohnShopNPC JohnMerchant;
	// Absolute map-tic schedules; +1 distinguishes an event on tic zero.
	int BossBannerStart;
	int JohnBannerStart;
	int BossArrivalBannerStart;
	int PromotionBannerStart;
	string PromotionBannerTitle, PromotionBannerDetail;
	int HeavyBannerStart[TUIN_MAX_PLAYERS];
	int WeaponBannerStart[TUIN_MAX_PLAYERS];
	int WeaponBannerQuality[TUIN_MAX_PLAYERS];
	string WeaponBannerDetail[TUIN_MAX_PLAYERS];
	int PointBannerStart[TUIN_MAX_PLAYERS];
	int PointBannerStats[TUIN_MAX_PLAYERS], PointBannerPerks[TUIN_MAX_PLAYERS], PointBannerWeapons[TUIN_MAX_PLAYERS];
	int PoisonBannerStart[TUIN_MAX_PLAYERS], PoisonBannerTick[TUIN_MAX_PLAYERS], PoisonBannerDamage[TUIN_MAX_PLAYERS];
	int KnownKeyMask[TUIN_MAX_PLAYERS], KeyBannerMask[TUIN_MAX_PLAYERS], KeyBannerStart[TUIN_MAX_PLAYERS];
	bool KeySnapshotReady[TUIN_MAX_PLAYERS];
	void UpdateKeyNotice(int playerNumber, Actor pawn)
	{
		if (ClassesEnabled() || !pawn) return;
		int mask = 0;
		for (int key = 0; key < 6; key++)
			if (pawn.CheckKeys(key + 1, false, true)) mask |= 1 << key;
		int added = mask & ~KnownKeyMask[playerNumber];
		if (KeySnapshotReady[playerNumber] && added)
		{
			if (KeyBannerStart[playerNumber] <= 0 || level.Time >= KeyBannerStart[playerNumber] + 105)
				KeyBannerMask[playerNumber] = 0;
			KeyBannerMask[playerNumber] |= added;
			KeyBannerStart[playerNumber] = level.Time + 1;
		}
		KnownKeyMask[playerNumber] = mask;
		KeySnapshotReady[playerNumber] = true;
	}
	void AnnouncePoints(int playerNumber, int stats, int perks, int weapons)
	{
		if (ClassesEnabled() || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS ||
			(stats <= 0 && perks <= 0 && weapons <= 0)) return;
		if (PointBannerStart[playerNumber] <= 0 || level.Time >= PointBannerStart[playerNumber] + 140)
		{
			PointBannerStats[playerNumber] = 0;
			PointBannerPerks[playerNumber] = 0;
			PointBannerWeapons[playerNumber] = 0;
		}
		PointBannerStart[playerNumber] = level.Time + 1;
		PointBannerStats[playerNumber] += max(0, stats);
		PointBannerPerks[playerNumber] += max(0, perks);
		PointBannerWeapons[playerNumber] += max(0, weapons);
	}
	void UpdatePointReminder(int playerNumber, TuinPlayerData data)
	{
		if (ClassesEnabled() || !data || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS) return;
		if (data.UnspentStatPoints <= 0 && data.UnspentSkillPoints <= 0 && data.UnspentWeaponPerkPoints <= 0)
		{
			PointBannerStart[playerNumber] = 0;
			return;
		}
		if (!data.Owner || data.Owner.Health <= 0) return;
		// Game-time cadence: pausing does not burn through the reminder interval.
		if (PointBannerStart[playerNumber] <= 0 || level.Time + 1 - PointBannerStart[playerNumber] >= 30 * 35)
		{
			PointBannerStart[playerNumber] = level.Time + 1;
			PointBannerStats[playerNumber] = max(0, data.UnspentStatPoints);
			PointBannerPerks[playerNumber] = max(0, data.UnspentSkillPoints);
			PointBannerWeapons[playerNumber] = max(0, data.UnspentWeaponPerkPoints);
		}
	}
	void AnnounceWeaponDrop(TuinWeaponDrop drop)
	{
		if (ClassesEnabled() || !drop) return;
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
		{
			Actor pawn = playerInGame[i] ? players[i].mo : null;
			if (!pawn || pawn.Health <= 0 || pawn.Distance3D(drop) > 1536) continue;
			int quality = clamp(drop.Quality, 1, 7);
			// Keep nearby loot timely, but do not let a lesser drop erase a rare find.
			int duration = 70 + min(6, WeaponBannerQuality[i]) * 12;
			if (WeaponBannerStart[i] > 0 && level.Time < WeaponBannerStart[i] + duration &&
				quality < WeaponBannerQuality[i]) continue;
			WeaponBannerStart[i] = level.Time + 1;
			WeaponBannerQuality[i] = quality;
			WeaponBannerDetail[i] = WeaponBaseName(drop.WeaponType).MakeUpper() ..
				String.Format(" - ITEM LEVEL %d", drop.ItemLevel);
		}
	}
	int NextBannerSlot()
	{
		int start = level.Time + 1;
		for(int c=0;c<3;c++) if(CompletionBannerStart[c]>0) start=max(start,CompletionBannerStart[c]+168);
		for(int c=0;c<8;c++) if(CoinBannerStart[c]>0) start=max(start,CoinBannerStart[c]+168);
		if (BossBannerStart > 0) start = max(start, BossBannerStart + 112);
		if (JohnBannerStart > 0) start = max(start, JohnBannerStart + 112);
		if (BossArrivalBannerStart > 0) start = max(start, BossArrivalBannerStart + 168);
		if (PromotionBannerStart > 0) start = max(start, PromotionBannerStart + 168);
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
			if (HeavyBannerStart[i] > 0) start = max(start, HeavyBannerStart[i] + 168);
		return start;
	}
	void UpdateCompletionMilestones()
	{
		if(ClassesEnabled() || level.Time<2) return;
		bool completed[3];
		completed[0]=level.total_monsters>0 && level.killed_monsters>=level.total_monsters;
		completed[1]=level.total_items>0 && level.found_items>=level.total_items;
		completed[2]=level.total_secrets>0 && level.found_secrets>=level.total_secrets;
		for(int i=0;i<3;i++)
			if(completed[i] && !CompletionAnnounced[i])
			{
				CompletionAnnounced[i]=true;
				CompletionBannerStart[i]=NextBannerSlot();
			}
	}
	void RecordCoinMilestone(Actor pawn, int collected)
	{
		if(ClassesEnabled() || BootstrappingCoinStack || !pawn || collected<=0) return;
		int playerNumber=pawn.PlayerNumber();
		if(playerNumber<0 || playerNumber>=8) return;
		let data=GetPlayerData(pawn);
		if(!data) return;
		if(!data.MilestoneCoinsInitialized)
		{
			let coins=Inventory(pawn.FindInventory('TuinCoinPickup'));
			data.MilestoneCoinsEarned=max(0,(coins?coins.Amount:0)-collected);
			data.MilestoneCoinsInitialized=true;
		}
		int previous=data.MilestoneCoinsEarned/100;
		data.MilestoneCoinsEarned+=collected;
		if(data.MilestoneCoinsEarned/100>previous)
		{
			CoinBannerAmount[playerNumber]=data.MilestoneCoinsEarned/100*100;
			// Coalesce a large coin shower rather than replaying a long popup backlog.
			if(CoinBannerStart[playerNumber]<=0 || level.Time>=CoinBannerStart[playerNumber]+168)
				CoinBannerStart[playerNumber]=NextBannerSlot();
		}
	}
	void AnnounceHeavyMilestone(int playerNumber)
	{
		if (!ClassesEnabled() && playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS)
			HeavyBannerStart[playerNumber] = NextBannerSlot();
	}
	void AnnounceMilestone(bool john)
	{
		if (ClassesEnabled()) return;
		if (!john) BossArrivalBannerStart = 0;
		int start = NextBannerSlot();
		if (john) JohnBannerStart = start;
		else
		{
			BossArrivalBannerStart = 0; // A quick kill supersedes the arrival challenge.
			BossBannerStart = start;
			if (JohnBannerStart > level.Time) JohnBannerStart = start + 112;
		}
	}
	int EpisodeTravelTics;
	bool EpisodeTravelShowsIntermission;
	int AppliedDifficultyMode;
	bool MonsterLevelsSynchronized;
	int DirectorCheckpoint;
	bool DirectorEmergencyAmmoUsed[4];
	int DirectorDamageTaken[TUIN_MAX_PLAYERS];
	Vector3 DirectorTrailPosition[TUIN_MAX_PLAYERS];
	bool DirectorTrailValid[TUIN_MAX_PLAYERS];
	int EpisodeTravelPlayer;
	string EpisodeTravelDestination;
	bool UseHeld[TUIN_MAX_PLAYERS];
	const WEAPON_PICKUP_HOLD_TICS = 105;
	int WeaponPickupHold[8];
	bool WeaponPickupConsumed[8];
	bool WeaponPickupInReach[8];
	TuinWeaponDrop WeaponPickupTarget[8];
	TuinWeaponDrop TargetWeaponDrop[TUIN_MAX_PLAYERS];
	int WeaponDropTargetGrace[TUIN_MAX_PLAYERS];
	string LootNotification[TUIN_MAX_PLAYERS];
	int LootNotificationTics[TUIN_MAX_PLAYERS];
	int LootNotificationQuality[TUIN_MAX_PLAYERS];
	string DifficultyNoticeTitle[TUIN_MAX_PLAYERS];
	string DifficultyNoticeStats[TUIN_MAX_PLAYERS];
	int DifficultyNoticeTics[TUIN_MAX_PLAYERS];
	int JohnCommentMilestone[TUIN_MAX_PLAYERS];
	int JohnCommentTics[TUIN_MAX_PLAYERS];
	int JohnCommentQuote[TUIN_MAX_PLAYERS];
	int JohnCommentPercent[TUIN_MAX_PLAYERS];
	string TargetName[TUIN_MAX_PLAYERS];
	string TargetAffixes[TUIN_MAX_PLAYERS];
	bool TargetDeathSentence[TUIN_MAX_PLAYERS];
	bool TargetIsBoss[TUIN_MAX_PLAYERS];
	int TargetLevel[TUIN_MAX_PLAYERS];
	int TargetRarity[TUIN_MAX_PLAYERS];
	int TargetHealth[TUIN_MAX_PLAYERS];
	int TargetMaxHealth[TUIN_MAX_PLAYERS];
	double TargetPreviousDisplayHealth[TUIN_MAX_PLAYERS];
	double TargetDisplayHealth[TUIN_MAX_PLAYERS];
	Actor LastHitTarget[TUIN_MAX_PLAYERS];
	int LastHitTargetTics[TUIN_MAX_PLAYERS];
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
	int DamageNumberElement[TUIN_MAX_DAMAGE_NUMBERS];
	double DamageNumberCurl[TUIN_MAX_DAMAGE_NUMBERS];
	int NextDamageNumber;
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
	double WeaponSwitchAccumulator[TUIN_MAX_PLAYERS];
	State RustChargeState[TUIN_MAX_PLAYERS];
	int WeaponPerkShotgunProcTime[TUIN_MAX_PLAYERS];
	int WeaponPerkPierceProcTime[TUIN_MAX_PLAYERS];
	class<Ammo> WeaponPerkTrackedAmmo[TUIN_MAX_PLAYERS];
	int WeaponPerkTrackedAmmoAmount[TUIN_MAX_PLAYERS];
	const TUIN_MAX_GUIDED_PROJECTILES = 128;
	Actor WeaponPerkGuidedProjectile[TUIN_MAX_GUIDED_PROJECTILES];
	int WeaponPerkGuidedOwner[TUIN_MAX_GUIDED_PROJECTILES];
	int NextWeaponPerkGuidedProjectile;
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

	clearscope static bool ClassesEnabled()
	{
		// This actor class is injected only by build-noclasses.ps1. A class marker
		// is deterministic and cannot be overridden by a persisted user CVAR.
		return FindClass('TuinNoClassesBuildMarker', 'Actor') == null;
	}

	clearscope static int WeaponFamily(Weapon weapon)
	{
		if (!weapon) return 0;
		if (weapon is 'ID24CalamityBlade') return 10;
		if (weapon is 'ID24Incinerator') return 9;
		string identity = String.Format("%s %s", weapon.GetClassName(),
			weapon.GetTag(weapon.GetClassName())).MakeLower();
		if (identity.IndexOf("bfg") >= 0) return 7;
		if (identity.IndexOf("rocket") >= 0 || identity.IndexOf("missilelauncher") >= 0) return 8;
		if (identity.IndexOf("plasma") >= 0) return 6;
		if (identity.IndexOf("chaingun") >= 0 || identity.IndexOf("minigun") >= 0 ||
			identity.IndexOf("gatling") >= 0) return 5;
		if (identity.IndexOf("supershotgun") >= 0 || identity.IndexOf("super shotgun") >= 0 ||
			identity.IndexOf("doublebarrel") >= 0 || identity.IndexOf("double barrel") >= 0) return 4;
		if (identity.IndexOf("shotgun") >= 0) return 3;
		if (identity.IndexOf("fist") >= 0 || identity.IndexOf("knuckle") >= 0 ||
			identity.IndexOf("punch") >= 0 || weapon.bMELEEWEAPON) return 2;
		if (identity.IndexOf("pistol") >= 0 || identity.IndexOf("handgun") >= 0 ||
			identity.IndexOf("revolver") >= 0) return 1;

		// AmmoType1 is a class reference, not a string accepted by %s. Resolve
		// its defaults first; ammo-less custom weapons have no fallback family.
		if (!weapon.AmmoType1) return 0;
		readonly<Ammo> ammoDefault = GetDefaultByType(weapon.AmmoType1);
		if (!ammoDefault) return 0;
		string ammoName = String.Format("%s", ammoDefault.GetClassName()).MakeLower();
		if (ammoName.IndexOf("rocket") >= 0) return 8;
		if (ammoName.IndexOf("shell") >= 0) return weapon.AmmoUse1 >= 2 ? 4 : 3;
		if (ammoName.IndexOf("cell") >= 0) return weapon.AmmoUse1 >= 20 ? 7 : 6;
		if (ammoName.IndexOf("clip") >= 0 || ammoName.IndexOf("bullet") >= 0)
			return weapon.SelectionOrder < 1000 ? 5 : 1;
		return 0;
	}

	clearscope static bool HasWeaponPerk(TuinPlayerData data, int family)
	{
		return !ClassesEnabled() && data && family >= 1 && family <= 10 &&
			(data.WeaponPerkFlags & (1 << (family - 1))) != 0;
	}

	clearscope static string WeaponPerkName(int family)
	{
		switch (family)
		{
		case 1: return "DEADEYE PISTOL";
		case 2: return "BLOOD KNUCKLES";
		case 3: return "INFERNO SHOTGUN";
		case 4: return "PHASING SUPER SHOTGUN";
		case 5: return "AMMO EATER CHAINGUN";
		case 6: return "SEEKER PLASMA";
		case 7: return "RAPID BFG";
		case 8: return "HELLFIRE ROCKETS";
		case 9: return "WILDFIRE INCINERATOR";
		case 10: return "OVERCHARGE CALAMITY BLADE";
		default: return "NO WEAPON PERK";
		}
	}

	clearscope static string WeaponPerkSummary(int family)
	{
		switch (family)
		{
		case 1: return "+100% DAMAGE  |  HALF FIRE RATE";
		case 2: return "BERSERK x1.5  |  LOSE 5% HEALTH PER HIT";
		case 3: return "AREA BURN: 50% OVER 3S; REFRESHES  |  -15% DIRECT DAMAGE";
		case 4: return "PIERCES MONSTERS/ARMOR  |  -25% DAMAGE";
		case 5: return "x3 DAMAGE/CAPACITY  |  x3 AMMO COST";
		case 6: return "PROJECTILES GUIDE TOWARD NEARBY ENEMIES";
		case 7: return "x4 FIRE RATE  |  ONE-QUARTER DAMAGE";
		case 8: return "-30% DAMAGE | 25% CRIT | +50% BURN / 5s, STACKS";
		case 9: return "FIRE SPREADS TO 3 NEARBY FOES | +25% FUEL USE";
		case 10: return "+50% DAMAGE / WAVE WIDTH | 30% LONGER CHARGE";
		default: return "NO SPECIALIZATION FOR THIS WEAPON";
		}
	}

	int SyncWeaponPerkMilestones(TuinPlayerData data)
	{
		if (!data || ClassesEnabled()) return 0;
		int earned = clamp(data.PlayerLevel / 5, 0, 6);
		if (!data.WeaponPerkScheduleInitialized)
		{
			data.WeaponPerkMilestonesAwarded = 0;
			data.WeaponPerkScheduleInitialized = true;
		}
		int gained = max(0, earned - data.WeaponPerkMilestonesAwarded);
		if (gained > 0)
		{
			data.UnspentWeaponPerkPoints += gained;
			data.WeaponPerkMilestonesAwarded = earned;
			if (data.Owner) AnnouncePoints(data.Owner.PlayerNumber(), 0, 0, gained);
		}
		return gained;
	}

	clearscope static int DifficultyMode()
	{
		if(TuinRun.Active())return 2;
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

	bool HasFodderDebuff(Actor target)
	{
		if (!IsValidMonster(target)) return false;
		if (target is 'LostSoul') return true;
		let data = GetMonsterData(target);
		if (data && data.FodderCheckTime > level.Time) return data.CrowdFodderDebuffed;
		int nearbyMonsters = 0;
		bool crowded = false;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor candidate;
		while (candidate = Actor(iterator.Next()))
		{
			if (!IsValidMonster(candidate) || target.Distance3D(candidate) > 512.0) continue;
			nearbyMonsters++;
			if (nearbyMonsters >= 11)
			{
				crowded = true;
				break;
			}
		}
		if (data)
		{
			data.CrowdFodderDebuffed = crowded;
			data.FodderCheckTime = level.Time + 18;
		}
		return crowded;
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
		if (!ClassesEnabled()) return "DOOM MARINE";
		switch (playerClass)
		{
		case 1: return "HEAVY";
		case 2: return "HEALER";
		case 3: return "EXECUTIONER";
		case 4: return "DOOM GUY";
		case 5: return "ROGUE";
		case 6: return "ENGINEER";
		default: return "UNSELECTED";
		}
	}

	clearscope static int RogueVeilDuration(TuinPlayerData data)
	{
		return 630 + (data ? data.PerkClassMastery : 0) * 210;
	}

	clearscope static int RogueChargeDamageRequired(TuinPlayerData data)
	{
		return 400 + max(1, data ? data.PlayerLevel : 1) * 60;
	}

	clearscope static int TankOverdriveDuration()
	{
		return 350;
	}

	clearscope static int HeavyRadioCooldown(TuinPlayerData data)
	{
		double trainingReduction = clamp(data ? data.PerkClassMastery : 0, 0, 3) * 0.10;
		// 4,095 damage is 30% above the original 3,150 requirement.
		return max(35, int(4095 * (1.0 - trainingReduction) + 0.5));
	}

	void ReduceHeavyRadioCooldown(int playerNumber, TuinPlayerData data, int damage)
	{
		if (!data || data.PlayerClass != 1 || data.HeavyRadioCooldownTics <= 0 || damage <= 0) return;
		int previous = data.HeavyRadioCooldownTics;
		data.HeavyRadioCooldownTics = max(0, data.HeavyRadioCooldownTics - damage);
		if (previous > 0 && data.HeavyRadioCooldownTics == 0)
			SetLootNotification(playerNumber, "RADIO SUPPORT READY - PRESS B", 4);
	}

	clearscope static int HealerSupplyCooldown()
	{
		return 700;
	}

	clearscope static int EngineerSlotCount(TuinPlayerData data)
	{
		return data && data.PerkCapstone ? 2 : 1;
	}

	void InitializeEngineerSentries(TuinPlayerData data)
	{
		if (!data || data.EngineerSentriesInitialized) return;
		data.EngineerSentriesInitialized = true;
		data.EngineerSentryMap = String.Format("%s", level.MapName);
		let legacyTurret = TuinEngineerTurret(data.EngineerTurret);
		if (legacyTurret && legacyTurret.Health > 0 && legacyTurret.ShotsRemaining > 0)
		{
			legacyTurret.SentrySlot = 0;
			data.EngineerSentry[0] = legacyTurret;
			data.EngineerSentryDeployed[0] = true;
			data.EngineerSentryReady[0] = true;
			data.EngineerSentryStoredHealth[0] = legacyTurret.Health;
			data.EngineerSentryStoredRounds[0] = legacyTurret.ShotsRemaining;
		}
		else
		{
			data.EngineerSentryReady[0] = true;
			data.EngineerSentryStoredHealth[0] = 400;
			data.EngineerSentryStoredRounds[0] = 250;
		}
		data.EngineerTurret = null;
		data.EngineerTurretCooldownTics = 0;
		if (data.PerkCapstone)
		{
			data.EngineerSecondSentryGranted = true;
			data.EngineerSentryReady[1] = true;
			data.EngineerSentryStoredHealth[1] = 400;
			data.EngineerSentryStoredRounds[1] = 250;
		}
	}

	void AddEngineerFabrication(int playerNumber, TuinPlayerData data, double amount)
	{
		if (!data || data.PlayerClass != 6 || amount <= 0.0) return;
		InitializeEngineerSentries(data);
		double remaining = amount * (1.0 + data.PerkClassMastery * 0.10);
		for (int slot = 0; slot < EngineerSlotCount(data) && remaining > 0.0; slot++)
		{
			if (data.EngineerSentryReady[slot] || data.EngineerSentryDeployed[slot]) continue;
			double needed = 100.0 - data.EngineerSentryFabrication[slot];
			double applied = min(needed, remaining);
			data.EngineerSentryFabrication[slot] += applied;
			remaining -= applied;
			if (data.EngineerSentryFabrication[slot] >= 99.999)
			{
				data.EngineerSentryFabrication[slot] = 0.0;
				data.EngineerSentryReady[slot] = true;
				data.EngineerSentryStoredHealth[slot] = 400;
				data.EngineerSentryStoredRounds[slot] = 250;
				SetLootNotification(playerNumber, String.Format("SENTRY %d REBUILT - READY TO DEPLOY", slot + 1), 4);
			}
		}
	}

	void UpdateEngineerAmmoFabrication(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 6) return;
		InitializeEngineerSentries(data);
		for (Inventory item = pawn.Inv; item; item = item.Inv)
		{
			let ammo = Ammo(item);
			if (!ammo) continue;
			class<Ammo> ammoType = (class<Ammo>)(ammo.GetClass());
			int index = -1;
			for (int i = 0; i < data.EngineerAmmoCount; i++)
				if (data.EngineerAmmoType[i] == ammoType) { index = i; break; }
			if (index < 0)
			{
				if (data.EngineerAmmoCount >= 32) continue;
				index = data.EngineerAmmoCount++;
				data.EngineerAmmoType[index] = ammoType;
				data.EngineerAmmoLastAmount[index] = ammo.Amount;
				continue;
			}
			int gained = ammo.Amount - data.EngineerAmmoLastAmount[index];
			if (gained > 0)
			{
				double weight = ammo is 'RocketAmmo' ? 2.5 : ammo is 'Shell' ? 1.0 : 0.25;
				AddEngineerFabrication(playerNumber, data, min(8.0, gained * weight));
			}
			data.EngineerAmmoLastAmount[index] = ammo.Amount;
		}
	}

	void UpdateEngineerSentries(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 6) return;
		InitializeEngineerSentries(data);
		string currentMap = String.Format("%s", level.MapName);
		if (!(data.EngineerSentryMap ~== currentMap))
		{
			for (int slot = 0; slot < 2; slot++)
			{
				data.EngineerSentry[slot] = null;
				data.EngineerSentryDeployed[slot] = false;
				if (data.EngineerSentryStoredHealth[slot] > 0 && data.EngineerSentryStoredRounds[slot] > 0)
					data.EngineerSentryReady[slot] = true;
			}
			data.EngineerSentryMap = currentMap;
		}
		if (data.PerkCapstone && !data.EngineerSecondSentryGranted)
		{
			data.EngineerSecondSentryGranted = true;
			data.EngineerSentryReady[1] = true;
			data.EngineerSentryStoredHealth[1] = 400;
			data.EngineerSentryStoredRounds[1] = 250;
		}
		for (int slot = 0; slot < EngineerSlotCount(data); slot++)
		{
			if (!data.EngineerSentryDeployed[slot]) continue;
			let turret = TuinEngineerTurret(data.EngineerSentry[slot]);
			if (turret && turret.Health > 0 && turret.ShotsRemaining > 0)
			{
				turret.master = pawn;
				turret.TrainingRank = clamp(data.PerkClassMastery, 0, 3);
				data.EngineerSentryStoredHealth[slot] = turret.Health;
				data.EngineerSentryStoredRounds[slot] = turret.ShotsRemaining;
				continue;
			}
			bool ranDry = turret && turret.ShotsRemaining <= 0;
			if (turret) turret.Destroy();
			data.EngineerSentry[slot] = null;
			data.EngineerSentryDeployed[slot] = false;
			data.EngineerSentryReady[slot] = false;
			data.EngineerSentryStoredHealth[slot] = 0;
			data.EngineerSentryStoredRounds[slot] = 0;
			data.EngineerSentryFabrication[slot] = 0.0;
			SetLootNotification(playerNumber, ranDry ?
				String.Format("SENTRY %d EMPTY - KILLS OR AMMO REBUILD IT", slot + 1) :
				String.Format("SENTRY %d DESTROYED - KILLS OR AMMO REBUILD IT", slot + 1), 0);
		}
	}

	int NearbyEngineerSentry(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return -1;
		int nearest = -1;
		double nearestDistance = 113.0;
		for (int slot = 0; slot < EngineerSlotCount(data); slot++)
		{
			let turret = TuinEngineerTurret(data.EngineerSentry[slot]);
			if (!data.EngineerSentryDeployed[slot] || !turret || turret.Health <= 0 ||
				turret.ShotsRemaining <= 0) continue;
			double distance = pawn.Distance3D(turret);
			if (distance >= nearestDistance || !pawn.CheckSight(turret, SF_IGNOREWATERBOUNDARY)) continue;
			nearest = slot;
			nearestDistance = distance;
		}
		return nearest;
	}

	void UseEngineerTurret(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 6 || pawn.Health <= 0) return;
		UpdateEngineerSentries(playerNumber, pawn, data);
		int nearby = NearbyEngineerSentry(pawn, data);
		if (nearby >= 0)
		{
			let turret = TuinEngineerTurret(data.EngineerSentry[nearby]);
			data.EngineerSentryStoredHealth[nearby] = turret.Health;
			data.EngineerSentryStoredRounds[nearby] = turret.ShotsRemaining;
			data.EngineerSentryDeployed[nearby] = false;
			data.EngineerSentryReady[nearby] = true;
			data.EngineerSentry[nearby] = null;
			turret.Destroy();
			pawn.A_StartSound("tuin/engineer/deploy", CHAN_ITEM, 0, 0.27);
			SetLootNotification(playerNumber, String.Format("SENTRY %d PACKED: %d HP | %d ROUNDS",
				nearby + 1, data.EngineerSentryStoredHealth[nearby], data.EngineerSentryStoredRounds[nearby]), 4);
			return;
		}
		int deploySlot = -1;
		for (int slot = 0; slot < EngineerSlotCount(data); slot++)
			if (data.EngineerSentryReady[slot] && !data.EngineerSentryDeployed[slot]) { deploySlot = slot; break; }
		if (deploySlot < 0)
		{
			bool hasActive;
			for (int slot = 0; slot < EngineerSlotCount(data); slot++)
				if (data.EngineerSentryDeployed[slot]) { hasActive = true; break; }
			SetLootNotification(playerNumber, hasActive ?
				"MOVE NEAR YOUR SENTRY AND PRESS V TO PACK IT" :
				"NO SENTRY - BUILD FABRICATION WITH KILLS OR AMMO", 0);
			return;
		}
		Vector3 position = pawn.Pos + (cos(pawn.Angle) * 64.0,
			sin(pawn.Angle) * 64.0, 8.0);
		TuinEngineerTurret turret = TuinEngineerTurret(Actor.Spawn('TuinEngineerTurret', position, NO_REPLACE));
		if (!turret || !turret.TestMobjLocation())
		{
			if (turret) turret.Destroy();
			SetLootNotification(playerNumber, "NOT ENOUGH ROOM TO DEPLOY SENTRY", 0);
			return;
		}
		turret.Angle = pawn.Angle;
		int weaponPower = 0;
		int weaponHaste = 0;
		int weaponCritical = 0;
		int variantIndex = ActiveWeaponVariantIndex(playerNumber, data);
		if (variantIndex >= 0)
		{
			weaponPower = int((WeaponItemLevelPowerPercent(data.VariantItemLevel[variantIndex]) +
				data.VariantPowerPercent[variantIndex]) * 0.50 + 0.5);
			weaponHaste = int(data.VariantHastePercent[variantIndex] * 0.50 + 0.5);
			weaponCritical = int(WeaponCriticalPercent(data.VariantAffixFlags[variantIndex],
				data.VariantQuality[variantIndex], data.VariantItemLevel[variantIndex]) * 0.50 + 0.5);
		}
		turret.Configure(playerNumber, deploySlot, pawn, data.PerkClassMastery, data.PlayerLevel,
			weaponPower, weaponHaste, weaponCritical, data.EngineerSentryStoredHealth[deploySlot],
			data.EngineerSentryStoredRounds[deploySlot]);
		data.EngineerSentry[deploySlot] = turret;
		data.EngineerSentryDeployed[deploySlot] = true;
		data.EngineerSentryReady[deploySlot] = true;
		pawn.A_StartSound("tuin/engineer/deploy", CHAN_ITEM, 0, 0.42);
		data.LevelAbilityUses++;
		SetLootNotification(playerNumber, String.Format("SENTRY %d DEPLOYED: %d HP | %d ROUNDS",
			deploySlot + 1, turret.Health, turret.ShotsRemaining), 4);
	}

	clearscope static int ExecutionerMarkDuration(TuinPlayerData data)
	{
		return data && data.PerkCapstone ? 420 : 350;
	}

	double ExecutionerMarkedDamageBonus(TuinPlayerData playerData,
		TuinMonsterData victimData, Actor victim)
	{
		if (!playerData || !victimData || !victim || playerData.PlayerClass != 3 ||
			ExecutionerMarkSlotForTarget(playerData, victim) < 0)
			return 0.0;
		bool bossTarget = victimData.MonsterRarity >= 6 || IsIconicEpisodeBoss(victim);
		return playerData.PerkCapstone ? (bossTarget ? 0.15 : 0.35) :
			(bossTarget ? 0.10 : 0.25);
	}

	clearscope static Name ExecutionerMarkLightName(int playerNumber)
	{
		switch (playerNumber)
		{
		case 0: return 'TuinExecutionerMark0'; case 1: return 'TuinExecutionerMark1';
		case 2: return 'TuinExecutionerMark2'; case 3: return 'TuinExecutionerMark3';
		case 4: return 'TuinExecutionerMark4'; case 5: return 'TuinExecutionerMark5';
		case 6: return 'TuinExecutionerMark6'; default: return 'TuinExecutionerMark7';
		}
	}

	Actor ExecutionerMarkTarget(TuinPlayerData data, int slot)
	{
		if (!data || slot < 0 || slot >= 3) return null;
		return slot == 0 ? data.ExecutionerMarkedTarget : data.ExecutionerExtraMarkedTarget[slot - 1];
	}

	Actor ExecutionerMarkVisual(TuinPlayerData data, int slot)
	{
		if (!data || slot < 0 || slot >= 3) return null;
		return slot == 0 ? data.ExecutionerMarkVisual : data.ExecutionerExtraMarkVisual[slot - 1];
	}

	int ExecutionerMarkTime(TuinPlayerData data, int slot)
	{
		if (!data || slot < 0 || slot >= 3) return 0;
		return slot == 0 ? data.ExecutionerMarkTics : data.ExecutionerExtraMarkTics[slot - 1];
	}

	void SetExecutionerMarkSlot(TuinPlayerData data, int slot, Actor target, Actor visual, int tics)
	{
		if (!data || slot < 0 || slot >= 3) return;
		if (slot == 0)
		{
			data.ExecutionerMarkedTarget = target;
			data.ExecutionerMarkVisual = visual;
			data.ExecutionerMarkTics = tics;
		}
		else
		{
			data.ExecutionerExtraMarkedTarget[slot - 1] = target;
			data.ExecutionerExtraMarkVisual[slot - 1] = visual;
			data.ExecutionerExtraMarkTics[slot - 1] = tics;
		}
	}

	int ExecutionerMarkSlotForTarget(TuinPlayerData data, Actor target)
	{
		if (!data || !target) return -1;
		for (int slot = 0; slot < 3; slot++)
			if (ExecutionerMarkTarget(data, slot) == target && ExecutionerMarkTime(data, slot) > 0)
				return slot;
		return -1;
	}

	int ExecutionerActiveMarkCount(TuinPlayerData data)
	{
		int count;
		for (int slot = 0; slot < 3; slot++)
			if (ExecutionerMarkTarget(data, slot) && ExecutionerMarkTime(data, slot) > 0) count++;
		return count;
	}

	int ExecutionerMaxMarkTime(TuinPlayerData data)
	{
		int result;
		for (int slot = 0; slot < 3; slot++) result = max(result, ExecutionerMarkTime(data, slot));
		return result;
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

	void AddExecutionerDamageCharge(int playerNumber, TuinPlayerData data, int damage)
	{
		if (!data || data.PlayerClass != 3 || damage <= 0 || data.ExecutionerCharge >= 100 ||
			data.HasActiveExecutionerMark()) return;
		int oldCharge = data.ExecutionerCharge;
		data.AddExecutionerCharge(damage);
		if (oldCharge < 100 && data.ExecutionerCharge >= 100)
		{
			data.ExecutionerReadyNotified = true;
			SetLootNotification(playerNumber, "JUDGMENT FULL - PRESS V TO ARM", 4);
		}
	}

	int FindExecutionerSplashTargets(Actor primary, out Actor second, out Actor third)
	{
		second = null; third = null;
		if (!primary) return 0;
		double secondScore = 1000000000.0;
		double thirdScore = 1000000000.0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor candidate;
		while (candidate = Actor(iterator.Next()))
		{
			if (candidate == primary || candidate.Health <= 0 || candidate.bFRIENDLY ||
				!GetMonsterData(candidate)) continue;
			double score = primary.Distance3D(candidate);
			if (score > 384.0 || !primary.CheckSight(candidate, SF_IGNOREWATERBOUNDARY)) continue;
			if (score < secondScore)
			{
				third = second; thirdScore = secondScore;
				second = candidate; secondScore = score;
			}
			else if (score < thirdScore)
			{
				third = candidate; thirdScore = score;
			}
		}
		return third ? 2 : (second ? 1 : 0);
	}

	void ClearExecutionerMarkSlot(int playerNumber, TuinPlayerData data, int slot)
	{
		if (!data || slot < 0 || slot >= 3) return;
		Actor target = ExecutionerMarkTarget(data, slot);
		Actor visual = ExecutionerMarkVisual(data, slot);
		if (target) target.A_RemoveLight(ExecutionerMarkLightName(playerNumber));
		if (visual) visual.Destroy();
		SetExecutionerMarkSlot(data, slot, null, null, 0);
	}

	void ClearExecutionerMark(int playerNumber, TuinPlayerData data)
	{
		if (!data) return;
		for (int slot = 0; slot < 3; slot++) ClearExecutionerMarkSlot(playerNumber, data, slot);
	}

	void UpdateExecutionerSkullMarkerSlot(int playerNumber, TuinPlayerData data, int slot)
	{
		Actor target = ExecutionerMarkTarget(data, slot);
		int tics = ExecutionerMarkTime(data, slot);
		if (!target || tics <= 0) return;
		Actor visual = ExecutionerMarkVisual(data, slot);
		if (!visual)
			visual = Actor.Spawn('TuinExecutionerSkullMarker',
				target.Pos + (0, 0, target.Height + 20), NO_REPLACE);
		if (!visual) return;
		SetExecutionerMarkSlot(data, slot, target, visual, tics);
		double bob = 20.0 + sin((level.Time + playerNumber * 9 + slot * 13) * 7.0) * 3.0;
		visual.SetOrigin(target.Pos + (0, 0, target.Height + bob), false);
		visual.Alpha = 0.78 +
			(sin((level.Time + playerNumber * 5 + slot * 11) * 10.0) + 1.0) * 0.10;
	}

	void UpdateExecutionerSkullMarker(int playerNumber, TuinPlayerData data)
	{
		if (!data) return;
		for (int slot = 0; slot < 3; slot++) UpdateExecutionerSkullMarkerSlot(playerNumber, data, slot);
	}

	void MarkExecutionerTarget(int playerNumber, TuinPlayerData data, int slot, Actor target)
	{
		if (!data || !target || slot < 0 || slot >= 3) return;
		SetExecutionerMarkSlot(data, slot, target, null, ExecutionerMarkDuration(data));
		UpdateExecutionerSkullMarkerSlot(playerNumber, data, slot);
		target.A_AttachLight(ExecutionerMarkLightName(playerNumber), DynamicLight.PulseLight,
			Color(255, 18, 12), 54, 104, DynamicLight.LF_ATTENUATE,
			(0, 0, target.Height * 0.58), 0.32);
		for (int i = 0; i < 18; i++)
		{
			double particleAngle = i * 20.0;
			target.A_SpawnParticle(i & 1 ? Color(255, 30, 12) : Color(150, 0, 0),
				SPF_FULLBRIGHT | SPF_FACECAMERA, 24, 5.0, particleAngle,
				cos(particleAngle) * (target.Radius + 8), sin(particleAngle) * (target.Radius + 8),
				target.Height * 0.55, 0, 0, 1.4, 0, 0, -0.08, 1.0, 0.05, -0.20);
		}
	}

	void ActivateExecutionerDeathSentence(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 3 || pawn.Health <= 0) return;
		int activeMarks = ExecutionerActiveMarkCount(data);
		if (activeMarks > 0)
		{
			SetLootNotification(playerNumber, String.Format("DEATH SENTENCE: %d TARGET%s - %.1f SEC",
				activeMarks, activeMarks == 1 ? "" : "S", ExecutionerMaxMarkTime(data) / 35.0), 0);
			return;
		}
		if (data.ExecutionerCharge < 100)
		{
			SetLootNotification(playerNumber, String.Format("JUDGMENT CHARGE: %d%% - DEAL DAMAGE",
				data.ExecutionerCharge), 0);
			return;
		}
		if (data.ExecutionerJudgmentArmed)
		{
			SetLootNotification(playerNumber, "JUDGMENT ARMED - NEXT SHOT PASSES SENTENCE", 0);
			return;
		}
		data.ExecutionerJudgmentArmed = true;
		SetLootNotification(playerNumber, "JUDGMENT ARMED - NEXT SHOT PASSES SENTENCE", 5);
	}

	bool IsExecutionerJudgmentDamage(Actor inflictor, Actor victim, Name damageType)
	{
		if (IsGrenadeDamage(inflictor, damageType)) return false;
		if (IsPlayerRocketDamage(inflictor, damageType) && !RocketHitWasDirect(inflictor, victim))
			return false;
		return damageType != 'TuinFinalVerdict' && damageType != 'TuinBloodPunch' &&
			damageType != 'TuinBleed' && damageType != 'TuinRocketBurn' &&
			damageType != 'TuinPlasmaArc' && damageType != 'Poison';
	}

	void PassExecutionerSentenceFromHit(int playerNumber, Actor pawn, TuinPlayerData data, Actor primary)
	{
		if (!pawn || !data || !primary || data.PlayerClass != 3 || pawn.Health <= 0 ||
			!data.ExecutionerJudgmentArmed || data.ExecutionerCharge < 100 ||
			data.HasActiveExecutionerMark()) return;
		Actor second, third;
		int extraTargets = FindExecutionerSplashTargets(primary, second, third);
		ClearExecutionerMark(playerNumber, data);
		data.ExecutionerCharge = 0;
		data.ExecutionerChargeRemainder = 0.0;
		data.ExecutionerReadyNotified = false;
		data.ExecutionerRefundGranted = false;
		data.ExecutionerJudgmentArmed = false;
		MarkExecutionerTarget(playerNumber, data, 0, primary);
		if (second) MarkExecutionerTarget(playerNumber, data, 1, second);
		if (third) MarkExecutionerTarget(playerNumber, data, 2, third);
		data.LevelAbilityUses++;
		int targetCount = 1 + extraTargets;
		SetLootNotification(playerNumber, String.Format("DEATH SENTENCE - %d TARGET%s JUDGED",
			targetCount, targetCount == 1 ? "" : "S"), 5);
	}

	void ApplyExecutionerDeathSentence(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!data) return;
		if (data.PlayerClass != 3 || !pawn || pawn.Health <= 0)
		{
			ClearExecutionerMark(playerNumber, data);
			data.ExecutionerJudgmentArmed = false;
			return;
		}
		bool hadMarks = data.HasActiveExecutionerMark();
		for (int slot = 0; slot < 3; slot++)
		{
			Actor target = ExecutionerMarkTarget(data, slot);
			int tics = ExecutionerMarkTime(data, slot);
			if (!target || target.Health <= 0 || tics <= 0)
			{
				if (target || ExecutionerMarkVisual(data, slot) || tics > 0)
					ClearExecutionerMarkSlot(playerNumber, data, slot);
				continue;
			}
			tics--;
			SetExecutionerMarkSlot(data, slot, target, ExecutionerMarkVisual(data, slot), tics);
			if (tics <= 0) ClearExecutionerMarkSlot(playerNumber, data, slot);
			else UpdateExecutionerSkullMarkerSlot(playerNumber, data, slot);
		}
		if (hadMarks && !data.HasActiveExecutionerMark())
			SetLootNotification(playerNumber, "DEATH SENTENCE EXPIRED - BUILD JUDGMENT", 0);
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
		if (data)
		{
			if (!ClassesEnabled() && !data.NoClassModeActive)
			{
				data.NoClassStoredPlayerClass = data.PlayerClass;
				data.PlayerClass = 0;
				data.NoClassModeActive = true;
			}
			else if (ClassesEnabled() && data.NoClassModeActive)
			{
				data.PlayerClass = data.NoClassStoredPlayerClass;
				data.NoClassStoredPlayerClass = 0;
				data.NoClassModeActive = false;
			}
			if (!ClassesEnabled() && players[playerNumber].mo)
			{
				// Bundled replacement and role weapons from a normal-edition save must
				// not leak into the weapon-mod compatibility edition. The saved role is
				// parked above and its normal loadout is granted again when restored.
				Actor pawn = players[playerNumber].mo;
				pawn.TakeInventory('PerkFist', 0x7FFFFFFF);
				pawn.TakeInventory('PerkPistol', 0x7FFFFFFF);
				pawn.TakeInventory('Z86Chainsaw', 0x7FFFFFFF);
				pawn.TakeInventory('PerkShotgun', 0x7FFFFFFF);
				pawn.TakeInventory('PerkSuperShotgun', 0x7FFFFFFF);
				pawn.TakeInventory('Z86Chaingun', 0x7FFFFFFF);
				pawn.TakeInventory('PerkRocketLauncher', 0x7FFFFFFF);
				pawn.TakeInventory('BloxPlasmaRifle', 0x7FFFFFFF);
				pawn.TakeInventory('Z86BFG9000', 0x7FFFFFFF);
				pawn.TakeInventory('TuinMinigun', 0x7FFFFFFF);
				pawn.TakeInventory('TuinMinigunRounds', 0x7FFFFFFF);
				pawn.TakeInventory('TuinMinigunInitialized', 0x7FFFFFFF);
				pawn.TakeInventory('TuinDoomGuyQuadShotgun', 0x7FFFFFFF);
				pawn.TakeInventory('TuinDoomGuyQuadLoaded', 0x7FFFFFFF);
				pawn.TakeInventory('TuinDoomGuyQuadAltChain', 0x7FFFFFFF);
				pawn.TakeInventory('TuinRogueKnife', 0x7FFFFFFF);
				pawn.TakeInventory('TuinRogueSilencedPistol', 0x7FFFFFFF);
				pawn.TakeInventory('TuinRogueBow', 0x7FFFFFFF);
				pawn.TakeInventory('TuinRogueBoltAmmo', 0x7FFFFFFF);
			}
		}
		if (data && !data.LivesInitialized)
		{
			data.Lives = clamp(CVInt('tuin_starting_lives', 3), 1, 99);
			data.LivesInitialized = true;
		}
		if (data && !data.PerkAwardScheduleMigrated)
		{
			// Existing saves earned one point at each five-level milestone. Grant
			// exactly the difference supplied by the expanded level-30 schedule.
			int oldSchedulePoints = max(0, data.PlayerLevel / 5);
			int newSchedulePoints = ScheduledPerkPointsThroughLevel(data.PlayerLevel);
			data.UnspentSkillPoints += max(0, newSchedulePoints - oldSchedulePoints);
			data.PerkAwardScheduleMigrated = true;
		}
		if (data && !data.ArmorPenetrationScheduleMigrated)
		{
			// Saves which already passed level 30 predate the three points added
			// alongside Armor Penetration. Lower-level characters earn them normally.
			if (data.PlayerLevel >= 30) data.UnspentSkillPoints += 3;
			data.ArmorPenetrationScheduleMigrated = true;
		}
		if (data) SyncWeaponPerkMilestones(data);
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

	clearscope static int PerkPointsAtLevel(int playerLevel)
	{
		if (!ClassesEnabled())
		{
			if (playerLevel == 5) return 1;
			if (playerLevel == 10) return 3;
			if (playerLevel == 15) return 4;
			if (playerLevel == 20 || playerLevel == 25) return 5;
			if (playerLevel == 30) return 3;
			return 0;
		}
		if (playerLevel == 5) return 1;
		if (playerLevel == 10) return 3;
		if (playerLevel == 15) return 4;
		if (playerLevel == 20 || playerLevel == 25) return 5;
		if (playerLevel == 30) return 8;
		// Complete builds need no more points, but later milestones retain one
		// point for future perks and additions to the class system.
		if (playerLevel > 30 && (playerLevel % 5) == 0) return 1;
		return 0;
	}

	clearscope static int ScheduledPerkPointsThroughLevel(int playerLevel)
	{
		int total;
		for (int milestone = 5; milestone <= playerLevel; milestone += 5)
			total += PerkPointsAtLevel(milestone);
		return total;
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
		int unmodifiedMaximum = max(1, pawn.GetMaxHealth(true) + data.AppliedClassHealthPenalty -
			data.AppliedLifeEssenceOverhealth);
		int baseMaximum = max(1, unmodifiedMaximum - data.AppliedVitality * 5 - data.AppliedPerkHealth);
		int desiredModifier = data.PlayerClass == 1 ? 175 + data.Strength * 5 - baseMaximum :
			data.PlayerClass == 3 ? -max(1, int(unmodifiedMaximum * 0.25 + 0.5)) :
			data.PlayerClass == 5 ? -max(1, int(unmodifiedMaximum * 0.30 + 0.5)) :
			data.PlayerClass == 6 ? -max(1, int(unmodifiedMaximum * 0.15 + 0.5)) : 0;
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
		// Healer retains its class pickup bonus; Scavenger applies universally.
		double rate = (data.PlayerClass == 2 ? 0.25 : 0.0) +
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
		if (data.PlayerClass == 2 && data.HealerSupplyCooldownTics > 0)
		{
			data.HealerSupplyCooldownTics--;
			if (data.HealerSupplyCooldownTics == 0)
				SetLootNotification(playerNumber, "FIELD SUPPLY READY - PRESS V", 4);
		}
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

	void ActivateHealerSupplyToss(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 2 || pawn.Health <= 0) return;
		if (data.HealerSupplyCooldownTics > 0)
		{
			SetLootNotification(playerNumber, String.Format("FIELD SUPPLY: %.1f SEC",
				data.HealerSupplyCooldownTics / 35.0), 0);
			return;
		}

		int roll = Random[TuinHealerSupply](1, 100);
		class<Actor> pickupType;
		string pickupName;
		if (roll <= 2)
		{
			pickupType = 'Soulsphere';
			pickupName = "SOULSPHERE";
		}
		else if (roll <= 32)
		{
			pickupType = 'HealthBonus';
			pickupName = "HEALTH BONUS";
		}
		else if (roll <= 67)
		{
			pickupType = 'Stimpack';
			pickupName = "STIMPACK";
		}
		else
		{
			pickupType = 'Medikit';
			pickupName = "MEDIKIT";
		}

		Vector3 spawnPosition = pawn.Pos + (cos(pawn.Angle) * 26.0, sin(pawn.Angle) * 26.0,
			max(20.0, pawn.Height * 0.58));
		Actor pickup = Actor.Spawn(pickupType, spawnPosition, ALLOW_REPLACE);
		if (!pickup)
		{
			SetLootNotification(playerNumber, "FIELD SUPPLY COULD NOT FIND ROOM", 0);
			return;
		}
		pickup.bDROPPED = true;
		pickup.Vel = (cos(pawn.Angle) * 10.0, sin(pawn.Angle) * 10.0, 5.5) + pawn.Vel * 0.35;
		pickup.Angle = pawn.Angle;
		data.HealerSupplyCooldownTics = HealerSupplyCooldown();
		data.LevelAbilityUses++;
		for (int particle = 0; particle < 14; particle++)
		{
			pawn.A_SpawnParticle(particle & 1 ? Color(40, 255, 100) : Color(80, 190, 255),
				SPF_FULLBRIGHT | SPF_FACECAMERA, 12, 7.0, 0,
				cos(pawn.Angle) * 20.0, sin(pawn.Angle) * 20.0, pawn.Height * 0.55,
				FRandom[TuinHealerSupply](-1.5, 1.5), FRandom[TuinHealerSupply](-1.5, 1.5),
				FRandom[TuinHealerSupply](0.5, 3.0), 0, 0, -0.04, 0.08);
		}
		SetLootNotification(playerNumber, String.Format("FIELD SUPPLY: %s - 20 SEC COOLDOWN", pickupName), 5);
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
		ReleaseRogueDisengagement(playerNumber, data);
	}

	void ReleaseRogueDisengagement(int playerNumber, TuinPlayerData playerData)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS) return;
		int playerBit = 1 << playerNumber;
		foreach (sector: level.Sectors)
		{
			for (Actor actor = sector.thinglist; actor; actor = actor.snext)
			{
				let monsterData = GetMonsterData(actor);
				if (!monsterData || !(monsterData.RogueVeilDormantMask & playerBit)) continue;
				monsterData.RogueVeilDormantMask &= ~playerBit;
				if (monsterData.RogueVeilDormantMask == 0 && actor.Health > 0)
				{
					actor.bDORMANT = false;
					actor.SetIdle();
				}
			}
		}
		if (playerData && playerData.RogueVeilDecoy)
		{
			playerData.RogueVeilDecoy.Destroy();
			playerData.RogueVeilDecoy = null;
		}
	}

	void MaintainRogueDisengagement(Actor pawn, Actor deathDecoy)
	{
		if (!pawn || !deathDecoy) return;
		foreach (sector: level.Sectors)
		{
			for (Actor actor = sector.thinglist; actor; actor = actor.snext)
			{
				if (!actor.bISMONSTER || actor.bFRIENDLY || actor.Health <= 0) continue;
				// Hand active pursuers an already-dead substitute target. Their normal
				// Doom chase logic then handles the "target died" transition itself,
				// avoiding externally forced idle, angle, velocity, or dormant changes.
				if (actor.Target != pawn) continue;
				actor.Target = deathDecoy;
				if (actor.LastHeard == pawn) actor.LastHeard = deathDecoy;
				if (actor.LastEnemy == pawn) actor.LastEnemy = deathDecoy;
			}
		}
	}

	void ActivateRogueVeil(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 5 || data.RogueVeilCharge < 100) return;
		data.RogueVeiled = true;
		data.RogueVeilTics = 0;
		data.RogueStillTics = 0;
		data.RogueAmbushHitTime = -1;
		data.LevelAbilityUses++;
		pawn.bNOTARGET = true;
		pawn.A_SetRenderStyle(0.50, Style_Translucent);
		ReleaseRogueDisengagement(playerNumber, data);
		data.RogueVeilDecoy = Actor.Spawn('TuinRogueDeathDecoy', pawn.Pos, NO_REPLACE);
		MaintainRogueDisengagement(pawn, data.RogueVeilDecoy);
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
			ReleaseRogueDisengagement(playerNumber, data);
			data.RogueVeilOwner = pawn;
			data.RogueVeiled = false;
			data.RogueVeilTics = 0;
			data.RogueStillTics = 0;
			data.RogueAmbushGraceTics = 0;
			data.RogueAmbushHitTime = -1;
			data.RogueChainActive = false;
			data.RogueChainTics = 0;
			data.RogueChainHitsRemaining = 0;
			data.RogueChainStartCount = 0;
			data.RogueChainVisitedCount = 0;
			data.RogueChainReturnValid = false;
			data.RoguePistolBurstTics = 0;
			data.RoguePistolBurstShotsRemaining = 0;
			for (int chainSlot = 0; chainSlot < 32; chainSlot++) data.RogueChainVisited[chainSlot] = null;
		}
		if (data.PlayerClass != 5)
		{
			if (data.RogueVeiled) BreakRogueVeil(playerNumber, data);
			else if (data.RogueVeilDecoy) ReleaseRogueDisengagement(playerNumber, data);
			return;
		}
		bool attacking = (players[playerNumber].cmd.buttons & (BT_ATTACK | BT_ALTATTACK)) != 0;
		if (data.RogueAmbushGraceTics > 0) data.RogueAmbushGraceTics--;
		if (data.RogueVeiled)
		{
			data.RogueVeilTics++;
			MaintainRogueDisengagement(pawn, data.RogueVeilDecoy);
			if (attacking) BreakRogueVeil(playerNumber, data, true);
			else if (data.RogueVeilTics >= RogueVeilDuration(data)) BreakRogueVeil(playerNumber, data);
			return;
		}
		data.RogueStillTics = 0;
	}

	bool RogueChainAlreadyVisited(TuinPlayerData data, Actor target)
	{
		if (!data || !target) return true;
		for (int i = 0; i < data.RogueChainVisitedCount; i++)
			if (data.RogueChainVisited[i] == target) return true;
		return false;
	}

	Actor FindRogueChainTarget(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return null;
		Actor nearest;
		double nearestDistance = 1024.0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor candidate;
		while (candidate = Actor(iterator.Next()))
		{
			if (!IsValidMonster(candidate) || RogueChainAlreadyVisited(data, candidate)) continue;
			double distance = pawn.Distance3D(candidate);
			if (distance >= nearestDistance || !pawn.CheckSight(candidate, SF_IGNOREWATERBOUNDARY)) continue;
			nearest = candidate;
			nearestDistance = distance;
		}
		return nearest;
	}

	void SpawnRogueShadowSmoke(Vector3 position)
	{
		for (int i = 0; i < 7; i++)
		{
			Vector3 smokePosition = position +
				(FRandom[TuinRogueChain](-18.0, 18.0),
				 FRandom[TuinRogueChain](-18.0, 18.0),
				 FRandom[TuinRogueChain](4.0, 48.0));
			Actor smoke = Actor.Spawn('TuinRogueShadowSmoke', smokePosition, NO_REPLACE);
			if (!smoke) continue;
			double smokeScale = FRandom[TuinRogueChain](0.55, 1.15);
			smoke.Scale *= smokeScale;
			smoke.Vel = (FRandom[TuinRogueChain](-1.2, 1.2),
				FRandom[TuinRogueChain](-1.2, 1.2),
				FRandom[TuinRogueChain](0.6, 2.2));
		}
	}

	bool PlaceRogueBesideTarget(Actor pawn, Actor target)
	{
		if (!pawn || !target) return false;
		Vector3 oldPosition = pawn.Pos;
		for (int attempt = 0; attempt < 8; attempt++)
		{
			double angleOffset = (attempt / 2) * 45.0;
			if (attempt & 1) angleOffset = -angleOffset;
			double angle = target.Angle + 180.0 + angleOffset;
			double distance = attempt < 4 ? 48.0 : 64.0;
			Vector3 destination = target.Pos + (cos(angle) * distance, sin(angle) * distance, 0);
			pawn.SetOrigin(destination, false);
			if (pawn.TestMobjLocation())
			{
				SpawnRogueShadowSmoke(oldPosition);
				SpawnRogueShadowSmoke(pawn.Pos);
				pawn.Angle = pawn.AngleTo(target, true);
				return true;
			}
			pawn.SetOrigin(oldPosition, false);
		}
		return false;
	}

	void FinishRogueChain(int playerNumber, TuinPlayerData data, bool struckTarget)
	{
		if (!data) return;
		int startingCharges = data.RogueChainStartCount;
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS && playerInGame[playerNumber] ?
			players[playerNumber].mo : null;
		bool returnedToStart = !struckTarget;
		bool returnBlocked;
		if (struckTarget && pawn && pawn.Health > 0 && data.RogueChainReturnValid)
		{
			Vector3 chainEndPosition = pawn.Pos;
			pawn.SetOrigin(data.RogueChainStartPosition, false);
			if (pawn.TestMobjLocation())
			{
				SpawnRogueShadowSmoke(chainEndPosition);
				SpawnRogueShadowSmoke(pawn.Pos);
				pawn.Angle = data.RogueChainStartAngle;
				returnedToStart = true;
			}
			else
			{
				pawn.SetOrigin(chainEndPosition, false);
				returnBlocked = true;
				SetLootNotification(playerNumber, "CHAIN RETURN BLOCKED - REMAINING AT LAST TARGET", 0);
			}
		}
		data.RogueChainActive = false;
		data.RogueChainTics = 0;
		data.RogueChainHitsRemaining = 0;
		data.RogueChainStartCount = 0;
		data.RogueChainVisitedCount = 0;
		data.RogueChainReturnValid = false;
		for (int i = 0; i < 32; i++) data.RogueChainVisited[i] = null;
		if (!struckTarget)
		{
			data.RogueChainCharges = clamp(data.RogueChainCharges + startingCharges, 0, 9);
			SetLootNotification(playerNumber, "NO CHAIN TARGET IN RANGE - CHARGES SAVED", 0);
		}
		else if (!returnBlocked) SetLootNotification(playerNumber, "CHAIN ASSASSINATION COMPLETE", 5);
		if (playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS && RogueChainTestActive[playerNumber])
		{
			if (players[playerNumber].mo)
				players[playerNumber].mo.A_Log(String.Format("ROGUE CHAIN RESULT: %d TARGETS STRUCK; RETURN %s.",
					RogueChainTestHits[playerNumber], returnedToStart ? "SUCCESS" : "BLOCKED"));
			RogueChainTestActive[playerNumber] = false;
		}
	}

	void ActivateRogueChain(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 5 || pawn.Health <= 0) return;
		if (data.RogueChainActive)
		{
			SetLootNotification(playerNumber, "CHAIN ASSASSINATION IN PROGRESS", 0);
			return;
		}
		if (data.RogueChainCharges <= 0)
		{
			SetLootNotification(playerNumber, "KNIFE KILL REQUIRED FOR CHAIN ASSASSINATION", 0);
			return;
		}
		data.RogueChainActive = true;
		data.RogueChainTics = 1;
		data.RogueChainStartCount = clamp(data.RogueChainCharges, 1, 9);
		data.RogueChainHitsRemaining = data.RogueChainStartCount;
		data.RogueChainCharges = 0;
		data.RogueChainStartPosition = pawn.Pos;
		data.RogueChainStartAngle = pawn.Angle;
		data.RogueChainReturnValid = true;
		data.RogueChainVisitedCount = 0;
		for (int i = 0; i < 32; i++) data.RogueChainVisited[i] = null;
		SetLootNotification(playerNumber, String.Format("CHAIN ASSASSINATION - %d STRIKES",
			data.RogueChainHitsRemaining), 5);
	}

	void FireRoguePistolBurstShot(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || data.PlayerClass != 5 || pawn.Health <= 0 ||
			data.RoguePistolBurstShotsRemaining <= 0)
		{
			if (data) data.RoguePistolBurstShotsRemaining = 0;
			return;
		}
		let bullets = Ammo(pawn.FindInventory('Clip'));
		if (!bullets || bullets.Amount <= 0)
		{
			data.RoguePistolBurstShotsRemaining = 0;
			SetLootNotification(playerNumber, "SILENCED BURST ENDED - OUT OF BULLETS", 0);
			return;
		}
		pawn.TakeInventory('Clip', 1);
		pawn.A_StartSound("tuin/rogue/silenced", CHAN_WEAPON, CHANF_OVERLAP, 0.82, ATTN_NONE);
		let pistol = Weapon(pawn.FindInventory('TuinRogueSilencedPistol'));
		if (pistol) pawn.player.SetPsprite(PSP_WEAPON, pistol.FindState('BurstShot'));
		pawn.A_SpawnParticle(Color(255, 205, 92), SPF_FULLBRIGHT | SPF_FACECAMERA, 8, 2.5, 0,
			cos(pawn.Angle) * 25.0, sin(pawn.Angle) * 25.0, pawn.Height * 0.72,
			cos(pawn.Angle) * 0.8, sin(pawn.Angle) * 0.8, 0.1, 0, 0, 0, 0.05);
		double bulletPitch = pawn.AimLineAttack(pawn.Angle, 8192.0);
		ApplyingRoguePistolBurst = true;
		RoguePistolBurstPlayer = playerNumber;
		pawn.LineAttack(pawn.Angle, 8192.0, bulletPitch, 10, 'TuinRogueSilenced',
			'TuinRogueSilencedPuff');
		ApplyingRoguePistolBurst = false;
		data.RoguePistolBurstShotsRemaining--;
	}

	void RestoreRoguePistolBurstWeapon(Actor pawn, TuinPlayerData data)
	{
		if (!data) return;
		if (data.RoguePistolBurstWeaponShown && pawn && pawn.player &&
			pawn.player.ReadyWeapon is 'TuinRogueKnife')
		{
			let knife = Weapon(pawn.FindInventory('TuinRogueKnife'));
			if (knife)
			{
				pawn.player.SetPsprite(PSP_WEAPON, knife.FindState('ReadyLoop'));
				let weaponSprite = pawn.player.FindPSprite(PSP_WEAPON);
				if (weaponSprite)
				{
					weaponSprite.x = 0;
					weaponSprite.y = WEAPONTOP;
					weaponSprite.ResetInterpolation();
				}
			}
		}
		data.RoguePistolBurstWeaponShown = false;
		data.RoguePistolBurstHolding = false;
		data.RoguePistolBurstShotsRemaining = 0;
		data.RoguePistolBurstTics = 0;
	}

	void BeginRoguePistolBurstHold(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || data.PlayerClass != 5 || pawn.Health <= 0) return;
		if (!(pawn.player.ReadyWeapon is 'TuinRogueKnife'))
		{
			SetLootNotification(playerNumber, "EQUIP ROGUE KNIFE TO USE SILENCED BURST", 0);
			return;
		}
		if (data.RoguePistolBurstWeaponShown || data.RoguePistolBurstShotsRemaining > 0)
		{
			SetLootNotification(playerNumber, "SILENCED BURST ALREADY FIRING", 0);
			return;
		}
		if (data.RoguePistolBurstCooldownTics > 0)
		{
			SetLootNotification(playerNumber, String.Format("SILENCED BURST COOLDOWN: %.1f SEC",
				data.RoguePistolBurstCooldownTics / 35.0), 0);
			return;
		}
		let bullets = Ammo(pawn.FindInventory('Clip'));
		if (!bullets || bullets.Amount < 3)
		{
			SetLootNotification(playerNumber, "SILENCED BURST NEEDS 3 BULLETS", 0);
			pawn.A_StartSound("weapons/noammo", CHAN_ITEM, CHANF_MAYBE_LOCAL, 0.65, ATTN_NONE);
			return;
		}
		let pistol = Weapon(pawn.FindInventory('TuinRogueSilencedPistol'));
		if (!pistol)
		{
			SetLootNotification(playerNumber, "SILENCED PISTOL NOT AVAILABLE", 0);
			return;
		}
		data.RoguePistolBurstShotsRemaining = 0;
		data.RoguePistolBurstTics = 0;
		data.RoguePistolBurstWeaponShown = true;
		data.RoguePistolBurstHolding = true;
		// Hold this static pistol pose until the key-up event starts the burst.
		pawn.player.SetPsprite(PSP_WEAPON, pistol.FindState('BurstHold'));
		let weaponSprite = pawn.player.FindPSprite(PSP_WEAPON);
		if (weaponSprite)
		{
			weaponSprite.x = 0;
			weaponSprite.y = WEAPONTOP;
			weaponSprite.ResetInterpolation();
		}
		SetLootNotification(playerNumber, "SILENCED PISTOL READY - RELEASE C TO BURST", 4);
	}

	void ReleaseRoguePistolBurst(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || !data.RoguePistolBurstHolding ||
			!data.RoguePistolBurstWeaponShown) return;
		data.RoguePistolBurstHolding = false;
		data.RoguePistolBurstCooldownTics = 350;
		data.RoguePistolBurstShotsRemaining = 3;
		data.RoguePistolBurstTics = 0;
		data.LevelAbilityUses++;
		let pistol = Weapon(pawn.FindInventory('TuinRogueSilencedPistol'));
		if (pistol) pawn.player.SetPsprite(PSP_WEAPON, pistol.FindState('BurstOverlay'));
		SetLootNotification(pawn.PlayerNumber(), "SILENCED BURST - THREE SHOTS", 5);
	}

	void ActivateRoguePistolBurst(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		BeginRoguePistolBurstHold(playerNumber, pawn, data);
		ReleaseRoguePistolBurst(pawn, data);
	}

	void UpdateRoguePistolBurst(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!data) return;
		if (data.RoguePistolBurstCooldownTics > 0)
		{
			data.RoguePistolBurstCooldownTics--;
			if (data.RoguePistolBurstCooldownTics == 0 && data.PlayerClass == 5)
				SetLootNotification(playerNumber, "SILENCED BURST READY - PRESS C", 4);
		}
		if (!pawn || data.PlayerClass != 5 || pawn.Health <= 0)
		{
			RestoreRoguePistolBurstWeapon(pawn, data);
			return;
		}
		if (data.RoguePistolBurstShotsRemaining <= 0)
		{
			if (data.RoguePistolBurstHolding) return;
			if (!data.RoguePistolBurstWeaponShown) return;
			if (data.RoguePistolBurstTics > 0) data.RoguePistolBurstTics--;
			if (data.RoguePistolBurstTics <= 0) RestoreRoguePistolBurstWeapon(pawn, data);
			return;
		}
		if (data.RoguePistolBurstTics > 0) data.RoguePistolBurstTics--;
		if (data.RoguePistolBurstTics > 0) return;
		FireRoguePistolBurstShot(playerNumber, pawn, data);
		// Four tics between shots keeps it snappy while allowing each pistol
		// recoil/muzzle animation to be seen instead of collapsing into one flash.
		data.RoguePistolBurstTics = data.RoguePistolBurstShotsRemaining > 0 ? 4 : 5;
	}

	void UpdateRogueChain(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!data || !data.RogueChainActive) return;
		if (RogueChainTestActive[playerNumber] && RogueChainTestHits[playerNumber] < 0)
		{
			if (pawn) pawn.A_Log("ROGUE CHAIN UPDATE ENTERED.");
			RogueChainTestHits[playerNumber] = 0;
		}
		if (!pawn || pawn.Health <= 0 || data.PlayerClass != 5)
		{
			FinishRogueChain(playerNumber, data,
				data.RogueChainHitsRemaining < data.RogueChainStartCount);
			return;
		}
		if (--data.RogueChainTics > 0) return;
		if (data.RogueChainVisitedCount >= 32)
		{
			FinishRogueChain(playerNumber, data,
				data.RogueChainHitsRemaining < data.RogueChainStartCount);
			return;
		}
		Actor target = FindRogueChainTarget(pawn, data);
		if (!target)
		{
			FinishRogueChain(playerNumber, data,
				data.RogueChainHitsRemaining < data.RogueChainStartCount);
			return;
		}
		data.RogueChainVisited[data.RogueChainVisitedCount++] = target;
		if (!PlaceRogueBesideTarget(pawn, target))
		{
			data.RogueChainTics = 1;
			return;
		}
		pawn.A_StartSound("tuin/rogue/knifehit", CHAN_WEAPON, CHANF_MAYBE_LOCAL, 0.95, ATTN_NORM);
		ApplyingRogueChainStrike = true;
		RogueChainStrikePlayer = playerNumber;
		target.DamageMobj(pawn, pawn, Random[TuinRogueChain](28, 42), 'TuinRogueKnife');
		ApplyingRogueChainStrike = false;
		RogueChainStrikePlayer = -1;
		if (RogueChainTestActive[playerNumber]) RogueChainTestHits[playerNumber]++;
		data.RogueChainHitsRemaining--;
		if (data.RogueChainHitsRemaining <= 0)
			FinishRogueChain(playerNumber, data, true);
		else data.RogueChainTics = 4;
	}

	void ActivateTankOverdrive(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.PlayerClass != 1 || data.TankOverdriveActive || data.TankOverdriveCharge < 100) return;
		data.TankOverdriveActive = true;
		data.TankOverdriveTics = TankOverdriveDuration();
		data.TankOverdriveCharge = 100;
		data.TankReadyNotified = true;
		data.TankOverdriveChargeRemainder = 0.0;
		data.LevelAbilityUses++;
		pawn.A_RemoveLight('TuinTankOverdriveGlow');
		pawn.GiveInventory('TuinTankOverdriveFiringSpeed', 1);
		pawn.A_AttachLight('TuinTankOverdriveGlow', DynamicLight.PulseLight, Color(255, 24, 8), 62, 128,
			DynamicLight.LF_ATTENUATE, (0, 0, pawn.Height * 0.52), 0.45);
		SetLootNotification(playerNumber, "HEAVY OVERDRIVE - 10 SECONDS", 5);
	}

	void ApplyHeavyMovement(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		if (data.PlayerClass == 1)
		{
			if (!pawn.FindInventory('TuinHeavyMovementPenalty'))
				pawn.GiveInventory('TuinHeavyMovementPenalty', 1);
		}
		else pawn.TakeInventory('TuinHeavyMovementPenalty', 0x7FFFFFFF);
	}

	void RestoreHeavyRadioWeapon(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		if (pawn.player && data.HeavyRadioWeaponHidden)
		{
			pawn.player.SetPsprite(PSP_FLASH, null);
			if (pawn.Health > 0 && pawn.player.ReadyWeapon)
			{
				pawn.player.SetPsprite(PSP_WEAPON, pawn.player.ReadyWeapon.GetUpState());
				let weaponSprite = pawn.player.FindPSprite(PSP_WEAPON);
				if (weaponSprite)
				{
					weaponSprite.y = WEAPONBOTTOM;
					weaponSprite.alpha = 1.0;
					weaponSprite.ResetInterpolation();
				}
			}
			else pawn.player.SetPsprite(PSP_WEAPON, null);
		}
		data.HeavyRadioWeaponHidden = false;
	}

	class<Actor> HeavyMarineClass(int color)
	{
		switch (color)
		{
		case 0: return 'TuinHeavySupportMarineGray';
		case 1: return 'TuinHeavySupportMarineBrown';
		case 2: return 'TuinHeavySupportMarineRed';
		case 3: return 'TuinHeavySupportMarineBlue';
		default: return 'TuinHeavySupportMarineBlue';
		}
	}

	void SpawnHeavySupport(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || data.HeavyRadioMarinesDeployed) return;
		data.HeavyRadioMarinesDeployed = true;
		int marineCount = Random[TuinHeavyMarineCount](2, 3);
		for (int i = 0; i < marineCount; i++)
		{
			double spawnAngle = pawn.Angle + (i - (marineCount - 1) * 0.5) * 42.0;
			Vector3 spawnPos = pawn.Pos + (cos(spawnAngle) * 48.0, sin(spawnAngle) * 48.0, 0);
			let marine = TuinHeavySupportMarine(Actor.Spawn(HeavyMarineClass(
				Random[TuinHeavyMarineColor](0, 3)), spawnPos, ALLOW_REPLACE));
			if (!marine) continue;
			if (!marine.TestMobjLocation()) marine.SetOrigin(pawn.Pos, false);
			marine.master = pawn;
			marine.SetFriendPlayer(pawn.player);
			Actor.Spawn('TeleportFog', marine.Pos, ALLOW_REPLACE);
		}
		SetLootNotification(playerNumber, String.Format("RADIO SUPPORT ARRIVED - %d MARINES / 30 SEC", marineCount), 4);
	}

	void ActivateHeavyRadio(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || data.PlayerClass != 1 || pawn.Health <= 0) return;
		if (data.HeavyRadioCallTics > 0)
		{
			SetLootNotification(playerNumber, "RADIO SUPPORT CALL IN PROGRESS", 0);
			return;
		}
		if (data.HeavyRadioCooldownTics > 0)
		{
			SetLootNotification(playerNumber, String.Format("RADIO RECHARGE: %d DAMAGE",
				data.HeavyRadioCooldownTics), 0);
			return;
		}
		data.HeavyRadioCooldownTics = HeavyRadioCooldown(data);
		data.HeavyRadioCallTics = 196;
		data.HeavyRadioMarinesDeployed = false;
		data.HeavyRadioWeaponHidden = true;
		data.HeavyRadioOwner = pawn;
		data.LevelAbilityUses++;
		pawn.player.SetPsprite(PSP_FLASH, null);
		let radio = GetDefaultByType('TuinHeavyRadioOverlay');
		pawn.player.SetPsprite(PSP_WEAPON, radio.FindState('Call'));
		let radioSprite = pawn.player.FindPSprite(PSP_WEAPON);
		if (radioSprite)
		{
			radioSprite.x = 0;
			radioSprite.y = WEAPONTOP;
			radioSprite.ResetInterpolation();
		}
		pawn.A_StartSound("tuin/heavy/radio_start", CHAN_VOICE, 0, 0.90);
		SetLootNotification(playerNumber, "CALLING RADIO SUPPORT...", 4);
	}

	void UpdateHeavyRadio(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		if (data.HeavyRadioCallTics <= 0) return;
		if (data.HeavyRadioOwner != pawn || data.PlayerClass != 1 || pawn.Health <= 0)
		{
			if (data.HeavyRadioOwner) RestoreHeavyRadioWeapon(data.HeavyRadioOwner, data);
			data.HeavyRadioOwner = pawn;
			data.HeavyRadioCallTics = 0;
			data.HeavyRadioMarinesDeployed = false;
			return;
		}
		data.HeavyRadioCallTics--;
		if (data.HeavyRadioCallTics == 185)
			pawn.A_StartSound("tuin/heavy/radio_voice", CHAN_VOICE, 0, 0.90);
		else if (data.HeavyRadioCallTics == 128)
			pawn.A_StartSound("tuin/heavy/radio_request", CHAN_VOICE, 0, 0.90);
		else if (data.HeavyRadioCallTics == 95)
			pawn.A_StartSound("tuin/heavy/radio_silence", CHAN_VOICE, 0, 0.75);
		else if (data.HeavyRadioCallTics == 66)
			pawn.A_StartSound("tuin/heavy/radio_confirm", CHAN_VOICE, 0, 0.90);
		else if (data.HeavyRadioCallTics == 22)
			SpawnHeavySupport(playerNumber, pawn, data);
		else if (data.HeavyRadioCallTics == 4)
			pawn.A_StartSound("tuin/heavy/radio_stop", CHAN_VOICE, 0, 0.75);
		if (data.HeavyRadioCallTics <= 0)
		{
			RestoreHeavyRadioWeapon(pawn, data);
			data.HeavyRadioOwner = pawn;
		}
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

	int DoomFatalityMaximumHealth(Actor target)
	{
		if (!target) return 1;
		let monsterData = GetMonsterData(target);
		if (monsterData && monsterData.ScaledMaxHealth > 0) return monsterData.ScaledMaxHealth;
		return max(1, target.SpawnHealth());
	}

	bool CanDoomFatality(Actor pawn, Actor target)
	{
		if (!pawn || !IsValidMonster(target) || target.Health <= 0 ||
			pawn.Distance3D(target) > 224.0 ||
			abs(Actor.deltaangle(pawn.Angle, pawn.AngleTo(target, true))) > 48.0 ||
			!pawn.CheckSight(target, SF_IGNOREWATERBOUNDARY)) return false;
		let monsterData = GetMonsterData(target);
		return monsterData && monsterData.DoomFatalityReservedBy == pawn &&
			target.Health * 100 <= DoomFatalityMaximumHealth(target) * 10;
	}

	Actor FindDoomFatalityTarget(Actor pawn)
	{
		if (!pawn) return null;
		Actor bestTarget;
		double bestScore = 1000000.0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor candidate;
		while (candidate = Actor(iterator.Next()))
		{
			if (!CanDoomFatality(pawn, candidate)) continue;
			double distance = pawn.Distance3D(candidate);
			double angleDifference = abs(Actor.deltaangle(pawn.Angle,
				pawn.AngleTo(candidate, true)));
			double score = distance + angleDifference * 2.5;
			if (score >= bestScore) continue;
			bestTarget = candidate;
			bestScore = score;
		}
		return bestTarget;
	}

	bool CanMarkDoomFatality(Actor pawn, Actor target)
	{
		if (!pawn || !IsValidMonster(target) || target.Health <= 0 ||
			pawn.Distance3D(target) > 2048.0 ||
			abs(Actor.deltaangle(pawn.Angle, pawn.AngleTo(target, true))) > 72.0) return false;
		let monsterData = GetMonsterData(target);
		return monsterData && !monsterData.DoomFatalityExpired &&
			(!monsterData.DoomFatalityReservedBy || monsterData.DoomFatalityReservedBy == pawn) &&
			target.Health * 100 <= DoomFatalityMaximumHealth(target) * 10;
	}

	bool CanMaintainDoomFatalityReservation(Actor pawn, Actor target)
	{
		if (!pawn || !IsValidMonster(target) || target.Health <= 0 ||
			pawn.Distance3D(target) > 2048.0) return false;
		let monsterData = GetMonsterData(target);
		return monsterData && monsterData.DoomFatalityReservedBy == pawn &&
			monsterData.DoomFatalityWindowTics > 0;
	}

	Actor FindDoomFatalityMarkerTarget(Actor pawn)
	{
		if (!pawn) return null;
		Actor bestTarget;
		double bestScore = 1000000.0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor candidate;
		while (candidate = Actor(iterator.Next()))
		{
			if (!CanMarkDoomFatality(pawn, candidate)) continue;
			double distance = pawn.Distance3D(candidate);
			double angleDifference = abs(Actor.deltaangle(pawn.Angle,
				pawn.AngleTo(candidate, true)));
			// Prefer what Doom Guy is looking at, then the nearer weakened enemy.
			double score = angleDifference * 18.0 + distance +
				(pawn.CheckSight(candidate, SF_IGNOREWATERBOUNDARY) ? 0.0 : 10000.0);
			if (score >= bestScore) continue;
			bestTarget = candidate;
			bestScore = score;
		}
		return bestTarget;
	}

	void ClearDoomFatalityMarker(TuinPlayerData data, Actor reservationOwner = null)
	{
		if (!data) return;
		if (data.DoomFatalityMarkerTarget)
		{
			let monsterData = GetMonsterData(data.DoomFatalityMarkerTarget);
			if (monsterData && monsterData.DoomFatalityReservedBy &&
				(!reservationOwner || monsterData.DoomFatalityReservedBy == reservationOwner))
				monsterData.EndDoomFatalityReservation(false);
		}
		if (data.DoomFatalityMarker) data.DoomFatalityMarker.Destroy();
		data.DoomFatalityMarker = null;
		data.DoomFatalityMarkerTarget = null;
	}

	void UpdateDoomFatalityMarker(int playerNumber, TuinPlayerData data, Actor candidate)
	{
		if (!data) return;
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS &&
			playerInGame[playerNumber] ? players[playerNumber].mo : null;
		if (data.DoomFatalityMarkerTarget != candidate)
		{
			ClearDoomFatalityMarker(data, pawn);
			data.DoomFatalityMarkerTarget = candidate;
		}
		if (!candidate || candidate.Health <= 0)
		{
			ClearDoomFatalityMarker(data, pawn);
			return;
		}
		let monsterData = GetMonsterData(candidate);
		if (monsterData && !monsterData.DoomFatalityReservedBy)
			monsterData.BeginDoomFatalityReservation(pawn);
		if (!monsterData || monsterData.DoomFatalityReservedBy != pawn) return;
		if (!data.DoomFatalityMarker)
			data.DoomFatalityMarker = Actor.Spawn('TuinDoomFatalitySkullMarker',
				candidate.Pos + (0, 0, candidate.Height + 24), NO_REPLACE);
		Actor marker = data.DoomFatalityMarker;
		if (!marker) return;
		double pulse = (sin((level.Time + playerNumber * 11) * 12.0) + 1.0) * 0.5;
		double bob = 24.0 + sin((level.Time + playerNumber * 7) * 8.0) * 4.0;
		marker.SetOrigin(candidate.Pos + (0, 0, candidate.Height + bob), false);
		marker.Scale = (0.033 + pulse * 0.007, 0.033 + pulse * 0.007);
		marker.Alpha = 0.82 + pulse * 0.16;
		if ((level.Time + playerNumber * 3) % 6 == 0)
		{
			double emberAngle = FRandom[TuinRPGCritical](0.0, 360.0);
			marker.A_SpawnParticle(Color(255, 34, 8),
				SPF_FULLBRIGHT | SPF_FACECAMERA, 12, 3.2, 0,
				cos(emberAngle) * 18.0, sin(emberAngle) * 18.0, 12.0,
				-cos(emberAngle) * 0.7, -sin(emberAngle) * 0.7, 0.8,
				0, 0, -0.03, 0.9, 0.07, -0.12);
		}
	}

	void SpawnDoomFatalityImpact(Actor target)
	{
		if (!target) return;
		for (int i = 0; i < 34; i++)
		{
			double particleAngle = FRandom[TuinRPGCritical](0.0, 360.0);
			double speed = FRandom[TuinRPGCritical](2.5, 9.0);
			Color particleColor = (i % 5) == 0 ? Color(22, 4, 3) :
				((i & 1) ? Color(210, 12, 6) : Color(118, 0, 0));
			target.A_SpawnParticle(particleColor, SPF_FULLBRIGHT | SPF_FACECAMERA,
				18, FRandom[TuinRPGCritical](3.5, 8.0), 0,
				FRandom[TuinRPGCritical](-10.0, 10.0),
				FRandom[TuinRPGCritical](-10.0, 10.0),
				FRandom[TuinRPGCritical](target.Height * 0.20, target.Height * 0.85),
				cos(particleAngle) * speed, sin(particleAngle) * speed,
				FRandom[TuinRPGCritical](0.5, 5.5), 0, 0, -0.18,
				1.0, 0.07, -0.13);
		}
		target.A_QuakeEx(6, 6, 5, 18, 0, 720, "", QF_SCALEDOWN);
	}

	void FinishDoomFatality(Actor pawn, TuinPlayerData data)
	{
		if (!data) return;
		Actor owner = data.DoomFatalityOwner ? data.DoomFatalityOwner : pawn;
		if (data.DoomFatalityTarget && !data.DoomFatalityImpactDone &&
			data.DoomFatalityTarget.Health > 0)
			data.DoomFatalityTarget.reactiontime = data.DoomFatalityTargetReactionTime;
		if (owner && owner.player)
		{
			if (!data.DoomFatalityWasFrozen) owner.player.cheats &= ~CF_TOTALLYFROZEN;
			if (data.DoomFatalityWeaponHidden && owner.Health > 0 && owner.player.ReadyWeapon)
			{
				owner.player.SetPsprite(PSP_WEAPON, owner.player.ReadyWeapon.GetUpState());
				let weaponSprite = owner.player.FindPSprite(PSP_WEAPON);
				if (weaponSprite)
				{
					weaponSprite.y = WEAPONBOTTOM;
					weaponSprite.alpha = 1.0;
					weaponSprite.ResetInterpolation();
				}
			}
			owner.player.SetPsprite(PSP_FLASH, null);
		}
		ClearDoomFatalityMarker(data, owner);
		data.DoomFatalityOwner = null;
		data.DoomFatalityTarget = null;
		data.DoomFatalityCandidate = null;
		data.DoomFatalityMarkerTarget = null;
		data.DoomFatalityTics = 0;
		data.DoomFatalityImpactDone = false;
		data.DoomFatalityWasFrozen = false;
		data.DoomFatalityWeaponHidden = false;
		data.DoomFatalityTargetReactionTime = 0;
	}

	void ExecuteDoomFatalityImpact(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || data.DoomFatalityImpactDone) return;
		Actor target = data.DoomFatalityTarget;
		if (!target || target.Health <= 0)
		{
			FinishDoomFatality(pawn, data);
			return;
		}
		data.DoomFatalityImpactDone = true;
		SpawnDoomFatalityImpact(target);
		pawn.A_StartSound("*fist", CHAN_WEAPON, 0, 1.0);
		target.A_StartSound("misc/gibbed", CHAN_BODY, 0, 0.95);
		int fatalDamage = max(1000, target.Health + DoomFatalityMaximumHealth(target) * 3);
		ApplyingBonusDamage = true;
		target.DamageMobj(pawn, pawn, fatalDamage, 'TuinDoomFatality', DMG_FORCED);
		ApplyingBonusDamage = false;
		if (target.Health <= 0) data.DoomFatalityCooldownTics = 180 * 35;
		int healing = max(8, int(pawn.GetMaxHealth(true) * 0.10 + 0.5));
		pawn.A_SetHealth(min(pawn.GetMaxHealth(true), pawn.Health + healing));
	}

	bool BeginDoomFatality(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || data.PlayerClass != 4 ||
			data.DoomFatalityCooldownTics > 0 || data.DoomFatalityTics > 0 || data.DoomBloodPunchHolding ||
			data.DoomBloodPunchPrepareTics > 0 || data.DoomBloodPunchAttackTics > 0) return false;
		Actor target = data.DoomFatalityMarkerTarget;
		if (!target || !CanDoomFatality(pawn, target)) return false;
		data.DoomFatalityOwner = pawn;
		data.DoomFatalityTarget = target;
		data.DoomFatalityCandidate = target;
		data.DoomFatalityTics = 42;
		data.DoomFatalityImpactDone = false;
		data.DoomFatalityWasFrozen = (pawn.player.cheats & CF_TOTALLYFROZEN) != 0;
		data.DoomFatalityWeaponHidden = true;
		data.DoomFatalityTargetReactionTime = target.reactiontime;
		target.reactiontime = max(target.reactiontime, 48);
		target.Vel = (0, 0, 0);
		let painState = target.FindState('Pain');
		if (painState) target.SetState(painState);
		pawn.player.cheats |= CF_TOTALLYFROZEN;
		pawn.player.SetPsprite(PSP_WEAPON, null);
		pawn.player.SetPsprite(PSP_FLASH, null);
		data.LevelAbilityUses++;
		return true;
	}

	void ApplyDoomFatality(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!data) return;
		if (data.DoomFatalityCooldownTics > 0) data.DoomFatalityCooldownTics--;
		if (data.DoomFatalityTics <= 0)
		{
			if (data.DoomFatalityCooldownTics > 0 || data.PlayerClass != 4 ||
				!pawn || pawn.Health <= 0)
			{
				data.DoomFatalityCandidate = null;
				UpdateDoomFatalityMarker(playerNumber, data, null);
				return;
			}
			Actor markerTarget = CanMaintainDoomFatalityReservation(pawn,
				data.DoomFatalityMarkerTarget) ? data.DoomFatalityMarkerTarget :
				FindDoomFatalityMarkerTarget(pawn);
			UpdateDoomFatalityMarker(playerNumber, data, markerTarget);
			data.DoomFatalityCandidate = markerTarget && CanDoomFatality(pawn, markerTarget) ?
				markerTarget : null;
			return;
		}
		if (!pawn || pawn.Health <= 0 || data.PlayerClass != 4 ||
			data.DoomFatalityOwner != pawn)
		{
			FinishDoomFatality(pawn, data);
			return;
		}
		Actor target = data.DoomFatalityTarget;
		if (!target || (!data.DoomFatalityImpactDone && target.Health <= 0))
		{
			FinishDoomFatality(pawn, data);
			return;
		}
		UpdateDoomFatalityMarker(playerNumber, data,
			data.DoomFatalityImpactDone ? null : target);
		pawn.Vel = (0, 0, 0);
		if (!data.DoomFatalityImpactDone)
		{
			target.Vel = (0, 0, 0);
			target.reactiontime = max(target.reactiontime, 12);
			pawn.Angle = pawn.AngleTo(target, true);
			if (data.DoomFatalityTics >= 27)
			{
				double approachAngle = target.AngleTo(pawn, true);
				double approachDistance = max(34.0, pawn.Radius + target.Radius + 5.0);
				Vector3 oldPosition = pawn.Pos;
				Vector3 destination =
					(oldPosition.X * 0.55 + (target.Pos.X + cos(approachAngle) * approachDistance) * 0.45,
					 oldPosition.Y * 0.55 + (target.Pos.Y + sin(approachAngle) * approachDistance) * 0.45,
					 oldPosition.Z);
				pawn.SetOrigin(destination, false);
				if (!pawn.TestMobjLocation()) pawn.SetOrigin(oldPosition, false);
			}
		}
		if (data.DoomFatalityTics == 29)
			ShowDoomBloodPunchReadyFists(pawn);
		if (data.DoomFatalityTics == 21)
		{
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
		if (data.DoomFatalityTics == 17)
			ExecuteDoomFatalityImpact(playerNumber, pawn, data);
		data.DoomFatalityTics--;
		if (data.DoomFatalityTics <= 0) FinishDoomFatality(pawn, data);
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
		data.LevelAbilityUses++;
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
		if (!ClassesEnabled()) return;
		let data = EnsurePlayerData(playerNumber);
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!data || !pawn || chosenClass < 1 || chosenClass > 6) return;
		if (data.PlayerClass != 0)
		{
			pawn.A_Log(String.Format("Your class is permanently set to %s.", PlayerClassName(data.PlayerClass)));
			SetLootNotification(playerNumber, String.Format("CLASS ALREADY CHOSEN: %s", PlayerClassName(data.PlayerClass)), 0);
			return;
		}
		data.PlayerClass = chosenClass;
		data.FreeClassChoiceRefunded = true;
		if (chosenClass == 5)
		{
			data.RogueChargeInitialized = true;
			data.RogueVeilCharge = 100;
			data.RoguePistolBurstCooldownTics = 0;
			data.RoguePistolBurstTics = 0;
			data.RoguePistolBurstShotsRemaining = 0;
			data.RoguePistolBurstWeaponShown = false;
			data.RoguePistolBurstHolding = false;
			pawn.TakeInventory('Fist', 0x7FFFFFFF);
			pawn.TakeInventory('PerkFist', 0x7FFFFFFF);
			pawn.TakeInventory('Pistol', 0x7FFFFFFF);
			pawn.TakeInventory('PerkPistol', 0x7FFFFFFF);
			pawn.GiveInventory('TuinRogueKnife', 1);
			pawn.GiveInventory('TuinRogueSilencedPistol', 1);
			pawn.GiveInventory('TuinRogueBow', 1);
			if (pawn.player)
				pawn.player.PendingWeapon = Weapon(pawn.FindInventory('TuinRogueSilencedPistol'));
			EnsureRogueCatchupChoice(playerNumber);
		}
		else if (chosenClass == 1)
		{
			data.TankChargeInitialized = true;
			data.TankOverdriveCharge = 0;
			data.TankOverdriveActive = false;
			data.TankOverdriveTics = 0;
			data.TankReadyNotified = false;
			data.HeavyRadioCooldownTics = 0;
			data.HeavyRadioCallTics = 0;
			pawn.GiveInventory('TuinMinigun', 1);
			pawn.GiveInventory('Clip', 100);
			if (pawn.player) pawn.player.PendingWeapon = Weapon(pawn.FindInventory('TuinMinigun'));
		}
		else if (chosenClass == 3)
		{
			data.ExecutionerCharge = 0;
			data.ExecutionerChargeRemainder = 0.0;
			data.ExecutionerReadyNotified = false;
			data.ExecutionerMarkedTarget = null;
			data.ExecutionerMarkVisual = null;
			data.ExecutionerMarkTics = 0;
			for (int i = 0; i < 2; i++)
			{
				data.ExecutionerExtraMarkedTarget[i] = null;
				data.ExecutionerExtraMarkVisual[i] = null;
				data.ExecutionerExtraMarkTics[i] = 0;
			}
			data.ExecutionerRefundGranted = false;
			data.ExecutionerJudgmentArmed = false;
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
			pawn.GiveInventory('TuinDoomGuyQuadShotgun', 1);
			pawn.GiveInventory('TuinDoomGuyQuadLoaded', 4);
			data.DoomQuadInitialized = true;
			if (pawn.player)
				pawn.player.PendingWeapon = Weapon(pawn.FindInventory('TuinDoomGuyQuadShotgun'));
		}
		else if (chosenClass == 6)
		{
			data.EngineerSentriesInitialized = false;
			InitializeEngineerSentries(data);
		}
		data.ClassHealClock = 0;
		data.ClassAmmoCount = 0;
		ApplyClassHealth(pawn, data);
		string className = PlayerClassName(chosenClass);
		pawn.A_Log(String.Format("CLASS CHOSEN: %s. This choice is permanent.", className));
		SetLootNotification(playerNumber, String.Format("CLASS CHOSEN: %s", className), 4);
		EventHandler.SendInterfaceEvent(playerNumber, "tuin_open_perk_hub");
	}

	void BuyPerk(int playerNumber, int perk)
	{
		let data = EnsurePlayerData(playerNumber);
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!data || !pawn) return;
		if (ClassesEnabled() && data.PlayerClass == 0)
		{
			SetLootNotification(playerNumber, "CHOOSE A CLASS BEFORE BUYING PERKS", 0);
			return;
		}
		if (!ClassesEnabled() && (perk == 6 || perk == 7))
		{
			SetLootNotification(playerNumber, "ONLY UNIVERSAL PERKS ARE AVAILABLE", 0);
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
		case 8:
			if (data.PlayerLevel < 20)
			{
				SetLootNotification(playerNumber, "GIANT SLAYER REQUIRES LEVEL 20", 0);
				return;
			}
			rank = data.PerkGiantSlayer;
			break;
		case 9: rank = data.PerkArmorPenetration; break;
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
		else if (perk == 8) data.PerkGiantSlayer++;
		else if (perk == 9) data.PerkArmorPenetration++;
		data.UnspentSkillPoints--;
		ApplyPerkHealth(pawn, data);
		ApplyClassHealth(pawn, data);
		SetLootNotification(playerNumber, String.Format("PERK UPGRADED TO RANK %d", rank + 1), 3);
	}

	void BuyWeaponPerk(int playerNumber, int family)
	{
		let data = EnsurePlayerData(playerNumber);
		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!data || !pawn || ClassesEnabled() || family < 1 || family > 10) return;
		if (family >= 9 && !TuinRustSupport.Available(family))
		{
			SetLootNotification(playerNumber, "LEGACY OF RUST RESOURCES REQUIRED", 0);
			return;
		}
		if (HasWeaponPerk(data, family))
		{
			SetLootNotification(playerNumber, "WEAPON PERK ALREADY CHOSEN", 0);
			return;
		}
		if (data.UnspentWeaponPerkPoints <= 0)
		{
			SetLootNotification(playerNumber, "NO WEAPON PERK POINTS AVAILABLE", 0);
			return;
		}
		data.WeaponPerkFlags |= 1 << (family - 1);
		data.UnspentWeaponPerkPoints--;
		data.ClassAmmoCount = 0;
		SetLootNotification(playerNumber, String.Format("WEAPON PERK: %s", WeaponPerkName(family)), 5);
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
        if(TuinRun.Active())return 1+TuinRun.Stage()*2;
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

	bool AmmoFeedsWeaponFamily(Actor pawn, class<Ammo> ammoType, int family)
	{
		if (!pawn || !ammoType) return false;
		for (Inventory item = pawn.Inv; item; item = item.Inv)
		{
			let weapon = Weapon(item);
			if (weapon && WeaponFamily(weapon) == family &&
				(weapon.AmmoType1 == ammoType || weapon.AmmoType2 == ammoType)) return true;
		}
		return false;
	}

	void ApplyWeaponPerkAmmoUse(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || ClassesEnabled() || !HasWeaponPerk(data, 5)) return;
		Weapon weapon = pawn.player.ReadyWeapon;
		if (!weapon || WeaponFamily(weapon) != 5 || !weapon.AmmoType1)
		{
			WeaponPerkTrackedAmmo[playerNumber] = null;
			WeaponPerkTrackedAmmoAmount[playerNumber] = 0;
			return;
		}
		let ammo = Ammo(pawn.FindInventory(weapon.AmmoType1));
		if (!ammo) return;
		class<Ammo> ammoType = (class<Ammo>)(ammo.GetClass());
		if (WeaponPerkTrackedAmmo[playerNumber] != ammoType)
		{
			WeaponPerkTrackedAmmo[playerNumber] = ammoType;
			WeaponPerkTrackedAmmoAmount[playerNumber] = ammo.Amount;
			return;
		}
		int spent = max(0, WeaponPerkTrackedAmmoAmount[playerNumber] - ammo.Amount);
		if (spent > 0) ammo.Amount = max(0, ammo.Amount - spent * 2);
		WeaponPerkTrackedAmmoAmount[playerNumber] = ammo.Amount;
	}

	void ApplyAmmoCapacity(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		int progressLevel = max(data.PlayerLevel, ProgressiveBaseLevel());
		double multiplier = CVInt('tuin_ammo_scaling_enabled', 1) ?
			AmmoProgressMultiplier(progressLevel, 'tuin_ammo_capacity_per_level',
				'tuin_ammo_capacity_max_multiplier', 2.0, 2.0) : 1.0;
		bool hasBackpack = pawn.FindInventory('BackpackItem') != null;
		for (Inventory item = pawn.Inv; item; item = item.Inv)
		{
			let ammo = Ammo(item);
			if (!ammo) continue;
			readonly<Ammo> def = GetDefaultByType((class<Ammo>)(ammo.GetClass()));
			if (!def || def.MaxAmount <= 0) continue;
			int desiredMaximum = max(1, int(def.MaxAmount * multiplier + 0.5));
			if (hasBackpack) desiredMaximum *= 2;
			if (!ClassesEnabled() && HasWeaponPerk(data, 5) &&
				AmmoFeedsWeaponFamily(pawn, (class<Ammo>)(ammo.GetClass()), 5)) desiredMaximum *= 3;
			if (data.PlayerClass == 1 && ammo is 'Clip') desiredMaximum *= 3;
			if (data.PlayerClass == 5) desiredMaximum = max(1, int(desiredMaximum * 0.70 + 0.5));
			if (data.PlayerClass == 5)
			{
				ammo.MaxAmount = desiredMaximum;
				ammo.Amount = min(ammo.Amount, ammo.MaxAmount);
				continue;
			}
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
			return clamp(WhiteLevelFloor(randomLevel, rarity, playerLevel), minLevel, maxLevel);
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
		return clamp(WhiteLevelFloor(rolledLevel, rarity, playerLevel), minLevel, maxLevel);
	}
	clearscope static int WhiteLevelFloor(int rolled, int rarity, int playerLevel)
	{
		return !ClassesEnabled() && rarity == 0 && playerLevel >= 20 ? max(rolled, playerLevel - 3) : rolled;
	}
	clearscope static double WhiteCatchupBonus(int rarity, bool damage, int playerLevel)
	{
		if (ClassesEnabled() || rarity != 0 || playerLevel < 20) return 1.;
		return 1. + (damage ? .20 : .15) + min(10, playerLevel - 20) * .02;
	}
	clearscope static int CatchupPlayerLevel()
	{
		int highest=1;
		for(int i=0;i<TUIN_MAX_PLAYERS;i++)
		{
			if(!playerInGame[i] || !players[i].mo) continue;
			let data=GetPlayerData(players[i].mo);
			if(data) highest=max(highest,data.PlayerLevel);
		}
		return highest;
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
		if (quality == 6)
		{
			// Godly gear cycles through the full rarity spectrum anywhere its name
			// is drawn, including the arsenal, comparison panel and weapon wheel.
			switch ((gametic / 7) % 7)
			{
			case 0: return Font.CR_RED;
			case 1: return Font.CR_ORANGE;
			case 2: return Font.CR_GOLD;
			case 3: return Font.CR_GREEN;
			case 4: return Font.CR_CYAN;
			case 5: return Font.CR_ICE;
			default: return Font.CR_PURPLE;
			}
		}
		switch (quality)
		{
		case 1: return Font.CR_GREEN;
		case 2: return Font.CR_CYAN;
		case 3: return Font.CR_ORANGE;
		case 4: return Font.CR_GOLD;
		case 5: return Font.CR_PURPLE;
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

	clearscope static bool IsRogueOnlyWeaponType(class<Weapon> weaponType)
	{
		return weaponType == 'TuinRogueKnife' || weaponType == 'TuinRogueSilencedPistol' ||
			weaponType == 'TuinRogueBow';
	}

	clearscope static bool IsDoomGuyOnlyWeaponType(class<Weapon> weaponType)
	{
		return weaponType == 'TuinDoomGuyQuadShotgun';
	}

	clearscope static bool IsHeavyOnlyWeaponType(class<Weapon> weaponType)
	{
		return weaponType == (class<Weapon>)(FindClass('TuinMinigun', 'Weapon'));
	}

	class<Weapon> RandomRogueWeaponType()
	{
		int choice = Random[TuinRPGLoot](0, 2);
		if (choice == 0) return 'TuinRogueKnife';
		if (choice == 1) return 'TuinRogueSilencedPistol';
		return 'TuinRogueBow';
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
		else if (affixFlags & WEAPON_AFFIX_EXECUTION) adjective = ClassesEnabled() ? "Executioner's" : "Finishing";
		else if (affixFlags & WEAPON_AFFIX_PROSPERITY) adjective = "Prosperous";
		else if (affixFlags & WEAPON_AFFIX_CRITICAL) adjective = "Keen";
		int trait = !ClassesEnabled() ? TuinWeaponTraits.Nth(affixFlags, 0) : -1;
		if (trait >= 0) adjective = TuinWeaponTraits.NameOf(trait);
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

	clearscope static bool IsNativeRogueWeapon(Weapon weapon)
	{
		if (!weapon) return false;
		name weaponName = weapon.GetClassName();
		return weaponName == 'TuinRogueKnife' || weaponName == 'TuinRogueSilencedPistol' ||
			weaponName == 'TuinRogueBow';
	}

	clearscope static double TotalCriticalChance(TuinPlayerData data, int variantIndex = -1,
		Weapon activeWeapon = null)
	{
		if (!data) return 0.0;
		if (!activeWeapon && data.Owner && data.Owner.player) activeWeapon = data.Owner.player.ReadyWeapon;
		if (WeaponFamily(activeWeapon) == 8 && HasWeaponPerk(data, 8)) return 25.0;
		double chance = 2.0 + data.Luck * 0.5 + data.PerkKillerInstinct * 2.0 +
			RogueCriticalBonus(data, activeWeapon);
		if (variantIndex >= 0 && variantIndex < data.WeaponVariantCount)
			chance += WeaponCriticalPercent(data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex],
				data.VariantItemLevel[variantIndex]);
		double cap = variantIndex >= 0 && data.VariantQuality[variantIndex] == TUIN_LEAD_SPITTER_QUALITY ? 100.0 : 50.0;
		return clamp(chance, 0.0, cap);
	}

	clearscope static double RogueCriticalBonus(TuinPlayerData data, Weapon activeWeapon = null)
	{
		return data && data.PlayerClass == 5 && IsNativeRogueWeapon(activeWeapon) ?
			5.0 + data.PerkClassMastery * 5.0 : 0.0;
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

	clearscope static bool IsPlayerRocketDamage(Actor inflictor, Name damageType)
	{
		if (!inflictor || !inflictor.bMISSILE || IsGrenadeDamage(inflictor, damageType)) return false;
		if (inflictor is 'Rocket') return true;
		// ProjectSIDE's SmoothRocket is a standalone replacement rather than a
		// Rocket subclass, so also recognize rocket-named missile actors.
		string projectileName = String.Format("%s", inflictor.GetClassName()).MakeLower();
		return projectileName.IndexOf("rocket") >= 0;
	}

	clearscope static bool IsMinigunExplosiveDamage(Actor inflictor, Name damageType)
	{
		if (inflictor && inflictor.GetClassName() == 'TuinMinigunExplosiveRound') return true;
		return damageType == 'TuinMinigunExplosive';
	}

	clearscope static bool IsPlayerPlasmaDamage(Actor inflictor)
	{
		return inflictor && inflictor is 'PlasmaBall';
	}

	clearscope static bool RocketHitWasDirect(Actor projectile, Actor victim)
	{
		if (!projectile || !victim) return false;
		double contactDistance = projectile.Radius + victim.Radius + 12.0;
		bool verticalContact = projectile.Pos.z + projectile.Height >= victim.Pos.z - 12.0 &&
			projectile.Pos.z <= victim.Pos.z + victim.Height + 12.0;
		return verticalContact && projectile.Distance2D(victim) <= contactDistance;
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
				// Armor, class modifiers, and other damage rules still apply.
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

	clearscope static double NativeBossResistance(Actor victim, Actor inflictor, Actor source, Name damageType)
	{
		if(!victim || !(victim is 'Cyberdemon' || victim is 'SpiderMastermind')) return 1.;
		if(!ClassesEnabled())
		{
			string typeName=String.Format("%s",damageType).MakeLower();
			string projectileName=inflictor?String.Format("%s",inflictor.GetClassName()).MakeLower():"";
			// Despite its name, ID24IncineratorProjectile is the Calamity Blade's heatwave.
			if((inflictor && inflictor is 'ID24IncineratorProjectile') ||
				projectileName.IndexOf("calamity")>=0 || typeName.IndexOf("calamity")>=0 ||
				projectileName.IndexOf("heatwave")>=0) return .25;
			// Burn ticks are fire, not a second rocket hit. Never infer delayed hits from ReadyWeapon.
			if(typeName=="tuinrocketburn" || typeName=="tuinhellfireburn" ||
				typeName=="tuinshotgunburn" || typeName=="tuinwildfire") return .65;
			if((inflictor && inflictor is 'Rocket') || IsPlayerRocketDamage(inflictor,damageType) ||
				(!IsGrenadeDamage(inflictor,damageType) && projectileName.IndexOf("rocket")>=0)) return .5;
			if(damageType=='Fire' || (inflictor && inflictor is 'ID24IncineratorFlame')) return .65;
		}
		return IsBFGDamage(inflictor,source,damageType)?.25:1.;
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

	int RollWeaponQuality(int monsterRarity, TuinPlayerData finder = null)
	{
		double roll = FRandom[TuinRPGLoot](0.0, 100.0);
		roll /= 1.0 + TuinWeaponTraits.Strength(finder, 14) * 0.04;
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
		if (!ClassesEnabled()) lootDrop.AffixFlags = TuinWeaponTraits.Roll(
			lootDrop.AffixFlags, quality, Random[TuinTraitRoll](0, 1000000), lootDrop.WeaponType);
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

	class<Weapon> PickDropWeapon(Actor pawn)
	{
		if(ClassesEnabled()) return PickOwnedWeapon(pawn);
		Array<class<Weapon> > choices;
		class<Weapon> baseTypes[9]={'Fist','Chainsaw','Pistol','Shotgun','SuperShotgun',
			'Chaingun','RocketLauncher','PlasmaRifle','BFG9000'};
		for(int i=0;i<9;i++)
		{
			// Check actual resources, not the map name: Doom II maps can be named E1M1 too.
			if(baseTypes[i]=='SuperShotgun' && !TexMan.CheckForTexture("SHT2A0",TexMan.Type_Any).IsValid()) continue;
			class<Weapon> candidate=(class<Weapon>)(Actor.GetReplacement(baseTypes[i]));
			if(!candidate) continue; // Never bypass a mod's non-weapon replacement.
			readonly<Weapon> def=GetDefaultByType(candidate);
			if(def.bPowered_Up) continue;
			bool duplicate=false;
			for(int j=0;j<choices.Size();j++) if(choices[j]==candidate) duplicate=true;
			if(!duplicate) choices.Push(candidate);
		}
		// Retain mod-specific extras once discovered, without enumerating hidden/internal weapon classes.
		if(pawn) for(Inventory item=pawn.Inv;item;item=item.Inv)
		{
			let weapon=Weapon(item);
			if(!weapon || weapon.Amount<=0 || weapon.bPowered_Up) continue;
			class<Weapon> candidate=(class<Weapon>)(weapon.GetClass());
			bool duplicate=false;
			for(int j=0;j<choices.Size();j++) if(choices[j]==candidate) duplicate=true;
			if(!duplicate) choices.Push(candidate);
		}
		return choices.Size()?choices[Random[TuinRPGLoot](0,choices.Size()-1)]:null;
	}
	class<Weapon> PickClassRewardWeapon(Actor pawn, TuinPlayerData playerData)
	{
		if (!pawn || !playerData) return null;
		// Classes with their own arsenal receive one of those signature weapons.
		// The remaining classes receive an already-owned weapon, which guarantees
		// compatibility with both custom loadouts and multiplayer class choices.
		if (playerData.PlayerClass == 1 && pawn.FindInventory('TuinMinigun')) return 'TuinMinigun';
		if (playerData.PlayerClass == 4 && pawn.FindInventory('TuinDoomGuyQuadShotgun'))
			return 'TuinDoomGuyQuadShotgun';
		if (playerData.PlayerClass == 5) return RandomRogueWeaponType();
		return PickOwnedWeapon(pawn);
	}

	TuinWeaponDrop SpawnRolledWeaponDrop(Vector3 position, class<Weapon> weaponType, int itemLevel, int quality)
	{
		weaponType = TuinRustSupport.Resolve(weaponType);
		if (!weaponType) return null;
		class<Weapon> shotgunType = (class<Weapon>)(Actor.GetReplacement('Shotgun'));
		if (ClassesEnabled() && (weaponType == 'Shotgun' || weaponType == shotgunType) &&
			FRandom[TuinRPGLoot](0.0, 100.0) < clamp(CVFloat('tuin_riot_shotgun_chance', 8.0), 0.0, 100.0))
		{
			weaponType = (class<Weapon>)(FindClass('TuinRiotShotgun', 'Weapon'));
		}
		let lootDrop = TuinWeaponDrop(Actor.Spawn('TuinWeaponDrop', position, NO_REPLACE));
		if (!lootDrop) return null;
		lootDrop.VariantID = ++NextLootID;
		lootDrop.WeaponType = weaponType;
		lootDrop.ItemLevel = itemLevel;
		lootDrop.Quality = quality;
		RollWeaponAffixes(lootDrop, itemLevel, quality);
		lootDrop.DisplayName = WeaponVariantName(weaponType, lootDrop.AffixFlags, quality, lootDrop.VariantID);
		lootDrop.ConfigureVisuals();
		AnnounceWeaponDrop(lootDrop);
		return lootDrop;
	}

	void ReleaseBossChestReward(TuinBossRewardChest chest)
	{
		if (!chest || !chest.RewardWeapon) return;
		let reward = SpawnRolledWeaponDrop(chest.Pos + (0, 0, 42),
			chest.RewardWeapon, chest.RewardLevel, chest.RewardQuality);
		if (!reward) return;
		reward.Vel = (0, 0, 7.0);
		reward.NudgeCooldown = 18;
		chest.A_StartSound("misc/secret", CHAN_ITEM, 0, 0.8);
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
		lootDrop.AffixFlags = TuinWeaponTraits.Roll(lootDrop.AffixFlags,
			lootDrop.Quality, lootDrop.VariantID, lootDrop.WeaponType);
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

	void EnsureRogueCatchupChoice(int playerNumber)
	{
		TuinWeaponDrop replacement;
		ThinkerIterator it = ThinkerIterator.Create('TuinWeaponDrop');
		TuinWeaponDrop drop;
		while (drop = TuinWeaponDrop(it.Next()))
		{
			if (!drop.CatchupReward || drop.CatchupPlayerNumber != playerNumber) continue;
			if (IsRogueOnlyWeaponType(drop.WeaponType)) return;
			if (!replacement) replacement = drop;
		}
		if (!replacement) return;
		replacement.WeaponType = RandomRogueWeaponType();
		replacement.DisplayName = WeaponVariantName(replacement.WeaponType,
			replacement.AffixFlags, replacement.Quality, replacement.VariantID);
		replacement.ConfigureVisuals();
	}

	void SpawnCatchupWeaponChoices(Actor pawn, int itemLevel)
	{
		if (!pawn) return;
		let playerData = TuinPlayerData(pawn.FindInventory('TuinPlayerData'));
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
		if (playerData && playerData.PlayerClass == 5)
		{
			candidates.Push('TuinRogueKnife');
			candidates.Push('TuinRogueSilencedPistol');
			candidates.Push('TuinRogueBow');
		}

		Array<class<Weapon> > selected;
		int firstRandomChoice = 0;
		if (playerData && playerData.PlayerClass == 5)
		{
			class<Weapon> rogueChoice = RandomRogueWeaponType();
			selected.Push(rogueChoice);
			double angle = pawn.Angle - 30.0;
			Vector3 position = (pawn.Pos.x + cos(angle) * 80.0,
				pawn.Pos.y + sin(angle) * 80.0, pawn.FloorZ + 8.0);
			let reward = SpawnRolledWeaponDrop(position, rogueChoice, itemLevel,
				RollCatchupWeaponQuality());
			if (reward)
			{
				reward.CatchupReward = true;
				reward.CatchupPlayerNumber = pawn.PlayerNumber();
			}
			firstRandomChoice = 1;
		}
		for (int choice = firstRandomChoice; choice < 3 && selected.Size() < candidates.Size(); choice++)
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
			if (reward)
			{
				reward.CatchupReward = true;
				reward.CatchupPlayerNumber = pawn.PlayerNumber();
			}
		}
	}

	void ApplyLateStartCatchup(int playerNumber)
	{
        if(TuinRun.Active())return;
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
		if (!CVInt('tuin_late_start_catchup', 1) || !(gameinfo.gametype & GAME_DoomChex))
			return;

		int baseLevel = ProgressiveBaseLevel();
		bool freshLateStart = previousMap <= 0 && baseLevel > 1;
		bool nonSequentialJump = previousMap > 0 && mapNumber != previousMap + 1;
		int targetLevel = clamp(baseLevel + clamp(CVInt('tuin_catchup_bonus_levels', 3), 0, 10),
			1, max(1, CVInt('tuin_monster_max_level', 40)));
		if ((!freshLateStart && !nonSequentialJump) || data.PlayerLevel >= targetLevel)
			return;

		int oldLevel = max(1, data.PlayerLevel);
		int catchupPerks = 0;
		for (int newLevel = oldLevel + 1; newLevel <= targetLevel; newLevel++)
		{
			data.UnspentStatPoints++;
			data.UnspentSkillPoints += PerkPointsAtLevel(newLevel);
			catchupPerks += PerkPointsAtLevel(newLevel);
		}
		data.PlayerLevel = targetLevel;
		AnnouncePoints(playerNumber, targetLevel - oldLevel, catchupPerks, 0);
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

	void TryDropExtraLife(Actor corpse, TuinMonsterData monsterData)
	{
		if (!corpse || !monsterData || monsterData.MonsterRarity < 2) return;
		double chance;
		switch (monsterData.MonsterRarity)
		{
		case 2: chance = 3.0; break;
		case 3: chance = 6.0; break;
		case 4: chance = 12.0; break;
		case 5: chance = 20.0; break;
		default: chance = 35.0; break;
		}
		if (FRandom[TuinRPGLifeDrop](0.0, 100.0) >= chance) return;
		Vector3 dropPosition = (corpse.Pos.x, corpse.Pos.y, corpse.FloorZ + 18.0);
		let heart = TuinLifePickup(Actor.Spawn('TuinLifePickup', dropPosition, NO_REPLACE));
		if (heart) heart.bDROPPED = true;
	}

	void TryDropLifeEssence(Actor corpse)
	{
		if (!corpse || !corpse.bCOUNTKILL) return;
		double chance = clamp(CVFloat('tuin_life_essence_drop_chance', 10.0), 0.0, 100.0);
		if (chance <= 0.0 || FRandom[TuinRPGLifeEssenceDrop](0.0, 100.0) >= chance) return;
		Vector3 dropPosition = (corpse.Pos.x, corpse.Pos.y, corpse.FloorZ + 14.0);
		let essence = TuinLifeEssencePickup(Actor.Spawn('TuinLifeEssencePickup',
			dropPosition, NO_REPLACE));
		if (essence) essence.bDROPPED = true;
	}

	void TryDropRogueBolts(Actor corpse, int playerNumber, TuinMonsterData monsterData)
	{
		if (!corpse || !monsterData || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS ||
			!playerInGame[playerNumber] || !players[playerNumber].mo) return;
		Actor pawn = players[playerNumber].mo;
		let playerData = GetPlayerData(pawn);
		if (!playerData || playerData.PlayerClass != 5 || !pawn.FindInventory('TuinRogueBow')) return;
		let ammo = Ammo(pawn.FindInventory('TuinRogueBoltAmmo'));
		if (ammo && ammo.Amount >= ammo.MaxAmount) return;
		// Bolts are premium Rogue ammunition. Ordinary enemies can still sustain the
		// bow, while elite and boss kills are noticeably better sources.
		double chance = min(10.0, 2.0 + monsterData.MonsterRarity * 1.25);
		if (FRandom[TuinRogueBoltDrop](0.0, 100.0) >= chance) return;
		Actor.Spawn('TuinRogueBoltAmmo', (corpse.Pos.x, corpse.Pos.y, corpse.FloorZ + 8.0), NO_REPLACE);
	}

	void SynchronizeLifeEssenceOverhealth(Actor pawn, TuinPlayerData data, bool drainHealth)
	{
		if (!pawn || !pawn.player || !data) return;
		let pp = PlayerPawn(pawn);
		if (!pp) return;
		if (data.LifeEssenceHealthOwner != pawn)
		{
			data.LifeEssenceHealthOwner = pawn;
			data.AppliedLifeEssenceOverhealth = 0;
		}
		int desired = max(0, int(ceil(data.LifeEssenceOverhealth)));
		int delta = desired - data.AppliedLifeEssenceOverhealth;
		if (delta == 0) return;
		pp.Stamina += delta;
		data.AppliedLifeEssenceOverhealth = desired;
		if (drainHealth && delta < 0 && pawn.Health > 0)
		{
			// Expiring temporary health is allowed to return a healthy marine to
			// 100, but it must never turn the timer itself into real damage. If the
			// player was already below that floor, preserve their current health.
			int decayFloor = min(100, pawn.GetMaxHealth(true));
			int targetHealth = pawn.Health >= decayFloor ?
				max(decayFloor, pawn.Health + delta) : pawn.Health;
			pawn.A_SetHealth(max(1, targetHealth));
		}
		if (pawn.Health > pawn.GetMaxHealth(true)) pawn.A_SetHealth(pawn.GetMaxHealth(true));
	}

	void GrantLifeEssenceOverhealth(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data || pawn.Health <= 0) return;
		// Retire any healing-over-time state carried by an older save.
		data.LifeEssenceHealingPool = 0.0;
		data.LifeEssenceHealingRemainder = 0.0;
		data.LifeEssenceHealingTics = 0;
		data.LifeEssenceOverhealth += 30.0;
		// A fresh orb refreshes the complete temporary-health pool back to the
		// gentle opening stage before its decay begins accelerating again.
		data.LifeEssenceDecayAgeTics = 0;
		data.LifeEssenceDecayClock = 0;
		SynchronizeLifeEssenceOverhealth(pawn, data, false);
		pawn.A_SetHealth(min(pawn.GetMaxHealth(true), pawn.Health + 30));
	}

	void ConsumeLifeEssenceOverhealth(Actor pawn, TuinPlayerData data, int damage)
	{
		if (!pawn || !data || damage <= 0 || data.LifeEssenceOverhealth <= 0.0) return;
		int actualDamage = min(damage, max(0, pawn.Health + damage));
		data.LifeEssenceOverhealth = max(0.0, data.LifeEssenceOverhealth - actualDamage);
		SynchronizeLifeEssenceOverhealth(pawn, data, false);
	}

	void UpdateLifeEssenceOverhealth(Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !data) return;
		SynchronizeLifeEssenceOverhealth(pawn, data, false);
		if (data.LifeEssenceOverhealth <= 0.0)
		{
			data.LifeEssenceDecayAgeTics = 0;
			data.LifeEssenceDecayClock = 0;
			return;
		}
		int ageSeconds = data.LifeEssenceDecayAgeTics / 35;
		double decayPerSecond = ageSeconds < 5 ? 1.0 :
			ageSeconds < 10 ? 2.0 :
			ageSeconds < 15 ? 4.0 :
			ageSeconds < 20 ? 8.0 : 16.0;
		data.LifeEssenceDecayAgeTics++;
		data.LifeEssenceOverhealth = max(0.0,
			data.LifeEssenceOverhealth - decayPerSecond / 35.0);
		SynchronizeLifeEssenceOverhealth(pawn, data, true);
		if ((level.Time % 7) == 0 && pawn.Health > 0)
			pawn.A_SpawnParticle(Color(70, 255, 125), SPF_FULLBRIGHT | SPF_FACECAMERA,
				10, 2.0, 0, FRandom[TuinLifeEssenceHeal](-8.0, 8.0),
				FRandom[TuinLifeEssenceHeal](-8.0, 8.0),
				FRandom[TuinLifeEssenceHeal](4.0, pawn.Height), 0, 0, 0.25,
				0, 0, -0.015, 0.10, 0.03);
	}

	void ReviveWithLife(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || !data.LifeRevivePending) return;
		pawn.A_RemoveLight('TuinLifeReviveGlow');
		if (data.LifeReviveFreezeApplied && !data.LifeReviveWasFrozen)
			pawn.player.cheats &= ~CF_TOTALLYFROZEN;
		Vector3 destination;
		int startAngle;
		[destination, startAngle] = level.PickPlayerStart(playerNumber);
		pawn.SetOrigin(destination, false);
		pawn.Angle = startAngle;
		pawn.Pitch = 0;
		pawn.Vel = (0, 0, 0);
		pawn.A_SetHealth(max(1, pawn.GetMaxHealth(true)));
		pawn.player.damagecount = 0;
		pawn.player.poisoncount = 0;
		PoisonTics[playerNumber] = 0;
		PoisonDamage[playerNumber] = 0;
		PoisonSource[playerNumber] = null;
		data.LifeRevivePending = false;
		data.LifeReviveTics = 0;
		data.LifeReviveFadeTics = 24;
		data.LifeReviveFreezeApplied = false;
		data.LifeReviveWasFrozen = false;
		data.LifeGraceTics = 3 * 35;
		for (int particle = 0; particle < 48; particle++)
			pawn.A_SpawnParticle(particle & 1 ? Color(255, 20, 12) : Color(255, 170, 40),
				SPF_FULLBRIGHT | SPF_FACECAMERA, 24, 8.0, 0,
				FRandom[TuinLifeRevive](-24.0, 24.0), FRandom[TuinLifeRevive](-24.0, 24.0),
				FRandom[TuinLifeRevive](0.0, pawn.Height), 0, 0, FRandom[TuinLifeRevive](0.5, 2.5),
				0, 0, -0.05, 0.25, 0.08);
		pawn.A_StartSound("misc/teleport", CHAN_BODY);
		SetLootNotification(playerNumber, String.Format("EXTRA LIFE USED  %d REMAIN", data.Lives), 5);
		pawn.A_Log(String.Format("Extra life used. Returned to the start with %d remaining.", data.Lives));
	}

	void UpdateLifeRevive(int playerNumber, Actor pawn, TuinPlayerData data)
	{
		if (!pawn || !pawn.player || !data || !data.LifeRevivePending) return;
		if (!data.LifeReviveFreezeApplied)
		{
			data.LifeReviveWasFrozen = (pawn.player.cheats & CF_TOTALLYFROZEN) != 0;
			data.LifeReviveFreezeApplied = true;
			pawn.player.cheats |= CF_TOTALLYFROZEN;
			pawn.A_RemoveLight('TuinLifeReviveGlow');
			pawn.A_AttachLight('TuinLifeReviveGlow', DynamicLight.PulseLight,
				Color(255, 8, 4), 96, 190, 0, (0, 0, 0), 0.42);
			pawn.A_StartSound("misc/secret", CHAN_BODY);
		}
		pawn.Vel = (0, 0, 0);
		if ((data.LifeReviveTics % 3) == 0)
		{
			for (int particle = 0; particle < 7; particle++)
				pawn.A_SpawnParticle(particle & 1 ? Color(255, 12, 8) : Color(170, 0, 0),
					SPF_FULLBRIGHT | SPF_FACECAMERA, 20, 5.0, 0,
					FRandom[TuinLifeRevive](-20.0, 20.0), FRandom[TuinLifeRevive](-20.0, 20.0),
					FRandom[TuinLifeRevive](0.0, pawn.Height), 0, 0,
					FRandom[TuinLifeRevive](0.6, 2.8), 0, 0, -0.03, 0.20, 0.05);
		}
		if (data.LifeReviveTics > 0) data.LifeReviveTics--;
		if (data.LifeReviveTics <= 0) ReviveWithLife(playerNumber, pawn, data);
	}

	ui string LifeReviveJohnQuote(int quote)
	{
		switch (quote)
		{
		case 0: return "JOHN: Not done yet. Get back in there.";
		case 1: return "JOHN: Hell does not get you that easily.";
		case 2: return "JOHN: That heart bought you another round.";
		case 3: return "JOHN: Up again. The map is still waiting.";
		default: return "JOHN: You still have work to do.";
		}
	}

	ui string JohnMilestoneQuote(int quote)
	{
		// Keep role advice entirely out of the compatibility edition, even if an
		// old save or a manually sent test event supplies one of these indices.
		if (!ClassesEnabled() && quote >= 29 && quote <= 42)
			return "Use the universal perks to shape the build around your weapon mod.";
		switch (quote)
		{
		case 0: return "Keep moving. A still marine is an easy target.";
		case 1: return "Check corners. Hell loves hiding one last imp.";
		case 2: return "Save the heavy ammunition for heavy problems.";
		case 3: return "Armor first. Heroics become cheaper afterward.";
		case 4: return "Press K when you have points waiting to be spent.";
		case 5: return "Press L to compare the weapons you have collected.";
		case 6: return "Luck raises critical chance as well as bonus XP.";
		case 7: return "Blood Drinker counts every hit, even tiny ones.";
		case 8: return "Armored enemies cut ordinary incoming damage in half.";
		case 9: return "Warding weakens your bonus and elemental damage.";
		case 10: return "Healing monsters need pressure, not patience.";
		case 11: return "Poison is a good reason to finish the fight quickly.";
		case 12: return "Rare colors mean better loot and nastier surprises.";
		case 13: return "Mythic does not mean immortal. Keep firing.";
		case 14: return "Bosses resist punishment, but they still bleed.";
		case 15: return "Rockets burn the target and scorch its neighbors.";
		case 16: return "Plasma arcs farther than the shot you can see.";
		case 17: return "Grenades cannot crit, so throw them into crowds.";
		case 18: return "Lost Souls are fodder. Clear them without mercy.";
		case 19: return "Dense packs become fodder. Make that weakness count.";
		case 20: return "At eighty five percent kills, Hunt reveals survivors.";
		case 21: return "Yellow Hunt marks point toward ordinary stragglers.";
		case 22: return "Colored Hunt marks still show enemy rarity.";
		case 23: return "A diamond on the minimap means weapon loot.";
		case 24: return "Press N if you need the minimap out of your way.";
		case 25: return "Your flashlight can expose a very bad idea early.";
		case 26: return "Fresh ammunition is useless if you forget to reload.";
		case 27: return "A weaker weapon level can still carry better traits.";
		case 28: return "Critical chance tops out at 50%. Put the rest into raw damage.";
		case 29: return "Firing speed has a limit outside Heavy Overdrive.";
		case 30: return "Heavy charges fastest by fighting in the thick of it.";
		case 31: return "Overdrive turns saved ammunition into ten wild seconds.";
		case 32: return "Healer supplies are best called before panic begins.";
		case 33: return "Executioner should sentence the enemy everyone fears.";
		case 34: return "Judgment waits for your next proper weapon hit.";
		case 35: return "Final Verdict rewards a well chosen execution.";
		case 36: return "Doom Guy earns Blood Punch by staying aggressive.";
		case 37: return "Hold V, choose the moment, then release the punch.";
		case 38: return "Blood Punch heals from the damage it actually deals.";
		case 39: return "Rogue earns Shadow Veil through weapon damage.";
		case 40: return "A Rogue ambush is always a critical hit.";
		case 41: return "Heavy critical hits create the strongest bleeding.";
		case 42: return "Do not waste Shadow Veil on the first weak target.";
		case 43: return "Cyberdemons and masterminds strongly resist the BFG.";
		case 44: return "The Director watches health, ammunition, and momentum.";
		case 45: return "Untouched ammunition may improve when reserves run low.";
		case 46: return "Extra lives protect the run and improve your rating.";
		case 47: return "Items and secrets matter when you want an elite score.";
		case 48: return "Good pace helps, but surviving matters much more.";
		default: return "You are making progress. Hell is running out of rooms.";
		}
	}

	void StartJohnMilestoneComment(int playerNumber, int percent, int forcedQuote = -1)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS) return;
		if (forcedQuote >= 0)
			JohnCommentQuote[playerNumber] = clamp(forcedQuote, 0, 49);
		else if (!ClassesEnabled())
		{
			// Quotes 29-42 discuss the six classes and their abilities. The
			// compatibility edition samples only the general gameplay remarks.
			int generalQuote = Random[TuinJohnMilestones](0, 35);
			JohnCommentQuote[playerNumber] = generalQuote <= 28 ? generalQuote : generalQuote + 14;
		}
		else JohnCommentQuote[playerNumber] = Random[TuinJohnMilestones](0, 49);
		JohnCommentPercent[playerNumber] = percent;
		JohnCommentTics[playerNumber] = 245;
		// This is a screen-local UI event, so use the engine's direct sound route.
		// Actor-local playback can be discarded when the HUD event originates in
		// server scope, even in a single-player game.
		if (playerNumber == consoleplayer)
			S_Sound("tuin/john/tip", CHAN_AUTO, 1.0, ATTN_NONE);
	}

	void UpdateJohnMilestoneComments()
	{
		if (level.total_monsters <= 0) return;
		int reached = clamp(level.killed_monsters * 10 / level.total_monsters, 0, 10);
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber]) continue;
			while (JohnCommentMilestone[playerNumber] < reached)
			{
				JohnCommentMilestone[playerNumber]++;
				if (CVInt('tuin_john_milestone_comments', 1) &&
					Random[TuinJohnMilestoneChance](0, 99) < 50)
					StartJohnMilestoneComment(playerNumber,
						JohnCommentMilestone[playerNumber] * 10);
			}
		}
	}

	string RandomJohnGreeting()
	{
		switch (Random[TuinRPGJohn](0, 5))
		{
		case 0: return "John: You made it. Spend those coins before the exit.";
		case 1: return "John: Monsters hoard everything. Lucky for you, I sell it back.";
		case 2: return "John: Need shells, armor, or something louder?";
		case 3: return "John: That boss looks tough. Gear up before you take it on.";
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
			AnnounceMilestone(true);
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
			BootstrappingCoinStack=true;
			pawn.GiveInventory('TuinCoinPickup', 1);
			BootstrappingCoinStack=false;
			coins = Inventory(pawn.FindInventory('TuinCoinPickup'));
			if (coins)
			{
				// GiveInventory creates the stack with one item; clear that bootstrap
				// amount so grants award exactly the requested number of coins.
				coins.Amount = 0;
				coins.A_RemoveLight('TuinCoinGlow');
			}
		}
		if (coins)
		{
			int previous=coins.Amount;
			coins.Amount = min(coins.MaxAmount, coins.Amount + amount);
			RecordCoinMilestone(pawn,coins.Amount-previous);
		}
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
						WeaponQualityName(quality), WeaponBaseName(reward.WeaponType));
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
		SetServerFloat('tuin_riot_shotgun_chance', 8.0);
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
		int scaledMaximum = max(1, monsterData.ScaledMaxHealth);
		bool colossalGodly = scaledMaximum >= 20000;
		double colossalProgress = clamp(double(scaledMaximum - 5000) / 15000.0, 0.0, 1.0);
		if (scaledMaximum >= 5000)
			chance = max(chance, 10.0 + colossalProgress * 40.0);
		bool trueFinale = monsterData.MonsterRarity >= 6 && IsIconicEpisodeBoss(corpse);
		bool nativeBossGodly = monsterData.MonsterRarity < 6 && corpse.bBOSS &&
			FRandom[TuinRPGLoot](0.0, 100.0) < clamp(CVFloat('tuin_native_boss_godly_chance', 5.0), 0.0, 25.0);
		if (monsterData.MonsterRarity < 6 && !nativeBossGodly && !colossalGodly &&
			FRandom[TuinRPGLoot](0.0, 100.0) >= chance) return;
		class<Weapon> weaponType;
		// Half of a Rogue's successful weapon-drop rolls stay class-relevant.
		// The drop remains a shared world object, so multiplayer pickup rules
		// still let another Rogue claim it without a non-Rogue consuming it.
		if (!ClassesEnabled())
			weaponType = PickDropWeapon(players[playerNumber].mo);
		else if (colossalGodly)
			weaponType = PickClassRewardWeapon(players[playerNumber].mo, playerData);
		else if (playerData && playerData.PlayerClass == 5 && Random[TuinRPGLoot](0, 1) == 0)
			weaponType = RandomRogueWeaponType();
		else
			weaponType = PickOwnedWeapon(players[playerNumber].mo);
		class<Weapon> rustReward = TuinRustSupport.Discovery(monsterData.MonsterRarity,
			FRandom[TuinRustLoot](0.0, 100.0));
		if (rustReward) weaponType = rustReward;
		if (!weaponType) return;
		int itemLevel = clamp(monsterData.MonsterLevel + Random[TuinRPGLoot](-2, 2), 1, max(1, CVInt('tuin_monster_max_level', 40)));
		int quality = colossalGodly || nativeBossGodly ? 6 : monsterData.MonsterRarity >= 6 ?
			RollBossWeaponQuality(trueFinale) : RollWeaponQuality(monsterData.MonsterRarity, playerData);
		if (!colossalGodly && scaledMaximum >= 5000 && quality < 5 &&
			FRandom[TuinRPGLoot](0.0, 100.0) < 15.0 + colossalProgress * 35.0)
			quality = 5;
		if (monsterData.MonsterRarity >= 6)
		{
			class<Actor> chestClass = CVInt('tuin_boss_chest_style', 0) == 1 ?
				'TuinBossRewardChestMinecraft' : 'TuinBossRewardChest';
			let chest = TuinBossRewardChest(Actor.Spawn(chestClass,
				(corpse.Pos.x, corpse.Pos.y, corpse.FloorZ + 2.0), NO_REPLACE));
			if (chest)
			{
				chest.Angle = chest.AngleTo(players[playerNumber].mo, true);
				chest.RewardWeapon = weaponType;
				chest.RewardLevel = itemLevel;
				chest.RewardQuality = quality;
				chest.PushNearbyBodies();
				for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
					if (playerInGame[i] && players[i].mo)
						SetLootNotification(i, "BOSS CHEST DROPPED - PRESS USE TO OPEN", 5);
				return;
			}
		}
		SpawnRolledWeaponDrop((corpse.Pos.x, corpse.Pos.y, corpse.FloorZ + 8.0), weaponType, itemLevel, quality);
	}

	int RollRarity()
	{
        if(TuinRun.Active())return TuinRun.RarityForRoll(TuinRun.Stage(),FRandom[TuinRunRarity](0.,100.));
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
		return ScaleHealthPower(multiplier) * WhiteCatchupBonus(rarity, false, CatchupPlayerLevel()) * (1.+TuinRun.Stage()*.08);
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
		return ScaleDamagePower(multiplier) * WhiteCatchupBonus(rarity, true, CatchupPlayerLevel()) * (1.+TuinRun.Stage()*.04);
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

	bool TryOpenBossChest(int playerNumber)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS || !playerInGame[playerNumber]) return false;
		Actor pawn = players[playerNumber].mo;
		if (!pawn || pawn.Health <= 0) return false;
		TuinBossRewardChest nearestChest;
		double nearestDistance = 96.0;
		ThinkerIterator iterator = ThinkerIterator.Create('TuinBossRewardChest');
		TuinBossRewardChest chest;
		while (chest = TuinBossRewardChest(iterator.Next()))
		{
			if (chest.Opened) continue;
			double distance = pawn.Distance3D(chest);
			if (distance > nearestDistance || !pawn.CheckSight(chest)) continue;
			if (distance > 36.0 &&
				abs(Actor.deltaangle(pawn.Angle, pawn.AngleTo(chest, true))) > 55.0) continue;
			nearestChest = chest;
			nearestDistance = distance;
		}
		return nearestChest && nearestChest.Used(pawn);
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
		if (announce && !ClassesEnabled())
			BossArrivalBannerStart = NextBannerSlot();

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
		bool meatyArmorBlocked = playerProgress >= 15 && monsterData &&
			monsterData.OriginalMaxHealth >= 400;
		bool lowBaseBoss = monster && !IsIconicEpisodeBoss(monster) && monsterData &&
			monsterData.OriginalMaxHealth < 500 && !meatyArmorBlocked;
		int flags = lowBaseBoss ? TuinMonsterData.AFFIX_ARMORED : 0;
		while (AffixBitCount(flags) < wanted)
		{
			int bit = 1 << Random[TuinRPGAffix](0, 8);
			if (flags & bit) continue;
			if (meatyArmorBlocked && bit == TuinMonsterData.AFFIX_ARMORED) continue;
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

	int RollAffixes(int count, int blockedFlags = 0)
	{
		int flags = 0;
		for (int i = 0; i < count; i++)
		{
			int bit = 1 << Random[TuinRPGAffix](0, 8);
			if ((flags & bit) || (blockedFlags & bit)) { i--; continue; }
			flags |= bit;
		}
		return flags;
	}

	int RollOrdinaryMonsterAffixes(int originalHealth, int rarity)
	{
		int count = AffixCountForRarity(rarity);
		bool meatyArmorBlocked = HighestActivePlayerLevel() >= 15 && originalHealth >= 400;
		// Hell Knight health is the dividing line. Armor consumes one trait slot;
		// all remaining slots keep their normal random rolls. At level 15, Cacodemon-
		// tier health pools no longer roll Armor because scaling already makes them meaty.
		if (rarity >= 2 && rarity < 6 && originalHealth < 500 && !meatyArmorBlocked)
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
		return RollAffixes(count, meatyArmorBlocked ? TuinMonsterData.AFFIX_ARMORED : 0);
	}

	string AffixList(TuinMonsterData data)
	{
		if (!data) return "";
		string result = "";
		if (HasFodderDebuff(data.Owner)) result.AppendFormat("FODDER: +50%% DAMAGE TAKEN");
		if (data.AffixFlags & TuinMonsterData.AFFIX_SWIFT)
			result.AppendFormat("%sSWIFT", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_ARMORED) result.AppendFormat("%sARMORED", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_REGENERATING) result.AppendFormat("%sREGENERATING", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_BERSERKER) result.AppendFormat("%sBERSERKER", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_EXPLOSIVE) result.AppendFormat("%sEXPLOSIVE", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_VAMPIRIC) result.AppendFormat("%sVAMPIRIC", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_POISONOUS) result.AppendFormat("%sPOISONOUS", result.Length() ? "  |  " : "");
		if (data.AffixFlags & TuinMonsterData.AFFIX_HEALER)
			result.AppendFormat("%s%s", result.Length() ? "  |  " : "", ClassesEnabled() ? "HEALER" : "SUPPORT");
		if (data.AffixFlags & TuinMonsterData.AFFIX_WARDING) result.AppendFormat("%sWARDING", result.Length() ? "  |  " : "");
		else if (data.WardTics > 0) result.AppendFormat("%sWARDED", result.Length() ? "  |  " : "");
		if (data.Owner && (data.Owner is 'Cyberdemon' || data.Owner is 'SpiderMastermind'))
			result.AppendFormat("%s%s", result.Length() ? "  |  " : "", ClassesEnabled() ? "BFG RESIST 75%" :
				"BFG 75% | ROCKET 50% | CALAMITY 75% | FIRE 35% RESIST");
		if (data.BleedPulsesRemaining > 0) result.AppendFormat("%sBLEEDING", result.Length() ? "  |  " : "");
		if (data.RoguePoisonPulsesRemaining > 0) result.AppendFormat("%sVENOMED", result.Length() ? "  |  " : "");
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
		data.LastRogueKnifePlayer = -1;
		data.LastRogueKnifeDamageTime = -1;
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
		monsterLevel = min(max(1, CVInt('tuin_monster_max_level', 40)), WhiteLevelFloor(monsterLevel, rarity, CatchupPlayerLevel()));
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

	clearscope static int SpawnRarityPriority(Actor monster, TuinMonsterData data)
	{
		if (!monster || !data) return -1;
		if (data.OriginalMaxHealth >= 1000) return 2; // Baron-or-stronger.
		if (data.OriginalMaxHealth >= 500 || monster is 'Revenant' || monster is 'PainElemental') return 1;
		return 0;                                     // Cacodemon and lower fallback.
	}

	bool IsHeavyRarityEligible(Actor monster, TuinMonsterData data)
	{
		if (!IsValidMonster(monster) || !monster.bCOUNTKILL || !data || data.MonsterRarity >= 6 ||
			IsIconicEpisodeBoss(monster)) return false;
		// Do not filter on Doom's generic BOSS/BOSSDEATH flags: stock Barons carry
		// them, and non-finale monsters above Baron strength belong in the same
		// health-based preference tier. Iconic map finales are protected above.
		return true;
	}

	void PrioritizeInitialHeavyRarities()
	{
		if (HighestActivePlayerLevel() < 15 || !CVInt('tuin_rarity_enabled', 1)) return;

		// Rarity is initially rolled once per actor while the map is spawning. Move
		// those complete roll packages onto the strongest eligible roster members:
		// Baron-tier first, then the remaining high-threat group, then lighter foes.
		// Counts and rarity grades remain unchanged; the Director is not involved.
		int maximumSwaps = max(1, level.total_monsters);
		for (int swap = 0; swap < maximumSwaps; swap++)
		{
			Actor donor;
			Actor receiver;
			int donorPriority = 3;
			int receiverPriority = -1;
			int donorChoices = 0;
			int receiverChoices = 0;
			ThinkerIterator iterator = ThinkerIterator.Create('Actor');
			Actor monster;
			while (monster = Actor(iterator.Next()))
			{
				let data = GetMonsterData(monster);
				if (!IsHeavyRarityEligible(monster, data)) continue;
				int priority = SpawnRarityPriority(monster, data);
				if (data.MonsterRarity >= 2)
				{
					if (priority < donorPriority)
					{
						donorPriority = priority;
						donorChoices = 1;
						donor = monster;
					}
					else if (priority == donorPriority && Random[TuinRPGRarity](1, ++donorChoices) == 1)
						donor = monster;
				}
				else
				{
					if (priority > receiverPriority)
					{
						receiverPriority = priority;
						receiverChoices = 1;
						receiver = monster;
					}
					else if (priority == receiverPriority && Random[TuinRPGRarity](1, ++receiverChoices) == 1)
						receiver = monster;
				}
			}
			if (!donor || !receiver || receiverPriority <= donorPriority) break;

			let donorData = GetMonsterData(donor);
			let receiverData = GetMonsterData(receiver);
			int donorRarity = donorData.MonsterRarity;
			int donorLevel = donorData.MonsterLevel;
			int receiverRarity = receiverData.MonsterRarity;
			int receiverLevel = receiverData.MonsterLevel;
			ApplyOrdinaryMonsterScale(receiver, receiverData, donorLevel, donorRarity, true);
			ApplyOrdinaryMonsterScale(donor, donorData, receiverLevel, receiverRarity, true);
		}
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
		if (!ClassesEnabled())
		{
			// Coalesce a burst of promotions into one latest-target announcement.
			PromotionBannerStart = 0;
			PromotionBannerStart = NextBannerSlot();
			PromotionBannerTitle = assassin ? "HELL HAS YOUR SCENT" :
				targetRarity >= 5 ? "A NIGHTMARE ASCENDS" :
				targetRarity == 4 ? "HELL CROWNS A CHAMPION" : "A NEW THREAT AWAKENS";
			PromotionBannerDetail = data.GeneratedName.MakeUpper() .. " - EMPOWERED";
		}
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

	bool TestPromoteHeavyMonster(int requestedType, int playerNumber)
	{
		Actor candidate;
		int candidatePriority = -1;
		int choices = 0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
		{
			let data = GetMonsterData(monster);
			if (!IsHeavyRarityEligible(monster, data) || data.MonsterRarity >= 5) continue;

			bool matches = false;
			int priority = SpawnRarityPriority(monster, data);
			if (requestedType == 1) matches = monster is 'HellKnight';
			else if (requestedType == 2) matches = monster is 'BaronOfHell' && !(monster is 'HellKnight');
			else matches = priority >= 1;
			if (!matches) continue;

			// The general command follows the same Baron-tier then high-threat rule.
			if (requestedType == 0 && priority > candidatePriority)
			{
				candidatePriority = priority;
				choices = 1;
				candidate = monster;
			}
			else if (requestedType != 0 || priority == candidatePriority)
			{
				choices++;
				if (Random[TuinRPGRarity](1, choices) == 1) candidate = monster;
			}
		}

		Actor pawn = playerNumber >= 0 && playerNumber < TUIN_MAX_PLAYERS ? players[playerNumber].mo : null;
		if (!candidate)
		{
			if (pawn) pawn.A_Log(requestedType == 1 ? "No eligible living Hell Knight found." :
				requestedType == 2 ? "No eligible living Baron of Hell found." : "No eligible living high-threat monster found.");
			return false;
		}

		let candidateData = GetMonsterData(candidate);
		ApplyOrdinaryMonsterScale(candidate, candidateData,
			max(candidateData.MonsterLevel, RollMonsterLevel(5)), 5, true);
		if (pawn)
		{
			pawn.A_Log(String.Format("TEST PROMOTION: %s is now Mythic.", candidateData.GeneratedName));
			SetLootNotification(playerNumber,
				String.Format("TEST: MYTHIC %s", candidate.GetTag(candidate.GetClassName()).MakeUpper()), 5);
		}
		return true;
	}

	clearscope static int PressureRarity(int roll)
	{
		return roll < 70 ? 2 : roll < 90 ? 3 : roll < 98 ? 4 : 5;
	}
	void RecordPressureDamage(int playerNumber, int amount)
	{
		if (playerNumber < 0 || playerNumber >= 8 || PressureStart[playerNumber] == 0) return;
		PressureDamage[playerNumber] += max(0, amount);
		if (PressureDamage[playerNumber] > 15)
			PressureKills[playerNumber] = PressureDamage[playerNumber] = PressureStart[playerNumber] = 0;
	}
	bool TrySpawnPressureReinforcement(int playerNumber, Actor corpse, int rarity)
	{
		Actor pawn=players[playerNumber].mo;
		if(!pawn || pawn.Health<=0 || (PressureReinforcement && PressureReinforcement.Health>0)) return false;
		// Reuse fought ground; validate space and distance from every player.
		ThinkerIterator bodies=ThinkerIterator.Create('Actor');
		Actor anchor=corpse;
		int attempts=0;
		while(anchor && attempts<16)
		{
			if(anchor.Health<=0 && anchor.bCORPSE && abs(anchor.Pos.Z-anchor.FloorZ)<8 &&
				pawn.Distance3D(anchor)>=256 && pawn.Distance3D(anchor)<=1024 && pawn.CheckSight(anchor))
			{
				bool safe=true;
				for(int i=0;i<8;i++)
					if(playerInGame[i] && players[i].mo && players[i].mo.Distance3D(anchor)<256) safe=false;
				if(safe)
				{
					attempts++;
					class<Actor> kind=rarity>=4?'Revenant':rarity==3?'Demon':'DoomImp';
					Actor reinforcement=Actor.Spawn(kind,anchor.Pos,ALLOW_REPLACE);
					if(reinforcement)
					{
						reinforcement.ClearCounters();
						if(reinforcement.TestMobjLocation() && !reinforcement.bFRIENDLY)
						{
							if(!GetMonsterData(reinforcement)) InitializeMonster(reinforcement);
							let data=GetMonsterData(reinforcement);
							if(data)
							{
								ApplyOrdinaryMonsterScale(reinforcement,data,RollMonsterLevel(rarity),rarity,true);
								PressureReinforcement=reinforcement;
								reinforcement.bDORMANT=false;
								reinforcement.bAMBUSH=false;
								reinforcement.Target=pawn;
								if(reinforcement.SeeState) reinforcement.SetState(reinforcement.SeeState);
								Actor.Spawn('TeleportFog',reinforcement.Pos,ALLOW_REPLACE);
								PromotionBannerStart=0;
								PromotionBannerStart=NextBannerSlot();
								PromotionBannerTitle=rarity>=5?"HELL SENDS ITS ANSWER":rarity>=4?"A CHAMPION ENTERS THE HUNT":"HELL WON'T LET YOU COAST";
								PromotionBannerDetail=RarityName(rarity).." REINFORCEMENT - "..data.GeneratedName.MakeUpper();
								return true;
							}
						}
						reinforcement.Destroy();
					}
				}
			}
			anchor=Actor(bodies.Next());
		}
		return false;
	}
	void RecordPressureKill(int playerNumber, Actor corpse, TuinMonsterData data)
	{
		if(ClassesEnabled() || !CVInt('tuin_director_enabled',1) || !CVInt('tuin_rarity_enabled',1) ||
			playerNumber<0 || playerNumber>=8 || !data || data.MonsterRarity!=0 || !corpse || !corpse.bCOUNTKILL || corpse.bFRIENDLY) return;
		let playerData=GetPlayerData(players[playerNumber].mo);
		if(!playerData || playerData.PlayerLevel<20 || !players[playerNumber].mo || players[playerNumber].mo.Health<=0) return;
		if(level.Time<PressureNextTime || (PressureReinforcement && PressureReinforcement.Health>0)) return;
		if(PressureStart[playerNumber]==0 || level.Time-(PressureStart[playerNumber]-1)>180*35)
		{
			PressureKills[playerNumber]=PressureDamage[playerNumber]=0;
			PressureStart[playerNumber]=level.Time+1;
		}
		if(++PressureKills[playerNumber]<8) return;
		PressureKills[playerNumber]=PressureDamage[playerNumber]=PressureStart[playerNumber]=0;
		// Failed rolls also cool down. Do not prolong an almost-cleared map.
		PressureNextTime=level.Time+90*35;
		if(level.total_monsters-level.killed_monsters<=3 || Random[TuinRPGPressure](0,99)>=50) return;
		TrySpawnPressureReinforcement(playerNumber,corpse,PressureRarity(Random[TuinRPGPressure](0,99)));
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

	clearscope static Name DirectorAmmoType(int family)
	{
		switch (family)
		{
		case 0: return 'Clip';
		case 1: return 'Shell';
		case 2: return 'RocketAmmo';
		case 3: return 'Cell';
		default: return 'None';
		}
	}

	clearscope static Name DirectorSmallAmmoPickup(int family)
	{
		return DirectorAmmoType(family);
	}

	clearscope static Name DirectorLargeAmmoPickup(int family)
	{
		switch (family)
		{
		case 0: return 'ClipBox';
		case 1: return 'ShellBox';
		case 2: return 'RocketBox';
		case 3: return 'CellPack';
		default: return 'None';
		}
	}

	double DirectorAmmoReserveRatio(int family)
	{
		Name ammoType = DirectorAmmoType(family);
		int current;
		int maximum;
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
			let ammo = Ammo(players[playerNumber].mo.FindInventory(ammoType));
			if (!ammo || ammo.MaxAmount <= 0) continue;
			current += max(0, ammo.Amount);
			maximum += ammo.MaxAmount;
		}
		return maximum > 0 ? clamp(double(current) / maximum, 0.0, 1.0) : -1.0;
	}

	Actor FindDirectorSmallAmmoPickup(int family)
	{
		Name pickupType = DirectorSmallAmmoPickup(family);
		Actor candidate;
		int choices;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor pickup;
		while (pickup = Actor(iterator.Next()))
		{
			let pickupInventory = Inventory(pickup);
			if (pickup.GetClassName() != pickupType || !pickupInventory || pickupInventory.Owner || pickup.bDROPPED) continue;
			bool visibleToPlayer = false;
			for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
			{
				if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
				if (players[playerNumber].mo.CheckSight(pickup, SF_IGNOREWATERBOUNDARY))
				{
					visibleToPlayer = true;
					break;
				}
			}
			if (visibleToPlayer) continue;
			choices++;
			if (Random[TuinRPGDirectorAmmo](1, choices) == 1) candidate = pickup;
		}
		return candidate;
	}

	bool DirectorAmmoFamilyEmpty(int family)
	{
		Name ammoName = DirectorAmmoType(family);
		class<Ammo> ammoType = (class<Ammo>)(FindClass(ammoName, 'Ammo'));
		if (!ammoType) return false;
		bool relevant;
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber] || !players[playerNumber].mo) continue;
			let pawn = players[playerNumber].mo;
			let ammo = Ammo(pawn.FindInventory(ammoType));
			if (ammo && ammo.Amount > 0) return false;
			for (Inventory item = pawn.Inv; item; item = item.Inv)
			{
				let weapon = Weapon(item);
				if (weapon && (weapon.AmmoType1 == ammoType || weapon.AmmoType2 == ammoType))
				{
					relevant = true;
					break;
				}
			}
		}
		return relevant;
	}

	bool UpgradeDirectorAmmoPickup(int family, Actor pickup)
	{
		if (!pickup) return false;
		Actor upgraded = Actor.Spawn(DirectorLargeAmmoPickup(family), pickup.Pos, NO_REPLACE);
		if (!upgraded) return false;
		upgraded.Angle = pickup.Angle;
		upgraded.Pitch = pickup.Pitch;
		upgraded.Roll = pickup.Roll;
		upgraded.Vel = pickup.Vel;
		pickup.Destroy();
		return true;
	}

	// Once per stock-ammo family and map, an empty reserve may receive one
	// silent rescue conversion. Failed attempts remain eligible so a pickup
	// that is currently visible can be upgraded later after it leaves sight.
	bool TryEmergencyAmmoUpgrade(int remainingMonsters)
	{
		if (remainingMonsters < 4) return false;
		for (int family = 0; family < 4; family++)
		{
			if (DirectorEmergencyAmmoUsed[family] || !DirectorAmmoFamilyEmpty(family)) continue;
			Actor pickup = FindDirectorSmallAmmoPickup(family);
			if (!UpgradeDirectorAmmoPickup(family, pickup)) continue;
			DirectorEmergencyAmmoUsed[family] = true;
			return true;
		}
		return false;
	}

	// Quietly convert one remaining stock pickup in the weakest carried ammo
	// family to its large-box equivalent. This never adds ammo directly to a
	// player and cannot affect grenades or unknown weapon-mod ammunition.
	bool UpgradeLowAmmoPickup(int remainingMonsters)
	{
		if (remainingMonsters < 4) return false;
		double reserveThreshold = remainingMonsters >= 40 ? 0.40 :
			remainingMonsters >= 20 ? 0.35 : remainingMonsters >= 10 ? 0.25 : 0.15;
		int chosenFamily = -1;
		double chosenRatio = 1.0;
		Actor chosenPickup;
		for (int family = 0; family < 4; family++)
		{
			double ratio = DirectorAmmoReserveRatio(family);
			if (ratio < 0.0 || ratio >= reserveThreshold || ratio >= chosenRatio) continue;
			Actor pickup = FindDirectorSmallAmmoPickup(family);
			if (!pickup) continue;
			chosenFamily = family;
			chosenRatio = ratio;
			chosenPickup = pickup;
		}
		if (chosenFamily < 0 || !chosenPickup) return false;

		return UpgradeDirectorAmmoPickup(chosenFamily, chosenPickup);
	}

	void UpdateHellDirector()
	{
		if (!CVInt('tuin_director_enabled', 1)) return;
		int remainingMonsters = max(0, level.total_monsters - level.killed_monsters);
		bool emergencyUpgraded;
		if ((level.Time % 35) == 0)
			emergencyUpgraded = TryEmergencyAmmoUpgrade(remainingMonsters);
		if (DirectorCheckpoint >= 3 ||
			level.total_monsters < max(8, CVInt('tuin_director_min_monsters', 12))) return;
		int threshold = (DirectorCheckpoint + 1) * 25;
		if (level.killed_monsters * 100 < level.total_monsters * threshold) return;
		DirectorCheckpoint++;
		// Do not perform a second conversion when the emergency check happened
		// on the exact same tic as a regular 25/50/75 percent checkpoint.
		if (!emergencyUpgraded) UpgradeLowAmmoPickup(remainingMonsters);

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
		Actor baronCandidate;
		int candidateCount = 0;
		int heavyCandidateCount = 0;
		int baronCandidateCount = 0;
		bool preferHeavy = HighestActivePlayerLevel() >= 15;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
		{
			let data = GetMonsterData(monster);
			if (!IsHeavyRarityEligible(monster, data) || data.MonsterRarity >= targetRarity) continue;
			candidateCount++;
			if (Random[TuinRPGDirector](1, candidateCount) == 1) candidate = monster;
			// Build the preferred threat pool independently. Dormant and unseen
			// monsters still belong to the roster and may awaken when a trap opens.
			int spawnPriority = SpawnRarityPriority(monster, data);
			if (preferHeavy && spawnPriority >= 1)
			{
				heavyCandidateCount++;
				if (Random[TuinRPGDirector](1, heavyCandidateCount) == 1) heavyCandidate = monster;
				// Keep the random choice within each tier, but do not let the wider
				// threat pool statistically bury Barons and heavier foes.
				if (spawnPriority >= 2)
				{
					baronCandidateCount++;
					if (Random[TuinRPGDirector](1, baronCandidateCount) == 1) baronCandidate = monster;
				}
			}
		}
		// Priority is Baron-tier, then the high-threat roster, then the unrestricted
		// Cacodemon/fodder fallback when the preferred pool is empty.
		if (baronCandidate) candidate = baronCandidate;
		else if (heavyCandidate) candidate = heavyCandidate;
		if (candidate) UpgradeDirectorMonster(candidate, targetRarity);
	}

	void RerollLivingMonsters(int requestingPlayer,bool preserveBosses=false)
	{
		int count = 0;
		ThinkerIterator it = ThinkerIterator.Create('Actor');
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			let data = GetMonsterData(mo);
			if (IsValidMonster(mo) && data && (!preserveBosses || data.MonsterRarity<6))
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
		for (int family = 0; family < 4; family++) DirectorEmergencyAmmoUsed[family] = false;
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
		{
			DirectorDamageTaken[i] = 0;
			DirectorTrailValid[i] = false;
		}
		for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
		{
			CatchupHandled[i] = false;
			InitialClassMenuRequested[i] = false;
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
	}

	override void WorldUnloaded(WorldEvent e)
	{
		if(Run)Run.Unloaded(e);
	}
	override void WorldLoaded(WorldEvent e)
	{
        EnsureRun();
        if(Run && !e.IsSaveGame)Run.Bootstrapping=false;
        if(Run)Run.Loaded(e);
        if(!e.IsSaveGame)
        {
            FullHealthCheckTime=0;FullHealthCheckDone=false;FullHealthReinforcement=null;
        }
        ScheduleFullHealthCheck();
        EnsureLocator();
        if (Locator) Locator.Loaded(e);
		for (int playerNumber = 0; playerNumber < TUIN_MAX_PLAYERS; playerNumber++)
			InitialClassMenuRequested[playerNumber] = false;
		if (!e.IsSaveGame)
		{
			for(int i=0;i<3;i++) { CompletionAnnounced[i]=false; CompletionBannerStart[i]=0; }
			for(int i=0;i<8;i++) CoinBannerStart[i]=CoinBannerAmount[i]=0;
			PressureNextTime=0;
			PressureReinforcement=null;
			for(int i=0;i<8;i++) PressureKills[i]=PressureDamage[i]=PressureStart[i]=0;
			FinaleBossPromoted = false;
			FinaleBoss = null;
			JohnMerchant = null;
			BossBannerStart = JohnBannerStart = BossArrivalBannerStart = 0;
			PromotionBannerStart = 0;
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++) HeavyBannerStart[i] = 0;
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++) WeaponBannerStart[i] = 0;
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
			{
				PointBannerStart[i] = PoisonBannerStart[i] = PoisonBannerTick[i] = 0;
				KeySnapshotReady[i] = false;
				KeyBannerStart[i] = KeyBannerMask[i] = KnownKeyMask[i] = 0;
			}
			MonsterLevelsSynchronized = false;
			DirectorCheckpoint = 0;
			for (int family = 0; family < 4; family++) DirectorEmergencyAmmoUsed[family] = false;
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
			{
				DirectorDamageTaken[i] = 0;
				DirectorTrailValid[i] = false;
				JohnCommentMilestone[i] = 0;
				JohnCommentTics[i] = 0;
			}
			PreviousLoadedCampaignMap = CurrentLoadedCampaignMap;
			CurrentLoadedCampaignMap = level.LevelNum;
			if (CurrentLoadedCampaignMap <= 0) CurrentLoadedCampaignMap = max(1, MapsVisited + 1);
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
			{
				CatchupHandled[i] = false;
			}
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
			{
				if (!playerInGame[i] || !players[i].mo) continue;
				let levelData = EnsurePlayerData(i);
				if (!levelData) continue;
				levelData.LevelDamageDealt = 0;
				levelData.LevelDamageTaken = 0;
				levelData.LevelXPEarned = 0;
				levelData.LevelCoinsEarned = 0;
				levelData.LevelEliteKills = 0;
				levelData.LevelBossKills = 0;
				levelData.LevelCriticalHits = 0;
				levelData.LevelAbilityUses = 0;
				levelData.LevelLivesUsed = 0;
				TuinWeaponTraits.ResetMap(levelData);
			}
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

	void TrackWeaponPerkProjectile(Actor projectile)
	{
		if (ClassesEnabled() || !projectile || !projectile.bMISSILE) return;
		int owner = PlayerNumberFromSource(projectile.Target, projectile);
		if (owner < 0 || owner >= TUIN_MAX_PLAYERS || !playerInGame[owner]) return;
		let data = EnsurePlayerData(owner);
		if (!HasWeaponPerk(data, 6) || WeaponFamily(players[owner].ReadyWeapon) != 6) return;
		int slot = NextWeaponPerkGuidedProjectile;
		NextWeaponPerkGuidedProjectile = (slot + 1) % TUIN_MAX_GUIDED_PROJECTILES;
		WeaponPerkGuidedProjectile[slot] = projectile;
		WeaponPerkGuidedOwner[slot] = owner;
	}

	void UpdateWeaponPerkProjectiles()
	{
		if (ClassesEnabled()) return;
		for (int i = 0; i < TUIN_MAX_GUIDED_PROJECTILES; i++)
		{
			Actor projectile = WeaponPerkGuidedProjectile[i];
			if (!projectile || !projectile.bMISSILE)
			{
				WeaponPerkGuidedProjectile[i] = null;
				continue;
			}
			Actor best;
			double bestDistance = 1024.0;
			foreach (sector: level.Sectors)
			{
				for (Actor candidate = sector.thinglist; candidate; candidate = candidate.snext)
				{
					if (candidate.Health <= 0 || !candidate.bISMONSTER || candidate.bFRIENDLY) continue;
					double distance = projectile.Distance3D(candidate);
					if (distance >= bestDistance || !projectile.CheckSight(candidate, SF_IGNOREWATERBOUNDARY)) continue;
					best = candidate;
					bestDistance = distance;
				}
			}
			if (!best) continue;
			double speed = max(6.0, projectile.Vel.Length());
			double dx = best.Pos.x - projectile.Pos.x;
			double dy = best.Pos.y - projectile.Pos.y;
			double dz = best.Pos.z + best.Height * 0.5 - projectile.Pos.z;
			double length = max(0.001, sqrt(dx * dx + dy * dy + dz * dz));
			// Strong steering still leaves a small amount of the original motion,
			// keeping custom plasma projectiles smooth instead of snapping sideways.
			projectile.Vel = projectile.Vel * 0.35 + (dx, dy, dz) * (speed * 0.65 / length);
		}
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		InitializeMonster(e.Thing);
		ScaleSpawnedAmmo(e.Thing);
		TrackWeaponPerkProjectile(e.Thing);
		TuinWeaponTraits.Stamp(e.Thing);
	}

	override void CheckReplacement(ReplaceEvent e)
	{
        EnsureRun();
        if(Run)Run.Replace(e);
        if(e.IsFinal)return;
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
			data.LastRogueKnifePlayer = -1;
			data.LastRogueKnifeDamageTime = -1;
			data.BleedPulsesRemaining = 0;
			data.BleedPlayerNumber = -1;
			data.BleedResistanceTics = 0;
			data.BleedDamageRemaining = 0;
			data.BurnPulsesRemaining = 0;
			data.BurnPlayerNumber = -1;
			data.BurnDamageRemaining = 0;
			data.RoguePoisonPulsesRemaining = 0;
			data.RoguePoisonPlayerNumber = -1;
			data.RoguePoisonDamageRemaining = 0;
			if (e.Thing.Health > 0 && e.Thing.Health < data.ScaledMaxHealth) e.Thing.A_SetHealth(data.ScaledMaxHealth);
		}
		else InitializeMonster(e.Thing);
	}

	static int PlayerNumberFromSource(Actor source, Actor inflictor)
	{
		if (source && source.player) return source.PlayerNumber();
		if (source is 'TuinEngineerTurret' && source.master && source.master.player)
			return source.master.PlayerNumber();
		if (inflictor && inflictor.target && inflictor.target.player) return inflictor.target.PlayerNumber();
		if (inflictor is 'TuinEngineerTracer' && inflictor.master && inflictor.master.player)
			return inflictor.master.PlayerNumber();
		if (inflictor is 'TuinEngineerTracer' && inflictor.target &&
			inflictor.target.master && inflictor.target.master.player)
			return inflictor.target.master.PlayerNumber();
		return -1;
	}

	static TuinMonsterData MonsterDataFromSource(Actor source, Actor inflictor)
	{
		let data = GetMonsterData(source);
		if (!data && inflictor) data = GetMonsterData(inflictor.target);
		return data;
	}

	void SpawnDamageNumber(int playerNumber, Actor victim, int amount, bool critical, bool bleeding = false,
		int element = 0)
	{
		if (!CVInt('tuin_damage_numbers', 1) || playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS ||
			!victim || amount <= 0) return;
		// Combine damage delivered during the same short burst. A shotgun should make
		// one useful total, not cover the monster in a number for every pellet.
		for (int i = 0; i < TUIN_MAX_DAMAGE_NUMBERS; i++)
		{
			if (DamageNumberTics[i] >= TUIN_DAMAGE_NUMBER_LIFETIME - 3 &&
				DamageNumberPlayer[i] == playerNumber && DamageNumberVictim[i] == victim &&
				DamageNumberBleed[i] == bleeding && DamageNumberElement[i] == element)
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
		DamageNumberElement[slot] = element;
		DamageNumberCurl[slot] = FRandom[TuinRPGDamageNumber](-1.0, 1.0);
	}

	void ApplyRogueBleed(int playerNumber, TuinMonsterData data, int triggeringDamage,
		bool knifeHit = false, bool stealthKnife = false)
	{
		if (!data || !data.Owner || data.Owner.Health <= 0 || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS || triggeringDamage <= 0) return;
		// Bleeding cannot be refreshed or stacked. This keeps rapid-fire weapons,
		// including Tuin's Lead Spitter, from maintaining permanent percentage damage.
		// Knife strikes are the exception: every hit adds Bleed and refreshes its
		// duration, with a larger ceiling for a true stealth ambush.
		if (!knifeHit && (data.BleedPulsesRemaining > 0 || data.BleedResistanceTics > 0)) return;
		if (data.BleedPulsesRemaining <= 0) data.BleedNextTime = level.Time + 35;
		data.BleedPulsesRemaining = 8;
		data.BleedPlayerNumber = playerNumber;
		double healthCapPercent = stealthKnife ? 0.36 : 0.24;
		// Knife Bleed remains stackable on finale bosses, but cannot erase a huge
		// share of an episode-ending health pool after one short attack sequence.
		if (knifeHit && data.MonsterRarity >= 6 && IsIconicEpisodeBoss(data.Owner))
			healthCapPercent = stealthKnife ? 0.15 : 0.10;
		int healthCap = max(1, int(max(1, data.ScaledMaxHealth) * healthCapPercent + 0.5));
		if (knifeHit)
			data.BleedDamageRemaining = max(data.BleedDamageRemaining,
				min(healthCap, data.BleedDamageRemaining + triggeringDamage));
		else data.BleedDamageRemaining = min(triggeringDamage, healthCap);
		data.BleedResistanceTics = 0;
		data.LastPlayerNumber = playerNumber;
	}

	void ApplyRocketBurn(int playerNumber, TuinMonsterData data, int triggeringDamage, bool directImpact)
	{
		if (!data || !data.Owner || data.Owner.Health <= 0 || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS || triggeringDamage <= 0) return;
		double percent = directImpact ? 0.32 : 0.16;
		int addedDamage = max(1, int(triggeringDamage * percent + 0.5));
		data.BurnDamageRemaining = min(2000000000, data.BurnDamageRemaining + addedDamage);
		if (data.BurnPulsesRemaining <= 0) data.BurnNextTime = level.Time + 35;
		data.BurnPulsesRemaining = 4;
		data.BurnPlayerNumber = playerNumber;
		data.LastPlayerNumber = playerNumber;
	}

	void ApplyWeaponPerkShotgunBurn(int playerNumber, Actor primaryVictim, int triggeringDamage)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS || !primaryVictim ||
			!players[playerNumber].mo) return;
		foreach (sector: level.Sectors)
		{
			for (Actor victim = sector.thinglist; victim; victim = victim.snext)
			{
				let data = GetMonsterData(victim);
				if (!data || victim.Health <= 0 || victim.bFRIENDLY ||
					primaryVictim.Distance3D(victim) > 176.0 ||
					!primaryVictim.CheckSight(victim, SF_IGNOREWATERBOUNDARY)) continue;
				victim.GiveInventoryType('TuinShotgunBurn');
				let burn = TuinShotgunBurn(victim.FindInventory('TuinShotgunBurn'));
				if (burn) burn.Refresh(players[playerNumber].mo, triggeringDamage);
				victim.A_SpawnParticle(Color(255, 92, 12), SPF_FULLBRIGHT | SPF_FACECAMERA,
					18, 3.0, FRandom[TuinRPGDamage](0.0, 360.0), 0, 0, victim.Height * 0.45,
					0, 0, 0.3, 0, 0, 0.01, 0.70, 0.04, -0.06);
			}
		}
	}

	void ApplyWeaponPerkSuperShotgunPierce(int playerNumber, Actor primaryVictim,
		Actor source, Actor inflictor, int damage)
	{
		if (playerNumber < 0 || playerNumber >= TUIN_MAX_PLAYERS || !primaryVictim ||
			!source || damage <= 0 || WeaponPerkPierceProcTime[playerNumber] == level.Time) return;
		WeaponPerkPierceProcTime[playerNumber] = level.Time;
		double dirX = primaryVictim.Pos.x - source.Pos.x;
		double dirY = primaryVictim.Pos.y - source.Pos.y;
		double dirLength = max(0.001, sqrt(dirX * dirX + dirY * dirY));
		dirX /= dirLength;
		dirY /= dirLength;
		foreach (sector: level.Sectors)
		{
			for (Actor victim = sector.thinglist; victim; victim = victim.snext)
			{
				if (victim == primaryVictim || victim.Health <= 0 || !GetMonsterData(victim) ||
					victim.bFRIENDLY) continue;
				double dx = victim.Pos.x - primaryVictim.Pos.x;
				double dy = victim.Pos.y - primaryVictim.Pos.y;
				double forward = dx * dirX + dy * dirY;
				if (forward <= 0.0 || forward > 512.0) continue;
				double lateral = abs(dx * dirY - dy * dirX);
				if (lateral > victim.Radius + 28.0 || !primaryVictim.CheckSight(victim)) continue;
				int healthBefore = victim.Health;
				ApplyingBonusDamage = true;
				victim.DamageMobj(inflictor, source, damage, 'TuinWeaponPerkPierce', DMG_FORCED);
				ApplyingBonusDamage = false;
				int dealt = min(healthBefore, max(0, healthBefore - victim.Health));
				if (dealt > 0) SpawnDamageNumber(playerNumber, victim, dealt, false);
			}
		}
	}

	void ApplyMinigunBurn(int playerNumber, TuinMonsterData data, int triggeringDamage)
	{
		if (!data || !data.Owner || data.Owner.Health <= 0 || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS || triggeringDamage <= 0) return;
		int addedDamage = max(1, int(triggeringDamage * 0.20 + 0.5));
		data.BurnDamageRemaining = min(2000000000, data.BurnDamageRemaining + addedDamage);
		if (data.BurnPulsesRemaining <= 0) data.BurnNextTime = level.Time + 35;
		data.BurnPulsesRemaining = 4;
		data.BurnPlayerNumber = playerNumber;
		data.LastPlayerNumber = playerNumber;
	}

	void ApplyRoguePoison(int playerNumber, TuinMonsterData data, int triggeringDamage)
	{
		if (!data || !data.Owner || data.Owner.Health <= 0 || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS || triggeringDamage <= 0) return;
		double capPercent = data.MonsterRarity >= 6 ?
			(IsIconicEpisodeBoss(data.Owner) ? 0.04 : 0.08) : 0.15;
		int healthCap = max(1, int(max(1, data.ScaledMaxHealth) * capPercent + 0.5));
		int addedDamage = max(1, int(triggeringDamage * 0.50 + 0.5));
		data.RoguePoisonDamageRemaining = min(healthCap,
			data.RoguePoisonDamageRemaining + addedDamage);
		if (data.RoguePoisonPulsesRemaining <= 0) data.RoguePoisonNextTime = level.Time + 35;
		data.RoguePoisonPulsesRemaining = 6;
		data.RoguePoisonPlayerNumber = playerNumber;
		data.LastPlayerNumber = playerNumber;
	}

	void ApplyPlasmaArc(int playerNumber, Actor primaryVictim, Actor source, Actor inflictor,
		int triggeringDamage)
	{
		if (!primaryVictim || primaryVictim.Health <= 0 || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS || triggeringDamage <= 0) return;
		int arcDamage = max(1, int(triggeringDamage * 0.20 + 0.5));
		foreach (arcSector: level.Sectors)
		{
			for (Actor victim = arcSector.thinglist; victim; victim = victim.snext)
			{
				if (victim == primaryVictim || victim.Health <= 0 || !GetMonsterData(victim) ||
					victim.bFRIENDLY || primaryVictim.Distance3D(victim) > 192.0 ||
					!primaryVictim.CheckSight(victim, SF_IGNOREWATERBOUNDARY)) continue;
				int healthBefore = victim.Health;
				ApplyingBonusDamage = true;
				victim.DamageMobj(inflictor, source, arcDamage, 'TuinPlasmaArc');
				ApplyingBonusDamage = false;
				int damageDone = min(healthBefore, max(0, healthBefore - victim.Health));
				if (damageDone > 0)
				{
					SpawnDamageNumber(playerNumber, victim, damageDone, false, false, 2);
					let victimData = GetMonsterData(victim);
					if (victimData) victimData.LastPlayerNumber = playerNumber;
				}
			}
		}
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

	void UpdateMonsterBurns()
	{
		foreach (sector: level.Sectors)
		{
			for (Actor victim = sector.thinglist; victim; victim = victim.snext)
			{
				let data = GetMonsterData(victim);
				if (!data || data.BurnPulsesRemaining <= 0 || victim.Health <= 0 ||
					level.Time < data.BurnNextTime) continue;
				int attacker = data.BurnPlayerNumber;
				Actor source = attacker >= 0 && attacker < TUIN_MAX_PLAYERS && playerInGame[attacker] ?
					players[attacker].mo : null;
				int requestedDamage = max(1, (data.BurnDamageRemaining + data.BurnPulsesRemaining - 1) /
					data.BurnPulsesRemaining);
				data.BurnDamageRemaining = max(0, data.BurnDamageRemaining - requestedDamage);
				int healthBefore = victim.Health;
				ApplyingBonusDamage = true;
				victim.DamageMobj(source, source, requestedDamage, 'TuinRocketBurn');
				ApplyingBonusDamage = false;
				int damageDone = min(healthBefore, max(0, healthBefore - victim.Health));
				if (damageDone > 0) SpawnDamageNumber(attacker, victim, damageDone, false, false, 1);
				data.BurnPulsesRemaining--;
				data.BurnNextTime += 35;
				if (data.BurnPulsesRemaining <= 0 || data.BurnDamageRemaining <= 0)
				{
					data.BurnPulsesRemaining = 0;
					data.BurnPlayerNumber = -1;
					data.BurnDamageRemaining = 0;
				}
			}
		}
	}

	void UpdateMonsterRoguePoison()
	{
		foreach (sector: level.Sectors)
		{
			for (Actor victim = sector.thinglist; victim; victim = victim.snext)
			{
				let data = GetMonsterData(victim);
				if (!data || data.RoguePoisonPulsesRemaining <= 0 || victim.Health <= 0 ||
					level.Time < data.RoguePoisonNextTime) continue;
				int attacker = data.RoguePoisonPlayerNumber;
				Actor source = attacker >= 0 && attacker < TUIN_MAX_PLAYERS && playerInGame[attacker] ?
					players[attacker].mo : null;
				int requestedDamage = max(1, (data.RoguePoisonDamageRemaining +
					data.RoguePoisonPulsesRemaining - 1) / data.RoguePoisonPulsesRemaining);
				data.RoguePoisonDamageRemaining = max(0, data.RoguePoisonDamageRemaining - requestedDamage);
				int healthBefore = victim.Health;
				ApplyingBonusDamage = true;
				victim.DamageMobj(source, source, requestedDamage, 'TuinRoguePoison', DMG_FORCED);
				ApplyingBonusDamage = false;
				int damageDone = min(healthBefore, max(0, healthBefore - victim.Health));
				if (damageDone > 0) SpawnDamageNumber(attacker, victim, damageDone, false, false, 4);
				data.RoguePoisonPulsesRemaining--;
				data.RoguePoisonNextTime += 35;
				if (data.RoguePoisonPulsesRemaining <= 0 || data.RoguePoisonDamageRemaining <= 0)
				{
					data.RoguePoisonPulsesRemaining = 0;
					data.RoguePoisonPlayerNumber = -1;
					data.RoguePoisonDamageRemaining = 0;
				}
			}
		}
	}

	override void WorldThingDamaged(WorldEvent e)
	{
		if (!CVInt('tuin_enabled', 1) || !e.Thing || e.Damage <= 0) return;
		if (!ClassesEnabled() && e.Thing.player && e.DamageType == 'Poison')
		{
			int poisoned = e.Thing.PlayerNumber();
			if (poisoned >= 0 && poisoned < TUIN_MAX_PLAYERS)
			{
				if (PoisonBannerTick[poisoned] <= 0 || level.Time > PoisonBannerTick[poisoned] + 70)
					PoisonBannerStart[poisoned] = level.Time + 1;
				PoisonBannerTick[poisoned] = level.Time + 1;
				PoisonBannerDamage[poisoned] = e.Damage;
			}
		}
		int attacker = PlayerNumberFromSource(e.DamageSource, e.Inflictor);
		let victimData = GetMonsterData(e.Thing);
		if ((victimData || (e.Thing.bISMONSTER && !e.Thing.bFRIENDLY)) &&
			attacker >= 0 && attacker < TUIN_MAX_PLAYERS)
		{
			let recordData = EnsurePlayerData(attacker);
			// Damage events arrive after health changes. Reconstruct pre-hit health so
			// lethal blows count correctly without counting their overkill damage.
			if (recordData) recordData.LevelDamageDealt += min(e.Damage,
				max(0, e.Thing.Health + e.Damage));
			// Follow the monster the player actually struck. Secondary damage ticks
			// and autonomous sentries must not steal the deliberate combat target.
			if (!ApplyingBonusDamage && e.DamageType != 'TuinEngineerTurret')
			{
				LastHitTarget[attacker] = e.Thing;
				LastHitTargetTics[attacker] = TUIN_LAST_HIT_TARGET_TICS;
			}
		}
		if (victimData)
		{
			if (attacker >= 0)
			{
				victimData.LastPlayerNumber = attacker;
				if (!ApplyingBonusDamage && (e.DamageType == 'TuinRogueKnife' ||
					e.Inflictor is 'TuinRogueKnifePuff'))
				{
					victimData.LastRogueKnifePlayer = attacker;
					victimData.LastRogueKnifeDamageTime = level.Time;
				}
			}
			// A healer under fire cannot sustain itself until it has avoided damage for two seconds.
			victimData.HealerSelfLockTics = 70;
		}
		if (e.Thing.player)
		{
			int hurtPlayer = e.Thing.PlayerNumber();
			if (hurtPlayer >= 0 && hurtPlayer < TUIN_MAX_PLAYERS)
				DirectorDamageTaken[hurtPlayer] = min(1000000, DirectorDamageTaken[hurtPlayer] + e.Damage);
			if (!ClassesEnabled()) RecordPressureDamage(hurtPlayer, e.Damage);
			let hurtData = GetPlayerData(e.Thing);
			if (hurtData) hurtData.LevelDamageTaken += min(e.Damage,
				max(0, e.Thing.Health + e.Damage));
			if (hurtData) ConsumeLifeEssenceOverhealth(e.Thing, hurtData, e.Damage);
			if (hurtData && hurtData.PlayerClass == 5)
			{
				hurtData.RogueStillTics = 0;
				if (hurtData.RogueVeiled) BreakRogueVeil(hurtPlayer, hurtData);
			}
		}
		if (ApplyingBonusDamage) return;
		if (victimData && attacker >= 0 && attacker < TUIN_MAX_PLAYERS &&
			IsExecutionerJudgmentDamage(e.Inflictor, e.Thing, e.DamageType))
		{
			let judgmentData = EnsurePlayerData(attacker);
			if (judgmentData && judgmentData.PlayerClass == 3 && judgmentData.ExecutionerJudgmentArmed)
				PassExecutionerSentenceFromHit(attacker, players[attacker].mo, judgmentData, e.Thing);
		}
		double multiplier = 1.0;
		double playerBaseDamageFactor = 1.0;
		double targetBaseDamageFactor = (e.DamageFlags & DMG_FORCED) ? 1.0 :
			NativeBossResistance(e.Thing, e.Inflictor, e.DamageSource, e.DamageType);
		bool bloodPunchAttack = e.DamageType == 'TuinBloodPunch';
		bool wasCritical = false;
		bool rogueAmbushAttack = false;
		int weaponPerkFamily;
		bool weaponPerkDirectHit;
		bool rocketPerkHit;
		bool engineerTurretAttack = e.DamageType == 'TuinEngineerTurret';
		let engineerTurret = engineerTurretAttack && e.Inflictor ?
			TuinEngineerTurret(e.Inflictor.target) : null;
		int engineerCriticalBonus = engineerTurret ? engineerTurret.WeaponCriticalPercent : 0;
		// Damage callbacks occur after the engine applies the original hit.
		// Preserve the reconstructed pre-hit health for charge and leech so a
		// lethal hit still receives credit for the damage it actually dealt.
		int victimHealthBefore = max(0, e.Thing.Health + e.Damage);
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
				bool roguePistolBurst = ApplyingRoguePistolBurst && RoguePistolBurstPlayer == attacker &&
					e.DamageType == 'TuinRogueSilenced';
				Weapon attackWeapon = players[attacker].ReadyWeapon;
				if (roguePistolBurst && players[attacker].mo)
					attackWeapon = Weapon(players[attacker].mo.FindInventory('TuinRogueSilencedPistol'));
				bool rogueChainStrike = ApplyingRogueChainStrike && RogueChainStrikePlayer == attacker &&
					e.DamageType == 'TuinRogueKnife';
				weaponPerkFamily = WeaponFamily(attackWeapon);
				let rocketStamp = e.Inflictor ? TuinTraitProjectileStamp(e.Inflictor.FindInventory('TuinTraitProjectileStamp')) : null;
				rocketPerkHit = !ClassesEnabled() && (rocketStamp && rocketStamp.Initialized ? rocketStamp.RocketPerk :
					weaponPerkFamily == 8 && HasWeaponPerk(playerData, 8));
				if (rocketPerkHit) weaponPerkFamily = 8;
				if (IsBFGDamage(e.Inflictor, e.DamageSource, e.DamageType)) weaponPerkFamily = 7;
				weaponPerkDirectHit = !ClassesEnabled() && victimData && attackWeapon &&
					HasWeaponPerk(playerData, weaponPerkFamily) &&
					!IsGrenadeDamage(e.Inflictor, e.DamageType) &&
					e.DamageType != 'TuinBleed' && e.DamageType != 'TuinRocketBurn' &&
					e.DamageType != 'TuinPlasmaArc' && e.DamageType != 'TuinRoguePoison' &&
					e.DamageType != 'TuinWeaponPerkPierce';
				if (weaponPerkDirectHit)
				{
					if (weaponPerkFamily == 1) multiplier *= 2.0;
					else if (weaponPerkFamily == 2) multiplier *= 15.0;
					else if (weaponPerkFamily == 3) playerBaseDamageFactor *= 0.85;
					else if (weaponPerkFamily == 4) playerBaseDamageFactor *= 0.75;
					else if (weaponPerkFamily == 5) multiplier *= 3.0;
					else if (weaponPerkFamily == 7) playerBaseDamageFactor *= 0.25;
				}
				if (playerData.PlayerClass == 1) playerBaseDamageFactor = 1.0;
				else if (playerData.PlayerClass == 2) playerBaseDamageFactor = 0.75;
				else if (playerData.PlayerClass == 3)
				{
					multiplier *= 1.30;
					double markBonus = ExecutionerMarkedDamageBonus(playerData, victimData, e.Thing);
					if (markBonus > 0.0) multiplier *= 1.0 + markBonus;
				}
				else if (playerData.PlayerClass == 4) multiplier *= 1.10;
				else if (playerData.PlayerClass == 6 && !engineerTurretAttack)
					playerBaseDamageFactor = 0.90;
				bool firstAmbushHit = !rogueChainStrike && playerData.PlayerClass == 5 &&
					(playerData.RogueVeiled || playerData.RogueAmbushGraceTics > 0);
				bool rogueAmbush = firstAmbushHit ||
					(playerData.PlayerClass == 5 && playerData.RogueAmbushHitTime == level.Time);
				if (rogueAmbush && victimData)
				{
					rogueAmbushAttack = true;
					bool melee = IsRogueMeleeWeapon(attackWeapon);
					bool knifeAmbush = e.DamageType == 'TuinRogueKnife';
					double ambushMultiplier = knifeAmbush ? (playerData.PerkCapstone ? 16.0 : 11.0) :
						melee ? 1.0 : (playerData.PerkCapstone ? 6.0 : 4.0);
					if (victimData.MonsterRarity >= 6 && IsIconicEpisodeBoss(e.Thing))
						ambushMultiplier = min(ambushMultiplier, knifeAmbush ?
							(playerData.PerkCapstone ? 8.0 : 5.5) :
							melee ? 1.0 : (playerData.PerkCapstone ? 3.0 : 2.0));
					multiplier *= ambushMultiplier;
					wasCritical = ambushMultiplier > 1.0;
					if (playerData.RogueVeiled) BreakRogueVeil(attacker, playerData, true);
					if (firstAmbushHit)
					{
						playerData.RogueAmbushGraceTics = 0;
						playerData.RogueAmbushHitTime = level.Time;
						SetLootNotification(attacker, String.Format("AMBUSH x%.0f!", ambushMultiplier), 5);
					}
				}
				// Opening criticals belong to the Rogue weapon hit itself. Checking only
				// the equipped weapon let grenades inherit a free opening critical.
				bool rogueSilencedPistol = playerData.PlayerClass == 5 && victimData &&
					e.DamageType == 'TuinRogueSilenced';
				bool rogueKnife = playerData.PlayerClass == 5 && victimData &&
					e.DamageType == 'TuinRogueKnife';
				Actor roguePawn = players[attacker].mo;
				bool pistolUnseen = rogueSilencedPistol && roguePawn &&
					(rogueAmbushAttack || e.Thing.target != roguePawn);
				// Every ability-burst bullet is a guaranteed critical. Unlike the
				// normal pistol opener, this must not be consumed by per-target masks.
				bool openingCritical = rogueChainStrike || roguePistolBurst || pistolUnseen || rogueKnife;
				if (openingCritical && !rogueChainStrike && !roguePistolBurst)
				{
					int playerBit = 1 << attacker;
					int previousHits = rogueKnife ? victimData.RogueKnifeHitMask :
						victimData.RogueSilencedHitMask;
					openingCritical = !(previousHits & playerBit);
					if (rogueKnife) victimData.RogueKnifeHitMask |= playerBit;
					else victimData.RogueSilencedHitMask |= playerBit;
				}
				if (openingCritical && !wasCritical)
				{
					multiplier *= 2.0;
					wasCritical = true;
					CriticalPopupTics[attacker] = 18;
				}
				if (playerBaseDamageFactor < 1.0)
					e.NewDamage = max(1, int(e.Damage * playerBaseDamageFactor + 0.5));
				multiplier *= 1.0 + playerData.Strength * 0.02;
				int variantIndex = (bloodPunchAttack || engineerTurretAttack) ? -1 :
					roguePistolBurst ? playerData.FindEquippedVariant('TuinRogueSilencedPistol') :
					ActiveWeaponVariantIndex(attacker, playerData);
				if (!wasCritical && victimData && !bloodPunchAttack &&
					!IsGrenadeDamage(e.Inflictor, e.DamageType) &&
					FRandom[TuinRPGCritical](0.0, 100.0) <
					(rocketPerkHit ? 25.0 : TotalCriticalChance(playerData, variantIndex, attackWeapon) +
					engineerCriticalBonus))
				{
					multiplier *= 2.0;
					wasCritical = true;
					CriticalPopupTics[attacker] = 18;
				}
				if (wasCritical) playerData.LevelCriticalHits++;
				if (variantIndex >= 0)
				{
					multiplier *= 1.0 + WeaponItemLevelPowerPercent(playerData.VariantItemLevel[variantIndex]) * 0.01;
					if (playerData.VariantPowerPercent[variantIndex] > 0) multiplier *= 1.0 + playerData.VariantPowerPercent[variantIndex] * 0.01;
					if (playerData.VariantExecutionPercent[variantIndex] > 0 && victimData && e.Thing.Health * 100 <= victimData.ScaledMaxHealth * 30)
						multiplier *= 1.0 + playerData.VariantExecutionPercent[variantIndex] * 0.01;
				}
			}
		}
		int bonusDamage = int(e.Damage * playerBaseDamageFactor * (multiplier - 1.0) + 0.5);
		int bowHealthDamage;
		if (victimData && e.DamageType == 'TuinRogueBolt')
		{
			// Every scarce bolt removes a large share of scaled health through 10k HP.
			// Above that point, retain boss-killer growth at 30% of the original rate
			// so extreme level scaling cannot turn one bolt into several thousand damage.
			bool iconicBowTarget = IsIconicEpisodeBoss(e.Thing);
			int scaledMaximum = max(1, victimData.ScaledMaxHealth);
			double healthPercent = iconicBowTarget ? 0.05 : 0.10;
			int fullRateHealth = min(scaledMaximum, 10000);
			int softenedHealth = max(0, scaledMaximum - 10000);
			bowHealthDamage = max(1, int(fullRateHealth * healthPercent +
				softenedHealth * healthPercent * 0.30 + 0.5));
			bool upgradedBowTarget = victimData.MonsterRarity >= 2 || iconicBowTarget || e.Thing.bBOSS;
			if (upgradedBowTarget)
			{
				int strippedAffixes = victimData.AffixFlags &
					(TuinMonsterData.AFFIX_ARMORED | TuinMonsterData.AFFIX_REGENERATING |
					TuinMonsterData.AFFIX_HEALER);
				victimData.AffixFlags &= ~(TuinMonsterData.AFFIX_ARMORED |
					TuinMonsterData.AFFIX_REGENERATING | TuinMonsterData.AFFIX_HEALER);
				victimData.HealerSelfLockTics = 0;
				if (strippedAffixes && attacker >= 0)
					SetLootNotification(attacker, "DEFENSES SHATTERED", 5);
			}
		}
		if (victimData && bonusDamage > 0)
			bonusDamage = DiminishRPGBonusDamage(e.Thing, victimData, bonusDamage);
		// The bow's defining health strike is intentionally added after the generic
		// RPG burst limiter so its health strike remains dependable per bolt.
		bonusDamage += bowHealthDamage;
		// Lost Souls and locally dense crowds are treated as fodder. Apply their
		// vulnerability after the RPG bonus limiter so rarity can never erase the
		// intended 50% weakness.
		if (victimData && attacker >= 0 && HasFodderDebuff(e.Thing))
		{
			int damageBeforeWeakness = max(1, int(e.Damage * playerBaseDamageFactor + 0.5)) +
				max(0, bonusDamage);
			bonusDamage += max(1, int(damageBeforeWeakness * 0.50 + 0.5));
		}
		// Giant Slayer removes a visible share of a 2500+ HP target's scaled health.
		// A short per-player, per-target window groups pellets, BFG tracers and rapid
		// fire so one attack cannot apply the complete percentage dozens of times.
		bool giantSlayerFollowup = e.DamageType == 'TuinBleed' ||
			e.DamageType == 'TuinRoguePoison' || e.DamageType == 'TuinRocketBurn' ||
			e.DamageType == 'TuinPlasmaArc';
		if (victimData && attacker >= 0 && attacker < TUIN_MAX_PLAYERS &&
			victimData.ScaledMaxHealth >= 2500 && !giantSlayerFollowup)
		{
			let giantData = EnsurePlayerData(attacker);
			int giantRank = giantData ? clamp(giantData.PerkGiantSlayer, 0, 3) : 0;
			if (giantRank > 0 && victimData.GiantSlayerWindowEndTime[attacker] <= level.Time)
			{
				victimData.GiantSlayerWindowEndTime[attacker] = level.Time + 18;
				bonusDamage += max(1, int(victimData.ScaledMaxHealth * giantRank * 0.005 + 0.5));
			}
		}
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
			if (weaponPerkDirectHit && weaponPerkFamily == 2 && players[attacker].mo &&
				players[attacker].mo.Health > 1)
			{
				Actor fistUser = players[attacker].mo;
				int selfDamage = max(1, int(fistUser.GetMaxHealth(true) * 0.05 + 0.5));
				ApplyingBonusDamage = true;
				fistUser.DamageMobj(fistUser, fistUser, selfDamage, 'TuinWeaponPerkFist', DMG_FORCED);
				ApplyingBonusDamage = false;
			}
			else if (weaponPerkDirectHit && weaponPerkFamily == 3)
				ApplyWeaponPerkShotgunBurn(attacker, e.Thing, totalDamage);
			else if (weaponPerkDirectHit && weaponPerkFamily == 4)
				ApplyWeaponPerkSuperShotgunPierce(attacker, e.Thing, e.DamageSource,
					e.Inflictor, max(1, totalDamage));
			if (rocketPerkHit && wasCritical && e.Thing.Health > 0)
			{
				e.Thing.GiveInventoryType('TuinHellfireBurn');
				let burn = TuinHellfireBurn(e.Thing.FindInventory('TuinHellfireBurn'));
				if (burn) burn.AddStack(players[attacker].mo, totalDamage);
			}
			if (ClassesEnabled() && !rocketPerkHit && IsPlayerRocketDamage(e.Inflictor, e.DamageType))
				ApplyRocketBurn(attacker, victimData, totalDamage,
					RocketHitWasDirect(e.Inflictor, e.Thing));
			else if (IsMinigunExplosiveDamage(e.Inflictor, e.DamageType))
				ApplyMinigunBurn(attacker, victimData, totalDamage);
			else if (IsPlayerPlasmaDamage(e.Inflictor))
				ApplyPlasmaArc(attacker, e.Thing, e.DamageSource, e.Inflictor, totalDamage);
			if (e.DamageType == 'TuinRogueBolt')
				ApplyRoguePoison(attacker, victimData, totalDamage);
			let attackData = EnsurePlayerData(attacker);
			bool roguePistolBurst = ApplyingRoguePistolBurst && RoguePistolBurstPlayer == attacker &&
				e.DamageType == 'TuinRogueSilenced';
			Weapon chargeWeapon = roguePistolBurst && players[attacker].mo ?
				Weapon(players[attacker].mo.FindInventory('TuinRogueSilencedPistol')) :
				players[attacker].ReadyWeapon;
			bool weaponChargeDamage = chargeWeapon && !IsGrenadeDamage(e.Inflictor, e.DamageType) &&
				e.DamageType != 'TuinBleed' && e.DamageType != 'TuinRocketBurn' &&
				e.DamageType != 'TuinPlasmaArc' && e.DamageType != 'TuinRoguePoison';
			bool rogueChainStrike = ApplyingRogueChainStrike && RogueChainStrikePlayer == attacker &&
				e.DamageType == 'TuinRogueKnife';
			if (attackData && attackData.PlayerClass == 5 && !rogueAmbushAttack &&
				!rogueChainStrike && weaponChargeDamage)
			{
				int rogueChargeDamage = min(totalDamage, max(0, victimHealthBefore));
				if (e.DamageType == 'TuinRogueBolt') rogueChargeDamage *= 3;
				AddRogueDamageCharge(attacker, attackData, rogueChargeDamage);
			}
			if (attackData && attackData.PlayerClass == 1 && !attackData.TankOverdriveActive)
				AddTankDamageCharge(attacker, attackData, min(totalDamage, max(0, victimHealthBefore)));
			if (attackData && attackData.PlayerClass == 1)
				ReduceHeavyRadioCooldown(attacker, attackData,
					min(totalDamage, max(0, victimHealthBefore)));
			if (attackData && attackData.PlayerClass == 3)
				AddExecutionerDamageCharge(attacker, attackData,
					min(totalDamage, max(0, victimHealthBefore)));
			if (attackData && attackData.PlayerClass == 4 && !bloodPunchAttack)
				AddDoomBloodPunchCharge(attacker, attackData, min(totalDamage, max(0, victimHealthBefore)));
			int attackVariant = attackData ? (roguePistolBurst ?
				attackData.FindEquippedVariant('TuinRogueSilencedPistol') :
				ActiveWeaponVariantIndex(attacker, attackData)) : -1;
			bool leadSpitterCritical = attackVariant >= 0 &&
				attackData.VariantQuality[attackVariant] == TUIN_LEAD_SPITTER_QUALITY;
			bool rogueKnifeDamage = attackData && attackData.PlayerClass == 5 &&
				e.DamageType == 'TuinRogueKnife';
			if (attackData && e.Thing.Health > 0 &&
				((wasCritical && (attackData.PlayerClass == 5 || leadSpitterCritical)) || rogueKnifeDamage))
			{
				int bleedTriggerDamage = totalDamage;
				if (rogueKnifeDamage)
					bleedTriggerDamage *= rogueAmbushAttack ? 4 : 2;
				ApplyRogueBleed(attacker, victimData, bleedTriggerDamage,
					rogueKnifeDamage, rogueKnifeDamage && rogueAmbushAttack);
			}
			// Accumulate fractional leech instead of rounding every small hit down
			// to zero. This makes bullets, pellets, and special weapons leech just
			// as reliably as rockets without granting one full HP per rapid hit.
			int leechPercent = attackData ? attackData.PerkBloodDrinker : 0;
			if (attackData && attackVariant >= 0)
				leechPercent += attackData.VariantLeechPercent[attackVariant];
			Actor leechPlayer = players[attacker].mo;
			if (attackData && leechPercent > 0 && leechPlayer && leechPlayer.Health > 0)
			{
				int maximumHealth = leechPlayer.GetMaxHealth(true);
				if (leechPlayer.Health >= maximumHealth) attackData.LeechHealingRemainder = 0.0;
				else
				{
					int damageDone = min(totalDamage, victimHealthBefore);
					double exactHealing = damageDone * leechPercent * 0.01 +
						attackData.LeechHealingRemainder;
					int healing = int(exactHealing);
					attackData.LeechHealingRemainder = exactHealing - healing;
					if (healing > 0)
						leechPlayer.A_SetHealth(min(maximumHealth, leechPlayer.Health + healing));
				}
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
		data.LevelXPEarned += max(0, amount);
		data.CurrentXP += amount;
		PopupXP[playerNumber] += amount;
		PopupTics[playerNumber] = 70;
		while (data.CurrentXP >= XPRequired(data.PlayerLevel))
		{
			data.CurrentXP -= XPRequired(data.PlayerLevel);
			data.PlayerLevel++;
			if (data.PlayerLevel == 15) AnnounceHeavyMilestone(playerNumber);
			data.UnspentStatPoints++;
			int gainedPerks = PerkPointsAtLevel(data.PlayerLevel);
			data.UnspentSkillPoints += gainedPerks;
			AnnouncePoints(playerNumber, 1, gainedPerks, 0);
			int gainedWeaponPerks = SyncWeaponPerkMilestones(data);
			if (players[playerNumber].mo)
			{
				if (gainedPerks > 0 || gainedWeaponPerks > 0)
					players[playerNumber].mo.A_Log(String.Format(
						"LEVEL UP! Level %d. +1 stat, +%d perk, +%d weapon perk point%s",
						data.PlayerLevel, gainedPerks, gainedWeaponPerks,
						gainedWeaponPerks == 1 ? "" : "s"));
				else players[playerNumber].mo.A_Log(String.Format(
					"LEVEL UP! You are now level %d. +1 stat point", data.PlayerLevel));
			}
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
			if (data.PlayerLevel == 15) AnnounceHeavyMilestone(playerNumber);
			data.UnspentStatPoints++;
			data.UnspentSkillPoints += PerkPointsAtLevel(data.PlayerLevel);
			AnnouncePoints(playerNumber, 1, PerkPointsAtLevel(data.PlayerLevel), 0);
			SyncWeaponPerkMilestones(data);
		}
		if (players[playerNumber].mo)
			players[playerNumber].mo.A_Log(String.Format("TEST CHEAT: gained %d level%s. Now level %d with %d stat, %d perk and %d weapon perk points.",
				amount, amount == 1 ? "" : "s", data.PlayerLevel, data.UnspentStatPoints,
				data.UnspentSkillPoints, data.UnspentWeaponPerkPoints));
	}

	void TriggerFinalVerdict(int playerNumber, Actor corpse, TuinMonsterData corpseData,
		TuinPlayerData playerData, int markSlot)
	{
		if (!corpse || !corpseData || !playerData || playerNumber < 0 ||
			playerNumber >= TUIN_MAX_PLAYERS) return;
		Actor source = playerInGame[playerNumber] ? players[playerNumber].mo : null;
		bool ultimate = playerData.PerkCapstone;
		double radius = FinalVerdictRadius(playerData);
		int explosionDamage = FinalVerdictDamage(corpseData, playerData);

		ClearExecutionerMarkSlot(playerNumber, playerData, markSlot);
		bool refunded;
		if (ultimate && !playerData.ExecutionerRefundGranted)
		{
			playerData.ExecutionerCharge = min(100, playerData.ExecutionerCharge + 25);
			playerData.ExecutionerChargeRemainder = 0.0;
			playerData.ExecutionerReadyNotified = false;
			playerData.ExecutionerRefundGranted = true;
			refunded = true;
		}
		Actor.Spawn('PSQuickGrenadeExplosionFX', corpse.Pos + (0, 0, 8), NO_REPLACE);
		corpse.A_StartSound("psgrenade/explode", CHAN_BODY);
		corpse.A_StartSound("psgrenade/explode_distant", CHAN_5);
		corpse.A_QuakeEx(5, 5, 5, 18, 0, 1000, "", QF_SCALEDOWN);

		foreach (verdictSector: level.Sectors)
		{
			for (Actor victim = verdictSector.thinglist; victim; victim = victim.snext)
			{
				let victimData = GetMonsterData(victim);
				if (!victimData || victim == corpse || victim.Health <= 0 || victim.bFRIENDLY ||
					corpse.Distance3D(victim) > radius ||
					!corpse.CheckSight(victim, SF_IGNOREWATERBOUNDARY)) continue;
				int healthBefore = victim.Health;
				ApplyingBonusDamage = true;
				victim.DamageMobj(source, source, explosionDamage, 'TuinFinalVerdict');
				ApplyingBonusDamage = false;
				int damageDone = min(healthBefore, max(0, healthBefore - victim.Health));
				if (damageDone > 0)
				{
					victimData.LastPlayerNumber = playerNumber;
					SpawnDamageNumber(playerNumber, victim, damageDone, false, false, 3);
				}
			}
		}
		SetLootNotification(playerNumber, refunded ?
			"FINAL VERDICT - 25% JUDGMENT REFUNDED" : "FINAL VERDICT", 5);
	}

	double FinalVerdictRadius(TuinPlayerData playerData)
	{
		return playerData && playerData.PerkCapstone ? 224.0 : 160.0;
	}

	int FinalVerdictDamage(TuinMonsterData corpseData, TuinPlayerData playerData)
	{
		bool ultimate = playerData && playerData.PerkCapstone;
		int scaledHealth = corpseData ? max(1, corpseData.ScaledMaxHealth) : 1;
		return clamp(int(scaledHealth * (ultimate ? 0.25 : 0.18) + 0.5),
			ultimate ? 60 : 40, ultimate ? 600 : 400);
	}

	override void WorldThingDied(WorldEvent e)
	{
        if(e.Thing && e.Thing.player)
        {
            EnsureRun();
            if(Run)Run.Finish(GetPlayerData(e.Thing));
        }
		let data = GetMonsterData(e.Thing);
		if (!data) return;
		// WorldThingDied does not populate DamageSource/DamageType in UZDoom.
		if (data.MonsterRarity >= 6) AnnounceMilestone(false);
		// The passive damage hook records the lethal hit before this event fires.
		if (data.TraitKillTime == level.Time)
			TuinWeaponTraits.Kill(data, data.TraitKillSource, data.TraitKillDamageType);
		e.Thing.A_RemoveLight('TuinSignatureTell');
		int killer = PlayerNumberFromSource(e.DamageSource, e.Inflictor);
		if (killer < 0) killer = data.LastPlayerNumber;
        if(TuinRun.Active() && killer>=0 && killer<TUIN_MAX_PLAYERS && e.Thing.bCOUNTKILL)
        {
            let runData=GetPlayerData(players[killer].mo);
            if(runData && runData.RunActive && !runData.RunEnded)
                runData.RunScore+=10+data.MonsterRarity*10;
        }
		RecordPressureKill(killer, e.Thing, data);
		if (data.MonsterRarity >= 6 && killer < 0)
		{
			for (int i = 0; i < TUIN_MAX_PLAYERS; i++)
				if (playerInGame[i] && players[i].mo) { killer = i; break; }
		}
		if (data.MonsterRarity >= 6 && !IsIconicEpisodeBoss(e.Thing))
		{
			for (int listener = 0; listener < TUIN_MAX_PLAYERS; listener++)
				if (playerInGame[listener] && players[listener].mo)
					players[listener].mo.A_StartSound("tuin/boss/down", CHAN_AUTO,
						CHANF_LOCAL | CHANF_UI, 0.85, ATTN_NONE);
		}
		for (int markedPlayer = 0; markedPlayer < TUIN_MAX_PLAYERS; markedPlayer++)
		{
			if (!playerInGame[markedPlayer] || !players[markedPlayer].mo) continue;
			let executionerData = GetPlayerData(players[markedPlayer].mo);
			int markSlot = ExecutionerMarkSlotForTarget(executionerData, e.Thing);
			if (!executionerData || markSlot < 0) continue;
			bool sentencedKill = executionerData.PlayerClass == 3 &&
				ExecutionerMarkTime(executionerData, markSlot) > 0 && killer == markedPlayer;
			if (sentencedKill) TriggerFinalVerdict(markedPlayer, e.Thing, data, executionerData, markSlot);
			else ClearExecutionerMarkSlot(markedPlayer, executionerData, markSlot);
		}
		int xpAward = data.XPValue;
		if (killer >= 0)
		{
			let playerData = EnsurePlayerData(killer);
			if (playerData)
			{
				if (playerData.PlayerClass == 4 && playerData.DoomFatalityCooldownTics > 0 &&
					e.DamageType != 'TuinDoomFatality')
					playerData.DoomFatalityCooldownTics =
						max(0, playerData.DoomFatalityCooldownTics - 5 * 35);
				bool knifeKill = e.DamageType == 'TuinRogueKnife' ||
					e.Inflictor is 'TuinRogueKnifePuff' ||
					(data.LastRogueKnifePlayer == killer && data.LastRogueKnifeDamageTime == level.Time);
				if (playerData.PlayerClass == 5 && knifeKill &&
					!playerData.RogueChainActive)
				{
					playerData.RogueChainCharges = min(9, playerData.RogueChainCharges + 1);
					SetLootNotification(killer, String.Format("CHAIN ASSASSINATION %d / 9 - PRESS B",
						playerData.RogueChainCharges), 5);
				}
				if (data.MonsterRarity >= 6) playerData.LevelBossKills++;
				else if (data.MonsterRarity >= 2) playerData.LevelEliteKills++;
				if (playerData.PlayerClass == 6)
				{
					double fabrication = 5.0 + clamp(data.MonsterLevel / 5, 0, 10) +
						min(20, data.MonsterRarity * 3);
					AddEngineerFabrication(killer, playerData, fabrication);
				}
			}
			int variantIndex = e.DamageType == 'TuinEngineerTurret' ? -1 :
				ActiveWeaponVariantIndex(killer, playerData);
			if (variantIndex >= 0)
				xpAward = int(xpAward * (1.0 + playerData.VariantProsperityPercent[variantIndex] * 0.01) + 0.5);
			AwardXP(killer, xpAward);
			TryDropWeapon(e.Thing, data, killer);
			TuinRustSupport.DropFuel(e.Thing, players[killer].mo);
			TryDropRogueBolts(e.Thing, killer, data);
		}
		SpawnCoinReward(e.Thing, data);
		TryDropExtraLife(e.Thing, data);
		TryDropLifeEssence(e.Thing);
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
			Actor.Spawn('PSQuickGrenadeExplosionFX', e.Thing.Pos + (0, 0, 8), NO_REPLACE);
			e.Thing.A_StartSound("psgrenade/explode", CHAN_BODY);
			e.Thing.A_StartSound("psgrenade/explode_distant", CHAN_5);
			e.Thing.A_QuakeEx(3, 3, 3, 12, 0, 640, "", QF_SCALEDOWN);

			// Damage nearby players and hostile monsters directly while the corpse
			// is still valid. This remains reliable with custom monster death states.
			foreach (blastSector: level.Sectors)
			{
				for (Actor blastVictim = blastSector.thinglist; blastVictim; blastVictim = blastVictim.snext)
				{
					if (blastVictim == e.Thing || blastVictim.Health <= 0 || !blastVictim.bSHOOTABLE ||
						(!blastVictim.player && (!blastVictim.bISMONSTER || blastVictim.bFRIENDLY))) continue;
					double distance = e.Thing.Distance3D(blastVictim);
					if (distance > radius || !e.Thing.CheckSight(blastVictim, SF_IGNOREWATERBOUNDARY)) continue;
					double fraction = clamp(1.0 - distance / radius, 0.0, 1.0);
					int dealtDamage = max(1, int(explosionDamage * (0.35 + fraction * 0.65) + 0.5));
					blastVictim.DamageMobj(e.Thing, e.Thing, dealtDamage, 'Fire');
				}
			}
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
		TargetDeathSentence[playerNumber] = false;
		TargetIsBoss[playerNumber] = false;
		int healthBarMode = CVInt('tuin_healthbar_mode', 1);
		if (!CVInt('tuin_enabled', 1) || healthBarMode == 3 || !playerInGame[playerNumber]) return;
		Actor pawn = players[playerNumber].mo;
		if (!pawn || pawn.Health <= 0) return;
		if (LastHitTargetTics[playerNumber] > 0) LastHitTargetTics[playerNumber]--;
		Actor target = LastHitTarget[playerNumber];
		if (!target || LastHitTargetTics[playerNumber] <= 0)
		{
			LastHitTarget[playerNumber] = null;
			return;
		}
		let data = GetMonsterData(target);
		if (!data || target.bFRIENDLY)
		{
			LastHitTarget[playerNumber] = null;
			LastHitTargetTics[playerNumber] = 0;
			return;
		}
		TargetName[playerNumber] = data.GeneratedName.Length() ? data.GeneratedName : target.GetTag(target.GetClassName());
		TargetAffixes[playerNumber] = AffixList(data);
		let playerData = GetPlayerData(pawn);
		if (playerData && playerData.PlayerClass == 3 &&
			ExecutionerMarkSlotForTarget(playerData, target) >= 0)
		{
			TargetDeathSentence[playerNumber] = true;
			TargetAffixes[playerNumber].AppendFormat("%sDEATH SENTENCE",
				TargetAffixes[playerNumber].Length() ? "  |  " : "");
		}
		TargetHealth[playerNumber] = max(0, target.Health);
		TargetMaxHealth[playerNumber] = max(1, data.ScaledMaxHealth);
		TargetPreviousDisplayHealth[playerNumber] = data.PreviousDisplayHealth;
		TargetDisplayHealth[playerNumber] = data.DisplayHealth;
		TargetLevel[playerNumber] = data.MonsterLevel;
		TargetRarity[playerNumber] = data.MonsterRarity;
		TargetIsBoss[playerNumber] = data.MonsterRarity >= 6 || target is 'Cyberdemon' ||
			target is 'SpiderMastermind' || IsIconicEpisodeBoss(target);
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
		if (!weapon || !psp || !psp.CurState || psp.Tics <= 0)
		{
			RustChargeState[playerNumber] = null;
			WeaponSwitchAccumulator[playerNumber] = 0.0;
			return;
		}

		State select = weapon.GetUpState();
		State deselect = weapon.GetDownState();
		bool switching = (select && psp.CurState.InStateSequence(select)) ||
			(deselect && psp.CurState.InStateSequence(deselect));
		if (switching)
		{
			RustChargeState[playerNumber] = null;
			// The shared baseline is twice normal speed. Rogue gets four extra
			// state steps per tick for a near-instant five-times-speed swap.
			double switchBonus = data.PlayerClass == 5 ? 4.0 : 1.0;
			WeaponSwitchAccumulator[playerNumber] += switchBonus;
			int switchSteps = 0;
			while (WeaponSwitchAccumulator[playerNumber] >= 1.0 && switchSteps < 5 && psp.CurState && psp.Tics > 0)
			{
				bool stillSwitching = (select && psp.CurState.InStateSequence(select)) ||
					(deselect && psp.CurState.InStateSequence(deselect));
				if (!stillSwitching) break;
				WeaponSwitchAccumulator[playerNumber] -= 1.0;
				psp.Tics--;
				if (psp.Tics == 0) psp.SetState(psp.CurState.NextState);
				switchSteps++;
			}
			return;
		}
		WeaponSwitchAccumulator[playerNumber] = 0.0;

		State fire = weapon.FindState('Fire');
		// Native Calamity charges are five 20-tic states. Add six tics once
		// per stage, without slowing equip, recovery, or other weapons.
		if (HasWeaponPerk(data, 10) && WeaponFamily(weapon) == 10 &&
			TuinRustSupport.IsChargeState(weapon, psp.CurState))
		{
			if (RustChargeState[playerNumber] != psp.CurState) psp.Tics += 6;
			RustChargeState[playerNumber] = psp.CurState;
			return;
		}
		RustChargeState[playerNumber] = null;
		State hold = weapon.FindState('Hold');
		State altFire = weapon.FindState('AltFire');
		State altHold = weapon.FindState('AltHold');
		bool firing = (fire && psp.CurState.InStateSequence(fire)) ||
			(hold && psp.CurState.InStateSequence(hold)) ||
			(altFire && psp.CurState.InStateSequence(altFire)) ||
			(altHold && psp.CurState.InStateSequence(altHold));
		if (!firing) return;
		int weaponFamily = WeaponFamily(weapon);
		double traitHaste = players[playerNumber].mo && players[playerNumber].mo.Health * 100 <
			players[playerNumber].mo.GetMaxHealth(true) * 30 ? TuinWeaponTraits.Strength(data, 8) * 0.05 : 0.0;
		if (!ClassesEnabled() && HasWeaponPerk(data, 1) && weaponFamily == 1)
		{
			// Repeat every other engine tick, doubling the time spent in firing
			// states without changing the external weapon's own state graph.
			if ((level.Time & 1) == 0 && psp.Tics > 0) psp.Tics++;
			AgilityAccumulator[playerNumber] += traitHaste * 0.5;
			if (AgilityAccumulator[playerNumber] >= 1.0 && psp.CurState && psp.Tics > 0)
			{
				AgilityAccumulator[playerNumber] -= 1.0;
				psp.Tics--;
				if (psp.Tics == 0) psp.SetState(psp.CurState.NextState);
			}
			return;
		}
		if (!ClassesEnabled() && HasWeaponPerk(data, 7) && weaponFamily == 7)
		{
			AgilityAccumulator[playerNumber] += traitHaste * 4.0;
			int rapidSteps = 3 + int(AgilityAccumulator[playerNumber]);
			AgilityAccumulator[playerNumber] -= int(AgilityAccumulator[playerNumber]);
			for (int rapidStep = 0; rapidStep < rapidSteps && psp.CurState && psp.Tics > 0; rapidStep++)
			{
				psp.Tics--;
				if (psp.Tics == 0) psp.SetState(psp.CurState.NextState);
			}
			return;
		}

		double speedBonus = data.Agility * 0.02 + traitHaste;
		int variantIndex = data.FindEquippedVariant((class<Weapon>)(weapon.GetClass()));
		if (variantIndex >= 0) speedBonus += data.VariantHastePercent[variantIndex] * 0.01;
		bool rogueKnife = data.PlayerClass == 5 && weapon.GetClassName() == 'TuinRogueKnife';
		if (rogueKnife) speedBonus += clamp(data.PerkClassMastery, 0, 3) * 0.25;
		if (data.PlayerClass == 1 && data.TankOverdriveActive) speedBonus += 0.50;
		// The engine power doubles every weapon state, including one-tic rocket states.
		// This manual remainder supplies the other +50%; gear may raise the combined ceiling to +200%.
		double speedCap = data.PlayerClass == 1 && data.TankOverdriveActive ? 1.0 :
			rogueKnife ? 1.50 : 0.75;
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
		WeaponPickupInReach[playerNumber] = false;
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
		let pickupTarget = TargetWeaponDrop[playerNumber];
		WeaponPickupInReach[playerNumber] = pickupTarget && pawn.Distance3D(pickupTarget) <= 128.0 && pawn.CheckSight(pickupTarget);
	}

	void UpdateWeaponPickupHold(int playerNumber, bool useDown, bool otherInteraction)
	{
		if (!useDown)
		{
			WeaponPickupHold[playerNumber] = 0;
			WeaponPickupTarget[playerNumber] = null;
			WeaponPickupConsumed[playerNumber] = false;
			return;
		}
		Actor pawn = players[playerNumber].mo;
		let drop = TargetWeaponDrop[playerNumber];
		bool valid = pawn && pawn.Health > 0 && drop && pawn.Distance3D(drop) <= 128.0 && pawn.CheckSight(drop);
		if (otherInteraction || !valid || (WeaponPickupTarget[playerNumber] && WeaponPickupTarget[playerNumber] != drop))
		{
			WeaponPickupHold[playerNumber] = 0;
			WeaponPickupTarget[playerNumber] = null;
			WeaponPickupConsumed[playerNumber] = true;
			return;
		}
		if (WeaponPickupConsumed[playerNumber]) return;
		WeaponPickupTarget[playerNumber] = drop;
		WeaponPickupHold[playerNumber]++;
		if (WeaponPickupHold[playerNumber] >= WEAPON_PICKUP_HOLD_TICS)
		{
			// One pickup per press: a newly dropped old variant cannot chain-swap back.
			WeaponPickupConsumed[playerNumber] = true;
			WeaponPickupHold[playerNumber] = 0;
			WeaponPickupTarget[playerNumber] = null;
			TryCollectWeaponDrop(playerNumber);
		}
	}
	void TryCollectWeaponDrop(int playerNumber)
	{
		let lootDrop = TargetWeaponDrop[playerNumber];
		Actor pawn = players[playerNumber].mo;
		if (!lootDrop || !pawn || pawn.Distance3D(lootDrop) > 128.0) return;
		lootDrop.WeaponType = TuinRustSupport.Resolve(lootDrop.WeaponType);
		let data = EnsurePlayerData(playerNumber);
		if (!data) return;
		if (IsRogueOnlyWeaponType(lootDrop.WeaponType) && data.PlayerClass != 5)
		{
			SetLootNotification(playerNumber, ClassesEnabled() ? "ROGUE CLASS ONLY" : "UNAVAILABLE IN UNIVERSAL BUILD", 0);
			pawn.A_StartSound("weapons/noammo", CHAN_ITEM, CHANF_MAYBE_LOCAL, 0.65, ATTN_NONE);
			return;
		}
		if (IsDoomGuyOnlyWeaponType(lootDrop.WeaponType) && data.PlayerClass != 4)
		{
			SetLootNotification(playerNumber, ClassesEnabled() ? "DOOM GUY CLASS ONLY" : "UNAVAILABLE IN UNIVERSAL BUILD", 0);
			pawn.A_StartSound("weapons/noammo", CHAN_ITEM, CHANF_MAYBE_LOCAL, 0.65, ATTN_NONE);
			return;
		}
		if (IsHeavyOnlyWeaponType(lootDrop.WeaponType) && data.PlayerClass != 1)
		{
			SetLootNotification(playerNumber, ClassesEnabled() ? "HEAVY CLASS ONLY" : "UNAVAILABLE IN UNIVERSAL BUILD", 0);
			pawn.A_StartSound("weapons/noammo", CHAN_ITEM, CHANF_MAYBE_LOCAL, 0.65, ATTN_NONE);
			return;
		}
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
        EnsureRun();
        if(Run && Run.Tick(self))return;
        EnsureLocator();
        if (Locator) Locator.TickLocator();
		UpdateGrenadeBossDamage();
		UpdateWeaponPerkProjectiles();
		UpdateJohnMilestoneComments();
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
            if(!ClassesEnabled()) RerollLivingMonsters(consoleplayer,true);
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
		if ((level.Time % 7) == 0)
		{
			UpdateMonsterBleeds();
			UpdateMonsterBurns();
			UpdateMonsterRoguePoison();
		}
		if (EpisodeTravelTics > 0)
		{
			EpisodeTravelTics--;
			if (EpisodeTravelTics == 0 && EpisodeTravelDestination.Length())
			{
				string destination = EpisodeTravelDestination;
				let runData=GetPlayerData(players[consoleplayer].mo);
				if(TuinRun.Active() && runData && runData.RunNextMap.Length())destination=runData.RunNextMap;
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
			UpdatePointReminder(i, playerData);
			UpdateKeyNotice(i, players[i].mo);
			if (ClassesEnabled() && playerData && playerData.PlayerClass != 0 && !playerData.FreeClassChoiceRefunded)
			{
				playerData.FreeClassChoiceRefunded = true;
				playerData.UnspentSkillPoints++;
				SetLootNotification(i, "FREE CLASS CHOICE: 1 PERK POINT REFUNDED", 4);
			}
			if (ClassesEnabled() && playerData && playerData.PlayerClass == 0 && players[i].mo &&
				level.Time >= 10 && !InitialClassMenuRequested[i])
			{
				InitialClassMenuRequested[i] = true;
				EventHandler.SendInterfaceEvent(i, "tuin_open_class_choice");
			}
			// Existing Doom Guy saves predate the class weapon. Grant it once when
			// their persistent class data reaches a live pawn.
			if (playerData && playerData.PlayerClass == 4 && players[i].mo && !playerData.DoomQuadInitialized)
			{
				if (!players[i].mo.FindInventory('TuinDoomGuyQuadShotgun'))
					players[i].mo.GiveInventory('TuinDoomGuyQuadShotgun', 1);
				players[i].mo.GiveInventory('TuinDoomGuyQuadLoaded', 4);
				playerData.DoomQuadInitialized = true;
			}
			if (playerData && playerData.LifeRevivePending) UpdateLifeRevive(i, players[i].mo, playerData);
			if (playerData && playerData.LifeGraceTics > 0) playerData.LifeGraceTics--;
			if (playerData && playerData.LifeReviveFadeTics > 0) playerData.LifeReviveFadeTics--;
			if (JohnCommentTics[i] > 0) JohnCommentTics[i]--;
			if ((level.Time % 35) == 0) ApplyAmmoCapacity(players[i].mo, playerData);
			ApplyWeaponPerkAmmoUse(i, players[i].mo, playerData);
			TuinWeaponTraits.Tick(playerData);
			if ((level.Time % 35) == 1) TuinRustSupport.MigratePlayer(players[i].mo, playerData);
			ApplyClassAmmoBonus(players[i].mo, playerData);
			ApplyClassRegeneration(i, players[i].mo, playerData);
			UpdateEngineerSentries(i, players[i].mo, playerData);
			UpdateEngineerAmmoFabrication(i, players[i].mo, playerData);
			UpdateLifeEssenceOverhealth(players[i].mo, playerData);
			ApplyRogueStealth(i, players[i].mo, playerData);
			UpdateRogueChain(i, players[i].mo, playerData);
			UpdateRoguePistolBurst(i, players[i].mo, playerData);
			if (RoguePistolBurstTestPending[i] && playerData && players[i].ReadyWeapon is 'TuinRogueKnife')
			{
				RoguePistolBurstTestPending[i] = false;
				BeginRoguePistolBurstHold(i, players[i].mo, playerData);
				RoguePistolBurstTestReleaseTics[i] = 6;
			}
			else if (RoguePistolBurstTestReleaseTics[i] > 0 && playerData)
			{
				RoguePistolBurstTestReleaseTics[i]--;
				if (RoguePistolBurstTestReleaseTics[i] == 0)
					ReleaseRoguePistolBurst(players[i].mo, playerData);
			}
			else if (RoguePistolBurstTestTarget[i] && playerData && !RoguePistolBurstTestPending[i] &&
				playerData.RoguePistolBurstShotsRemaining <= 0)
			{
				players[i].mo.A_Log(String.Format(
					"ROGUE BURST RESULT: %d DAMAGE, %d BULLETS, %.1f SEC COOLDOWN.",
					max(0, RoguePistolBurstTestHealth[i] - max(0, RoguePistolBurstTestTarget[i].Health)),
					Ammo(players[i].mo.FindInventory('Clip')).Amount,
					playerData.RoguePistolBurstCooldownTics / 35.0));
				RoguePistolBurstTestTarget[i] = null;
			}
			ApplyTankOverdrive(i, players[i].mo, playerData);
			ApplyHeavyMovement(players[i].mo, playerData);
			UpdateHeavyRadio(i, players[i].mo, playerData);
			ApplyExecutionerDeathSentence(i, players[i].mo, playerData);
			ApplyDoomFatality(i, players[i].mo, playerData);
			ApplyDoomBloodPunch(i, players[i].mo, playerData);
			ApplyFlashlight(players[i].mo, playerData);
			ApplyHeldGodlyGlow(i, playerData);
			ApplyAgility(i, playerData);
			UpdateWeaponDropTarget(i);
			bool useDown = (players[i].cmd.buttons & BT_USE) != 0;
			bool otherUse = false;
			if (useDown && !UseHeld[i])
				otherUse = TryOpenBossChest(i) || TryOpenJohnShop(i);
			if (!ClassesEnabled()) UpdateWeaponPickupHold(i, useDown, otherUse);
			else if (useDown && !UseHeld[i] && !otherUse) TryCollectWeaponDrop(i);
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
			// A fresh map can tick once before the player pawn and its persistent RPG
			// token are ready. Do not consume the one-shot rarity pass at level 1 in
			// that gap; retry after catch-up or carried progression becomes visible.
			bool playerProgressReady;
			for (int progressPlayer = 0; progressPlayer < TUIN_MAX_PLAYERS; progressPlayer++)
			{
				if (playerInGame[progressPlayer] && players[progressPlayer].mo &&
					GetPlayerData(players[progressPlayer].mo))
				{
					playerProgressReady = true;
					break;
				}
			}
			// Map actors can finish reporting WorldThingSpawned over the opening
			// ticks. Ten tics keeps the pass before meaningful play while ensuring
			// the complete dormant and active roster has RPG data.
			if (playerProgressReady && level.Time >= 10)
			{
				PrioritizeInitialHeavyRarities();
				SynchronizeLivingMonsterLevels();
				MonsterLevelsSynchronized = true;
			}
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
        UpdateAmmoPressureDirector();
        UpdateFullHealthDirector();
		UpdateCompletionMilestones();
	}

    override void WorldLineActivated(WorldEvent e)
    {
        EnsureLocator();
        if(Locator) Locator.RecordActivatedLine(e.ActivatedLine);
    }

    override void NetworkProcess(ConsoleEvent e)
	{
        EnsureLocator();
        if (Locator) Locator.ProcessRequest(e.Name,e.Args[0],e.Player);
		if (e.Player < 0 || e.Player >= TUIN_MAX_PLAYERS) return;
		if (e.Name ~== "tuin_inspect_weapon" && !ClassesEnabled())
		{
			InspectWeapon[e.Player] = !InspectWeapon[e.Player];
			return;
		}
		if (!ClassesEnabled() && (e.Name ~== "tuin_heavy_radio" ||
			e.Name ~== "tuin_rogue_pistol_burst_down" || e.Name ~== "tuin_rogue_pistol_burst" ||
			e.Name ~== "tuin_rogue_pistol_burst_up" || e.Name ~== "tuin_class_ability_up" ||
			e.Name ~== "tuin_class_ability_down" || e.Name ~== "tuin_rogue_shadow_veil" ||
			e.Name ~== "tuin_test_heavy_radio" || e.Name ~== "tuin_test_rogue_chain" ||
			e.Name ~== "tuin_test_rogue_pistol_burst" || e.Name ~== "tuin_test_engineer_turret" ||
			e.Name ~== "tuin_test_blood_punch" || e.Name ~== "tuin_test_fatality" ||
			e.Name ~== "tuin_test_death_sentence" || e.Name ~== "tuin_choose_class" ||
			e.Name ~== "tuin_test_minigun")) return;
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
		if (e.Name ~== "tuin_heavy_radio")
		{
			let radioData = EnsurePlayerData(e.Player);
			let radioPawn = players[e.Player].mo;
			if (radioData && radioPawn && radioData.PlayerClass == 1)
				ActivateHeavyRadio(e.Player, radioPawn, radioData);
			else if (radioData && radioPawn && radioData.PlayerClass == 5)
				ActivateRogueChain(e.Player, radioPawn, radioData);
			else SetLootNotification(e.Player, "NO SECONDARY CLASS ABILITY", 0);
			return;
		}
		if (e.Name ~== "tuin_rogue_pistol_burst_down" || e.Name ~== "tuin_rogue_pistol_burst")
		{
			let burstData = EnsurePlayerData(e.Player);
			let burstPawn = players[e.Player].mo;
			if (burstData && burstPawn && burstData.PlayerClass == 5)
			{
				if (e.Name ~== "tuin_rogue_pistol_burst") ActivateRoguePistolBurst(e.Player, burstPawn, burstData);
				else BeginRoguePistolBurstHold(e.Player, burstPawn, burstData);
			}
			else SetLootNotification(e.Player, "NO THIRD CLASS ABILITY", 0);
			return;
		}
		if (e.Name ~== "tuin_rogue_pistol_burst_up")
		{
			let burstData = EnsurePlayerData(e.Player);
			let burstPawn = players[e.Player].mo;
			if (burstData && burstPawn && burstData.PlayerClass == 5)
				ReleaseRoguePistolBurst(burstPawn, burstData);
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
			if (rogueData && pawn && rogueData.PlayerClass == 2)
			{
				ActivateHealerSupplyToss(e.Player, pawn, rogueData);
				return;
			}
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
			if (rogueData && pawn && rogueData.PlayerClass == 3)
			{
				ActivateExecutionerDeathSentence(e.Player, pawn, rogueData);
				return;
			}
			if (rogueData && pawn && rogueData.PlayerClass == 4)
			{
				if (rogueData.DoomFatalityTics > 0) return;
				if (BeginDoomFatality(e.Player, pawn, rogueData)) return;
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
			if (rogueData && pawn && rogueData.PlayerClass == 6)
			{
				UseEngineerTurret(e.Player, pawn, rogueData);
				return;
			}
			if (!rogueData || !pawn || rogueData.PlayerClass != 5)
			{
				SetLootNotification(e.Player, "CHOOSE A CLASS WITH AN ACTIVE ABILITY", 0);
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
				SetLootNotification(e.Player, String.Format("SHADOW CHARGE: %d%% - USE WEAPONS",
					rogueData.RogueVeilCharge), 0);
			return;
		}
		if (e.Name ~== "tuin_give_levels")
		{
			GiveTestLevels(e.Player, e.Args[0] > 0 ? e.Args[0] : 1);
			return;
		}
		if (e.Name ~== "tuin_test_john_comment")
		{
			int percent = level.total_monsters > 0 ?
				clamp(level.killed_monsters * 100 / level.total_monsters, 0, 100) : 10;
			StartJohnMilestoneComment(e.Player, max(10, percent));
			return;
		}
		if (e.Name ~== "tuin_test_life_essence")
		{
			Actor pawn = players[e.Player].mo;
			if (pawn)
			{
				Vector3 position = pawn.Pos + (cos(pawn.Angle) * 48.0,
					sin(pawn.Angle) * 48.0, 8.0);
				Actor.Spawn('TuinLifeEssencePickup', position, NO_REPLACE);
			}
			return;
		}
		if (e.Name ~== "tuin_test_heavy_radio")
		{
			let testData = EnsurePlayerData(e.Player);
			let testPawn = players[e.Player].mo;
			if (testData && testPawn)
			{
				testData.PlayerClass = 1;
				testData.HeavyRadioCooldownTics = 0;
				testData.HeavyRadioCallTics = 0;
				testData.HeavyRadioMarinesDeployed = false;
				ApplyClassHealth(testPawn, testData);
				ApplyAmmoCapacity(testPawn, testData);
				ApplyHeavyMovement(testPawn, testData);
				ActivateHeavyRadio(e.Player, testPawn, testData);
				testPawn.A_Log("HEAVY RADIO TEST STARTED. Reinforcements arrive during the call animation.");
			}
			return;
		}
		if (e.Name ~== "tuin_test_rogue_chain")
		{
			let testData = EnsurePlayerData(e.Player);
			let testPawn = players[e.Player].mo;
			if (testData && testPawn)
			{
				testData.PlayerClass = 5;
				testData.RogueVeilOwner = testPawn;
				testData.RogueChainCharges = 0;
				Vector3 testKillPosition = testPawn.Pos + (cos(testPawn.Angle) * 96.0,
					sin(testPawn.Angle) * 96.0, 0);
				let testKillTarget = Actor.Spawn('DoomImp', testKillPosition, ALLOW_REPLACE);
				if (testKillTarget)
				{
					InitializeMonster(testKillTarget);
					let knifePuff = Actor.Spawn('TuinRogueKnifePuff', testKillTarget.Pos, NO_REPLACE);
					testKillTarget.DamageMobj(knifePuff, testPawn, testKillTarget.Health + 1, 'Melee');
				}
				testPawn.A_Log(String.Format("ROGUE KNIFE KILL DETECTION: %d / 9 CHARGES.",
					testData.RogueChainCharges));
				testData.RogueChainCharges = 9;
				RogueChainTestActive[e.Player] = true;
				RogueChainTestHits[e.Player] = -1;
				for (int i = 0; i < 9; i++)
				{
					double spawnAngle = testPawn.Angle + (i - 4) * 18.0;
					double spawnDistance = 160.0 + (i % 3) * 64.0;
					Vector3 spawnPosition = testPawn.Pos + (cos(spawnAngle) * spawnDistance,
						sin(spawnAngle) * spawnDistance, 0);
					let monster = Actor.Spawn('DoomImp', spawnPosition, ALLOW_REPLACE);
					if (monster && !monster.TestMobjLocation()) monster.Destroy();
				}
				ActivateRogueChain(e.Player, testPawn, testData);
				testPawn.A_Log(String.Format("ROGUE CHAIN TEST STARTED: ACTIVE %d, %d STRIKES.",
					testData.RogueChainActive, testData.RogueChainHitsRemaining));
			}
			return;
		}
		if (e.Name ~== "tuin_test_rogue_pistol_burst")
		{
			let testData = EnsurePlayerData(e.Player);
			let testPawn = players[e.Player].mo;
			if (testData && testPawn)
			{
				testData.PlayerClass = 5;
				testData.RogueVeilOwner = testPawn;
				testData.RogueVeiled = false;
				testData.RoguePistolBurstCooldownTics = 0;
				testData.RoguePistolBurstShotsRemaining = 0;
				if (!testPawn.FindInventory('TuinRogueSilencedPistol'))
					testPawn.GiveInventory('TuinRogueSilencedPistol', 1);
				if (!testPawn.FindInventory('TuinRogueKnife'))
					testPawn.GiveInventory('TuinRogueKnife', 1);
				testPawn.GiveInventory('Clip', 3);
				Vector3 targetPosition = testPawn.Pos + (cos(testPawn.Angle) * 96.0,
					sin(testPawn.Angle) * 96.0, 0);
				let target = Actor.Spawn('DoomImp', targetPosition, ALLOW_REPLACE);
				if (target)
				{
					InitializeMonster(target);
					RoguePistolBurstTestTarget[e.Player] = target;
					RoguePistolBurstTestHealth[e.Player] = target.Health;
					RoguePistolBurstTestPending[e.Player] = true;
					testPawn.player.PendingWeapon = Weapon(testPawn.FindInventory('TuinRogueKnife'));
					testPawn.A_Log("ROGUE SILENCED BURST TEST STARTED.");
				}
			}
			return;
		}
		if (e.Name ~== "tuin_test_engineer_turret")
		{
			let testData = EnsurePlayerData(e.Player);
			let testPawn = players[e.Player].mo;
			if (testData && testPawn)
			{
				testData.PlayerClass = 6;
				for (int slot = 0; slot < 2; slot++)
				{
					if (testData.EngineerSentry[slot]) testData.EngineerSentry[slot].Destroy();
					testData.EngineerSentry[slot] = null;
					testData.EngineerSentryDeployed[slot] = false;
					testData.EngineerSentryReady[slot] = false;
					testData.EngineerSentryStoredHealth[slot] = 0;
					testData.EngineerSentryStoredRounds[slot] = 0;
					testData.EngineerSentryFabrication[slot] = 0.0;
				}
				testData.EngineerSentriesInitialized = false;
				testData.EngineerSecondSentryGranted = false;
				InitializeEngineerSentries(testData);
				ApplyClassHealth(testPawn, testData);
				UseEngineerTurret(e.Player, testPawn, testData);
			}
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
		if (e.Name ~== "tuin_test_fatality")
		{
			let testData = EnsurePlayerData(e.Player);
			let testPawn = players[e.Player].mo;
			if (testData && testPawn)
			{
				testData.PlayerClass = 4;
				ApplyClassHealth(testPawn, testData);
				Vector3 targetPosition = testPawn.Pos +
					(cos(testPawn.Angle) * 112.0, sin(testPawn.Angle) * 112.0, 0);
				Actor target = Actor.Spawn('Demon', targetPosition, NO_REPLACE);
				if (target)
				{
					InitializeMonster(target);
					target.Health = max(1, DoomFatalityMaximumHealth(target) / 10);
					target.reactiontime = 350;
					testPawn.Angle = testPawn.AngleTo(target, true);
					testPawn.A_Log("FATALITY TEST READY. The Demon is at 10% health; face it and press V.");
					SetLootNotification(e.Player, "FATALITY READY - PRESS V", 5);
				}
				else SetLootNotification(e.Player, "FATALITY TEST NEEDS OPEN SPACE", 0);
			}
			return;
		}
		if (e.Name ~== "tuin_test_death_sentence")
		{
			let testData = EnsurePlayerData(e.Player);
			let testPawn = players[e.Player].mo;
			if (testData && testPawn)
			{
				ClearExecutionerMark(e.Player, testData);
				testData.PlayerClass = 3;
				testData.ExecutionerCharge = 100;
				testData.ExecutionerChargeRemainder = 0.0;
				testData.ExecutionerReadyNotified = true;
				testData.ExecutionerJudgmentArmed = false;
				ApplyClassHealth(testPawn, testData);
				testPawn.A_Log("DEATH SENTENCE TEST READY. Press V, then shoot a monster.");
				SetLootNotification(e.Player, "DEATH SENTENCE TEST READY - PRESS V, THEN FIRE", 4);
			}
			return;
		}
		if (e.Name ~== "tuin_test_finale_boss")
		{
			if (!TryPromoteFinaleBoss(true) && players[e.Player].mo)
				players[e.Player].mo.A_Log("No eligible monster is alive for finale-boss testing.");
			return;
		}
		if (e.Name ~== "tuin_test_boss_chest")
		{
			Actor pawn = players[e.Player].mo;
			if (!pawn) return;
			class<Actor> chestClass = CVInt('tuin_boss_chest_style', 0) == 1 ?
				'TuinBossRewardChestMinecraft' : 'TuinBossRewardChest';
			let chest = TuinBossRewardChest(Actor.Spawn(chestClass,
				(pawn.Pos.X + cos(pawn.Angle) * 92.0,
				 pawn.Pos.Y + sin(pawn.Angle) * 92.0,
				 pawn.FloorZ + 2.0), NO_REPLACE));
			if (chest)
			{
				chest.Angle = chest.AngleTo(pawn, true);
				chest.RewardWeapon = PickDropWeapon(pawn);
				chest.RewardLevel = max(1, EnsurePlayerData(e.Player).PlayerLevel);
				chest.RewardQuality = 6;
				pawn.A_Log("Boss chest test spawned. Face it and press Use.");
			}
			return;
		}
		if (e.Name ~== "tuin_test_promote_heavy" || e.Name ~== "tuin_test_promote_hellknight" ||
			e.Name ~== "tuin_test_promote_baron")
		{
			int requestedType = e.Name ~== "tuin_test_promote_hellknight" ? 1 :
				e.Name ~== "tuin_test_promote_baron" ? 2 : 0;
			TestPromoteHeavyMonster(requestedType, e.Player);
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
		if (e.Name ~== "tuin_test_riot_shotgun" || e.Name ~== "tuin_test_minigun")
		{
			let pawn = players[e.Player].mo;
			let testData = EnsurePlayerData(e.Player);
			if (pawn && testData)
			{
				Name specialName = e.Name ~== "tuin_test_riot_shotgun" ? 'TuinRiotShotgun' : 'TuinMinigun';
				class<Weapon> specialType = (class<Weapon>)(FindClass(specialName, 'Weapon'));
				Vector3 position = pawn.Pos + (cos(pawn.Angle) * 64.0, sin(pawn.Angle) * 64.0, 8.0);
				let reward = SpawnRolledWeaponDrop(position, specialType, max(1, testData.PlayerLevel), 5);
				if (reward) SetLootNotification(e.Player,
					String.Format("MYTHIC %s TEST DROP SPAWNED", WeaponBaseName(specialType)), 5);
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
		if (e.Name ~== "tuin_buy_weapon_perk")
		{
			BuyWeaponPerk(e.Player, e.Args[0]);
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
		ApplyClassHealth(players[e.Player].mo, data);
	}

	override void InterfaceProcess(ConsoleEvent e)
	{
        if(e.Name=="tuin_run_finished") {Menu.SetMenu('TuinRunScores');return;}
        if(e.Name=="tuin_run_score")
        {
            TuinRun.SaveScore(e.Args[0],e.Args[1],e.Args[2]);
            Menu.SetMenu('TuinRunScores');
            return;
        }
        if (Locator) Locator.HandleInterface(e);
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
		else if (e.Name ~== "tuin_open_class_choice")
		{
			if (ClassesEnabled()) Menu.SetMenu('TuinRPGClassChoice');
		}
		else if (e.Name ~== "tuin_open_perk_hub")
			Menu.SetMenu(ClassesEnabled() ? 'TuinRPGPerkHub' : 'TuinRPGGeneralPerks');
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
				DamageNumberElement[i] == 1 ? Font.CR_ORANGE :
				DamageNumberElement[i] == 2 ? Font.CR_CYAN :
				DamageNumberElement[i] == 3 ? Font.CR_RED :
				DamageNumberElement[i] == 4 ? Font.CR_GREEN :
				(DamageNumberCritical[i] ? Font.CR_GOLD : Font.CR_WHITE);
			Screen.DrawText(font, numberColor, x, y, number,
				DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Alpha, fade);
		}
	}

	ui void DrawBossTarget(RenderEvent e, int p, int sw, int sh)
	{
		if (ClassesEnabled() || menuactive || !TargetIsBoss[p] || TargetMaxHealth[p] <= 0 ||
			CVInt('tuin_healthbar_mode',1) == 3) return;
		Font f = "TINYBABY";
		double s = min(sw / 1280., sh / 800.);
		int w = int(460*s), x = (sw-w)/2, y = int(24*s);
		double ratio = clamp(double(TargetHealth[p])/TargetMaxHealth[p],0.,1.);
		double trail = clamp((TargetPreviousDisplayHealth[p] +
			(TargetDisplayHealth[p]-TargetPreviousDisplayHealth[p])*e.FracTic)/TargetMaxHealth[p],ratio,1.);
		Color accent = Color(70,185,245);
		Screen.Dim(Color(3,10,20),.94,x,y,w,int(93*s));
		Screen.DrawLineFrame(Color(28,75,110),x,y,w,int(93*s),1);
		string title = CVInt('tuin_healthbar_show_name',1) ? TargetName[p] : "BOSS";
		double nameScale = min(2.0*s,(w-24*s)/max(1,f.StringWidth(title)));
		Screen.DrawText(f,Font.CR_WHITE,x+12*s,y+9*s,title,DTA_ScaleX,nameScale,DTA_ScaleY,nameScale);
		string hp = CVInt('tuin_healthbar_show_exact',1) ?
			String.Format("%d / %d HP   |   %.0f%%",TargetHealth[p],TargetMaxHealth[p],ratio*100) : String.Format("%.0f%%",ratio*100);
		if (CVInt('tuin_healthbar_show_level',1)) hp = String.Format("LV %d   |   ",TargetLevel[p]) .. hp;
		Screen.DrawText(f,Font.CR_LIGHTBLUE,x+12*s,y+27*s,hp,DTA_ScaleX,1.2*s,DTA_ScaleY,1.2*s);
		int bx=x+int(12*s), by=y+int(43*s), bw=w-int(24*s), bh=max(3,int(12*s));
		Screen.Dim(Color(16,30,45),1,bx,by,bw,bh);
		if (trail>0) Screen.Dim(Color(245,170,60),.85,bx,by,int(bw*trail),bh);
		if (ratio>0) Screen.Dim(accent,.95,bx,by,int(bw*ratio),bh);
		for(int tick=1;tick<4;tick++) Screen.Dim(Color(3,10,20),.65,bx+bw*tick/4,by,max(1,int(s)),bh);
		string details = CVInt('tuin_healthbar_show_affixes',1) ? TargetAffixes[p] : "";
		// Wrap rather than shrinking resistance labels into unreadable microtext.
		int split = details.Length()>65 ? details.IndexOf(" | ",40) : -1;
		string first = split>=0 ? details.Left(split) : details;
		string second = split>=0 ? details.Mid(split+3) : "";
		for(int row=0;row<2;row++)
		{
			string label = row==0 ? first : second;
			double fs=min(1.1*s,(w-24*s)/max(1,f.StringWidth(label)));
			Screen.DrawText(f,Font.CR_GRAY,x+12*s,y+(63+13*row)*s,label,DTA_ScaleX,fs,DTA_ScaleY,fs);
		}
	}

	ui void DrawCurrentTargetPanel(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (!ClassesEnabled() && TargetIsBoss[playerNumber]) return;
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
				(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7);
			double statusScale = clamp(hudScale * 1.45, 2.0, 2.8);
			panelY = playerStatusY + int(47 * statusScale) + 7;
			let targetPlayerData = GetPlayerData(players[playerNumber].mo);
			if (targetPlayerData && targetPlayerData.PlayerClass >= 1 && targetPlayerData.PlayerClass <= 6)
			{
				double classAbilityScale = clamp(hudScale * 1.45, 2.0, 2.8);
				int classPanelUnits = targetPlayerData.PlayerClass == 5 ? 52 :
					targetPlayerData.PlayerClass == 1 ? 36 : 20;
				panelY += int(classPanelUnits * classAbilityScale) + 5;
			}
			panelWidth = mapSize;
		}

		string rarity = TargetRarity[playerNumber] > 0 ? RarityName(TargetRarity[playerNumber]) : "NORMAL";
		string stats = String.Format("LEVEL %d    HP %d/%d    %s", TargetLevel[playerNumber],
			TargetHealth[playerNumber], TargetMaxHealth[playerNumber], rarity);
		int line = int(14 * scale);
		int panelHeight = int(42 * scale);
		if (panelY + panelHeight > screenHeight - 8) panelY = screenHeight - panelHeight - 8;
		Screen.Dim(Color(3, 5, 9), 0.94, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawText(font, Font.CR_GOLD, panelX + 7, panelY + 5, "LAST HIT",
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

	ui void DrawHealerSupplyStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 2) return;
		double scale = clamp(hudScale * 1.45, 2.0, 2.8);
		string status = data.HealerSupplyCooldownTics > 0 ?
			String.Format("FIELD SUPPLY  %.1f SEC", data.HealerSupplyCooldownTics / 35.0) :
			"FIELD SUPPLY READY  -  PRESS V";
		int statusColor = data.HealerSupplyCooldownTics > 0 ? Font.CR_GOLD : Font.CR_GREEN;
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
				(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7) + int(47 * clamp(hudScale * 1.45, 2.0, 2.8)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(2, 14, 9), 0.94, panelX, panelY, panelWidth, int(20 * scale));
		Screen.DrawLineFrame(Color(35, 210, 105), panelX, panelY, panelWidth, int(20 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
	}

	ui void DrawEngineerTurretStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 6) return;
		double scale = clamp(hudScale * 1.45, 2.0, 2.8);
		string status = "";
		int statusColor = Font.CR_GOLD;
		for (int slot = 0; slot < (data.PerkCapstone ? 2 : 1); slot++)
		{
			if (slot > 0) status.AppendFormat("  |  ");
			let turret = TuinEngineerTurret(data.EngineerSentry[slot]);
			if (data.EngineerSentryDeployed[slot] && turret && turret.Health > 0 && turret.ShotsRemaining > 0)
			{
				status.AppendFormat("S%d ACTIVE %dHP/%dR", slot + 1, turret.Health, turret.ShotsRemaining);
				statusColor = Font.CR_CYAN;
			}
			else if (data.EngineerSentryReady[slot])
			{
				status.AppendFormat("S%d PACKED %dHP/%dR", slot + 1,
					data.EngineerSentryStoredHealth[slot], data.EngineerSentryStoredRounds[slot]);
				if (statusColor != Font.CR_CYAN) statusColor = Font.CR_GREEN;
			}
			else
				status.AppendFormat("S%d FABRICATION %.0f%%", slot + 1,
					clamp(data.EngineerSentryFabrication[slot], 0.0, 100.0));
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
				(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7) + int(47 * clamp(hudScale * 1.45, 2.0, 2.8)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(2, 10, 15), 0.94, panelX, panelY, panelWidth, int(20 * scale));
		Screen.DrawLineFrame(Color(45, 185, 235), panelX, panelY, panelWidth, int(20 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
	}

	ui void DrawExecutionerStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 3) return;
		double scale = clamp(hudScale * 1.45, 2.0, 2.8);
		string status;
		int statusColor;
		int activeMarks = data.ExecutionerMarkedTarget && data.ExecutionerMarkTics > 0 ? 1 : 0;
		int maxMarkTime = data.ExecutionerMarkTics;
		for (int i = 0; i < 2; i++)
		{
			if (data.ExecutionerExtraMarkedTarget[i] && data.ExecutionerExtraMarkTics[i] > 0) activeMarks++;
			maxMarkTime = max(maxMarkTime, data.ExecutionerExtraMarkTics[i]);
		}
		if (activeMarks > 0)
		{
			status = String.Format("DEATH SENTENCE  %d TARGET%s  %.1f SEC",
				activeMarks, activeMarks == 1 ? "" : "S", max(0, maxMarkTime) / 35.0);
			statusColor = Font.CR_RED;
		}
		else if (data.ExecutionerJudgmentArmed)
		{
			status = "JUDGMENT ARMED  -  NEXT HIT PASSES SENTENCE";
			statusColor = Font.CR_RED;
		}
		else if (data.ExecutionerCharge < 100)
		{
			status = String.Format("JUDGMENT CHARGE  %d%%  -  DEAL DAMAGE", data.ExecutionerCharge);
			statusColor = Font.CR_GOLD;
		}
		else
		{
			status = "JUDGMENT READY  -  PRESS V TO ARM";
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
				(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7) + int(47 * clamp(hudScale * 1.45, 2.0, 2.8)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(16, 1, 1), 0.94, panelX, panelY, panelWidth, int(20 * scale));
		Screen.DrawLineFrame(Color(230, 28, 16), panelX, panelY, panelWidth, int(20 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
	}

	ui void DrawRogueStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 5) return;
		double scale = clamp(hudScale * 1.45, 2.0, 2.8);
		string status;
		string chainStatus;
		string burstStatus;
		int statusColor;
		if (data.RogueVeiled)
		{
			status = String.Format("SHADOW VEIL ACTIVE  %.1f SEC  -  AMBUSH READY",
				max(0, RogueVeilDuration(data) - data.RogueVeilTics) / 35.0);
			statusColor = Font.CR_PURPLE;
		}
		else if (data.RogueVeilCharge < 100)
		{
			status = String.Format("SHADOW CHARGE  %d%%  -  USE WEAPONS", data.RogueVeilCharge);
			statusColor = Font.CR_GOLD;
		}
		else
		{
			status = "SHADOW VEIL READY  -  USE ROGUE ABILITY";
			statusColor = Font.CR_GREEN;
		}
		if (data.RogueChainActive)
			chainStatus = String.Format("CHAIN ASSASSINATION  %d STRIKE%s REMAINING",
				data.RogueChainHitsRemaining, data.RogueChainHitsRemaining == 1 ? "" : "S");
		else if (data.RogueChainCharges > 0)
			chainStatus = String.Format("CHAIN ASSASSINATION  %d / 9  -  PRESS B",
				data.RogueChainCharges);
		else chainStatus = "CHAIN ASSASSINATION  0 / 9  -  KNIFE KILLS ADD STRIKES";
		if (data.RoguePistolBurstHolding)
			burstStatus = "SILENCED PISTOL AIMING  -  RELEASE C TO BURST";
		else if (data.RoguePistolBurstShotsRemaining > 0)
			burstStatus = String.Format("SILENCED BURST  %d SHOT%s REMAINING",
				data.RoguePistolBurstShotsRemaining,
				data.RoguePistolBurstShotsRemaining == 1 ? "" : "S");
		else if (data.RoguePistolBurstCooldownTics > 0)
			burstStatus = String.Format("SILENCED BURST  %.1f SEC",
				data.RoguePistolBurstCooldownTics / 35.0);
		else burstStatus = "SILENCED BURST READY  -  PRESS C  -  COST 3 BULLETS";
		int longestWidth = max(font.StringWidth(status),
			max(font.StringWidth(chainStatus), font.StringWidth(burstStatus)));
		int panelWidth = min(screenWidth - 20, int(longestWidth * scale) + 16);
		int panelX = screenWidth - panelWidth - 10;
		int panelY = 10;
		if (CVInt('tuin_minimap_enabled', 1))
		{
			int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, screenHeight - 32));
			double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
			double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
			panelX = int(8 + (screenWidth - mapSize - 16) * mapHorizontal);
			panelY = int(8 + (screenHeight - mapSize - 16) * mapVertical) + mapSize +
				(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7) + int(47 * clamp(hudScale * 1.45, 2.0, 2.8)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(8, 3, 14), 0.94, panelX, panelY, panelWidth, int(52 * scale));
		Screen.DrawLineFrame(Color(150, 70, 220), panelX, panelY, panelWidth, int(52 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
		double chainScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(chainStatus)));
		Screen.DrawText(font, data.RogueChainCharges > 0 || data.RogueChainActive ? Font.CR_GREEN : Font.CR_GOLD,
			panelX + 6, panelY + int(20 * scale), chainStatus,
			DTA_ScaleX, chainScale, DTA_ScaleY, chainScale);
		double burstScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(burstStatus)));
		Screen.DrawText(font, data.RoguePistolBurstCooldownTics <= 0 ? Font.CR_GREEN : Font.CR_GOLD,
			panelX + 6, panelY + int(36 * scale), burstStatus,
			DTA_ScaleX, burstScale, DTA_ScaleY, burstScale);
	}

	ui void DrawRogueBurstCrosshair(int playerNumber, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 5 || !data.RoguePistolBurstHolding) return;
		int centerX = screenWidth / 2;
		int centerY = screenHeight / 2;
		double pulse = 1.0 + 0.12 * sin((gametic + 1.0) * 18.0);
		int gap = int(7 * pulse);
		int arm = int(10 * pulse);
		Color crosshairColor = Color(205, 105, 255);
		Screen.DrawThickLine(centerX - gap - arm, centerY, centerX - gap, centerY,
			2, crosshairColor, 245);
		Screen.DrawThickLine(centerX + gap, centerY, centerX + gap + arm, centerY,
			2, crosshairColor, 245);
		Screen.DrawThickLine(centerX, centerY - gap - arm, centerX, centerY - gap,
			2, crosshairColor, 245);
		Screen.DrawThickLine(centerX, centerY + gap, centerX, centerY + gap + arm,
			2, crosshairColor, 245);
		Screen.DrawThickLine(centerX - 2, centerY, centerX + 2, centerY,
			2, Color(255, 220, 100), 255);
		Font aimFont = "TINYBABY";
		string prompt = "RELEASE C - FIRE 3-SHOT BURST";
		double promptScale = clamp(hudScale * 1.35, 1.9, 2.6);
		Screen.DrawText(aimFont, Font.CR_PURPLE,
			centerX - int(aimFont.StringWidth(prompt) * promptScale * 0.5), centerY + int(27 * pulse),
			prompt, DTA_ScaleX, promptScale, DTA_ScaleY, promptScale);
	}

	ui void DrawTankStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 1) return;
		double scale = clamp(hudScale * 1.45, 2.0, 2.8);
		string status;
		string radioStatus;
		int statusColor;
		if (data.TankOverdriveActive)
		{
			status = String.Format("HEAVY OVERDRIVE  %.1f SEC  -  +25%% DAMAGE / +150%% FIRE SPEED",
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
		if (data.HeavyRadioCallTics > 0)
			radioStatus = "RADIO SUPPORT  CALLING...";
		else if (data.HeavyRadioCooldownTics > 0)
			radioStatus = String.Format("RADIO RECHARGE  %d DAMAGE - DEAL DAMAGE", data.HeavyRadioCooldownTics);
		else radioStatus = "RADIO SUPPORT READY  -  PRESS B";
		int longestWidth = max(font.StringWidth(status), font.StringWidth(radioStatus));
		int panelWidth = min(screenWidth - 20, int(longestWidth * scale) + 16);
		int panelX = screenWidth - panelWidth - 10;
		int panelY = 10;
		if (CVInt('tuin_minimap_enabled', 1))
		{
			int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, screenHeight - 32));
			double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
			double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
			panelX = int(8 + (screenWidth - mapSize - 16) * mapHorizontal);
			panelY = int(8 + (screenHeight - mapSize - 16) * mapVertical) + mapSize +
				(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7) + int(47 * clamp(hudScale * 1.45, 2.0, 2.8)) + 3;
			panelWidth = mapSize;
		}
		Screen.Dim(Color(15, 2, 2), 0.94, panelX, panelY, panelWidth, int(36 * scale));
		Screen.DrawLineFrame(Color(235, 42, 18), panelX, panelY, panelWidth, int(36 * scale), 2);
		double textScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(status)));
		Screen.DrawText(font, statusColor, panelX + 6, panelY + int(4 * scale), status,
			DTA_ScaleX, textScale, DTA_ScaleY, textScale);
		double radioScale = min(scale, double(panelWidth - 12) / max(1, font.StringWidth(radioStatus)));
		Screen.DrawText(font, data.HeavyRadioCooldownTics <= 0 ? Font.CR_GREEN : Font.CR_GOLD,
			panelX + 6, panelY + int(20 * scale), radioStatus,
			DTA_ScaleX, radioScale, DTA_ScaleY, radioScale);
	}

	ui void DrawDoomBloodPunchStatus(int playerNumber, Font font, int screenWidth, int screenHeight, double hudScale)
	{
		if (menuactive || !players[playerNumber].mo) return;
		let data = GetPlayerData(players[playerNumber].mo);
		if (!data || data.PlayerClass != 4) return;
		// The world-space skull is the complete Fatality prompt. Do not add a
		// second textual instruction or let the Blood Punch panel compete with it.
		if (data.DoomFatalityTics > 0 || data.DoomFatalityCandidate ||
			data.DoomFatalityMarkerTarget) return;
		double scale = clamp(hudScale * 1.45, 2.0, 2.8);
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
				(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7) + int(47 * clamp(hudScale * 1.45, 2.0, 2.8)) + 3;
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
		// The modern boss panel already contains these traits below its health bar.
		if (!ClassesEnabled() && TargetIsBoss[playerNumber] && CVInt('tuin_healthbar_mode',1) != 3) return;
		if (menuactive || !CVInt('tuin_healthbar_show_affixes', 1) ||
			TargetMaxHealth[playerNumber] <= 0 || !TargetAffixes[playerNumber].Length()) return;
		double scale = clamp(hudScale * 1.12, 1.65, 2.55);
		string heading = TargetDeathSentence[playerNumber] ? "MARKED TARGET" : "TARGET TRAITS";
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
		Screen.DrawLineFrame(TargetDeathSentence[playerNumber] ? Color(240, 22, 12) :
			RarityBarColor(TargetRarity[playerNumber]), panelX, panelY, panelWidth, panelHeight, 2);
		Screen.DrawText(font, Font.CR_GOLD, (screenWidth - font.StringWidth(heading) * scale) / 2,
			panelY + int(3 * scale), heading, DTA_ScaleX, scale, DTA_ScaleY, scale);
		int targetColor = TargetDeathSentence[playerNumber] ? Font.CR_RED :
			(TargetRarity[playerNumber] > 0 ? RarityColor(TargetRarity[playerNumber]) : Font.CR_WHITE);
		Screen.DrawText(font, targetColor, (screenWidth - font.StringWidth(affixes) * affixScale) / 2,
			panelY + int(16 * scale), affixes, DTA_ScaleX, affixScale, DTA_ScaleY, affixScale);
	}

	override bool InputProcess(InputEvent e)
	{
		if (!ClassesEnabled()) return false;
		if (gamestate == GS_LEVEL && e.KeyScan == 0x2E &&
			Bindings.GetBinding(e.KeyScan) ~== "netevent tuin_rogue_pistol_burst")
		{
			if (e.Type == InputEvent.Type_KeyDown)
			{
				EventHandler.SendNetworkEvent("tuin_rogue_pistol_burst_down");
				return true;
			}
			if (e.Type == InputEvent.Type_KeyUp)
			{
				EventHandler.SendNetworkEvent("tuin_rogue_pistol_burst_up");
				return true;
			}
		}
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
        if (Locator) Locator.DrawLocator(e);
		int pnum = consoleplayer;
		if (pnum < 0 || pnum >= TUIN_MAX_PLAYERS || !playerInGame[pnum]) return;
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		Font font = SmallFont;
		Font classStatusFont = "TINYBABY";
		double hudScale = clamp(CVFloat('tuin_hud_scale', 1.5), 1.25, 3.0);
		let overlayData = GetPlayerData(players[pnum].mo);
        if(overlayData && overlayData.RunActive)
        {
            if(overlayData.RunClearTics>0 && !menuactive)TuinRunArt.ClearPopup(overlayData.RunScore,overlayData.RunStages,(245-overlayData.RunClearTics)/35.);
            double rs=min(sw/1100.,sh/750.);
            Screen.DrawText(classStatusFont,Font.CR_GOLD,sw*.025,sh*.17,
                overlayData.RunEnded?"GAMBIT ENDED / NEW GAME TO TRY AGAIN":String.Format("HELL'S GAMBIT / STAGE %d / SCORE %d",overlayData.RunStages+1,overlayData.RunScore),
                DTA_ScaleX,rs,DTA_ScaleY,rs);
        }
		if (overlayData && overlayData.LifeRevivePending)
		{
			double pulse = 0.31 + 0.09 * sin(level.Time * 24.0);
			Screen.Dim(Color(150, 0, 0), pulse, 0, 0, sw, sh);
			TextureID johnFace = TexMan.CheckForTexture("graphics/TuinReviveJohn.png", TexMan.Type_Any);
			if (johnFace.IsValid())
			{
				int faceSize = clamp(int(sh * 0.29), 150, 330);
				double facePulse = 0.84 + 0.10 * sin(level.Time * 18.0);
				int faceX = (sw - faceSize) / 2 + int(sin(level.Time * 3.0) * 9.0);
				int faceY = int(sh * 0.10) + int(sin(level.Time * 6.0) * 13.0);
				Screen.DrawTexture(johnFace, false, faceX, faceY,
					DTA_DestWidth, faceSize, DTA_DestHeight, faceSize, DTA_Alpha, facePulse);
			}
			double titleScale = clamp(hudScale * 1.55, 2.1, 3.5);
			string title = "EXTRA LIFE";
			Screen.DrawText(BigFont, Font.CR_RED,
				(sw - BigFont.StringWidth(title) * titleScale) / 2, int(sh * 0.43), title,
				DTA_ScaleX, titleScale, DTA_ScaleY, titleScale);
			string quote = LifeReviveJohnQuote(overlayData.LifeReviveQuote);
			double quoteScale = clamp(hudScale * 1.12, 1.55, 2.25);
			Screen.DrawText(font, Font.CR_WHITE,
				(sw - font.StringWidth(quote) * quoteScale) / 2, int(sh * 0.55), quote,
				DTA_ScaleX, quoteScale, DTA_ScaleY, quoteScale);
		}
		else if (overlayData && overlayData.LifeReviveFadeTics > 0)
		{
			Screen.Dim(Color(130, 0, 0), 0.18 * overlayData.LifeReviveFadeTics / 24.0,
				0, 0, sw, sh);
		}
		if (!menuactive && (!overlayData || !overlayData.LifeRevivePending) &&
			CVInt('tuin_john_milestone_comments', 1) && JohnCommentTics[pnum] > 0)
		{
			int remaining = JohnCommentTics[pnum];
			double alpha = min(1.0, min((245 - remaining) / 18.0, remaining / 24.0));
			int faceSize = clamp(int(sh * 0.105), 64, 108);
			int faceX = sw - faceSize - 16;
			int faceBaseY = 16;
			if (CVInt('tuin_minimap_enabled', 1))
			{
				int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, sh - 32));
				double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
				double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
				int mapLeft = int(8 + (sw - mapSize - 16) * mapHorizontal);
				int mapTop = int(8 + (sh - mapSize - 16) * mapVertical);
				faceX = mapLeft - faceSize - 10;
				faceBaseY = mapTop;
			}
			faceX = clamp(faceX, 116, sw - faceSize - 8);
			int faceY = clamp(faceBaseY + int(sin((gametic + e.FracTic) * 5.0) * 5.0),
				8, sh - faceSize - 8);
			TextureID johnFace = TexMan.CheckForTexture("graphics/TuinReviveJohn.png", TexMan.Type_Any);
			if (johnFace.IsValid())
				Screen.DrawTexture(johnFace, false, faceX, faceY,
					DTA_DestWidth, faceSize, DTA_DestHeight, faceSize, DTA_Alpha, alpha);
			string quote = JohnMilestoneQuote(JohnCommentQuote[pnum]);
			string heading = "JOHN";
			double commentScale = clamp(hudScale * 0.90, 1.15, 1.65);
			int availableWidth = max(98, faceX - 18);
			commentScale = min(commentScale,
				double(availableWidth - 24) / max(1, font.StringWidth(quote)));
			int panelWidth = min(availableWidth,
				max(int(font.StringWidth(quote) * commentScale),
					int(font.StringWidth(heading) * commentScale)) + 24);
			int panelHeight = int(34 * commentScale);
			int panelX = max(8, faceX - panelWidth - 10);
			int panelY = faceY + (faceSize - panelHeight) / 2;
			Screen.Dim(Color(3, 3, 3), 0.90 * alpha, panelX, panelY, panelWidth, panelHeight);
			Screen.DrawLineFrame(Color(185, 38, 25), panelX, panelY, panelWidth, panelHeight, 2);
			Screen.DrawText(font, Font.CR_RED, panelX + 10, panelY + int(4 * commentScale), heading,
				DTA_ScaleX, commentScale, DTA_ScaleY, commentScale, DTA_Alpha, alpha);
			Screen.DrawText(font, Font.CR_WHITE, panelX + 10, panelY + int(18 * commentScale), quote,
				DTA_ScaleX, commentScale, DTA_ScaleY, commentScale, DTA_Alpha, alpha);
		}
		if (overlayData && overlayData.PlayerClass == 4 && overlayData.DoomBloodPunchFlashTics > 0)
		{
			double flashStrength = 0.08 + 0.18 * overlayData.DoomBloodPunchFlashTics / 22.0;
			Screen.Dim(Color(155, 0, 0), flashStrength, 0, 0, sw, sh);
		}
		if (overlayData && overlayData.PlayerClass == 4 && overlayData.DoomFatalityTics > 0)
		{
			double fatalityPulse = 0.10 + 0.05 * sin((gametic + e.FracTic) * 22.0);
			if (overlayData.DoomFatalityImpactDone) fatalityPulse += 0.12;
			Screen.Dim(Color(115, 0, 0), fatalityPulse, 0, 0, sw, sh);
			double fatalityScale = clamp(hudScale * 1.55, 2.2, 3.4);
			string fatalityText = overlayData.DoomFatalityImpactDone ? "RIP AND TEAR" : "FATALITY";
			Screen.DrawText(BigFont, Font.CR_RED,
				(sw - BigFont.StringWidth(fatalityText) * fatalityScale) / 2,
				int(sh * 0.16), fatalityText,
				DTA_ScaleX, fatalityScale, DTA_ScaleY, fatalityScale,
				DTA_Alpha, min(1.0, 0.72 + fatalityPulse));
		}
		DrawOverheadHealthBars(e, pnum, font, sw, sh);
		DrawBossTarget(e, pnum, sw, sh);
		DrawDamageNumbers(e, pnum, font, sw, sh);
		DrawHealerSupplyStatus(pnum, classStatusFont, sw, sh, hudScale);
		DrawEngineerTurretStatus(pnum, classStatusFont, sw, sh, hudScale);
		DrawExecutionerStatus(pnum, classStatusFont, sw, sh, hudScale);
		DrawRogueStatus(pnum, classStatusFont, sw, sh, hudScale);
		DrawRogueBurstCrosshair(pnum, sw, sh, hudScale);
		DrawTankStatus(pnum, classStatusFont, sw, sh, hudScale);
		DrawDoomBloodPunchStatus(pnum, classStatusFont, sw, sh, hudScale);
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
			Font lootFont = "TINYBABY";
			double lootScale = min(clamp(hudScale * 1.35, 1.7, 2.4), double(sh - 48) / 210.0);
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
			int traitRows = !ClassesEnabled() ? TuinWeaponTraits.Slots(viewedDrop.Quality) : 0;
			int panelHeight = int((151 + traitRows * 16 + (!ClassesEnabled() ? 28 : 0)) * lootScale);
			int panelX = (sw - panelWidth) / 2;
			int panelY = min(int(sh * 0.48), sh - panelHeight - 16);
			int textX = panelX + int(10 * lootScale);
			int line = int(13 * lootScale);
			int color = WeaponQualityFontColor(viewedDrop.Quality);
			Screen.Dim(Color(8, 8, 14), 0.88, panelX, panelY, panelWidth, panelHeight);
			TuinWeaponTraits.FluidText(lootFont, color, textX, panelY + 6, TuinWeaponTraits.DisplayName(viewedDrop.WeaponType,
				viewedDrop.AffixFlags, viewedDrop.Quality, viewedDrop.VariantID), lootScale,
				panelWidth - 20 * lootScale, viewedDrop.Quality == 6, viewedDrop.Quality >= 2, viewedDrop.Quality == 5, viewedDrop.Quality);
			Screen.DrawText(lootFont, color, textX, panelY + 6 + line, String.Format("DROP: %s   LEVEL %d   SCORE %d", WeaponQualityName(viewedDrop.Quality), viewedDrop.ItemLevel, viewedScore), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			string currentLine = hasCurrent ? String.Format("CURRENT: %s   LEVEL %d   SCORE %d", WeaponQualityName(playerData.VariantQuality[equippedIndex]), playerData.VariantItemLevel[equippedIndex], equippedScore) : "CURRENT: NORMAL WEAPON - NO BONUSES";
			Screen.DrawText(lootFont, Font.CR_WHITE, textX, panelY + 6 + line * 2, currentLine, DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			string comparison = equippedIndex < 0 ? "NEW WEAPON VARIANT" : difference > 0 ? String.Format("UPGRADE  +%d SCORE", difference) : difference < 0 ? String.Format("LOWER  %d SCORE", difference) : "EQUAL GEAR SCORE";
			Screen.DrawText(lootFont, difference >= 0 ? Font.CR_GREEN : Font.CR_RED, textX, panelY + 6 + line * 3, comparison, DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(lootFont, WeaponStatComparisonColor(viewedDrop.HastePercent, currentHaste, hasCurrent), textX, panelY + 6 + line * 4, WeaponStatComparison("FIRE SPEED", viewedDrop.HastePercent, currentHaste, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			int viewedPower = WeaponTotalPowerPercent(viewedDrop.ItemLevel, viewedDrop.PowerPercent);
			Screen.DrawText(lootFont, WeaponStatComparisonColor(viewedPower, currentPower, hasCurrent), textX, panelY + 6 + line * 5, WeaponStatComparison("TOTAL DAMAGE", viewedPower, currentPower, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(lootFont, WeaponStatComparisonColor(viewedDrop.LeechPercent, currentLeech, hasCurrent), textX, panelY + 6 + line * 6, WeaponStatComparison("DAMAGE LEECH", viewedDrop.LeechPercent, currentLeech, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(lootFont, WeaponStatComparisonColor(viewedDrop.ExecutionPercent, currentExecution, hasCurrent), textX, panelY + 6 + line * 7, WeaponStatComparison("EXECUTION", viewedDrop.ExecutionPercent, currentExecution, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(lootFont, WeaponStatComparisonColor(viewedDrop.ProsperityPercent, currentProsperity, hasCurrent), textX, panelY + 6 + line * 8, WeaponStatComparison("KILL XP", viewedDrop.ProsperityPercent, currentProsperity, hasCurrent), DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			Screen.DrawText(lootFont, WeaponStatComparisonColor(viewedCritical, currentCritical, hasCurrent), textX,
				panelY + 6 + line * 9, WeaponStatComparison("CRITICAL", viewedCritical, currentCritical, hasCurrent),
				DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
			for (int row = 0; row < traitRows; row++)
			{
				int trait = TuinWeaponTraits.Nth(viewedDrop.AffixFlags, row);
				if (trait < 0) break;
				string traitLine = TuinWeaponTraits.Label(trait, viewedDrop.Quality);
				double traitScale = min(lootScale, double(panelWidth - 20) / max(1, lootFont.StringWidth(traitLine)));
				Screen.DrawText(lootFont, Font.CR_WHITE, textX, panelY + 6 + line * 10 + int(row * 16 * lootScale),
					traitLine, DTA_ScaleX, traitScale, DTA_ScaleY, traitScale);
			}
			bool closeEnough = WeaponPickupInReach[pnum];
			bool rogueRestricted = IsRogueOnlyWeaponType(viewedDrop.WeaponType) &&
				(!playerData || playerData.PlayerClass != 5);
			bool doomGuyRestricted = IsDoomGuyOnlyWeaponType(viewedDrop.WeaponType) &&
				(!playerData || playerData.PlayerClass != 4);
			bool heavyRestricted = IsHeavyOnlyWeaponType(viewedDrop.WeaponType) &&
				(!playerData || playerData.PlayerClass != 1);
			bool classRestricted = rogueRestricted || doomGuyRestricted || heavyRestricted;
			string prompt = classRestricted && !ClassesEnabled() ? "UNAVAILABLE IN UNIVERSAL BUILD" :
				rogueRestricted ? "ROGUE CLASS ONLY" :
				doomGuyRestricted ? "DOOM GUY CLASS ONLY" :
				heavyRestricted ? "HEAVY CLASS ONLY" : closeEnough ?
				(equippedIndex >= 0 ? "PRESS USE [E] TO SWAP - OLD WEAPON DROPS" : "PRESS USE [E] TO EQUIP") :
				"MOVE CLOSER TO INSPECT AND EQUIP";
			if (!ClassesEnabled() && !classRestricted)
			{
				bool holding = WeaponPickupHold[pnum] > 0 && WeaponPickupTarget[pnum] == viewedDrop;
				prompt = !closeEnough ? "MOVE CLOSER TO PICK UP" : WeaponPickupConsumed[pnum] ? "RELEASE USE [E] - THEN HOLD TO PICK UP" :
					holding ? "PICKING UP... KEEP HOLDING" : equippedIndex >= 0 ? "HOLD USE [E] 3 SEC TO SWAP - OLD VARIANT DROPS" : "HOLD USE [E] 3 SEC TO PICK UP WEAPON";
				double promptScale = min(lootScale, (panelWidth - 24.0) / max(1, lootFont.StringWidth(prompt)));
				double promptX = (sw - lootFont.StringWidth(prompt) * promptScale) / 2;
				int promptY = panelY + panelHeight - int(43 * lootScale);
				TuinWeaponTraits.FluidText(lootFont, closeEnough ? color : Font.CR_GRAY, promptX, promptY, prompt,
					promptScale, panelWidth - 24, viewedDrop.Quality == 6, closeEnough, viewedDrop.Quality == 5, viewedDrop.Quality);
				string hint = "TAP USE [E] FOR DOORS / SWITCHES";
				double hintScale = lootScale * .82;
				Screen.DrawText(lootFont, Font.CR_GRAY, (sw - lootFont.StringWidth(hint) * hintScale) / 2,
					promptY + 15 * lootScale, hint, DTA_ScaleX, hintScale, DTA_ScaleY, hintScale);
				int barX = panelX + int(12 * lootScale), barWidth = panelWidth - int(24 * lootScale);
				int barY = panelY + panelHeight - int(10 * lootScale), barHeight = max(2, int(4 * lootScale));
				Screen.Dim(Color(25,39,54), .95, barX, barY, barWidth, barHeight);
				double fill = holding ? clamp((WeaponPickupHold[pnum] + e.FracTic) / double(WEAPON_PICKUP_HOLD_TICS), 0., 1.) : 0;
				if (fill > 0)
				{
					int filled = max(1, int(barWidth * fill));
					Screen.Dim(Color(72,205,238), .95, barX, barY, filled, barHeight);
					Screen.Dim(Color(190,249,255), .4 + .25 * sin(MSTimeF() * .4),
						barX + filled - max(1, int(2 * lootScale)), barY - 1, max(1, int(2 * lootScale)), barHeight + 2);
				}
			}
			else Screen.DrawText(lootFont, classRestricted ? Font.CR_RED : closeEnough ? Font.CR_GOLD : Font.CR_WHITE,
				(sw - lootFont.StringWidth(prompt) * lootScale) / 2, panelY + panelHeight - int(15 * lootScale),
				prompt, DTA_ScaleX, lootScale, DTA_ScaleY, lootScale);
		}
		// The animated poison notice replaces both legacy poison labels.
		// Keep the legacy fallback when either modern HUD option is disabled.
		bool animatedPoison = !ClassesEnabled() && CVInt('tuin_modern_hud', 1)
			&& CVInt('tuin_combat_bonus_hud', 1);
		if (LootNotificationTics[pnum] > 0 && LootNotification[pnum].Length()
			&& !(animatedPoison && LootNotification[pnum] ~== "POISONED"))
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
		if (PoisonTics[pnum] > 0 && !animatedPoison)
		{
			double poisonScale = clamp(hudScale, 1.0, 1.7);
			string poisonText = String.Format("POISONED  %d", (PoisonTics[pnum] + 34) / 35);
			Screen.DrawText(font, Font.CR_GREEN, (sw - font.StringWidth(poisonText) * poisonScale) / 2,
				int(sh * 0.46), poisonText, DTA_ScaleX, poisonScale, DTA_ScaleY, poisonScale);
		}
		int activeHealthBarMode = CVInt('tuin_healthbar_mode', 1);
		if (TargetMaxHealth[pnum] > 0 && (ClassesEnabled() || !TargetIsBoss[pnum]) && (activeHealthBarMode == 0 || activeHealthBarMode == 2))
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
				string progress = String.Format("LV %d   XP %d/%d", pd.PlayerLevel, pd.CurrentXP,
					XPRequired(pd.PlayerLevel));
				string resources = String.Format("STAT %d   PERK %d   COINS %d", pd.UnspentStatPoints,
					pd.UnspentSkillPoints, CoinBalance(players[pnum].mo));
				string lives = String.Format("LIVES %d", pd.Lives);
				Font minimapFont = "TINYBABY";
				double statusScale = clamp(hudScale * 1.45, 2.0, 2.8);
				int statusX = 10;
				int statusY = 10;
				int statusWidth = max(max(int(minimapFont.StringWidth(progress) * statusScale),
					int(minimapFont.StringWidth(resources) * statusScale)), int(minimapFont.StringWidth(lives) * statusScale)) + 14;
				if (CVInt('tuin_minimap_enabled', 1))
				{
					int mapSize = clamp(CVInt('tuin_minimap_size', 320), 140, min(520, sh - 32));
					double mapHorizontal = clamp(CVFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
					double mapVertical = clamp(CVFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
					statusX = int(8 + (sw - mapSize - 16) * mapHorizontal);
					statusY = int(8 + (sh - mapSize - 16) * mapVertical) + mapSize +
						(CVInt('tuin_minimap_show_stats', 1) ? 33 : 7);
					statusWidth = mapSize;
				}
				Screen.Dim(Color(3, 5, 9), 0.93, statusX, statusY - 5, statusWidth, int(47 * statusScale));
				Screen.DrawText(minimapFont, Font.CR_GOLD, statusX + 6, statusY, progress,
					DTA_ScaleX, statusScale, DTA_ScaleY, statusScale);
				Screen.DrawText(minimapFont, Font.CR_GOLD, statusX + 6, statusY + int(13 * statusScale), resources,
					DTA_ScaleX, statusScale, DTA_ScaleY, statusScale);
				Screen.DrawText(minimapFont, pd.Lives > 1 ? Font.CR_RED : Font.CR_GOLD,
					statusX + 6, statusY + int(26 * statusScale), lives,
					DTA_ScaleX, statusScale, DTA_ScaleY, statusScale);
			}
		}
	}
}
