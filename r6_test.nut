
::EntFireHandle <- function(t, i, v = "", d = 0.0, a = null, c = null) {EntFireByHandle(t, i, v, d, a, c)}

::PLAYERMODEL_PREFIX <- "models/player/custom_player/legacy/"
::PLAYERMODEL_POSTFIX <- ".mdl"
::PLYMDL <- function(mdl) {return PLAYERMODEL_PREFIX + mdl + PLAYERMODEL_POSTFIX}

::DEFENDERS <- 2
::ATTACKERS <- 3

::VecSum <- function(v) {return ceil(v.x) + "_" + ceil(v.y) + "_" + ceil(v.z)}
::WallStatus <- {} // 0 is fine, 1 is reinforced, 2 is blown (thermite)

OnPostSpawn <- function()
{
	EntFire("reinforcement", "disable")
	local wall = null
	while (wall = Entities.FindByName(wall, "reinforceable"))
	{
		if (wall.ValidateScriptScope())
		{
			wall.GetScriptScope().InputUse <- function()
			{
				if (activator.GetTeam() == DEFENDERS)
				{
					local sum = VecSum(self.GetOrigin())
					if (!(sum in WallStatus))
					{
						::WallStatus[sum] <- 0
					}
					if (WallStatus[sum] == 0)
					{
						local reinforcement = Entities.FindByNameNearest("reinforcement", self.GetOrigin(), 2)
						if (reinforcement != null)
						{
							::WallStatus[sum] <- 1
							EntFireHandle(reinforcement, "enable")
							reinforcement.EmitSound("Metal_Barrel.ImpactHard")
							local ent = null
							while (ent = Entities.FindByNameWithin(ent, "reinforceable", self.GetOrigin(), 2))
							{
								EntFireHandle(ent, "enablemotion")
							}
						}
					}
				}
				return false
			}
		}
	}
	local prop = null
	while (prop = Entities.FindByName(prop, "ph_prop"))
	{
		if (prop.ValidateScriptScope())
		{
			prop.GetScriptScope().InputUse <- function()
			{
				local mdl = self.GetModelName()
				printl(activator + " is now " + mdl)
				activator.PrecacheModel(mdl)
				activator.SetModel(mdl)
				activator.SetMaxHealth(9999)
				activator.SetHealth(9999)
			}
		}
	}
}
