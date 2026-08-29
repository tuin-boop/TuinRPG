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

class TuinRPGCharacterMenu : OptionMenu
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
		double rogueCritical = TuinRPGHandler.RogueCriticalBonus(data);
		double classDamage = data.PlayerClass == 1 ? (data.TankOverdriveActive ? 1.25 : 0.50) : data.PlayerClass == 2 ? 0.75 :
			data.PlayerClass == 3 ? 1.30 + data.PerkClassMastery * 0.03 : data.PlayerClass == 4 ? 1.10 : 1.0;
		double damageBonus = (classDamage * (1.0 + data.Strength * 0.02) * (1.0 + weaponPower * 0.01) - 1.0) * 100.0;
		int firingSpeed = min(data.PlayerClass == 1 && data.TankOverdriveActive ? 200 : 75,
			data.Agility * 2 + weaponHaste + (data.PlayerClass == 1 && data.TankOverdriveActive ? 150 : 0));
		double criticalChance = TuinRPGHandler.TotalCriticalChance(data, variantIndex);
		double bonusXPChance = (1.0 - exp(log(0.97) * max(0, data.Luck))) * 100.0;
		double classProtection = data.PlayerClass == 1 ? 0.50 * (1.0 - data.PerkClassMastery * 0.03) : data.PlayerClass == 3 ? 1.10 :
			data.PlayerClass == 4 ? 0.90 : 1.0;
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
		if (mLabel ~== "TANK")
		{
			role = "BULWARK";
			bonuses = "300 BASE HP | 50% DAMAGE RESISTANCE | +100% AMMO";
			tradeoff = "WEAPON DAMAGE REDUCED BY 50%";
			ability = "V: OVERDRIVE - DAMAGE + FIRE SPEED FOR 10 SEC";
			training = "+3% DAMAGE RESISTANCE PER RANK";
			ultimate = "LAST STAND BELOW 30% HEALTH";
		}
		else if (mLabel ~== "HEALER")
		{
			role = "COMBAT MEDIC";
			bonuses = "HEAL THE TEAM 5 HP EVERY 2 SEC | +25% AMMO";
			tradeoff = "WEAPON DAMAGE REDUCED BY 25%";
			ability = "PASSIVE TEAM HEALING - NO ACTIVATION NEEDED";
			training = "+1 HEALTH PER HEALING PULSE PER RANK";
			ultimate = "DOUBLE ALL CLASS HEALING";
		}
		else if (mLabel ~== "DAMAGE DEALER")
		{
			role = "GLASS CANNON";
			bonuses = "+30% WEAPON DAMAGE";
			tradeoff = "-25% MAX HEALTH | TAKE 10% MORE DAMAGE";
			ability = "HIGH-DAMAGE CRITICAL-HIT SPECIALIST";
			training = "+3% WEAPON DAMAGE PER RANK";
			ultimate = "CRITICAL HITS DEAL 2.5X DAMAGE";
		}
		else if (mLabel ~== "DOOM GUY")
		{
			role = "SLAYER";
			bonuses = "+10% DAMAGE | 10% RESISTANCE | REGEN 1 HP / 10 SEC";
			tradeoff = "NO MAJOR DRAWBACKS";
			ability = "HOLD V TO READY BLOOD PUNCH - RELEASE TO STRIKE";
			training = "BLOOD PUNCH CHARGE +10% / +20% / +30%";
			ultimate = "+45% CHARGE | HEAL 30% DAMAGE, MAX 110 HP";
		}
		else
		{
			role = "AMBUSHER";
			bonuses = "+5% CRITICAL CHANCE | CRITICAL HITS CAUSE BLEEDING";
			tradeoff = "-20% MAXIMUM HEALTH";
			ability = "V: SHADOW VEIL - ATTACK FROM STEALTH TO AMBUSH";
			training = "+2% CRIT | LONGER VEIL | FASTER CHARGE PER RANK";
			ultimate = "AMBUSH: X6 RANGED DAMAGE / X30 FIST DAMAGE";
		}

		int center = Screen.GetWidth() / 2;
		int classX = center - 650;
		int detailX = center - 250;
		int valueX = center + 20;
		if (mLabel ~== "TANK")
			drawText(classX, y - 28, Font.CR_GOLD, "SELECT A CLASS");
		drawText(classX, y, selected ? Font.CR_RED : Font.CR_WHITE,
			selected ? String.Format("> %s", mLabel) : String.Format("  %s", mLabel));
		if (selected)
		{
			drawText(detailX, 132, Font.CR_RED, String.Format("%s  //  %s", mLabel, role));
			drawText(detailX, 178, Font.CR_WHITE, "CORE BONUSES");
			drawText(valueX, 178, Font.CR_GOLD, bonuses);
			drawText(detailX, 218, Font.CR_WHITE, "TRADEOFF");
			drawText(valueX, 218, Font.CR_GOLD, tradeoff);
			drawText(detailX, 258, Font.CR_WHITE, "CLASS ABILITY");
			drawText(valueX, 258, Font.CR_GOLD, ability);
			drawText(detailX, 298, Font.CR_WHITE, "CLASS TRAINING");
			drawText(valueX, 298, Font.CR_GOLD, training);
			drawText(detailX, 338, Font.CR_WHITE, "CLASS ULTIMATE");
			drawText(valueX, 338, Font.CR_GOLD, ultimate);
		}
		return classX - 16 * CleanXfac_1;
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
			if (item.mLabel ~== "TANK") command = "netevent tuin_choose_class 1";
			else if (item.mLabel ~== "HEALER") command = "netevent tuin_choose_class 2";
			else if (item.mLabel ~== "DAMAGE DEALER") command = "netevent tuin_choose_class 3";
			else if (item.mLabel ~== "DOOM GUY") command = "netevent tuin_choose_class 4";
			else if (item.mLabel ~== "ROGUE") command = "netevent tuin_choose_class 5";
			else continue;
			mDesc.mItems[i] = new ('TuinRPGClassChoiceItem').Init(item.mLabel, command);
		}
		mDesc.CalcIndent();
	}

	override void Drawer()
	{
		int width = Screen.GetWidth();
		int height = Screen.GetHeight();
		int panelWidth = min(width - 72, 1660);
		int panelHeight = min(height - 72, 500);
		int panelX = (width - panelWidth) / 2;
		int panelY = 36;
		Screen.Dim(Color(0, 0, 0), 0.96, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(0, 0, 0), panelX, panelY, panelWidth, panelHeight, 7);
		Screen.DrawLineFrame(Color(170, 116, 26), panelX + 7, panelY + 7,
			panelWidth - 14, panelHeight - 14, 2);
		Screen.Dim(Color(170, 116, 26), 0.72, width / 2 - 330, panelY + 94, 2, panelHeight - 118);
		Super.Drawer();
	}
}

class TuinRPGPerkMenu : OptionMenu
{
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		Super.Init(parent, desc);
		for (int i = 0; i < mDesc.mItems.Size(); i++)
		{
			if (mDesc.mItems[i].Selectable()) mDesc.mItems[i].mCentered = true;
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
		Screen.Dim(Color(3, 5, 10), 0.93, panelX, panelY, panelWidth, panelHeight);
		Screen.DrawLineFrame(Color(170, 116, 26), panelX, panelY, panelWidth, panelHeight, 2);
		Screen.Dim(Color(11, 17, 23), 0.64, panelX + 12, panelY + 12,
			panelWidth - 24, panelHeight - 24);
		Super.Drawer();
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
