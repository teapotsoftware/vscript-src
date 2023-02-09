
Larry <- EntityGroup[0]
Start <- EntityGroup[1]
Dest <- EntityGroup[2]

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

Think <- function()
{
	local ourpos = Larry.GetOrigin()
	local target = Entities.FindByClassnameNearest("player", ourpos, 500)
	if (target == null)
	{
		EntFireByHandle(Larry, "Stop", "", 0.0, null, null)
	}
	local targpos = target.EyePosition()
	local newang1 = AngleBetween(targpos, ourpos)
	local newang2 = AngleBetween(ourpos, targpos)
	Dest.SetOrigin(targpos)
	Start.SetAngles(newang2.x, newang2.y, newang2.z)
	Dest.SetAngles(newang1.x, newang1.y, newang1.z)
	EntFireByHandle(Larry, "StartForward", "", 0.0, null, null)
}
