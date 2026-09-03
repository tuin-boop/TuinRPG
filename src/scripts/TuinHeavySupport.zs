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
		RADI ABCDE 2;
		RADI GHI 2;
		RADI J 35;
		RADI IHGFEDCBA 2;
		Stop;
	}
}

class TuinHeavySupportMarine : ScriptedMarine
{
	int ServiceTics;

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
		Speed 12;
		PainChance 0;
		Species "TuinHeavySupport";
		+FRIENDLY
		+INVULNERABLE
		+NOBLOOD
		+QUICKTORETALIATE
		+LOOKALLAROUND
		+NOBLOCKMONST
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

class TuinHeavySupportMarineGold : TuinHeavySupportMarine
{
	Default { Translation "112:127=160:175"; }
}

class TuinHeavySupportMarinePurple : TuinHeavySupportMarine
{
	Default { Translation "112:127=176:191"; }
}
