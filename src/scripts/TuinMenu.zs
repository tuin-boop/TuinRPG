class TuinRPGOptionsMenu : OptionMenu
{
	int LastDifficulty;

	static void SetFloatCVar(Name key, double value)
	{
		let cv = CVar.FindCVar(key);
		if (cv) cv.SetFloat(value);
	}

	static void MarkProfileApplied(int mode)
	{
		let cv = CVar.FindCVar('tuin_difficulty_profile_applied');
		if (cv) cv.SetInt(mode);
		let scaling = CVar.FindCVar('tuin_scaling_migrated_121');
		if (scaling) scaling.SetBool(true);
	}

	static void ApplyVisibleProfile(int mode)
	{
		if (mode == 0)
		{
			SetFloatCVar('tuin_health_scale', 0.025); SetFloatCVar('tuin_damage_scale', 0.012);
			SetFloatCVar('tuin_rarity_uncommon_chance', 8.0); SetFloatCVar('tuin_rarity_rare_chance', 4.0);
			SetFloatCVar('tuin_rarity_elite_chance', 1.5); SetFloatCVar('tuin_rarity_legendary_chance', 0.50);
			SetFloatCVar('tuin_rarity_mythic_chance', 0.25);
		}
		else if (mode == 1)
		{
			SetFloatCVar('tuin_health_scale', 0.045); SetFloatCVar('tuin_damage_scale', 0.020);
			SetFloatCVar('tuin_rarity_uncommon_chance', 11.0); SetFloatCVar('tuin_rarity_rare_chance', 5.0);
			SetFloatCVar('tuin_rarity_elite_chance', 2.0); SetFloatCVar('tuin_rarity_legendary_chance', 0.75);
			SetFloatCVar('tuin_rarity_mythic_chance', 0.35);
		}
		else if (mode == 3)
		{
			SetFloatCVar('tuin_health_scale', 0.100); SetFloatCVar('tuin_damage_scale', 0.040);
			SetFloatCVar('tuin_rarity_uncommon_chance', 21.0); SetFloatCVar('tuin_rarity_rare_chance', 10.0);
			SetFloatCVar('tuin_rarity_elite_chance', 3.5); SetFloatCVar('tuin_rarity_legendary_chance', 1.50);
			SetFloatCVar('tuin_rarity_mythic_chance', 0.75);
		}
		else
		{
			SetFloatCVar('tuin_health_scale', 0.070); SetFloatCVar('tuin_damage_scale', 0.028);
			SetFloatCVar('tuin_rarity_uncommon_chance', 15.0); SetFloatCVar('tuin_rarity_rare_chance', 7.0);
			SetFloatCVar('tuin_rarity_elite_chance', 2.5); SetFloatCVar('tuin_rarity_legendary_chance', 1.00);
			SetFloatCVar('tuin_rarity_mythic_chance', 0.50);
		}
	}

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		LastDifficulty = TuinRPGHandler.DifficultyMode();
		let applied = CVar.FindCVar('tuin_difficulty_profile_applied');
		if (!applied || applied.GetInt() != LastDifficulty)
		{
			ApplyVisibleProfile(LastDifficulty);
			MarkProfileApplied(LastDifficulty);
		}
	}

	override void Drawer()
	{
		int mode = TuinRPGHandler.DifficultyMode();
		if (mode != LastDifficulty)
		{
			LastDifficulty = mode;
			ApplyVisibleProfile(mode);
			MarkProfileApplied(mode);
		}
		Super.Drawer();

		Font font = SmallFont;
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		double scale = clamp(TuinRPGHandler.CVFloat('tuin_hud_scale', 1.5), 1.4, 2.0);
		int panelWidth = min(sw - 32, int(330 * scale));
		int panelHeight = int(112 * scale);
		int panelX = sw - panelWidth - 20;
		int panelY = max(20, (sh - panelHeight) / 2);
		int x = panelX + int(12 * scale);
		int y = panelY + int(9 * scale);
		int line = int(14 * scale);
		string modeName = mode == 0 ? "EASY" : mode == 1 ? "NORMAL" : mode == 2 ? "HARD" : "CRAZY";
		double health = TuinRPGHandler.CVFloat('tuin_health_scale', 0.05) * 100.0;
		double damage = TuinRPGHandler.CVFloat('tuin_damage_scale', 0.02) * 100.0;
		Screen.Dim(Color(4, 5, 12), 0.97, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(232, 160, 24), panelX, panelY, panelWidth, panelHeight, 2);
		Screen.DrawText(font, Font.CR_GOLD, x, y, "DIFFICULTY PROFILE", DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(font, mode == 3 ? Font.CR_RED : mode == 0 ? Font.CR_GREEN : Font.CR_GOLD,
			x, y + line, modeName, DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(font, Font.CR_WHITE, x, y + line * 3, String.Format("HEALTH PER LEVEL   +%.2f%%", health), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(font, Font.CR_WHITE, x, y + line * 4, String.Format("DAMAGE PER LEVEL   +%.2f%%", damage), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(font, Font.CR_WHITE, x, y + line * 5, String.Format("MAXIMUM BUFFS      %d", TuinRPGHandler.DifficultyAffixMaximum()), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(font, Font.CR_WHITE, x, y + line * 6, String.Format("RARITY POWER       HP x%.2f / DMG x%.2f",
			TuinRPGHandler.DifficultyHealthPowerFactor(), TuinRPGHandler.DifficultyDamagePowerFactor()), DTA_ScaleX, scale, DTA_ScaleY, scale);
	}
}

class TuinRPGCharacterMenuLegacy : OptionMenu
{
	double OldTimeScale;
	bool ChangedTimeScale;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		int behavior = CVar.FindCVar('tuin_menu_time_mode').GetInt();
		if (behavior == 1)
		{
			let timescale = CVar.FindCVar('i_timescale');
			if (timescale)
			{
				OldTimeScale = timescale.GetFloat();
				timescale.SetFloat(0.10);
				ChangedTimeScale = true;
			}
			menuactive = Menu.OnNoPause;
		}
		else if (behavior == 2) menuactive = Menu.OnNoPause;
	}

	void RestoreTimeScale()
	{
		if (ChangedTimeScale)
		{
			let timescale = CVar.FindCVar('i_timescale');
			if (timescale) timescale.SetFloat(OldTimeScale);
			ChangedTimeScale = false;
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Back) RestoreTimeScale();
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override void Drawer()
	{
		Super.Drawer();
		if (consoleplayer < 0 || !playerInGame[consoleplayer] || !players[consoleplayer].mo) return;
		let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
		if (!data) return;
		Font f = SmallFont;
		int w = Screen.GetWidth();
		int h = Screen.GetHeight();
		double scale = clamp(TuinRPGHandler.CVFloat('tuin_hud_scale', 1.5) * 1.18, 1.75, 3.0);
		scale = min(scale, max(1.15, double(w - 48) / 560.0));
		int panelWidth = int(560 * scale);
		int panelHeight = int(345 * scale);
		int panelX = clamp(w / 2 + 20, 24, w - panelWidth - 24);
		int panelY = max(28, h / 2 - int(175 * scale));
		int x = panelX + int(18 * scale);
		int y = panelY + int(15 * scale);
		int line = int(14 * scale);
		Actor pawn = players[consoleplayer].mo;
		int variantIndex = TuinRPGHandler.ActiveWeaponVariantIndex(consoleplayer, data);
		int weaponAffixPower = variantIndex >= 0 ? data.VariantPowerPercent[variantIndex] : 0;
		int weaponLevelPower = variantIndex >= 0 ? TuinRPGHandler.WeaponItemLevelPowerPercent(data.VariantItemLevel[variantIndex]) : 0;
		int weaponPower = variantIndex >= 0 ? TuinRPGHandler.WeaponTotalPowerPercent(data.VariantItemLevel[variantIndex], weaponAffixPower) : 0;
		int weaponHaste = variantIndex >= 0 ? data.VariantHastePercent[variantIndex] : 0;
		int weaponLeech = variantIndex >= 0 ? data.VariantLeechPercent[variantIndex] : 0;
		int weaponExecution = variantIndex >= 0 ? data.VariantExecutionPercent[variantIndex] : 0;
		int weaponProsperity = variantIndex >= 0 ? data.VariantProsperityPercent[variantIndex] : 0;
		int weaponCritical = variantIndex >= 0 ? TuinRPGHandler.WeaponCriticalPercent(data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex], data.VariantItemLevel[variantIndex]) : 0;
		int playerDamage = data.Strength * 2;
		int playerHaste = min(75, data.Agility * 2);
		double luckCritical = data.Luck * 0.5;
		Weapon activeWeapon = players[consoleplayer].ReadyWeapon;
		double rogueCritical = TuinRPGHandler.RogueCriticalBonus(data, activeWeapon);
		double classDamage = data.PlayerClass == 1 ? (data.TankOverdriveActive ? 1.25 : 1.00) : data.PlayerClass == 2 ? 0.75 :
			data.PlayerClass == 3 ? 1.30 : data.PlayerClass == 4 ? 1.10 : data.PlayerClass == 6 ? 0.90 : 1.0;
		double damageBonus = (classDamage * (1.0 + data.Strength * 0.02) * (1.0 + weaponPower * 0.01) - 1.0) * 100.0;
		int firingSpeed = min(data.PlayerClass == 1 && data.TankOverdriveActive ? 200 : 75,
			data.Agility * 2 + weaponHaste + (data.PlayerClass == 1 && data.TankOverdriveActive ? 150 : 0));
		double criticalChance = TuinRPGHandler.TotalCriticalChance(data, variantIndex, activeWeapon);
		double bonusXPChance = (1.0 - exp(log(0.97) * max(0, data.Luck))) * 100.0;
		double classProtection = data.PlayerClass == 1 ? 0.75 * (1.0 - data.PerkClassMastery * 0.03) : data.PlayerClass == 3 ? 1.10 :
			data.PlayerClass == 4 ? 0.90 : data.PlayerClass == 5 ? 1.10 : 1.0;
		double perkProtection = 1.0 - data.PerkIronSkin * 0.03;
		int totalDamageReduction = int((1.0 - (1.0 - min(75, data.Endurance) * 0.01) * classProtection * perkProtection) * 100.0 + 0.5);
		string weaponName = "STANDARD WEAPON";
		int weaponColor = Font.CR_WHITE;
		int weaponLevel = 0;
		if (players[consoleplayer].ReadyWeapon)
		{
			weaponName = TuinRPGHandler.WeaponBaseName((class<Weapon>)(players[consoleplayer].ReadyWeapon.GetClass()));
			if (variantIndex >= 0)
			{
				weaponName = TuinRPGHandler.WeaponVariantName(data.VariantWeaponType[variantIndex], data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex], data.VariantID[variantIndex]);
				weaponColor = TuinRPGHandler.WeaponQualityFontColor(data.VariantQuality[variantIndex]);
				weaponLevel = data.VariantItemLevel[variantIndex];
			}
		}
		int columnWidth = int(252 * scale);
		int rightX = x + int(270 * scale);
		int columnsY = y + line * 11;
		Screen.Dim(Color(4, 5, 12), 0.96, panelX, panelY, panelWidth, panelHeight);
		Screen.Dim(Color(3, 18, 23), 0.58, x - int(7 * scale), columnsY - int(5 * scale), columnWidth, int(113 * scale));
		Screen.Dim(Color(20, 5, 24), 0.58, rightX - int(7 * scale), columnsY - int(5 * scale), columnWidth, int(113 * scale));

		Screen.DrawText(f, Font.CR_GOLD, x, y, String.Format("LEVEL %d", data.PlayerLevel), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x + int(105 * scale), y, String.Format("XP %d / %d", data.CurrentXP, TuinRPGHandler.XPRequired(data.PlayerLevel)), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, data.PlayerClass > 0 ? Font.CR_GOLD : Font.CR_RED, x + int(300 * scale), y,
			String.Format("CLASS: %s", TuinRPGHandler.PlayerClassName(data.PlayerClass)), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x + int(300 * scale), y + line,
			String.Format("PERK POINTS: %d", data.UnspentSkillPoints), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_GOLD, x, y + line * 2, "ATTRIBUTES", DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_GREEN, x, y + line * 3, String.Format("VITALITY %d", data.Vitality), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_RED, x, y + line * 4, String.Format("STRENGTH %d", data.Strength), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_GOLD, x, y + line * 5, String.Format("LUCK %d", data.Luck), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_CYAN, x + int(160 * scale), y + line * 3, String.Format("AGILITY %d", data.Agility), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_ORANGE, x + int(160 * scale), y + line * 4, String.Format("ENDURANCE %d", data.Endurance), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x + int(160 * scale), y + line * 5, String.Format("UNSPENT POINTS %d", data.UnspentStatPoints), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_GOLD, x, y + line * 6, String.Format(
			"PERKS: VITAL CORE %d | SCAVENGER %d | KILLER INSTINCT %d",
			data.PerkVitalCore, data.PerkScavenger, data.PerkKillerInstinct),
			DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_GOLD, x, y + line * 7, String.Format(
			"IRON SKIN %d | BLOOD DRINKER %d | CLASS TRAINING %d | ULTIMATE %s",
			data.PerkIronSkin, data.PerkBloodDrinker, data.PerkClassMastery,
			data.PerkCapstone ? "YES" : "NO"), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_GOLD, x, y + line * 8,
			String.Format("GIANT SLAYER %d", data.PerkGiantSlayer),
			DTA_ScaleX, scale, DTA_ScaleY, scale);

		Screen.DrawText(f, Font.CR_GOLD, x, y + line * 9, "CURRENT WEAPON", DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, weaponColor, x, y + line * 10, variantIndex >= 0 ? String.Format("%s  -  ITEM LEVEL %d", weaponName, weaponLevel) : weaponName, DTA_ScaleX, scale, DTA_ScaleY, scale);

		Screen.DrawText(f, Font.CR_CYAN, x, columnsY, "FROM PLAYER STATS", DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, columnsY + line, String.Format("MAX HEALTH  \c[green]%d\c[white]  (VITALITY +%d | PERK +%d)", pawn.GetMaxHealth(true), data.Vitality * 5, data.PerkVitalCore * 10), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, columnsY + line * 2, String.Format("DAMAGE  \c[cyan]+%d%%\c[white]  (STRENGTH)", playerDamage), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, columnsY + line * 3, String.Format("FIRE SPEED  \c[cyan]+%d%%\c[white]  (AGILITY)", playerHaste), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, columnsY + line * 4, String.Format("CRITICAL  \c[cyan]%.1f%%", 2.0 + luckCritical + data.PerkKillerInstinct * 2.0 + rogueCritical), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, columnsY + line * 5, String.Format("  BASE 2 | LUCK +%.1f | CLASS/PERKS +%.1f", luckCritical, data.PerkKillerInstinct * 2.0 + rogueCritical), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, columnsY + line * 6, String.Format("DAMAGE REDUCTION  \c[green]%d%%", totalDamageReduction), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, columnsY + line * 7, String.Format("LEECH \c[green]%d%%\c[white] | BONUS XP \c[gold]%.1f%%", data.PerkBloodDrinker, bonusXPChance), DTA_ScaleX, scale, DTA_ScaleY, scale);

		Screen.DrawText(f, Font.CR_PURPLE, rightX, columnsY, "FROM CURRENT WEAPON", DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, rightX, columnsY + line, String.Format("DAMAGE  \c[purple]+%d%%\c[white]  (LEVEL +%d | ROLL +%d)", weaponPower, weaponLevelPower, weaponAffixPower), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, rightX, columnsY + line * 2, String.Format("FIRE SPEED  \c[purple]+%d%%", weaponHaste), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, rightX, columnsY + line * 3, String.Format("CRITICAL  \c[purple]+%d%%", weaponCritical), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, rightX, columnsY + line * 4, String.Format("DAMAGE LEECH  \c[purple]%d%%", weaponLeech), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, rightX, columnsY + line * 5, String.Format("EXECUTION DAMAGE  \c[purple]+%d%%", weaponExecution), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, rightX, columnsY + line * 6, String.Format("KILL XP  \c[purple]+%d%%", weaponProsperity), DTA_ScaleX, scale, DTA_ScaleY, scale);

		Screen.DrawText(f, Font.CR_GOLD, x, y + line * 19, "COMBINED TOTALS", DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x, y + line * 20, String.Format("DAMAGE  \c[gold]+%.1f%%", damageBonus), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x + int(175 * scale), y + line * 20, String.Format("FIRE SPEED  \c[gold]+%d%% / 75%%", firingSpeed), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, x + int(375 * scale), y + line * 20, String.Format("CRITICAL  \c[gold]%.1f%% / 50%%", criticalChance), DTA_ScaleX, scale, DTA_ScaleY, scale);
	}
}

class TuinRPGHiddenCommandItem : OptionMenuItemCommand
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected) { return -1; }
}

class TuinRPGHiddenSubmenuItem : OptionMenuItemSubmenu
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected) { return -1; }
}

class TuinRPGMenuTimeItem : OptionMenuItemCommand
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected) { return -1; }
	override bool Activate()
	{
		let mode = CVar.FindCVar('tuin_menu_time_mode');
		if (mode) mode.SetInt((mode.GetInt() + 1) % 3);
		Menu.MenuSound("menu/change");
		return true;
	}
}

class TuinRPGCharacterMenu : OptionMenu
{
	double OldTimeScale;
	bool ChangedTimeScale;

	void DrawNavCard(Font font, int itemIndex, int x, int y, int width, int height,
		string heading, string detail, Color accent, int textColor)
	{
		bool selected = mDesc.mSelectedItem == itemIndex;
		Screen.Dim(selected ? Color(11, 43, 76) : Color(5, 23, 43), 0.98, x, y, width, height);
		Screen.Dim(accent, selected ? 0.52 : 0.22, x, y, 8, height);
		Screen.DrawLineFrame(selected ? accent : Color(26, 68, 105), x, y, width, height, selected ? 2 : 1);
		Screen.DrawText(font, selected ? textColor : Font.CR_WHITE, x + 21, y + 10, heading,
			DTA_ScaleX, 2.40, DTA_ScaleY, 2.40);
		Screen.DrawText(font, Font.CR_GRAY, x + 21, y + 31, detail,
			DTA_ScaleX, 1.85, DTA_ScaleY, 1.85);
	}

	void DrawAttributeCard(Font font, int itemIndex, int x, int y, int width, int height,
		string heading, int value, string effect, Color accent, int textColor, int unspent)
	{
		bool selected = mDesc.mSelectedItem == itemIndex;
		Screen.Dim(selected ? Color(11, 43, 76) : Color(5, 23, 43), 0.98, x, y, width, height);
		Screen.Dim(accent, selected ? 0.48 : 0.20, x, y, 8, height);
		Screen.DrawLineFrame(selected ? accent : Color(26, 68, 105), x, y, width, height, selected ? 2 : 1);
		Screen.DrawText(font, selected ? textColor : Font.CR_WHITE, x + 22, y + 14, heading,
			DTA_ScaleX, 2.70, DTA_ScaleY, 2.70);
		Screen.DrawText(font, textColor, x + width - 70, y + 14, String.Format("%d", value),
			DTA_ScaleX, 2.70, DTA_ScaleY, 2.70);
		Screen.DrawText(font, Font.CR_WHITE, x + 22, y + 49, effect,
			DTA_ScaleX, 2.0, DTA_ScaleY, 2.0);
		if (selected)
			Screen.DrawText(font, unspent > 0 ? Font.CR_GOLD : Font.CR_GRAY, x + 22, y + height - 27,
				unspent > 0 ? "ENTER OR CLICK: SPEND 1 POINT" : "NO STAT POINTS AVAILABLE",
				DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
	}

	void DrawInfoBox(Font font, int x, int y, int width, int height, string heading,
		Color accent, int headingColor)
	{
		Screen.Dim(Color(4, 20, 38), 0.98, x, y, width, height);
		Screen.Dim(accent, 0.30, x, y, 8, height);
		Screen.DrawLineFrame(Color(27, 69, 106), x, y, width, height, 1);
		Screen.DrawText(font, headingColor, x + 22, y + 15, heading,
			DTA_ScaleX, 2.35, DTA_ScaleY, 2.35);
	}

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			let item = mDesc.mItems[i];
			if (item.mLabel ~== "CLASS AND PERKS")
				mDesc.mItems[i] = new ('TuinRPGHiddenSubmenuItem').Init(item.mLabel, 'TuinRPGPerkHub');
			else if (item.mLabel ~== "ARSENAL")
				mDesc.mItems[i] = new ('TuinRPGHiddenSubmenuItem').Init(item.mLabel, 'TuinRPGArsenal');
			else if (item.mLabel ~== "MENU TIME")
				mDesc.mItems[i] = new ('TuinRPGMenuTimeItem').Init(item.mLabel, "");
			else
			{
				string command = item.mLabel ~== "VITALITY" ? "netevent tuin_spend_vitality" :
					item.mLabel ~== "STRENGTH" ? "netevent tuin_spend_strength" :
					item.mLabel ~== "LUCK" ? "netevent tuin_spend_luck" :
					item.mLabel ~== "AGILITY" ? "netevent tuin_spend_agility" : "netevent tuin_spend_endurance";
				mDesc.mItems[i] = new ('TuinRPGHiddenCommandItem').Init(item.mLabel, command);
			}
		}
		mDesc.mSelectedItem = 0;
		mDesc.CalcIndent();
		int behavior = CVar.FindCVar('tuin_menu_time_mode').GetInt();
		if (behavior == 1)
		{
			let timescale = CVar.FindCVar('i_timescale');
			if (timescale)
			{
				OldTimeScale = timescale.GetFloat();
				timescale.SetFloat(0.10);
				ChangedTimeScale = true;
			}
			menuactive = Menu.OnNoPause;
		}
		else if (behavior == 2) menuactive = Menu.OnNoPause;
	}

	void RestoreTimeScale()
	{
		if (!ChangedTimeScale) return;
		let timescale = CVar.FindCVar('i_timescale');
		if (timescale) timescale.SetFloat(OldTimeScale);
		ChangedTimeScale = false;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Left) return Super.MenuEvent(MKEY_Up, fromcontroller);
		if (mkey == MKEY_Right) return Super.MenuEvent(MKEY_Down, fromcontroller);
		if (mkey == MKEY_Back) RestoreTimeScale();
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		int panelWidth = min(sw - 72, 1660);
		int panelHeight = min(sh - 72, 800);
		int panelX = (sw - panelWidth) / 2;
		int panelY = (sh - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.21), 310, 350);
		int middleWidth = clamp(int(panelWidth * 0.27), 390, 450);
		int navHeight = 52;
		int navGap = 10;
		int navStart = panelY + panelHeight - 3 * (navHeight + navGap) - 12;
		int attrGap = 10;
		int attrHeight = (panelHeight - 153 - attrGap * 4) / 5;
		int middleX = panelX + leftWidth + 18;
		int hit = -1;
		if (x >= panelX + 20 && x < panelX + leftWidth - 14)
		{
			if (y >= navStart && y < navStart + navHeight) hit = 0;
			else if (y >= navStart + navHeight + navGap && y < navStart + navHeight * 2 + navGap) hit = 6;
			else if (y >= navStart + (navHeight + navGap) * 2 && y < navStart + navHeight * 3 + navGap * 2) hit = 7;
		}
		if (x >= middleX && x < middleX + middleWidth)
			for (int i = 0; i < 5; i++)
			{
				int attrY = panelY + 92 + i * (attrHeight + attrGap);
				if (y >= attrY && y < attrY + attrHeight) hit = i + 1;
			}
		if (hit >= 0)
		{
			if (mDesc.mSelectedItem != hit)
			{
				mDesc.mSelectedItem = hit;
				MenuSound("menu/cursor");
			}
			if (type == MOUSE_Release) return MenuEvent(MKEY_Enter, true);
		}
		return true;
	}

	override void Drawer()
	{
		if (consoleplayer < 0 || !playerInGame[consoleplayer] || !players[consoleplayer].mo) { Super.Drawer(); return; }
		let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
		if (!data) { Super.Drawer(); return; }
		Actor pawn = players[consoleplayer].mo;
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		int panelWidth = min(sw - 72, 1660);
		int panelHeight = min(sh - 72, 800);
		int panelX = (sw - panelWidth) / 2;
		int panelY = (sh - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.21), 310, 350);
		int middleWidth = clamp(int(panelWidth * 0.27), 390, 450);
		int middleX = panelX + leftWidth + 18;
		int rightX = middleX + middleWidth + 18;
		int rightWidth = panelX + panelWidth - 20 - rightX;
		Font font = "TINYBABY";
		Screen.Dim(Color(3, 13, 31), 0.98, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(1, 5, 13), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(Color(36, 128, 210), panelX + 7, panelY + 7, panelWidth - 14, panelHeight - 14, 2);
		Screen.DrawText(font, Font.CR_WHITE, panelX + 24, panelY + 22, "CHARACTER DASHBOARD",
			DTA_ScaleX, 3.10, DTA_ScaleY, 3.10);
		Screen.DrawText(font, Font.CR_LIGHTBLUE, middleX, panelY + 29, "ATTRIBUTES",
			DTA_ScaleX, 2.55, DTA_ScaleY, 2.55);
		Screen.DrawText(font, Font.CR_PURPLE, rightX, panelY + 29, "COMBAT BREAKDOWN",
			DTA_ScaleX, 2.55, DTA_ScaleY, 2.55);

		int classIndex = clamp(data.PlayerClass - 1, 0, 5);
		string portraitName = classIndex == 0 ? "graphics/TuinClassHeavy.png" : classIndex == 1 ? "graphics/TuinClassMedic.png" :
			classIndex == 2 ? "graphics/TuinClassExecutioner.png" : classIndex == 3 ? "graphics/TuinClassDoomGuy.png" :
			classIndex == 4 ? "graphics/TuinClassRogue.png" : "graphics/TuinClassEngineer.png";
		TextureID portrait = TexMan.CheckForTexture(portraitName, TexMan.Type_Any);
		int navHeight = 52;
		int navGap = 10;
		int navStart = panelY + panelHeight - 3 * (navHeight + navGap) - 12;
		int artSize = min(leftWidth - 70, navStart - panelY - 140);
		int artX = panelX + (leftWidth - artSize) / 2;
		int artY = panelY + 72;
		if (portrait.IsValid()) Screen.DrawTexture(portrait, false, artX, artY,
			DTA_DestWidth, artSize, DTA_DestHeight, artSize);
		string className = TuinRPGHandler.PlayerClassName(data.PlayerClass);
		int infoY = artY + artSize + 18;
		Screen.DrawText(font, Font.CR_GOLD, panelX + 28, infoY, className,
			DTA_ScaleX, 2.75, DTA_ScaleY, 2.75);
		Screen.DrawText(font, Font.CR_WHITE, panelX + 28, infoY + 34,
			String.Format("LEVEL %d    XP %d / %d", data.PlayerLevel, data.CurrentXP, TuinRPGHandler.XPRequired(data.PlayerLevel)),
			DTA_ScaleX, 2.0, DTA_ScaleY, 2.0);
		Screen.DrawText(font, data.UnspentStatPoints > 0 ? Font.CR_GOLD : Font.CR_GRAY, panelX + 28, infoY + 62,
			String.Format("STAT POINTS: %d", data.UnspentStatPoints), DTA_ScaleX, 2.1, DTA_ScaleY, 2.1);
		Screen.DrawText(font, data.UnspentSkillPoints > 0 ? Font.CR_GOLD : Font.CR_GRAY, panelX + 28, infoY + 90,
			String.Format("PERK POINTS: %d", data.UnspentSkillPoints), DTA_ScaleX, 2.1, DTA_ScaleY, 2.1);
		int timeMode = CVar.FindCVar('tuin_menu_time_mode').GetInt();
		string timeName = timeMode == 0 ? "PAUSE GAME" : timeMode == 1 ? "SLOW MOTION 10%" : "DO NOT PAUSE";
		DrawNavCard(font, 0, panelX + 20, navStart, leftWidth - 34, navHeight, "CLASS AND PERKS", "OPEN BUILD DASHBOARD", Color(55, 153, 238), Font.CR_LIGHTBLUE);
		DrawNavCard(font, 6, panelX + 20, navStart + navHeight + navGap, leftWidth - 34, navHeight, "ARSENAL", "INSPECT WEAPON VARIANTS", Color(178, 94, 237), Font.CR_PURPLE);
		DrawNavCard(font, 7, panelX + 20, navStart + (navHeight + navGap) * 2, leftWidth - 34, navHeight, "MENU TIME", timeName, Color(233, 179, 45), Font.CR_GOLD);

		int attrGap = 10;
		int attrHeight = (panelHeight - 153 - attrGap * 4) / 5;
		DrawAttributeCard(font, 1, middleX, panelY + 92, middleWidth, attrHeight, "VITALITY", data.Vitality, "+5 MAXIMUM HEALTH", Color(75, 210, 108), Font.CR_GREEN, data.UnspentStatPoints);
		DrawAttributeCard(font, 2, middleX, panelY + 92 + (attrHeight + attrGap), middleWidth, attrHeight, "STRENGTH", data.Strength, data.PlayerClass == 1 ? "+2% DAMAGE; +5 HEAVY HEALTH" : "+2% WEAPON DAMAGE", Color(234, 67, 53), Font.CR_RED, data.UnspentStatPoints);
		DrawAttributeCard(font, 3, middleX, panelY + 92 + (attrHeight + attrGap) * 2, middleWidth, attrHeight, "LUCK", data.Luck, "+0.5% CRITICAL AND BONUS XP", Color(233, 179, 45), Font.CR_GOLD, data.UnspentStatPoints);
		DrawAttributeCard(font, 4, middleX, panelY + 92 + (attrHeight + attrGap) * 3, middleWidth, attrHeight, "AGILITY", data.Agility, "+2% FIRING SPEED", Color(48, 201, 218), Font.CR_CYAN, data.UnspentStatPoints);
		DrawAttributeCard(font, 5, middleX, panelY + 92 + (attrHeight + attrGap) * 4, middleWidth, attrHeight, "ENDURANCE", data.Endurance, "-1% DAMAGE TAKEN", Color(244, 123, 39), Font.CR_ORANGE, data.UnspentStatPoints);

		int variantIndex = TuinRPGHandler.ActiveWeaponVariantIndex(consoleplayer, data);
		int weaponAffixPower = variantIndex >= 0 ? data.VariantPowerPercent[variantIndex] : 0;
		int weaponLevelPower = variantIndex >= 0 ? TuinRPGHandler.WeaponItemLevelPowerPercent(data.VariantItemLevel[variantIndex]) : 0;
		int weaponPower = variantIndex >= 0 ? TuinRPGHandler.WeaponTotalPowerPercent(data.VariantItemLevel[variantIndex], weaponAffixPower) : 0;
		int weaponHaste = variantIndex >= 0 ? data.VariantHastePercent[variantIndex] : 0;
		int weaponLeech = variantIndex >= 0 ? data.VariantLeechPercent[variantIndex] : 0;
		int weaponExecution = variantIndex >= 0 ? data.VariantExecutionPercent[variantIndex] : 0;
		int weaponProsperity = variantIndex >= 0 ? data.VariantProsperityPercent[variantIndex] : 0;
		int weaponCritical = variantIndex >= 0 ? TuinRPGHandler.WeaponCriticalPercent(data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex], data.VariantItemLevel[variantIndex]) : 0;
		Weapon activeWeapon = players[consoleplayer].ReadyWeapon;
		double rogueCritical = TuinRPGHandler.RogueCriticalBonus(data, activeWeapon);
		double classDamage = data.PlayerClass == 1 ? (data.TankOverdriveActive ? 1.25 : 1.00) : data.PlayerClass == 2 ? 0.75 :
			data.PlayerClass == 3 ? 1.30 : data.PlayerClass == 4 ? 1.10 : data.PlayerClass == 6 ? 0.90 : 1.0;
		double damageBonus = (classDamage * (1.0 + data.Strength * 0.02) * (1.0 + weaponPower * 0.01) - 1.0) * 100.0;
		int firingSpeed = min(data.PlayerClass == 1 && data.TankOverdriveActive ? 200 : 75,
			data.Agility * 2 + weaponHaste + (data.PlayerClass == 1 && data.TankOverdriveActive ? 150 : 0));
		double criticalChance = TuinRPGHandler.TotalCriticalChance(data, variantIndex, activeWeapon);
		double bonusXPChance = (1.0 - exp(log(0.97) * max(0, data.Luck))) * 100.0;
		double classProtection = data.PlayerClass == 1 ? 0.75 * (1.0 - data.PerkClassMastery * 0.03) : data.PlayerClass == 3 ? 1.10 :
			data.PlayerClass == 4 ? 0.90 : data.PlayerClass == 5 ? 1.10 : 1.0;
		int totalDR = int((1.0 - (1.0 - min(75, data.Endurance) * 0.01) * classProtection * (1.0 - data.PerkIronSkin * 0.03)) * 100.0 + 0.5);
		string weaponName = activeWeapon ? TuinRPGHandler.WeaponBaseName((class<Weapon>)(activeWeapon.GetClass())) : "NO WEAPON READY";
		int weaponColor = Font.CR_WHITE;
		int weaponLevel = 0;
		if (variantIndex >= 0)
		{
			weaponName = TuinRPGHandler.WeaponVariantName(data.VariantWeaponType[variantIndex], data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex], data.VariantID[variantIndex]);
			weaponColor = TuinRPGHandler.WeaponQualityFontColor(data.VariantQuality[variantIndex]);
			weaponLevel = data.VariantItemLevel[variantIndex];
		}
		int boxY = panelY + 88;
		DrawInfoBox(font, rightX, boxY, rightWidth, 112, "CURRENT WEAPON", Color(178, 94, 237), Font.CR_PURPLE);
		Screen.DrawText(font, weaponColor, rightX + 22, boxY + 49, weaponName, DTA_ScaleX, 2.20, DTA_ScaleY, 2.20);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 76, variantIndex >= 0 ? String.Format("ITEM LEVEL %d", weaponLevel) : "STANDARD - NO AFFIXES", DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		boxY += 124;
		DrawInfoBox(font, rightX, boxY, rightWidth, 118, "COMBINED TOTALS", Color(233, 179, 45), Font.CR_GOLD);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 51, String.Format("DAMAGE  \c[gold]+%.1f%%", damageBonus), DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 250, boxY + 51, String.Format("FIRE SPEED  \c[gold]+%d%% / 75%%", firingSpeed), DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 82, String.Format("CRITICAL  \c[gold]%.1f%% / 50%%", criticalChance), DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 250, boxY + 82, String.Format("DAMAGE REDUCTION  \c[green]%d%%", totalDR), DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		boxY += 130;
		DrawInfoBox(font, rightX, boxY, rightWidth, 166, "FROM PLAYER", Color(49, 199, 219), Font.CR_CYAN);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 49, String.Format("MAX HEALTH  \c[green]%d\c[white]   VITALITY +%d   PERK +%d", pawn.GetMaxHealth(true), data.Vitality * 5, data.PerkVitalCore * 10), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 77, String.Format("DAMAGE +%d%%   FIRE SPEED +%d%%", data.Strength * 2, min(75, data.Agility * 2)), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 105, String.Format("CRITICAL %.1f%%   BASE 2 + LUCK %.1f + CLASS/PERKS %.1f", 2.0 + data.Luck * 0.5 + data.PerkKillerInstinct * 2.0 + rogueCritical, data.Luck * 0.5, data.PerkKillerInstinct * 2.0 + rogueCritical), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 133, String.Format("LEECH %d%%   BONUS XP %.1f%%", data.PerkBloodDrinker, bonusXPChance), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		boxY += 178;
		DrawInfoBox(font, rightX, boxY, rightWidth, 172, "FROM WEAPON", Color(178, 94, 237), Font.CR_PURPLE);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 49, String.Format("DAMAGE +%d%%   LEVEL +%d   ROLL +%d", weaponPower, weaponLevelPower, weaponAffixPower), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 77, String.Format("FIRE SPEED +%d%%   CRITICAL +%d%%", weaponHaste, weaponCritical), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 105, String.Format("DAMAGE LEECH %d%%   EXECUTION +%d%%", weaponLeech, weaponExecution), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Screen.DrawText(font, Font.CR_WHITE, rightX + 22, boxY + 133, String.Format("KILL XP +%d%%", weaponProsperity), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Super.Drawer();
	}
}

class TuinRPGArsenalMenuLegacy : OptionMenu
{
	int SelectedIndex;
	int TopIndex;
	double OldTimeScale;
	bool ChangedTimeScale;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		int behavior = CVar.FindCVar('tuin_menu_time_mode').GetInt();
		if (behavior == 1)
		{
			let timescale = CVar.FindCVar('i_timescale');
			if (timescale)
			{
				OldTimeScale = timescale.GetFloat();
				timescale.SetFloat(0.10);
				ChangedTimeScale = true;
			}
			menuactive = Menu.OnNoPause;
		}
		else if (behavior == 2) menuactive = Menu.OnNoPause;
	}

	void RestoreTimeScale()
	{
		if (!ChangedTimeScale) return;
		let timescale = CVar.FindCVar('i_timescale');
		if (timescale) timescale.SetFloat(OldTimeScale);
		ChangedTimeScale = false;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		let data = consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo ?
			TuinRPGHandler.GetPlayerData(players[consoleplayer].mo) : null;
		int count = data ? data.WeaponVariantCount : 0;
		if (mkey == MKEY_Up && count > 0)
		{
			SelectedIndex = (SelectedIndex + count - 1) % count;
			return true;
		}
		if (mkey == MKEY_Down && count > 0)
		{
			SelectedIndex = (SelectedIndex + 1) % count;
			return true;
		}
		if (mkey == MKEY_Back) RestoreTimeScale();
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override void Drawer()
	{
		Super.Drawer();
		if (consoleplayer < 0 || !playerInGame[consoleplayer] || !players[consoleplayer].mo) return;
		let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
		if (!data) return;
		Font f = SmallFont;
		int w = Screen.GetWidth();
		int h = Screen.GetHeight();
		double scale = clamp(TuinRPGHandler.CVFloat('tuin_hud_scale', 1.5), 1.25, 2.25);
		int count = data.WeaponVariantCount;
		if (count <= 0)
		{
			string emptyText = "NO WEAPON VARIANTS COLLECTED";
			Screen.DrawText(f, Font.CR_WHITE, (w - f.StringWidth(emptyText) * scale) / 2, h / 2, emptyText, DTA_ScaleX, scale, DTA_ScaleY, scale);
			return;
		}
		SelectedIndex = clamp(SelectedIndex, 0, count - 1);
		int visibleRows = 10;
		if (SelectedIndex < TopIndex) TopIndex = SelectedIndex;
		if (SelectedIndex >= TopIndex + visibleRows) TopIndex = SelectedIndex - visibleRows + 1;
		int left = max(24, w / 2 - int(310 * scale));
		int top = max(70, h / 2 - int(90 * scale));
		int rowHeight = int(14 * scale);
		Screen.Dim(Color(8, 8, 16), 0.86, left - 12, top - 12, int(600 * scale), int(180 * scale));
		for (int i = TopIndex; i < min(count, TopIndex + visibleRows); i++)
		{
			string marker = i == SelectedIndex ? ">" : " ";
			string equipped = data.VariantEquipped[i] ? " [ACTIVE]" : "";
			string row = String.Format("%s %s  LV %d%s", marker, TuinRPGHandler.WeaponVariantName(data.VariantWeaponType[i], data.VariantAffixFlags[i], data.VariantQuality[i], data.VariantID[i]), data.VariantItemLevel[i], equipped);
			Screen.DrawText(f, TuinRPGHandler.WeaponQualityFontColor(data.VariantQuality[i]), left, top + (i - TopIndex) * rowHeight, row, DTA_ScaleX, scale, DTA_ScaleY, scale);
		}

		int detailX = left + int(330 * scale);
		int detailY = top;
		int line = int(14 * scale);
		int color = TuinRPGHandler.WeaponQualityFontColor(data.VariantQuality[SelectedIndex]);
		Screen.DrawText(f, color, detailX, detailY, TuinRPGHandler.WeaponVariantName(data.VariantWeaponType[SelectedIndex], data.VariantAffixFlags[SelectedIndex], data.VariantQuality[SelectedIndex], data.VariantID[SelectedIndex]), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, color, detailX, detailY + line, String.Format("%s   ITEM LEVEL %d", TuinRPGHandler.WeaponQualityName(data.VariantQuality[SelectedIndex]), data.VariantItemLevel[SelectedIndex]), DTA_ScaleX, scale, DTA_ScaleY, scale);
		Screen.DrawText(f, Font.CR_WHITE, detailX, detailY + line * 2, String.Format("GEAR SCORE %d", TuinRPGHandler.StoredWeaponVariantScore(data, SelectedIndex)), DTA_ScaleX, scale, DTA_ScaleY, scale);
		int statLine = 4;
		int levelPower = TuinRPGHandler.WeaponItemLevelPowerPercent(data.VariantItemLevel[SelectedIndex]);
		if (levelPower) Screen.DrawText(f, Font.CR_GOLD, detailX, detailY + line * statLine++, String.Format("+%d%% item-level damage", levelPower), DTA_ScaleX, scale, DTA_ScaleY, scale);
		if (data.VariantHastePercent[SelectedIndex]) Screen.DrawText(f, Font.CR_WHITE, detailX, detailY + line * statLine++, String.Format("+%d%% firing speed", data.VariantHastePercent[SelectedIndex]), DTA_ScaleX, scale, DTA_ScaleY, scale);
		if (data.VariantPowerPercent[SelectedIndex]) Screen.DrawText(f, Font.CR_WHITE, detailX, detailY + line * statLine++, String.Format("+%d%% damage", data.VariantPowerPercent[SelectedIndex]), DTA_ScaleX, scale, DTA_ScaleY, scale);
		if (data.VariantLeechPercent[SelectedIndex]) Screen.DrawText(f, Font.CR_WHITE, detailX, detailY + line * statLine++, String.Format("%d%% damage leech", data.VariantLeechPercent[SelectedIndex]), DTA_ScaleX, scale, DTA_ScaleY, scale);
		if (data.VariantExecutionPercent[SelectedIndex]) Screen.DrawText(f, Font.CR_WHITE, detailX, detailY + line * statLine++, String.Format("+%d%% execution damage", data.VariantExecutionPercent[SelectedIndex]), DTA_ScaleX, scale, DTA_ScaleY, scale);
		if (data.VariantProsperityPercent[SelectedIndex]) Screen.DrawText(f, Font.CR_WHITE, detailX, detailY + line * statLine++, String.Format("+%d%% kill XP", data.VariantProsperityPercent[SelectedIndex]), DTA_ScaleX, scale, DTA_ScaleY, scale);
		int critical = TuinRPGHandler.WeaponCriticalPercent(data.VariantAffixFlags[SelectedIndex], data.VariantQuality[SelectedIndex], data.VariantItemLevel[SelectedIndex]);
		if (critical) Screen.DrawText(f, Font.CR_WHITE, detailX, detailY + line * statLine++, String.Format("+%d%% critical chance", critical), DTA_ScaleX, scale, DTA_ScaleY, scale);
	}
}

class TuinRPGArsenalMenu : OptionMenu
{
	int SelectedIndex;
	int TopIndex;
	double OldTimeScale;
	bool ChangedTimeScale;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		int behavior = CVar.FindCVar('tuin_menu_time_mode').GetInt();
		if (behavior == 1)
		{
			let timescale = CVar.FindCVar('i_timescale');
			if (timescale)
			{
				OldTimeScale = timescale.GetFloat();
				timescale.SetFloat(0.10);
				ChangedTimeScale = true;
			}
			menuactive = Menu.OnNoPause;
		}
		else if (behavior == 2) menuactive = Menu.OnNoPause;
	}

	void RestoreTimeScale()
	{
		if (!ChangedTimeScale) return;
		let timescale = CVar.FindCVar('i_timescale');
		if (timescale) timescale.SetFloat(OldTimeScale);
		ChangedTimeScale = false;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		let data = consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo ?
			TuinRPGHandler.GetPlayerData(players[consoleplayer].mo) : null;
		int count = data ? data.WeaponVariantCount : 0;
		if ((mkey == MKEY_Up || mkey == MKEY_Left) && count > 0)
		{
			SelectedIndex = (SelectedIndex + count - 1) % count;
			MenuSound("menu/cursor");
			return true;
		}
		if ((mkey == MKEY_Down || mkey == MKEY_Right) && count > 0)
		{
			SelectedIndex = (SelectedIndex + 1) % count;
			MenuSound("menu/cursor");
			return true;
		}
		if (mkey == MKEY_Enter && count > 0)
		{
			EventHandler.SendNetworkEvent("tuin_equip_variant", data.VariantID[SelectedIndex]);
			MenuSound("menu/choose");
			return true;
		}
		if (mkey == MKEY_Back) RestoreTimeScale();
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		let data = consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo ?
			TuinRPGHandler.GetPlayerData(players[consoleplayer].mo) : null;
		if (!data || data.WeaponVariantCount <= 0) return true;
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		int panelWidth = min(sw - 72, 1560);
		int panelHeight = min(sh - 72, 780);
		int panelX = (sw - panelWidth) / 2;
		int panelY = (sh - panelHeight) / 2;
		int listWidth = clamp(int(panelWidth * 0.40), 520, 620);
		int rowHeight = max(48, (panelHeight - 178) / 9);
		for (int row = 0; row < 9; row++)
		{
			int index = TopIndex + row;
			int rowY = panelY + 86 + row * rowHeight;
			if (index < data.WeaponVariantCount && x >= panelX + 24 && x < panelX + listWidth - 10 && y >= rowY && y < rowY + rowHeight - 5)
			{
				if (SelectedIndex != index)
				{
					SelectedIndex = index;
					MenuSound("menu/cursor");
				}
				return true;
			}
		}
		int detailX = panelX + listWidth + 18;
		int buttonY = panelY + panelHeight - 68;
		if (x >= detailX && x < panelX + panelWidth - 24 && y >= buttonY && y < buttonY + 38 && type == MOUSE_Release)
			return MenuEvent(MKEY_Enter, true);
		return true;
	}

	override void Drawer()
	{
		int sw = Screen.GetWidth();
		int sh = Screen.GetHeight();
		int panelWidth = min(sw - 72, 1560);
		int panelHeight = min(sh - 72, 780);
		int panelX = (sw - panelWidth) / 2;
		int panelY = (sh - panelHeight) / 2;
		int listWidth = clamp(int(panelWidth * 0.40), 520, 620);
		int detailX = panelX + listWidth + 18;
		int detailWidth = panelX + panelWidth - 24 - detailX;
		Font font = "TINYBABY";
		Screen.Dim(Color(3, 13, 31), 0.98, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(1, 5, 13), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(Color(36, 128, 210), panelX + 7, panelY + 7, panelWidth - 14, panelHeight - 14, 2);
		Screen.DrawText(font, Font.CR_WHITE, panelX + 25, panelY + 23, "ARSENAL",
			DTA_ScaleX, 3.15, DTA_ScaleY, 3.15);
		Screen.DrawText(font, Font.CR_LIGHTBLUE, panelX + 205, panelY + 29,
			"COLLECTED WEAPON VARIANTS", DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(font, Font.CR_PURPLE, detailX, panelY + 29,
			"WEAPON INSPECTION", DTA_ScaleX, 2.55, DTA_ScaleY, 2.55);
		if (consoleplayer < 0 || !playerInGame[consoleplayer] || !players[consoleplayer].mo) { Super.Drawer(); return; }
		let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
		if (!data || data.WeaponVariantCount <= 0)
		{
			Screen.Dim(Color(5, 23, 43), 0.98, panelX + 24, panelY + 86, panelWidth - 48, 150);
			Screen.DrawText(font, Font.CR_GRAY, panelX + 54, panelY + 123,
				"NO WEAPON VARIANTS COLLECTED", DTA_ScaleX, 3.0, DTA_ScaleY, 3.0);
			Screen.DrawText(font, Font.CR_WHITE, panelX + 54, panelY + 173,
				"DEFEAT UPGRADED MONSTERS AND INSPECT THEIR DROPS.", DTA_ScaleX, 2.25, DTA_ScaleY, 2.25);
			Super.Drawer();
			return;
		}
		int count = data.WeaponVariantCount;
		SelectedIndex = clamp(SelectedIndex, 0, count - 1);
		if (SelectedIndex < TopIndex) TopIndex = SelectedIndex;
		if (SelectedIndex >= TopIndex + 9) TopIndex = SelectedIndex - 8;
		int rowHeight = max(48, (panelHeight - 178) / 9);
		for (int row = 0; row < 9; row++)
		{
			int index = TopIndex + row;
			if (index >= count) break;
			int rowY = panelY + 86 + row * rowHeight;
			bool selected = index == SelectedIndex;
			int qualityColor = TuinRPGHandler.WeaponQualityFontColor(data.VariantQuality[index]);
			Color rowAccent = data.VariantQuality[index] >= 6 ? Color(244, 193, 48) :
				data.VariantQuality[index] >= 5 ? Color(181, 88, 236) : Color(44, 139, 217);
			Screen.Dim(selected ? Color(12, 43, 76) : Color(5, 23, 43), 0.98,
				panelX + 24, rowY, listWidth - 34, rowHeight - 5);
			Screen.Dim(rowAccent, selected ? 0.50 : 0.20, panelX + 24, rowY, 8, rowHeight - 5);
			Screen.DrawLineFrame(selected ? rowAccent : Color(25, 65, 100), panelX + 24, rowY, listWidth - 34, rowHeight - 5, selected ? 2 : 1);
			string name = TuinRPGHandler.WeaponVariantName(data.VariantWeaponType[index], data.VariantAffixFlags[index], data.VariantQuality[index], data.VariantID[index]);
			Screen.DrawText(font, qualityColor, panelX + 47, rowY + 9, name, DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
			Screen.DrawText(font, Font.CR_WHITE, panelX + 47, rowY + 31,
				String.Format("LV %d   SCORE %d%s", data.VariantItemLevel[index], TuinRPGHandler.StoredWeaponVariantScore(data, index), data.VariantEquipped[index] ? "   ACTIVE" : ""),
				DTA_ScaleX, 1.75, DTA_ScaleY, 1.75);
		}
		int selected = SelectedIndex;
		int qualityColor = TuinRPGHandler.WeaponQualityFontColor(data.VariantQuality[selected]);
		string selectedName = TuinRPGHandler.WeaponVariantName(data.VariantWeaponType[selected], data.VariantAffixFlags[selected], data.VariantQuality[selected], data.VariantID[selected]);
		int equippedIndex = data.FindEquippedVariant(data.VariantWeaponType[selected]);
		int selectedScore = TuinRPGHandler.StoredWeaponVariantScore(data, selected);
		int equippedScore = equippedIndex >= 0 ? TuinRPGHandler.StoredWeaponVariantScore(data, equippedIndex) : 0;
		Screen.Dim(Color(5, 23, 43), 0.98, detailX, panelY + 82, detailWidth, 122);
		Screen.DrawLineFrame(Color(75, 50, 111), detailX, panelY + 82, detailWidth, 122, 2);
		Screen.DrawText(font, qualityColor, detailX + 24, panelY + 104, selectedName, DTA_ScaleX, 2.65, DTA_ScaleY, 2.65);
		Screen.DrawText(font, qualityColor, detailX + 24, panelY + 143,
			String.Format("%s   ITEM LEVEL %d", TuinRPGHandler.WeaponQualityName(data.VariantQuality[selected]), data.VariantItemLevel[selected]), DTA_ScaleX, 2.15, DTA_ScaleY, 2.15);
		Screen.DrawText(font, Font.CR_WHITE, detailX + 24, panelY + 171,
			String.Format("GEAR SCORE %d   %s%d VS EQUIPPED", selectedScore, selectedScore >= equippedScore ? "+" : "", selectedScore - equippedScore), DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		int statsY = panelY + 220;
		Screen.Dim(Color(14, 5, 24), 0.72, detailX, statsY, detailWidth, 324);
		Screen.DrawLineFrame(Color(105, 44, 137), detailX, statsY, detailWidth, 324, 1);
		Screen.DrawText(font, Font.CR_PURPLE, detailX + 24, statsY + 18, "AFFIX AND POWER BREAKDOWN", DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		int statY = statsY + 61;
		int levelPower = TuinRPGHandler.WeaponItemLevelPowerPercent(data.VariantItemLevel[selected]);
		Screen.DrawText(font, Font.CR_GOLD, detailX + 24, statY, String.Format("ITEM-LEVEL DAMAGE          +%d%%", levelPower), DTA_ScaleX, 2.10, DTA_ScaleY, 2.10); statY += 34;
		Screen.DrawText(font, Font.CR_WHITE, detailX + 24, statY, String.Format("POWER ROLL                +%d%%", data.VariantPowerPercent[selected]), DTA_ScaleX, 2.10, DTA_ScaleY, 2.10); statY += 34;
		Screen.DrawText(font, Font.CR_WHITE, detailX + 24, statY, String.Format("FIRING SPEED              +%d%%", data.VariantHastePercent[selected]), DTA_ScaleX, 2.10, DTA_ScaleY, 2.10); statY += 34;
		Screen.DrawText(font, Font.CR_WHITE, detailX + 24, statY, String.Format("CRITICAL CHANCE           +%d%%", TuinRPGHandler.WeaponCriticalPercent(data.VariantAffixFlags[selected], data.VariantQuality[selected], data.VariantItemLevel[selected])), DTA_ScaleX, 2.10, DTA_ScaleY, 2.10); statY += 34;
		Screen.DrawText(font, Font.CR_GREEN, detailX + 24, statY, String.Format("DAMAGE LEECH               %d%%", data.VariantLeechPercent[selected]), DTA_ScaleX, 2.10, DTA_ScaleY, 2.10); statY += 34;
		Screen.DrawText(font, Font.CR_RED, detailX + 24, statY, String.Format("EXECUTION DAMAGE          +%d%%", data.VariantExecutionPercent[selected]), DTA_ScaleX, 2.10, DTA_ScaleY, 2.10); statY += 34;
		Screen.DrawText(font, Font.CR_GOLD, detailX + 24, statY, String.Format("KILL XP                   +%d%%", data.VariantProsperityPercent[selected]), DTA_ScaleX, 2.10, DTA_ScaleY, 2.10);
		int buttonY = panelY + panelHeight - 68;
		Screen.Dim(data.VariantEquipped[selected] ? Color(34, 93, 58) : Color(67, 31, 91), 0.94, detailX, buttonY, detailWidth, 38);
		Screen.DrawLineFrame(data.VariantEquipped[selected] ? Color(79, 211, 119) : Color(180, 91, 237), detailX, buttonY, detailWidth, 38, 2);
		Screen.DrawText(font, data.VariantEquipped[selected] ? Font.CR_GREEN : Font.CR_WHITE, detailX + 22, buttonY + 10,
			data.VariantEquipped[selected] ? "ACTIVE VARIANT" : "PRESS ENTER OR CLICK HERE TO EQUIP", DTA_ScaleX, 2.25, DTA_ScaleY, 2.25);
		Screen.DrawText(font, Font.CR_GRAY, panelX + 26, panelY + panelHeight - 27,
			String.Format("WEAPONS %d   UP / DOWN OR CLICK TO INSPECT", count), DTA_ScaleX, 1.95, DTA_ScaleY, 1.95);
		Super.Drawer();
	}
}

class TuinRPGFinaleTravelCommand : OptionMenuItemCommand
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		// Keep the irreversible story transition visually separate from John's
		// ordinary shop and conversation entries.
		int x = drawLabel(indent, y, selected ? Font.CR_YELLOW : Font.CR_GOLD);
		if (mCentered) return x - 16 * CleanXfac_1;
		return indent;
	}
}

class TuinRPGClassChoiceItem : OptionMenuItemCommand
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		string role;
		string bonuses;
		string tradeoff;
		string ability;
		string training;
		string ultimate;
		if (mLabel ~== "HEAVY")
		{
			role = "HEAVY WEAPONS BULWARK";
			bonuses = "175 BASE HP | 25% RESIST | 3X BULLETS | STARTS MINIGUN";
			tradeoff = "-20% MOVE SPEED";
			ability = "V: OVERDRIVE | B: RADIO - 2-3 MARINES FOR 30 SEC";
			training = "+3% RESIST | RADIO DAMAGE REQUIRED -10% PER RANK";
			ultimate = "LAST STAND BELOW 30% HEALTH";
		}
		else if (mLabel ~== "HEALER")
		{
			role = "COMBAT MEDIC";
			bonuses = "HEAL THE TEAM 5 HP EVERY 2 SEC | +25% AMMO";
			tradeoff = "WEAPON DAMAGE REDUCED BY 25%";
			ability = "V: FIELD SUPPLY - TOSS ONE RANDOM HEALING PICKUP";
			training = "+1 HEALTH PER HEALING PULSE PER RANK";
			ultimate = "DOUBLE ALL CLASS HEALING";
		}
		else if (mLabel ~== "EXECUTIONER")
		{
			role = "PRIORITY KILLER";
			bonuses = "+30% WEAPON DAMAGE";
			tradeoff = "-25% MAX HEALTH";
			ability = "V: ARM JUDGMENT | NEXT HIT SENTENCES UP TO 3";
			training = "JUDGMENT CHARGE +10% / +20% / +30%";
			ultimate = "NO APPEALS: STRONGER MARK | 12 SEC | 25% REFUND";
		}
		else if (mLabel ~== "DOOM GUY")
		{
			role = "SLAYER";
			bonuses = "+10% DAMAGE | 10% RESIST | REGEN | QUAD SHOTGUN";
			tradeoff = "NO MAJOR DRAWBACKS";
			ability = "HOLD V TO READY BLOOD PUNCH - RELEASE TO STRIKE";
			training = "BLOOD PUNCH CHARGE +10% / +20% / +30%";
			ultimate = "+45% CHARGE | HEAL 30% DAMAGE, MAX 110 HP";
		}
		else if (mLabel ~== "ROGUE")
		{
			role = "AMBUSHER";
			bonuses = "+5% ROGUE WEAPON CRIT | BLEED + VENOM";
			tradeoff = "-20% MAX HP | +10% DAMAGE TAKEN | -50% MAX AMMO";
			ability = "V: SHADOW VEIL - ATTACK FROM STEALTH TO AMBUSH";
			training = "ROGUE WEAPON +2% CRIT | KNIFE +25% SPEED / +20% REACH";
			ultimate = "AMBUSH: X6 RANGED DAMAGE / X16 KNIFE DAMAGE";
		}
		else
		{
			role = "FIELD ENGINEER";
			bonuses = "DEPLOYABLE 400 HP AUTO-TURRET | 250 TRACER ROUNDS";
			tradeoff = "-15% MAX HP | -10% WEAPON DAMAGE";
			ability = "V: DEPLOY | PRESS V NEAR SENTRY TO PACK IT";
			training = "+10% TURRET DAMAGE AND FABRICATION PER RANK";
			ultimate = "TWIN SENTRIES: OWN AND DEPLOY TWO TURRETS";
		}

		int classIndex = mLabel ~== "HEAVY" ? 0 : mLabel ~== "HEALER" ? 1 :
			mLabel ~== "EXECUTIONER" ? 2 : mLabel ~== "DOOM GUY" ? 3 :
			mLabel ~== "ROGUE" ? 4 : 5;
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1660);
		int panelHeight = min(height - 72, 800);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int rosterWidth = clamp(int(panelWidth * 0.20), 290, 340);
		int rowStep = max(66, (panelHeight - 136) / 6);
		int cardSize = clamp(rowStep - 10, 64, 82);
		int cardX = panelX + 22;
		int cardY = panelY + 70 + classIndex * rowStep;
		int cardWidth = rosterWidth - 34;
		string portraitName = classIndex == 0 ? "graphics/TuinClassHeavy.png" :
			classIndex == 1 ? "graphics/TuinClassMedic.png" :
			classIndex == 2 ? "graphics/TuinClassExecutioner.png" :
			classIndex == 3 ? "graphics/TuinClassDoomGuy.png" :
			classIndex == 4 ? "graphics/TuinClassRogue.png" :
			"graphics/TuinClassEngineer.png";
		TextureID portrait = TexMan.CheckForTexture(portraitName, TexMan.Type_Any);
		Font deltaFont = "TINYBABY";
		Color classColor = classIndex == 0 ? Color(55, 150, 255) :
			classIndex == 1 ? Color(74, 210, 105) : classIndex == 2 ? Color(238, 58, 48) :
			classIndex == 3 ? Color(255, 150, 38) : classIndex == 4 ? Color(184, 94, 255) :
			Color(235, 190, 48);
		int classTextColor = classIndex == 0 ? Font.CR_LIGHTBLUE :
			classIndex == 1 ? Font.CR_GREEN : classIndex == 2 ? Font.CR_RED :
			classIndex == 3 ? Font.CR_ORANGE : classIndex == 4 ? Font.CR_PURPLE : Font.CR_GOLD;
		Screen.Dim(selected ? Color(10, 35, 66) : Color(4, 13, 27), 0.96,
			cardX - 5, cardY - 5, cardWidth, cardSize + 10);
		if (portrait.IsValid())
			Screen.DrawTexture(portrait, false, cardX, cardY,
				DTA_DestWidth, cardSize, DTA_DestHeight, cardSize,
				DTA_Alpha, selected ? 1.0 : 0.52);
		Screen.DrawLineFrame(selected ? classColor : Color(22, 62, 102),
			cardX - 5, cardY - 5, cardWidth, cardSize + 10, selected ? 3 : 1);
		Screen.DrawText(deltaFont, selected ? classTextColor : Font.CR_DARKGRAY,
			cardX + cardSize + 18, cardY + cardSize / 2 - 8, mLabel,
			DTA_ScaleX, 2.65, DTA_ScaleY, 2.65);
		if (!selected) return -1;
		int artSize = clamp(min(panelHeight - 190, int(panelWidth * 0.23)), 260, 390);
		int artX = panelX + rosterWidth + 24;
		int artY = panelY + 76;
		if (portrait.IsValid())
			Screen.DrawTexture(portrait, false, artX, artY,
				DTA_DestWidth, artSize, DTA_DestHeight, artSize);
		Screen.DrawLineFrame(classColor, artX - 3, artY - 3, artSize + 6, artSize + 6, 3);
		int detailX = artX + artSize + 30;
		int detailTop = panelY + 74;
		int groupTop = panelY + 160;
		int groupStep = max(61, (panelHeight - 225) / 5);
		Screen.DrawText(deltaFont, Font.CR_WHITE, detailX, detailTop, mLabel,
			DTA_ScaleX, 3.50, DTA_ScaleY, 3.50);
		Screen.DrawText(deltaFont, classTextColor, detailX, detailTop + 39, role,
			DTA_ScaleX, 2.70, DTA_ScaleY, 2.70);
		Screen.DrawText(deltaFont, classTextColor, detailX, groupTop, "CORE BONUSES",
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, Font.CR_WHITE, detailX, groupTop + 26, bonuses,
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, classTextColor, detailX, groupTop + groupStep, "TRADEOFF",
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, Font.CR_WHITE, detailX, groupTop + groupStep + 26, tradeoff,
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, classTextColor, detailX, groupTop + groupStep * 2, "CLASS ABILITY",
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, Font.CR_WHITE, detailX, groupTop + groupStep * 2 + 26, ability,
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, classTextColor, detailX, groupTop + groupStep * 3, "CLASS TRAINING",
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, Font.CR_WHITE, detailX, groupTop + groupStep * 3 + 26, training,
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, classTextColor, detailX, groupTop + groupStep * 4, "CLASS ULTIMATE",
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(deltaFont, Font.CR_WHITE, detailX, groupTop + groupStep * 4 + 26, ultimate,
			DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		int chooseY = panelY + panelHeight - 69;
		int chooseWidth = panelX + panelWidth - 22 - detailX;
		Screen.Dim(classColor, 0.38, detailX, chooseY, chooseWidth, 35);
		Screen.DrawLineFrame(classColor, detailX, chooseY, chooseWidth, 35, 2);
		Screen.DrawText(deltaFont, Font.CR_WHITE, detailX + 16, chooseY + 9,
			"PRESS ENTER OR CLICK TO CHOOSE " .. mLabel,
			DTA_ScaleX, 2.50, DTA_ScaleY, 2.50);
		// This menu draws its own full-card selection state. Returning a negative
		// indent suppresses UZDoom's stock option arrow at the hidden menu row.
		return -1;
	}
}

class TuinRPGClassChoiceMenu : OptionMenu
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			let item = mDesc.mItems[i];
			string command;
			if (item.mLabel ~== "HEAVY") command = "netevent tuin_choose_class 1";
			else if (item.mLabel ~== "HEALER") command = "netevent tuin_choose_class 2";
			else if (item.mLabel ~== "EXECUTIONER") command = "netevent tuin_choose_class 3";
			else if (item.mLabel ~== "DOOM GUY") command = "netevent tuin_choose_class 4";
			else if (item.mLabel ~== "ROGUE") command = "netevent tuin_choose_class 5";
			else if (item.mLabel ~== "ENGINEER") command = "netevent tuin_choose_class 6";
			else continue;
			mDesc.mItems[i] = new ('TuinRPGClassChoiceItem').Init(item.mLabel, command);
		}
		mDesc.mSelectedItem = 0;
		mDesc.CalcIndent();
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Left) return Super.MenuEvent(MKEY_Up, fromcontroller);
		if (mkey == MKEY_Right) return Super.MenuEvent(MKEY_Down, fromcontroller);
		if (mkey == MKEY_Back)
		{
			let data = consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo ?
				TuinRPGHandler.GetPlayerData(players[consoleplayer].mo) : null;
			if (!data || data.PlayerClass == 0) return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1660);
		int panelHeight = min(height - 72, 800);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int rosterWidth = clamp(int(panelWidth * 0.20), 290, 340);
		int rowStep = max(66, (panelHeight - 136) / 6);
		int cardSize = clamp(rowStep - 10, 64, 82);
		int cardX = panelX + 17;
		int cardWidth = rosterWidth - 34;

		for (int i = 0; i < 6; i++)
		{
			int cardY = panelY + 65 + i * rowStep;
			if (x >= cardX && x < cardX + cardWidth &&
				y >= cardY && y < cardY + cardSize + 10)
			{
				if (mDesc.mSelectedItem != i)
				{
					mDesc.mSelectedItem = i;
					MenuSound("menu/cursor");
				}
				if (type == MOUSE_Release) return MenuEvent(MKEY_Enter, true);
				return true;
			}
		}
		return true;
	}

	override void Drawer()
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1660);
		int panelHeight = min(height - 72, 800);
		int panelX = (width - panelWidth) / 2;
		int rosterWidth = clamp(int(panelWidth * 0.20), 290, 340);
		int panelY = (height - panelHeight) / 2;
		Screen.Dim(Color(3, 13, 31), 0.97, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(1, 5, 13), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(Color(36, 128, 210), panelX + 7, panelY + 7,
			panelWidth - 14, panelHeight - 14, 2);
		Screen.Dim(Color(36, 128, 210), 0.72, panelX + rosterWidth, panelY + 58, 2, panelHeight - 78);
		Font deltaFont = "TINYBABY";
		Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 22, panelY + 24, "SELECT A CLASS",
			DTA_ScaleX, 2.85, DTA_ScaleY, 2.85);
		Screen.DrawText(deltaFont, Font.CR_LIGHTBLUE, panelX + rosterWidth + 34, panelY + 24,
			"FREE STARTING CHOICE - YOUR CLASS IS PERMANENT",
			DTA_ScaleX, 2.65, DTA_ScaleY, 2.65);
		Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 22, panelY + panelHeight - 27,
			"KEYS OR MOUSE: BROWSE",
			DTA_ScaleX, 2.40, DTA_ScaleY, 2.40);
		Super.Drawer();
	}
}

class TuinRPGPerkHubItem : OptionMenuItemSubmenu
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		int itemIndex = mLabel ~== "GENERAL PERKS" ? 0 : mLabel ~== "CLASS TRAINING" ? 1 :
			mLabel ~== "CLASS ULTIMATE" ? 2 : 3;
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.30), 330, 430);
		int cardX = panelX + leftWidth + 34;
		int cardWidth = panelWidth - leftWidth - 58;
		int cardGap = 12;
		int cardHeight = clamp((panelHeight - 175 - cardGap * 3) / 4, 105, 145);
		int cardY = panelY + 88 + itemIndex * (cardHeight + cardGap);
		Font deltaFont = "TINYBABY";
		Color accent = itemIndex == 0 ? Color(45, 151, 236) :
			itemIndex == 1 ? Color(80, 207, 132) : itemIndex == 2 ? Color(229, 169, 43) :
			Color(174, 92, 235);
		int accentText = itemIndex == 0 ? Font.CR_LIGHTBLUE :
			itemIndex == 1 ? Font.CR_GREEN : itemIndex == 2 ? Font.CR_GOLD : Font.CR_PURPLE;
		string description = itemIndex == 0 ?
			"UNIVERSAL SURVIVAL, DAMAGE, CRITICAL, LEECH AND AMMO UPGRADES" :
			itemIndex == 1 ? "THREE RANKS OF SPECIALIZED TRAINING FOR YOUR CHOSEN CLASS" :
			itemIndex == 2 ? "YOUR FINAL LEVEL-20 CLASS POWER" :
			"JOHN EXPLAINS CLASSES, PROGRESSION, LOOT, ENEMIES AND MULTIPLAYER";
		string progress = "OPEN CATEGORY";
		if (itemIndex == 3) progress = "OPEN FIELD MANUAL";
		if (consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo)
		{
			let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
			if (data)
			{
				if (itemIndex == 1)
					progress = String.Format("TRAINING RANK %d / 3", data.PerkClassMastery);
				else if (itemIndex == 2)
					progress = data.PerkCapstone ? "UNLOCKED" :
						(data.PlayerLevel < 20 ? "LOCKED - REQUIRES LEVEL 20" :
						data.PerkClassMastery < 2 ? "LOCKED - REQUIRES TRAINING RANK 2" : "READY TO UNLOCK");
			}
		}

		Screen.Dim(selected ? Color(10, 42, 76) : Color(5, 23, 43), 0.97,
			cardX, cardY, cardWidth, cardHeight);
		Screen.Dim(accent, selected ? 0.48 : 0.22, cardX, cardY, 9, cardHeight);
		Screen.DrawLineFrame(selected ? accent : Color(26, 69, 108),
			cardX, cardY, cardWidth, cardHeight, selected ? 3 : 1);
		Screen.DrawText(deltaFont, selected ? accentText : Font.CR_WHITE,
			cardX + 28, cardY + 23, mLabel, DTA_ScaleX, 3.15, DTA_ScaleY, 3.15);
		Screen.DrawText(deltaFont, Font.CR_WHITE, cardX + 28, cardY + 64, description,
			DTA_ScaleX, 2.15, DTA_ScaleY, 2.15);
		Screen.DrawText(deltaFont, selected ? accentText : Font.CR_GRAY,
			cardX + 28, cardY + cardHeight - 31, progress,
			DTA_ScaleX, 2.25, DTA_ScaleY, 2.25);
		if (selected)
			Screen.DrawText(deltaFont, Font.CR_WHITE, cardX + cardWidth - 178,
				cardY + cardHeight - 31, "ENTER OR CLICK",
				DTA_ScaleX, 2.25, DTA_ScaleY, 2.25);
		return -1;
	}
}

class TuinRPGPerkHubMenu : OptionMenu
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			let item = mDesc.mItems[i];
			Name destination = item.mLabel ~== "GENERAL PERKS" ? 'TuinRPGGeneralPerks' :
				item.mLabel ~== "CLASS TRAINING" ? 'TuinRPGClassTraining' :
				item.mLabel ~== "CLASS ULTIMATE" ? 'TuinRPGClassCapstone' : 'TuinRPGHelp';
			mDesc.mItems[i] = new ('TuinRPGPerkHubItem').Init(item.mLabel, destination);
		}
		mDesc.mSelectedItem = 0;
		mDesc.CalcIndent();
	}

	override bool MouseEvent(int type, int x, int y)
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.30), 330, 430);
		int cardX = panelX + leftWidth + 34;
		int cardWidth = panelWidth - leftWidth - 58;
		int cardGap = 12;
		int cardHeight = clamp((panelHeight - 175 - cardGap * 3) / 4, 105, 145);
		for (int i = 0; i < 4; i++)
		{
			int cardY = panelY + 88 + i * (cardHeight + cardGap);
			if (x >= cardX && x < cardX + cardWidth && y >= cardY && y < cardY + cardHeight)
			{
				if (mDesc.mSelectedItem != i)
				{
					mDesc.mSelectedItem = i;
					MenuSound("menu/cursor");
				}
				if (type == MOUSE_Release) return MenuEvent(MKEY_Enter, true);
				return true;
			}
		}
		return true;
	}

	override void Drawer()
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.30), 330, 430);
		Font deltaFont = "TINYBABY";
		Screen.Dim(Color(3, 13, 31), 0.97, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(1, 5, 13), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(Color(36, 128, 210), panelX + 7, panelY + 7,
			panelWidth - 14, panelHeight - 14, 2);
		Screen.Dim(Color(5, 25, 49), 0.94, panelX + 18, panelY + 18,
			leftWidth - 32, panelHeight - 36);
		Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 28, panelY + 25,
			"CLASS AND PERKS", DTA_ScaleX, 3.25, DTA_ScaleY, 3.25);
		Screen.DrawText(deltaFont, Font.CR_LIGHTBLUE, panelX + leftWidth + 34, panelY + 30,
			"CHOOSE AN UPGRADE PATH", DTA_ScaleX, 2.65, DTA_ScaleY, 2.65);

		if (consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo)
		{
			let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
			if (data)
			{
				int classIndex = clamp(data.PlayerClass - 1, 0, 5);
				string portraitName = classIndex == 0 ? "graphics/TuinClassHeavy.png" :
					classIndex == 1 ? "graphics/TuinClassMedic.png" :
					classIndex == 2 ? "graphics/TuinClassExecutioner.png" :
					classIndex == 3 ? "graphics/TuinClassDoomGuy.png" :
					classIndex == 4 ? "graphics/TuinClassRogue.png" : "graphics/TuinClassEngineer.png";
				TextureID portrait = TexMan.CheckForTexture(portraitName, TexMan.Type_Any);
				int artSize = min(leftWidth - 72, panelHeight - 310);
				int artX = panelX + (leftWidth - artSize) / 2;
				int artY = panelY + 88;
				if (portrait.IsValid())
					Screen.DrawTexture(portrait, false, artX, artY,
						DTA_DestWidth, artSize, DTA_DestHeight, artSize);
				string className = TuinRPGHandler.PlayerClassName(data.PlayerClass);
				int infoY = artY + artSize + 30;
				Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 38, infoY, className,
					DTA_ScaleX, 3.0, DTA_ScaleY, 3.0);
				Screen.DrawText(deltaFont, Font.CR_LIGHTBLUE, panelX + 38, infoY + 48,
					String.Format("LEVEL %d", data.PlayerLevel), DTA_ScaleX, 2.35, DTA_ScaleY, 2.35);
				Screen.DrawText(deltaFont, Font.CR_GOLD, panelX + 38, infoY + 80,
					String.Format("PERK POINTS: %d", data.UnspentSkillPoints),
					DTA_ScaleX, 2.35, DTA_ScaleY, 2.35);
				Screen.DrawText(deltaFont, Font.CR_GREEN, panelX + 38, infoY + 112,
					String.Format("TRAINING: %d / 3", data.PerkClassMastery),
					DTA_ScaleX, 2.35, DTA_ScaleY, 2.35);
				Screen.DrawText(deltaFont, data.PerkCapstone ? Font.CR_GOLD : Font.CR_GRAY,
					panelX + 38, infoY + 144, data.PerkCapstone ? "ULTIMATE: UNLOCKED" : "ULTIMATE: LOCKED",
					DTA_ScaleX, 2.35, DTA_ScaleY, 2.35);
			}
		}
		Screen.DrawText(deltaFont, Font.CR_GRAY, panelX + 30, panelY + panelHeight - 27,
			"23 PERK POINTS BY LEVEL 30 - RANKED PERKS HAVE 3 RANKS",
			DTA_ScaleX, 2.10, DTA_ScaleY, 2.10);
		Super.Drawer();
	}
}

class TuinRPGHelpTopicItem : OptionMenuItemCommand
{
	override bool Activate() { return true; }

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		int topic = mLabel ~== "OVERVIEW" ? 0 : mLabel ~== "PROGRESSION" ? 1 :
			mLabel ~== "CLASSES AND PERKS" ? 2 : mLabel ~== "LOOT AND ENEMIES" ? 3 : 4;
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.25), 330, 390);
		int tabX = panelX + 22;
		int tabY = panelY + 294 + topic * 58;
		int tabWidth = leftWidth - 44;
		Color accent = topic == 0 ? Color(220, 65, 52) : topic == 1 ? Color(55, 153, 238) :
			topic == 2 ? Color(82, 207, 124) : topic == 3 ? Color(233, 179, 45) : Color(178, 94, 237);
		int textColor = topic == 0 ? Font.CR_RED : topic == 1 ? Font.CR_LIGHTBLUE :
			topic == 2 ? Font.CR_GREEN : topic == 3 ? Font.CR_GOLD : Font.CR_PURPLE;
		Font deltaFont = "TINYBABY";
		Screen.Dim(selected ? Color(12, 43, 75) : Color(5, 22, 40), 0.98,
			tabX, tabY, tabWidth, 46);
		Screen.Dim(accent, selected ? 0.52 : 0.22, tabX, tabY, 8, 46);
		Screen.DrawLineFrame(selected ? accent : Color(27, 69, 105), tabX, tabY, tabWidth, 46, selected ? 2 : 1);
		Screen.DrawText(deltaFont, selected ? textColor : Font.CR_WHITE,
			tabX + 23, tabY + 13, mLabel, DTA_ScaleX, 2.35, DTA_ScaleY, 2.35);
		return -1;
	}
}

class TuinRPGHelpMenu : OptionMenu
{
	void DrawGuideBlock(Font guideFont, int headingColor, Color accent, int x, int y, int width,
		string heading, string line1, string line2, string line3, string line4)
	{
		Screen.Dim(Color(5, 23, 43), 0.98, x, y, width, 160);
		Screen.Dim(accent, 0.36, x, y, 8, 160);
		Screen.DrawLineFrame(Color(28, 72, 110), x, y, width, 160, 1);
		Screen.DrawText(guideFont, headingColor, x + 24, y + 18, heading,
			DTA_ScaleX, 2.55, DTA_ScaleY, 2.55);
		Screen.DrawText(guideFont, Font.CR_WHITE, x + 24, y + 54, line1, DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Screen.DrawText(guideFont, Font.CR_WHITE, x + 24, y + 80, line2, DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Screen.DrawText(guideFont, Font.CR_WHITE, x + 24, y + 106, line3, DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Screen.DrawText(guideFont, headingColor, x + 24, y + 132, line4, DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
	}

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		for (int i = 0; i < mDesc.mItems.Size(); i++)
			mDesc.mItems[i] = new ('TuinRPGHelpTopicItem').Init(mDesc.mItems[i].mLabel, "");
		mDesc.mSelectedItem = 0;
		mDesc.CalcIndent();
	}

	override bool MouseEvent(int type, int x, int y)
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.25), 330, 390);
		for (int i = 0; i < 5; i++)
		{
			int tabX = panelX + 22;
			int tabY = panelY + 294 + i * 58;
			if (x >= tabX && x < tabX + leftWidth - 44 && y >= tabY && y < tabY + 46)
			{
				if (mDesc.mSelectedItem != i)
				{
					mDesc.mSelectedItem = i;
					MenuSound("menu/cursor");
				}
				return true;
			}
		}
		return true;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Left) return Super.MenuEvent(MKEY_Up, fromcontroller);
		if (mkey == MKEY_Right) return Super.MenuEvent(MKEY_Down, fromcontroller);
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override void Drawer()
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.25), 330, 390);
		int contentX = panelX + leftWidth + 24;
		int contentWidth = panelWidth - leftWidth - 47;
		int topic = clamp(mDesc.mSelectedItem, 0, 4);
		Font deltaFont = "TINYBABY";
		Screen.Dim(Color(3, 13, 31), 0.98, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(1, 5, 13), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(Color(36, 128, 210), panelX + 7, panelY + 7, panelWidth - 14, panelHeight - 14, 2);
		Screen.Dim(Color(7, 28, 51), 0.96, panelX + 18, panelY + 18, leftWidth - 31, panelHeight - 36);
		Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 28, panelY + 23,
			"JOHN'S FIELD MANUAL", DTA_ScaleX, 2.75, DTA_ScaleY, 2.75);
		TextureID john = TexMan.CheckForTexture("graphics/TuinJohnPortrait.png", TexMan.Type_Any);
		int portraitSize = min(leftWidth - 100, 190);
		int portraitX = panelX + (leftWidth - portraitSize) / 2;
		int portraitY = panelY + 72;
		if (john.IsValid()) Screen.DrawTexture(john, false, portraitX, portraitY,
			DTA_DestWidth, portraitSize, DTA_DestHeight, portraitSize);
		Screen.DrawLineFrame(Color(207, 58, 47), portraitX - 3, portraitY - 3, portraitSize + 6, portraitSize + 6, 3);
		Screen.DrawText(deltaFont, Font.CR_RED, panelX + 30, panelY + 270,
			"CHOOSE A SECTION", DTA_ScaleX, 2.20, DTA_ScaleY, 2.20);

		string pageTitle = topic == 0 ? "WELCOME TO TUIN RPG" : topic == 1 ? "PROGRESSION GUIDE" :
			topic == 2 ? "CLASSES AND PERKS" : topic == 3 ? "LOOT AND ENEMIES" : "MULTIPLAYER GUIDE";
		int pageColor = topic == 0 ? Font.CR_RED : topic == 1 ? Font.CR_LIGHTBLUE :
			topic == 2 ? Font.CR_GREEN : topic == 3 ? Font.CR_GOLD : Font.CR_PURPLE;
		Screen.DrawText(deltaFont, pageColor, contentX, panelY + 27, pageTitle,
			DTA_ScaleX, 3.05, DTA_ScaleY, 3.05);
		Screen.DrawText(deltaFont, Font.CR_WHITE, contentX, panelY + 63,
			"JOHN SAYS:", DTA_ScaleX, 2.10, DTA_ScaleY, 2.10);

		if (topic == 0)
		{
			DrawGuideBlock(deltaFont, Font.CR_RED, Color(211, 61, 49), contentX, panelY + 94, contentWidth,
				"THE CORE LOOP", "KILL DEMONS TO EARN XP, LEVELS, STATS AND REWARDS.",
				"BUILD A PERMANENT CLASS AROUND ITS ABILITY AND WEAPONS.",
				"HUNT UPGRADED MONSTERS FOR STRONGER RANDOMIZED GEAR.", "GROW STRONGER - THEN FIGHT STRONGER HELLSPAWN.");
			DrawGuideBlock(deltaFont, Font.CR_LIGHTBLUE, Color(55, 153, 238), contentX, panelY + 270, contentWidth,
				"YOUR RUN", "THE RPG PROGRESSION FOLLOWS YOU THROUGH THE CAMPAIGN.",
				"THE MINIMAP TRACKS THE LEVEL, TARGETS AND DISCOVERED LOOT.",
				"JOHN'S END-LEVEL SHOP SELLS RECOVERY, AMMO AND WEAPONS.", "OPEN CLASS AND PERKS TO PLAN YOUR BUILD.");
			DrawGuideBlock(deltaFont, Font.CR_GOLD, Color(233, 179, 45), contentX, panelY + 446, contentWidth,
				"QUICK CONTROLS", "V: USE OR READY YOUR MAIN CLASS ABILITY.",
				"N: TOGGLE THE MINIMAP. USE: INSPECT AND EQUIP WEAPON DROPS.",
				"HEAVY ALSO USES B TO CALL RADIO MARINES WHEN CHARGED.", "ESC OR BACK RETURNS TO THE PREVIOUS PAGE.");
		}
		else if (topic == 1)
		{
			DrawGuideBlock(deltaFont, Font.CR_LIGHTBLUE, Color(55, 153, 238), contentX, panelY + 94, contentWidth,
				"LEVELS AND STATS", "MONSTER KILLS AWARD XP; HARDER TARGETS ARE WORTH MORE.",
				"LEVELS GRANT STAT POINTS FOR STRENGTH, AGILITY AND ENDURANCE.",
				"STRENGTH ALSO GRANTS HEAVY +5 MAX HEALTH PER POINT.", "YOUR HUD SHOWS LEVEL, XP, STATS AND AVAILABLE POINTS.");
			DrawGuideBlock(deltaFont, Font.CR_GREEN, Color(82, 207, 124), contentX, panelY + 270, contentWidth,
				"PERK MILESTONES", "MILESTONES AWARD 23 TOTAL PERK POINTS BY LEVEL 30.",
				"GENERAL AND CLASS TRAINING PERKS EACH HAVE THREE RANKS.",
				"CLASS ULTIMATES COST ONE POINT AND REQUIRE LEVEL 20.", "ULTIMATES ALSO REQUIRE CLASS TRAINING RANK 2.");
			DrawGuideBlock(deltaFont, Font.CR_PURPLE, Color(178, 94, 237), contentX, panelY + 446, contentWidth,
				"LATE-START CATCH-UP", "STARTING ON A LATER MAP RAISES YOU TO A SUITABLE LEVEL.",
				"YOU RECEIVE THE CORRESPONDING STAT AND PERK PROGRESSION.",
				"THREE RARE-OR-BETTER WEAPON CHOICES SPAWN NEARBY.", "THIS ALSO WORKS WHEN JOINING A CAMPAIGN IN PROGRESS.");
		}
		else if (topic == 2)
		{
			DrawGuideBlock(deltaFont, Font.CR_GREEN, Color(82, 207, 124), contentX, panelY + 94, contentWidth,
				"PERMANENT CLASS", "CHOOSE HEAVY, HEALER, EXECUTIONER, DOOM GUY, ROGUE OR ENGINEER.",
				"EACH CLASS HAS CORE BONUSES, A TRADEOFF AND AN ACTIVE ABILITY.",
				"THE CHOICE LASTS FOR THAT CHARACTER'S RPG PROGRESSION.", "CLASS WEAPONS REWARD PLAYING TO YOUR ROLE.");
			DrawGuideBlock(deltaFont, Font.CR_LIGHTBLUE, Color(55, 153, 238), contentX, panelY + 270, contentWidth,
				"TRAINING", "CLASS TRAINING HAS THREE RANKS AND COSTS ONE POINT EACH.",
				"IT IMPROVES YOUR CHOSEN CLASS'S DEFINING MECHANIC.",
				"OTHER CLASSES' TRAINING BONUSES ARE NOT APPLIED TO YOU.", "RANK 2 OPENS THE ULTIMATE ONCE YOU REACH LEVEL 20.");
			DrawGuideBlock(deltaFont, Font.CR_GOLD, Color(233, 179, 45), contentX, panelY + 446, contentWidth,
				"ROLE SNAPSHOT", "HEAVY DEFENDS; HEALER SUPPORTS; EXECUTIONER HUNTS PRIORITIES.",
				"DOOM GUY BRAWLS; ROGUE AMBUSHES; ENGINEER CONTROLS SPACE.",
				"V ACTIVATES EACH ROLE'S MAIN ABILITY OR READIES ITS ATTACK.", "COMBINE ROLES IN COOP FOR STRONGER TEAMS.");
		}
		else if (topic == 3)
		{
			DrawGuideBlock(deltaFont, Font.CR_GOLD, Color(233, 179, 45), contentX, panelY + 94, contentWidth,
				"WEAPON QUALITY", "DROPS PROGRESS THROUGH UNCOMMON, RARE, EPIC AND LEGENDARY.",
				"MYTHIC AND GODLY WEAPONS ARE THE HIGHEST STANDARD QUALITIES.",
				"QUALITY, ITEM LEVEL AND AFFIXES ALL SHAPE A WEAPON'S POWER.", "MOVE CLOSE TO A DROP TO INSPECT AND EQUIP IT.");
			DrawGuideBlock(deltaFont, Font.CR_PURPLE, Color(178, 94, 237), contentX, panelY + 270, contentWidth,
				"AFFIXES", "WEAPONS CAN ROLL HASTE, POWER, LEECH, EXECUTION AND PROSPERITY.",
				"HIGHER QUALITY ADDS MORE AND STRONGER RANDOM AFFIXES.",
				"REPLACING AN EQUIPPED VARIANT DROPS THE OLD ONE NEARBY.", "YOUR ARSENAL MENU TRACKS COLLECTED WEAPON VARIANTS.");
			DrawGuideBlock(deltaFont, Font.CR_ORANGE, Color(244, 112, 35), contentX, panelY + 446, contentWidth,
				"UPGRADED MONSTERS", "RARE-AND-HIGHER ENEMIES GAIN HEALTH, DAMAGE AND TRAITS.",
				"HELL KNIGHT-OR-STRONGER MONSTERS RECEIVE HIGH-LEVEL PRIORITY.",
				"VERY HIGH-HP TARGETS HAVE IMPROVED MYTHIC OR GODLY REWARDS.", "A VOLATILE ICON WARNS THAT DEATH WILL CAUSE AN EXPLOSION.");
		}
		else
		{
			DrawGuideBlock(deltaFont, Font.CR_PURPLE, Color(178, 94, 237), contentX, panelY + 94, contentWidth,
				"PER-PLAYER PROGRESSION", "EACH PLAYER OWNS THEIR CLASS, XP, STATS, PERKS AND LIVES.",
				"CLASS ABILITIES, CHARGES AND PERSONAL REWARDS TRACK SEPARATELY.",
				"LATE JOINERS RECEIVE MAP-APPROPRIATE CATCH-UP PROGRESSION.", "EVERY PLAYER CAN BUILD A DIFFERENT ROLE.");
			DrawGuideBlock(deltaFont, Font.CR_GREEN, Color(82, 207, 124), contentX, panelY + 270, contentWidth,
				"COOP ROLES", "HEALER SUSTAINS THE TEAM WHILE HEAVY ABSORBS PRESSURE.",
				"EXECUTIONER AND ROGUE DELETE PRIORITY TARGETS.",
				"ENGINEER CONTROLS LANES; DOOM GUY PROVIDES RELIABLE DAMAGE.", "MIXING ROLES IS STRONGER THAN DUPLICATING ONE JOB.");
			DrawGuideBlock(deltaFont, Font.CR_LIGHTBLUE, Color(55, 153, 238), contentX, panelY + 446, contentWidth,
				"ALLIES AND REWARDS", "HEAVY'S RADIO CALLS 2-3 INVULNERABLE MARINES FOR 30 SECONDS.",
				"THE RADIO COOLDOWN RECHARGES ONLY WHEN THE HEAVY DEALS DAMAGE.",
				"CLASS-MATCHED REWARDS USE THE RECEIVING PLAYER'S OWN CLASS.", "COMMUNICATE BEFORE CLAIMING SHARED MAP PICKUPS.");
		}
		Screen.DrawText(deltaFont, Font.CR_GRAY, contentX, panelY + panelHeight - 25,
			"UP / DOWN, LEFT / RIGHT OR CLICK: CHANGE SECTION     ESC: RETURN",
			DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Super.Drawer();
	}
}

class TuinRPGGeneralPerkItem : OptionMenuItemCommand
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		int itemIndex = mLabel.IndexOf("VITAL CORE") == 0 ? 0 :
			mLabel.IndexOf("IRON SKIN") == 0 ? 1 :
			mLabel.IndexOf("KILLER INSTINCT") == 0 ? 2 :
			mLabel.IndexOf("BLOOD DRINKER") == 0 ? 3 :
			mLabel.IndexOf("SCAVENGER") == 0 ? 4 : 5;
		string perkName = itemIndex == 0 ? "VITAL CORE" : itemIndex == 1 ? "IRON SKIN" :
			itemIndex == 2 ? "KILLER INSTINCT" : itemIndex == 3 ? "BLOOD DRINKER" :
			itemIndex == 4 ? "SCAVENGER" : "GIANT SLAYER";
		string description = itemIndex == 0 ? "+10 MAXIMUM HEALTH PER RANK" :
			itemIndex == 1 ? "3% LESS DAMAGE TAKEN PER RANK" :
			itemIndex == 2 ? "+2% CRITICAL CHANCE PER RANK" :
			itemIndex == 3 ? "LEECH 1% OF DAMAGE PER RANK" :
			itemIndex == 4 ? "+10% AMMUNITION GAINED PER RANK" :
			"+0.5% TARGET MAX HP DAMAGE PER RANK VS 2500+ HP";
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int gap = 16;
		int cardWidth = (panelWidth - 74 - gap) / 2;
		int cardHeight = clamp((panelHeight - 176 - gap * 2) / 3, 125, 176);
		int column = itemIndex % 2;
		int row = itemIndex / 2;
		int cardX = panelX + 29 + column * (cardWidth + gap);
		int cardY = panelY + 91 + row * (cardHeight + gap);
		Color accent = itemIndex == 0 ? Color(73, 211, 106) :
			itemIndex == 1 ? Color(58, 153, 241) : itemIndex == 2 ? Color(239, 71, 58) :
			itemIndex == 3 ? Color(184, 94, 255) : itemIndex == 4 ? Color(232, 184, 48) :
			Color(255, 123, 35);
		int accentText = itemIndex == 0 ? Font.CR_GREEN : itemIndex == 1 ? Font.CR_LIGHTBLUE :
			itemIndex == 2 ? Font.CR_RED : itemIndex == 3 ? Font.CR_PURPLE :
			itemIndex == 4 ? Font.CR_GOLD : Font.CR_ORANGE;
		int rank = 0;
		int playerLevel = 1;
		int points = 0;
		if (consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo)
		{
			let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
			if (data)
			{
				playerLevel = data.PlayerLevel;
				points = data.UnspentSkillPoints;
				rank = itemIndex == 0 ? data.PerkVitalCore : itemIndex == 1 ? data.PerkIronSkin :
					itemIndex == 2 ? data.PerkKillerInstinct : itemIndex == 3 ? data.PerkBloodDrinker :
					itemIndex == 4 ? data.PerkScavenger : data.PerkGiantSlayer;
			}
		}
		bool levelLocked = itemIndex == 5 && playerLevel < 20;
		bool maxed = rank >= 3;
		Font deltaFont = "TINYBABY";
		Screen.Dim(selected ? Color(11, 43, 76) : Color(5, 23, 43), 0.97,
			cardX, cardY, cardWidth, cardHeight);
		Screen.Dim(accent, selected ? 0.50 : 0.22, cardX, cardY, 9, cardHeight);
		Screen.DrawLineFrame(selected ? accent : Color(25, 67, 104),
			cardX, cardY, cardWidth, cardHeight, selected ? 3 : 1);
		Screen.DrawText(deltaFont, selected ? accentText : Font.CR_WHITE,
			cardX + 27, cardY + 22, perkName, DTA_ScaleX, 3.0, DTA_ScaleY, 3.0);
		Screen.DrawText(deltaFont, levelLocked ? Font.CR_DARKGRAY : Font.CR_WHITE,
			cardX + 27, cardY + 62, description, DTA_ScaleX, 2.15, DTA_ScaleY, 2.15);
		for (int rankSlot = 0; rankSlot < 3; rankSlot++)
		{
			int slotX = cardX + 27 + rankSlot * 34;
			Screen.Dim(rankSlot < rank ? accent : Color(24, 40, 57), 0.96,
				slotX, cardY + cardHeight - 42, 24, 17);
			Screen.DrawLineFrame(rankSlot < rank ? accent : Color(73, 91, 108),
				slotX, cardY + cardHeight - 42, 24, 17, 1);
		}
		string state = levelLocked ? "LOCKED - LEVEL 20" : maxed ? "MAX RANK" :
			points <= 0 ? String.Format("RANK %d / 3 - NO POINTS", rank) :
			String.Format("RANK %d / 3 - BUY FOR 1 POINT", rank);
		Screen.DrawText(deltaFont, levelLocked || points <= 0 ? Font.CR_GRAY : accentText,
			cardX + 142, cardY + cardHeight - 42, state,
			DTA_ScaleX, 2.15, DTA_ScaleY, 2.15);
		return -1;
	}
}

class TuinRPGGeneralPerkMenu : OptionMenu
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			let item = mDesc.mItems[i];
			string command = item.mLabel.IndexOf("VITAL CORE") == 0 ? "netevent tuin_buy_perk 1" :
				item.mLabel.IndexOf("IRON SKIN") == 0 ? "netevent tuin_buy_perk 4" :
				item.mLabel.IndexOf("KILLER INSTINCT") == 0 ? "netevent tuin_buy_perk 3" :
				item.mLabel.IndexOf("BLOOD DRINKER") == 0 ? "netevent tuin_buy_perk 5" :
				item.mLabel.IndexOf("SCAVENGER") == 0 ? "netevent tuin_buy_perk 2" :
				"netevent tuin_buy_perk 8";
			mDesc.mItems[i] = new ('TuinRPGGeneralPerkItem').Init(item.mLabel, command);
		}
		mDesc.mSelectedItem = 0;
		mDesc.CalcIndent();
	}

	override bool MouseEvent(int type, int x, int y)
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int gap = 16;
		int cardWidth = (panelWidth - 74 - gap) / 2;
		int cardHeight = clamp((panelHeight - 176 - gap * 2) / 3, 125, 176);
		for (int i = 0; i < 6; i++)
		{
			int cardX = panelX + 29 + (i % 2) * (cardWidth + gap);
			int cardY = panelY + 91 + (i / 2) * (cardHeight + gap);
			if (x >= cardX && x < cardX + cardWidth && y >= cardY && y < cardY + cardHeight)
			{
				if (mDesc.mSelectedItem != i)
				{
					mDesc.mSelectedItem = i;
					MenuSound("menu/cursor");
				}
				if (type == MOUSE_Release) return MenuEvent(MKEY_Enter, true);
				return true;
			}
		}
		return true;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		int oldSelection = mDesc.mSelectedItem;
		if (mkey == MKEY_Left && (mDesc.mSelectedItem % 2) == 1)
		{
			mDesc.mSelectedItem--;
		}
		else if (mkey == MKEY_Right && (mDesc.mSelectedItem % 2) == 0)
		{
			mDesc.mSelectedItem++;
		}
		else if (mkey == MKEY_Up)
			mDesc.mSelectedItem = mDesc.mSelectedItem >= 2 ? mDesc.mSelectedItem - 2 : mDesc.mSelectedItem + 4;
		else if (mkey == MKEY_Down)
			mDesc.mSelectedItem = mDesc.mSelectedItem <= 3 ? mDesc.mSelectedItem + 2 : mDesc.mSelectedItem - 4;
		else return Super.MenuEvent(mkey, fromcontroller);
		if (mDesc.mSelectedItem != oldSelection) MenuSound("menu/cursor");
		return true;
	}

	override void Drawer()
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		Font deltaFont = "TINYBABY";
		Screen.Dim(Color(3, 13, 31), 0.97, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(1, 5, 13), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(Color(36, 128, 210), panelX + 7, panelY + 7,
			panelWidth - 14, panelHeight - 14, 2);
		Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 29, panelY + 25,
			"GENERAL PERKS", DTA_ScaleX, 3.25, DTA_ScaleY, 3.25);
		Screen.DrawText(deltaFont, Font.CR_LIGHTBLUE, panelX + 330, panelY + 30,
			"1 POINT PER RANK - 3 RANKS MAX", DTA_ScaleX, 2.55, DTA_ScaleY, 2.55);
		if (consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo)
		{
			let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
			if (data)
			{
				Screen.Dim(Color(7, 29, 56), 0.94, panelX + 22, panelY + panelHeight - 48,
					panelWidth - 44, 28);
				Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 36, panelY + panelHeight - 40,
					String.Format("%s - LEVEL %d", TuinRPGHandler.PlayerClassName(data.PlayerClass), data.PlayerLevel),
					DTA_ScaleX, 2.25, DTA_ScaleY, 2.25);
				Screen.DrawText(deltaFont, data.UnspentSkillPoints > 0 ? Font.CR_GOLD : Font.CR_GRAY,
					panelX + panelWidth - 285, panelY + panelHeight - 40,
					String.Format("AVAILABLE PERK POINTS: %d", data.UnspentSkillPoints),
					DTA_ScaleX, 2.25, DTA_ScaleY, 2.25);
			}
		}
		Super.Drawer();
	}
}

class TuinRPGClassUpgradeItem : OptionMenuItemCommand
{
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		return -1;
	}
}

class TuinRPGClassUpgradeMenuBase : OptionMenu
{
	int UpgradeMode;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		string command = UpgradeMode == 0 ? "netevent tuin_buy_perk 6" : "netevent tuin_buy_perk 7";
		for (int i = 0; i < mDesc.mItems.Size(); i++)
			mDesc.mItems[i] = new ('TuinRPGClassUpgradeItem').Init(mDesc.mItems[i].mLabel, command);
		mDesc.mSelectedItem = 0;
		mDesc.CalcIndent();
	}

	override bool MouseEvent(int type, int x, int y)
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.30), 350, 430);
		int buttonX = panelX + leftWidth + 34;
		int buttonY = panelY + panelHeight - 92;
		int buttonWidth = panelWidth - leftWidth - 58;
		if (x >= buttonX && x < buttonX + buttonWidth && y >= buttonY && y < buttonY + 48)
		{
			if (type == MOUSE_Release) return MenuEvent(MKEY_Enter, true);
			return true;
		}
		return true;
	}

	void DrawRequirement(Font font, int x, int y, int width, string title, string value, bool met)
	{
		Color accent = met ? Color(69, 207, 116) : Color(199, 61, 55);
		Screen.Dim(met ? Color(7, 39, 36) : Color(42, 15, 24), 0.97, x, y, width, 82);
		Screen.Dim(accent, 0.48, x, y, 7, 82);
		Screen.DrawLineFrame(accent, x, y, width, 82, 1);
		Screen.DrawText(font, Font.CR_GRAY, x + 20, y + 15, title,
			DTA_ScaleX, 2.0, DTA_ScaleY, 2.0);
		Screen.DrawText(font, met ? Font.CR_GREEN : Font.CR_RED, x + 20, y + 44, value,
			DTA_ScaleX, 2.35, DTA_ScaleY, 2.35);
	}

	override void Drawer()
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1560);
		int panelHeight = min(height - 72, 780);
		int panelX = (width - panelWidth) / 2;
		int panelY = (height - panelHeight) / 2;
		int leftWidth = clamp(int(panelWidth * 0.30), 350, 430);
		int contentX = panelX + leftWidth + 34;
		int contentWidth = panelWidth - leftWidth - 58;
		Font font = "TINYBABY";
		let data = consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo ?
			TuinRPGHandler.GetPlayerData(players[consoleplayer].mo) : null;
		int playerClass = data ? data.PlayerClass : 0;
		int classIndex = clamp(playerClass - 1, 0, 5);
		int level = data ? data.PlayerLevel : 1;
		int points = data ? data.UnspentSkillPoints : 0;
		int rank = data ? data.PerkClassMastery : 0;
		bool ultimate = data && data.PerkCapstone;
		string className = playerClass > 0 ? TuinRPGHandler.PlayerClassName(playerClass) : "NO CLASS CHOSEN";
		string portraitName = classIndex == 0 ? "graphics/TuinClassHeavy.png" :
			classIndex == 1 ? "graphics/TuinClassMedic.png" :
			classIndex == 2 ? "graphics/TuinClassExecutioner.png" :
			classIndex == 3 ? "graphics/TuinClassDoomGuy.png" :
			classIndex == 4 ? "graphics/TuinClassRogue.png" : "graphics/TuinClassEngineer.png";
		Color accent = classIndex == 0 ? Color(232, 179, 43) : classIndex == 1 ? Color(82, 207, 124) :
			classIndex == 2 ? Color(224, 57, 48) : classIndex == 3 ? Color(54, 205, 68) :
			classIndex == 4 ? Color(175, 55, 238) : Color(32, 183, 229);
		int accentText = classIndex == 0 ? Font.CR_GOLD : classIndex == 1 ? Font.CR_GREEN :
			classIndex == 2 ? Font.CR_RED : classIndex == 3 ? Font.CR_GREEN :
			classIndex == 4 ? Font.CR_PURPLE : Font.CR_CYAN;

		string perkTitle;
		string line1;
		string line2;
		string line3;
		if (UpgradeMode == 0)
		{
			perkTitle = classIndex == 0 ? "BULWARK DRILLS" : classIndex == 1 ? "COMBAT MEDIC" :
				classIndex == 2 ? "SWIFT JUDGMENT" : classIndex == 3 ? "BLOOD RUSH" :
				classIndex == 4 ? "DEADLY PRECISION" : "FIELD FABRICATION";
			line1 = classIndex == 0 ? "+3% DAMAGE RESISTANCE PER RANK" :
				classIndex == 1 ? "+1 HEALTH TO EVERY HEALING PULSE PER RANK" :
				classIndex == 2 ? "+10% JUDGMENT CHARGE RATE PER RANK" :
				classIndex == 3 ? "+10% BLOOD PUNCH CHARGE RATE PER RANK" :
				classIndex == 4 ? "+2% ROGUE WEAPON CRITICAL CHANCE PER RANK" :
				"+10% TURRET DAMAGE PER RANK";
			line2 = classIndex == 0 ? "RADIO RECHARGE NEEDS 10% LESS DAMAGE PER RANK" :
				classIndex == 4 ? "KNIFE GAINS +25% SPEED AND +20% REACH PER RANK" :
				classIndex == 5 ? "FABRICATION BUILDS 10% FASTER PER RANK" :
				"THREE RANKS STRENGTHEN YOUR DEFINING CLASS MECHANIC";
			line3 = "EACH RANK COSTS 1 PERK POINT";
		}
		else
		{
			perkTitle = classIndex == 0 ? "LAST STAND" : classIndex == 1 ? "MIRACLE WORKER" :
				classIndex == 2 ? "NO APPEALS" : classIndex == 3 ? "RIP AND TEAR" :
				classIndex == 4 ? "PERFECT AMBUSH" : "TWIN SENTRIES";
			line1 = classIndex == 0 ? "BELOW 30% HEALTH, TAKE 25% LESS DAMAGE" :
				classIndex == 1 ? "DOUBLE ALL HEALING FROM YOUR CLASS ABILITY" :
				classIndex == 2 ? "STRONGER 12-SECOND MARK WITH A 25% REFUND" :
				classIndex == 3 ? "+45% BLOOD PUNCH CHARGE AND HEAL 30% OF DAMAGE" :
				classIndex == 4 ? "AMBUSH DEALS X6 RANGED OR X16 KNIFE DAMAGE" :
				"OWN AND DEPLOY TWO FULLY INDEPENDENT TURRETS";
			line2 = "THE FINAL POWER FOR YOUR CHOSEN CLASS";
			line3 = "REQUIRES LEVEL 20 AND CLASS TRAINING RANK II";
		}

		Screen.Dim(Color(3, 13, 31), 0.98, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(1, 5, 13), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(accent, panelX + 7, panelY + 7, panelWidth - 14, panelHeight - 14, 2);
		Screen.Dim(Color(5, 25, 49), 0.96, panelX + 18, panelY + 18, leftWidth - 32, panelHeight - 36);
		Screen.Dim(accent, 0.55, panelX + leftWidth, panelY + 18, 2, panelHeight - 36);

		Screen.DrawText(font, Font.CR_WHITE, panelX + 28, panelY + 25,
			UpgradeMode == 0 ? "CLASS TRAINING" : "CLASS ULTIMATE",
			DTA_ScaleX, 3.15, DTA_ScaleY, 3.15);
		TextureID portrait = TexMan.CheckForTexture(portraitName, TexMan.Type_Any);
		int artSize = min(leftWidth - 76, min(360, panelHeight - 300));
		int artX = panelX + (leftWidth - artSize) / 2;
		int artY = panelY + 83;
		if (portrait.IsValid()) Screen.DrawTexture(portrait, false, artX, artY,
			DTA_DestWidth, artSize, DTA_DestHeight, artSize);
		Screen.DrawLineFrame(accent, artX - 3, artY - 3, artSize + 6, artSize + 6, 3);
		Screen.DrawText(font, accentText, panelX + 34, artY + artSize + 26, className,
			DTA_ScaleX, 3.0, DTA_ScaleY, 3.0);
		Screen.DrawText(font, Font.CR_WHITE, panelX + 34, artY + artSize + 66,
			String.Format("LEVEL %d", level), DTA_ScaleX, 2.3, DTA_ScaleY, 2.3);
		Screen.DrawText(font, points > 0 ? Font.CR_GOLD : Font.CR_GRAY, panelX + 34, artY + artSize + 98,
			String.Format("PERK POINTS: %d", points), DTA_ScaleX, 2.3, DTA_ScaleY, 2.3);
		Screen.DrawText(font, rank >= 2 ? Font.CR_GREEN : Font.CR_GRAY, panelX + 34, artY + artSize + 130,
			String.Format("TRAINING RANK: %d / 3", rank), DTA_ScaleX, 2.3, DTA_ScaleY, 2.3);

		Screen.DrawText(font, accentText, contentX, panelY + 27,
			String.Format("%s - %s", className, perkTitle), DTA_ScaleX, 3.25, DTA_ScaleY, 3.25);
		Screen.DrawText(font, Font.CR_GRAY, contentX, panelY + 67,
			UpgradeMode == 0 ? "SPECIALIZED ROLE PROGRESSION" : "FINAL CLASS POWER",
			DTA_ScaleX, 2.2, DTA_ScaleY, 2.2);
		Screen.Dim(Color(5, 23, 43), 0.98, contentX, panelY + 110, contentWidth, 184);
		Screen.Dim(accent, 0.48, contentX, panelY + 110, 9, 184);
		Screen.DrawLineFrame(accent, contentX, panelY + 110, contentWidth, 184, 2);
		Screen.DrawText(font, accentText, contentX + 28, panelY + 132, "WHAT IT DOES",
			DTA_ScaleX, 2.55, DTA_ScaleY, 2.55);
		Screen.DrawText(font, Font.CR_WHITE, contentX + 28, panelY + 178, line1,
			DTA_ScaleX, 2.4, DTA_ScaleY, 2.4);
		Screen.DrawText(font, Font.CR_WHITE, contentX + 28, panelY + 216, line2,
			DTA_ScaleX, 2.25, DTA_ScaleY, 2.25);
		Screen.DrawText(font, Font.CR_GRAY, contentX + 28, panelY + 254, line3,
			DTA_ScaleX, 2.15, DTA_ScaleY, 2.15);

		if (UpgradeMode == 0)
		{
			int gap = 14;
			int rankWidth = (contentWidth - gap * 2) / 3;
			for (int rankSlot = 0; rankSlot < 3; rankSlot++)
			{
				int rx = contentX + rankSlot * (rankWidth + gap);
				bool owned = rank > rankSlot;
				bool next = rank == rankSlot && rank < 3;
				Color rankAccent = owned ? accent : next ? Color(232, 179, 43) : Color(57, 76, 96);
				Screen.Dim(owned ? Color(7, 38, 37) : next ? Color(43, 32, 13) : Color(10, 22, 37), 0.98,
					rx, panelY + 320, rankWidth, 136);
				Screen.DrawLineFrame(rankAccent, rx, panelY + 320, rankWidth, 136, next ? 3 : 1);
				Screen.DrawText(font, owned ? accentText : next ? Font.CR_GOLD : Font.CR_GRAY,
					rx + 22, panelY + 342, String.Format("RANK %d", rankSlot + 1),
					DTA_ScaleX, 2.55, DTA_ScaleY, 2.55);
				Screen.DrawText(font, owned ? Font.CR_GREEN : next ? Font.CR_GOLD : Font.CR_GRAY,
					rx + 22, panelY + 389, owned ? "UNLOCKED" : next ? "NEXT UPGRADE" : "LOCKED",
					DTA_ScaleX, 2.15, DTA_ScaleY, 2.15);
			}
		}
		else
		{
			int gap = 14;
			int reqWidth = (contentWidth - gap * 2) / 3;
			DrawRequirement(font, contentX, panelY + 326, reqWidth, "LEVEL REQUIREMENT",
				String.Format("%d / 20", level), level >= 20);
			DrawRequirement(font, contentX + reqWidth + gap, panelY + 326, reqWidth, "TRAINING REQUIREMENT",
				String.Format("RANK %d / 2", rank), rank >= 2);
			DrawRequirement(font, contentX + (reqWidth + gap) * 2, panelY + 326, reqWidth, "COST",
				points > 0 ? "1 PERK POINT - READY" : "NEED 1 PERK POINT", points > 0);
			Screen.Dim(ultimate ? Color(7, 38, 37) : Color(8, 22, 39), 0.98,
				contentX, panelY + 428, contentWidth, 66);
			Screen.DrawLineFrame(ultimate ? Color(69, 207, 116) : Color(38, 91, 133),
				contentX, panelY + 428, contentWidth, 66, 2);
			Screen.DrawText(font, ultimate ? Font.CR_GREEN : Font.CR_LIGHTBLUE,
				contentX + 24, panelY + 449, ultimate ? "ULTIMATE STATUS: UNLOCKED" : "ULTIMATE STATUS: LOCKED",
				DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		}

		bool ready = playerClass > 0 && points > 0 && (UpgradeMode == 0 ? rank < 3 : level >= 20 && rank >= 2 && !ultimate);
		string actionText = UpgradeMode == 0 ?
			(rank >= 3 ? "MAXIMUM TRAINING REACHED" : points <= 0 ? "NEED 1 PERK POINT" : String.Format("BUY TRAINING RANK %d - 1 PERK POINT", rank + 1)) :
			(ultimate ? "CLASS ULTIMATE UNLOCKED" : level < 20 ? "LOCKED - REQUIRES LEVEL 20" : rank < 2 ? "LOCKED - REQUIRES TRAINING RANK 2" : points <= 0 ? "NEED 1 PERK POINT" : "UNLOCK CLASS ULTIMATE - 1 PERK POINT");
		int buttonY = panelY + panelHeight - 92;
		Screen.Dim(ready ? accent : Color(38, 49, 64), ready ? 0.62 : 0.92,
			contentX, buttonY, contentWidth, 48);
		Screen.DrawLineFrame(ready ? accent : Color(72, 86, 101), contentX, buttonY, contentWidth, 48, ready ? 3 : 1);
		Screen.DrawText(font, ready ? Font.CR_WHITE : Font.CR_GRAY, contentX + 24, buttonY + 14,
			actionText, DTA_ScaleX, 2.45, DTA_ScaleY, 2.45);
		Screen.DrawText(font, Font.CR_GRAY, panelX + 28, panelY + panelHeight - 27,
			"ENTER OR CLICK: PURCHASE     ESC: RETURN", DTA_ScaleX, 2.05, DTA_ScaleY, 2.05);
		Super.Drawer();
	}
}

class TuinRPGClassTrainingMenu : TuinRPGClassUpgradeMenuBase
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		UpgradeMode = 0;
		Super.Init(parent, desc);
	}
}

class TuinRPGClassUltimateMenu : TuinRPGClassUpgradeMenuBase
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		UpgradeMode = 1;
		Super.Init(parent, desc);
	}
}

class TuinRPGPerkMenu : OptionMenu
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			let item = mDesc.mItems[i];
			if (item.Selectable()) item.mCentered = true;
			else if (item.mLabel.Length() > 0 && item.mLabel != " ")
			{
				string label = item.mLabel;
				int textColor = Font.CR_WHITE;
				if (label.IndexOf("HEAVY:") == 0) textColor = Font.CR_LIGHTBLUE;
				else if (label.IndexOf("HEALER:") == 0) textColor = Font.CR_GREEN;
				else if (label.IndexOf("EXECUTIONER") == 0) textColor = Font.CR_RED;
				else if (label.IndexOf("DOOM GUY:") == 0) textColor = Font.CR_ORANGE;
				else if (label.IndexOf("ROGUE:") == 0) textColor = Font.CR_PURPLE;
				else if (label.IndexOf("ENGINEER") == 0) textColor = Font.CR_GOLD;
				else if (label.IndexOf("SELECT") == 0 || label.IndexOf("REQUIRES") == 0 ||
					label.IndexOf("COST:") == 0 || label.IndexOf("AVAILABLE") == 0 ||
					label.IndexOf("YOUR STARTING") == 0 || label.IndexOf("MILESTONES") == 0)
					textColor = Font.CR_LIGHTBLUE;
				mDesc.mItems[i] = new ('OptionMenuItemStaticText').InitDirect(label, textColor);
			}
		}
		mDesc.CalcIndent();
	}

	override void Drawer()
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 48, 1500);
		int panelHeight = min(height - 80, 560);
		int panelX = (width - panelWidth) / 2;
		int panelY = 36;
		Screen.Dim(Color(3, 13, 31), 0.96, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(36, 128, 210), panelX, panelY, panelWidth, panelHeight, 2);
		Screen.Dim(Color(6, 21, 43), 0.72, panelX + 12, panelY + 12,
			panelWidth - 24, panelHeight - 24);
		Super.Drawer();
		if (consoleplayer >= 0 && playerInGame[consoleplayer] && players[consoleplayer].mo)
		{
			let data = TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
			if (data)
			{
				Font deltaFont = "TINYBABY";
				string status = String.Format("CLASS: %s     LEVEL: %d     AVAILABLE PERK POINTS: %d",
					TuinRPGHandler.PlayerClassName(data.PlayerClass), data.PlayerLevel, data.UnspentSkillPoints);
				Screen.Dim(Color(7, 29, 56), 0.92, panelX + 20, panelY + panelHeight - 43,
					panelWidth - 40, 27);
				Screen.DrawText(deltaFont, Font.CR_WHITE, panelX + 32, panelY + panelHeight - 36,
					status, DTA_ScaleX, 2.10, DTA_ScaleY, 2.10);
			}
		}
	}
}

class TuinRPGJohnShopMenu : OptionMenu
{
	double OldTimeScale;
	bool ChangedTimeScale;
	TextureID JohnPortrait;
	string LastDialogue;
	int DialogueRevealStart;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		JohnPortrait = TexMan.CheckForTexture("graphics/TuinJohnPortrait.png", TexMan.Type_Any);
		LastDialogue = "";
		DialogueRevealStart = MenuTime();
		for (int itemIndex = 0; itemIndex < desc.mItems.Size(); itemIndex++)
		{
			let item = OptionMenuItem(desc.mItems[itemIndex]);
			if (item && item.mLabel == "REACH OUT AND HOLD JOHN ROMERO'S HAND (GO TO NEXT LEVEL)"
				&& item.GetClass() != 'TuinRPGFinaleTravelCommand')
			{
				desc.mItems[itemIndex] = new ('TuinRPGFinaleTravelCommand').Init(
					item.mLabel, "netevent tuin_john_travel", false, true);
			}
		}
		int behavior = CVar.FindCVar('tuin_menu_time_mode').GetInt();
		if (behavior == 1)
		{
			let timescale = CVar.FindCVar('i_timescale');
			if (timescale)
			{
				OldTimeScale = timescale.GetFloat();
				timescale.SetFloat(0.10);
				ChangedTimeScale = true;
			}
			menuactive = Menu.OnNoPause;
		}
		else if (behavior == 2) menuactive = Menu.OnNoPause;
	}

	void RestoreTimeScale()
	{
		if (!ChangedTimeScale) return;
		let timescale = CVar.FindCVar('i_timescale');
		if (timescale) timescale.SetFloat(OldTimeScale);
		ChangedTimeScale = false;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey == MKEY_Back) RestoreTimeScale();
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override void Drawer()
	{
		Super.Drawer();
		if (consoleplayer < 0 || !playerInGame[consoleplayer] || !players[consoleplayer].mo) return;
		Actor pawn = players[consoleplayer].mo;
		let data = TuinRPGHandler.GetPlayerData(pawn);
		if (!data) return;
		Font font = SmallFont;
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		double scale = clamp(TuinRPGHandler.CVFloat('tuin_hud_scale', 1.5), 1.25, 2.0);
		int portraitWidth = min(240, width / 5);
		int portraitHeight = portraitWidth;
		int portraitX = max(28, width / 2 - int(500 * scale));
		int portraitY = max(height / 2, height - portraitHeight - int(42 * scale));
		Screen.Dim(Color(5, 8, 18), 0.90, portraitX - 8, portraitY - 8, portraitWidth + 16, portraitHeight + 16);
		if (JohnPortrait.IsValid())
			Screen.DrawTexture(JohnPortrait, false, portraitX, portraitY, DTA_DestWidth, portraitWidth,
				DTA_DestHeight, portraitHeight, DTA_Alpha, 0.95);

		string coins = String.Format("TUIN COINS: %d", TuinRPGHandler.CoinBalance(pawn));
		Screen.DrawText(font, Font.CR_GOLD, portraitX, portraitY + portraitHeight + 12, coins,
			DTA_ScaleX, scale, DTA_ScaleY, scale);

		string dialogue = data.ShopDialogue.Length() ? data.ShopDialogue : "John: Take your time. The exit is not going anywhere.";
		if (dialogue != LastDialogue)
		{
			LastDialogue = dialogue;
			DialogueRevealStart = MenuTime();
		}
		double dialogueScale = clamp(scale * 1.35, 1.8, 2.5);
		int dialogueX = portraitX + portraitWidth + int(30 * scale);
		int dialogueY = portraitY + portraitHeight / 2 - int(16 * dialogueScale);
		int dialogueWidth = min(width - dialogueX - 28, int(900 * scale));
		BrokenLines dialogueLines = font.BreakLines(dialogue, int((dialogueWidth - 24) / dialogueScale));
		int dialogueLineHeight = int(11 * dialogueScale);
		int visibleLineCount = min(6, dialogueLines.Count());
		int dialogueHeight = max(int(30 * dialogueScale), dialogueLineHeight * visibleLineCount + int(16 * dialogueScale));
		Screen.Dim(Color(7, 7, 14), 0.92, dialogueX - 12, dialogueY - 10, dialogueWidth, dialogueHeight);

		// Reveal roughly one character per menu tic. Working from the already
		// wrapped lines keeps completed words from jumping as the text grows.
		int revealCharacters = max(1, MenuTime() - DialogueRevealStart + 1);
		for (int dialogueLine = 0; dialogueLine < visibleLineCount; dialogueLine++)
		{
			string fullLine = dialogueLines.StringAt(dialogueLine);
			if (revealCharacters <= 0) break;
			int lineCharacters = min(fullLine.Length(), revealCharacters);
			Screen.DrawText(font, Font.CR_WHITE, dialogueX, dialogueY + dialogueLine * dialogueLineHeight,
				fullLine.Left(lineCharacters), DTA_ScaleX, dialogueScale, DTA_ScaleY, dialogueScale);
			revealCharacters -= fullLine.Length();
		}
	}
}

class TuinRPGWeaponWheelMenu : OptionMenu
{
	Array<class<Weapon> > WeaponTypes;
	Array<string> WeaponNames;
	Array<int> WeaponQualities;
	Array<int> AmmoCurrent;
	Array<int> AmmoMaximum;
	int SelectedIndex;
	int CurrentIndex;
	int MouseX;
	int MouseY;
	int LastMouseX;
	int LastMouseY;
	double WheelCursorX;
	double WheelCursorY;
	bool HaveMouseSample;
	bool HasDrawn;
	bool Closing;

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		DontDim = true;
		DontBlur = true;
		// Use the engine's ordinary menu pause. UZDoom forbids changing
		// i_timescale from a wheel opened by an interface event.
		menuactive = Menu.On;
		CurrentIndex = -1;
		BuildWeaponList();
		SelectedIndex = CurrentIndex >= 0 ? CurrentIndex : 0;
		double initialAngle = WeaponTypes.Size() > 0 ? -90.0 + SelectedIndex * (360.0 / WeaponTypes.Size()) : -90.0;
		WheelCursorX = cos(initialAngle) * 96.0;
		WheelCursorY = sin(initialAngle) * 96.0;
		MouseX = Screen.GetWidth() / 2 + int(WheelCursorX);
		MouseY = Screen.GetHeight() / 2 + int(WheelCursorY);
	}

	void BuildWeaponList()
	{
		if (consoleplayer < 0 || !playerInGame[consoleplayer] || !players[consoleplayer].mo) return;
		Actor pawn = players[consoleplayer].mo;
		let data = TuinRPGHandler.GetPlayerData(pawn);
		let item = pawn.Inv;
		while (item)
		{
			let weapon = Weapon(item);
			item = item.Inv;
			if (!weapon || weapon.bPowered_Up) continue;
			int entry = WeaponTypes.Size();
			class<Weapon> weaponType = (class<Weapon>)(weapon.GetClass());
			WeaponTypes.Push(weaponType);
			int variantIndex = data ? data.FindEquippedVariant(weaponType) : -1;
			if (variantIndex >= 0)
			{
				WeaponNames.Push(TuinRPGHandler.WeaponVariantName(data.VariantWeaponType[variantIndex],
					data.VariantAffixFlags[variantIndex], data.VariantQuality[variantIndex], data.VariantID[variantIndex]));
				WeaponQualities.Push(data.VariantQuality[variantIndex]);
			}
			else
			{
				WeaponNames.Push(TuinRPGHandler.WeaponBaseName(weaponType));
				WeaponQualities.Push(0);
			}

			int currentAmmo;
			int maximumAmmo;
			if (weapon.Ammo1)
			{
				currentAmmo += weapon.Ammo1.Amount;
				maximumAmmo += weapon.Ammo1.MaxAmount;
			}
			if (weapon.Ammo2 && weapon.Ammo2 != weapon.Ammo1)
			{
				currentAmmo += weapon.Ammo2.Amount;
				maximumAmmo += weapon.Ammo2.MaxAmount;
			}
			AmmoCurrent.Push(currentAmmo);
			AmmoMaximum.Push(maximumAmmo);
			if (players[consoleplayer].ReadyWeapon == weapon) CurrentIndex = entry;
		}
	}

	void RestoreTimeScale()
	{
	}

	void FinishSelection(bool equip)
	{
		if (Closing) return;
		Closing = true;
		if (equip && SelectedIndex >= 0 && SelectedIndex < WeaponTypes.Size())
			EventHandler.SendNetworkEvent("tuin_weapon_wheel_select", SelectedIndex);
		else
			EventHandler.SendNetworkEvent("tuin_weapon_wheel_closed");
		RestoreTimeScale();
		Close();
	}

	void UpdateMouseSelection(int mx, int my)
	{
		MouseX = mx;
		MouseY = my;
		int count = WeaponTypes.Size();
		if (count <= 0) return;
		double dx = mx - Screen.GetWidth() * 0.5;
		double dy = my - Screen.GetHeight() * 0.5;
		if (dx * dx + dy * dy < 1600.0) return;
		double angle = atan2(dy, dx) + 90.0;
		while (angle < 0.0) angle += 360.0;
		while (angle >= 360.0) angle -= 360.0;
		double step = 360.0 / count;
		SelectedIndex = int((angle + step * 0.5) / step) % count;
	}

	void ApplyRelativeMouse(int mx, int my)
	{
		if (!HaveMouseSample)
		{
			LastMouseX = mx;
			LastMouseY = my;
			HaveMouseSample = true;
			return;
		}
		int deltaX = mx - LastMouseX;
		int deltaY = my - LastMouseY;
		LastMouseX = mx;
		LastMouseY = my;
		if (abs(deltaX) + abs(deltaY) < 2) return;
		WheelCursorX += deltaX * 2.2;
		WheelCursorY += deltaY * 2.2;
		double maximum = min(Screen.GetWidth(), Screen.GetHeight()) * 0.38;
		double length = sqrt(WheelCursorX * WheelCursorX + WheelCursorY * WheelCursorY);
		if (length > maximum)
		{
			WheelCursorX *= maximum / length;
			WheelCursorY *= maximum / length;
		}
		UpdateMouseSelection(Screen.GetWidth() / 2 + int(WheelCursorX),
			Screen.GetHeight() / 2 + int(WheelCursorY));
	}

	override bool OnInputEvent(InputEvent ev)
	{
		if (HasDrawn && ev.Type == InputEvent.Type_KeyDown &&
			(ev.KeyScan == 0x10 || ev.KeyChar == 113 || ev.KeyChar == 81 || ev.KeyString ~== "q"))
		{
			FinishSelection(true);
			return true;
		}
		if (ev.Type == InputEvent.Type_KeyDown && ev.KeyScan == InputEvent.Key_Escape)
		{
			FinishSelection(false);
			return true;
		}
		return false;
	}

	override bool OnUIEvent(UiEvent ev)
	{
		if (HasDrawn && ev.Type == UiEvent.Type_KeyDown &&
			(ev.KeyChar == 113 || ev.KeyChar == 81 || ev.KeyString ~== "q"))
		{
			FinishSelection(true);
			return true;
		}
		if (ev.Type == UiEvent.Type_MouseMove)
		{
			ApplyRelativeMouse(ev.MouseX, ev.MouseY);
			return true;
		}
		if (ev.Type == UiEvent.Type_LButtonDown)
		{
			FinishSelection(true);
			return true;
		}
		if (ev.Type == UiEvent.Type_RButtonDown)
		{
			FinishSelection(false);
			return true;
		}
		if (ev.Type == UiEvent.Type_KeyDown && ev.KeyChar == UiEvent.Key_Escape)
		{
			FinishSelection(false);
			return true;
		}
		return false;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		int count = WeaponTypes.Size();
		if (mkey == MKEY_Left && count > 0)
		{
			SelectedIndex = (SelectedIndex + count - 1) % count;
			return true;
		}
		if (mkey == MKEY_Right && count > 0)
		{
			SelectedIndex = (SelectedIndex + 1) % count;
			return true;
		}
		if (mkey == MKEY_Enter)
		{
			FinishSelection(true);
			return true;
		}
		if (mkey == MKEY_Back)
		{
			FinishSelection(false);
			return true;
		}
		return true;
	}

	ui Color AmmoBarColor(double ratio)
	{
		ratio = clamp(ratio, 0.0, 1.0);
		int red = ratio < 0.5 ? 255 : int((1.0 - ratio) * 510.0);
		int green = ratio < 0.5 ? int(ratio * 510.0) : 255;
		return Color(clamp(red, 0, 255), clamp(green, 0, 255), 24);
	}

	ui int AmmoFontColor(double ratio)
	{
		if (ratio <= 0.20) return Font.CR_RED;
		if (ratio <= 0.45) return Font.CR_ORANGE;
		if (ratio <= 0.70) return Font.CR_GOLD;
		return Font.CR_GREEN;
	}

	override void Drawer()
	{
		HasDrawn = true;
		int count = WeaponTypes.Size();
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int centerX = width / 2;
		int centerY = height / 2;
		Font font = SmallFont;
		double scale = clamp(TuinRPGHandler.CVFloat('tuin_hud_scale', 1.5) * 0.90, 1.15, 1.65);
		double itemScale = count > 10 ? scale * 0.78 : count > 8 ? scale * 0.88 : scale;
		double radius = clamp(min(width, height) * 0.31, 210.0, 470.0);
		int boxWidth = int((count > 10 ? 150 : 195) * itemScale);
		int boxHeight = int(51 * itemScale);
		Screen.Dim(Color(2, 3, 7), 0.66, 0, 0, width, height);

		if (count <= 0)
		{
			string empty = "NO WEAPONS AVAILABLE";
			Screen.DrawText(font, Font.CR_RED, centerX - font.StringWidth(empty) * scale * 0.5, centerY,
				empty, DTA_ScaleX, scale, DTA_ScaleY, scale);
			return;
		}

		double step = 360.0 / count;
		for (int i = 0; i < count; i++)
		{
			double angle = -90.0 + i * step;
			int nodeX = centerX + int(cos(angle) * radius);
			int nodeY = centerY + int(sin(angle) * radius);
			int left = nodeX - boxWidth / 2;
			int top = nodeY - boxHeight / 2;
			bool selected = i == SelectedIndex;
			Screen.DrawThickLine(centerX + cos(angle) * radius * 0.42, centerY + sin(angle) * radius * 0.42,
				nodeX, nodeY, selected ? 5.0 : 2.0, selected ? Color(255, 188, 35) : Color(72, 76, 90),
				selected ? 235 : 145);
			Screen.Dim(selected ? Color(49, 34, 5) : Color(5, 7, 13), selected ? 0.96 : 0.90,
				left, top, boxWidth, boxHeight);
			Screen.DrawLineFrame(i == CurrentIndex ? Color(70, 220, 255) :
				selected ? Color(255, 188, 35) : Color(72, 76, 90), left, top, boxWidth, boxHeight,
				selected ? 3 : 1);

			double nameScale = min(itemScale, double(boxWidth - 12) /
				max(1, font.StringWidth(WeaponNames[i])));
			int nameX = nodeX - int(font.StringWidth(WeaponNames[i]) * nameScale * 0.5);
			Screen.DrawText(font, TuinRPGHandler.WeaponQualityFontColor(WeaponQualities[i]), nameX,
				top + int(5 * itemScale), WeaponNames[i], DTA_ScaleX, nameScale, DTA_ScaleY, nameScale);

			double ammoRatio = AmmoMaximum[i] > 0 ? clamp(double(AmmoCurrent[i]) / AmmoMaximum[i], 0.0, 1.0) : 1.0;
			int barX = left + int(7 * itemScale);
			int barY = top + int(23 * itemScale);
			int barWidth = boxWidth - int(14 * itemScale);
			int barHeight = max(4, int(7 * itemScale));
			Screen.Dim(Color(24, 24, 28), 0.98, barX, barY, barWidth, barHeight);
			Screen.Dim(AmmoMaximum[i] > 0 ? AmmoBarColor(ammoRatio) : Color(80, 180, 255), 0.98,
				barX, barY, AmmoMaximum[i] > 0 ? int(barWidth * ammoRatio) : barWidth, barHeight);
			string ammoText = AmmoMaximum[i] > 0 ? String.Format("AMMO %d / %d", AmmoCurrent[i], AmmoMaximum[i]) :
				"NO AMMO REQUIRED";
			double ammoScale = itemScale * 0.78;
			Screen.DrawText(font, AmmoMaximum[i] > 0 ? AmmoFontColor(ammoRatio) : Font.CR_CYAN,
				nodeX - int(font.StringWidth(ammoText) * ammoScale * 0.5), top + int(34 * itemScale),
				ammoText, DTA_ScaleX, ammoScale, DTA_ScaleY, ammoScale);
		}

		int centerWidth = int(330 * scale);
		int centerHeight = int(103 * scale);
		int centerLeft = centerX - centerWidth / 2;
		int centerTop = centerY - centerHeight / 2;
		Screen.Dim(Color(4, 5, 11), 0.96, centerLeft, centerTop, centerWidth, centerHeight);
		Screen.DrawLineFrame(Color(255, 188, 35), centerLeft, centerTop, centerWidth, centerHeight, 2);
		string title = "WEAPON WHEEL";
		Screen.DrawText(font, Font.CR_GOLD, centerX - int(font.StringWidth(title) * scale * 0.5),
			centerTop + int(8 * scale), title, DTA_ScaleX, scale, DTA_ScaleY, scale);
		string selectedName = WeaponNames[SelectedIndex];
		double selectedScale = min(scale * 1.08, double(centerWidth - 20) / max(1, font.StringWidth(selectedName)));
		Screen.DrawText(font, TuinRPGHandler.WeaponQualityFontColor(WeaponQualities[SelectedIndex]),
			centerX - int(font.StringWidth(selectedName) * selectedScale * 0.5), centerTop + int(31 * scale),
			selectedName, DTA_ScaleX, selectedScale, DTA_ScaleY, selectedScale);
		double selectedRatio = AmmoMaximum[SelectedIndex] > 0 ?
			clamp(double(AmmoCurrent[SelectedIndex]) / AmmoMaximum[SelectedIndex], 0.0, 1.0) : 1.0;
		string selectedAmmo = AmmoMaximum[SelectedIndex] > 0 ?
			String.Format("AMMO: %d / %d", AmmoCurrent[SelectedIndex], AmmoMaximum[SelectedIndex]) :
			"NO AMMO REQUIRED";
		Screen.DrawText(font, AmmoMaximum[SelectedIndex] > 0 ? AmmoFontColor(selectedRatio) : Font.CR_CYAN,
			centerX - int(font.StringWidth(selectedAmmo) * scale * 0.5), centerTop + int(55 * scale),
			selectedAmmo, DTA_ScaleX, scale, DTA_ScaleY, scale);
		string help = "MOVE MOUSE | Q / CLICK / ENTER: EQUIP | ESC / RIGHT CLICK: CANCEL";
		double helpScale = scale * 0.82;
		Screen.DrawText(font, Font.CR_WHITE, centerX - int(font.StringWidth(help) * helpScale * 0.5),
			centerTop + int(80 * scale), help, DTA_ScaleX, helpScale, DTA_ScaleY, helpScale);

	}

	override void OnDestroy()
	{
		RestoreTimeScale();
		Super.OnDestroy();
	}
}
