
IncludeScript("butil")

::VIP <- null
::VIP_MODEL <- "models/player/custom_player/legacy/ctm_st6_varianti.mdl"

OnPostSpawn <- function()
{
	if (ScriptIsWarmupPeriod())
		return

	local candidates = []
	local ply = null
	while (ply = Entities.Next(ply))
	{
		if (ply.GetClassname() == "player")
		{
			if (ply.GetTeam() == CT)
			{
				candidates.push(ply)
			}
		}
	}

	::VIP <- candidates[RandomInt(0, candidates.len() - 1)]
	local mdl = "models/player/custom_player/legacy/tm_professional_var" + RandomInt(1, 4) + ".mdl"
	SetModelSafe(VIP, mdl)
	CenterPrint(VIP, "You are the VIP.")

	HookToPlayerDeath(function(dead) {
		if (VIP != null && dead == VIP)
		{
			::VIP <- null
			ChatPrintAll(" " + DARK_RED + "The VIP has been killed!")
			EntFire("round_end", "EndRound_TerroristsWin", "7")
			local n = 2
			if (RandomInt(1, 5) == 5)
			{
				n = 1
				if (RandomInt(1, 5) == 5)
					n = 3
			}
			EntFire("vipdown" + n, "playsound")
			EntFire("money_giver_t", "addteammoneyterrorist")
		}
	})
}

::RescueZone <- function(ply)
{
	if (VIP != null && ply == VIP)
	{
		::VIP <- null
		ChatPrintAll(" " + LIME + "The VIP has escaped!")
		EntFire("round_end", "EndRound_CounterTerroristsWin", "7")
		local n = 2
		if (RandomInt(1, 5) == 5)
			n = 1
		EntFire("vipwin" + n, "playsound")
		EntFire("money_giver_ct", "addteammoneyct")
	}
}
