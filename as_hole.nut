
::TruckSpeedRange <- [40, 160]
::TruckSpeed <- 80

::AddTruckSpeed <- function(amt)
{
	::TruckSpeed <- Clamp(TruckSpeed + amt, TruckSpeedRange[0], TruckSpeedRange[1])
	EntFire("truck", "setspeed", ::TruckSpeed.tostring())
}

::RandomTruckSpeed <- function()
{
	EntFire("truck", "setspeed", RandomInt(30, 50).tostring())
}

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_autokick 0")
	ChatPrintAll("Glass will break in 15 seconds. Get to a vehicle, quick!")
}
