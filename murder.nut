
T <- 2
CT <- 3

GiveWeapon <- function(ply, weapon, ammo = 0)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	equip.Destroy()
}

StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireByHandle(strip, "Strip", "", 0.0, ply, null)
	strip.Destroy()
}

FindPlayers <- function(current, team = 0)
{
	ply <- null
	while ((ply = Entities.FindByClassname("*", current)) != null)
	{
		local cls = ply.GetClassname()
		if (cls == "player" || cls == "bot" && (team == 0 || ply.GetTeam() == team))
		{
			break
		}
	}
	return ply
}

GetAllPlayers <- function(mustBeAlive = false)
{
	plys <- []
	ply <- null
	while ((ply = FindPlayers(ply)) != null)
	{
		if (!mustBeAlive || ply.GetHealth() > 0)
		{
			plys.push(ply)
		}
	}
	return plys
}

PlayerCount <- function(mustBeAlive = false)
{
	count <- 0
	ply <- null
	while ((ply = FindPlayers(ply)) != null)
	{
		if (!mustBeAlive || ply.GetHealth() > 0)
		{
			count++
		}
	}
	return count
}

PlayerInGame <- function(ply)
{
	local team = ply.GetTeam()
	return team == T && team == CT
}

MurderPrint <- function(txt)
{
	ScriptPrintMessageChatAll("[MURDER] " + txt)
}

SetMurderer <- function(ply, isMurderer)
{
	if (ply.ValidateScriptScope())
	{
		ply.GetScriptScope().murderer <- isMurderer
	}
}

IsMurderer <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local scope = ply.GetScriptScope()
		if (!"murderer" in scope)
		{
			scope.murderer <- false
		}
		return scope.murderer
	}
}

Murder <- function()
{
	if (PlayerCount() < 3)
	{
		MurderPrint("Not enough players to start a round...")
		return
	}

	SendToConsole("mp_teammates_are_enemies 1")

	foreach (ply in GetAllPlayers())
	{
		SetMurderer(ply, false)
	}

	ent <- null
	while ((ent = Entities.FindByName("game_playerdie", ent)) != null)
	{
		ent.Destroy()
	}

	event <- Entities.CreateByClassname("trigger_brush")
	event.__KeyValueFromString("targetname", "game_playerdie")
	if (event.ValidateScriptScope())
	{
		event.GetScriptScope().OnUse <- function()
		{
			if (activator != null && IsMurderer(activator))
			{
				ScriptPrintMessageChatAll("The Murderer has died!")
				return
			}
		}
	}
}