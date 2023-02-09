
::EntFireHandle <- function(t, i, v = "", d = 0.0, a = null, c = null) {EntFireByHandle(t, i, v, d, a, c)}

::PLY_MODEL <- "models/player/custom_player/legacy/tm_phoenix.mdl"

::SetModelSafe <- function(p, m)
{
	p.PrecacheModel(m)
	p.SetModel(m)
}

OnPostSpawn <- function()
{
	local prop = null
	while (prop = Entities.FindByClassname(prop, "prop_physics*"))
	{
		if (prop.ValidateScriptScope())
		{
			prop.GetScriptScope().InputUse <- function()
			{
				if (activator.GetTeam() == 3)
				{
					printl("CT cannot become prop!")
					return
				}
				SetModelSafe(activator, self.GetModelName())
				activator.SetMaxHealth(9999)
				activator.SetHealth(9999)
			}
		}
	}
}

Think <- function()
{
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
	{
		if (ply.GetTeam() == 2 && ply.GetHealth() > 0 && ply.GetHealth() != 100 && (9999 - ply.GetHealth()) > 50)
		{
			SetModelSafe(ply, PLY_MODEL)
			ply.SetHealth(1)
			EntFireHandle(ply, "IgniteLifetime", "0.1", 0.1)
		}
	}
}
