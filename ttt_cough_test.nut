
local ply = Entities.FindByClassname(null, "player")
local coof = Entities.FindByName(null, "covid_snd" + RandomInt(1, 8))
if (coof != null)
{
	coof.SetOrigin(ply.EyePosition())
	EntFireHandle(coof, "playsound")
}
