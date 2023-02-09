
if ("timer_init" in getroottable())
{
	ScriptPrintMessageChatAll("Timer script already loaded!")
	return
}

::timer_init <- true
ScriptPrintMessageChatAll("Timer script loaded!")
ScriptPrintMessageChatAll("Kill a chicken to start/stop the timer.")

ClientCMD <- Entities.CreateByClassname("point_broadcastclientcommand")
ClientCMD.__KeyValueFromString("targetname", "timer_cmd")

::TimerActive <- false
::TimerTime <- 0.0

::Timer <- function()
{
	local time = (Time() - TimerTime)
	if (time < 0.001)
	{
		return
	}
	if (::TimerActive)
	{
		ScriptPrintMessageChatAll("Time: " + time + " seconds.")
	}
	else
	{
		::TimerActive <- true
	}
	EntFire("chicken", "addoutput", "onbreak player:runscriptcode:Timer():0:-1")
	EntFire("timer_cmd", "command", "playvol buttons/blip1 0.4")
	::TimerTime <- Time()
}

Timer()

/*
::StartTimer <- function()
{
	if (TimerActive)
	{
		ScriptPrintMessageChatAll("Timer restarted. Time was " + (Time() - Timer) + " seconds.")
	}
	else
	{
		ScriptPrintMessageChatAll("Timer started. Kill any chicken to stop the timer.")
		::TimerActive <- true
	}
	EntFire("chicken", "addoutput", "onbreak player:runscriptcode:StopTimer():0:-1")
	EntFire("timer_cmd", "command", "playvol buttons/blip1 1")
	Timer <- Time()
}

::StopTimer <- function()
{
	ScriptPrintMessageChatAll("Timer stopped. Time was " + (Time() - Timer) + " seconds.")
	EntFire("timer_cmd", "command", "playvol buttons/blip1 1")
	::TimerActive <- false
}
*/
