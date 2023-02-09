
::env_hudhint <- Entities.CreateByClassname("env_hudhint")

::CenterPrint <- function(ply, text)
{
	env_hudhint.__KeyValueFromString("message", text)
	EntFireByHandle(env_hudhint, "ShowHudHint", "", 0.0, ply, null)
}

::GiveWeapon <- function(player, weapon)
{
	::game_player_equip <- Entities.CreateByClassname("game_player_equip")
	::game_player_equip.__KeyValueFromInt("spawnflags", 5)
	::game_player_equip.__KeyValueFromInt(weapon, 999999)
	EntFireByHandle(::game_player_equip, "Use", "", 0.0, player, null)
	::game_player_equip.__KeyValueFromInt(weapon, 0)
	::game_player_equip.Destroy()
}

::CheckChat <- function()
{
	local data = this.event_data
	local ply = GetPlayerFromUserID(data.userid)
	local text = data.text
	local args = split(text, " ")
	if (text == "CRUNCHATIZE ME CAP'N" && ply.ValidateScriptScope())
	{
		local scope = ply.GetScriptScope()
		scope.captain_crunch <- true
		CenterPrint(ply, "Crunchatization successful!")
	}
	if (text == "GIVE ME THE SUPER CRUNCH" && ply.ValidateScriptScope())
	{
		local scope = ply.GetScriptScope()
		scope.super_crunch <- Time() + 10
		CenterPrint(ply, "You now have  S U P E R   C R O N C H  for 10 seconds!")
	}
	if (text == "A B S O L U T E C R O N C H" && ply.ValidateScriptScope())
	{
		local scope = ply.GetScriptScope()
		scope.super_crunch <- Time() + 60
		CenterPrint(ply, "O H N O")
	}
	if (args[0] == "give" && typeof args[1] == "string")
	{
		GiveWeapon(ply, "weapon_" + args[1])
	}
}
