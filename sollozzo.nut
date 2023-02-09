
::GiveWeapon <- function(ply, weapon, ammo = 1)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	equip.__KeyValueFromInt(weapon, 0)
	equip.Destroy()
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireByHandle(strip, "Strip", "", 0.0, ply, null)
	strip.Destroy()
}

OnPostSpawn <- function()
{
	ply <- null
	while ((ply = Entities.FindByClassname(ply, "*")) != null)
	{
		if (ply.GetClassname() == "player" || ply.GetClassname() == "bot")
		{
			StripWeapons(ply)
			GiveWeapon(ply, "weapon_knife_stiletto")
			GiveWeapon(ply, "weapon_deagle", 7)
		}
	}

	EntFire("weapon_knife", "addoutput", "classname weapon_knifegg")
}

