
IncludeScript("butil")

SendToConsoleServer("mp_autoteambalance 0")
SendToConsoleServer("mp_limitteams 30")

/*
SendToConsoleServer("mp_respawn_on_death_t 1")
SendToConsoleServer("mp_respawn_on_death_ct 1")
SendToConsoleServer("mp_teammates_are_enemies 1")
ForEachPlayerAndBot(function(ply) {if (LivingPlayer(ply)) ply.SetHealth(999999)})

::DisableRespawn <- function()
{
	SendToConsoleServer("mp_respawn_on_death_t 0")
	SendToConsoleServer("mp_respawn_on_death_ct 0")
	SendToConsoleServer("mp_teammates_are_enemies 0")
	ForEachPlayerAndBot(function(ply) {if (LivingPlayer(ply)) ply.SetHealth(100)})
}
*/

EntFireHandle(LocalPlayer(), "runscriptcode", "DisableRespawn()", 8)

if ("ghost_init" in getroottable())
{
	printl("ghost script already loaded!")
}
else
{
	printl("performing first time setup for ghost gamemode...")
}

::ghost_init <- true
::plylist <- []

ForEachPlayerAndBot(function(ply) {
	if (ply.GetTeam() == T)
		ply.SetTeam(CT)
	plylist.push(ply)
	ply.__KeyValueFromInt("rendermode", 1)
	//ply.__KeyValueFromInt("effects", 4)
})

local ghost = plylist[RandomInt(0, plylist.len())]
printl(ghost)
ghost.SetTeam(T)
ghost.__KeyValueFromInt("rendermode", 10)
//ghost.__KeyValueFromInt("effects", 0)
ghost.SetOrigin(Entities.FindByClassname(null, "info_player_terrorist").GetOrigin())

ChatPrintAll(" " + BLUE + "a ghost is haunting about! go find him")

HookToPlayerDeath(function(ply) {
	printl(ply + " died !")
	//ply.__KeyValueFromInt("effects", 0)
	ply.__KeyValueFromInt("rendermode", 1)
})
