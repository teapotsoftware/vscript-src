
environment <- EntityGroup[0]
time <- -1

function max(x, y)
{
	if(x > y)
	{
		return x
	}
	return y
}

function Think()
{
	time = cos(Time() / 12)
	environment.__KeyValueFromFloat("pitch", time * 160)
	environment.__KeyValueFromString("_light", "255 " + max(time * 255, 0) + " " + max(time * 255, 0) + " " + max(time * 255, 0))
	environment.__KeyValueFromString("_ambient", "255 " + max(time * 255, 0) + " " + max(time * 255, 0) + " " + max(time * 255, 0))
}