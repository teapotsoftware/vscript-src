
SendToConsoleServer("mp_teamname_1 Vigilantes")
SendToConsoleServer("mp_teamname_2 Banditos")
SendToConsoleServer("sv_infinite_ammo 2")

::GiveWeapon <- function(ply, weapon)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, 999999)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	equip.__KeyValueFromInt(weapon, 0)
	equip.Destroy()
}

::RandNumToWepName <- {
	[6] = "Sawed Off",
	[5] = "Molotov",
	[4] = "Kevlar",
	[3] = "Dynamite",
	[2] = "Dual Pistols",
	[1] = "None",
}

::GivePlayerWeapons <- function()
{
	local rand = RandomInt(1, 6)
	ply <- null
	while ((ply = Entities.FindByClassname(ply, "*")) != null)
	{
		if (ply.GetClassname() == "player" || ply.GetClassname() == "bot")
		{
			if (rand == 6)
			{
				GiveWeapon(ply, "weapon_sawedoff")
			}
			else if (rand == 5)
			{
				GiveWeapon(ply, "weapon_molotov")
			}
			else if (rand == 4)
			{
				GiveWeapon(ply, "item_assaultsuit")
			}
			else if (rand == 3)
			{
				GiveWeapon(ply, "weapon_hegrenade")
			}
			if (rand == 2) // no else
			{
				GiveWeapon(ply, "weapon_elite")
			}
			else
			{
				GiveWeapon(ply, "weapon_revolver")
			}

			GiveWeapon(ply, "weapon_fists")
		}
	}

	ScriptPrintMessageChatAll("Special item this round: " + RandNumToWepName[rand])

	EntFire("weapon_fists", "addoutput", "classname weapon_knifegg")
}

::RefreshWhiskey <- function()
{
	EntFire("whiskey", "kill", "")
	EntFire("whiskey_template", "forcespawn", "")
}

::DrinkWhiskey <- function(ply)
{
	local hp = ply.GetHealth()
	local max = ply.GetMaxHealth()
	if (hp >= max)
	{
		SendCommandToClient(ply, "play fof/burp")
		return false
	}
	else
	{
		hp += 25
		if (hp > max)
		{
			hp = max
		}
		SendCommandToClient(ply, "play fof/whiskey" + RandomInt(1, 4))
		ply.SetHealth(hp)
		return true
	}
}

function OnPostSpawn()
{
	GivePlayerWeapons()

	ent <- null
	while ((ent = Entities.FindByName(ent, "whiskey_*")) != null)
	{
		if (ent.GetClassname() == "func_button" && ent.ValidateScriptScope())
		{
			local scope = ent.GetScriptScope()
			scope.DrinkMe <- function()
			{
				printl("yuhhh")
				if (DrinkWhiskey(activator))
				{
					EntFire(this.self.GetName() + "_bottle", "kill", "")
					this.self.Destroy()
				}
			}
			ent.ConnectOutput("OnPressed", "DrinkMe")
		}
	}
}
