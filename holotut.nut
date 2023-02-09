
VisModel <- "models/player/tm_leet_variantC.mdl"
Entities.FindByClassname(null, "*").PrecacheModel(VisModel)

::VisDummy <- CreateProp("prop_dynamic", Vector(0, 0, 0), VisModel, 1)
VisDummy.__KeyValueFromInt("collisiongroup", 2)
VisDummy.__KeyValueFromInt("rendermode", 5)
VisDummy.__KeyValueFromString("rendercolor", "255 255 255 180")

::VisList <- {}
::VisCurTime <- 0

::VisRecordPlayer <- false
::VisPlayingBack <- false
::VisRecording <- false

::VisStartPlayback <- function(id)
{
	if (id in VisList)
	{
		::VisCurTime <- 0
		::VisPlayingBack <- id
	}
	else
	{
		printl("invalid id")
	}
}

::VisStopPlayback <- function()
{
	if (VisPlayingBack)
	{
		::VisPlayingBack <- false
		printl("playback stopped...")
	}
}

::VisStartRecording <- function(id)
{
	if (id in VisList)
	{
		printl("recording for \"" + id + "\" already exists, overwriting...")
	}
	::VisRecording <- id
}

::VisStopRecording <- function()
{
	if (VisRecording)
	{
		::VisRecording <- false
		printl("recording stopped...")
	}
}

::VisThink <- function()
{
	VisCurTime++
	if (VisPlayingBack)
	{
		local tab = VisList[VisPlayingBack]
		local subtab = tab[VisCurTime % tab.len()]
		VisDummy.SetOrigin(subtab[0])
		VisDummy.SetAngles(subtab[1].x, subtab[1].y, 0)
		EntFireByHandle(VisDummy, "SetAnimation", subtab[2] ? "Crouch_Idle_Lower" : "Idle_Lower", 0.0, null, null)
	}
	if (VisRecording)
	{
		if (!::VisRecordPlayer)
		{
			::VisRecordPlayer <- Entities.FindByClassname(null, "player")
		}
		local tab = [::VisRecordPlayer.GetOrigin(), ::VisRecordPlayer.GetAngles(), ::VisRecordPlayer.GetBoundingMaxs().z < 60]
		if (VisRecording in VisList)
		{
			VisList[VisRecording].push(tab)
		}
		else
		{
			VisList[VisRecording] <- [tab]
		}
	}
}

VisThinkTimer <- Entities.CreateByClassname("logic_timer")
VisThinkTimer.__KeyValueFromInt("RefireTime", 0.2)
VisThinkTimer.__KeyValueFromString("TargetName", "vis_think_timer")
EntFire("vis_think_timer", "enable", "")
EntFire("vis_think_timer", "addoutput", "OnTimer vis_think_timer,RunScriptCode,VisThink(),0.0,-1")
