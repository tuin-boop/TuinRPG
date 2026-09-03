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
				64, 0, 0, null, "tuin/rogue/knifehit");
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
