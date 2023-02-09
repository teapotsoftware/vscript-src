
ScriptPrintMessageChatAll("Welcome to AIM_SUPREME!")
ScriptPrintMessageChatAll("Type \"give <weapon name>\" in chat for a weapon.")

::AssignUserID <- function()
{
	local params = this.event_data
	if (::CapturedPlayer != null && params.entity == 0)
	{
		local script_scope = ::CapturedPlayer.GetScriptScope()
		script_scope.userid <- params.userid
		::CapturedPlayer = null
	}
}

if (!("gameevents_proxy" in getroottable()) || !(::gameevents_proxy.IsValid()))
{
	::gameevents_proxy <- Entities.CreateByClassname("info_game_event_proxy")
	::gameevents_proxy.__KeyValueFromString("event_name", "player_use")
	::gameevents_proxy.__KeyValueFromInt("range", 0)
}

::CapturedPlayer<-null

Think <- function()
{
	ply <- null
	while((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		if (ply.ValidateScriptScope())
		{
			local script_scope = ply.GetScriptScope()
			if (!("userid" in script_scope) && !("attemptogenerateuserid" in script_scope))
			{
				script_scope.attemptogenerateuserid <- true
				::CapturedPlayer = ply
				EntFireByHandle(::gameevents_proxy, "GenerateGameEvent", "", 0.0, ply, null)
				return
			}
			if ("super_crunch" in script_scope && script_scope.super_crunch > Time())
			{
				AimbotPlayer(ply)
			}
		}
	}
}
