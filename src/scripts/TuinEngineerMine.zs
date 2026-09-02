// Engineer-only proximity mine adapted from Doom Deluxe's slot-0 land mine.
// It keeps the original throw/world artwork and mine cues while using TuinRPG's
// existing grenade blast, ensuring the familiar explosion balance and effects.
class TuinEngineerMineVisual : Inventory
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
		MINE BCD 1;
		MINE E 2;
		MINE F 1;
		MINE G 3;
		MINE H 2;
		MINE IJKL 1;
		MINE M 2;
		MINE N 1;
		MINE O 1;
		MINE P 1;
		MINE Q 1;
		MINE RS 2;
		MINE TUVW 2;
		MINE XY 1;
		Stop;
	}
}

class TuinEngineerMineProjectile : Actor
{
	Default
	{
		Radius 12;
		Height 12;
		Speed 24;
		DamageFunction 0;
		DamageType "Grenade";
		Projectile;
		-NOGRAVITY
		Gravity 0.8;
		BounceType "Doom";
		BounceFactor 0.5;
		WallBounceFactor 0.3;
		BounceSound "tuin/mine/bounce";
		+BOUNCEONWALLS
		+BOUNCEONCEILINGS
		+BOUNCEAUTOOFFFLOORONLY
		+FORCEXYBILLBOARD
		+THRUSPECIES
		+EXPLODEONWATER
		Species "TuinEngineer";
	}

	States
	{
	Spawn:
		LMIN A 4 A_PlaySound("tuin/mine/woosh1", CHAN_AUTO, 0.55);
		LMIN B 4 A_PlaySound("tuin/mine/woosh2", CHAN_AUTO, 0.55);
		LMIN C 4 A_PlaySound("tuin/mine/woosh1", CHAN_AUTO, 0.55);
		LMIN D 4 A_PlaySound("tuin/mine/woosh2", CHAN_AUTO, 0.55);
		Loop;
	Death:
		TNT1 A 1
		{
			let mine = TuinEngineerMine(Actor.Spawn('TuinEngineerMine', Pos, NO_REPLACE));
			if (mine)
			{
				mine.Target = Target;
				mine.Master = Target;
				mine.Angle = Angle;
				mine.bFRIENDLY = true;
			}
		}
		Stop;
	}
}

class TuinEngineerMine : Actor
{
	bool Triggered;

	Default
	{
		Radius 20;
		Height 12;
		Health 5;
		PainChance 255;
		Mass 1000000;
		Gravity 0.8;
		DamageType "Grenade";
		Obituary "%o stepped on an Engineer mine.";
		+FRIENDLY
		+SHOOTABLE
		-SOLID
		+FORCEPAIN
		+NOBLOOD
		+FORCERADIUSDMG
		+FORCEXYBILLBOARD
		+NOTARGET
		+NEVERTARGET
		+NOTAUTOAIMED
		+USESPECIAL
		+SPECIAL
		Activation THINGSPEC_Activate;
		Species "TuinEngineer";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_AttachLight('TuinEngineerMineGlow', DynamicLight.PulseLight,
			Color(255, 40, 20), 18, 34, DynamicLight.LF_ATTENUATE, (0, 0, 7), 0.65);
	}

	override void Tick()
	{
		Super.Tick();
		if (Triggered || Health <= 0 || GetAge() < 40 || (GetAge() & 1)) return;

		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		Actor damageSource = Target;
		if (!damageSource) damageSource = self;
		while (monster = Actor(iterator.Next()))
		{
			if (!monster.bISMONSTER || monster.bFRIENDLY || !monster.bSHOOTABLE ||
				monster.Health <= 0 || Distance3D(monster) > 130.0 ||
				!CheckSight(monster, SF_IGNOREWATERBOUNDARY)) continue;
			Triggered = true;
			SetState(FindState('Trigger'), true);
			break;
		}
	}

	override bool Used(Actor user)
	{
		if (Triggered || GetAge() < 40 || !user || !user.player || user.Health <= 0 ||
			(Target && Target != user)) return false;
		let data = TuinPlayerData(user.FindInventory('TuinPlayerData'));
		if (!data || data.PlayerClass != 6) return false;

		Inventory ammo = user.FindInventory('PSQuickGrenadeAmmo');
		int before = ammo ? ammo.Amount : 0;
		user.GiveInventory('PSQuickGrenadeAmmo', 1);
		ammo = user.FindInventory('PSQuickGrenadeAmmo');
		if (!ammo || ammo.Amount <= before)
		{
			user.A_Print("Mine reserve full.");
			return false;
		}

		A_RemoveLight('TuinEngineerMineGlow');
		user.A_StartSound("tuin/mine/bounce", CHAN_ITEM, 0, 0.65);
		user.A_Print("Proximity mine recovered.");
		Destroy();
		return true;
	}

	void Detonate()
	{
		A_RemoveLight('TuinEngineerMineGlow');
		A_Stop();
		A_StartSound("psgrenade/explode", CHAN_BODY);
		A_StartSound("psgrenade/explode_distant", CHAN_5);
		A_AlertMonsters(1024);
		// Apply the grenade's five concentric damage bands explicitly to hostiles.
		// This keeps the mine safe for its Engineer and friendly sentries.
		ThinkerIterator iterator = ThinkerIterator.Create('Actor');
		Actor monster;
		while (monster = Actor(iterator.Next()))
		{
			if (!monster.bISMONSTER || monster.bFRIENDLY || !monster.bSHOOTABLE ||
				monster.Health <= 0 || !CheckSight(monster, SF_IGNOREWATERBOUNDARY)) continue;
			double distance = Distance3D(monster);
			if (distance > 480.0) continue;
			int damage = 13;
			if (distance <= 400.0) damage += 27;
			if (distance <= 320.0) damage += 40;
			if (distance <= 240.0) damage += 53;
			if (distance <= 160.0) damage += 67;
			monster.DamageMobj(self, damageSource, damage, 'Grenade');
		}
		A_QuakeEx(5, 5, 5, 18, 0, 1000, "", QF_SCALEDOWN);
		A_SpawnItemEx("PSQuickGrenadeExplosionFX", 0, 0, 0, Flags: SXF_NOCHECKPOSITION);
	}

	States
	{
	Spawn:
		LMIN A 20;
		LMIN E 2 Bright A_PlaySound("tuin/mine/beep", CHAN_BODY, 0.8, false, ATTN_NORM, 1.5);
		LMIN JEJ 2 Bright;
	Armed:
		LMIN J 16;
		LMIN E 16 Bright;
		Loop;
	Trigger:
		LMIN F 2 Bright A_PlaySound("tuin/mine/beep", CHAN_BODY, 1.0, false, ATTN_NORM, 1.25);
		LMIN J 2;
		LMIN F 2 Bright A_PlaySound("tuin/mine/beep", CHAN_BODY, 1.0, false, ATTN_NORM, 1.5);
		Goto Death;
	Death:
		TNT1 A 1 Bright Detonate();
		Stop;
	}
}
