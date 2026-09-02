// Tuin RPG minimap.
// Line clipping and the general explored-line approach are adapted from
// Standalone Minimap (c) 2022-2025 Marisa the Magician, UnSX Team, MIT License.

class TuinMapMarker : Object play
{
	Actor Target;
	Vector3 LastPosition;
	int Kind;       // 1 monster, 2 weapon drop, 3 John
	int Rarity;
	int LastSeen;
	int Discovered;
	bool Alive;
	bool HuntReveal;
	TuinMapMarker Next;
}

class TuinMinimapHandler : EventHandler
{
	TuinMapMarker Markers;
	bool HuntModeUnlocked;

	override void UiTick()
	{
		let migrated = CVar.FindCVar('tuin_minimap_size_migrated_051');
		if (migrated && !migrated.GetBool())
		{
			let sizeCVar = CVar.FindCVar('tuin_minimap_size');
			if (sizeCVar && sizeCVar.GetInt() == 240) sizeCVar.SetInt(320);
			migrated.SetBool(true);
		}
	}

	clearscope static int MapInt(Name key, int fallback = 0)
	{
		let cv = CVar.FindCVar(key);
		return cv ? cv.GetInt() : fallback;
	}

	clearscope static double MapFloat(Name key, double fallback = 0.0)
	{
		let cv = CVar.FindCVar(key);
		return cv ? cv.GetFloat() : fallback;
	}

	void ClearMarkers()
	{
		TuinMapMarker marker = Markers;
		while (marker)
		{
			TuinMapMarker nextMarker = marker.Next;
			marker.Destroy();
			marker = nextMarker;
		}
		Markers = null;
	}

	override void WorldLoaded(WorldEvent e)
	{
		ClearMarkers();
		HuntModeUnlocked = false;
	}

	override void WorldUnloaded(WorldEvent e)
	{
		ClearMarkers();
	}

	TuinMapMarker FindMarker(Actor target)
	{
		for (TuinMapMarker marker = Markers; marker; marker = marker.Next)
			if (marker.Target == target) return marker;
		return null;
	}

	void RememberActor(Actor target, int kind, int rarity, bool huntReveal = false)
	{
		if (!target) return;
		TuinMapMarker marker = FindMarker(target);
		if (!marker)
		{
			marker = new("TuinMapMarker");
			marker.Target = target;
			marker.Kind = kind;
			marker.Discovered = level.Time;
			marker.Next = Markers;
			Markers = marker;
		}
		marker.LastPosition = target.Pos;
		marker.Rarity = rarity;
		marker.HuntReveal = kind == 1 && huntReveal;
		marker.LastSeen = level.Time;
		marker.Alive = kind == 2 ? target.bSPECIAL : kind == 3 ? true : target.Health > 0;
	}

	bool CanDiscover(Actor viewer, Actor target, int playerNumber)
	{
		if (!viewer || !target) return false;
		double maxDistance = clamp(MapFloat('tuin_minimap_discovery_distance', 4096.0), 512.0, 8192.0);
		if (viewer.Distance3D(target) > maxDistance) return false;
		double halfFov = clamp(players[playerNumber].FOV * 0.60, 45.0, 100.0);
		if (abs(Actor.deltaangle(viewer.Angle, viewer.AngleTo(target, true))) > halfFov) return false;
		return viewer.CheckSight(target, SF_IGNOREVISIBILITY | SF_IGNOREWATERBOUNDARY);
	}

	void RefreshExistingMarkers(Actor viewer, int playerNumber)
	{
		TuinMapMarker marker = Markers;
		TuinMapMarker previous = null;
		while (marker)
		{
			TuinMapMarker nextMarker = marker.Next;
			bool remove = !marker.Target;
			if (!remove && marker.Kind == 1)
			{
				marker.Alive = marker.Target.Health > 0 && !marker.Target.bKILLED;
				if (marker.Alive && CanDiscover(viewer, marker.Target, playerNumber))
				{
					marker.LastPosition = marker.Target.Pos;
					marker.LastSeen = level.Time;
				}
				if (!marker.Alive && level.Time - marker.LastSeen > 175) remove = true;
			}
			else if (!remove && marker.Kind == 2)
			{
				marker.Alive = marker.Target.bSPECIAL;
				if (!marker.Alive) remove = true;
				else if (CanDiscover(viewer, marker.Target, playerNumber))
				{
					marker.LastPosition = marker.Target.Pos;
					marker.LastSeen = level.Time;
				}
			}
			else if (!remove)
			{
				marker.Alive = true;
				marker.LastPosition = marker.Target.Pos;
				marker.LastSeen = level.Time;
			}
			if (remove)
			{
				if (previous) previous.Next = nextMarker;
				else Markers = nextMarker;
				marker.Destroy();
			}
			else previous = marker;
			marker = nextMarker;
		}
	}

	override void WorldTick()
	{
		if ((level.Time % 4) != 0) return;
		int pnum = consoleplayer;
		if (pnum < 0 || pnum >= 8 || !playerInGame[pnum] || !players[pnum].mo) return;
		Actor viewer = players[pnum].mo;
		RefreshExistingMarkers(viewer, pnum);
		if (!HuntModeUnlocked && level.total_monsters > 0 &&
			level.killed_monsters * 100 >= level.total_monsters * 85)
			HuntModeUnlocked = true;
		bool showNormal = MapInt('tuin_minimap_show_normal_monsters', 0) != 0;
		bool showLoot = MapInt('tuin_minimap_show_weapon_drops', 1) != 0;
		foreach (sector: level.Sectors)
		{
			for (Actor actor = sector.thinglist; actor; actor = actor.snext)
			{
				if (actor.bISMONSTER && actor.bSHOOTABLE && !actor.bFRIENDLY && actor.Health > 0)
				{
					let data = TuinRPGHandler.GetMonsterData(actor);
					int rarity = data ? data.MonsterRarity : 0;
					if (HuntModeUnlocked || rarity >= 6 ||
						((rarity > 0 || showNormal) && CanDiscover(viewer, actor, pnum)))
						RememberActor(actor, 1, rarity, HuntModeUnlocked);
				}
				else if (showLoot && actor is 'TuinWeaponDrop')
				{
					RememberActor(actor, 2, TuinWeaponDrop(actor).Quality);
				}
				else if (actor is 'TuinJohnShopNPC')
				{
					RememberActor(actor, 3, 0);
				}
			}
		}
	}

	clearscope static bool, Vector2, Vector2 ClipLine(Vector2 minimum, Vector2 maximum, Vector2 start, Vector2 finish)
	{
		double first = 0.0;
		double last = 1.0;
		Vector2 delta = finish - start;
		for (int side = 0; side < 4; side++)
		{
			double p;
			double q;
			switch (side)
			{
			case 0: p = -delta.x; q = start.x - minimum.x; break;
			case 1: p = delta.x; q = maximum.x - start.x; break;
			case 2: p = -delta.y; q = start.y - minimum.y; break;
			default: p = delta.y; q = maximum.y - start.y; break;
			}
			if (p == 0.0 && q < 0.0) return false, (0, 0), (0, 0);
			if (p != 0.0)
			{
				double ratio = q / p;
				if (p < 0.0)
				{
					if (ratio > last) return false, (0, 0), (0, 0);
					if (ratio > first) first = ratio;
				}
				else
				{
					if (ratio < first) return false, (0, 0), (0, 0);
					if (ratio < last) last = ratio;
				}
			}
		}
		return true, start + delta * first, start + delta * last;
	}

	clearscope static Color MarkerColor(int rarity)
	{
		switch (rarity)
		{
		case 1: return Color(60, 225, 90);
		case 2: return Color(40, 200, 255);
		case 3: return Color(255, 120, 24);
		case 4: return Color(255, 195, 35);
		case 5: return Color(205, 45, 255);
		case 6: return Color(255, 32, 72);
		default: return Color(235, 45, 45);
		}
	}

	clearscope static Vector2 ToMap(Vector2 worldPosition, Vector2 playerPosition, double viewAngle,
		bool rotateMap, Vector2 center, double scale)
	{
		Vector2 relative = worldPosition - playerPosition;
		relative.y *= -1.0;
		if (rotateMap) relative = Actor.RotateVector(relative, viewAngle - 90.0);
		return center + relative * scale;
	}

	clearscope static void DrawCircle(Vector2 center, double radius, Color color, int alpha, double thickness = 1.5)
	{
		Vector2 previous = center + (radius, 0);
		for (int i = 1; i <= 12; i++)
		{
			double angle = i * 30.0;
			Vector2 current = center + (cos(angle) * radius, sin(angle) * radius);
			Screen.DrawThickLine(previous.x, previous.y, current.x, current.y, thickness, color, alpha);
			previous = current;
		}
	}

	override void RenderOverlay(RenderEvent e)
	{
		if (!MapInt('tuin_minimap_enabled', 1)) return;
		int pnum = consoleplayer;
		if (pnum < 0 || pnum >= 8 || !playerInGame[pnum] || !players[pnum].Camera) return;
		int screenWidth = Screen.GetWidth();
		int screenHeight = Screen.GetHeight();
		int size = clamp(MapInt('tuin_minimap_size', 320), 140, min(520, screenHeight - 32));
		double range = clamp(MapFloat('tuin_minimap_range', 1536.0), 512.0, 4096.0);
		double horizontal = clamp(MapFloat('tuin_minimap_horizontal', 0.98), 0.0, 1.0);
		double vertical = clamp(MapFloat('tuin_minimap_vertical', 0.02), 0.0, 1.0);
		int left = int(8 + (screenWidth - size - 16) * horizontal);
		int top = int(8 + (screenHeight - size - 16) * vertical);
		double half = size * 0.5;
		Vector2 center = (left + half, top + half);
		Vector2 minimum = (left + 3, top + 3);
		Vector2 maximum = (left + size - 3, top + size - 3);
		double scale = (half - 5.0) / range;
		bool rotateMap = MapInt('tuin_minimap_rotate', 1) != 0;
		Vector2 playerPosition = players[pnum].Camera.Pos.xy;
		double viewAngle = e.ViewAngle;
		double opacity = clamp(MapFloat('tuin_minimap_opacity', 0.72), 0.2, 1.0);

		Screen.Dim(Color(4, 7, 10), opacity, left, top, size, size);
		Screen.DrawThickLine(left, top, left + size, top, 2, Color(70, 105, 125));
		Screen.DrawThickLine(left + size, top, left + size, top + size, 2, Color(70, 105, 125));
		Screen.DrawThickLine(left + size, top + size, left, top + size, 2, Color(70, 105, 125));
		Screen.DrawThickLine(left, top + size, left, top, 2, Color(70, 105, 125));

		foreach (mapLine: level.Lines)
		{
			if (!(mapLine.Flags & Line.ML_MAPPED) && !level.AllMap && !am_cheat) continue;
			if ((mapLine.Flags & Line.ML_DONTDRAW) && !am_cheat) continue;
			Vector2 point1 = ToMap(mapLine.v1.p, playerPosition, viewAngle, rotateMap, center, scale);
			Vector2 point2 = ToMap(mapLine.v2.p, playerPosition, viewAngle, rotateMap, center, scale);
			bool visible;
			[visible, point1, point2] = ClipLine(minimum, maximum, point1, point2);
			if (!visible) continue;
			Color lineColor = Color(120, 135, 142);
			if (mapLine.locknumber > 0) lineColor = Color(255, 195, 40);
			else if (mapLine.special == Exit_Normal || mapLine.special == Exit_Secret || mapLine.special == Teleport_NewMap)
				lineColor = Color(80, 255, 100);
			else if (mapLine.Flags & Line.ML_SECRET) lineColor = Color(190, 65, 220);
			else if (mapLine.backsector) lineColor = Color(70, 82, 88);
			Screen.DrawLine(point1.x, point1.y, point2.x, point2.y, lineColor, 220);
		}

		for (TuinMapMarker marker = Markers; marker; marker = marker.Next)
		{
			if (!marker.Alive) continue;
			Vector2 markerPoint = ToMap(marker.LastPosition.xy, playerPosition, viewAngle, rotateMap, center, scale);
			Vector2 offset = markerPoint - center;
			double edge = half - 9.0;
			if (max(abs(offset.x), abs(offset.y)) > edge)
			{
				if (marker.Kind != 2 && marker.Kind != 3 &&
					(marker.Kind != 1 || (marker.Rarity < 4 && !marker.HuntReveal))) continue;
				double factor = edge / max(abs(offset.x), abs(offset.y));
				markerPoint = center + offset * factor;
			}
			Color markerColor = marker.Kind == 2 ? TuinWeaponDrop.QualityColor(marker.Rarity) :
				marker.Kind == 3 ? Color(70, 255, 210) :
				marker.HuntReveal && marker.Rarity == 0 ? Color(255, 245, 70) : MarkerColor(marker.Rarity);
			int age = level.Time - marker.LastSeen;
			int alpha = age <= 8 ? 255 : 155;
			if (marker.Kind == 2)
			{
				Screen.DrawThickLine(markerPoint.x, markerPoint.y - 4, markerPoint.x + 4, markerPoint.y, 2, markerColor, alpha);
				Screen.DrawThickLine(markerPoint.x + 4, markerPoint.y, markerPoint.x, markerPoint.y + 4, 2, markerColor, alpha);
				Screen.DrawThickLine(markerPoint.x, markerPoint.y + 4, markerPoint.x - 4, markerPoint.y, 2, markerColor, alpha);
				Screen.DrawThickLine(markerPoint.x - 4, markerPoint.y, markerPoint.x, markerPoint.y - 4, 2, markerColor, alpha);
			}
			else if (marker.Kind == 3)
			{
				DrawCircle(markerPoint, 6.0, markerColor, 255, 2.2);
				Screen.DrawThickLine(markerPoint.x - 4, markerPoint.y, markerPoint.x + 4, markerPoint.y, 2, markerColor, 255);
				Screen.DrawThickLine(markerPoint.x, markerPoint.y - 4, markerPoint.x, markerPoint.y + 4, 2, markerColor, 255);
				double pulse = 10.0 + 2.0 * sin((gametic + e.FracTic) * 10.0);
				DrawCircle(markerPoint, pulse, markerColor, 150, 1.6);
			}
			else
			{
				double radius = marker.Rarity >= 4 ? 5.0 : marker.Rarity > 0 ? 4.0 :
					marker.HuntReveal ? 3.5 : 2.5;
				DrawCircle(markerPoint, radius, markerColor, alpha, marker.Rarity >= 4 ? 2.0 : 1.4);
				if (marker.HuntReveal || level.Time - marker.Discovered < 70 || marker.Rarity >= 5)
				{
					double pulse = radius + 3.0 + 2.0 * sin((gametic + e.FracTic) * 12.0);
					DrawCircle(markerPoint, pulse, markerColor, max(70, alpha - 60));
				}
			}
		}

		// Player arrow; it points upward when map rotation is enabled.
		double playerAngle = rotateMap ? -90.0 : -viewAngle;
		Vector2 forward = (cos(playerAngle) * 8.0, sin(playerAngle) * 8.0);
		Vector2 side = (-forward.y * 0.55, forward.x * 0.55);
		Screen.DrawThickLine(center.x + forward.x, center.y + forward.y, center.x - forward.x * 0.55 + side.x, center.y - forward.y * 0.55 + side.y, 2, Color(80, 255, 120));
		Screen.DrawThickLine(center.x + forward.x, center.y + forward.y, center.x - forward.x * 0.55 - side.x, center.y - forward.y * 0.55 - side.y, 2, Color(80, 255, 120));
		Screen.DrawThickLine(center.x - forward.x * 0.55 + side.x, center.y - forward.y * 0.55 + side.y, center.x - forward.x * 0.55 - side.x, center.y - forward.y * 0.55 - side.y, 2, Color(80, 255, 120));

		if (MapInt('tuin_minimap_show_stats', 1))
		{
			string statistics = HuntModeUnlocked ?
				String.Format("K %d/%d   HUNT   I %d/%d   S %d/%d", level.killed_monsters, level.total_monsters,
					level.found_items, level.total_items, level.found_secrets, level.total_secrets) :
				String.Format("K %d/%d   I %d/%d   S %d/%d", level.killed_monsters, level.total_monsters,
					level.found_items, level.total_items, level.found_secrets, level.total_secrets);
			double statisticsScale = 1.60;
			int statisticsY = top + size + 5;
			Screen.Dim(Color(3, 5, 9), min(0.96, opacity + 0.18), left, statisticsY - 4, size, 23);
			Screen.DrawText(SmallFont, Font.CR_WHITE, left + 6, statisticsY, statistics,
				DTA_ScaleX, statisticsScale, DTA_ScaleY, statisticsScale);
		}
	}
}
