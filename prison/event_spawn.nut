
::GiveWeapons <- function()
{
	ply <- null
	while ((ply = Entities.FindByClassname(ply, "*")) != null)
	{
		if ((ply.GetClassname() == "player" || ply.GetClassname() == "bot") && ply.ValidateScriptScope())
		{
			local scope = found.GetScriptScope()
			if (!("userid" in scope))
			{
				P("Killing " + found.entindex() + " to get userid")
				// kill that fucker, and again after godmode wears off
				EntFireByHandle(found, "sethealth", "0", 0, null, null)
				EntFireByHandle(found, "sethealth", "0", 3, null, null)
				CenterPrint(found, "Source engine spaghetti! Sorry for killing you.")
			}
		}		
	}
}
