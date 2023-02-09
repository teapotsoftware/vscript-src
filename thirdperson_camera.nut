
Owner <- null
MM <- null

function Think()
{
	if (Owner == null)
	{
		Owner = Entities.FindByClassname(null, "player")
		if (Owner == null)
			return

		local ourName = self.GetName()
		MM = Entities.FindByName(null, ourName + "_mm")
		local ownerName = ourName + "_owner"
		//Owner.__KeyValueFromString("targetname", ownerName)
		//EntFire(ourName, "SetParent", ownerName)
		//self.SetOrigin(Owner.GetOrigin() + Owner.GetForwardVector() * -100 + Owner.GetUpVector() * 100)
	}

	//self.SetOrigin(Owner.GetOrigin() + Owner.GetForwardVector() * -100 + Owner.GetUpVector() * 100)
	//local a = Owner.GetAngles()
	//self.SetAngles(a.x + 15, a.y, a.z)

	DebugDrawLine(Owner.EyePosition(), Owner.EyePosition() + self.GetForwardVector() * 100, 255, 100, 255, true, 0)
}