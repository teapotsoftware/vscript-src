
local part = null
local num = 1

while (part = Entities.FindByName(part, "pirateship_breakable"))
{
	printl("Part #" + num + ": " + part.GetHealth() + "/" + part.GetMaxHealth())
	num++
}
