
::CANNON_SOUND <- "coop.grenade_launch"

ShotCooldown <- 0

OnPostSpawn <- function()
{
	self.PrecacheScriptSound(CANNON_SOUND)
}

UpdateColor <- function()
{
	local v = 255 - (ShotCooldown * 100)
	self.__KeyValueFromString("rendercolor", "255 " + v + " " + v)
}

Think <- function()
{
	ShotCooldown -= 0.1
	if (ShotCooldown < 0)
	{
		ShotCooldown = 0
	}

	UpdateColor()
}

InputUse <- function()
{
	if (ShotCooldown == 0)
	{
		local maker = Entities.FindByName(null, "cannonball_maker")
		if (maker != null)
		{
			local ang = self.GetAngles() + Vector(-8, 270, 0)
			maker.__KeyValueFromString("PostSpawnDirection", ang.x + " " + ang.y + " " + ang.z)
			maker.SpawnEntityAtLocation(self.GetOrigin() + (self.GetLeftVector() * 130) + (self.GetUpVector() * 50), Vector(0, 0, 0))
		}

		self.EmitSound(CANNON_SOUND)
		ShotCooldown = 2
		UpdateColor()
	}
/*
	if (self.GetName() == "cannon_loaded")
	{
	}
	else
	{
		local wep = GetActiveWeapon(activator)
		if (wep != null && wep.GetClassname() == "weapon_hegrenade")
		{
			wep.Destroy()
			self.__KeyValueFromString("rendercolor", "255 255 255")
			self.__KeyValueFromString("targetname", "cannon_loaded")
		}
	}
*/
}
