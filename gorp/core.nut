::GORP_LONGNAME <- "Global Offensive Roleplay";
::GORP_SHORTNAME <- "GORP";
::GORP_VERSION <- "v0.1 ALPHA";
::GORP_AUTHOR <- "Sir Francis Billard";

::CT <- 2;
::T <- 3;

SendToConsoleServer("mp_warmup_end");
SendToConsoleServer("mp_roundtime 9999999999");
SendToConsoleServer("mp_roundtime_defuse 9999999999");
SendToConsoleServer("mp_roundtime_hostage 9999999999");
SendToConsoleServer("mp_ignore_round_win_conditions 1");
SendToConsoleServer("mp_teammates_are_enemies 1");
SendToConsoleServer("mp_buy_anywhere 1");
SendToConsoleServer("mp_respawn_on_death_ct 1");
SendToConsoleServer("mp_respawn_on_death_t 1");
SendToConsoleServer("mp_limitteams 0");
SendToConsoleServer("mp_autoteambalance 0");
SendToConsoleServer("mp_give_player_c4 0");
SendToConsoleServer("mp_startmoney 200");
SendToConsoleServer("mp_maxmoney 1000000");
SendToConsoleServer("mp_buytime 9999999999");

::OnGameEvent_player_chat <- function(team, uid, txt)
{
	ply <- GetPlayerForUserID(uid);
	ScriptPrintMessageChatAll(txt);
	ScriptPrintMessageChatAll(ply.GetHealth());
}

ScriptPrintMessageChatAll(GORP_LONGNAME);
ScriptPrintMessageChatAll(GORP_SHORTNAME + " " + GORP_VERSION);
ScriptPrintMessageChatAll("By " + GORP_AUTHOR);
