
SendToConsoleServer("mp_autokick 0")

::LightningStrike <- function()
{
	local delay = RandomFloat(0.5, 1.2)
	EntFire("thunder", "addoutput", "message ambient/weather/thunderstorm/lightning_strike_" + RandomInt(1, 4) + ".wav", delay)
	EntFire("thunder", "playsound", "", delay)
	EntFire("lightning", "turnon", "", delay)
	EntFire("lightning", "turnoff", "", delay + RandomFloat(0.3, 0.8))
}

OnPostSpawn <- function()
{
	if (RandomInt(1, 2) == 2)
		LightningStrike()
}
