
InputUse <- function()
{
	if (activator.GetTeam() == T)
	{
		if (!IsPrepPhase)
		{
			CenterPrint(activator, Lang.REINFORCE_NOTPREP)
			return false
		}
		if (ReinforcementsLeft <= 0)
		{
			CenterPrint(activator, Lang.REINFORCE_OUTOF)
			return false
		}
		::ReinforcementsLeft--
		if (self.GetName() == "hatch")
		{
			CenterPrint(activator, Lang.REINFORCE_HATCH)
			ReinforcedHatchMaker.SpawnEntityAtLocation(self.GetOrigin(), Vector(0, 0, 0))
			EntFire("reinforcement_hatch", "Open")
			EntFireHandle(self, "Break")
		}
		else
		{
			CenterPrint(activator, Lang.REINFORCE_WALL)
			ReinforcedWallMaker.SpawnEntityAtLocation(self.GetOrigin(), Vector(0, self.GetName() == "soft_wall_90" ? 90 : 0, 0))
			EntFire("reinforcement_wall", "Open")
			BreakNearby(self.GetName(), self.GetOrigin())
		}
		return true
	}
	return false
}
