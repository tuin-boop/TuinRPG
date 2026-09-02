class TuinEngineerTracer : FastProjectile
{
	Default
	{
		Radius 2;
		Height 2;
		Speed 150;
		DamageFunction 8;
		DamageType "TuinEngineerTurret";
		Projectile;
		+RANDOMIZE;
		+BRIGHT;
		+NOEXTREMEDEATH;
		RenderStyle "Add";
		Alpha 0.96;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_AttachLight('TuinEngineerTracerGlow', DynamicLight.PointLight,
			Color(255, 206, 78), 28, 28,
			DynamicLight.LF_ATTENUATE | DynamicLight.LF_DONTLIGHTSELF);
	}

	States
	{
	Spawn:
		TRAC A 1 Bright;
		Loop;
	Death:
		TNT1 A 0 A_PlaySound("tuin/engineer/impact", CHAN_AUTO, 0.45);
		Stop;
	}
}

class TuinEngineerTracerII : TuinEngineerTracer { Default { DamageFunction 9; } }
class TuinEngineerTracerIII : TuinEngineerTracer { Default { DamageFunction 10; } }
class TuinEngineerTracerIV : TuinEngineerTracer { Default { DamageFunction 11; } }
class TuinEngineerTracerUltimate : TuinEngineerTracer { Default { DamageFunction 14; } }

class TuinEngineerTurret : Actor
{
	int OwnerPlayer;
	int ShotsRemaining;
	int TrainingRank;
	bool Ultimate;
	int FireClock;
	int ScanClock;

	Default
	{
		Health 400;
		Radius 20;
		Height 56;
		Mass 800;
		Monster;
		+FRIENDLY;
		+SHOOTABLE;
		+FLOORCLIP;
		+NOBLOOD;
		+NOBLOODDECALS;
		+NOINFIGHTING;
		+DONTHARMSPECIES;
		+NOTAUTOAIMED;
		-COUNTKILL;
		Species "TuinEngineer";
		Tag "Engineer Auto-Turret";
	}

	void Configure(int playerNumber, Actor ownerPawn, int training, bool ultimate)
	{
		OwnerPlayer = playerNumber;
		master = ownerPawn;
		TrainingRank = clamp(training, 0, 3);
		Ultimate = ultimate;
		ShotsRemaining = ultimate ? 400 : 250;
		Health = Ultimate ? 600 : 400;
		A_SetHealth(Health);
	}

	bool ValidTarget(Actor candidate)
	{
		return candidate && candidate.Health > 0 && candidate.bSHOOTABLE &&
			candidate.bISMONSTER && !candidate.bFRIENDLY &&
			Distance3D(candidate) <= 1280.0 &&
			CheckSight(candidate, SF_IGNOREWATERBOUNDARY);
	}

	Actor FindTarget()
	{
		Actor best;
		double bestDistance = 1281.0;
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor candidate;
		while (candidate = Actor(iterator.Next()))
		{
			if (!ValidTarget(candidate)) continue;
			double distance = Distance3D(candidate);
			if (distance >= bestDistance) continue;
			best = candidate;
			bestDistance = distance;
		}
		return best;
	}

	void FireTracer()
	{
		if (!ValidTarget(target) || ShotsRemaining <= 0) return;
		Vector3 start = Pos + (cos(Angle) * 18.0, sin(Angle) * 18.0, 31.0);
		Vector3 finish = target.Pos + (0, 0, target.Height * 0.55);
		Vector3 delta = level.Vec3Diff(start, finish);
		double distance = delta.length();
		if (distance <= 0.01) return;
		Name projectileType = Ultimate ? 'TuinEngineerTracerUltimate' :
			TrainingRank >= 3 ? 'TuinEngineerTracerIV' :
			TrainingRank == 2 ? 'TuinEngineerTracerIII' :
			TrainingRank == 1 ? 'TuinEngineerTracerII' : 'TuinEngineerTracer';
		TuinEngineerTracer bullet = TuinEngineerTracer(Actor.Spawn(projectileType, start, NO_REPLACE));
		if (!bullet) return;
		bullet.target = self;
		bullet.master = master;
		bullet.Angle = atan2(delta.y, delta.x);
		bullet.Pitch = -asin(delta.z / distance);
		bullet.Vel = delta / distance * bullet.Speed;
		ShotsRemaining--;
		A_PlaySound("tuin/engineer/fire", CHAN_WEAPON, 0.72);
		SetState(FindState('Fire'), true);
	}

	override void Tick()
	{
		Super.Tick();
		if (Health <= 0 || !master || !master.player || master.Health <= 0) return;
		if (ShotsRemaining <= 0)
		{
			SetState(FindState('Empty'), true);
			return;
		}
		if (--ScanClock <= 0 || !ValidTarget(target))
		{
			target = FindTarget();
			ScanClock = 7;
		}
		if (!ValidTarget(target)) return;
		Vector3 delta = level.Vec3Diff(Pos, target.Pos);
		Angle = atan2(delta.y, delta.x);
		if (--FireClock <= 0)
		{
			FireTracer();
			FireClock = Ultimate ? 5 : 7;
		}
	}

	States
	{
	Spawn:
		TURE A -1;
		Stop;
	Fire:
		TURE F 2 Bright;
		TURE A -1;
		Stop;
	Empty:
		TURE B -1;
		Stop;
	Death:
		TURD A 1 A_PlaySound("weapons/rocklx", CHAN_BODY, 0.8);
		TURD A -1;
		Stop;
	}
}
