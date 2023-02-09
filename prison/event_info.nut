
//::gameevents_proxy <- Entities.CreateByClassname("info_game_event_proxy")
//::gameevents_proxy.__KeyValueFromString("event_name", "player_info")
//::gameevents_proxy.__KeyValueFromInt("range", 0)

::PlayerData <- {}

::UpdatePlayerInfo <- function()
{
	local data = this.event_data
	P(data.name + " id: " + data.userid)
	::PlayerData[data.userid] <- this.event_data
	P(::PlayerData.len().tostring())
}

::GetSteamName <- function(ply)
{
	return PlayerData[GetUserID(ply)].name
}

::GetSteamID <- function(ply)
{
	return PlayerData[GetUserID(ply)].networkid
}

// yikes!
::GetIP <- function(ply)
{
	return PlayerData[GetUserID(ply)].address
}
