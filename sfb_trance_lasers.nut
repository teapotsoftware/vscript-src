
RefPos <- EntityGroup[0].GetOrigin()
BlueTarget <- EntityGroup[1]
RedTarget <- EntityGroup[2]

CurTime <- 0

Think <- function()
{
	CurTime = (CurTime + 0.1) % 360
	local offset = Vector(cos(CurTime * 0.5) * 70, sin(CurTime * 0.5) * 70, 0)
	BlueTarget.SetOrigin(RefPos + offset)
	RedTarget.SetOrigin(RefPos - offset)
}
