
IncludeScript("util")

::PLY_MODEL <- "models/player/custom_player/legacy/tm_phoenix.mdl"

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
			ChangeHealth(activator, 9999)
		}
	}
}

if (!TimerExists("ph_timer"))
{
	CreateTimer("ph_timer", function() {
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
	})
}
