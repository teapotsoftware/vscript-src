
::SplatMakers <- [EntityGroup[0], EntityGroup[1]]
::BloodMaker <- EntityGroup[2]

::Splat <- function(data, index)
{
	// ScriptPrintMessageChatAll((index ? "ct" : "t") + " shot at " + pos)
	SplatMakers[index].SpawnEntityAtLocation(Vector(data.x, data.y, data.z), Vector(RandomInt(0, 360), RandomInt(0, 360), RandomInt(0, 360)))
}

::SplatT <- function(data) {Splat(data, 0)}
::SplatCT <- function(data) {Splat(data, 1)}

::BloodTimer <- function()
{
	blood <- null
	while ((blood = Entities.FindByTarget(blood, "blood_red")) != null)
	{
		local pos = blood.GetOrigin()
		pos.z += 1
		blood.SetOrigin(pos)
	}
}

OnPostSpawn <- function()
{
	/*
	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope())
	{
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function()
		{
			if (::LAST_DEATH != null)
			{
				PlayerKilledPlayer(::LAST_DEATH, activator)
				PlayerDeath(activator)
			}
		}
	}
	*/
	DeathEvent <- Entities.CreateByClassname("trigger_brush")
	DeathEvent.__KeyValueFromString("targetname", "game_playerdie")
	if (DeathEvent.ValidateScriptScope())
	{
		DeathEvent.ConnectOutput("OnUse", "OnDeath")
		DeathEvent.GetScriptScope().OnDeath <- function()
		{
			BloodMaker.SpawnEntityAtLocation(activator.GetOrigin(), Vector(0, 0, 0))
		}
	}
}
