class TuinBossRewardChestOpenVisual : Actor
{
	Default
	{
		Scale 0.35;
		+NOGRAVITY
		-SOLID
	}
	States
	{
	Spawn:
		TBCO A -1;
		Stop;
	}
}

class TuinBossRewardChestMinecraftOpenVisual : Actor
{
	Default
	{
		Scale 0.75;
		+NOGRAVITY
		-SOLID
	}
	States
	{
	Spawn:
		TBCO ABCDEFGH 2;
		TBCO H -1;
		Stop;
	}
}

class TuinBossRewardChest : Actor
{
	class<Weapon> RewardWeapon;
	int RewardLevel;
	int RewardQuality;
	int OpenClock;
	int BodyPushClock;
	bool Opened;
	bool RewardReleased;
	Actor OpenVisual;
	bool NotifiedPlayer[8];

	Default
	{
		Scale 0.35;
		Radius 22;
		Height 42;
		Tag "Boss reward chest - press Use";
		+USESPECIAL
		+SPECIAL
		+NOTAUTOAIMED
		+NOBLOOD
		-SOLID
		Activation THINGSPEC_Activate;
	}

	States
	{
	Spawn:
		TBCS A -1;
		Stop;
	Open:
		TNT1 A -1;
		Stop;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_AttachLight('TuinBossChestGlow', DynamicLight.PulseLight,
			Color(255, 70, 24), 50, 95, DynamicLight.LF_ATTENUATE,
			(0, 0, 20), 0.7);
	}

	void PushNearbyBodies()
	{
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor body;
		while (body = Actor(iterator.Next()))
		{
			if (body == self || body.Health > 0 ||
				!(body.bCORPSE || body.bISMONSTER) ||
				abs(body.Pos.Z - Pos.Z) > 64.0) continue;
			double dx = body.Pos.X - Pos.X;
			double dy = body.Pos.Y - Pos.Y;
			double distance = sqrt(dx * dx + dy * dy);
			double clearRadius = Radius + clamp(body.Radius, 8.0, 36.0) + 12.0;
			if (distance >= clearRadius) continue;
			if (distance < 1.0)
			{
				dx = cos(Angle);
				dy = sin(Angle);
				distance = 1.0;
			}
			// Move the corpse outside the model immediately. Try alternate angles
			// when the nearest direction runs into a wall or another obstacle.
			Vector3 oldPosition = body.Pos;
			double baseAngle = atan2(dy, dx);
			bool cleared;
			for (int direction = 0; direction < 8; direction++)
			{
				double candidateAngle = baseAngle + direction * 45.0;
				body.SetOrigin((Pos.X + cos(candidateAngle) * (clearRadius + 8.0),
					Pos.Y + sin(candidateAngle) * (clearRadius + 8.0), oldPosition.Z), false);
				if (body.TestMobjLocation())
				{
					cleared = true;
					break;
				}
			}
			if (cleared) continue;
			body.SetOrigin(oldPosition, false);
			// If no free spot exists, at least keep applying an outward impulse.
			body.Vel.X = dx / distance * 8.0;
			body.Vel.Y = dy / distance * 8.0;
			body.Vel.Z = max(body.Vel.Z, 1.5);
		}
	}

	override void Tick()
	{
		Super.Tick();
		BodyPushClock++;
		if ((BodyPushClock % 4) == 0) PushNearbyBodies();

		if (!Opened)
		{
			if ((level.Time % 6) == 0)
			{
				double sparkAngle = FRandom[TuinBossChestFX](0.0, 360.0);
				A_SpawnParticle(Color(255, 100, 30), SPF_FULLBRIGHT | SPF_FACECAMERA,
					18, 3.2, sparkAngle, cos(sparkAngle) * 17.0,
					sin(sparkAngle) * 17.0, FRandom[TuinBossChestFX](7.0, 30.0),
					0, 0, 0.45, 0, 0, 0.01, 0.8, 0.045, -0.07);
			}
			for (int i = 0; i < 8; i++)
			{
				if (NotifiedPlayer[i] || !playerInGame[i] || !players[i].mo ||
					players[i].mo.Health <= 0 || Distance2D(players[i].mo) > 112.0) continue;
				players[i].mo.A_Print("Boss reward chest: press Use to open.");
				NotifiedPlayer[i] = true;
			}
			return;
		}

		OpenClock++;
		if (!RewardReleased && OpenClock >= 14)
		{
			RewardReleased = true;
			let handler = TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
			if (handler) handler.ReleaseBossChestReward(self);
		}
		// Leave the open chest visible for six seconds, then shrink it away
		// during the seventh. The weapon reward is a separate actor.
		if (OpenVisual && OpenClock >= 35 * 6)
		{
			double baseScale = self is 'TuinBossRewardChestMinecraft' ? 0.75 : 0.35;
			double shrink = clamp((35.0 * 7.0 - OpenClock) / 35.0, 0.01, 1.0);
			OpenVisual.Scale = (baseScale * shrink, baseScale * shrink);
		}
		if (OpenClock >= 35 * 7)
		{
			if (OpenVisual) OpenVisual.Destroy();
			Destroy();
		}
	}

	override bool Used(Actor user)
	{
		if (Opened || !user || !user.player || user.Health <= 0) return false;
		Opened = true;
		SetState(FindState('Open'), true);
		class<Actor> visualClass = self is 'TuinBossRewardChestMinecraft' ?
			'TuinBossRewardChestMinecraftOpenVisual' : 'TuinBossRewardChestOpenVisual';
		OpenVisual = Actor.Spawn(visualClass, Pos, NO_REPLACE);
		if (OpenVisual) OpenVisual.Angle = Angle;
		A_RemoveLight('TuinBossChestGlow');
		A_AttachLight('TuinBossChestOpenGlow', DynamicLight.PulseLight,
			Color(255, 202, 58), 68, 120, DynamicLight.LF_ATTENUATE,
			(0, 0, 28), 0.55);
		A_StartSound("tuin/chest/open", CHAN_BODY, 0, 0.95);
		for (int i = 0; i < 30; i++)
		{
			double burstAngle = i * 12.0;
			A_SpawnParticle(i & 1 ? Color(255, 208, 70) : Color(255, 92, 30),
				SPF_FULLBRIGHT | SPF_FACECAMERA, 22, 3.5, burstAngle,
				cos(burstAngle) * 15.0, sin(burstAngle) * 15.0, 34.0,
				cos(burstAngle) * 0.8, sin(burstAngle) * 0.8,
				FRandom[TuinBossChestFX](1.0, 2.2), 0, 0, -0.06,
				0.95, 0.045, -0.08);
		}
		user.A_Print("Boss chest opened! Your reward is emerging.");
		return true;
	}
}

class TuinBossRewardChestMinecraft : TuinBossRewardChest
{
	Default
	{
		Scale 0.75;
	}
}

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
	bool SeparatingLoot;
	bool SafeSeparationStep(Vector2 impulse)
	{
		// Check the full damped travel distance, not just the next tick. This
		// prevents repulsion from sending loot through a wall or off a pedestal.
		FCheckPosition check;
		Vector2 destination = (Pos.X + impulse.X * 6, Pos.Y + impulse.Y * 6);
		if (!CheckMove(destination, 0, check)) return false;
		return abs(check.floorz - FloorZ) <= 4 && check.dropoffz >= FloorZ - 4 &&
			check.ceilingz - max(Pos.Z, check.floorz) >= Height;
	}
	bool PushNearbyWeapons()
	{
		// Loot deliberately has NOBLOCKMAP, so iterate only our drop class.
		ThinkerIterator iterator = ThinkerIterator.Create('TuinWeaponDrop');
		TuinWeaponDrop other;
		Vector2 push = (0, 0);
		while (other = TuinWeaponDrop(iterator.Next()))
		{
			if (other == self || abs(other.Pos.Z - Pos.Z) > 24) continue;
			double dx = Pos.X - other.Pos.X;
			double dy = Pos.Y - other.Pos.Y;
			double clearance = Radius + other.Radius + 16;
			if (abs(dx) >= clearance || abs(dy) >= clearance) continue;
			double distance = sqrt(dx * dx + dy * dy);
			if (distance >= clearance) continue;
			if (distance < .1)
			{
				// Deterministic opposite directions even for identical spawn positions.
				double angle = ((min(VariantID, other.VariantID) * 137) % 360);
				if (VariantID > other.VariantID) angle += 180;
				dx = cos(angle); dy = sin(angle); distance = 1;
			}
			double force = clamp((clearance - distance) * .12, .3, 3.);
			push += (dx / distance * force, dy / distance * force);
		}
		if (push.Length() < .01) return false;
		if (push.Length() > 4) push *= 4 / push.Length();
		if (!SafeSeparationStep(push))
		{
			// Slide along a safe axis if the full diagonal is blocked.
			if (abs(push.X) > .01 && SafeSeparationStep((push.X, 0))) push.Y = 0;
			else if (abs(push.Y) > .01 && SafeSeparationStep((0, push.Y))) push.X = 0;
			else { Vel.X = Vel.Y = 0; NudgeCooldown = 14; return false; }
		}
		Vel.X = push.X; Vel.Y = push.Y;
		SeparatingLoot = true;
		// Give separation time to settle before the pickup's player nudge resumes.
		NudgeCooldown = 14;
		return true;
	}
	void PushNearbyBodies()
	{
		// Local blockmap query: large loot piles must not scan the whole map.
		let nearby = BlockThingsIterator.Create(self, 160);
		while (nearby.Next())
		{
			Actor body = nearby.thing;
			if (!body || body == self || body.player || body.Health > 0 ||
				!(body.bCORPSE || body.bISMONSTER) ||
				abs(body.Pos.Z - FloorZ) > 32) continue;
			double dx = body.Pos.X - Pos.X;
			double dy = body.Pos.Y - Pos.Y;
			double distance = sqrt(dx * dx + dy * dy);
			double clearance = Radius + clamp(body.Radius, 8., 48.) + 64.;
			if (distance >= clearance) continue;
			if (distance < 1.)
			{
				dx = cos(body.Angle + Angle);
				dy = sin(body.Angle + Angle);
				distance = 1.;
			}
			// A bounded horizontal shove uses normal collision instead of teleporting
			// bodies through walls. Never damage, launch or delete the corpse.
			double speed = clamp((clearance - distance) * .3, 2., 8.);
			body.Vel.X = dx / distance * speed;
			body.Vel.Y = dy / distance * speed;
		}
	}

	clearscope static Color QualityColor(int quality)
	{
		switch (quality)
		{
		case 1: return Color(48, 220, 72);
		case 2: return Color(40, 190, 255);
		case 3: return Color(233, 94, 24);
		case 4: return Color(255, 224, 65);
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
		if (SeparatingLoot && !SafeSeparationStep((Vel.X, Vel.Y))) Vel.X = Vel.Y = 0;
		if (!TuinRPGHandler.ClassesEnabled() && (Age == 1 || ((Age + VariantID) % 4) == 0))
			PushNearbyBodies();
		if (!TuinRPGHandler.ClassesEnabled())
		{
			int adjustedFlags = TuinWeaponTraits.Roll(AffixFlags, Quality, VariantID, WeaponType);
			if (adjustedFlags != AffixFlags)
			{
				AffixFlags = adjustedFlags;
				DisplayName = TuinRPGHandler.WeaponVariantName(WeaponType, AffixFlags, Quality, VariantID);
			}
		}
		let lifetimeCV = CVar.FindCVar('tuin_weapon_drop_lifetime');
		int lifetime = clamp(lifetimeCV ? lifetimeCV.GetInt() : 90, 15, 600) * 35;
		// No-Classes loot persists for the map, including aged drops restored
		// from saves with the old 90-second lifetime setting.
		if (TuinRPGHandler.ClassesEnabled() && Age >= lifetime)
		{
			Destroy();
			return;
		}
		// Let each impulse die away quickly; loot should hop off awkward geometry,
		// not behave like a continuously homing coin.
		Vel.X *= 0.82;
		Vel.Y *= 0.82;
		if (!TuinRPGHandler.ClassesEnabled() && (Age == 1 || ((Age + VariantID) % 4) == 0))
			PushNearbyWeapons();

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
		SeparatingLoot = false;
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
		let traitData = toucher ? TuinPlayerData(toucher.FindInventory('TuinPlayerData')) : null;
		int fortune = TuinWeaponTraits.Strength(traitData, 9);
		int originalAmount = Amount;
		int fortuneRemainder = traitData ? traitData.TraitCoinRemainder : 0;
		if (fortune > 0)
		{
			int scaledBonus = Amount * fortune * 10 + fortuneRemainder;
			Amount += scaledBonus / 100;
			fortuneRemainder = scaledBonus % 100;
			collected = Amount;
		}
		A_RemoveLight('TuinCoinGlow');
		bool pickedUp = Super.TryPickup(toucher);
		if (!pickedUp) Amount = originalAmount;
		if (pickedUp && toucher)
		{
			let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
			if (data)
			{
				data.LevelCoinsEarned += max(0, collected);
				let milestoneHandler=TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
				if(milestoneHandler) milestoneHandler.RecordCoinMilestone(toucher,max(0,collected));
				if (fortune > 0) data.TraitCoinRemainder = fortuneRemainder;
			}
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
