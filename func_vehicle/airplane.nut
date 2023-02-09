
// Make sure people can't get kicked from being run over
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
ApproachZero <- function(n, a)
{
	if (n > 0)
	{
		return Clamp(n - a, 0, n)
	}
	else if (n < 0)
	{
		return Clamp(n + a, n, 0)
	}
	return n
}

Car <- EntityGroup[0]
Start <- EntityGroup[1]
Dest <- EntityGroup[2]
GameUI <- EntityGroup[3]
Trigger <- EntityGroup[4]
SteeringWheel <- EntityGroup[5]

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
	if (MainScript.Destroyed)
	{
		return false
	}
	MainScript.StartDriving(activator)
	return true
}

GameUI.ConnectOutput("PlayerOff", "OnDeactivate")
GameUI_SS.OnDeactivate <- function()
{
	MainScript.StopDriving()
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

Destroyed <- false
Driver <- null
Speed <- 0.0
DesiredPitch <- 0.0
OldSpeed <- 0.1
TurnAngle <- 0.0
Falling <- false
FallSpeed <- 0.0

// Default handling, can be changed through RunScriptCode
Acceleration <- 0.1
Deceleration <- 0.06
TurnAngleStep <- 0.4
TurnAngleDecay <- 0.2
MaxTurnAngle <- 4
PitchStep <- 0.1
PitchDecay <- 0.05

BreakDown <- function()
{
	if (Driver != null)
	{
		EntFireHandle(GameUI, "Deactivate")
	}
	Destroyed <- true
}

StartDriving <- function(ply)
{
	EntFireHandle(Trigger, "Disable")
	EntFireHandle(Trigger, "Lock")
	Driver <- ply
}

StopDriving <- function()
{
	EntFireHandle(Trigger, "Enable")
	EntFireHandle(Trigger, "Unlock")
	Driver <- null
	HeldInputs = [false, false, false, false]
}

OnPostSpawn <- function()
{
	Car.PrecacheSoundScript("Bounce.Metal")
}

Think <- function()
{
	local inputs = false
	for (local i = 0; i < 4; i++)
		inputs = inputs || HeldInputs[i]

	// Make sure we update the speed as long as we have any inputs
	// This means the car won't slow down if we're just turning
	// If we don't do this, the car will break
	if (inputs)
	{
		if (HeldInputs[VEHICLE_BACK]) DesiredPitch -= PitchStep
		if (HeldInputs[VEHICLE_FORWARD]) DesiredPitch += PitchStep
		if (HeldInputs[VEHICLE_LEFT]) TurnAngle -= TurnAngleStep
		if (HeldInputs[VEHICLE_RIGHT]) TurnAngle += TurnAngleStep

		TurnAngle = Clamp(TurnAngle, -MaxTurnAngle, MaxTurnAngle)
	}
	else
	{
		DesiredPitch = ApproachZero(DesiredPitch, PitchDecay)
	}

	// Falling = (t == 1.0) && (Driver == null) && false

	// Buffer to make sure we never actually reach the destination path_track
	// (That always messes things up)
	local buffer = 12 * (Speed < 0 ? -1 : 1)
	local pos_start = Car.GetOrigin()
	local pos_dest = pos_start + (Car.GetForwardVector() * (buffer + (Speed * 100))) + (Car.GetLeftVector() * (TurnAngle * fabs(Speed)))

/*
	pos_dest.z += DesiredPitch * 20
	if (Falling)
	{
		
	}
	else if (false)
	{
		FallSpeed = 0
		local a = (highestSlopeTestPos.z - pos_dest.z) * ((pos_dest - pos_start).Length2D() / (highestSlopeTestPos - pos_start).Length2D()) * 1.5
		local b = DesiredPitch * 50
		pos_dest.z += DesiredPitch * 50
	}
*/

	if (Driver == null)
	{
		local heightOffset = Vector(0, 0, 60)
		local cornerPos = Car.GetOrigin()
		local t = TraceLine(cornerPos + heightOffset, cornerPos - heightOffset, Entities.FindByNameNearest("vehicle_ignore", cornerPos, 200))
		if (t > 0.5)
		{
			Falling = true
			FallSpeed = Clamp(FallSpeed + 5, 0, 100)
			pos_dest.z -= FallSpeed
		}
		else
		{
			if (Falling)
			{
				Car.EmitSound("Bounce.Metal")
				SteeringWheel.EmitSound("Bounce.Metal")
				Falling = false
			}
			FallSpeed = 0
			Speed = ApproachZero(Speed, Deceleration)
		}
		// local slope = (cornerPos + heightOffset - (heightOffset * 2 * t)).z - Car.GetOrigin().z
		// local highestSlopeTestPos = cornerPos + heightOffset - (heightOffset * 2 * t)
	}
	else
	{
		Speed = Clamp(Speed + Acceleration, 0, 1)
		pos_dest.z += DesiredPitch * 20
		FallSpeed = 0
	}

	// height limit
	if (pos_dest.z > 3700)
		pos_dest.z = 3700

	// Plane never go backward
	Start.SetOrigin(pos_start)
	Dest.SetOrigin(pos_dest)

	if (Speed != OldSpeed)
	{
		EntFireHandle(Car, "SetSpeedDir", Speed.tostring())
	}

	// Turn steering wheel
	SteeringWheel.SetAngles(0, 0, (TurnAngle / MaxTurnAngle) * 65)

	OldSpeed = Speed
	TurnAngle = ApproachZero(TurnAngle, TurnAngleDecay)

	// If the driver gets too far, kick him off the controls
	// If he falls off or gets stuck on something, we don't want an RC car
	if (Driver != null && DistToSqr(Driver.GetOrigin(), Trigger.GetOrigin()) > 16000)
		EntFireHandle(GameUI, "Deactivate")
}
