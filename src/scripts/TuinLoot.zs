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
			Scale = (0.49, 0.49);
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
		int collected = Amount;
		A_RemoveLight('TuinCoinGlow');
		bool pickedUp = Super.TryPickup(toucher);
		if (pickedUp && toucher)
		{
			let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
			if (data) data.LevelCoinsEarned += max(0, collected);
		}
		return pickedUp;
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

class TuinLifePickup : Inventory
{
	override void BeginPlay()
	{
		Super.BeginPlay();
		A_AttachLight('TuinLifeGlow', DynamicLight.PulseLight, Color(255, 28, 18), 46, 78,
			DynamicLight.LF_ATTENUATE, (0, 0, 20), 0.55);
	}

	override void Tick()
	{
		Super.Tick();
		if ((level.Time % 6) == 0)
			A_SpawnParticle(Color(255, 54, 22), SPF_FULLBRIGHT | SPF_FACECAMERA, 13, 3.0, 0,
				FRandom[TuinLifeSpark](-11.0, 11.0), FRandom[TuinLifeSpark](-4.0, 4.0),
				FRandom[TuinLifeSpark](2.0, 38.0), 0, 0, 0.35, 0, 0, -0.02, 0.18, 0.05);
	}

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
		if (!data) return false;
		int maximum = clamp(CVar.FindCVar('tuin_max_lives') ? CVar.FindCVar('tuin_max_lives').GetInt() : 9, 3, 99);
		if (data.Lives >= maximum)
		{
			toucher.A_Log(String.Format("LIVES FULL: %d / %d", data.Lives, maximum));
			return false;
		}
		data.Lives++;
		toucher.A_StartSound("misc/i_pkup", CHAN_ITEM);
		toucher.A_Log(String.Format("EXTRA LIFE! %d LIVES", data.Lives));
		A_RemoveLight('TuinLifeGlow');
		GoAwayAndDie();
		return true;
	}

	Default
	{
		Radius 16;
		Height 30;
		Scale 0.06;
		Inventory.PickupMessage "Extra life!";
		+FLOATBOB
		+RELATIVETOFLOOR
		+FORCEXYBILLBOARD
	}

	States
	{
	Spawn:
		TLIF A -1 Bright;
		Stop;
	}
}

class TuinLifeEssencePickup : Inventory
{
	override void BeginPlay()
	{
		Super.BeginPlay();
		A_AttachLight('TuinLifeEssenceGlow', DynamicLight.PulseLight,
			Color(70, 255, 130), 32, 56, DynamicLight.LF_ATTENUATE, (0, 0, 12), 0.65);
	}

	override void Tick()
	{
		Super.Tick();
		if ((level.Time % 7) == 0)
			A_SpawnParticle(Color(85, 255, 145), SPF_FULLBRIGHT | SPF_FACECAMERA,
				11, 2.2, 0, FRandom[TuinLifeEssenceSpark](-8.0, 8.0),
				FRandom[TuinLifeEssenceSpark](-8.0, 8.0),
				FRandom[TuinLifeEssenceSpark](1.0, 22.0), 0, 0,
				FRandom[TuinLifeEssenceSpark](0.25, 0.9), 0, 0, -0.015, 0.12, 0.04);
	}

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player || toucher.Health <= 0) return false;
		let data = TuinPlayerData(toucher.FindInventory('TuinPlayerData'));
		if (!data) return false;
		data.LifeEssenceHealingPool += 30.0;
		data.LifeEssenceHealingTics = max(data.LifeEssenceHealingTics, 350);
		toucher.A_StartSound("pickups/lifeessence", CHAN_ITEM,
			CHANF_MAYBE_LOCAL, 1.0, ATTN_NONE);
		let handler = TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
		if (handler)
			handler.SetLootNotification(toucher.PlayerNumber(),
				"LIFE ESSENCE   REGENERATING 30 HEALTH", 1);
		A_RemoveLight('TuinLifeEssenceGlow');
		GoAwayAndDie();
		return true;
	}

	Default
	{
		Radius 12;
		Height 20;
		Scale 0.4;
		Inventory.PickupMessage "Life Essence absorbed.";
		+FLOATBOB
		+RELATIVETOFLOOR
		+INVENTORY.ALWAYSPICKUP
		-COUNTITEM
	}

	States
	{
	Spawn:
		LIFE A -1 Bright;
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
