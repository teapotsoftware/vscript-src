
IncludeScript("butil")

SendToConsoleServer("mp_autokick 0")
SendToConsoleServer("mp_solid_teammates 1")
SendToConsoleServer("mp_forcecamera 0")

::T <- 2
::CT <- 3

::GiveWeapon <- function(ply, weapon, ammo = 99999, everybody = false)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, everybody ? "TriggerForAllPlayers" : "Use", "", 0.0, ply, null)
	EntFireByHandle(equip, "kill", "", 0.1, null, null)
}

::GiveEverybodyWeapon <- function(weapon, ammo)
{
	ply <- null
	while (ply = Entities.FindByClassname(ply, "*"))
	{
		local cls = ply.GetClassname()
		if (cls == "player" || cls == "bot")
		{
			GiveWeapon(ply, weapon, ammo)
		}
	}
}

::CubeLoadouts <- [
	{weps = [["weapon_revolver", 420], ["weapon_molotov", 1], ["weapon_fists", 1]]},
	{weps = [["item_assaultsuit", 1], ["weapon_deagle", 420], ["weapon_bumpmine", 420], ["weapon_knife_karambit", 1]]},
	{weps = [["item_assaultsuit", 1], ["weapon_ssg08", 420], ["weapon_knife_butterfly", 1]], low_grav = true},
	{weps = [["item_assaultsuit", 1], ["weapon_p250", 420], ["weapon_shield", 1], ["weapon_knife_tactical", 1]]},
	{weps = [["item_assaultsuit", 1], ["weapon_nova", 420], ["weapon_bayonet", 1]], start = function() {EntFire("amosmoses", "playsound")}},
	{weps = [["item_assaultsuit", 1], ["weapon_mp5sd", 420], ["weapon_smokegrenade", 1], ["weapon_knife_stiletto", 1]]},
	{weps = [["item_heavyassaultsuit", 1], ["weapon_bizon", 420], ["weapon_breachcharge", 69], ["weapon_knife_survival_bowie", 1]]},
	{weps = [["weapon_hegrenade", 1], ["weapon_bayonet", 1]], infinite_ammo = true},
	{weps = [["weapon_cz75a", 420], ["weapon_tagrenade", 1], ["weapon_bayonet", 1]], infinite_ammo = true},
	{weps = [["weapon_elite", 420], ["weapon_knife_flip", 1]]},
	{weps = [["weapon_knife_m9_bayonet", 1]], buy_round = true, start = function() {
		ScriptPrintMessageChatAll("Buy round!")
	}},
	{weps = [["weapon_fists", 1]], start = function() {
		ScriptPrintMessageChatAll("Hunger games!")
		EntFire("hunger_template", "forcespawn")
	}},
	{weps = [["weapon_hammer", 1]]},
	{weps = [["item_assaultsuit", 1], ["weapon_awp", 420], ["weapon_knife_karambit", 1]]},
	{weps = [["item_assaultsuit", 1], ["weapon_negev", 420], ["weapon_knife_m9_bayonet", 1]]},
	{weps = [["item_assaultsuit", 1], ["weapon_p90", 420], ["weapon_decoy", 1], ["weapon_knife_gut", 1]]},
	{weps = [["weapon_usp_silencer", 420], ["weapon_fists", 1]], start = function() {
		EntFire("ge64music", "playsound")
		// EntFire("doors", "addoutput", "noise1 doors/doorstop1")
	}},
	{weps = [], team_based = true, start = function() {
		ScriptPrintMessageChatAll("Zombies VS. Humans")
		EntFire("vampintro", "playsound")
		local ply = null
		while (ply = Entities.Next(ply))
		{
			if (ply.GetClassname() == "player" && ply.GetHealth() > 0)
			{
				if (ply.GetTeam() == T)
				{
					GiveWeapon(ply, "weapon_knife_push", 1)
					ply.SetMaxHealth(500)
					ply.SetHealth(500)
				}
				else if (ply.GetTeam() == CT)
				{
					GiveWeapon(ply, "weapon_m4a1", 999)
					GiveWeapon(ply, "item_assaultsuit", 1)
					GiveWeapon(ply, "weapon_bayonet", 1)
				}
			}
		}
	}},
	{weps = [["item_assaultsuit", 1]], team_based = true, start = function() {
		local ply = null
		while (ply = Entities.Next(ply))
		{
			if (ply.GetClassname() == "player" && ply.GetHealth() > 0)
			{
				if (ply.GetTeam() == T)
				{
					GiveWeapon(ply, "weapon_knife_css", 1)
					GiveWeapon(ply, "weapon_glock", 999)
					GiveWeapon(ply, "weapon_ak47", 999)
				}
				else if (ply.GetTeam() == CT)
				{
					GiveWeapon(ply, "weapon_knife_css", 1)
					GiveWeapon(ply, "weapon_usp_silencer", 999)
					GiveWeapon(ply, "weapon_m4a1", 999)
				}
			}
		}
	}},
]

::CubeLoadout <- function(round = -1)
{
	ForEachPlayerAndBot(StripWeapons)
	if (round == -1 || round >= CubeLoadouts.len())
		round = RandomInt(0, CubeLoadouts.len() - 1)
	::CurrentRoundIndex <- round
	::CurrentRound <- CubeLoadouts[round]

	foreach (wep in CurrentRound.weps)
		GiveWeapon(null, wep[0], wep[1], true)

	if ("start" in CurrentRound)
		::CurrentRound.start()

	MeleeFixup()

	local any_mods = false
	local modifiers = []
	for (local i = 0; i < 4; i++)
	{
		modifiers.push(["team_based", "infinite_ammo", "buy_round", "low_grav"][i] in CurrentRound)
		if (i < 3)
			SendToConsoleServer(["mp_teammates_are_enemies", "sv_infinite_ammo", "mp_buy_anywhere"][i] + " " + ((i == 0) ? (modifiers[i] ? "0" : "1") : (modifiers[i] ? "1" : "0")))
		else if (modifiers[i])
			EntFire("lowgrav", "enable")
		if (modifiers[i])
			any_mods = true
	}

	if (any_mods)
	{
		ChatPrintAll("MODIFIERS:")
		for (local i = 0; i < 4; i++)
		{
			if (modifiers[i])
				ChatPrintAll("- " + ["Teams", "Infinite ammo", "Buyzones enabled", "Low gravity"][i])
		}
	}
}

::WantSkip <- {}
::RoundStartTime <- 0

OnPostSpawn <- function()
{
	::WantSkip <- {}
	::RoundStartTime <- Time()
	EntFire("console", "command", "mp_autokick 0")
	EntFire("console", "command", "mp_forcecamera 0")
	EntFire("console", "command", "mp_solid_teammates 1")
	CubeLoadout()
	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope())
	{
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function()
		{
			GiveWeapon(activator, "weapon_healthshot")
			if ("on_kill" in CurrentRound)
				::CurrentRound.on_kill(activator)
		}
	}
	DeathEvent <- Entities.CreateByClassname("trigger_brush")
	DeathEvent.__KeyValueFromString("targetname", "game_playerdie")
	if (DeathEvent.ValidateScriptScope())
	{
		DeathEvent.ConnectOutput("OnUse", "OnDeath")
		DeathEvent.GetScriptScope().OnDeath <- function()
		{
			if ("on_death" in CurrentRound)
				::CurrentRound.on_death(activator)

			local alive = GetLivingPlayers()
			if (alive.len() == 2)
			{
				ChatPrintAll("Sudden death will commence in 20 seconds.")
				for (local i = 0; i < 4; i++)
					EntFire("suddendeath_bing", "playsound", "", 17 + i)
				EntFire("suddendeath_bong", "playsound", "", 20)
				for (local i = 0; i < 2; i++)
					EntFireHandle(alive[i], "RunScriptCode", "SuddenDeath(self, " + i + ")", 20)
			}
		}
		
	}
}

::SuddenDeath <- function(ply, i)
{
	local exit = Entities.FindByName(null, "suddendeath_exit_" + i)
	if (exit != null)
	{
		ply.SetOrigin(exit.GetOrigin())
		local a = exit.GetAngles()
		ply.SetAngles(a.x, a.y, a.z)
	}
}

::RoundEnded <- function()
{
	if ("end" in CurrentRound)
		::CurrentRound.end()
}

::GiveDeagle <- function(ply)
	GiveWeapon(ply, "weapon_deagle")

::GetPlayerCount <- function()
{
	local count = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*"))
	{
		if (ply.GetClassname() == "player")
			count++
	}
	return count
}

::PlayerChat <- function(data)
{
	if (data.text == "skip")
	{
		if ((Time() - RoundStartTime) > 10)
		{
			ScriptPrintMessageChatAll("It's too late to re-roll this round!")
			return
		}
		local needed = ceil(GetPlayerCount() * 0.5)
		if (data.userid in WantSkip)
		{
			ScriptPrintMessageChatAll("You already voted to skip!")
		}
		else
		{
			::WantSkip[data.userid] <- true
			local cur = WantSkip.len()
			ScriptPrintMessageChatAll("Votes to re-roll this round: (" + cur + "/" + needed + ")")
			if (cur >= needed)
			{
				::WantSkip <- {}
				::RoundStartTime <- Time()
				local round = CurrentRoundIndex
				while (round == CurrentRoundIndex)
					round = RandomInt(0, CubeLoadouts.len() - 1)
				CubeLoadout(round)
				ScriptPrintMessageChatAll("A new loadout has been chosen!")
			}
		}
	}
}
