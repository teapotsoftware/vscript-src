
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

PosessPlayer <- function(ply)
{
	local us = ply.EyePosition()
	local enemy = GetEnemy(ply)
	if (enemy == null)
	{
		return
	}
	local them = enemy.EyePosition()
	local ang = AngleBetween(them, us)	

	local new_pitch = ((deg(ang.x) / 2) - 90) * -2
	local new_yaw = ((deg(ang.y) + 360) % 360) - 180
	ply.SetAngles(new_pitch, new_yaw, 0)
}