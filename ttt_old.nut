
::HSMaker <- EntityGroup[0]
::JestMaker <- EntityGroup[1]

// primary
::WEP_M16 <- "weapon_galilar"
::WEP_HUGE <- "weapon_m249"
::WEP_MAC10 <- "weapon_mac10"
::WEP_RIFLE <- "weapon_ssg08"
::WEP_SHOTGUN <- "weapon_xm1014"

// secondary
::WEP_GLOCK <- "weapon_glock"
::WEP_PISTOL <- "weapon_tec9"
::WEP_DEAGLE <- "weapon_deagle"

// nades
::WEP_FRAG <- "weapon_hegrenade"
::WEP_SMOKE <- "weapon_smokegrenade"
::WEP_FLASHBANG <- "weapon_flashbang"

::WEPLIST <- ["m16", "huge", "mac10", "rifle", "shotgun", "deagle", "pistol", "glock"]

::ClampValue <- function(val, min, max)
{
	if (val > max)
	{
		return max
	}
	if (val < min)
	{
		return min
	}
	return val
}

::EntFireHandle <- function(target, input, value = "", delay = 0.0, activator = null, caller = null)
{
	EntFireByHandle(target, input, value, delay, activator, caller)
}

::CenterPrint <- function(ply, msg)
{
	local messager = Entities.CreateByClassname("env_message")
	messager.__KeyValueFromString("message", msg)
	EntFireByHandle(messager, "ShowMessage", "", 0.0, ply, null)
	EntFireByHandle(messager, "Kill", "", 0.1, null, null)
}

::CenterPrintTest <- function(ply, msg)
{
	local messager = Entities.CreateByClassname("game_text")
	messager.__KeyValueFromString("message", msg)
	messager.__KeyValueFromString("color", "100 100 100")
	messager.__KeyValueFromString("color2", "240 110 0")
	messager.__KeyValueFromInt("x", -1)
	messager.__KeyValueFromInt("y", -1)
	messager.__KeyValueFromInt("effect", 0)
	messager.__KeyValueFromInt("channel", 1)
	EntFireByHandle(messager, "Display", "", 0.0, ply, null)
	EntFireByHandle(messager, "Kill", "", 0.1, null, null)
}

::GiveWeapon <- function(ply, weapon, ammo = 999)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 1)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	EntFireByHandle(equip, "Kill", "", 0.1, null, null)
	ply.StopSound("Player.DamageKevlar")
}

::RefillAmmo <- function(ply)
{
	local ammo = Entities.CreateByClassname("point_give_ammo")
	EntFireByHandle(ammo, "GiveAmmo", "", 0, ply, null)
	EntFireByHandle(ammo, "Kill", "", 0.1, null, null)
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireByHandle(strip, "Strip", "", 0.0, ply, null)
	EntFireByHandle(strip, "Kill", "", 0.1, null, null)
}

::GiveLoadout <- function(ply, array)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 3)
	equip.__KeyValueFromInt("item_assaultsuit", 1)
	foreach (wep in array)
	{
		equip.__KeyValueFromInt(wep, 999)
	}
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	EntFireByHandle(equip, "Kill", "", 0.1, null, null)
}

::ModifySpeed <- function(ply, speed)
{
	local speedmod = Entities.CreateByClassname("player_speedmod")
	EntFireByHandle(speedmod, "ModifySpeed", speed.tostring(), 0.0, ply, null)
	EntFireByHandle(speedmod, "Kill", "", 0.1, null, null)
}

::MeleeFixup <- function()
{
	foreach (wep in ["knife", "fists", "melee"])
	{
		EntFire("weapon_" + wep, "addoutput", "classname weapon_knifegg")
	}
}

::INNOCENT <- 0
::TRAITOR <- 1
::DETECTIVE <- 2
::JESTER <- 3

::ROLE_NAME <- ["innocent", "traitor", "detective", "jester"]

::Alive <- function(ply) {return ply.GetHealth() > 0}
::LivingPlayer <- function(ent) {return ent.GetClassname() == "player" && ent.GetHealth() > 0}
::IsRole <- function(ply, role) {return GetRole(ply) == role}
::SetRole <- function(ply, role) {ply.__KeyValueFromString("targetname", "player_" + ROLE_NAME[role])}

::GetRole <- function(ply) {
	switch (ply.GetName())
	{
		case "player_traitor":
			return TRAITOR

		case "player_detective":
			return DETECTIVE

		case "player_jester":
			return JESTER

		default:
			return INNOCENT
	}
}

::hs_timer <- 0
::hud_timer <- 0
::role_timer <- 0

Think <- function()
{
	local oops = true
	local tac = null
	while (tac = Entities.FindByClassname(tac, "tagrenade_projectile"))
	{
		if (tac.GetVelocity().Length() == 0 && oops)
		{
			local owner = tac.GetOwner()
			if (owner != null)
			{
				oops = false
				HSMaker.SpawnEntityAtLocation(tac.GetOrigin(), Vector(0, 0, 0))
				tac.StopSound("Sensor.Activate")
				tac.Destroy()
				EntFire("health_station", "color", "100 100 255")
			}
		}
		else if (tac.ValidateScriptScope())
		{
			local ss = tac.GetScriptScope()
			if (!("microwave" in ss))
			{
				ss.microwave <- true
				tac.SetModel("models/props/cs_office/microwave.mdl")
				tac.__KeyValueFromString("rendercolor", "100 100 255")
			}
		}
	}
	::hs_timer++
	if (::hs_timer > 9)
	{
		::hs_timer <- 0
		local hs = null
		while (hs = Entities.FindByName(hs, "health_station"))
		{
			local healed = false
			local ply = null
			while (ply = Entities.FindByClassnameWithin(ply, "*", hs.GetOrigin(), 120))
			{
				if (LivingPlayer(ply) && TraceLine(hs.GetOrigin(), ply.GetOrigin() + Vector(0, 0, 20), hs) == 1)
				{
					local healing = ClampValue(5, 0, ply.GetMaxHealth() - ply.GetHealth())
					ply.SetHealth(ply.GetHealth() + healing)
					if (healing > 0)
					{
						DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), Vector(0, 0, 0))
						healed = true
					}
				}
			}
			if (healed)
			{
				hs.EmitSound("HealthShot.Pickup")
			}
		}
	}
	::hud_timer++
	if (::hud_timer > 98)
	{
		::hud_timer <- 0
		UpdateRoleHints()
	}
	if (PREPARING && !ScriptIsWarmupPeriod())
	{
		::role_timer++
		if (::role_timer > 49 && GetPlayerCount() > 1)
		{
			AssignRoles()
		}
	}
}

::GetPlayerCount <- function(role = -1)
{
	local count = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*"))
	{
		if (ply.GetClassname() == "player" && (role == -1 || IsRole(ply, role)))
		{
			count++
		}
	}
	return count
}

::GetLivingPlayerCount <- function(role = -1)
{
	local count = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*"))
	{
		if (LivingPlayer(ply) && (role == -1 || IsRole(ply, role)))
		{
			count++
		}
	}
	return count
}

::PREPARING <- true
::ROUND_OVER <- false
::ShowHintToPlayer <- function(ply, name) {EntFire("hud_" + name, "display", "", 0, ply)}

::RoleHintMe <- function(ply)
{
	if (PREPARING)
	{
		ShowHintToPlayer(ply, "preparing")
		return
	}
	if (ROUND_OVER)
	{
		ShowHintToPlayer(ply, "roundover")
		return
	}
	if (ply.GetHealth() < 1)
	{
		ShowHintToPlayer(ply, "dead")
		return
	}
	switch (GetRole(ply))
	{
		case TRAITOR:
			ShowHintToPlayer(ply, "traitor")
			break
		case DETECTIVE:
			ShowHintToPlayer(ply, "detective")
			break
		case JESTER:
			ShowHintToPlayer(ply, "jester")
			break
		default:
			ShowHintToPlayer(ply, "innocent")
			break
	}
}

::UpdateRoleHints <- function()
{
	EntFire("player_*", "RunScriptCode", "RoleHintMe(self)")
}

::PlayerDeath <- function(ply)
{
	if (GetRole(ply) == JESTER)
	{
		JestMaker.SpawnEntityAtLocation(ply.GetOrigin() + Vector(0, 0, 30), Vector(0, 0, 0))
		DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), Vector(0, 0, 0))
	}
	else if (!PREPARING && !ROUND_OVER)
	{
		if ((GetLivingPlayerCount(INNOCENT) + GetLivingPlayerCount(DETECTIVE)) < 1)
		{
			// traitors are technically "counter-terrorists"
			EntFire("round_ender", "EndRound_CounterTerroristsWin", "7")
			EntFire("hud_win_traitor", "display")
			::ROUND_OVER <- true
		}
		else if (GetLivingPlayerCount(TRAITOR) < 1)
		{
			EntFire("round_ender", "EndRound_TerroristsWin", "7")
			EntFire("hud_win_innocent", "display")
			::ROUND_OVER <- true
		}
	}
	UpdateRoleHints()
}

if (!("EXTREME_JESTER" in getroottable()))
{
	::EXTREME_JESTER <- false
}

::PlayerKilledPlayer <- function(victim, killer)
{
	/*
	printl("=== DEATH IN THE ROYALE FAMILY ===")
	printl("=== Victim: " + victim)
	printl("=== Killer: " + killer)
	printl("=== T.O.D.: " + Time())
	printl("=== TRAVELE IS MORE IMPORTANTE ===")
	*/

	local vrole = GetRole(victim)
	local krole = GetRole(killer)
	if (vrole == krole && vrole != INNOCENT)
	{
		ScriptPrintMessageChatAll("0MG RDM!!!!!1!! SOMEONE CALL A ADMIN QUIZK!!!!")
	}
	if (vrole == JESTER)
	{
		if (krole != TRAITOR)
		{
			if (EXTREME_JESTER)
			{
				EntFire("round_ender", "EndRound_TerroristsWin", "7")
				EntFire("hud_win_jester", "display")
				::ROUND_OVER <- true
				UpdateRoleHints()
			}
			else
			{
				ScriptPrintMessageChatAll(" \xeget jested nerd LUL")
				EntFireHandle(killer, "IgniteLifetime", "30")
			}
		}
	}
}

::KnifeList <- ["bayonet", "knife_m9_bayonet", "knife_karambit", "knife_butterfly", "knife_flip"]
::LAST_DEATH <- null

::Debug_PrintRoles <- function()
{
	local ply = null
	while (ply = Entities.Next(ply))
	{
		if (ply.GetClassname() == "player")
		{
			if (ply.GetHealth() > 0)
			{
				printl(ply)
			}
			else
			{
				printl(ply + " - DEAD")
			}
		}
	}
}

::Debug_ModelTest <- function(mdl = "models/player/custom_player/legacy/tm_phoenix_varianta.mdl")
{
	local ent = null
	while (ent = Entities.FindByModel(ent, mdl))
	{
		printl(ent)
	}
}

if (!("DETECTIVE_MIN_PLAYERS" in getroottable()))
{
	::DETECTIVE_MIN_PLAYERS <- 4
}

::DETECTIVE_MODEL <- "models/player/custom_player/legacy/ctm_sas_varianta.mdl"
::MakeDetective <- function(ply)
{
	SetRole(ply, DETECTIVE)
	ply.PrecacheModel(DETECTIVE_MODEL)
	ply.SetModel(DETECTIVE_MODEL)
	GiveWeapon(ply, "weapon_aug")
	GiveWeapon(ply, "weapon_fiveseven")
	GiveWeapon(ply, "weapon_shield")
	GiveWeapon(ply, "weapon_tagrenade")
}

::AssignRoles <- function()
{
	::PREPARING <- false
	local plylist = []
	local ply = null
	while (ply = Entities.Next(ply))
	{
		if (ply.GetClassname() == "player")
		{
			plylist.push(ply)
			ply.SetMaxHealth(100)
			ply.SetHealth(100)
			// replace eaten armor from prep time
			GiveWeapon(ply, "item_assaultsuit")
		}
	}
	local count = GetPlayerCount()
	local traitors = []
	local traitor_amt = ClampValue(floor(count * 0.25), 1, count - 1)
	traitor_amt = 1 // TEMPORARY - No way to know your fellow traitors yet
	do
	{
		local index = RandomInt(1, plylist.len()) - 1
		SetRole(plylist[index], TRAITOR)
		traitors.push(plylist[index])
		plylist.remove(index)
		traitor_amt--
	}
	while (traitor_amt > 1)
	if (count >= DETECTIVE_MIN_PLAYERS)
	{
		local index = RandomInt(1, plylist.len()) - 1
		MakeDetective(plylist[index])
		plylist.remove(index)
	}
	if (RandomInt(1, 3) == 1)
	{
		local index = RandomInt(1, plylist.len()) - 1
		SetRole(plylist[index], JESTER)
		EntFire("speedmod", "ModifySpeed", "1.05", 0, plylist[index])
		foreach (traitor in traitors)
		{
			ShowHintToPlayer(traitor, "jester_active")
		}
		plylist.remove(index)
	}
	UpdateRoleHints()
	SendToConsoleServer("mp_respawn_on_death_t 0")
	SendToConsoleServer("mp_respawn_on_death_ct 0")
	if (KITTYS)
	{
		EntFire("kitty_overlay", "startoverlays")
		EntFire("kitty_overlay", "stopoverlays", "", 0.1)
		::KITTYS <- false
	}
}

::ColorList <- [["RED", "255 0 0"], ["ORANGE", "255 128 0"], ["YELLOW", "255 255 0"], ["GREEN", "0 255 0"], ["BLUE", "0 0 255"], ["MAGENTA", "255 0 255"], ["VIOLET", "128 0 255"], ["CYAN", "0 255 255"], ["GRAY", "128 128 128"]]
::PlayerColors <- {}

if (!("KITTYS" in getroottable()))
{
	::KITTYS <- false
}

OnPostSpawn <- function()
{
	ScriptPrintMessageChatAll("• \x03 Welcome to TTT_ClintonBeach!")
	ScriptPrintMessageChatAll("• \x03 Your roles are in the top left of your screen.")
	ScriptPrintMessageChatAll("• \x03 TA Grenades place down health stations.")
	ScriptPrintMessageChatAll("• \x03 Have fun!")
	SendToConsoleServer("bot_join_team t")
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_roundtime 5")
	SendToConsoleServer("mp_freezetime 0")
	SendToConsoleServer("mp_forcecamera 0")
	SendToConsoleServer("mp_limitteams 999")
	SendToConsoleServer("mp_solid_teammates 1")
	SendToConsoleServer("mp_autoteambalance 0")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_teammates_are_enemies 1")
	EntFire("broadcaster", "Command", "cl_drawhud_force_deathnotices -1")
	::ROUND_OVER <- false
	::PREPARING <- true
	local ply = null
	while (ply = Entities.Next(ply))
	{
		if (ply.GetClassname() == "player")
		{
			SetRole(ply, INNOCENT)
			EntFire("speedmod", "ModifySpeed", "1", 0, ply)
			GiveWeapon(ply, "weapon_" + KnifeList[RandomInt(1, KnifeList.len()) - 1])
			GiveWeapon(ply, "item_assaultsuit")
			ply.SetMaxHealth(9999)
			ply.SetHealth(9999)
			if (ply.ValidateScriptScope())
			{
				ply.GetScriptScope().infected <- false
			}
		}
	}
	MeleeFixup()
	UpdateRoleHints()
	local wepspawn = null
	while (wepspawn = Entities.FindByName(wepspawn, "ttt_weapon_spawn"))
	{
		local spawner = Entities.FindByName(null, "wepmaker_" + WEPLIST[RandomInt(1, WEPLIST.len()) - 1])
		spawner.SpawnEntityAtEntityOrigin(wepspawn)
	}
	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope())
	{
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function()
		{
			if (::LAST_DEATH != null)
			{
				PlayerKilledPlayer(::LAST_DEATH, activator)
			}
		}
	}
	DeathEvent <- Entities.CreateByClassname("trigger_brush")
	DeathEvent.__KeyValueFromString("targetname", "game_playerdie")
	if (DeathEvent.ValidateScriptScope())
	{
		DeathEvent.ConnectOutput("OnUse", "OnDeath")
		DeathEvent.GetScriptScope().OnDeath <- function()
		{
			::LAST_DEATH <- activator
			PlayerDeath(activator)
		}
	}
	if (KITTYS)
	{
		EntFire("kitty_overlay", "startoverlays")
		EntFire("kitty_overlay", "stopoverlays", "", 0.1)
		::KITTYS <- false
	}
}

::ChangeCostume <- function()
{
	local costume = Entities.FindByNameNearest("costume", self.GetOrigin(), 6)
	local ply = Entities.FindByNameNearest("player_*", self.GetOrigin(), 100)
	if (costume != null && ply != null)
	{
		local mdl = costume.GetModelName()
		ply.PrecacheModel(mdl)
		ply.SetModel(mdl)
		costume.EmitSound("Player.EquipArmor_T")
	}
}

::InfectPlayer <- function(ply)
{
	if (LivingPlayer(ply) && ply.ValidateScriptScope() && GetRole(ply) != DETECTIVE)
	{
		ply.GetScriptScope().infected <- true
	}
}

::SpreadInfection <- function()
{
	local ply = null
	while (ply = Entities.Next(ply))
	{
		if (LivingPlayer(ply) && ply.ValidateScriptScope())
		{
			local ss = ply.GetScriptScope()
			if ("infected" in ss && ss.infected)
			{
				if (RandomInt(1, 2) == 1)
				{
					local new_health = ply.GetHealth() - RandomInt(10, 20)
					if (new_health > 0)
					{
						ply.SetHealth(new_health)
						EntFire("client_cmd", "command", "say *cough*", RandomFloat(0, 3), ply)
					}
					else
					{
						ply.SetHealth(1)
						EntFireHandle(ply, "IgniteLifetime", "0.1", 0.1)
					}
				}
				printl("searching near " + ply + "...")
				local nearby = null
				while (nearby = Entities.FindByNameWithin(nearby, "player_*", ply.GetOrigin(), 200))
				{
					printl("found " + nearby)
					if (nearby != ply)
					{
						InfectPlayer(nearby)
					}
				}
			}
		}
	}
}

::SpinSpinner <- function()
{
	EntFire("spinner", "start")
	EntFire("spinner", "stop", "", RandomFloat(6, 9))
}
