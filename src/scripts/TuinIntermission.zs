class TuinRPGStatusScreen : DoomStatusScreen
{
	int ResultPercent(int current, int maximum)
	{
		if (current < 0) return 0;
		if (maximum <= 0) return 100;
		return clamp(int(current * 100.0 / maximum + 0.5), 0, 100);
	}

	int PacePercent()
	{
		if (cnt_time < 0) return 0;
		int parSeconds = wbs.partime / GameTicRate;
		if (parSeconds <= 0 || cnt_time <= parSeconds) return 100;
		return clamp(100 - int((cnt_time - parSeconds) * 100.0 / max(1, parSeconds * 2)), 0, 100);
	}

	int MissionScore()
	{
		int killsPercent = ResultPercent(cnt_kills[0], wbs.maxkills);
		int itemsPercent = ResultPercent(cnt_items[0], wbs.maxitems);
		int secretsPercent = ResultPercent(cnt_secret[0], wbs.maxsecret);
		return clamp(killsPercent * 3 + int(itemsPercent * 1.5) +
			int(secretsPercent * 1.5) + PacePercent() + LifeScore(), 0, 1000);
	}

	int LifeScore()
	{
		Actor pawn = me >= 0 && me < MAXPLAYERS ? players[me].mo : null;
		let data = pawn ? TuinPlayerData(pawn.FindInventory('TuinPlayerData')) : null;
		if (!data || data.LevelLivesUsed <= 0) return 300;
		if (data.LevelLivesUsed == 1) return 160;
		if (data.LevelLivesUsed == 2) return 60;
		return 0;
	}

	string MissionRating(int score)
	{
		if (score >= 950) return "S";
		if (score >= 850) return "A";
		if (score >= 750) return "B";
		if (score >= 550) return "C";
		if (score >= 400) return "D";
		return "E";
	}

	int RatingColor(int score)
	{
		if (score >= 950) return Font.CR_WHITE;
		if (score >= 850) return Font.CR_GOLD;
		if (score >= 750) return Font.CR_GREEN;
		if (score >= 550) return Font.CR_ORANGE;
		return Font.CR_RED;
	}

	string JohnVerdict(int score)
	{
		if (score >= 950) return "JOHN: You owned every inch of this place. Beautiful work.";
		if (score >= 850) return "JOHN: Hell barely had time to learn your name.";
		if (score >= 750) return "JOHN: Strong run. You kept the pressure where it belonged.";
		if (score >= 550) return "JOHN: You made it through. Make the next map remember you.";
		if (score >= 400) return "JOHN: Rough around the edges, but you are still standing.";
		return "JOHN: That hurt. Breathe, reload, and hit the next one harder.";
	}

	string ResultTime(int seconds)
	{
		seconds = max(0, seconds);
		return String.Format("%02d:%02d", seconds / 60, seconds % 60);
	}

	void DrawCentered(Font font, int color, double centerX, double y, string text, double scale)
	{
		screen.DrawText(font, color, centerX - font.StringWidth(text) * scale * 0.5, y, text,
			DTA_ScaleX, scale, DTA_ScaleY, scale, DTA_Shadow, true);
	}

	void DrawResultRow(Font font, string label, int current, int maximum,
		double x, double y, double width, double scale)
	{
		int percent = ResultPercent(current, maximum);
		string value = maximum > 0 ? String.Format("%d / %d    %d%%", max(0, current), maximum, percent) :
			String.Format("%d%%", percent);
		screen.DrawText(font, Font.CR_WHITE, x, y, label, DTA_ScaleX, scale, DTA_ScaleY, scale);
		screen.DrawText(font, percent >= 100 ? Font.CR_GOLD : Font.CR_GRAY,
			x + width - font.StringWidth(value) * scale, y, value,
			DTA_ScaleX, scale, DTA_ScaleY, scale);
		double barY = y + 13 * scale;
		screen.Dim(Color(18, 18, 18), 0.92, int(x), int(barY), int(width), max(3, int(7 * scale)));
		if (percent > 0)
			screen.Dim(percent >= 100 ? Color(210, 135, 24) : Color(150, 22, 14), 0.12,
				int(x + 2), int(barY + 2), int((width - 4) * percent / 100.0), max(1, int(7 * scale) - 4));
	}

	void DrawRecordRow(Font font, string label, string value,
		double x, double y, double width, double scale)
	{
		screen.DrawText(font, Font.CR_GRAY, x, y, label,
			DTA_ScaleX, scale, DTA_ScaleY, scale);
		screen.DrawText(font, Font.CR_WHITE, x + width - font.StringWidth(value) * scale, y, value,
			DTA_ScaleX, scale, DTA_ScaleY, scale);
	}

	override void drawStats()
	{
		int sw = screen.GetWidth();
		int sh = screen.GetHeight();
		double scale = clamp(min(sw / 960.0, sh / 600.0), 0.80, 2.50);
		int panelWidth = min(sw - 24, int(800 * scale));
		int panelHeight = min(sh - 24, int(480 * scale));
		int panelX = (sw - panelWidth) / 2;
		int panelY = (sh - panelHeight) / 2;
		Font bodyFont = NewSmallFont;
		Font headingFont = BigFont;

		screen.Dim(Color(0, 0, 0), 0.68, 0, 0, sw, sh);
		screen.Dim(Color(5, 7, 9), 0.90, panelX, panelY, panelWidth, panelHeight);
		screen.DrawLineFrame(Color(175, 32, 18), panelX, panelY, panelWidth, panelHeight, max(2, int(2 * scale)));
		screen.DrawLineFrame(Color(54, 43, 24), panelX + int(7 * scale), panelY + int(7 * scale),
			panelWidth - int(14 * scale), panelHeight - int(14 * scale), max(1, int(scale)));

		double centerX = sw * 0.5;
		DrawCentered(headingFont, Font.CR_RED, centerX, panelY + 18 * scale, "MISSION COMPLETE", scale * 1.05);
		string mapTitle = StringTable.Localize(wbs.thisname);
		DrawCentered(bodyFont, Font.CR_GOLD, centerX, panelY + 53 * scale, mapTitle, scale * 1.20);

		Actor pawn = me >= 0 && me < MAXPLAYERS ? players[me].mo : null;
		let rpgData = pawn ? TuinPlayerData(pawn.FindInventory('TuinPlayerData')) : null;
		let coinItem = pawn ? Inventory(pawn.FindInventory('TuinCoinPickup')) : null;
		if (rpgData)
		{
			string heroLine = String.Format("LEVEL %d    %s    %d COINS    %d LIVES", rpgData.PlayerLevel,
				TuinRPGHandler.PlayerClassName(rpgData.PlayerClass), coinItem ? coinItem.Amount : 0, rpgData.Lives);
			DrawCentered(bodyFont, Font.CR_GRAY, centerX, panelY + 72 * scale, heroLine, scale);
		}

		double leftX = panelX + 38 * scale;
		double leftWidth = 430 * scale;
		double rightX = panelX + 520 * scale;
		double rightWidth = 240 * scale;
		double sectionY = panelY + 108 * scale;
		screen.DrawText(bodyFont, Font.CR_GOLD, leftX, sectionY, "COMBAT RECORD",
			DTA_ScaleX, scale * 1.15, DTA_ScaleY, scale * 1.15);
		DrawResultRow(bodyFont, "KILLS", cnt_kills[0], wbs.maxkills, leftX, sectionY + 30 * scale, leftWidth, scale);
		DrawResultRow(bodyFont, "ITEMS", cnt_items[0], wbs.maxitems, leftX, sectionY + 76 * scale, leftWidth, scale);
		DrawResultRow(bodyFont, "SECRETS", cnt_secret[0], wbs.maxsecret, leftX, sectionY + 122 * scale, leftWidth, scale);

		int score = MissionScore();
		DrawCentered(bodyFont, Font.CR_GOLD, rightX + rightWidth * 0.5, sectionY,
			"MISSION RATING", scale * 1.15);
		DrawCentered(headingFont, RatingColor(score), rightX + rightWidth * 0.5,
			sectionY + 38 * scale, MissionRating(score), scale * 3.10);
		DrawCentered(bodyFont, Font.CR_WHITE, rightX + rightWidth * 0.5,
			sectionY + 104 * scale, String.Format("SCORE  %d / 1000", score), scale * 1.10);
		DrawCentered(bodyFont, PacePercent() >= 100 ? Font.CR_GOLD : Font.CR_GRAY,
			rightX + rightWidth * 0.5, sectionY + 130 * scale,
			String.Format("PACE BONUS  %d / 100", PacePercent()), scale);
		DrawCentered(bodyFont, LifeScore() >= 300 ? Font.CR_GOLD : Font.CR_RED,
			rightX + rightWidth * 0.5, sectionY + 152 * scale,
			String.Format("LIFE BONUS  %d / 300", LifeScore()), scale);
		DrawCentered(bodyFont, Font.CR_GOLD, rightX + rightWidth * 0.5,
			sectionY + 180 * scale, "RPG RECORD", scale * 1.10);
		if (rpgData)
		{
			DrawRecordRow(bodyFont, "DAMAGE DEALT", String.Format("%d", rpgData.LevelDamageDealt),
				rightX, sectionY + 204 * scale, rightWidth, scale);
			DrawRecordRow(bodyFont, "DAMAGE TAKEN", String.Format("%d", rpgData.LevelDamageTaken),
				rightX, sectionY + 224 * scale, rightWidth, scale);
			DrawRecordRow(bodyFont, "XP EARNED / COINS", String.Format("%d / %d", rpgData.LevelXPEarned, rpgData.LevelCoinsEarned),
				rightX, sectionY + 244 * scale, rightWidth, scale);
			DrawRecordRow(bodyFont, "SPECIALS / BOSSES", String.Format("%d / %d", rpgData.LevelEliteKills, rpgData.LevelBossKills),
				rightX, sectionY + 264 * scale, rightWidth, scale);
			DrawRecordRow(bodyFont, "CRITS / ABILITIES", String.Format("%d / %d", rpgData.LevelCriticalHits, rpgData.LevelAbilityUses),
				rightX, sectionY + 284 * scale, rightWidth, scale);
			DrawRecordRow(bodyFont, "LIVES USED", String.Format("%d", rpgData.LevelLivesUsed),
				rightX, sectionY + 304 * scale, rightWidth, scale);
		}

		double timeY = panelY + 312 * scale;
		screen.DrawText(bodyFont, Font.CR_GRAY, leftX, timeY, "MISSION TIME",
			DTA_ScaleX, scale, DTA_ScaleY, scale);
		screen.DrawText(bodyFont, Font.CR_WHITE, leftX + 132 * scale, timeY,
			ResultTime(cnt_time), DTA_ScaleX, scale, DTA_ScaleY, scale);
		if (wbs.partime > 0)
		{
			screen.DrawText(bodyFont, Font.CR_GRAY, leftX + 250 * scale, timeY, "PAR",
				DTA_ScaleX, scale, DTA_ScaleY, scale);
			screen.DrawText(bodyFont, cnt_time >= 0 && cnt_time <= wbs.partime / GameTicRate ? Font.CR_GOLD : Font.CR_WHITE,
				leftX + 305 * scale, timeY, ResultTime(wbs.partime / GameTicRate),
				DTA_ScaleX, scale, DTA_ScaleY, scale);
		}

		DrawCentered(SmallFont, Font.CR_TAN, centerX, panelY + 428 * scale,
			JohnVerdict(score), scale * 1.05);
		string footer = sp_state == 10 ? "PRESS USE TO CONTINUE" : "CALCULATING MISSION REPORT...";
		DrawCentered(bodyFont, sp_state == 10 ? Font.CR_GOLD : Font.CR_GRAY,
			centerX, panelY + 454 * scale, footer, scale * 1.05);
	}
}
