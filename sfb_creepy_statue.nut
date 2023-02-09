
CurTime <- 0

Distance2D <- function(v1,v2)
{
	local a = (v2.x-v1.x);
	local b = (v2.y-v1.y);
	
	return sqrt((a*a)+(b*b));
}

AngleBetween <- function(v1,v2)
{
	local aZ = atan2((v1.y - v2.y),(v1.x - v2.x))+PI;	
	local aY = atan2((v1.z - v2.z),Distance2D(v1,v2))+PI;	
	return Vector(aY,aZ,0.0);
}

deg <- function(n)
{
	return n * 57.295779513082320876798154814105
}

FacePlayer <- function(ply)
{
	local ang = AngleBetween(ply.GetOrigin(), self.GetOrigin())
	local yaw = ((deg(ang.y) + 360) % 360) - 180
	self.SetAngles(0, yaw, 0)
}

YawDiff <- function(a, b)
{
	return ((a - b) + 180) % 360 - 180;
}

FacingTowardMe <- function(ply)
{
	local curYaw = ((ply.GetAngles().y + 360) % 360) - 180
	local yawFacingMe = ((deg(AngleBetween(self.GetOrigin(), ply.GetOrigin()).y) + 360) % 360) - 180
	local diff = YawDiff(curYaw, yawFacingMe)
	// printl("cur yaw: " + curYaw)
	// printl("targ yaw: " + yawFacingMe)
	// printl("yaw diff: " + diff)
	if (diff > 120 || diff < -120)
	{
		// printl("PASSING DIFF was " + diff)
		return true
	}
	return false
}

Think <- function()
{
	CurTime++
	if (CurTime > 7)
	{
		CurTime <- 0
		local ply = null
		while (ply = Entities.FindByClassname(ply, "player"))
		{
			if ((TraceLine(ply.EyePosition(), self.GetOrigin() + Vector(0, 0, 24), ply) == 1 && FacingTowardMe(ply)) || Distance2D(self.GetOrigin(), ply.GetOrigin()) < 100)
			{
				// printl("can be seen")
				return
			}
		}
		// printl("cant be seen")
		local ply = Entities.FindByClassnameNearest("player", self.GetOrigin(), 1000)
		if (ply != null)
		{
			FacePlayer(ply)
		}
	}
}
