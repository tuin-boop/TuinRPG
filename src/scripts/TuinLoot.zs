class TuinWeaponDrop : Actor
{
	int VariantID;
	class<Weapon> WeaponType;
	int ItemLevel;
	int Quality;
	int AffixFlags;
	int HastePercent;
	int PowerPercent;
	int LeechPercent;
	int ExecutionPercent;
	int ProsperityPercent;
	int Age;
	string DisplayName;
	bool CatchupReward;

	clearscope static Color QualityColor(int quality)
	{
		switch (quality)
		{
		case 1: return Color(48, 220, 72);
		case 2: return Color(40, 190, 255);
		case 3: return Color(255, 128, 24);
		case 4: return Color(255, 190, 40);
		case 5: return Color(190, 40, 255);
		case 6: return Color(170, 255, 255);
		case 7: return Color(255, 72, 16);
		default: return Color(255, 255, 255);
		}
	}

	void ConfigureVisuals()
	{
		bool unarmedPickup = false;
		if (WeaponType)
		{
			readonly<Weapon> def = GetDefaultByType(WeaponType);
			if (def)
			{
				string label = def.GetTag(def.GetClassName());
				unarmedPickup = def.GetClassName() == 'Fist' || label ~== "FIST" ||
					label ~== "FISTS" || label ~== "BRASS KNUCKLES" || label ~== "KNUCKLES" ||
					label ~== "BARE HANDS" || label ~== "UNARMED" || label ~== "PUNCH" ||
					label ~== "PUNCHES" || label ~== "MARTIAL ARTS";
			}
			if (def && def.SpawnState)
			{
				SetState(def.SpawnState, true);
				Tics = -1;
			}
		}
		// First-person fist sprites commonly have no world offset and disappear below
		// the floor. Use our normalized pickup billboard for fists and knuckles.
		if (unarmedPickup)
		{
			SetState(FindState('KnucklePickup'), true);
			Scale = (0.70, 0.70);
			Tics = -1;
		}
		Color col = QualityColor(Quality);
		SetShade(col);
		A_SetRenderStyle(0.92, STYLE_Shaded);
		int innerRadius = 24 + Quality * 5;
		int outerRadius = 40 + Quality * 10;
		A_AttachLight('TuinLootGlow', Quality >= 4 ? 1 : 0, col, innerRadius, outerRadius, 0,
			(0, 0, Height * 0.5), Quality >= 6 ? 1.0 : Quality >= 4 ? 0.75 : 0.0);
	}

	override void Tick()
	{
		Super.Tick();
		Age++;
		let lifetimeCV = CVar.FindCVar('tuin_weapon_drop_lifetime');
		int lifetime = clamp(lifetimeCV ? lifetimeCV.GetInt() : 90, 15, 600) * 35;
		if (Age >= lifetime) Destroy();
	}

	Default
	{
		Radius 12;
		Height 16;
		Gravity 0.35;
		+NOBLOCKMAP
		+NOINTERACTION
		+RELATIVETOFLOOR
		+FORCEXYBILLBOARD
	}

	States
	{
	KnucklePickup:
		TKNK A -1;
		Stop;
	Spawn:
		TNT1 A -1;
		Stop;
	}
}

class TuinCoinPickup : Inventory
{
	override void BeginPlay()
	{
		Super.BeginPlay();
		A_AttachLight('TuinCoinGlow', DynamicLight.PointLight, Color(255, 190, 32), 28, 42,
			DynamicLight.LF_ATTENUATE, (0, 0, 10));
	}

	override bool TryPickup(in out Actor toucher)
	{
		A_RemoveLight('TuinCoinGlow');
		return Super.TryPickup(toucher);
	}

	Default
	{
		Radius 10;
		Height 12;
		Scale 0.005;
		Inventory.MaxAmount 999999;
		Inventory.InterHubAmount 999999;
		Inventory.PickupMessage "Picked up Tuin coins.";
		Inventory.PickupSound "misc/i_pkup";
		+INVENTORY.KEEPDEPLETED
		+INVENTORY.UNDROPPABLE
		+FLOATBOB
		+RELATIVETOFLOOR
	}

	States
	{
	Spawn:
		TCIN A -1 Bright;
		Stop;
	}
}

class TuinJohnShopNPC : Actor
{
	Default
	{
		Radius 18;
		Height 56;
		Scale 0.9375;
		Mass 1000;
		-SOLID
		+FRIENDLY
		+NOTARGET
		+NOBLOOD
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		JOHN A -1;
		Stop;
	}
}

// A rare adaptive-director ambusher. It deliberately reuses the stock Imp
// states so it remains readable in Doom and compatible with gore/voxel packs.
class TuinAssassinImp : DoomImp
{
	Default
	{
		Tag "Assassin Imp";
		Health 120;
		Speed 14;
		PainChance 96;
		Scale 0.90;
		RenderStyle "Translucent";
		Alpha 0.68;
		+SHADOW
		+AMBUSH
	}
}

// Map-specific replacements selected by TuinRPGHandler.CheckReplacement.
// Their attacks and visuals remain entirely stock; only the final A_BossDeath
// frame is omitted so John, rather than Doom's hard-coded episode ending,
// controls the E2M8/E3M8 transition.
class TuinFinaleCyberdemon : Cyberdemon
{
	Default
	{
		-BOSSDEATH
		-E2M8BOSS
	}
	States
	{
	Death:
		CYBR H 10;
		CYBR I 10 A_Scream;
		CYBR JKL 10;
		CYBR M 10 A_NoBlocking;
		CYBR NO 10;
		CYBR P -1;
		Stop;
	}
}

class TuinFinaleSpiderMastermind : SpiderMastermind
{
	Default
	{
		-BOSSDEATH
		-E3M8BOSS
	}
	States
	{
	Death:
		SPID J 20 A_Scream;
		SPID K 10 A_NoBlocking;
		SPID LMNOPQR 10;
		SPID S -1;
		Stop;
	}
}
