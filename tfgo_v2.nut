
IncludeScript("butil")

/*
[x] scout model
models/player/custom_player/legacy/tm_leet_variantb.mdl
models/player/tfgo_v2/legacy/tm_leet_scout_red_____.mdl

[x] soldier model
models/player/custom_player/legacy/ctm_swat.mdl
models/player/tfgo_v2/legacy/ctm_swat_soldr.mdl
models/player/tfgo_v2/legacy/ctm_swat_soldb.mdl

[ ] pyro model
models/player/custom_player/legacy/tm_separatist.mdl
models/player/tfgo_v2/legacy/tm_separatist_pyror.mdl
models/player/tfgo_v2/legacy/tm_separatist_pyrob.mdl

[x] demo model
models/player/custom_player/legacy/tm_jungle_raider_variantd.mdl
models/player/tfgo_v2/legacy/tm_jungle_raider_demoman_red___.mdl

[x] heavy model
models/player/custom_player/legacy/ctm_heavy.mdl
models/player/tfgo_v2/legacy/ctm_heavy_red__.mdl

[x] engineer model
models/player/custom_player/legacy/tm_balkan_variantc.mdl
models/player/tfgo_v2/legacy/tm_balkan_engineer_red__.mdl

[ ] medic model
models/player/custom_player/legacy/tm_balkan_varianth.mdl
models/player/tfgo_v2/legacy/tm_balkan_medic_red_____.mdl

[x] sniper model
models/player/custom_player/legacy/ctm_st6_variantn.mdl
models/player/tfgo_v2/legacy/ctm_st6_sniper_red____.mdl

[x] spy model
models/player/custom_player/legacy/tm_professional_var1.mdl
models/player/tfgo_v2/legacy/tm_professional_spy_red___.mdl
*/

::ClassList <- []

::AddClass <- function(cls) {
	if (!("hp" in cls)) {
		cls.hp <- 100
	}
	ClassList.push(cls)
	return ClassList.len() - 1
}

::TF_SCOUT <- AddClass({
	name = "Scout",
	mdl = ["models/player/tfgo_v2/legacy/tm_leet_scout_red_____.mdl", "models/player/tfgo_v2/legacy/tm_leet_scout_blu_____.mdl"],
	loadout = ["weapon_p90", "weapon_fiveseven", "weapon_knife_karambit", "weapon_bumpmine"]
})
::TF_SOLDIER <- AddClass({
	name = "Soldier",
	mdl = ["models/player/tfgo_v2/legacy/ctm_swat_soldr.mdl", "models/player/tfgo_v2/legacy/ctm_swat_soldb.mdl"],
	loadout = ["item_assaultsuit", "weapon_ak47", "weapon_glock", "weapon_knife_m9_bayonet", "weapon_hegrenade", "weapon_hegrenade", "weapon_hegrenade"]
})
::TF_DEMOMAN <- AddClass({
	name = "Demoman",
	mdl = ["models/player/tfgo_v2/legacy/tm_jungle_raider_demoman_red___.mdl", "models/player/tfgo_v2/legacy/tm_jungle_raider_demoman_blu___.mdl"],
	loadout = ["item_kevlar", "weapon_m4a1", "weapon_knife_stiletto", "weapon_breachcharge"]
})
::TF_HEAVY <- AddClass({
	name = "Heavy",
	mdl = ["models/player/tfgo_v2/legacy/ctm_heavy_red__.mdl", "models/player/tfgo_v2/legacy/ctm_heavy_blu__.mdl"],
	loadout = ["item_assaultsuit", "weapon_negev", "weapon_glock", "weapon_knife_outdoor"],
	hp = 200
})
::TF_ENGINEER <- AddClass({
	name = "Engineer",
	mdl = ["models/player/tfgo_v2/legacy/tm_balkan_engineer_red__.mdl", "models/player/tfgo_v2/legacy/tm_balkan_engineer_blu__.mdl"],
	loadout = ["weapon_nova", "weapon_fiveseven", "weapon_spanner"]
})
::TF_SNIPER <- AddClass({
	name = "Sniper",
	mdl = ["models/player/tfgo_v2/legacy/ctm_st6_sniper_red____.mdl", "models/player/tfgo_v2/legacy/ctm_st6_sniper_blu____.mdl"],
	loadout = ["weapon_awp", "weapon_elite", "weapon_knife_survival_bowie"]
})
::TF_SPY <- AddClass({
	name = "Spy",
	mdl = ["models/player/tfgo_v2/legacy/tm_professional_spy_red___.mdl", "models/player/tfgo_v2/legacy/tm_professional_spy_blu___.mdl"],
	loadout = ["weapon_m4a1_silencer", "weapon_deagle", "weapon_knife_butterfly", "weapon_smokegrenade"]
})

::ChangeClass <- function(ply) {

}

::ChooseClass <- function(ply, clsi) {
	SetPlayerClass(ply, clsi)
	// tP?
}

::ClassEquips <- []
::CloakSpeedMod <- null
::BuildGameUIIndex <- 0
::BuildGameUIs <- []
::BuilderList <- {}
::EntityMakers <- {}
::BuildingPlayers <- []

OnPostSpawn <- function() {
	SendToConsoleServer("mp_death_drop_gun 0")
	foreach (cls in ClassList) {
		local gpe = Entities.CreateByClassname("game_player_equip")
		foreach (wep in cls.loadout) {
			gpe.__KeyValueFromString(wep, 999)
		}
		ClassEquips.push(gpe)
	}
	::CloakSpeedMod = Entities.CreateByClassname("player_speedmod")
	CloakSpeedMod.__KeyValueFromInt("spawnflags", 64)
	for (::TEMP_I <- 0; TEMP_I < 8; TEMP_I++) {
		local ent = Ent("build_gameui_" + TEMP_I)
		if (ent.ValidateScriptScope()) {
			local ss = ent.GetScriptScope()
			ss.PressedLeft <- function() {BuildInput(TEMP_I, -1)}
			ss.PressedRight <- function() {BuildInput(TEMP_I, 1)}
			ent.ConnectOutput("PressedMoveLeft", "PressedLeft")
			ent.ConnectOutput("PressedMoveRight", "PressedRight")
			
		}
		BuildGameUIs.push(ent)
		BuilderList[TEMP_I] <- null
	}
	delete ::TEMP_I
	local ent = null
	while (ent = Entities.Next(ent)) {
		local cls = ent.GetClassname()
		local name = ent.GetName()

		if (cls == "point_template" && ent.ValidateScriptScope()) {
			local ss = ent.GetScriptScope()
			if (name.len() > 18 && name.slice(0, 18) == "template_building_") {
				ss.PreSpawnInstance <- function(cls, tgt) {}
				ss.PostSpawn <- function(ents) {
					if (BuildingPlayers.len() > 0) {
						local ply = BuildingPlayers.pop()
						if (ply.ValidateScriptScope()) {
							local ss2 = ply.GetScriptScope()
							local bldgid = name.slice(18, name.len())
							if (ss2[bldgid] != null) {
								foreach (ent in ss2[bldgid]) {
									EntFireHandle(ent, "FireUser4")
								}
							}
							ss2[bldgid] <- ents
						}
					}
				}
			}
			ss.entmaker <- Entities.CreateByClassname("env_entity_maker")
			ss.entmaker.__KeyValueFromString("EntityTemplate", name)
			EntityMakers[name] <- ss.entmaker
		}
	}
}

::Resupply <- function(ply) {
	if (!ply.ValidateScriptScope()) {
		return
	}
	local ss = ply.GetScriptScope()
	local clsi = ss.tf_class
	local cls = ClassList[clsi]
	EntFireHandle(ClassEquips[clsi], "Use", "", 0, ply)
	SetHealthAndMaxHealth(ply, cls.hp)
	ply.SetModel(cls.mdl[ply.GetTeam() - 2])
	MeleeFixup()
}

::GetPlayerClass <- function(ply) {
	if (!ply.ValidateScriptScope()) {
		return -1
	}
	return ply.GetScriptScope().tf_class
}

::SetPlayerClass <- function(ply, clsi) {
	if (!ply.ValidateScriptScope()) {
		return
	}
	ply.GetScriptScope().tf_class <- clsi
	local cls = ClassList[i]
	ply.SetModel(cls.mdl[ply.GetTeam() - 2])
}

::SetCloak <- function(ply, b) {
	if (!ply.ValidateScriptScope()) {
		return
	}
	local ss = ply.GetScriptScope()
	ss.tf_cloaked <- b
	EntFireHandle(ply, (ss.tf_cloaked ? "Dis" : "En") + "ableDraw")
	CenterPrint(ply, "Cloak O" + (ss.tf_cloaked ? "N" : "FF"))
	EntFireHandle(CloakSpeedMod, "ModifySpeed", ss.tf_cloaked ? 1.2 : 1.0, 0, ply)
}

::ToggleCloak <- function(ply) {
	if (!ply.ValidateScriptScope()) {
		return
	}
	local ss = ply.GetScriptScope()
	if (!("tf_cloaked" in ss)) {
		ss.tf_cloaked <- false
	}
	SetCloak(ply, !ss.tf_cloaked)
}

::BuildingList <- [
	{
		id = "sentry",
		name = "Sentry Gun",
		maker = null
	}, {
		id = "dispenser",
		name = "Dispenser",
		maker = null
	}, {
		id = "spawn",
		name = "Spawn Pad",
		maker = null
	}
]

// called from game_ui outputs
::BuildInput <- function(i, n) {
	CycleBuildUI(BuilderList[i], n)
}

::CycleBuildUI <- function(ply, i) {
	if (!ply.ValidateScriptScope()) {
		return
	}
	local ss = ply.GetScriptScope()
	if (!("tf_buildings" in ss)) {
		ss.tf_buildings <- {}
		foreach (bldg in BuildingList) {
			ss.tf_buildings[bldg.id] <- null
		}
	}
	local n = BuildingList.len()
	ss.tf_build_index = (n + ss.tf_build_index + i) % n
	local bldg = BuildingList[ss.tf_build_index]
	local built = ss.tf_buildings[ss.tf_build_index] != null
	CenterPrint(ply, "CONSTRUCTION PDA\n" + bldg.name + (built ? " - BUILT" : "") + "\nThrow wrench to " + (built ? "destroy" : "build"))
}

Think <- function() {
	local ent = null
	while (ent = Entities.Next(ent)) {
		local cls = ent.GetClassname()
		local name = ent.GetName()

		if (cls == "player") {
			UserIDThink(ent)
		} else if (cls == "smokegrenade_projectile") {
			QueueForDeletion(ent)
			ToggleCloak(ent.GetOwner())
		} else if (cls == "predicted_viewmodel") {
			local ply = ent.GetOwner()
			if (ply != null && ply.ValidateScriptScope()) {
				local tf_cls = GetPlayerClass(ply)
				if (tf_cls == TF_ENGINEER) {
					local ss = ply.GetScriptScope()
					local isbuild = ("tf_build" in ss)
					local shouldbuild = (ent.GetModelName() == "models/weapons/v_spanner.mdl")
					if (isbuild != shouldbuild) {
						if (shouldbuild) {
							EntFireHandle(BuildGameUIs[BuildGameUIIndex], "Activate", "", 0, ply)
							BuilderList[BuildGameUIIndex] = ply
							BuildGameUIIndex++
							ss.tf_build <- true
							ss.tf_build_index <- 0
							CycleBuildUI(ply, 0)
						} else {
							delete ss.tf_build
						}
					}
				}
			}
		} else if (cls == "weapon_knifegg" && ent.GetModelName() == "models/weapon/w_spanner_dropped.mdl") {
			local ply = ent.GetOwner()
			if (ply != null && ply.ValidateScriptScope()) {
				local ss = ply.GetScriptScope()
				local bldgi = ss.tf_build_index
				local bldg = BuildingList[bldgi]
				if (ss.buildings[bldgi] == null) {
					local plypos = ply.GetOrigin()
					local dir = (ent.GetOrigin() - plypos).Norm()
					dir.z = 0
					local pos = plypos + (dir * 50)
					BuildingPlayers.push(ply)
					EntityMakers[bldg.id].SpawnEntityAtLocation(pos, Vector(0, 0, 0))
				} else {
					foreach (ent in ss.buildings[bldgi]) {
						EntFireHandle(ent, "FireUser4")
					}
					ss.buildings[bldgi] = null
					CenterPrint(ply, bldg.name + " destroyed!")
				}
				GiveWeapon(ply, "weapon_spanner")
				MeleeFixup()
			}
			QueueForDeletion(ent)
		}
	}
	FlushDeletionQueue()
}

::Debug_ProjTest <- function() {
	local e = null
	while (e = Entities.FindByClassname(e, "*_projectile")) {
		printl(e.GetClassname())
	}
}
