
/*
**
** SUB ROSA by Nick B (https://steamcommunity.com/id/sirfrancisbillard/)
** Last updated 7-28-2021
**
** Sub rosa (Latin for "under the rose") denotes secrecy or confidentiality.
** The rose has an ancient history as a symbol of secrecy.
**
** In Counter-Strike, Sub Rosa is a gamemode about tense deals between armed businessmen.
**
*/

IncludeScript("butil")

::MODEL_BRIEFCASE <- "models/props_survival/briefcase/briefcase.mdl"
::MODEL_C4 <- "models/weapons/w_ied.mdl"

Precache <- function()
{
	self.PrecacheModel(MODEL_BRIEFCASE)
	self.PrecacheModel(MODEL_C4)
}

Think <- function()
{
	local ent = null
	while (ent = Entities.FindByClassname(ent, "weapon_c4"))
	{
		local owner = ent.GetOwner()
		if (owner != GetScopeVar(ent, "holder", null))
		{
			SetScopeVar(ent, "holder", owner)
			local carryEnt = ent.FirstMoveChild()

			if (owner == null)
			{
				EntFireHandle(carryEnt, "DisableDraw")
				SetModelSafe(ent, carryEnt.GetModelName())
			}
			else
			{
				EntFireHandle(carryEnt, "EnableDraw")
			}
		}
	}
}

::BombUse <- function(ent)
{
	// ent is the activating player here, for some reason
	printl("BOMB USED: " + ent)
}
