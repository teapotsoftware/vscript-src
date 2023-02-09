
SendToConsoleServer("mp_autokick 0")

::EntFireHandle <- function(t, i, v = "", d = 0.0, a = null, c = null) EntFireByHandle(t, i, v, d, a, c)

::VEHICLE_BACK <- 0
::VEHICLE_FORWARD <- 1
::VEHICLE_LEFT <- 2
::VEHICLE_RIGHT <- 3

sqr <- function(x) return x * x
DistToSqr <- function(a, b) return sqr(a.x - b.x) + sqr(a.y - b.y) + sqr(a.z - b.z)
Clamp <- function(x, min, max)
{
	if (x < min) return min
	if (x > max) return max
	return x
}
Approach <- function(d, n, a)
{
	if (n > d)
	{
		return Clamp(n - a, d, n)
	}
	else if (n < d)
	{
		return Clamp(n + a, n, d)
	}
	return n
}

Car <- EntityGroup[0]
Start <- EntityGroup[1]
Dest <- EntityGroup[2]
GameUI <- EntityGroup[3]
Trigger <- EntityGroup[4]
if (5 in EntityGroup && EntityGroup[5] != null)
	Hurt <- EntityGroup[5]
if (6 in EntityGroup && EntityGroup[6] != null)
	Wheels <- EntityGroup[6]

Car.__KeyValueFromInt("spawnflags", 3)

Trigger_SS <- null
if (Trigger.ValidateScriptScope())
	Trigger_SS <- Trigger.GetScriptScope()

Trigger.ConnectOutput("OnStartTouch", "Triggered")
Trigger.ConnectOutput("OnPressed", "Triggered")
Trigger.ConnectOutput("OnOpen", "Triggered")
Trigger_SS.GameUI <- GameUI
Trigger_SS.Triggered <- function()
{
	EntFireHandle(GameUI, "Activate", "", 0.0, activator, self)
}
GameUI.__KeyValueFromInt("spawnflags", 416)

GameUI_SS <- null
if (GameUI.ValidateScriptScope())
	GameUI_SS <- GameUI.GetScriptScope()

GameUI_SS.MainScript <- this
GameUI_SS.InputActivate <- function()
{
	MainScript.StartDriving(activator)
	return true
}

GameUI.ConnectOutput("PlayerOff", "OnDeactivate")
GameUI_SS.OnDeactivate <- function()
{
	MainScript.StopDriving(activator)
}

HeldInputs <- [false, false, false, false]

GameUI.ConnectOutput("PressedBack", "GoBack")
GameUI.ConnectOutput("PressedForward", "GoForward")
GameUI.ConnectOutput("PressedMoveLeft", "GoLeft")
GameUI.ConnectOutput("PressedMoveRight", "GoRight")
GameUI.ConnectOutput("UnpressedBack", "StopBack")
GameUI.ConnectOutput("UnpressedForward", "StopForward")
GameUI.ConnectOutput("UnpressedMoveLeft", "StopLeft")
GameUI.ConnectOutput("UnpressedMoveRight", "StopRight")
GameUI_SS.GoBack <- function() {MainScript.HeldInputs[VEHICLE_BACK] = true}
GameUI_SS.GoForward <- function() {MainScript.HeldInputs[VEHICLE_FORWARD] = true}
GameUI_SS.GoLeft <- function() {MainScript.HeldInputs[VEHICLE_LEFT] = true}
GameUI_SS.GoRight <- function() {MainScript.HeldInputs[VEHICLE_RIGHT] = true}
GameUI_SS.StopBack <- function() {MainScript.HeldInputs[VEHICLE_BACK] = false}
GameUI_SS.StopForward <- function() {MainScript.HeldInputs[VEHICLE_FORWARD] = false}
GameUI_SS.StopLeft <- function() {MainScript.HeldInputs[VEHICLE_LEFT] = false}
GameUI_SS.StopRight <- function() {MainScript.HeldInputs[VEHICLE_RIGHT] = false}

Driver <- null
Speed <- 0.0
OldSpeed <- 0.1
TurnAngle <- 0
LastDriverTime <- 0

// Altitude-related variables
BaseAltitude <- Car.GetOrigin().z
Altitude <- 0
MaxAltitude <- 720
AltitudeStep <- 5

// Configurable for helicopters that start on a helipad high up
StartAltitude <- 0

SetStartAltitude <- function(alt)
{
	local offset = alt - StartAltitude
	BaseAltitude -= offset * AltitudeStep
	Altitude += offset
}

CalcCurrentAltitude <- function()
{
	local offsetZ = Car.GetOrigin().z - BaseAltitude
	Altitude = ceil(offsetZ / AltitudeStep)
}

StartDriving <- function(ply)
{
	CalcCurrentAltitude()
	EntFireHandle(Trigger, "Disable")
	EntFireHandle(Trigger, "Lock")
	Driver <- ply
	CenterPrint(ply, "W: forward + up\nS: forward + down\nA/D: turn left/right")
}

StopDriving <- function(ply)
{
	CalcCurrentAltitude()
	EntFireHandle(Trigger, "Enable")
	EntFireHandle(Trigger, "Unlock")
	Driver <- null
	HeldInputs = [false, false, false, false]
	LastDriverTime <- Time()
}

ChangeAltitude <- function(amt)
{
	Altitude = Clamp(Altitude + amt, 0, MaxAltitude)
}

Think <- function()
{
	local DesiredAltitude = BaseAltitude + (Altitude * AltitudeStep)

	// If we have any inputs at all
	local inputs = false
	for (local i = 0; i < 4; i++)
		inputs = inputs || HeldInputs[i]

	if (inputs)
	{
		if (HeldInputs[VEHICLE_BACK] || HeldInputs[VEHICLE_FORWARD]) {
			Speed += 0.2
			if (!(HeldInputs[VEHICLE_BACK] && HeldInputs[VEHICLE_FORWARD])) {
				if (HeldInputs[VEHICLE_FORWARD]) ChangeAltitude(2)
				if (HeldInputs[VEHICLE_BACK]) ChangeAltitude(-3)
			}
		}
		if (HeldInputs[VEHICLE_LEFT]) TurnAngle -= 2
		if (HeldInputs[VEHICLE_RIGHT]) TurnAngle += 2

		Speed = Clamp(Speed, -0.5, 1)
		TurnAngle = Clamp(TurnAngle, -9, 9)
	} else {
		// If we aren't near our target height, go at 60% speed until we are
		local NearTargetHeight = fabs(Car.GetOrigin().z - DesiredAltitude) < 1
		Speed = Approach(NearTargetHeight ? 0 : 0.6, Speed, 0.1)
	}

	local pos_start = Car.GetOrigin()

	// Buffer to make sure we never actually reach the destination path_track
	// (That would always messes things up)
	local buffer = 12 * (Speed < 0 ? -1 : 1)
	local pos_dest = pos_start + (Car.GetForwardVector() * (buffer + (Speed * 100))) + (Car.GetLeftVector() * (TurnAngle * fabs(Speed)))

	if (Driver == null && Time() - LastDriverTime >= 10)
	{
		local heightOffset = Vector(0, 0, 400)
		local heliPos = Car.GetOrigin()
		local t = TraceLine(heliPos + Vector(0, 0, 5), heliPos - heightOffset, Entities.FindByNameNearest("vehicle_ignore", heliPos, 200))
		pos_dest.z = (heliPos - heightOffset * t).z
		Speed = t > 0.05 ? 0.1 : 0
	}
	else
	{
		// Keep the car "in gear" as long as we have a driver
		// If we don't do this, the car will break
		if (Driver != null && Speed == 0)
			Speed = 0.01

		// Go to desired altitude
		pos_dest.z = DesiredAltitude
	}

	// If we're going backwards, the start path_track is our destination
	if (Speed < 0)
	{
		Start.SetOrigin(pos_dest)
		Dest.SetOrigin(pos_start)
	}
	else
	{
		Start.SetOrigin(pos_start)
		Dest.SetOrigin(pos_dest)
	}

	if (Speed != OldSpeed)
	{
		EntFireHandle(Car, "SetSpeedDir", Speed.tostring())

		if ("Hurt" in this)
		{
			local damage = Speed * 220
			Hurt.__KeyValueFromInt("damage", damage)
			EntFireHandle(Hurt, (damage > 1 ? "En" : "Dis") + "able")
		}

		if ("Wheels" in this)
		{
			EntFire(Wheels.GetName(), "SetSpeed", Speed.tostring())
		}
	}

	OldSpeed = Speed
	TurnAngle = Approach(0, TurnAngle, 1)

	// If the driver gets too far, kick him off the controls
	// For example, if he falls off or gets stuck on something
	if (Driver != null && DistToSqr(Driver.GetOrigin(), Trigger.GetOrigin()) > 16000)
		EntFireHandle(GameUI, "Deactivate")
}
