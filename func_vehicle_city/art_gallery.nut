
InitialZ <- false
CurTime <- 0

OnPostSpawn <- function()
{
	InitialZ <- EntityGroup[0].GetOrigin().z
}

ColorValue <- function(mod, i)
{
	return (sin(CurTime + (i * 0.4) + mod) * 128) + 127
	//return (sin((CurTime * mod) + i) * 128) + 127
}

Think <- function()
{
	if (InitialZ == false) return
	CurTime = (CurTime + 0.1) % 360
	for (local i = 0 ; i < 5; i++)
	{
		local origin = EntityGroup[i].GetOrigin()
		EntityGroup[i].SetOrigin(Vector(origin.x, origin.y, InitialZ + (sin((CurTime * 2) + (i * 12)) * 5)))
		EntityGroup[i].__KeyValueFromString("rendercolor", ColorValue(0, i) + " " + ColorValue(2, i) + " " + ColorValue(4, i))
	}
}
