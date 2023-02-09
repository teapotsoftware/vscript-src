
::EntFireHandle <- function(t, i, v = "", d = 0.0, a = null, c = null) {EntFireByHandle(t, i, v, d, a, c)}

Clamp <- function(x, min, max)
{
	if (x < min) return min
	if (x > max) return max
	return x
}

::VEHICLE_BACK <- 0
::VEHICLE_FORWARD <- 1
::VEHICLE_LEFT <- 2
::VEHICLE_RIGHT <- 3

Car <- EntityGroup[0]
Start <- EntityGroup[1]
Dest <- EntityGroup[2]
GameUI <- EntityGroup[3]
Trigger <- EntityGroup[4]

Car.__KeyValueFromInt("spawnflags", 2)

Trigger_SS <- null
if (Trigger.ValidateScriptScope())
	Trigger_SS <- Trigger.GetScriptScope()

Trigger.ConnectOutput("OnStartTouch", "Triggered")
Trigger.ConnectOutput("OnPressed", "Triggered")
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

GameUI.ConnectOutput("PressedBack", "GoBack")
GameUI.ConnectOutput("PressedForward", "GoForward")
GameUI.ConnectOutput("PressedMoveLeft", "GoLeft")
GameUI.ConnectOutput("PressedMoveRight", "GoRight")
GameUI_SS.GoBack <- function() {MainScript.VehicleInput(VEHICLE_BACK)}
GameUI_SS.GoForward <- function() {MainScript.VehicleInput(VEHICLE_FORWARD)}
GameUI_SS.GoLeft <- function() {MainScript.VehicleInput(VEHICLE_LEFT)}
GameUI_SS.GoRight <- function() {MainScript.VehicleInput(VEHICLE_RIGHT)}

Driver <- null
Speed <- 0.0
OldSpeed <- 0.1
TurnAngle <- 0
TargetHeight <- 0
HeightBaseline <- false

StartDriving <- function(ply)
{
	EntFireHandle(Trigger, "Disable")
	EntFireHandle(Trigger, "Lock")
	Driver <- ply
}

StopDriving <- function(ply)
{
	EntFireHandle(Trigger, "Enable")
	EntFireHandle(Trigger, "Unlock")
	Driver <- null
	Speed = 0
	TurnAngle = 0
}

VehicleInput <- function(type)
{
	if (type == VEHICLE_FORWARD)
	{
		Speed += 0.25
	}
	else if (type == VEHICLE_BACK)
	{
		Speed -= 0.25
	}
	else if (type == VEHICLE_LEFT)
	{
		TurnAngle -= 3
	}
	else if (type == VEHICLE_RIGHT)
	{
		TurnAngle += 3
	}

	Speed = Clamp(Speed, 0, 1)
	TurnAngle = Clamp(TurnAngle, -9, 9)

	if (Speed == 0)
		TurnAngle = 0
}

Think <- function()
{
	local ourpos = Car.GetOrigin()
	local targpos = ourpos + (Car.GetForwardVector() * 120) + (Car.GetLeftVector() * TurnAngle)

	Start.SetOrigin(ourpos)
	Dest.SetOrigin(targpos)

	if (Speed != OldSpeed)
	{
		EntFireHandle(Car, "SetSpeedDir", Speed.tostring())
		EntFireHandle(Car, "Start")
	}

	if (TurnAngle > 0) TurnAngle--
	if (TurnAngle < 0) TurnAngle++

	OldSpeed <- Speed
}
