
IncludeScript("butil")

::ClassLoadouts <- [
	[[ITEM_KEVLAR, WEAPON_KNIFE, WEAPON_AWP], [ITEM_KEVLAR, WEAPON_KNIFE, WEAPON_AWP]],
	[[ITEM_KEVLAR, WEAPON_KNIFE, WEAPON_GLOCK], [ITEM_KEVLAR, WEAPON_KNIFE, WEAPON_P2000]],
	[[ITEM_KEVLAR, WEAPON_KNIFE], [ITEM_KEVLAR, WEAPON_KNIFE]],
	[[ITEM_KEVLAR, WEAPON_KNIFE, WEAPON_AK47], [ITEM_KEVLAR, WEAPON_KNIFE, WEAPON_M4A1]],
	[[ITEM_KEVLAR, WEAPON_TASER], [ITEM_KEVLAR, WEAPON_TASER]],
]

function OnPostSpawn()
{
	ChatPrintAll("cp_bestinclass_csgo")
	ChatPrintAll("Pick a teleport, any teleport!")
}

::ClassSpawn <- function(ply, i)
{
	GiveLoadout(ply, ClassLoadouts[ply.GetTeam() - 2])
	ply.SetVelocity(Vector(0, 0, 0))
}
