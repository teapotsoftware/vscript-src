
::T <- 2
::CT <- 3

::LastGivenWep <- {}

::GiveWeapon <- function(ply, weapon, ammo = 99999)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	EntFireByHandle(equip, "Kill", "", 0.1, ply, null)
	LastGivenWep[ply.entindex()] <- Time()
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireByHandle(strip, "Strip", "", 0.0, ply, null)
	EntFireByHandle(strip, "Kill", "", 0.1, ply, null)
}

::LAST_DEATH <- null

::PlayerDeath <- function(ply)
{
	printl("ded")
}

::PlayerKilledPlayer <- function(victim, killer)
{
	printl("=== DEATH IN THE ROYALE FAMILY ===")
	printl("=== Victim: " + victim)
	printl("=== Killer: " + killer)
	printl("=== T.O.D.: " + Time())
	printl("=== TRAVELE IS MORE IMPORTANTE ===")
}

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_teammates_are_enemies 1")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("sv_falldamage_scale 0")
	SendToConsoleServer("mp_damage_scale_ct_head 2")
	SendToConsoleServer("mp_damage_scale_ct_body 0.8")
	SendToConsoleServer("mp_damage_scale_t_head 2")
	SendToConsoleServer("mp_damage_scale_t_body 0.8")
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
				PlayerDeath(activator)
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
		}
	}
}

HasWeapons <- function(ply)
{
	if ((ply.entindex() in LastGivenWep) && (Time() - LastGivenWep[ply.entindex()] < 0.1))
	{
		return true
	}
	wep <- null
	while ((wep = Entities.FindByClassname(wep, "weapon_*")) != null)
	{
		if (wep.GetClassname() != "weapon_c4")
		{
			if (wep.GetOwner() == ply)
			{
				return true
			}
		}
	}
	return false
}

::PlayerSpawned <- function()
{
	ply <- null
	while ((ply = Entities.FindByClassname(ply, "*")) != null)
	{
		if (ply.IsValid() && ply.GetClassname() == "player" && !HasWeapons(ply) && ply.GetHealth() > 0)
		{
			GiveWeapon(ply, "item_assaultsuit")
			GiveWeapon(ply, "weapon_m4a1")
			GiveWeapon(ply, "weapon_knife_m9_bayonet")
			GiveWeapon(ply, "weapon_hegrenade")
			EntFire("weapon_knife", "addoutput", "classname weapon_knifegg")
			// ply.PrecacheModel("models/player/zombie.mdl")
			// ply.SetModel("models/player/zombie.mdl")
		}
	}
}
