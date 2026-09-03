// Doom Guy-exclusive Quad Shotgun adapted from Complex Doom v27f.
// It keeps the original art and uses Project Brutality's dedicated quad
// shotgun sound set, including randomized half-blast sounds.
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
		bool pickedUp = Super.TryPickup(toucher);
		if (pickedUp && !toucher.FindInventory('TuinDoomGuyQuadLoaded'))
			toucher.GiveInventory('TuinDoomGuyQuadLoaded', 4);
		return pickedUp;
	}

	Default
	{
		Radius 20;
		Height 20;
		+WEAPON.NOALERT
	}
}

class TuinDoomGuyQuadLoaded : Inventory
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 4;
		Inventory.InterHubAmount 4;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNCLEARABLE
	}
}

class TuinDoomGuyQuadAltChain : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
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
		// Four shells begin inside the barrels and four enter the reserve.
		Weapon.AmmoGive1 4;
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
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadLoaded", 4, "ReadyFull");
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadLoaded", 2, "ReadyHalf");
		Goto ReadyEmpty;
	ReadyFull:
		QSGN A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	ReadyHalf:
		QSG2 A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto ReadyHalf;
	ReadyEmpty:
		QSG3 A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto ReadyEmpty;
	Select:
		QSGN A 1 A_Raise;
		Loop;
	Deselect:
		QSGN A 1 A_Lower;
		Loop;
	Fire:
		TNT1 A 0 A_TakeInventory("TuinDoomGuyQuadAltChain", 1);
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadLoaded", 4, "QuadFire");
		TNT1 A 0 A_JumpIfInventory("Shell", 1, "QuadReload");
		QSGN A 4 A_PlaySound("weapons/noammo", CHAN_WEAPON, 0.75);
		Goto Ready;
	QuadFire:
		TNT1 A 0 A_TakeInventory("TuinDoomGuyQuadLoaded", 4);
		TNT1 A 0 A_PlaySound("tuin/doomguy/quadprimary", CHAN_WEAPON, 1.0);
		TNT1 A 0 A_AlertMonsters;
		TNT1 A 0 A_GunFlash;
		TNT1 A 0 A_FireBullets(11.8, 7.3, 52, 5, "XtremeSGPuff");
		QS4F A 1 Bright A_Light1;
		QS4F B 1 Bright A_Light2;
		TNT1 A 0 A_Light0;
		QSGN CFG 1;
		QSGN H 1;
		QSER A 2;
		QSER B 6;
		QSGN GFEDC 1;
		Goto TryAutoReload;
	AltFire:
		TNT1 A 0 A_GiveInventory("TuinDoomGuyQuadAltChain", 1);
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadLoaded", 2, "DoubleFire");
		TNT1 A 0 A_JumpIfInventory("Shell", 1, "QuadReload");
		QSGN A 4 A_PlaySound("weapons/noammo", CHAN_WEAPON, 0.75);
		Goto Ready;
	DoubleFire:
		TNT1 A 0 A_TakeInventory("TuinDoomGuyQuadLoaded", 2);
		TNT1 A 0 A_PlaySound("tuin/doomguy/quaddouble", CHAN_WEAPON, 1.0);
		TNT1 A 0 A_AlertMonsters;
		TNT1 A 0 A_GunFlash;
		TNT1 A 0 A_FireBullets(11.2, 7.1, 20, 5, "XtremeSGPuff");
		QSGF C 1 Bright A_Light1;
		QSGF D 1 Bright A_Light2;
		TNT1 A 0 A_Light0;
		QRE2 A 2;
		QRE2 BCDE 1;
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadLoaded", 2, "AltRefire");
		Goto TryAutoReload;
	AltRefire:
		TNT1 A 0 A_ReFire("AltFire");
		TNT1 A 0 A_TakeInventory("TuinDoomGuyQuadAltChain", 1);
		Goto Ready;
	Reload:
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadLoaded", 4, "Ready");
		TNT1 A 0 A_JumpIfInventory("Shell", 1, "QuadReload");
		Goto Ready;
	TryAutoReload:
		TNT1 A 0 A_JumpIfInventory("Shell", 1, "QuadReload");
		Goto Ready;
	QuadReload:
		// Roughly 40% shorter than the imported reload, on top of the
		// approximately 25% faster firing and recovery sequences above.
		QSGN SRQP 1;
		QS2N I 1;
		QSGN PJ 1;
		QSGN KL 1;
		QS2N L 1;
		QSGR A 7 A_PlaySound("tuin/doomguy/quadopen", CHAN_WEAPON, 0.9);
		QSGR BCD 1;
		QSGR E 2 A_PlaySound("tuin/doomguy/quadload", CHAN_WEAPON, 0.9);
		TNT1 A 0 A_JumpIfInventory("Shell", 2, "LoadFirstPair");
		TNT1 A 0 A_TakeInventory("Shell", 1);
		TNT1 A 0 A_GiveInventory("TuinDoomGuyQuadLoaded", 1);
		Goto AfterFirstPair;
	LoadFirstPair:
		TNT1 A 0 A_TakeInventory("Shell", 2);
		TNT1 A 0 A_GiveInventory("TuinDoomGuyQuadLoaded", 2);
	AfterFirstPair:
		QSGR FGH 1;
		QSGR I 5;
		QSGR JK 1;
		QSGR LM 1;
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadLoaded", 4, "CloseQuad");
		TNT1 A 0 A_JumpIfInventory("Shell", 1, "LoadSecondPair");
		Goto CloseQuad;
	LoadSecondPair:
		QSGR N 2 A_PlaySound("tuin/doomguy/quadload", CHAN_WEAPON, 0.9);
		TNT1 A 0 A_JumpIfInventory("Shell", 2, "LoadSecondPairTwo");
		TNT1 A 0 A_TakeInventory("Shell", 1);
		TNT1 A 0 A_GiveInventory("TuinDoomGuyQuadLoaded", 1);
		Goto FinishSecondPair;
	LoadSecondPairTwo:
		TNT1 A 0 A_TakeInventory("Shell", 2);
		TNT1 A 0 A_GiveInventory("TuinDoomGuyQuadLoaded", 2);
	FinishSecondPair:
		QSGR OP 1;
		QSGR Q 1;
	CloseQuad:
		QSGN MNO 1;
		QSGN P 1 A_PlaySound("tuin/doomguy/quadclose", CHAN_WEAPON, 0.9);
		QSGN QRS 1;
		QSGN A 1;
		TNT1 A 0 A_JumpIfInventory("TuinDoomGuyQuadAltChain", 1, "AltReloadRefire");
		Goto Ready;
	AltReloadRefire:
		TNT1 A 0 A_ReFire("AltFire");
		TNT1 A 0 A_TakeInventory("TuinDoomGuyQuadAltChain", 1);
		Goto Ready;
	}
}
