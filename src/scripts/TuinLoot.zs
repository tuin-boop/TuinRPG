class TuinWeaponDrop : Actor
{
	int VariantID;
	class<Weapon> WeaponType;
	int ItemLevel;
	int Quality;
	int AffixFlags;
	int HastePercent;
	int PowerPercent;
	int LeechPercent;
	int ExecutionPercent;
	int ProsperityPercent;
	int Age;
	int NudgeCooldown;
	string DisplayName;
	bool CatchupReward;
	int CatchupPlayerNumber;

	clearscope static Color QualityColor(int quality)
	{
		switch (quality)
		{
		case 1: return Color(48, 220, 72);
		case 2: return Color(40, 190, 255);
		case 3: return Color(255, 128, 24);
		case 4: return Color(255, 190, 40);
		case 5: return Color(190, 40, 255);
		case 6: return Color(170, 255, 255);
		case 7: return Color(255, 72, 16);
		default: return Color(255, 255, 255);
		}
	}

	void ConfigureVisuals()
	{
		bool unarmedPickup = false;
		if (WeaponType)
		{
			readonly<Weapon> def = GetDefaultByType(WeaponType);
			if (def)
			{
				string label = def.GetTag(def.GetClassName());
				unarmedPickup = def.GetClassName() == 'Fist' || label ~== "FIST" ||
					label ~== "FISTS" || label ~== "BRASS KNUCKLES" || label ~== "KNUCKLES" ||
					label ~== "BARE HANDS" || label ~== "UNARMED" || label ~== "PUNCH" ||
					label ~== "PUNCHES" || label ~== "MARTIAL ARTS";
			}
			if (def && def.SpawnState)
			{
				SetState(def.SpawnState, true);
				Tics = -1;
			}
		}
		// First-person fist sprites commonly have no world offset and disappear below
		// the floor. Use our normalized pickup billboard for fists and knuckles.
		if (unarmedPickup)
		{
			SetState(FindState('KnucklePickup'), true);
			Scale = (0.49, 0.49);
			Tics = -1;
		}
		Color col = QualityColor(Quality);
		SetShade(col);
		A_SetRenderStyle(0.92, STYLE_Shaded);
		int innerRadius = 24 + Quality * 5;
		int outerRadius = 40 + Quality * 10;
		A_AttachLight('TuinLootGlow', Quality >= 4 ? 1 : 0, col, innerRadius, outerRadius, 0,
			(0, 0, Height * 0.5), Quality >= 6 ? 1.0 : Quality >= 4 ? 0.75 : 0.0);
	}

	override void Tick()
	{
		Super.Tick();
		Age++;
		let lifetimeCV = CVar.FindCVar('tuin_weapon_drop_lifetime');
		int lifetime = clamp(lifetimeCV ? lifetimeCV.GetInt() : 90, 15, 600) * 35;
		if (Age >= lifetime)
		{
			Destroy();
			return;
		}
		// Let each impulse die away quickly; loot should hop off awkward geometry,
		// not behave like a continuously homing coin.
		Vel.X *= 0.82;
		Vel.Y *= 0.82;

		if (NudgeCooldown > 0)
		{
			NudgeCooldown--;
			return;
		}

		Actor nearestPlayer;
		double nearestDistance = 224.0;
		// Catch-up choices stay loyal to the player they were spawned for.
		if (CatchupReward && CatchupPlayerNumber >= 0 && CatchupPlayerNumber < MAXPLAYERS &&
			playerInGame[CatchupPlayerNumber] && players[CatchupPlayerNumber].mo &&
			players[CatchupPlayerNumber].mo.Health > 0)
		{
			Actor intendedPlayer = players[CatchupPlayerNumber].mo;
			double intendedDistance = Distance2D(intendedPlayer);
			if (intendedDistance < nearestDistance && CheckSight(intendedPlayer, SF_IGNOREWATERBOUNDARY))
			{
				nearestDistance = intendedDistance;
				nearestPlayer = intendedPlayer;
			}
		}
		else
		{
			for (int playerNumber = 0; playerNumber < MAXPLAYERS; playerNumber++)
			{
				if (!playerInGame[playerNumber] || !players[playerNumber].mo ||
					players[playerNumber].mo.Health <= 0) continue;
				Actor candidate = players[playerNumber].mo;
				double distance = Distance2D(candidate);
				if (distance >= nearestDistance || !CheckSight(candidate, SF_IGNOREWATERBOUNDARY)) continue;
				nearestDistance = distance;
				nearestPlayer = candidate;
			}
		}

		if (!nearestPlayer || nearestDistance < 28.0) return;
		double deltaX = nearestPlayer.Pos.X - Pos.X;
		double deltaY = nearestPlayer.Pos.Y - Pos.Y;
		double distance = max(1.0, sqrt(deltaX * deltaX + deltaY * deltaY));
		double nudgeSpeed = distance < 96.0 ? 1.8 : 1.25;
		Vel.X = deltaX / distance * nudgeSpeed;
		Vel.Y = deltaY / distance * nudgeSpeed;
		// Horizontal movement carries loot over an edge; gravity handles the fall.
		// Never add upward velocity here, or repeated nudges can make a drop climb.
		NudgeCooldown = 14;
	}

	Default
	{
		Radius 12;
		Height 16;
		Gravity 0.8;
		+NOBLOCKMAP
		+RELATIVETOFLOOR
		+FORCEXYBILLBOARD
	}

	States
	{
	KnucklePickup:
		TKNK A -1;
		Stop;
	Spawn:
		TNT1 A -1;
		Stop;
	}
}

class TuinCoinPickup : Inventory
{
	override void PlayPickupSound(Actor toucher)
	{
		if (toucher)
			toucher.A_StartSound("pickups/tuincoin", CHAN_ITEM,
				CHANF_NOPAUSE | CHANF_MAYBE_LOCAL | CHANF_OVERLAP, 1.0, ATTN_NONE);
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		A_AttachLight('TuinCoinGlow', DynamicLight.PointLight, Color(255, 190, 32), 28, 42,
			DynamicLight.LF_ATTENUATE, (0, 0, 10));
	}

	override void Tick()
	{
		Super.Tick();
		if (Owner) return;

		Actor nearestPlayer;
		double nearestDistance = 320.0;
		for (int playerNumber = 0; playerNumber < MAXPLAYERS; playerNumber++)
		{
			if (!playerInGame[playerNumber] || !players[playerNumber].mo ||
				players[playerNumber].mo.Health <= 0) continue;
			Actor candidate = players[playerNumber].mo;
			double distance = Distance2D(candidate);
			if (distance >= nearestDistance || !CheckSight(candidate, SF_IGNOREWATERBOUNDARY)) continue;
			nearestDistance = distance;
			nearestPlayer = candidate;
		}

		if (!nearestPlayer)
		{
			Vel.X *= 0.75;
			Vel.Y *= 0.75;
			return;
		}

		double deltaX = nearestPlayer.Pos.X - Pos.X;
		double deltaY = nearestPlayer.Pos.Y - Pos.Y;
		double distance = max(1.0, sqrt(deltaX * deltaX + deltaY * deltaY));
		double speed = clamp(6.0 + (320.0 - distance) * 0.025, 6.0, 14.0);
		Vel.X = deltaX / distance * speed;
		Vel.Y = deltaY / distance * speed;
	}

	override bool TryPickup(in out Actor toucher)
	{
		int collected = Amount;
		A_RemoveLight('TuinCoinGlow');
		bool pickedUp = Super.TryPickup(toucher);
		if (pickedUp && toucher)
		{
			let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
			if (data) data.LevelCoinsEarned += max(0, collected);
		}
		return pickedUp;
	}

	Default
	{
		Radius 10;
		Height 12;
		Scale 0.005;
		Inventory.MaxAmount 999999;
		Inventory.InterHubAmount 999999;
		Inventory.PickupMessage "Picked up Tuin coins.";
		Inventory.PickupSound "pickups/tuincoin";
		+INVENTORY.KEEPDEPLETED
		+INVENTORY.UNDROPPABLE
		+FLOATBOB
		+RELATIVETOFLOOR
	}

	States
	{
	Spawn:
		TCIN A -1 Bright;
		Stop;
	}
}

class TuinLifePickup : Inventory
{
	override void BeginPlay()
	{
		Super.BeginPlay();
		A_AttachLight('TuinLifeGlow', DynamicLight.PulseLight, Color(255, 28, 18), 46, 78,
			DynamicLight.LF_ATTENUATE, (0, 0, 20), 0.55);
	}

	override void Tick()
	{
		Super.Tick();
		if ((level.Time % 6) == 0)
			A_SpawnParticle(Color(255, 54, 22), SPF_FULLBRIGHT | SPF_FACECAMERA, 13, 3.0, 0,
				FRandom[TuinLifeSpark](-11.0, 11.0), FRandom[TuinLifeSpark](-4.0, 4.0),
				FRandom[TuinLifeSpark](2.0, 38.0), 0, 0, 0.35, 0, 0, -0.02, 0.18, 0.05);
	}

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
		if (!data) return false;
		int maximum = clamp(CVar.FindCVar('tuin_max_lives') ? CVar.FindCVar('tuin_max_lives').GetInt() : 9, 3, 99);
		if (data.Lives >= maximum)
		{
			toucher.A_Log(String.Format("LIVES FULL: %d / %d", data.Lives, maximum));
			return false;
		}
		data.Lives++;
		toucher.A_StartSound("misc/i_pkup", CHAN_ITEM);
		toucher.A_Log(String.Format("EXTRA LIFE! %d LIVES", data.Lives));
		A_RemoveLight('TuinLifeGlow');
		GoAwayAndDie();
		return true;
	}

	Default
	{
		Radius 16;
		Height 30;
		Scale 0.04;
		Inventory.PickupMessage "Extra life!";
		+FLOATBOB
		+RELATIVETOFLOOR
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		TLIF A -1 Bright;
		Stop;
	}
}

class TuinLifeEssencePickup : Inventory
{
	override void BeginPlay()
	{
		Super.BeginPlay();
		A_AttachLight('TuinLifeEssenceGlow', DynamicLight.PulseLight,
			Color(70, 255, 130), 32, 56, DynamicLight.LF_ATTENUATE, (0, 0, 12), 0.65);
	}

	override void Tick()
	{
		Super.Tick();
		if ((level.Time % 7) == 0)
			A_SpawnParticle(Color(85, 255, 145), SPF_FULLBRIGHT | SPF_FACECAMERA,
				11, 2.2, 0, FRandom[TuinLifeEssenceSpark](-8.0, 8.0),
				FRandom[TuinLifeEssenceSpark](-8.0, 8.0),
				FRandom[TuinLifeEssenceSpark](1.0, 22.0), 0, 0,
				FRandom[TuinLifeEssenceSpark](0.25, 0.9), 0, 0, -0.015, 0.12, 0.04);
	}

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player || toucher.Health <= 0) return false;
		let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
		if (!data) return false;
		let handler = TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
		if (handler)
		{
			handler.GrantLifeEssenceOverhealth(toucher, data);
			handler.SetLootNotification(toucher.PlayerNumber(),
				"LIFE ESSENCE   +30 TEMPORARY HEALTH", 1);
		}
		// This pickup is consumed manually instead of through Super.TryPickup,
		// so play its randomized cue explicitly on a channel other pickups do not use.
		toucher.A_StartSound("pickups/lifeessence", CHAN_6);
		A_RemoveLight('TuinLifeEssenceGlow');
		GoAwayAndDie();
		return true;
	}

	Default
	{
		Radius 12;
		Height 20;
		Scale 0.4;
		Inventory.PickupMessage "Life Essence absorbed.";
		Inventory.PickupSound "pickups/lifeessence";
		+FLOATBOB
		+RELATIVETOFLOOR
		+INVENTORY.ALWAYSPICKUP
		-COUNTITEM
	}

	States
	{
	Spawn:
		LIFE A -1 Bright;
		Stop;
	}
}

class TuinJohnShopNPC : Actor
{
	Default
	{
		Radius 18;
		Height 56;
		Scale 0.9375;
		Mass 1000;
		-SOLID
		+FRIENDLY
		+NOTARGET
		+NOBLOOD
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		JOHN A -1;
		Stop;
	}
}

// A rare adaptive-director ambusher. It deliberately reuses the stock Imp
// states so it remains readable in Doom and compatible with gore/voxel packs.
class TuinAssassinImp : DoomImp
{
	Default
	{
		Tag "Assassin Imp";
		Health 120;
		Speed 14;
		PainChance 96;
		Scale 0.90;
		RenderStyle "Translucent";
		Alpha 0.68;
		+SHADOW
		+AMBUSH
	}
}

// Map-specific replacements selected by TuinRPGHandler.CheckReplacement.
// Their attacks and visuals remain entirely stock; only the final A_BossDeath
// frame is omitted so John, rather than Doom's hard-coded episode ending,
// controls the E2M8/E3M8 transition.
class TuinFinaleCyberdemon : Cyberdemon
{
	Default
	{
		-BOSSDEATH
		-E2M8BOSS
	}
	States
	{
	Death:
		CYBR H 10;
		CYBR I 10 A_Scream;
		CYBR JKL 10;
		CYBR M 10 A_NoBlocking;
		CYBR NO 10;
		CYBR P -1;
		Stop;
	}
}

class TuinFinaleSpiderMastermind : SpiderMastermind
{
	Default
	{
		-BOSSDEATH
		-E3M8BOSS
	}
	States
	{
	Death:
		SPID J 20 A_Scream;
		SPID K 10 A_NoBlocking;
		SPID LMNOPQR 10;
		SPID S -1;
		Stop;
	}
}
