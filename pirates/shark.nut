
IncludeScript("butil")

Target <- null
Speed <- RandomFloat(12, 16)
Range <- 800 + (60 * (Speed - 12))
TurnSpeed <- RandomFloat(0.08, 0.12)

GoToPos <- function(target)
{
	self.SetForwardVector(LerpVector(TurnSpeed, self.GetForwardVector(), NormalizeVector(target - self.GetOrigin())))
	local step = self.GetOrigin() + (self.GetForwardVector() * Speed)
	if (step.z > -32)
	{
		step.z = -32
	}
	self.SetOrigin(step)
}

RoamFrac <- RandomFloat(0.3, 0.7)
RoamOffset <- Vector(RandomInt(-300, 300), RandomInt(-300, 300), RandomInt(-200, 0))
Ships <- []

OnPostSpawn <- function()
{
	Ships.push(Entities.FindByName(null, "pirateship"))
	Ships.push(Entities.FindByName(null, "royalship"))
}

Think <- function()
{
	if (Target == null)
	{
		Target = Entities.FindByClassnameNearest("player", self.GetOrigin(), Range)

		// If there's no target in range
		if (Target == null || Target.GetOrigin().z > 0)
		{
			// Go about in between the two ships, most likely place for swimmers
			GoToPos(Ships[0].GetOrigin() + ((Ships[1].GetOrigin() - Ships[0].GetOrigin()) * RoamFrac) + RoamOffset)
		}
	}
	else
	{
		local target_pos = Target.GetOrigin()
		if (target_pos.z > 0 || DistToSqr(self.GetOrigin(), target_pos) > Range * Range)
		{
			Target = null
		}
		else
		{
			GoToPos(target_pos)
		}
	}
}

TakeDamage <- function()
{
	printl(self + " says ouch!")
}
