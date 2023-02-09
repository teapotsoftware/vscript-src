
IncludeScript("butil")

::ANY_SHIP_SANK <- false
THIS_SHIP_SANK <- false

::VEHICLE_BACK <- 0
::VEHICLE_FORWARD <- 1
::VEHICLE_LEFT <- 2
::VEHICLE_RIGHT <- 3

Car <- EntityGroup[0]
Start <- EntityGroup[1]
Dest <- EntityGroup[2]
GameUI <- EntityGroup[3]
Trigger <- EntityGroup[4]
Wheel <- EntityGroup[5]

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
Speed <- 0.4
OldSpeed <- 0.1
TurnAngle <- 0
HeightBaseline <- false

BoatHeight <- 100
HullIntegrity <- 1.0
MastIntegrity <- 1.0
MinimumSpeed <- 0.4
MaximumSpeed <- 1.0

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
	HeldInputs = [false, false, false, false]
}

Think <- function()
{
	if (!HeightBaseline)
	{
		HeightBaseline = Car.GetOrigin().z
	}

	if (HullIntegrity > 0)
	{
		// If we have any inputs at all
		local inputs = false
		for (local i = 0; i < 4; i++)
			inputs = inputs || HeldInputs[i]

		if (inputs)
		{
			if (HeldInputs[VEHICLE_BACK]) Speed -= 0.1
			if (HeldInputs[VEHICLE_FORWARD]) Speed += 0.1
			if (HeldInputs[VEHICLE_LEFT]) TurnAngle -= 0.03
			if (HeldInputs[VEHICLE_RIGHT]) TurnAngle += 0.03

			Speed = Clamp(Speed, MinimumSpeed, MinimumSpeed + MastIntegrity * (MaximumSpeed - MinimumSpeed))
			TurnAngle = Clamp(TurnAngle, MastIntegrity * -1.5, MastIntegrity * 1.5)
		}
		else
		{
			// Speed = Approach(Speed, 0.4, 0.05)
		}
	}
	else
	{
		Speed = 0.4
		TurnAngle = 0
	}

	// Buffer to make sure we never actually reach the destination path_track
	// (That would always messes things up)
	local buffer = 12 * (Speed < 0 ? -1 : 1)
	local pos_start = Car.GetOrigin()
	local pos_dest = pos_start + (Car.GetForwardVector() * (buffer + (Speed * 100))) + (Car.GetLeftVector() * (TurnAngle * fabs(Speed)))
	pos_dest.z = HeightBaseline - (BoatHeight * (1 - HullIntegrity))
	local magnitude = fabs(Speed * 100)

	Start.SetOrigin(pos_start)
	Dest.SetOrigin(pos_dest)

	if (Speed != OldSpeed)
	{
		EntFireHandle(Car, "SetSpeedDir", Speed.tostring())
	}

	OldSpeed = Speed
	// TurnAngle = Approach(TurnAngle, 0, 0.05)
	// TurnAngle *= 0.8

	// If the driver gets too far, kick him off the controls
	// For example, if he falls off or gets stuck on something
	if (Driver != null && (DistToSqr(Driver.GetOrigin(), Trigger.GetOrigin()) > 16000 || HullIntegrity < 0))
	{
		EntFireHandle(GameUI, "Deactivate")
	}

	local CurrentWheelAngle = Wheel.GetAngles().z * 0.01
	local DesiredWheelAngle = TurnAngle

	//local speed = DesiredWheelAngle - CurrentWheelAngle
	//if (abs(speed) > 0.001)
	//	speed = speed < 0 ? -1 : 1

	EntFireHandle(Wheel, "SetSpeed", (DesiredWheelAngle - CurrentWheelAngle).tostring())
}

BreakMast <- function()
{
	MastIntegrity -= 0.3
}

BreakHull <- function()
{
	HullIntegrity -= 0.036
	if (HullIntegrity <= 0)
	{
		HullIntegrity = -8

		THIS_SHIP_SANK <- true
		if (!ANY_SHIP_SANK)
		{
			::ANY_SHIP_SANK <- true

			if (!ScriptIsWarmupPeriod())
			{
				EntFire("round_ender", "EndRound_" + (Car.GetName() == "pirateship" ? "Counter" : "") + "TerroristsWin", "10")
			}

			//ForEachPlayerAndBot(function(ply) {
			//	local cam_name = Car.GetName() + "_sinkcam"
			//	EntFire(cam_name, "enable", "", 0, ply)
			//	EntFire(cam_name, "disable", "", 7, ply)
			//})
		}
	}
}

::BoardShip <- function(ply, num)
{
	local exit = Entities.FindByNameNearest("@pirateship_tp_" + num, ply.GetOrigin(), 2000)
	if (exit != null)
	{
		ply.SetOrigin(exit.GetOrigin())
		local a = exit.GetAngles()
		ply.SetAngles(a.x, a.y, a.z)
	}
}
