// Doom Guy-exclusive Quad Shotgun adapted from Complex Doom v27f.
// It keeps the original art while using that mod's ordinary double-barrel
// blast for the four-barrel primary fire.
class TuinDoomGuyWeapon : Weapon
{
	int RejectMessageTime[MAXPLAYERS];

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
		if (!data || data.PlayerClass != 4)
		{
			int playerNumber = toucher.PlayerNumber();
			if (playerNumber >= 0 && playerNumber < MAXPLAYERS && level.Time >= RejectMessageTime[playerNumber])
			{
				RejectMessageTime[playerNumber] = level.Time + 35;
				toucher.A_Print("DOOM GUY CLASS ONLY");
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
		+WEAPON.NOALERT
	}
}

class TuinDoomGuyQuadShotgun : TuinDoomGuyWeapon
{
	Default
	{
		Tag "DOOM GUY QUAD SHOTGUN";
		Inventory.PickupMessage "Picked up Doom Guy's Quad Shotgun.";
		Inventory.PickupSound "tuin/doomguy/quadpickup";
		Inventory.Icon "QSGPA0";
		Scale 0.75;
		Weapon.SlotNumber 3;
		Weapon.SelectionOrder 450;
		Weapon.Kickback 100;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoUse1 0;
		Weapon.AmmoGive1 8;
		+WEAPON.AMMO_OPTIONAL
		+WEAPON.NOAUTOFIRE
		+INVENTORY.UNDROPPABLE
	}

	States
	{
	Spawn:
		QSGP A -1;
		Stop;
	Ready:
		QSGN A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Select:
		QSGN A 1 A_Raise;
		Loop;
	Deselect:
		QSGN A 1 A_Lower;
		Loop;
	Fire:
		TNT1 A 0 A_JumpIfInventory("Shell", 4, "QuadFire");
		QSGN A 4 A_PlaySound("weapons/noammo", CHAN_WEAPON, 0.75);
		Goto Ready;
	QuadFire:
		TNT1 A 0 A_TakeInventory("Shell", 4);
		TNT1 A 0 A_PlaySound("tuin/doomguy/quadprimary", CHAN_WEAPON, 1.0);
		TNT1 A 0 A_AlertMonsters;
		TNT1 A 0 A_GunFlash;
		TNT1 A 0 A_FireBullets(11.8, 7.3, 52, 5, "TuinDoomGuyQuadPuff");
		QS4F A 1 Bright A_Light1;
		QS4F B 1 Bright A_Light2;
		TNT1 A 0 A_Light0;
		QSGN CFG 1;
		QSGN H 2;
		QSER A 3;
		QSER B 8;
		QSGN GFEDC 2;
		Goto QuadReload;
	AltFire:
		TNT1 A 0 A_JumpIfInventory("Shell", 2, "DoubleFire");
		QSGN A 4 A_PlaySound("weapons/noammo", CHAN_WEAPON, 0.75);
		Goto Ready;
	DoubleFire:
		TNT1 A 0 A_TakeInventory("Shell", 2);
		TNT1 A 0 A_PlaySound("tuin/doomguy/quaddouble", CHAN_WEAPON, 1.0);
		TNT1 A 0 A_AlertMonsters;
		TNT1 A 0 A_GunFlash;
		TNT1 A 0 A_FireBullets(11.2, 7.1, 20, 5, "TuinDoomGuyQuadPuff");
		QSGF C 1 Bright A_Light1;
		QSGF D 1 Bright A_Light2;
		TNT1 A 0 A_Light0;
		QRE2 A 3;
		QRE2 BCDE 1;
		Goto Ready;
	Reload:
		Goto Ready;
	QuadReload:
		QSGN SRQP 2;
		QS2N I 2;
		QSGN PJ 2;
		QSGN KL 1;
		QS2N L 1;
		QSGR A 12 A_PlaySound("tuin/doomguy/quadopen", CHAN_WEAPON, 0.9);
		QSGR BCD 2;
		QSGR E 3 A_PlaySound("tuin/doomguy/quadload", CHAN_WEAPON, 0.9);
		QSGR FGH 2;
		QSGR I 8;
		QSGR JK 1;
		QSGR LM 2;
		QSGR N 3 A_PlaySound("tuin/doomguy/quadload", CHAN_WEAPON, 0.9);
		QSGR OP 2;
		QSGR Q 1;
		QSGN MNO 1;
		QSGN P 1 A_PlaySound("tuin/doomguy/quadclose", CHAN_WEAPON, 0.9);
		QSGN QRS 2;
		QSGN A 2;
		Goto Ready;
	}
}

class TuinDoomGuyQuadPuff : BulletPuff
{
	Default { DamageType "TuinDoomGuyQuad"; }
}
