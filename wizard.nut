
if ("wizard_init" in getroottable())
{
	ScriptPrintMessageChatAll("Wizard script already loaded!")
	//return
}

::wizard_init <- true

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

EntsByClass <- function(cls)
{
	ents <- []
	ent <- null
	while ((ent = Entities.FindByClassname(ent, cls)) != null)
	{
		ents.push(ent)
	}
	return ents
}

FindPlayers <- function(current, team = 0)
{
	ply <- current
	while ((ply = Entities.FindByClassname(ply, "*")) != null)
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

::Fate <- function(fate)
{
	switch (fate)
	{
		case 0:
			ScriptPrintMessageChatAll("Your fate: EXPLODING BARRELS!")
			foreach (ent in GetAllPlayers())
			{
				GiveWeapon(ent, "prop_exploding_barrel")
				continue
				print("one ")
				local barel = Entities.CreateByClassname("prop_exploding_barrel")
				barel.SetOrigin(ent.GetOrigin())
			}

		case 1:
			ScriptPrintMessageChatAll("Your fate: HAMMER TIME!")
			foreach (ply in GetAllPlayers())
			{
				StripWeapons(ply)
				GiveWeapon(ply, "weapon_hammer")
			}
			EntFire("weapon_melee", "addoutput", "classname weapon_knifegg")
	}
}

::wizard_round_end <- Entities.CreateByClassname("logic_auto")
::wizard_round_end.__KeyValueFromString("classname", "info_target")
::wizard_round_end.__KeyValueFromString("targetname", "ruhmoment")
if (wizard_round_end.ValidateScriptScope())
{
	printl("ruh moment")
	wizard_round_end.GetScriptScope().MapSpawn <- function()
	{
		ScriptPrintMessageChatAll("hehe beter")
	}
	wizard_round_end.ConnectOutput("OnMapSpawn", "MapSpawn")
}
else
{
	printl("logic_auto cant have script scope !!! (??)")
}

site <- null
while ((site = Entities.FindByClassname(site, "func_bomb_target")) != null)
{
	if (site.ValidateScriptScope())
	{
		site.GetScriptScope().Peter <- function()
		{
			self.EmitSound("multigames/bagpipes.mp3")
			ScriptPrintMessageChatAll("Peter!")
		}
	}
	site.ConnectOutput("BombPlanted", "Peter")
}
