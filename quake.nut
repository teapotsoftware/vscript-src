
IncludeScript("util")

::EntFireHandle <- function(t, i, v = "", d = 0.0, a = null, c = null) {EntFireByHandle(t, i, v, d, a, c)}

::T <- 2
::CT <- 3

::ClientCMD <- function(ply, cmd)
{
	local ent = Entities.CreateByClassname("point_clientcommand")
	EntFireHandle(ent, "Command", cmd, 0.0, ply)
	EntFireHandle(ent, "Kill", "", 0.1, ply)
}

::GiveWeapon <- function(ply, weapon, ammo = 99999)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1, ply)
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireHandle(strip, "Strip", "", 0.0, ply)
	EntFireHandle(strip, "Kill", "", 0.1, ply)
}

::GiveLoadout <- function(ply, array)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 3)
	equip.__KeyValueFromInt("item_assaultsuit", 1)
	foreach (wep in array)
	{
		equip.__KeyValueFromInt("weapon_" + wep, 999)
	}
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1)
}

/*
::ModifySpeed <- function(ply, speed)
{
	EntFire("speedmod", "ModifySpeed", speed.tostring(), 0.0, ply)
	EntFire("speedmod", "Kill", "", 0.1)
}
*/

::ModifySpeed <- function(ply, speed)
{
	local speedmod = Entities.CreateByClassname("player_speedmod")
	EntFireHandle(speedmod, "ModifySpeed", speed.tostring(), 0.0, ply)
	EntFireHandle(speedmod, "Kill", "", 0.1)
}

::MeleeFixup <- function()
{
	foreach (wep in ["knife", "fists", "melee"])
	{
		EntFire("weapon_" + wep, "addoutput", "classname weapon_knifegg")
	}
}

::LAST_DEATH <- null

::PlayerDeath <- function(ply)
{
	printl("ded " + ply)
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		ss.killstreak <- 0
	}
}

::ShowHUD <- function(ply, name, msg = -1)
{
	if (msg != -1)
	{
		EntFire(name, "settext", msg)
	}
	EntFire(name, "display", "", 0, ply)
}

::PlayerKilledPlayer <- function(victim, killer)
{
	// DebugDrawLine(killer.EyePosition(), victim.EyePosition(), 255, 0, 100, false, 2)
	if (killer.ValidateScriptScope())
	{
		local ss = killer.GetScriptScope()
		if (victim == killer)
		{
			ScriptPrintMessageChatAll(" \x04 slewer slide!")
		}
		else
		{
			ClientCMD(killer, "playvol buttons/button3.wav 1")
			ShowHUD(killer, "hud_hitmarker")
			if (!("killstreak" in ss))
			{
				ss.killstreak <- 1
			}
			else
			{
				ss.killstreak++
			}
			local nonred = 255 * (1 - (ss.killstreak / 20))
			killer.__KeyValueFromString("rendercolor", "255 " + nonred + " " + nonred)
			if (ss.killstreak % 5 == 0)
			{
				ShowHUD(killer, "hud_killstreak", "Killstreak: " + ss.killstreak)
			}
		}
	}
}

::POWERUP_NONE <- 0
::POWERUP_REGEN <- 1
::POWERUP_SLOWMO <- 2

::BULLET_TIME_END <- 0

::SetPowerup <- function(ply, id, duration = 10)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		ss.powerup <- id
		ss.powerup_end <- Time() + duration
		switch (id)
		{
			case 2:
				EntFire("slowmo_sound", "playsound")
				::BULLET_TIME_END <- Time() + duration
				break
		}
	}
}

::GetPowerup <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if (!("powerup" in ss))
		{
			ss.powerup <- 0
			ss.powerup_end <- 0
		}
		return ss.powerup
	}
}

::PowerupNames <- ["None", "Regen", "Bullet Time", ""]

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_teammates_are_enemies 1")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_damage_scale_ct_head 2")
	SendToConsoleServer("mp_damage_scale_ct_body 0.8")
	SendToConsoleServer("mp_damage_scale_t_head 2")
	SendToConsoleServer("mp_damage_scale_t_body 0.8")
	SendToConsoleServer("sv_falldamage_scale 0")
	SendToConsoleServer("weapon_accuracy_nospread 1")
	ScriptPrintMessageChatAll("> \x03 Welcome to WEDDING QUAKE")
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
}

::TICK_COUNT <- 0

Think <- function()
{
	foreach (cls in ["player", "cs_bot"])
	{
		EntFire(cls, "addoutput", "targetname gamer")
	}
	local ply = null
	while (ply = Entities.FindByName(ply, "gamer"))
	{
		if (ply.ValidateScriptScope())
		{
			local ss = ply.GetScriptScope()
			if ("powerup" in ss && ss.powerup != 0 && Time() < ss.powerup_end)
			{
				if (TICK_COUNT % 5 == 0)
				{
					ShowHUD(ply, "hud_powerup", "POWERUP: " + PowerupNames[ss.powerup] + " (" + ceil(ss.powerup_end - Time()) + "s)")
				}
				switch (ss.powerup)
				{
					case 1:
						local hp = ply.GetHealth() + 2
						if (hp > ply.GetMaxHealth())
						{
							ply.SetHealth(ply.GetMaxHealth())
						}
						else
						{
							ply.SetHealth(hp)
						}
						break
				}
			}
		}
		if (BULLET_TIME_END > Time())
		{
			ModifySpeed(ply, 0.4)
		}
		else if (Time() - BULLET_TIME_END < 1)
		{
			ModifySpeed(ply, 1)
		}
	}
	local ent = null
	while (ent = Entities.FindByName(ent, "pickup_model"))
	{
		local ang = ent.GetAngles()
		ang.y += 3
		ent.SetAngles(ang.x, ang.y, ang.z)
	}
}

::GodMode <- function(ply, on)
{
	if (on)
	{
		// ply.__KeyValueFromInt("rendermode 1")
		// ply.__KeyValueFromInt("renderamt 150")
		ply.__KeyValueFromString("rendercolor", "0 255 255")
		ply.SetMaxHealth(9999)
		ply.SetHealth(9999)
	}
	else
	{
		// ply.__KeyValueFromInt("rendermode 0")
		// ply.__KeyValueFromInt("renderamt 255")
		ply.__KeyValueFromString("rendercolor", "255 255 255")
		ply.SetMaxHealth(100)
		ply.SetHealth(100)
	}
}

::PlayerSpawned <- function(ply)
{
	// ply.PrecacheSoundScript("seal_epic.goto_enemy_spawn_01")
	local dest = Entities.FindByNameNearest("spawns", ply.GetOrigin(), 32)
	if (dest != null)
	{
		dest.EmitSound("UI.PlayerPing")
	}
	if (ply.GetTeam() == CT)
	{
		GiveLoadout(ply, ["fiveseven", "knife_m9_bayonet"])
	}
	else
	{
		GiveLoadout(ply, ["tec9", "bayonet"])
	}
	EntFire("weapon_knife", "addoutput", "classname weapon_knifegg")
}

::WEP_DEAGLE <- "weapon_deagle"
::WEP_XM1014 <- "weapon_xm1014"
::WEP_P90 <- "weapon_p90"
::WEP_AK47 <- "weapon_ak47"
::WEP_AWP <- "weapon_awp"
::WEP_SCAR20 <- "weapon_scar20"

::PICKUP_PLY <- null

::PlayerPickup <- function(ply, wep)
{
	::PICKUP_PLY <- ply
	GiveWeapon(ply, wep)
}

::PickupItem <- function(trigger)
{
	trigger.EmitSound("Survival.DroneGunScanForPlayer")
	EntFireHandle(trigger, "disable")
	EntFireHandle(trigger, "enable", "", 10)
	local wep = Entities.FindByNameNearest("pickup_model", trigger.GetOrigin(), 10)
	if (wep != null)
	{
		EntFireHandle(wep, "addoutput", "renderamt 150")
		EntFireHandle(wep, "addoutput", "renderamt 255", 10)
	}
}
