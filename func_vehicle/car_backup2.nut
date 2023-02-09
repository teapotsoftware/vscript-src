
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
if (6 in EntityGroup && EntityGroup[6] != null)
	Wheels <- EntityGroup[6]
TurnSignalLeft <- EntityGroup[7]
TurnSignalRight <- EntityGroup[8]
BrakeLights <- EntityGroup[9]
if (10 in EntityGroup && EntityGroup[10] != null)
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
VehicleBounds <- []
Falling <- false
FallSpeed <- 0.0

// Default handling, can be changed through RunScriptCode
SpeedStep <- 0.1
TurnAngleStep <- 3
TurnAngleDecay <- 1.5
MaxTurnAngle <- 14
MaxBackwardSpeed <- 0.5
SpeedDecay <- 0.05

SetVehicleBounds <- function(back, fwd, sides)
{
	VehicleBounds.push(Vector(sides, -back, 0))
	VehicleBounds.push(Vector(-sides, -back, 0))
	VehicleBounds.push(Vector(sides, fwd, 0))
	VehicleBounds.push(Vector(-sides, fwd, 0))

	// Life hack: Z axis caches the distance to that corner from the center of the car
	for (local i = 0; i < VehicleBounds.len(); i++)
	{
		VehicleBounds[i].z = VehicleBounds[i].Length2D()
	}
}

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
		if (HeldInputs[VEHICLE_BACK]) Speed -= SpeedStep
		if (HeldInputs[VEHICLE_FORWARD]) Speed += SpeedStep
		if (HeldInputs[VEHICLE_LEFT]) TurnAngle -= TurnAngleStep
		if (HeldInputs[VEHICLE_RIGHT]) TurnAngle += TurnAngleStep

		Speed = Clamp(Speed, -MaxBackwardSpeed, 1)
		TurnAngle = Clamp(TurnAngle, -MaxTurnAngle, MaxTurnAngle)
	}
	else
	{
		Speed = ApproachZero(Speed, SpeedDecay)
	}

	// Do a trace at all four corners of the car
	local heightOffset = Vector(0, 0, 60)
	
	local highestSlope = 0
	local highestSlopeTestPos = Vector(0, 0, 0)
	for (local i = 0; i < 4; i++)
	{
		if (!(i in VehicleBounds))
		{
			break
		}
		local cornerPos = Car.GetOrigin() + Car.GetLeftVector() * VehicleBounds[i].x + Car.GetForwardVector() * VehicleBounds[i].y
		local t = TraceLine(cornerPos + heightOffset, cornerPos - heightOffset, Entities.FindByNameNearest("vehicle_ignore", cornerPos, 200))

		DebugDrawLine(cornerPos + heightOffset, cornerPos + heightOffset - (heightOffset * 2 * t), 0, 150, 0, true, 0.12)
		DebugDrawLine(cornerPos + heightOffset - (heightOffset * 2 * t), cornerPos - heightOffset, 150, 0, 0, true, 0.12)

		// If we're going into a wall, bounce off
		/*
		printl("#" + i + ": " + t)
		if (t == 1)
		{
			local t2 = TraceLine(Car.GetOrigin(), cornerPos, Entities.FindByNameNearest("vehicle_ignore", cornerPos, 200))
			if (t2 < 1)
			{
				if (i < 2 && Speed < 0)
				{
					Speed = 1
				}
				else if (i > 1 && Speed > 0)
				{
					Speed = -1
				}
			}
		}
		*/

		local slope = ((cornerPos + heightOffset - (heightOffset * 2 * t)).z - Car.GetOrigin().z) / VehicleBounds[i].z
		if (i == 0 || slope > highestSlope)
		{
			highestSlope = slope
			highestSlopeTestPos = cornerPos + heightOffset - (heightOffset * 2 * t)
		}
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
	// local magnitude = fabs(Speed * 100)

	// pos_dest.z = Car.GetOrigin().z + ((pos_dest - Car.GetOrigin()).Length2D() * highestSlope)
	pos_dest.z += (highestSlopeTestPos.z - pos_dest.z) * ((pos_dest - pos_start).Length2D() / (highestSlopeTestPos - pos_start).Length2D())
	// DebugDrawLine(pos_start, pos_dest, 150, 0, 150, true, 0.12)
	//DebugDrawLine(pos_start, highestSlopeTestPos, 0, 150, 150, true, 0.12)

	// Go up and down slopes
	// The length of the vertical trace line scales with speed,
	//     because we'll be going up or down faster
	// Ignore physboxes because they make the car sink sometimes
	// local height_offset = Vector(0, 0, magnitude)
	// local t = TraceLine(pos_dest + height_offset, pos_dest - height_offset, Entities.FindByNameNearest("vehicle_ignore", pos_dest, 200))
	// pos_dest.z += magnitude - (magnitude * t * 2)

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
		if ("Wheels" in this)
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
	if ("SteeringWheel" in this)
		SteeringWheel.SetAngles(0, 0, (TurnAngle / MaxTurnAngle) * 65)

	OldSpeed = Speed
	TurnAngle = ApproachZero(TurnAngle, TurnAngleDecay)

	// If the driver gets too far, kick him off the controls
	// If he falls off or gets stuck on something, we don't want an RC car
	if (Driver != null && DistToSqr(Driver.GetOrigin(), Trigger.GetOrigin()) > 16000)
		EntFireHandle(GameUI, "Deactivate")
}
