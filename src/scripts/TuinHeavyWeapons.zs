class TuinMinigunExplosionFX : Actor
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
		for (int i = 0; i < 3; i++)
		{
			Actor flame = Actor.Spawn("PSBrutalGrenadeFlame",
				Pos + (Random[TuinMinigunFX](-9, 9), Random[TuinMinigunFX](-9, 9),
				Random[TuinMinigunFX](2, 17)), NO_REPLACE);
			if (flame)
			{
				flame.Scale *= 0.5;
				flame.Vel = (FRandom[TuinMinigunFX](-0.75, 0.75),
					FRandom[TuinMinigunFX](-0.75, 0.75), FRandom[TuinMinigunFX](0.25, 1.25));
			}
		}
		for (int j = 0; j < 3; j++)
		{
			Actor smoke = Actor.Spawn("PSBrutalGrenadeSmoke",
				Pos + (Random[TuinMinigunFX](-11, 11), Random[TuinMinigunFX](-11, 11),
				Random[TuinMinigunFX](4, 19)), NO_REPLACE);
			if (smoke)
			{
				smoke.Scale *= 0.5;
				smoke.Vel = (FRandom[TuinMinigunFX](-0.6, 0.6),
					FRandom[TuinMinigunFX](-0.6, 0.6), FRandom[TuinMinigunFX](0.3, 1.1));
			}
		}
		Actor column = Actor.Spawn("PSBrutalGrenadeSmokeColumn", Pos, NO_REPLACE);
		if (column) column.Scale *= 0.5;
		Actor flare = Actor.Spawn("PSBrutalGrenadeFlare", Pos, NO_REPLACE);
		if (flare) flare.Scale *= 0.5;
		for (int k = 0; k < 32; k++)
		{
			double ringAngle = k * 11.25;
			A_SpawnParticle("FFB040", SPF_FULLBRIGHT, 18, 2.5, ringAngle,
				Cos(ringAngle) * 3.0, Sin(ringAngle) * 3.0, 4,
				Cos(ringAngle) * 4.0, Sin(ringAngle) * 4.0, 0,
				0, 0, 0, 0.45, -1, 0.25);
		}
	}

	States
	{
	Spawn:
		TNT1 A 2;
		Stop;
	}
}

// Fast secondary projectile for the Heavy-exclusive DECORATE Minigun.
class TuinMinigunExplosiveRound : FastProjectile
{
	Default
	{
		Radius 3;
		Height 3;
		Speed 60;
		Damage 1;
		DamageType "TuinMinigunExplosive";
		Obituary "%o was shredded by an explosive Minigun round.";
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.20;
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		MISL A 1 Bright;
		Loop;
	Death:
		TNT1 A 0 Bright
		{
			A_StartSound("psgrenade/explode", CHAN_BODY, CHANF_OVERLAP, 0.65);
			A_Explode(20, 48);
			A_SpawnItemEx("TuinMinigunExplosionFX", 0, 0, 0,
				Flags: SXF_NOCHECKPOSITION);
		}
		TNT1 A 2 Bright;
		Stop;
	}
}
