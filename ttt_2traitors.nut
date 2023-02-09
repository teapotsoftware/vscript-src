
local idiots = ["Eddie", "Aidan", "Jack", "Nick", "JD", "Shawn", "Elton", "Kate", "Ryan", "Noah"]
local i = RandomInt(0, idiots.len() - 1)
local ts = idiots[i] + " and "
idiots.remove(i)
i = RandomInt(0, idiots.len() - 1)
ts += idiots[i]
idiots.remove(i)
ScriptPrintMessageChatAll("The traitors this round will be " + ts)
if (RandomInt(1, 3) == 1)
	ScriptPrintMessageChatAll("And the jester will be " + idiots[RandomInt(0, idiots.len() - 1)])

