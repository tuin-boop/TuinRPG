class TuinEngineerTracer : FastProjectile
{
	int FixedDamage;

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

	override int DoSpecialDamage(Actor victim, int damage, Name damageType)
	{
		return FixedDamage > 0 ? FixedDamage : Super.DoSpecialDamage(victim, damage, damageType);
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

class TuinEngineerTurret : Actor
{
	int OwnerPlayer;
	int SentrySlot;
	int ShotsRemaining;
	int TrainingRank;
	int OwnerLevel;
	int WeaponPowerPercent;
	int WeaponHastePercent;
	int WeaponCriticalPercent;
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

	void Configure(int playerNumber, int sentrySlot, Actor ownerPawn, int training, int ownerLevel,
		int weaponPower, int weaponHaste, int weaponCritical, int startingHealth, int startingRounds)
	{
		OwnerPlayer = playerNumber;
		self.SentrySlot = sentrySlot;
		master = ownerPawn;
		TrainingRank = clamp(training, 0, 3);
		self.OwnerLevel = max(1, ownerLevel);
		WeaponPowerPercent = max(0, weaponPower);
		WeaponHastePercent = max(0, weaponHaste);
		WeaponCriticalPercent = max(0, weaponCritical);
		ShotsRemaining = clamp(startingRounds, 1, 250);
		Health = clamp(startingHealth, 1, 400);
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
		TuinEngineerTracer bullet = TuinEngineerTracer(Actor.Spawn('TuinEngineerTracer', start, NO_REPLACE));
		if (!bullet) return;
		bullet.target = self;
		bullet.master = master;
		bullet.Angle = atan2(delta.y, delta.x);
		bullet.Pitch = -asin(delta.z / distance);
		bullet.Vel = delta / distance * bullet.Speed;
		int levelDamage = 8 + max(0, OwnerLevel - 1) / 5;
		double multiplier = (1.0 + TrainingRank * 0.10) * (1.0 + WeaponPowerPercent * 0.01);
		bullet.FixedDamage = max(1, int(levelDamage * multiplier + 0.5));
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
			FireClock = max(4, int(7.0 / (1.0 + WeaponHastePercent * 0.01) + 0.5));
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
