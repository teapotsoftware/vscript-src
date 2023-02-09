
::GetPlayerFromUserID <- function(id)
{
	found <- null
	while ((found = Entities.FindByClassname(found, "player")) != null)
	{
		if (found.ValidateScriptScope())
		{
			local scope = found.GetScriptScope()
			if ("userid" in scope && scope.userid == id)
			{
				return found
			}
		}		
	}
	return null
}

::GetEnemy <- function(friend)
{
	found <- null
	while ((found = Entities.FindByClassname(found, "*")) != null)
	{
		local cls = found.GetClassname()
		if (cls == "player" || cls == "bot")
		{
			if (found.GetTeam() + friend.GetTeam() == 5 && found.GetHealth() > 0)
			{
				return found
			}
		}
	}
	return null
}

::Distance2D <- function(v1,v2)
{
	local a = (v2.x-v1.x);
	local b = (v2.y-v1.y);
	
	return sqrt((a*a)+(b*b));
}

::AngleBetween <- function(v1,v2)
{
	local aZ = atan2((v1.y - v2.y),(v1.x - v2.x))+PI;	
	local aY = atan2((v1.z - v2.z),Distance2D(v1,v2))+PI;	
	return Vector(aY,aZ,0.0);
}

::deg <- function(n)
{
	return n * 57.295779513082320876798154814105
}

::AimbotPlayer <- function(ply)
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

::InspectWeapon <- function()
{
	local data = this.event_data
	local ply = GetPlayerFromUserID(data.userid)
	if (ply.ValidateScriptScope())
	{
		local scope = ply.GetScriptScope()
		if (!("captain_crunch" in scope) || !(scope.captain_crunch))
		{
			return
		}
	}
	else
	{
		return
	}
	AimbotPlayer(ply)
}
