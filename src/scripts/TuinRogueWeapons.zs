// Rogue-exclusive starter weapons adapted from DOOM Revitalized 1.3.
// They deliberately do not replace Doom's global Fist or Pistol classes.
class TuinRogueWeapon : Weapon
{
	int RejectMessageTime[MAXPLAYERS];

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
		if (!data || data.PlayerClass != 5)
		{
			int playerNumber = toucher.PlayerNumber();
			if (playerNumber >= 0 && playerNumber < MAXPLAYERS && level.Time >= RejectMessageTime[playerNumber])
			{
				RejectMessageTime[playerNumber] = level.Time + 35;
				toucher.A_Print("ROGUE CLASS ONLY");
				toucher.A_StartSound("weapons/noammo", CHAN_ITEM, CHANF_MAYBE_LOCAL, 0.65, ATTN_NONE);
			}
			return false;
		}
		return Super.TryPickup(toucher);
	}

	Default
	{
		Radius 20;
		Height 20;
		+WEAPON.WIMPY_WEAPON
		+WEAPON.NOALERT
	}
}

class TuinRogueKnife : TuinRogueWeapon
{
	double KnifeReach()
	{
		let data = Owner ? TuinPlayerData(Owner.FindInventory('TuinPlayerData')) : null;
		int trainingRank = data && data.PlayerClass == 5 ? clamp(data.PerkClassMastery, 0, 3) : 0;
		// 80 is the new +25% base reach over the former 64-unit strike.
		return 80.0 * (1.0 + trainingRank * 0.20);
	}

	Default
	{
		Tag "ROGUE KNIFE";
		Inventory.PickupMessage "Picked up a Rogue Knife.";
		Inventory.PickupSound "misc/w_pkup";
		Inventory.Icon "KNIFA0";
		Weapon.SlotNumber 1;
		Weapon.SelectionOrder 3700;
		Weapon.Kickback 100;
		+WEAPON.MELEEWEAPON
	}

	States
	{
	Spawn:
		TRKN A -1;
		Stop;
	Ready:
		NIFA ABCD 1;
		NIFE A 1;
		Goto ReadyLoop;
	ReadyLoop:
		NIFE A 1 A_WeaponReady;
		Loop;
	Select:
		TNT1 A 1 A_Raise;
		Loop;
	Deselect:
		NIFE A 1 A_Lower;
		Loop;
	Fire:
		NIFE ABC 2;
		NIFE D 1 A_PlaySound("tuin/rogue/knifeswing", CHAN_WEAPON, 0.85);
		NIFE E 1
		{
			A_CustomPunch(Random[TuinRogueKnife](28, 42), true, 0, "TuinRogueKnifePuff",
				TuinRogueKnife(invoker).KnifeReach(), 0, 0, null, "tuin/rogue/knifehit");
			A_GunFlash();
		}
		NIFE FGH 1;
		NIHA ABCDEF 1;
		NIFE A 4 A_ReFire;
		Goto ReadyLoop;
	}
}

class TuinRogueSilencedPistol : TuinRogueWeapon
{
	Default
	{
		Tag "ROGUE SILENCED PISTOL";
		Inventory.PickupMessage "Picked up a Rogue Silenced Pistol.";
		Inventory.PickupSound "misc/w_pkup";
		Inventory.Icon "PSSIA0";
		Weapon.SlotNumber 2;
		Weapon.SelectionOrder 1900;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoUse1 1;
		Weapon.AmmoGive1 20;
	}

	States
	{
	Spawn:
		TRPP A -1;
		Stop;
	Ready:
		SIEQ ABCD 1;
		SIPI A 1;
		Goto ReadyLoop;
	ReadyLoop:
		SIPI A 1 A_WeaponReady;
		Loop;
	Select:
		TNT1 A 1 A_Raise;
		Loop;
	Deselect:
		SIPI A 1 A_Lower;
		Loop;
	Fire:
		SIPI A 1;
		SIPI B 2;
		SIPI C 2
		{
			A_PlaySound("tuin/rogue/silenced", CHAN_WEAPON, 0.8);
			A_FireBullets(0, 0, 1, 8, "TuinRogueSilencedPuff");
		}
		SIPI DEFGHI 1;
		SIPI F 2;
		SIPI B 1 A_ReFire;
		SIPI A 1;
		Goto ReadyLoop;
	}
}

class TuinRogueKnifePuff : BulletPuff
{
	Default { DamageType "TuinRogueKnife"; }
}

class TuinRogueSilencedPuff : BulletPuff
{
	Default { DamageType "TuinRogueSilenced"; }
}

class TuinRogueBoltAmmo : Ammo
{
	int RejectMessageTime[MAXPLAYERS];

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
		if (!data || data.PlayerClass != 5)
		{
			int playerNumber = toucher.PlayerNumber();
			if (playerNumber >= 0 && playerNumber < MAXPLAYERS && level.Time >= RejectMessageTime[playerNumber])
			{
				RejectMessageTime[playerNumber] = level.Time + 35;
				toucher.A_Print("ROGUE CLASS ONLY");
				toucher.A_StartSound("weapons/noammo", CHAN_ITEM, CHANF_MAYBE_LOCAL, 0.65, ATTN_NONE);
			}
			return false;
		}
		return Super.TryPickup(toucher);
	}

	Default
	{
		Inventory.Amount 2;
		Inventory.MaxAmount 30;
		Inventory.PickupMessage "Picked up venom bolts.";
		Inventory.PickupSound "misc/ammo_pkup";
		Inventory.Icon "TBLTICON";
		Ammo.BackpackAmount 2;
		Ammo.BackpackMaxAmount 60;
		Scale 0.032;
		+FLOATBOB
		+RELATIVETOFLOOR
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		TBLT A -1 Bright;
		Stop;
	}
}

class TuinRogueBow : TuinRogueWeapon
{
	Default
	{
		Tag "ROGUE VENOM BOW";
		Inventory.PickupMessage "Picked up the Rogue Venom Bow.";
		Inventory.PickupSound "misc/w_pkup";
		Inventory.Icon "TRBWA0";
		Weapon.SlotNumber 3;
		Weapon.SelectionOrder 1850;
		Weapon.AmmoType1 "TuinRogueBoltAmmo";
		Weapon.AmmoUse1 1;
		Weapon.AmmoGive1 6;
		Weapon.UpSound "tuin/rogue/bowdraw";
		+WEAPON.NOAUTOFIRE
		+WEAPON.NOALERT
	}

	States
	{
	Spawn:
		TRBW A -1 Bright;
		Stop;
	Ready:
		RBOW ABC 2 A_WeaponReady;
		Loop;
	Select:
		RBOW A 1 A_Raise;
		Loop;
	Deselect:
		RBOW A 1 A_Lower;
		Loop;
	Fire:
		RBOW D 2 Bright;
		RBOW E 1 Bright
		{
			A_PlaySound("tuin/rogue/bowfire", CHAN_WEAPON, 0.85);
			A_FireProjectile("TuinRogueVenomBolt");
			A_GunFlash();
		}
		RBOW FG 2;
	Reload:
		RBOW H 2;
		RBOW IJK 2;
		RBOW L 1;
		RBOW MNOPQRS 2;
		RBOW T 1 A_PlaySound("tuin/rogue/bowpull", CHAN_WEAPON, 0.75);
		RBOW U 1;
		RBOW V 2;
		RBOW WX 1;
		RBOW Y 2;
		RBOW Z 4;
		RBL2 ABCDE 2;
		Goto Ready;
	Flash:
		TNT1 A 2 Bright A_Light1;
		TNT1 A 2 A_Light0;
		Stop;
	}
}

class TuinRogueVenomBolt : Actor
{
	Default
	{
		Radius 5;
		Height 5;
		Speed 72;
		DamageFunction 70;
		DamageType "TuinRogueBolt";
		DeathSound "tuin/rogue/bowhit";
		SeeSound "tuin/rogue/boltloop";
		Projectile;
		+BRIGHT
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		RBOL A 1 Bright;
		Loop;
	Death:
		RBOL BCD 3 Bright;
		Stop;
	}
}
