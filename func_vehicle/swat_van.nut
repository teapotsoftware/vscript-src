
::FORWARD <- 1
::BACK <- 2
::LEFT <- 3
::RIGHT <- 4

Car <- EntityGroup[0]
Start <- EntityGroup[1]
Dest <- EntityGroup[2]
GameUI <- EntityGroup[3]
Trigger <- EntityGroup[4]
LowerBounds <- EntityGroup[5].GetOrigin()
UpperBounds <- EntityGroup[6].GetOrigin()

// entity creation (busted)

/*
local prefix = Car.GetName()
local carangles = Car.GetAngles()

Start <- Entities.CreateByClassname("path_track")
Start.__KeyValueFromString("targetname", prefix + "_start_track")
Start.__KeyValueFromString("target", prefix + "_end_track")
Start.SetOrigin(Car.GetOrigin())
Start.SetAngles(carangles.x, carangles.y, carangles.z)

Dest <- Entities.CreateByClassname("path_track")
Dest.__KeyValueFromString("targetname", prefix + "_end_track")
Dest.SetOrigin(Car.GetOrigin())
Dest.SetAngles(carangles.x, carangles.y, carangles.z)

GameUI <- Entities.CreateByClassname("game_ui")
GameUI.__KeyValueFromString("targetname", prefix + "_controls")
GameUI.__KeyValueFromInt("spawnflags", 288)
*/

// trigger setup

Trigger_SS <- null
if (Trigger.ValidateScriptScope()) Trigger_SS <- Trigger.GetScriptScope()

Trigger.ConnectOutput("OnStartTouch", "Triggered")
Trigger.ConnectOutput("OnPressed", "Triggered")
Trigger_SS.GameUI <- GameUI
Trigger_SS.Triggered <- function()
{
	EntFireByHandle(GameUI, "Activate", "", 0.0, activator, self)
	//EntFire(GameUI.GetName(), "Activate", "", 0.0, activator)
}

// game_ui setup

// 32 : Freeze Player
// 64 : Hide Weapon
// 128 : +Use Deactivates
// 256 : Jump Deactivates
GameUI.__KeyValueFromInt("spawnflags", 288)

GameUI_SS <- null
if (GameUI.ValidateScriptScope()) GameUI_SS <- GameUI.GetScriptScope()

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
GameUI_SS.GoBack <- function() {MainScript.VehicleInput(BACK)}
GameUI_SS.GoForward <- function() {MainScript.VehicleInput(FORWARD)}
GameUI_SS.GoLeft <- function() {MainScript.VehicleInput(LEFT)}
GameUI_SS.GoRight <- function() {MainScript.VehicleInput(RIGHT)}

// util functions

Clamp <- function(x, min, max)
{
	if (x > max) return max;
	if (x < min) return min;
	return x;
}

Distance2D <- function(v1, v2)
{
	local a = (v2.x - v1.x)
	local b = (v2.y - v1.y)

	return sqrt((a * a) + (b * b))
}

AngleBetween <- function(v1, v2)
{
	local aZ = atan2((v1.y - v2.y), (v1.x - v2.x)) + PI
	local aY = atan2((v1.z - v2.z), Distance2D(v1, v2)) + PI

	return Vector(aY, aZ, 0.0)
}

point_clientcommand <- Entities.CreateByClassname("point_clientcommand")

SendCommandToClient <- function(player, command)
{
	EntFireByHandle(point_clientcommand, "Command", command, 0, player, point_clientcommand)
}

// car setup

Driver <- null
Speed <- 0.0
TurnAngle <- 0
TargetHeight <- 0
HeightBaseline <- false

StartDriving <- function(ply)
{
	EntFireByHandle(Trigger, "Disable", "", 0.0, null, null)
	EntFireByHandle(Trigger, "Lock", "", 0.0, null, null)
	Driver <- ply
	point_clientcommand <- Entities.CreateByClassname("point_clientcommand")
	EntFireByHandle(point_clientcommand, "Command", "play vehicles/vehicle_ignition", 0, ply, point_clientcommand)
	point_clientcommand.Destroy()
}

StopDriving <- function(ply)
{
	EntFireByHandle(Trigger, "Enable", "", 0.0, null, null)
	EntFireByHandle(Trigger, "Unlock", "", 0.0, null, null)
	Driver <- null
}

VehicleInput <- function(type)
{
	if (type == FORWARD)
	{
		Speed += 0.25
	}
	else if (type == BACK)
	{
		Speed -= 0.25
	}
	else if (type == LEFT)
	{
		TurnAngle -= 3//(6 * Speed)
	}
	else if (type == RIGHT)
	{
		TurnAngle += 3//(6 * Speed)
	}

	Speed = Clamp(Speed, 0.01, 1)
	TurnAngle = Clamp(TurnAngle, -9, 9)
	if (Speed == 0) TurnAngle = 0
}

Think <- function(slopes = false)
{
	local ourpos = Car.GetOrigin()
	local targpos = ourpos + (Car.GetForwardVector() * 120 * Speed) + (Car.GetLeftVector() * TurnAngle)//+ Vector(cos(TurnAngle), sin(TurnAngle), 0)//(Car.GetLeftVector() * cos(TurnAngle) * 1)
	
	//if (Driver != null) Driver.SetOrigin(ourpos)

	// height adjustment for ramps (wip)
	if (slopes)
	{
		local trace = TraceLine(targpos + Vector(0, 0, 64), targpos - Vector(0, 0, 64), Car)
		DebugDrawLine(targpos + Vector(0, 0, 64), (targpos + Vector(0, 0, 64)) - Vector(0, 0, 128 * trace), 255, 0, 255, true, 0.2)
		if (HeightBaseline == false)
		{
			HeightBaseline = trace
		} else {
			if (trace < (HeightBaseline - 0.02)) TargetHeight += Clamp(8 * Speed, 2, 6)
			if (trace > (HeightBaseline + 0.02)) TargetHeight -= Clamp(8 * Speed, 2, 6)
		}
		targpos.z = TargetHeight
	}
	

	Start.SetOrigin(ourpos)
	Dest.SetOrigin(targpos)
	
	if (targpos.x > LowerBounds.x && targpos.x < UpperBounds.x && targpos.y > LowerBounds.y && targpos.y < UpperBounds.y)
	{
		EntFireByHandle(Car, "SetSpeedDir", Speed.tostring(), 0.0, null, null)
		EntFireByHandle(Car, "Start", "", 0.0, null, null)
	}
	else
	{
		EntFireByHandle(Car, "SetSpeedDir", "0", 0.0, null, null)
	}

	DebugDrawLine(ourpos, targpos, 255, 0, 0, true, 0.2)
	DebugDrawLine(Start.GetOrigin(), Start.GetOrigin() + Vector(0, 0, 12), 0, 255, 0, true, 0.2)
	DebugDrawLine(Dest.GetOrigin(), Dest.GetOrigin() + Vector(0, 0, 12), 0, 0, 255, true, 0.2)

	if (TurnAngle > 0) TurnAngle--;
	if (TurnAngle < 0) TurnAngle++;

	// eye trace test
	/*
	local ply = Entities.FindByClassname(null , "player")
	local tracelen = 2000
	local eyepos = ply.EyePosition()
	local fv = ply.GetForwardVector()
	local tr = TraceLine(eyepos, eyepos + (fv * tracelen), ply)
	DebugDrawLine(eyepos, eyepos + (fv * tracelen * tr), 255, 0, 255, true, 0.2)
	printl(tracelen * tr)
	*/
}

SlopeThink <- function()
{
	Think(true)
}
