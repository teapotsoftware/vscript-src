
IncludeScript("butil")

SendToConsoleServer("mp_roundtime_hostage 4")
SendToConsoleServer("mp_free_armor 0")
SendToConsoleServer("mp_damage_scale_t_head 50")
SendToConsoleServer("mp_damage_scale_ct_head 50")
SendToConsoleServer("mp_death_drop_grenade 0")
SendToConsoleServer("mp_death_drop_gun 0")
SendToConsoleServer("mp_death_drop_healthshot 0")
SendToConsoleServer("mp_death_drop_breachcharge 0")
SendToConsoleServer("mp_death_drop_taser 0")
SendToConsoleServer("mp_autokick 0")
SendToConsoleServer("mp_friendlyfire 1")
SendToConsoleServer("mp_hostages_spawn_same_every_round 0")
SendToConsoleServer("mp_freezetime 0")
SendToConsoleServer("mp_taser_recharge_time 2")
SendToConsoleServer("ammo_grenade_limit_default 3")
SendToConsoleServer("ammo_grenade_limit_flashbang 3")
SendToConsoleServer("ammo_grenade_limit_total 999")
SendToConsoleServer("weapon_accuracy_nospread 1")
SendToConsoleServer("sv_hegrenade_damage_multiplier 2")

::BarricadeMaker <- EntityGroup[0]
::BigBarricadeMaker <- EntityGroup[1]
::ReinforcedWallMaker <- EntityGroup[2]
::ReinforcedHatchMaker <- EntityGroup[3]

::Lang <- {
	BARRICADE_START = "Barricading...",
	BARRICADE_BREAK = "Tearing down barricade...",
	REINFORCE_WALL = "Reinforcing wall...",
	REINFORCE_HATCH = "Reinforcing hatch...",
	REINFORCE_OUTOF = "Your team is out of reinforcements!",
	REINFORCE_NOTPREP = "You can only reinforce during the prep phase."
}

// DEF, ATK
::Operators <- [
	[
		{
			name = "Recruit",
			model = "tm_phoenix_varianta",
			weapons = ["sawedoff", "p250", "bayonet"],
			speed = 2
		},
		{
			name = "Smoke",
			model = "tm_anarchist_variantd", //"ctm_gendarmerie_variantb",
			weapons = ["nova", "cz75a", "bayonet", "decoy", "decoy", "decoy"],
			speed = 2
		},
		{
			name = "Pulse",
			model = "tm_leet_varianti",
			weapons = ["ump45", "fiveseven", "bayonet"],
			speed = 3
		},
		{
			name = "Doc",
			model = "tm_phoenix_varianti", //"ctm_swat_variantg",
			weapons = ["p90", "revolver", "bayonet", "healthshot", "healthshot", "healthshot"],
			speed = 1
		},
		{
			name = "Tachanka",
			model = "tm_balkan_variantf",
			weapons = ["negev", "glock", "bayonet", "molotov", "molotov"],
			speed = 1
		},
		{
			name = "Bandit",
			model = "tm_professional_varh", //"ctm_gsg9_variantc",
			weapons = ["mp7", "usp_silencer", "bayonet"],
			speed = 3
		},
	],
	[
		{
			name = "Recruit",
			model = "ctm_swat",
			weapons = ["m249", "usp_silencer", "bayonet", "flashbang", "flashbang", "flashbang"],
			speed = 2
		},
		{
			name = "Thatcher",
			model = "ctm_sas_variantg",
			weapons = ["sg556", "p250", "bayonet", "breachcharge"],
			speed = 2
		},
		{
			name = "Ash",
			model = "ctm_fbi_variantb",
			weapons = ["m4a1", "fiveseven", "bayonet", "breachcharge"],
			speed = 3
		},
		{
			name = "Twitch",
			model = "ctm_gendarmerie_variantc",
			weapons = ["famas", "revolver", "bayonet", "flashbang", "flashbang", "flashbang"],
			speed = 2
		},
		{
			name = "Fuze",
			model = "ctm_swat_varianth",
			weapons = ["ak47", "glock", "bayonet", "smokegrenade", "smokegrenade"],
			speed = 1
		},
		{
			name = "IQ",
			model = "ctm_fbi_variantb",
			weapons = ["aug", "usp_silencer", "bayonet", "flashbang", "flashbang", "flashbang"],
			speed = 3
		},
	]
]

::PLAYERMODEL_PREFIX <- "models/player/custom_player/legacy/"
::PLAYERMODEL_POSTFIX <- ".mdl"
::PLYMDL <- function(mdl) {return PLAYERMODEL_PREFIX + mdl + PLAYERMODEL_POSTFIX}

::SpawnTeleport <- function(ply)
{
	if (ply.GetName() == "")
	{
		SetOperator(ply, 0)
	}
}

::SetOperator <- function(ply, index)
{
	local tab = Operators[ply.GetTeam() - 2][index]

	StripWeapons(ply)
	EntFire("operator_equip_" + ply.GetTeam() + "_" + index, "Use", "", 0.0, ply)
	MeleeFixup()

	local health = 100 + ((2 - tab.speed) * 25)
	ply.SetMaxHealth(health)
	ply.SetHealth(health)

	local finalSpeed = 1 + (tab.speed - 2) * 0.2
	ModifySpeed(ply, finalSpeed)
	ply.__KeyValueFromFloat("gravity", 1 / finalSpeed)

	local mdl = PLYMDL(tab.model)
	ply.PrecacheModel(mdl)
	ply.SetModel(mdl)

	ply.__KeyValueFromString("targetname", "operator_" + index)

	CenterPrint(ply, "You picked " + tab.name)
}

::BreakNearby <- function(name, pos)
{
	if (!Entities.FindByNameNearest(name, pos, 2))
	{
		return false
	}
	local pieces = []
	local ent = null
	while (ent = Entities.FindByNameWithin(ent, name, pos, 2))
	{
		pieces.push(ent)
	}
	foreach (p in pieces)
	{
		EntFireHandle(p, "EnableMotion")
		EntFireHandle(p, "BecomeDebris")
		EntFireHandle(p, "Break", "", RandomFloat(0.5, 0.8))
	}
	return true
}

OnPostSpawn <- function()
{
	::IsPrepPhase <- false
	::SmokeMaker <- Entities.FindByName(null, "smoke_maker")

	// Build equippers for loadout
	for (local t = 2; t <= 3; t++)
	{
		for (local o = 0; o < 6; o++)
		{
			local equip = Entities.CreateByClassname("game_player_equip")
			equip.__KeyValueFromString("targetname", "operator_equip_" + t + "_" + o)
			equip.__KeyValueFromInt("spawnflags", 3)
			equip.__KeyValueFromInt("item_kevlar", 1)
			foreach (wep in Operators[t - 2][o].weapons)
				equip.__KeyValueFromInt("weapon_" + wep, 999)
		}
	}

	local precached = false
	local ent = null
	while (ent = Entities.Next(ent))
	{
		if (!precached)
		{
			precached = true
			ent.PrecacheModel("models/weapons/v_models/arms/pirate/v_pirate_watch.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/bare/v_bare_hands.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/anarchist/v_glove_anarchist.mdl")
			ent.PrecacheModel("models/props/coop_kashbah/toxic_canister/toxic_canister.mdl")
		}

		if (ent.ValidateScriptScope())
		{
			local ss = ent.GetScriptScope()

			if (ent.GetClassname() == "player")
			{
				ent.__KeyValueFromString("targetname", "")
				continue
			}

			switch (ent.GetName())
			{
				case "barricade_button":
				case "barricade_big_button":
					printl("initializing " + ent)
					ss.InputUse <- function()
					{
						if (!("LastPlace" in this))
						{
							this.LastPlace <- Time() - 2
						}
						if (activator.GetTeam() == T && Time() - this.LastPlace >= 1)
						{
							CenterPrint(activator, Entities.FindByNameNearest((self.GetName() == "barricade_button") ? "barricade" : "barricade_big", self.GetOrigin(), 2) == null ? Lang.BARRICADE_START : Lang.BARRICADE_BREAK)
							return true
						}
						return false
					}
					break

				case "soft_wall":
				case "soft_wall_90":
				case "hatch":
					printl("initializing " + ent)
					ss.InputUse <- function()
					{
						if (activator.GetTeam() == T)
						{
							if (!IsPrepPhase)
							{
								CenterPrint(activator, Lang.REINFORCE_NOTPREP)
								return false
							}
							if (ReinforcementsLeft <= 0)
							{
								CenterPrint(activator, Lang.REINFORCE_OUTOF)
								return false
							}
							ReinforcementsLeft--
							if (self.GetName() == "hatch")
							{
								CenterPrint(activator, Lang.REINFORCE_HATCH)
								ReinforcedHatchMaker.SpawnEntityAtLocation(self.GetOrigin(), Vector(0, 0, 0))
								EntFire("reinforcement_hatch", "Open")
								EntFireHandle(self, "Break")
							}
							else
							{
								CenterPrint(activator, Lang.REINFORCE_WALL)
								ReinforcedWallMaker.SpawnEntityAtLocation(self.GetOrigin(), Vector(0, self.GetName() == "soft_wall_90" ? 90 : 0, 0))
								EntFire("reinforcement_wall", "Open")
								BreakNearby(self.GetName(), self.GetOrigin())
							}
							return true
						}
						return false
					}
					break
			}
		}
	}

	HookToPlayerKill(function (ply) {
		EntFire("hud_hitmarker", "display", "", 0, ply)
	})

	HookToPlayerDeath(function (ply) {
		if (ply == null)
			return
		ply.__KeyValueFromString("targetname", "")
	})

	if (ScriptIsWarmupPeriod())
	{
		EntFire("start_teleport", "Enable")
		EntFire("arena_walls", "Kill")
		EntFire("arena_lid", "Kill")
	}
	else
	{
		local delay = 12
		ScriptPrintMessageChatAll("Preparation phase will begin in " + delay + " seconds.")
		ScriptPrintMessageChatAll("If you don't select an operator, you will be Recruit.")
		EntFire("start_teleport", "Enable", "", delay)
		EntFire("char_models", "Break", "", delay)
		EntFireHandle(self, "RunScriptCode", "StartPrepPhase()", delay)
	}
}

::StartPrepPhase <- function()
{
	::IsPrepPhase <- true
	::ReinforcementsLeft <- 5
	local delay = 20
	ScriptPrintMessageChatAll("Walls will fall in " + delay + " seconds.")
	ScriptPrintMessageChatTeam(T, "Defenders, prepare for attacker siege!")
	ScriptPrintMessageChatTeam(CT, "Attackers, prepare to siege!")
	EntFire("arena_walls", "Open", "", delay)
	EntFire("arena_lid", "Break", "", delay)
	EntFireHandle(self, "RunScriptCode", "::IsPrepPhase <- false", delay)
}

::AddHook("hostage_killed", "ultimate_siege", function(data) {
	printl(data.userid_player + " KILLED FUCKING HOSTAGE!!!")
})

Think <- function()
{
	local deleted = []
	local ent = null
	while (ent = Entities.Next(ent))
	{
		local cname = ent.GetClassname()
		switch (cname)
		{
			case "player":
				UserIDThink(ent)
				//printl(ent + " has userid " + GetUserID(ent))
				break

			case "decoy_projectile":
				if (ent.ValidateScriptScope())
				{
					local ss = ent.GetScriptScope()
					if (!("thrown_smoke" in ss))
					{
						ss.thrown_smoke <- true
						SetModelSafe(ent, "models/props/coop_kashbah/toxic_canister/toxic_canister.mdl")
					}
				}
				if (ent.GetVelocity().LengthSqr() == 0)
				{
					SmokeMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
					deleted.push(ent)
				}
				break

			case "flashbang_projectile":
			case "smokegrenade_projectile":
			case "molotov_projectile":
			case "hegrenade_projectile":
				break
		}
	}
	foreach (del in deleted)
	{
		del.Destroy()
	}
}

// AddHook()

::BarricadeFinished <- function(big = false)
{
	if (Time() - this.LastPlace >= 1 && !BreakNearby(big ? "barricade_big" : "barricade", self.GetOrigin()))
	{
		this.LastPlace <- Time()
		local maker = big ? BigBarricadeMaker : BarricadeMaker;
		maker.SpawnEntityAtLocation(self.GetOrigin(), self.GetAngles())
		self.EmitSound("Wood.ImpactHard")
	}
}
