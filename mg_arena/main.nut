
/*
** Author: Nick B (https://steamcommunity.com/id/sirfrancisbillard/)
** Description:
**     Main game handler for a rainbow 6 siege-like map.
*/

IncludeScript("butil")

SendToConsoleServer("mp_roundtime_hostage 4")
SendToConsoleServer("mp_free_armor 0")
SendToConsoleServer("mp_damage_scale_t_body 1.2")
SendToConsoleServer("mp_damage_scale_t_head 50")
SendToConsoleServer("mp_damage_scale_ct_body 1.2")
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
::WireMaker <- EntityGroup[4]
::ShieldMaker <- EntityGroup[5]
::ADSMaker <- EntityGroup[6]
::SmokeMaker <- EntityGroup[7]
::ClaymoreMaker <- EntityGroup[8]
::ClusterMaker <- EntityGroup[9]
::ClusterNadeMaker <- EntityGroup[10]

::ADS_TARGET_LIST <- ["hegrenade", "flashbang", "smokegrenade", "tagrenade"]

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
			weapons = ["sawedoff", "p250", "bayonet", "tagrenade", "bumpmine"],
			speed = 2
		},
		{
			name = "Smoke",
			model = "tm_anarchist_variantd", //"ctm_gendarmerie_variantb",
			weapons = ["mac10", "cz75a", "bayonet", "decoy", "decoy", "decoy", "tagrenade"],
			speed = 2
		},
		{
			name = "Pulse",
			model = "tm_leet_varianti",
			weapons = ["ump45", "fiveseven", "bayonet", "bumpmine"],
			speed = 3
		},
		{
			name = "Doc",
			model = "tm_phoenix_varianti", //"ctm_swat_variantg",
			weapons = ["p90", "revolver", "bayonet", "healthshot", "healthshot", "healthshot", "bumpmine"],
			speed = 1
		},
		{
			name = "Tachanka",
			model = "tm_balkan_variantf",
			weapons = ["negev", "glock", "bayonet", "molotov", "molotov", "tagrenade"],
			speed = 1
		},
		{
			name = "Jager",
			model = "tm_professional_varh", //"ctm_gsg9_variantc",
			weapons = ["m4a1", "usp_silencer", "bayonet", "bumpmine"],
			speed = 3
		},
	],
	[
		{
			name = "Recruit",
			model = "ctm_swat",
			weapons = ["m249", "usp_silencer", "bayonet", "smokegrenade", "smokegrenade", "flashbang", "flashbang", "flashbang"],
			speed = 2
		},
		{
			name = "Thatcher",
			model = "ctm_sas_variantg",
			weapons = ["sg556", "p250", "bayonet", "breachcharge", "decoy", "decoy"],
			speed = 2
		},
		{
			name = "Ash",
			model = "ctm_swat_variante",
			weapons = ["m4a1", "fiveseven", "bayonet", "breachcharge"],
			speed = 3
		},
		{
			name = "Twitch",
			model = "ctm_gendarmerie_variantc",
			weapons = ["famas", "revolver", "bayonet", "tagrenade"],
			speed = 2
		},
		{
			name = "Fuze",
			model = "ctm_swat_varianth",
			weapons = ["ak47", "glock", "bayonet", "smokegrenade", "smokegrenade", "bumpmine"],
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

::SpawnTeleport <- function(ply) {
	if (ply.GetName() == "")
		SetOperator(ply, 0, false)

	GiveOperatorLoadout(ply)
}

::GiveOperatorLoadout <- function(ply) {
	local id = ply.GetName().slice(9)
	printl("op id: " + ply.GetName().slice(9))
	StripWeapons(ply)
	EntFire("operator_equip_" + ply.GetTeam() + "_" + id, "Use", "", 0.0, ply)
	MeleeFixup()
}

::SetOperator <- function(ply, index, showMsg = true)
{
	if (ply.GetName() == "operator_" + index)
		return

	local tab = Operators[ply.GetTeam() - 2][index]

	// StripWeapons(ply)
	// EntFire("operator_equip_" + ply.GetTeam() + "_" + index, "Use", "", 0.0, ply)
	// MeleeFixup()

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

	if (showMsg)
		CenterPrint(ply, "You picked " + tab.name)

	ply.SetOrigin(Vector(3016 * (ply.GetTeam() == CT ? -1 : 1), 0, 1))
}

::BreakNearby <- function(name, pos) {
	if (!Entities.FindByNameNearest(name, pos, 2)) {
		return false
	}
	local pieces = []
	local ent = null
	while (ent = Entities.FindByNameWithin(ent, name, pos, 2)) {
		pieces.push(ent)
	}
	foreach (p in pieces) {
		EntFireHandle(p, "EnableMotion")
		EntFireHandle(p, "BecomeDebris")
		EntFireHandle(p, "Break", "", RandomFloat(0.5, 0.8))
	}
	return true
}

OnPostSpawn <- function() {
	::IsPrepPhase <- false

	// Build equippers for loadout
	for (local t = 2; t <= 3; t++) {
		for (local o = 0; o < 6; o++) {
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
	while (ent = Entities.Next(ent)) {
		if (!precached) {
			precached = true
			ent.PrecacheModel("models/weapons/v_models/arms/pirate/v_pirate_watch.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/bare/v_bare_hands.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/anarchist/v_glove_anarchist.mdl")
			ent.PrecacheModel("models/props/coop_kashbah/toxic_canister/toxic_canister.mdl")
		}

		if (ent.GetClassname() == "player") {
			ent.__KeyValueFromString("targetname", "")
			StripWeapons(ent)
			SetOutside(ent, false)
			continue
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

	if (ScriptIsWarmupPeriod()) {
		EntFire("start_teleport", "Enable")
		EntFire("arena_walls", "Kill")
		EntFire("arena_lid", "Kill")
	} else {
		local delay = 12
		ScriptPrintMessageChatAll("Preparation phase will begin in " + delay + " seconds.")
		ScriptPrintMessageChatAll("If you don't select an operator, you will be Recruit.")
		EntFire("start_teleport", "Enable", "", delay)
		EntFire("char_models", "Break", "", delay)
		EntFireHandle(self, "RunScriptCode", "StartPrepPhase()", delay)
	}
}

::StartPrepPhase <- function() {
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

::MAX_Ts_OUTSIDE <- 8

Think <- function() {
	local plyOutsideIndex = 0

	local ent = null
	while (ent = Entities.Next(ent)) {
		local cname = ent.GetClassname()
		switch (cname) {
			case "player":
				UserIDThink(ent)
				if (ent.GetHealth() > 0 && ent.GetTeam() == T && ent.ValidateScriptScope()) {
					local ss = ent.GetScriptScope()
					if ("is_outside" in ss && ss.is_outside) {
						EntFire("hud_youreoutside", "display", "", 0, ent)
						if (plyOutsideIndex < MAX_Ts_OUTSIDE) {
							local glowEnt = Entities.FindByName(null, "ply_outside_sprite_" + plyOutsideIndex)
							glowEnt.SetOrigin(ent.GetOrigin())
							local ang = ent.GetAngles()
							glowEnt.SetAngles(ang.x, ang.y, ang.z)
							EntFireHandle(glowEnt, "SetGlowEnabled")
							plyOutsideIndex++
						}
					}
				}
				break

			case "decoy_projectile":
				if (ent.ValidateScriptScope()) {
					local ss = ent.GetScriptScope()
					if (!("model_fixed" in ss)) {
						ss.model_fixed <- true
						local owner = ent.GetOwner()
						if (owner.GetTeam() == T) {
							SetModelSafe(ent, "models/props/coop_kashbah/toxic_canister/toxic_canister.mdl")
						} else {
							SetModelSafe(ent, "models/weapons/w_eq_sensorgrenade_thrown.mdl")
						}
					}
				}
				if (ent.GetVelocity().LengthSqr() == 0) {
					local owner = ent.GetOwner()
					if (owner != null) {
						if (owner.GetTeam() == T) {
							switch (owner.GetName()) {
								case "operator_1":
									SmokeMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
									DispatchParticleEffect("explosion_hegrenade_brief", ent.GetOrigin(), Vector(-1, 0, 0))
									ent.EmitSound("BaseGrenade.Explode")
									break
							}
						} else {
							switch (owner.GetName()) {
								case "operator_1":
									local gadget = null
									while (gadget = Entities.FindInSphere(gadget, ent.GetOrigin(), 100)) {
										if (gadget.ValidateScriptScope()) {
											local ss = gadget.GetScriptScope()
											if ("DefenderGadget" in ss) {
												ss.LastDisable <- Time()
												gadget.EmitSound("radio_computer.break")
											}
										}
									}
									DispatchParticleEffect("explosion_hegrenade_brief", ent.GetOrigin(), Vector(-1, 0, 0))
									DispatchParticleEffect("firework_crate_explosion_01", ent.GetOrigin(), ent.GetOrigin())
									ent.EmitSound("BaseGrenade.Explode")
									ent.EmitSound("ambient.electrical_random_zap_2")
									break
							}
						}
					}
					QueueForDeletion(ent)
				}
				break

			case "bumpmine_projectile":
				if (ent.ValidateScriptScope()) {
					local ss = ent.GetScriptScope()
					if (!("last_angles" in ss)) {
						ss.last_angles <- ent.GetAngles()
					} else if ((ss.last_angles - ent.GetAngles()).LengthSqr() < 0.1) {
						local owner = ent.GetOwner()
						if (owner != null) {
							ent.StopSound("Survival.BumpIdle")
							ent.StopSound("Survival.BumpMineSetArmed")
							QueueForDeletion(ent)
							if (owner.GetTeam() == T) {
								switch (owner.GetName()) {
									case "operator_5":
										ADSMaker.SpawnEntityAtLocation(ent.GetOrigin(), ent.GetAngles())
										break

									default:
										WireMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
										break
								}
							} else {
								switch (owner.GetName()) {
									case "operator_4":
										::ClusterChargePlacer <- owner
										ClusterMaker.SpawnEntityAtLocation(ent.GetOrigin(), ent.GetAngles())
										break

									default:
										WireMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
										break
								}
								
							}
						}
					} else {
						ss.last_angles <- ent.GetAngles()
					}
				}
				break

			case "tagrenade_projectile":
				if (ent.GetVelocity().Length() == 0) {
					local owner = ent.GetOwner()
					if (owner != null) {
						ent.StopSound("Sensor.Activate")
						if (owner.GetTeam() == T) {
							switch (owner.GetName()) {
								default:
									local ang = owner.GetAngles()
									ang.x = 0
									ShieldMaker.SpawnEntityAtLocation(ent.GetOrigin(), ang)
									break
							}
						} else {
							switch (owner.GetName()) {
								default:
									local ang = owner.GetAngles()
									ang.x = 0
									ClaymoreMaker.SpawnEntityAtLocation(ent.GetOrigin(), ang)
									break
							}
						}
						QueueForDeletion(ent)
					}
				}
				break

			case "flashbang_projectile":
			case "smokegrenade_projectile":
			case "molotov_projectile":
			case "hegrenade_projectile":
				break
		}
	}
	FlushDeletionQueue()

	if (plyOutsideIndex > 0) {
		local p = null
		while (p = Entities.FindByClassname(p, "player")) {
			if (p.GetTeam() == CT)
				EntFire("hud_enemyoutside", "display", "", 0, p)
		}
	}

	for (local i = plyOutsideIndex; i < MAX_Ts_OUTSIDE; i++)
		EntFire("ply_outside_sprite_" + i, "SetGlowDisabled")

	// mark ADS target grenades (see: ads.nut)
	foreach (nadetype in ADS_TARGET_LIST) {
		EntFire(nadetype + "_projectile", "addoutput", "targetname ads_target")
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

::SetOutside <- function(ply, isOutside) {
	if (ply.ValidateScriptScope())
		ply.GetScriptScope().is_outside <- isOutside
}
