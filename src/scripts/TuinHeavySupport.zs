class TuinHeavyMovementPenalty : Powerup
{
	override double GetSpeedFactor()
	{
		return 0.70;
	}

	Default
	{
		Powerup.Duration 0x7FFFFFFF;
		Inventory.InterHubAmount 0;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNCLEARABLE
	}
}

class TuinHeavyMarineDamage : Powerup
{
	override void ModifyDamage(int damage, Name damageType, out int newdamage,
		bool passive, Actor inflictor, Actor source, int flags)
	{
		if (!passive && damage > 0) newdamage = max(1, damage * 2);
	}

	Default
	{
		Powerup.Duration 0x7FFFFFFF;
		Inventory.InterHubAmount 0;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNCLEARABLE
	}
}

class TuinHeavyRadioOverlay : Weapon
{
	Default
	{
		Inventory.MaxAmount 0;
		Weapon.SelectionOrder 0;
		+INVENTORY.UNDROPPABLE
	}

	States
	{
	Call:
		RADI ABCDE 1;
		RADI GHI 1;
		RADI J 57;
		RADI JJJJJIHG 1;
		RADI F 25;
		RADI F 29;
		RADI F 31;
		RADI F 13;
		RADI F 16;
		RADI F 4;
		RADI EDCBA 1;
		Stop;
	}
}

class TuinHeavySupportMarine : ScriptedMarine
{
	int ServiceTics;
	int MasterSightLostTics;
	int MovementPulse;
	int EnemyScanTics;

	bool ValidEnemy(Actor candidate)
	{
		return candidate && candidate.Health > 0 && candidate.bSHOOTABLE &&
			candidate.bISMONSTER && !candidate.bFRIENDLY &&
			Distance3D(candidate) <= 1536.0 && CheckSight(candidate, SF_IGNOREWATERBOUNDARY);
	}

	Actor FindNearestEnemy()
	{
		Actor nearest;
		double nearestDistance = 1537.0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor candidate;
		while (candidate = Actor(iterator.Next()))
		{
			if (!ValidEnemy(candidate)) continue;
			double distance = Distance3D(candidate);
			if (distance >= nearestDistance) continue;
			nearest = candidate;
			nearestDistance = distance;
		}
		return nearest;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		ServiceTics = 30 * 35;
		SetWeapon(Random[TuinHeavyMarineWeapon](WEAPON_Shotgun, WEAPON_PlasmaRifle));
		GiveInventory('TuinHeavyMarineDamage', 1);
	}

	override void Tick()
	{
		Super.Tick();
		if (--EnemyScanTics <= 0 || !ValidEnemy(target))
		{
			target = FindNearestEnemy();
			EnemyScanTics = 7;
			if (target)
			{
				threshold = 100;
				reactiontime = 0;
			}
		}
		if (master)
		{
			double masterDistance = Distance3D(master);
			if (!CheckSight(master)) MasterSightLostTics++;
			else MasterSightLostTics = 0;
			if (masterDistance > 1024.0 || MasterSightLostTics >= 70)
			{
				Actor.Spawn('TeleportFog', Pos, ALLOW_REPLACE);
				Warp(master, FRandom[TuinHeavyMarineFollow](-64.0, -24.0),
					FRandom[TuinHeavyMarineFollow](-64.0, 64.0), 0, 0,
					WARPF_STOP | WARPF_TOFLOOR);
				Actor.Spawn('TeleportFog', Pos, ALLOW_REPLACE);
				MasterSightLostTics = 0;
			}
			MovementPulse++;
			if (target && target.Health > 0 && (MovementPulse % 7) == 0)
			{
				Vel.X += FRandom[TuinHeavyMarineMotion](-1.5, 1.5);
				Vel.Y += FRandom[TuinHeavyMarineMotion](-1.5, 1.5);
			}
			if (target && target.Health > 0 && Distance3D(target) > 160.0)
			{
				Angle = AngleTo(target);
				A_Recoil(-0.65);
			}
			else if ((!target || target.Health <= 0) && masterDistance > 86.0)
			{
				Angle = AngleTo(master);
				A_Recoil(-0.75);
			}
			else if ((!target || target.Health <= 0) && masterDistance < 70.0)
			{
				Vel.X *= 0.72;
				Vel.Y *= 0.72;
			}
		}
		if (ServiceTics > 0) ServiceTics--;
		if (ServiceTics <= 0)
		{
			Actor.Spawn('TeleportFog', Pos, ALLOW_REPLACE);
			A_StartSound("tuin/heavy/teleport", CHAN_BODY, 0, 0.80);
			Destroy();
		}
	}

	Default
	{
		Health 1000;
		Speed 6;
		PainChance 0;
		MaxStepHeight 48;
		MaxDropOffHeight 48;
		Species "TuinHeavySupport";
		+FRIENDLY
		+INVULNERABLE
		+NOBLOOD
		+QUICKTORETALIATE
		+MISSILEMORE
		+LOOKALLAROUND
		+NOBLOCKMONST
		+SLIDESONWALLS
		+FLOORCLIP
		-COUNTKILL
	}
}

class TuinHeavySupportMarineGray : TuinHeavySupportMarine
{
	Default { Translation "112:127=96:111"; }
}

class TuinHeavySupportMarineBrown : TuinHeavySupportMarine
{
	Default { Translation "112:127=64:79"; }
}

class TuinHeavySupportMarineRed : TuinHeavySupportMarine
{
	Default { Translation "112:127=32:47"; }
}

class TuinHeavySupportMarineBlue : TuinHeavySupportMarine
{
	Default { Translation "112:127=192:207"; }
}
