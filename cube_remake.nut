
IncludeScript("butil")

SendToConsoleServer("mp_teammates_are_enemies 1")

// Compass:
// N is Y++
// S is Y--
// E is X++
// W is X--

// TODO: there are still problems with rotating stuff, especially the explosive barrels
// because sometimes they spawn inside players somehow???

::REGION_FLOOR_CENTER <- 1
::REGION_FLOOR_NW <- 2
::REGION_FLOOR_NE <- 4
::REGION_FLOOR_SW <- 8
::REGION_FLOOR_SE <- 16
::REGION_WALL_N <- 32
::REGION_WALL_E <- 64
::REGION_WALL_S <- 128
::REGION_WALL_W <- 256
::REGION_CEILING <- 512
::REGION_MAX <- 1024

::REGION_FLOOR <- REGION_FLOOR_CENTER + REGION_FLOOR_NW + REGION_FLOOR_NE + REGION_FLOOR_SW + REGION_FLOOR_SE
::REGION_WALLS <- REGION_WALL_N + REGION_WALL_E + REGION_WALL_S + REGION_WALL_W

::RegionRotations <- {
	[REGION_FLOOR_NE] = REGION_FLOOR_NW,
	[REGION_FLOOR_NW] = REGION_FLOOR_SW,
	[REGION_FLOOR_SW] = REGION_FLOOR_SE,
	[REGION_FLOOR_SE] = REGION_FLOOR_NE,
	[REGION_WALL_E] = REGION_WALL_N,
	[REGION_WALL_N] = REGION_WALL_W,
	[REGION_WALL_W] = REGION_WALL_S,
	[REGION_WALL_S] = REGION_WALL_E,
}

::PIECES <- {
	["2x2"] = [
		{
			name = "Standard",
			weight = 30,
			regions = [0, 0, 0, 0],
			rotatable = false
		},
		{
			name = "Glass",
			weight = 4,
			regions = [0, 0, 0, 0],
			rotatable = false
		},
		{
			name = "Park",
			weight = 2,
			regions = [
				REGION_FLOOR + REGION_WALL_S + REGION_WALL_E,
				REGION_FLOOR + REGION_WALL_S + REGION_WALL_W,
				REGION_FLOOR + REGION_WALL_N + REGION_WALL_W,
				REGION_FLOOR + REGION_WALL_N + REGION_WALL_E,
			],
			rotatable = true
		},
		{
			name = "Library",
			weight = 2,
			regions = [
				REGION_FLOOR + REGION_WALL_S + REGION_WALL_E,
				REGION_FLOOR + REGION_WALL_S + REGION_WALL_W,
				REGION_FLOOR + REGION_WALL_N + REGION_WALL_W,
				REGION_FLOOR + REGION_WALL_N + REGION_WALL_E,
			],
			PreSpawnInstance = function(cls, name) {
				return {model = "models/props/cs_office/bookshelf" + RandomInt(1, 3) + ".mdl"}
			},
			rotatable = true
		},
		{
			name = "Bricked",
			weight = 8,
			regions = [0, 0, 0, 0],
			rotatable = true
		},
		{
			name = "Medieval",
			weight = 4,
			regions = [0, 0, 0, 0],
			rotatable = false
		}
	],
	["1x1"] = [
		{
			name = "Olmec",
			weight = 2,
			region = REGION_FLOOR_SW
		},
		{
			name = "Explosive",
			weight = 3,
			region = REGION_FLOOR + REGION_WALL_W
		},
		{
			name = "Plushies",
			weight = 10,
			region = REGION_FLOOR_SW
		},
		{
			name = "Sentries",
			weight = 3,
			region = REGION_FLOOR
		},
		{
			name = "Camera",
			weight = 20,
			region = REGION_WALL_N
		},
		{
			name = "Vents",
			weight = 2,
			region = REGION_FLOOR + REGION_WALLS
		},
		{
			name = "Table",
			weight = 2,
			region = REGION_FLOOR_CENTER
		},
		{
			name = "Caesar",
			weight = 8,
			region = REGION_FLOOR_NE,
			PreSpawnInstance = function(cls, name) {
				local n = (RandomInt(0, 1) * 2) + 1
				return {model = "models/props/de_venice/loggetta_statue_" + n + "/loggetta_statue_" + n + ".mdl"}
			}
		},
		{
			name = "Radio",
			weight = 8,
			region = REGION_FLOOR_NW,
			PreSpawnInstance = function(cls, name) {
				if (cls == "ambient_generic") {
					local radio_songs = [
						"songloops/sfb_home_highfive_radio.wav",
						"songloops/sfb_fort_petrified_radio.wav",
						"songloops/sfb_gramatik_wayout_radio.wav",
						"songloops/sfb_gold_superman_radio.wav",
						"songloops/sfb_greenday_basketcase_radio.wav",
						"songloops/sfb_greta_blacksmoke_radio.wav",
						"songloops/sfb_soulchef_write_radio.wav",
						"songloops/sfb_kingo_cruisin_radio.wav",
						"songloops/sfb_tame_happen_radio.wav",
						"songloops/sfb_jake_atlas_radio.wav",
						"songloops/sfb_modest_salty_radio.wav",
						"songloops/sfb_uganda_gwa_radio.wav",
						"songloops/sfb_outkast_heyya_radio.wav",
					]
					return {message = radio_songs[RandomInt(0, radio_songs.len() - 1)]}
				}
				else {
					local radio_models = [
						"models/props/cs_italy/radio_wooden.mdl",
						"models/props/cs_office/radio.mdl",
						"models/props/de_inferno/hr_i/inferno_vintage_radio/inferno_vintage_radio.mdl",
					]
					return {model = radio_models[RandomInt(0, radio_models.len() - 1)]}
				}
			},
			PostSpawn = function(ents) {
				// stupid ass workaround
				foreach(name, ent in ents) {
					EntFire(name, "PlaySound")
					break
				}
			}
		},
		{
			name = "Walker",
			weight = 1,
			region = 0
		}
	]
}

::RotateSpecificRegion <- function(flag, times) {
	if (times == 0 || !(flag in RegionRotations))
		return flag

	return RotateSpecificRegion(RegionRotations[flag], times - 1)
}

::RotateRegion <- function(region, times) {
	local ret = 0
	for (local f = 1; f < REGION_MAX; f *= 2) {
		if (region & f) {
			if (f in RegionRotations) {
				ret += RotateSpecificRegion(f, times)
			}
			else {
				ret += f
			}
		}
	}

	return ret
}

::GetPotentialOrientations <- function(region, already_occupied) {
	local arr = []
	for (local i = 0; i < 4; i++) {
		if (!(already_occupied & RotateRegion(region, i)))
			arr.push(i)
	}

	return arr
}

::SelectWeightedIndex <- function(tab, already_occupied = 0) {
	local arr = []
	for (local i = 0; i < tab.len(); i++) {
		// region is already occupied
		if (already_occupied && (tab[i].region & already_occupied))
			continue

		for (local j = 0; j < tab[i].weight; j++)
			arr.push(i)
	}

	if (arr.len() == 0)
		return -1

	return arr[RandomInt(0, arr.len() - 1)]
}

::CubeWeapons <- [
	"glock",
	"hkp2000",
	"deagle",
	"elite",
	"mac10",
	"mp9",
	"p90",
	"nova",
	"xm1014",
	"ssg08",
	"awp",
	"m4a1",
	"m4a1",
	"m4a1_silencer",
	"m4a1_silencer",
	"ak47",
	"ak47",
]

::CubeKnives <- [
	"bayonet",
	"knife_karambit",
	"knife_m9_bayonet",
	"knife_css",
	"knife_butterfly",
	"knife_tactical",
	"knife_outdoor",
	"knife_survival_bowie",
]

OnPostSpawn <- function() {
	::CURRENT_WEAPON <- RandomInt(0, CubeWeapons.len())

	for (local s = 1; s < 3; s++) {
		local bucket = s + "x" + s
		for (local i = 0; i < PIECES[bucket].len(); i++) {
			// precache entity makers so FindByName isn't called repeatedly
			local maker = Entities.FindByName(null, "maker_" + bucket + "_" + i)
			if (maker != null)
				PIECES[bucket][i].maker <- maker

			// built-in point_template hooks for more control and variety
			local template = Entities.FindByName(null, "template_" + bucket + "_" + i)
			if (template == null || !template.ValidateScriptScope())
				continue

			local ss = template.GetScriptScope()
			if ("PreSpawnInstance" in PIECES[bucket][i]) {
				ss.PreSpawnInstance <- PIECES[bucket][i].PreSpawnInstance
				ss.PreSpawnInstance.bindenv(ss)

				// PostSpawn is only called if PreSpawnInstance exists
				if ("PostSpawn" in PIECES[bucket][i]) {
					ss.PostSpawn <- PIECES[bucket][i].PostSpawn
					ss.PostSpawn.bindenv(ss)
				}
			}
		}
	}

	// keep a history of what goes on in each cell
	// for debugging
	::CellHistory <- {}

	// table to save occupied regions for each room
	::OccupiedRegions <- {}
	for (local x = 0; x < 10; x++) {
		CellHistory[x] <- {}
		OccupiedRegions[x] <- {}
		for (local y = 0; y < 10; y++) {
			local flags = 0

			// spawning players dont get stuck
			if ((x % 2 == 0) && (y % 2 == 1))
				flags += REGION_FLOOR_CENTER

			// lights on the ceiling
			if ((x % 2) + (y % 2) == 1)
				flags += REGION_CEILING

			OccupiedRegions[x][y] <- flags
			CellHistory[x][y] <- [{region = flags, desc = "default setup"}]
		}
	}

	// 2x2 init
	local pieces = PIECES["2x2"]
	for (local x = 0; x < 5; x++) {
		for (local y = 0; y < 5; y++) {
			local piece = pieces[SelectWeightedIndex(pieces)]
			local r = piece.rotatable ? RandomInt(0, 3) : 0
			piece.maker.SpawnEntityAtLocation(Vector(512 * (x - 2), 512 * (y - 2), 0), Vector(0, 90 * r, 0))

			local regions = piece.regions
			local tx = x * 2, ty = y * 2
			local offsets = [[0, 1, 0, 1], [1, 1, 0, 0]]
			for (local j = 0; j < 4; j++) {
				local fx = tx + offsets[0][j], fy = ty + offsets[1][j]
				OccupiedRegions[fx][fy] = OccupiedRegions[fx][fy] | RotateRegion(regions[(j + r) % 4], r)
				CellHistory[fx][fy].push({region = OccupiedRegions[fx][fy], desc = "placed " + piece.name + " (" + ["north west", "north east", "south west", "south east"][j] + ")"})
			}
		}
	}

	// 1x1 init
	for (local n = 0; n < 3; n++) {
		for (local x = 0; x < 10; x++) {
			for (local y = 0; y < 10; y++) {
				if (RandomInt(1, 5) != 5)
					continue

				// stop early if there's nothing that could possibly fit here
				local already_occupied = OccupiedRegions[x][y]
				local i = SelectWeightedIndex(PIECES["1x1"], already_occupied)
				if (i == -1)
					continue

				local region = PIECES["1x1"][i].region
				local rots = GetPotentialOrientations(region, already_occupied)
				local r = rots[RandomInt(0, rots.len() - 1)]
				PIECES["1x1"][i].maker.SpawnEntityAtLocation(Vector((x * 256) - 1152, (y * 256) - 1152, 0), Vector(0, 90 * r, 0))

				// mark our regions as occupied
				OccupiedRegions[x][y] = already_occupied | RotateRegion(region, r)
				CellHistory[x][y].push({region = OccupiedRegions[x][y], desc = "placed " + PIECES["1x1"][i].name + " (orientation " + r + ")"})
			}
		}
	}

	HookToPlayerDeath(function(ply) {
		// SpeakResponse(ply, "paincrticialdeath", true)
		EntFireHandle(ply, "AddOutput", "effects 0")
		SetScopeVar(ply, "spawned", false)
	})
	HookToPlayerKill(function(ply) {
		if (ply.GetHealth() <= 0)
			return

		/*
		local lasttime = GetScopeVar(ply, "last_vo_time")
		if ((RandomInt(1, 3) == 1) && (lasttime == 0 || ((Time() - lasttime) > 5)))
			EntFireHandle(ply, "RunScriptCode", "SpeakResponse(self, \"laughshort\")", RandomFloat(0.6, 1))
		*/
	})

	ForEachPlayerAndBot(function(ply) {
		SetScopeVar(ply, "spawned", false)
	})
}

Think <- function() {
	ForEachPlayerAndBot(function(ply) {
		if (ply.GetHealth() > 0 && !GetScopeVar(ply, "spawned", false)) {
			local ldt = ["item_kevlar"]
			ldt.push("weapon_" + CubeWeapons[CURRENT_WEAPON])
			ldt.push("weapon_" + RandomFromArray(CubeKnives))
			GiveLoadout(ply, ldt)
			MeleeFixup()
			EntFireHandle(ply, "AddOutput", "effects 4")
			SetScopeVar(ply, "spawned", true)
		}
	})
}

// debugging helpers

::RegionNames <- {
	[1] = "FLOOR CENTER",
	[2] = "NW CORNER",
	[4] = "NE CORNER",
	[8] = "SW CORNER",
	[16] = "SE CORNER",
	[32] = "NORTH WALL",
	[64] = "EAST WALL",
	[128] = "SOUTH WALL",
	[256] = "WEST WALL",
	[512] = "CEILING"
}

::PrintRegion <- function(reg) {
	printl(reg + ":")
	for (local f = 1; f < REGION_MAX; f *= 2) {
		if (reg & f) {
			if (f in RegionNames)
				printl(f + " (" + RegionNames[f] + ")")
			else
				printl(f)
		}
	}
}

::PrintCellHistory <- function(x, y) {
	printl("cell history for (" + x + "," + y + ")")
	local h = CellHistory[x][y]
	for (local i = 0; i < h.len(); i++) {
		printl("[" + i + "] " + h[i].desc)
		PrintRegion(h[i].region)
	}
}

::Goto <- function(x, y) {
	LocalPlayer().SetOrigin(Vector((x * 256) - 1152, (y * 256) - 1152, 0))
	PrintCellHistory(x, y)
}

::Snap <- function() {
	local pos = LocalPlayer().GetOrigin()
	Goto(round((pos.x + 1152) / 256), round((pos.y + 1152) / 256))
}

// voice responses

/*
::ModelClasses <- {
	["models/player/custom_player/legacy/tm_jumpsuit_varianta.mdl"] = "demoman",
	["models/player/custom_player/legacy/tm_jumpsuit_variantb.mdl"] = "soldier",
	["models/player/custom_player/legacy/tm_jumpsuit_variantc.mdl"] = "heavy",
}

::SpeakResponse <- function(ply, name, can_be_dead = false) {
	local mdl = ply.GetModelName()
	printl(mdl)
	if (!(mdl in ModelClasses))
		return

	if (!can_be_dead && !LivingPlayer(ply))
		return

	local ambname = "vo_" + ply.entindex()
	local amb = Entities.FindByName(null, ambname)
	if (amb == null) {
		amb = Entities.CreateByClassname("ambient_generic")
		amb.__KeyValueFromString("targetname", ambname)
	}

	name = "tf2/vo/" + ModelClasses[mdl] + "_" + name + "0" + RandomInt(1, 3) + ".mp3"
	amb.__KeyValueFromString("message", name)

	amb.SetOrigin(ply.GetOrigin() + Vector(0, 0, 64))
	EntFireHandle(amb, "PlaySound")

	SetScopeVar(ply, "last_vo_name", name)
	SetScopeVar(ply, "last_vo_time", Time())
}

Precache <- function() {
	local world = Entities.First()
	for (local i = 1; i < 4; i++)
		foreach (cls in ["heavy", "demoman", "soldier"])
			foreach (snd in ["laughshort", "paincrticialdeath", "painsevere", "painsharp"])
				world.PrecacheSoundScript("tf2/vo/" + cls + "_" + snd + "0" + i + ".mp3")
}

AddHook("player_hurt", "HeavyHurtVoiceLines", function(data) {
	local ply = data.userid_player
	if (ply == null || ply.GetHealth() <= 0)
		return

	local dmg = data.dmg_health
	if (dmg <= 0)
		return

	local max = ply.GetMaxHealth()
	if (dmg >= (max * 0.8)) {
		SpeakResponse(ply, "painsevere")
	} else {
		local lasttime = GetScopeVar(ply, "last_vo_time")
		local curtime = Time()
		if (dmg >= (max * 0.5) || (lasttime != 0 && (curtime - lasttime) > 2))
			SpeakResponse(ply, "painsharp")
	}
})
*/
