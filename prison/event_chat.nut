
::CheatCodes <- function()
{
	local data = this.event_data
	local ply = GetPlayerFromUserID(data.userid)
	local text = data.text
	if (text == "ping")
	{
		P("pong")
	}
	else if (text == "keycard plz")
	{
		GiveKeycard(ply)
	}
	else if (text == "addict")
	{
		SnortCocaine(ply)
	}
	else if (text == "coldwar")
	{
		EntFire("nuke", "trigger", "", 0, ply)
	}
	else if (text == "shawshank redemption")
	{
		EntFire("intercom_music", "playsound", "", 0, ply)
	}
	else if (text == "shawshank redemption stop")
	{
		EntFire("intercom_music", "stopsound", "", 0, ply)
	}
	else if (text == "about me")
	{
		CenterPrint(ply, GetSteamName(ply) + " - " + GetSteamID(ply) + " - " + GetIP(ply))
	}
	else if (text == "debug player info")
	{
		foreach (key, value in PlayerData)
		{
			P("Key: " + key + " has the value: " + value);
		}
	}
}
