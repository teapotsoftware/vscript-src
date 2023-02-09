
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
Hurt <- EntityGroup[5]
Wheels <- EntityGroup[6]
TurnSignalLeft <- EntityGroup[7]
TurnSignalRight <- EntityGroup[8]
BrakeLights <- EntityGroup[9]
SteeringWheel <- EntityGroup[10]

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
OldSpeed <- 0.1
TurnAngle <- 0.0
TargetHeight <- 0.0
NextTurnSignal <- 0.0

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
		if (HeldInputs[VEHICLE_BACK]) Speed -= 0.1
		if (HeldInputs[VEHICLE_FORWARD]) Speed += 0.1
		if (HeldInputs[VEHICLE_LEFT]) TurnAngle -= 2
		if (HeldInputs[VEHICLE_RIGHT]) TurnAngle += 2

		Speed = Clamp(Speed, -0.5, 1)
		TurnAngle = Clamp(TurnAngle, -9, 9)
	}
	else
	{
		Speed = ApproachZero(Speed, 0.05)
	}

	// Keep the car "in gear" as long as we have a driver
	// If we don't do this, the car will break
	if (Driver != null && Speed == 0)
		Speed = 0.01

	// Buffer to make sure we never actually reach the destination path_track
	// (That always messes things up)
	local buffer = 12 * (Speed < 0 ? -1 : 1)
	local pos_start = Car.GetOrigin()
	local pos_dest = pos_start + (Car.GetForwardVector() * (buffer + (Speed * 100))) + (Car.GetLeftVector() * (TurnAngle * fabs(Speed)))
	local magnitude = fabs(Speed * 100)

	// Go up and down slopes
	// The length of the vertical trace line scales with speed,
	//     because we'll be going up or down faster
	// Ignore physboxes because they make the car sink sometimes
	local height_offset = Vector(0, 0, magnitude)
	local t = TraceLine(pos_dest + height_offset, pos_dest - height_offset, Entities.FindByNameNearest("vehicle_ignore", pos_dest, 200))
	pos_dest.z += magnitude - (magnitude * t * 2)

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

		// Run over damage based on speed
		local damage = Speed * 220
		Hurt.__KeyValueFromInt("damage", damage)
		EntFireHandle(Hurt, (damage > 1 ? "En" : "Dis") + "able")

		// Spin wheels
		EntFire(Wheels.GetName(), "SetSpeed", Speed.tostring())
	}

	// Turn signal blinker
	if (Speed > 0 && abs(TurnAngle) > 2 && Time() >= NextTurnSignal)
	{
		local signal = (TurnAngle < 0) ? TurnSignalLeft : TurnSignalRight
		EntFire(signal.GetName(), "ShowSprite")
		EntFire(signal.GetName(), "HideSprite", "", 0.3)
		NextTurnSignal = Time() + 0.6
	}

	// Brake lights unless we're going forward
	EntFire(BrakeLights.GetName(), (HeldInputs[VEHICLE_FORWARD] ? "Hide" : "Show") + "Sprite")

	// Turn steering wheel
	SteeringWheel.SetAngles(0, 0, TurnAngle * 6)

	OldSpeed = Speed
	TurnAngle = ApproachZero(TurnAngle, 1)

	// If the driver gets too far, kick him off the controls
	// If he falls off or gets stuck on something, we don't want an RC car
	if (Driver != null && DistToSqr(Driver.GetOrigin(), Trigger.GetOrigin()) > 16000)
		EntFireHandle(GameUI, "Deactivate")
}
