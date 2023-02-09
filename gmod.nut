
::CenterPrint <- function(ply, msg)
{
	local messager = Entities.CreateByClassname("env_message")
	messager.__KeyValueFromString("message", msg)
	EntFireByHandle(messager, "ShowMessage", "", 0.0, ply, null)
	EntFireByHandle(messager, "Kill", "", 0.1, null, null)
}

::GiveWeapon <- function(ply, weapon, ammo = 1)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	EntFireByHandle(equip, "Kill", "", 0.1, null, null)
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

::Alive <- function(ply) {return ply.GetHealth() > 0}
::LivingPlayer <- function(ent) {return ent.GetClassname() == "player" && ent.GetHealth() > 0}

::CapturedPlayer <- null

Think <- function()
{
	local tac = null
	while (tac = Entities.FindByClassname(tac, "tagrenade_projectile"))
	{
		if (tac.GetVelocity().Length() == 0 && fuck)
		{
			local owner = tac.GetOwner()
			if (owner != null)
			{
				tac.StopSound("Sensor.Activate")
				tac.Destroy()
			}
		}
	}
	ply <- null
	while((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		if (ply.ValidateScriptScope())
		{
			local script_scope = ply.GetScriptScope()
			if (!("userid" in script_scope) && !("attemptogenerateuserid" in script_scope))
			{
				script_scope.attemptogenerateuserid <- true
				::CapturedPlayer = ply
				EntFireByHandle(::gameevents_proxy, "GenerateGameEvent", "", 0.0, ply, null)
				return
			}
		}
	}
}

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_teammates_are_enemies 0")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("sv_falldamage_scale 0.2")
	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope())
	{
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function()
		{
			printl("killer: " + activator + " time:" + Time())
		}
	}
	DeathEvent <- Entities.CreateByClassname("trigger_brush")
	DeathEvent.__KeyValueFromString("targetname", "game_playerdie")
	if (DeathEvent.ValidateScriptScope())
	{
		DeathEvent.ConnectOutput("OnUse", "OnDeath")
		DeathEvent.GetScriptScope().OnDeath <- function()
		{
			printl("death: " + activator + " time:" + Time())
		}
	}
}

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

::PrintTable <- function(tab, printfunc = printl, indent = "")
{
	foreach (k, v in tab)
	{
		if (typeof v == "table")
		{
			PrintTable(v, printfunc, indent + "   ");
		}
		else
		{
			printfunc(k + " = " + v)
		}
	}
}

if (!("gameevents_proxy" in getroottable()) || !(::gameevents_proxy.IsValid()))
{
	::gameevents_proxy <- Entities.CreateByClassname("info_game_event_proxy")
	::gameevents_proxy.__KeyValueFromString("event_name", "player_use")
	::gameevents_proxy.__KeyValueFromInt("range", 0)
}

if (!("gameevents_proxy_connect" in getroottable()) || !(::gameevents_proxy_connect.IsValid()))
{
	::gameevents_proxy_connect <- Entities.CreateByClassname("info_game_event_proxy")
	::gameevents_proxy_connect.__KeyValueFromString("event_name", "player_connect_full")
	::gameevents_proxy_connect.__KeyValueFromInt("range", 0)
}

::GimmeXD <- function(ply = -1)
{
	if (ply = -1)
	{
		ply = Entities.FindByClassname(null, "player")
	}
	EntFireByHandle(::gameevents_proxy_connect, "GenerateGameEvent", "", 0.0, ply, null)
}

::PlayerUse <- function(data)
{
	if (::CapturedPlayer != null && data.entity == 0)
	{
		local script_scope = ::CapturedPlayer.GetScriptScope()
		script_scope.userid <- data.userid
		::CapturedPlayer = null
	}
	PrintTable(data)
}

::PlayerConnect <- function(data)
{
	PrintTable(data)
}

::PlayerHurt <- function(data)
{
	printl("somebody got hurt")
}
