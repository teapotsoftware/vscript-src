
IncludeScript("butil")

Start <- EntityGroup[0]
Dest <- EntityGroup[1]
TargetFloor <- 0
IsMoving <- false

::ELEVATOR_FLOORS <- {}

::CallAllElevatorsToFloor <- function(floor)
{
}

function Precache()
{
	self.PrecacheSoundScript("Buttons.snd0")
}

function OnPostSpawn()
{
	local target = null
	while (target = Entities.FindByClassname(target, "info_target"))
	{
		local name = target.GetName()
		if (name.slice(0, 15) == "elevator_floor_")
		{
			::ELEVATOR_FLOOR_HEIGHT[name.slice(15).tointeger()] <- target.GetOrigin().z
			printl("Floor " + name.slice(15).tointeger() + " is at z " + target.GetOrigin().z)
		}
	}
}

function FloorReached()
{
	// Swap paths
	local tempStart = Start
	Start = Dest
	Dest = tempStart
}

function GoToFloor(floor)
{
	
}

