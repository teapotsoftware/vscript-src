
IncludeScript("butil")

::DispatchVO <- function(ply, name, interrupt = false)
{
	if (interrupt)
	{
		local last = GetScopeVar(ply, "last_vo_name")
		if (last)
			ply.StopSound(last)
	}

	name = "monster_slayers/" + ((ply.GetTeam() == 2) ? "heavy" : "demoman") + "_" + name + "0" + RandomInt(1, 3) + ".mp3"
	ply.EmitSound(name)
	SetScopeVar(ply, "last_vo_name", name)
	SetScopeVar(ply, "last_vo_time", Time())
}

Precache <- function()
{
	local world = Entities.First()
	for (local i = 1; i < 4; i++)
		foreach (cls in ["heavy", "demoman"])
			foreach (snd in ["laughshort", "paincrticialdeath", "painsevere", "painsharp"])
				world.PrecacheSoundScript("monster_slayers/" + cls + "_" + snd + "0" + i + ".mp3")
}

OnPostSpawn <- function()
{
	HookToPlayerDeath(function(ply)
	{
		DispatchVO(ply, "paincrticialdeath", true)
	})
	HookToPlayerKill(function(ply)
	{
		if (ply.GetHealth() <= 0)
			return
		local lasttime = GetScopeVar(ply, "last_vo_time")
		local curtime = Time()
		if ((RandomInt(1, 3) == 1) && (lasttime == 0 || ((curtime - lasttime) > 5)))
		{
			DispatchVO(ply, "laughshort")
		}
	})
}

AddHook("player_hurt", "HeavyHurtVoiceLines", function(data)
{
	local ply = data.userid_player
	if (ply == null || ply.GetHealth() <= 0)
		return

	local dmg = data.dmg_health
	if (dmg <= 0)
		return

	local max = ply.GetMaxHealth()
	if (dmg >= (max * 0.8))
	{
		DispatchVO(ply, "painsevere", true)
	}
	else
	{
		local lasttime = GetScopeVar(ply, "last_vo_time")
		local curtime = Time()
		if (dmg >= (max * 0.5) || (lasttime != 0 && (curtime - lasttime) > 2))
			DispatchVO(ply, "painsharp", true)
	}
})
