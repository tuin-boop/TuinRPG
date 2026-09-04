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
				Pos + (Random[TuinMinigunFX](-5, 5), Random[TuinMinigunFX](-5, 5),
				Random[TuinMinigunFX](1, 9)), NO_REPLACE);
			if (flame)
			{
				flame.Scale *= 0.25;
				flame.Vel = (FRandom[TuinMinigunFX](-0.375, 0.375),
					FRandom[TuinMinigunFX](-0.375, 0.375), FRandom[TuinMinigunFX](0.125, 0.625));
			}
		}
		for (int j = 0; j < 3; j++)
		{
			Actor smoke = Actor.Spawn("PSBrutalGrenadeSmoke",
				Pos + (Random[TuinMinigunFX](-6, 6), Random[TuinMinigunFX](-6, 6),
				Random[TuinMinigunFX](2, 10)), NO_REPLACE);
			if (smoke)
			{
				smoke.Scale *= 0.25;
				smoke.Vel = (FRandom[TuinMinigunFX](-0.3, 0.3),
					FRandom[TuinMinigunFX](-0.3, 0.3), FRandom[TuinMinigunFX](0.15, 0.55));
			}
		}
		Actor column = Actor.Spawn("PSBrutalGrenadeSmokeColumn", Pos, NO_REPLACE);
		if (column) column.Scale *= 0.25;
		Actor flare = Actor.Spawn("PSBrutalGrenadeFlare", Pos, NO_REPLACE);
		if (flare) flare.Scale *= 0.25;
		for (int k = 0; k < 32; k++)
		{
			double ringAngle = k * 11.25;
			A_SpawnParticle("FFB040", SPF_FULLBRIGHT, 14, 1.25, ringAngle,
				Cos(ringAngle) * 1.5, Sin(ringAngle) * 1.5, 2,
				Cos(ringAngle) * 2.0, Sin(ringAngle) * 2.0, 0,
				0, 0, 0, 0.225, -1, 0.25);
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
		Radius 2;
		Height 2;
		Speed 150;
		DamageFunction 10;
		DamageType "TuinMinigunExplosive";
		Obituary "%o was shredded by an explosive Minigun round.";
		RenderStyle "Add";
		Alpha 0.96;
		+FORCEXYBILLBOARD
		+BRIGHT
		+NOEXTREMEDEATH
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_AttachLight('TuinMinigunExplosiveTracerGlow', DynamicLight.PointLight,
			Color(255, 138, 28), 18, 18,
			DynamicLight.LF_ATTENUATE | DynamicLight.LF_DONTLIGHTSELF);
	}

	States
	{
	Spawn:
		TRAC A 1 Bright;
		Loop;
	Death:
		TNT1 A 0 Bright
		{
			A_StartSound("tuin/minigun/altexplode", CHAN_BODY, CHANF_OVERLAP, 1.0);
			A_Explode(10, 24);
			A_SpawnItemEx("TuinMinigunExplosionFX", 0, 0, 0,
				Flags: SXF_NOCHECKPOSITION);
		}
		TNT1 A 2 Bright;
		Stop;
	}
}
