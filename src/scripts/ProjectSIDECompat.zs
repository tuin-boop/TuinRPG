// Standalone quick-grenade support adapted from Doom Deluxe. It intentionally
// has no dependency on Doom Deluxe's player class or weapon framework.
class PSQuickGrenadeVisual : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		DefaultStateUsage SUF_ACTOR|SUF_OVERLAY|SUF_WEAPON;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
	}

	States
	{
	Throw:
		HNDG A 1;
		HNDG B 1;
		HNDG C 2;
		HNDG D 2;
		HNDG E 3;
		HNDG F 2;
		HNDG GHI 1;
		HNDG K 1;
		HNDG L 2;
		HNDG MNO 1;
		HNDG PQQ 2;
		HNDG RS 2;
		Stop;

	Pin:
		GPIN ABCDEFG 1;
		Stop;
	}
}

class PSQuickGrenadeAmmo : Ammo
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 5;
		Ammo.BackpackAmount 1;
		Ammo.BackpackMaxAmount 8;
		Inventory.PickupMessage "Picked up a quick grenade.";
		Inventory.PickupSound "psgrenade/pickup";
		Inventory.Icon "GRNDA0";
		Radius 10;
		Height 8;
		Scale 0.5;
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		GRND A -1;
		Stop;
	}
}

// Standalone adaptations of Brutal Doom 22's grenade flame, smoke, flare,
// smoke-column and shockwave components.
class PSBrutalGrenadeFlame : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		Scale 1.15;
		RenderStyle "Add";
		Alpha 0.92;
		+FORCEXYBILLBOARD
		+BRIGHT
		+NOINTERACTION
		+NOGRAVITY
		+CLIENTSIDEONLY
	}

	States
	{
	Spawn:
		EXP3 BCDEFGHIJKLMN 1 Bright;
		EXP3 PQRSTUVW 1 Bright A_FadeOut(0.07);
		Stop;
	}
}

class PSBrutalGrenadeSmoke : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		Scale 2.0;
		RenderStyle "Translucent";
		Alpha 0.45;
		+FORCEXYBILLBOARD
		+NOINTERACTION
		+NOGRAVITY
		+CLIENTSIDEONLY
	}

	States
	{
	Spawn:
		SM9K ABCDEFGHIJKLMNOPQRSTUVWXYZ 2;
		Stop;
	}
}

class PSBrutalGrenadeSmokeColumn : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		XScale 1.6;
		YScale 0.8;
		RenderStyle "Translucent";
		Alpha 0.7;
		+FORCEXYBILLBOARD
		+NOINTERACTION
		+NOGRAVITY
		+CLIENTSIDEONLY
	}

	States
	{
	Spawn:
		SB17 ABCDEFG 3;
		SB17 ABCDEFGABCDEFGABCDEFGABCDEFG 3;
		SB17 ABCDEFG 3 A_FadeOut(0.10);
		Stop;
	}
}

class PSBrutalGrenadeFlare : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		XScale 2.0;
		YScale 1.5;
		RenderStyle "Add";
		Alpha 0.4;
		+FORCEXYBILLBOARD
		+BRIGHT
		+NOINTERACTION
		+NOGRAVITY
		+CLIENTSIDEONLY
	}

	States
	{
	Spawn:
		FLAR B 2 Bright;
		FLAR BBBBBBBBBBBB 1 Bright A_FadeOut(0.11);
		Stop;
	}
}

class PSQuickGrenadeExplosionFX : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		+NOINTERACTION
		+NOGRAVITY
		+CLIENTSIDEONLY
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		for (int i = 0; i < 4; i++)
		{
			Actor flame = Actor.Spawn("PSBrutalGrenadeFlame",
				Pos + (Random[PSBrutalFX](-18, 18), Random[PSBrutalFX](-18, 18),
				Random[PSBrutalFX](4, 34)), NO_REPLACE);
			if (flame)
				flame.Vel = (FRandom[PSBrutalFX](-1.5, 1.5),
					FRandom[PSBrutalFX](-1.5, 1.5), FRandom[PSBrutalFX](0.5, 2.5));
		}

		for (int j = 0; j < 5; j++)
		{
			Actor smoke = Actor.Spawn("PSBrutalGrenadeSmoke",
				Pos + (Random[PSBrutalFX](-22, 22), Random[PSBrutalFX](-22, 22),
				Random[PSBrutalFX](8, 38)), NO_REPLACE);
			if (smoke)
				smoke.Vel = (FRandom[PSBrutalFX](-1.2, 1.2),
					FRandom[PSBrutalFX](-1.2, 1.2), FRandom[PSBrutalFX](0.6, 2.2));
		}

		Actor.Spawn("PSBrutalGrenadeSmokeColumn", Pos, NO_REPLACE);
		Actor.Spawn("PSBrutalGrenadeFlare", Pos, NO_REPLACE);
		Actor.Spawn("PSBrutalGrenadeFlare", Pos + (36, 36, 0), NO_REPLACE);
		Actor.Spawn("PSBrutalGrenadeFlare", Pos + (36, -36, 0), NO_REPLACE);
		Actor.Spawn("PSBrutalGrenadeFlare", Pos + (-36, 36, 0), NO_REPLACE);
		Actor.Spawn("PSBrutalGrenadeFlare", Pos + (-36, -36, 0), NO_REPLACE);

		// Bright, fast horizontal particle ring in place of Brutal's shockwave actor.
		for (int k = 0; k < 48; k++)
		{
			double ringAngle = k * 7.5;
			A_SpawnParticle("FFB040", SPF_FULLBRIGHT, 24, 5.0, ringAngle,
				Cos(ringAngle) * 6.0, Sin(ringAngle) * 6.0, 8,
				Cos(ringAngle) * 8.0, Sin(ringAngle) * 8.0, 0,
				0, 0, 0, 0.9, -1, 0.25);
		}
	}

	States
	{
	Spawn:
		TNT1 A 2;
		Stop;
	}
}

class PSQuickGrenadeProjectile : Actor
{
	int FuseTics;

	Default
	{
		Radius 4;
		Height 4;
		Speed 35;
		Projectile;
		-NOGRAVITY
		Gravity 0.7;
		BounceType "Doom";
		BounceFactor 0.6;
		WallBounceFactor 0.3;
		BounceSound "psgrenade/bounce";
		Scale 0.7;
		Obituary "%o was caught by a grenade.";
		+BOUNCEONWALLS
		+BOUNCEONCEILINGS
		+ALLOWBOUNCEONACTORS
		-BOUNCEAUTOOFF
		+BOUNCEAUTOOFFFLOORONLY
		+FORCEXYBILLBOARD
		+FORCEPAIN
		+EXPLODEONWATER
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		FuseTics = 105;
	}

	override void Tick()
	{
		Super.Tick();
		if (--FuseTics <= 0)
		{
			ExplodeMissile();
			return;
		}

		if ((FuseTics & 3) == 0)
		{
			A_SpawnParticle("DarkGray", 0, 20, 2.0, 0, 0, 2,
				Vel.X * -0.05, Vel.Y * -0.05, 0.25, 0, 0, -0.04, 0.08);
		}
	}

	States
	{
	Spawn:
		GRND ABCDEFGH 2;
		Loop;

	Death:
		TNT1 A 0 Bright
		{
			A_Stop();
			A_NoGravity();
			A_StartSound("psgrenade/explode", CHAN_BODY);
			A_StartSound("psgrenade/explode_distant", CHAN_5);
			A_AlertMonsters(1024);
			// Brutal's concentric shrapnel bands: about 200 total close-range
			// damage with steadily diminishing damage out to 480 map units.
			A_Explode(67, 160);
			A_Explode(53, 240);
			A_Explode(40, 320);
			A_Explode(27, 400);
			A_Explode(13, 480);
			A_QuakeEx(5, 5, 5, 18, 0, 1000, "", QF_SCALEDOWN);
			A_SpawnItemEx("PSQuickGrenadeExplosionFX", 0, 0, 0,
				Flags: SXF_NOCHECKPOSITION);
		}
		Stop;
	}
}

// Normalizes only Doom's two starting weapons. This avoids keeping the base
// Fist/Pistol beside ProjectSIDE's replacements without replacing DoomPlayer.
class PSCompatWeaponHandler : EventHandler
{
	bool User1Held[MAXPLAYERS];
	bool GrenadeHidingWeapon[MAXPLAYERS];
	bool EngineerMineThrow[MAXPLAYERS];
	int ThrowTimer[MAXPLAYERS];
	int ThrowCooldown[MAXPLAYERS];

	override void PlayerEntered(PlayerEvent e)
	{
		NormalizeStartingWeapons(players[e.PlayerNumber].mo);
		SetupGrenades(e.PlayerNumber, true);
	}

	override void PlayerRespawned(PlayerEvent e)
	{
		NormalizeStartingWeapons(players[e.PlayerNumber].mo);
		SetupGrenades(e.PlayerNumber, true);
	}

	override void WorldTick()
	{
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo)
			{
				User1Held[i] = false;
				GrenadeHidingWeapon[i] = false;
				EngineerMineThrow[i] = false;
				ThrowTimer[i] = 0;
				ThrowCooldown[i] = 0;
				continue;
			}

			PlayerInfo p = players[i];
			PlayerPawn pawn = p.mo;
			bool user1Now = (p.cmd.buttons & BT_USER1) != 0;

			if (ThrowCooldown[i] > 0) ThrowCooldown[i]--;
			if (ThrowTimer[i] > 0)
			{
				ThrowTimer[i]--;
				if (!EngineerMineThrow[i] && ThrowTimer[i] == 26) PullGrenadePin(i, pawn);
				if (!EngineerMineThrow[i] && ThrowTimer[i] == 13) LaunchGrenade(pawn);
				if (EngineerMineThrow[i] && ThrowTimer[i] == 29)
					pawn.A_StartSound("tuin/mine/beep", CHAN_BODY, 0, 0.7);
				if (EngineerMineThrow[i] && ThrowTimer[i] == 15) LaunchEngineerMine(pawn);
				if (ThrowTimer[i] == 0) RestoreWeaponAfterGrenade(i, pawn);
			}

			if (user1Now && !User1Held[i] && ThrowTimer[i] == 0 &&
				ThrowCooldown[i] == 0 && pawn.health > 0)
			{
				StartGrenadeThrow(i, pawn);
			}

			User1Held[i] = user1Now;
		}
	}

	override void RenderOverlay(RenderEvent e)
	{
		int pnum = consoleplayer;
		if (menuactive || pnum < 0 || pnum >= MAXPLAYERS ||
			!playeringame[pnum] || !players[pnum].mo) return;

		Inventory ammo = players[pnum].mo.FindInventory("PSQuickGrenadeAmmo");
		int grenadeCount = ammo ? ammo.Amount : 0;
		bool engineer = IsEngineerPawn(players[pnum].mo);
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		// Keep the grenade counter close to the weapon ammo instead of competing
		// with the health and armor HUD in the lower left corner.
		int panelWidth = 112;
		int panelHeight = 58;
		int panelX = sw - panelWidth - 18;
		int panelY = sh - 160;
		TextureID grenadeIcon = TexMan.CheckForTexture(engineer ? "TMNEICON" : "TGRNICON");

		Screen.Dim(Color(120, 76, 18), 0.80, panelX - 2, panelY - 2, panelWidth + 4, panelHeight + 4);
		Screen.Dim(Color(0, 0, 0), 0.88, panelX, panelY, panelWidth, panelHeight);
		if (grenadeIcon.IsValid())
		{
			Screen.DrawTexture(grenadeIcon, false, panelX + (engineer ? 4 : 9), panelY + (engineer ? 10 : 5),
				DTA_DestWidth, engineer ? 54 : 44, DTA_DestHeight, engineer ? 40 : 48,
				DTA_LeftOffset, 0, DTA_TopOffset, 0, DTA_Alpha, 0.9);
		}
		Screen.DrawText(BigFont, grenadeCount > 0 ? Font.CR_GOLD : Font.CR_DARKGRAY,
			panelX + 72, panelY + 18, String.Format("%d", grenadeCount));
	}

	// The dedicated bind is more reliable than a generic +user button and also
	// works correctly in multiplayer. WorldTick keeps +user1 as a legacy fallback.
	override void NetworkProcess(ConsoleEvent e)
	{
		if (!(e.Name ~== "ps_quick_grenade") || e.Player < 0 ||
			e.Player >= MAXPLAYERS || !playeringame[e.Player]) return;

		PlayerPawn pawn = players[e.Player].mo;
		if (!pawn) return;

		if (!pawn.FindInventory("PSQuickGrenadeVisual"))
			SetupGrenades(e.Player, true);

		if (ThrowTimer[e.Player] == 0 && ThrowCooldown[e.Player] == 0 && pawn.health > 0)
			StartGrenadeThrow(e.Player, pawn);
	}

	override void WorldThingDied(WorldEvent e)
	{
		if (e.Thing && e.Thing.bIsMonster && Random[PSGrenadeDrops](0, 11) == 0)
		{
			Actor dropped = Actor.Spawn("PSQuickGrenadeAmmo", e.Thing.Pos + (0, 0, 8), ALLOW_REPLACE);
			if (dropped) dropped.bDropped = true;
		}
	}

	override void CheckReplacement(ReplaceEvent e)
	{
		if (!e.Replacee || Random[PSGrenadeAmmoSwap](0, 9) != 0) return;

		name itemName = e.Replacee.GetClassName();
		if (itemName == 'Clip' || itemName == 'Shell' ||
			itemName == 'RocketAmmo' || itemName == 'Cell')
		{
			e.Replacement = 'PSQuickGrenadeAmmo';
		}
	}

	void SetupGrenades(int playerNumber, bool giveStartingGrenades)
	{
		PlayerPawn pawn = players[playerNumber].mo;
		if (!pawn) return;

		bool firstSetup = !pawn.FindInventory("PSQuickGrenadeVisual");
		if (firstSetup)
			pawn.GiveInventory("PSQuickGrenadeVisual", 1);
		if (!pawn.FindInventory("TuinEngineerMineVisual"))
			pawn.GiveInventory("TuinEngineerMineVisual", 1);

		if (giveStartingGrenades && firstSetup && !pawn.FindInventory("PSQuickGrenadeAmmo"))
		{
			pawn.GiveInventory("PSQuickGrenadeAmmo", 2);
		}

		User1Held[playerNumber] = false;
		GrenadeHidingWeapon[playerNumber] = false;
		EngineerMineThrow[playerNumber] = false;
		ThrowTimer[playerNumber] = 0;
		ThrowCooldown[playerNumber] = 0;
	}

	void StartGrenadeThrow(int playerNumber, PlayerPawn pawn)
	{
		Inventory ammo = pawn.FindInventory("PSQuickGrenadeAmmo");
		bool engineer = IsEngineerPawn(pawn);
		Inventory visual = pawn.FindInventory(engineer ? "TuinEngineerMineVisual" : "PSQuickGrenadeVisual");
		if (!visual || !pawn.player) return;
		if (!ammo || ammo.Amount <= 0)
		{
			pawn.A_Print(engineer ? "No proximity mines." : "No quick grenades.");
			pawn.A_StartSound("weapons/noammo", CHAN_WEAPON);
			return;
		}

		pawn.TakeInventory("PSQuickGrenadeAmmo", 1);

		Weapon currentWeapon = pawn.player.ReadyWeapon;
		name currentWeaponName = currentWeapon ? currentWeapon.GetClassName() : 'None';
		bool hideMeleeWeapon = engineer || currentWeaponName == 'PerkFist' ||
			currentWeaponName == 'Fist' || currentWeaponName == 'Z86Chainsaw' ||
			currentWeaponName == 'Chainsaw';

		if (hideMeleeWeapon)
		{
			// These weapons already show arms, so hide them during the grenade throw.
			pawn.player.SetPSprite(PSP_WEAPON, null);
			pawn.player.SetPSprite(PSP_FLASH, null);
			GrenadeHidingWeapon[playerNumber] = true;
		}
		else
		{
			// Normal guns remain visible; resetting to Ready still cancels a reload.
			if (currentWeapon)
				pawn.player.SetPSprite(PSP_WEAPON, currentWeapon.GetReadyState());
			GrenadeHidingWeapon[playerNumber] = false;
		}

		pawn.player.SetPSprite(1001, visual.FindState("Throw"));
		if (hideMeleeWeapon) AdjustMeleeGrenadeLayer(pawn.player, 1001);
		EngineerMineThrow[playerNumber] = engineer;
		ThrowTimer[playerNumber] = engineer ? 35 : 28;
		ThrowCooldown[playerNumber] = engineer ? 45 : 38;
	}

	void RestoreWeaponAfterGrenade(int playerNumber, PlayerPawn pawn)
	{
		if (!GrenadeHidingWeapon[playerNumber] || !pawn || !pawn.player) return;

		pawn.player.SetPSprite(1001, null);
		pawn.player.SetPSprite(1002, null);
		if (pawn.health > 0 && pawn.player.ReadyWeapon)
			pawn.player.SetPSprite(PSP_WEAPON, pawn.player.ReadyWeapon.GetReadyState());
		GrenadeHidingWeapon[playerNumber] = false;
		EngineerMineThrow[playerNumber] = false;
	}

	void AdjustMeleeGrenadeLayer(PlayerInfo p, int layerID)
	{
		PSprite grenadeLayer = p.FindPSprite(layerID);
		if (!grenadeLayer) return;

		grenadeLayer.Y += 30;
		grenadeLayer.ResetInterpolation();
	}

	void PullGrenadePin(int playerNumber, PlayerPawn pawn)
	{
		if (!pawn || !pawn.player || pawn.health <= 0) return;

		Inventory visual = pawn.FindInventory("PSQuickGrenadeVisual");
		if (!visual) return;

		// Doom Deluxe starts its GPIN layer and pull sound on HNDG frame C.
		pawn.player.SetPSprite(1002, visual.FindState("Pin"));
		if (GrenadeHidingWeapon[playerNumber])
			AdjustMeleeGrenadeLayer(pawn.player, 1002);
		pawn.A_StartSound("psgrenade/pin", CHAN_WEAPON);
	}

	void LaunchGrenade(PlayerPawn pawn)
	{
		if (!pawn || !pawn.player || pawn.health <= 0) return;

		FTranslatedLineTarget aimTarget;
		Actor grenade = pawn.SpawnPlayerMissile("PSQuickGrenadeProjectile",
			pawn.Angle, 12, 0, 10, aimTarget, false, true);
		if (grenade)
		{
			double runBoost = Clamp(1.0 + (pawn.Vel.XY Dot pawn.Angle.ToVector()) * 0.04,
				1.0, 1.6);
			grenade.Vel *= runBoost;
			grenade.Vel.Z += 5.0;
			grenade.Vel += pawn.Vel * 0.45;
		}
		pawn.A_StartSound("psgrenade/toss", CHAN_WEAPON);
	}

	clearscope static bool IsEngineerPawn(PlayerPawn pawn)
	{
		if (!pawn) return false;
		let data = TuinPlayerData(pawn.FindInventory('TuinPlayerData'));
		return data && data.PlayerClass == 6;
	}

	void LaunchEngineerMine(PlayerPawn pawn)
	{
		if (!pawn || !pawn.player || pawn.health <= 0) return;

		FTranslatedLineTarget aimTarget;
		Actor mine = pawn.SpawnPlayerMissile("TuinEngineerMineProjectile",
			pawn.Angle, 12, 0, 7, aimTarget, false, true);
		if (mine)
		{
			mine.Vel.Z += 2.5;
			mine.Vel += pawn.Vel * 0.35;
		}
		pawn.A_StartSound("tuin/mine/throw", CHAN_WEAPON);
	}

	void NormalizeStartingWeapons(PlayerPawn playerPawn)
	{
		if (!playerPawn) return;

		if (playerPawn.FindInventory("Fist") || playerPawn.FindInventory("PerkFist"))
		{
			playerPawn.TakeInventory("Fist", 0x7FFFFFFF);
			playerPawn.TakeInventory("PerkFist", 0x7FFFFFFF);
			playerPawn.GiveInventory("PerkFist", 1);
		}

		if (playerPawn.FindInventory("Pistol") || playerPawn.FindInventory("PerkPistol"))
		{
			playerPawn.TakeInventory("Pistol", 0x7FFFFFFF);
			playerPawn.TakeInventory("PerkPistol", 0x7FFFFFFF);
			playerPawn.GiveInventory("PerkPistol", 1);
		}
	}
}
