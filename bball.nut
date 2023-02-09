
::BallMaker <- EntityGroup[0]

ScriptPrintMessageChatAll("• \x04 Welcome to BBall!")

::EntFireHandle <- function(target, input, value = "", delay = 0.0, activator = null, caller = null)
{
	EntFireByHandle(target, input, value, delay, activator, caller)
}

::CenterPrint <- function(ply, msg)
{
	local messager = Entities.CreateByClassname("env_message")
	messager.__KeyValueFromString("message", msg)
	EntFireHandle(messager, "ShowMessage", "", 0.0, ply)
	EntFireHandle(messager, "Kill", "", 0.1)
}

::GiveWeapon <- function(ply, weapon, ammo = 1)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1)
}

::RefillAmmo <- function(ply)
{
	local ammo = Entities.CreateByClassname("point_give_ammo")
	EntFireHandle(ammo, "GiveAmmo", "", 0, ply)
	EntFireHandle(ammo, "Kill", "", 0.1)
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireHandle(strip, "Strip", "", 0.0, ply)
	EntFireHandle(strip, "Kill", "", 0.1)
}

::GiveLoadout <- function(ply, array)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 3)
	equip.__KeyValueFromInt("item_assaultsuit", 1)
	foreach (wep in array)
	{
		equip.__KeyValueFromInt(wep, 999)
	}
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1)
}

::ModifySpeed <- function(ply, speed)
{
	local speedmod = Entities.CreateByClassname("player_speedmod")
	EntFireHandle(speedmod, "ModifySpeed", speed.tostring(), 0.0, ply)
	EntFireHandle(speedmod, "Kill", "", 0.1)
}

::MeleeFixup <- function()
{
	foreach (wep in ["knife", "fists", "melee"])
	{
		EntFire("weapon_" + wep, "addoutput", "classname weapon_knifegg")
	}
}

::NormalizeVector <- function(v)
{
	local max = fabs(v.x)
	if (fabs(v.y) > max)
	{
		max = fabs(v.y)
	}
	if (fabs(v.z) > max)
	{
		max = fabs(v.z)
	}
	return Vector(v.x / max, v.y / max, v.z / max)
}

::FadeOut <- function(ent, delay = 0)
{
	if (ent.GetClassname() == "weapon_c4")
	{
		return
	}
	if (ent.ValidateScriptScope())
	{
		local ss = ent.GetScriptScope()
		if ("faded_bro" in ss)
		{
			return
		}
		else
		{
			ss.faded_bro <- true
		}
	}
	ent.__KeyValueFromInt("rendermode", 1)
	for (local i = 1; i < 11; i++)
	{
		EntFireHandle(ent, "addoutput", "renderamt " + (255 - (25 * i)), i.tofloat() / 10)
	}
	EntFireHandle(ent, "kill", "", 1.1)
}

::OVERTIME <- false
::SCORES <- [0, 0]

OnPostSpawn <- function()
{
	::OVERTIME <- false
	::SCORES <- [0, 0]
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_solid_teammates 0")
	SendToConsoleServer("mp_freezetime 0")
	SendToConsoleServer("mp_roundtime 3")
	SendToConsoleServer("mp_anyone_can_pickup_c4 1")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("sv_falldamage_scale 0.1")
	SendToConsoleServer("sv_airaccelerate 1337")
	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope())
	{
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function()
		{
			if (activator != null && activator.GetHealth() > 0)
			{
				activator.SetHealth(100)
				GiveWeapon(activator, "item_assaultsuit")
			}
		}
	}
	DeathEvent <- Entities.CreateByClassname("trigger_brush")
	DeathEvent.__KeyValueFromString("targetname", "game_playerdie")
	if (DeathEvent.ValidateScriptScope())
	{
		DeathEvent.ConnectOutput("OnUse", "OnDeath")
		DeathEvent.GetScriptScope().OnDeath <- function()
		{
			if (activator != null && activator.GetName() == "bomb_carrier")
			{
				// EntFire("ball_trail", "color", "255 255 0")
			}
			local wep = null
			while (wep = Entities.FindByClassname(wep, "weapon_*"))
			{
				if (wep.GetOwner() == null)
				{
					FadeOut(wep)
				}
			}
		}
	}
}

::GiveBomb <- function(ply)
{
	GiveWeapon(ply, "weapon_c4")
}

::BumpSound <- function(ent)
{
	ent.EmitSound("Survival.BumpMineDetonate")
}

::Dunk <- function(team)
{
	::SCORES[team - 2]++
	local bomb = Entities.FindByClassname(null, "weapon_c4")
	if (bomb != null)
	{
		bomb.Destroy()
	}
	if (OVERTIME)
	{
		TeamWon(team)
	}
	else
	{
		local mod = 1
		if (team == 2)
		{
			ScriptPrintMessageChatAll("• \x07 Terrorists score!")
		}
		else
		{
			mod = -1
			ScriptPrintMessageChatAll("• \x0B Counter-Terrorists score!")
		}
		ScriptPrintMessageChatAll("• \x07 " + SCORES[0] + " \x01 - \x0B " + SCORES[1])
		BallMaker.SpawnEntityAtLocation(Vector(448 * mod, 0, 5120), Vector(0, 0, 0))
	}
}

Think <- function()
{
	EntFire("weapon_knife", "addoutput", "classname weapon_knifegg")
	EntFire("bomb_carrier", "addoutput", "targetname random_dude")
	local bomb = Entities.FindByClassname(null, "weapon_c4")
	if (bomb != null)
	{
		local owner = bomb.GetOwner()
		if (owner != null)
		{
			EntFireHandle(owner, "addoutput", "targetname bomb_carrier")
			if (owner.GetTeam() == 2)
			{
				EntFire("ball_trail", "color", "255 0 0")
			}
			else
			{
				EntFire("ball_trail", "color", "0 0 255")
			}
		}
		else
		{
			EntFire("ball_trail", "color", "255 255 0")
		}
		EntFire("ball_trail", "setscale", "1")
	}
}

::TeamWon <- function(team)
{
	if (team == 2)
	{
		ScriptPrintMessageChatAll("• \x07 Terrorists win!")
		EntFire("round_ender", "EndRound_TerroristsWin", "10")
		SendToConsoleServer("mp_respawn_on_death_ct 0")
	}
	else
	{
		ScriptPrintMessageChatAll("• \x0B Counter-Terrorists win!")
		EntFire("round_ender", "EndRound_CounterTerroristsWin", "10")
		SendToConsoleServer("mp_respawn_on_death_t 0")
	}
	ScriptPrintMessageChatAll("• \x03 Final: \x07 " + SCORES[0] + " \x01 - \x0B " + SCORES[1])
	local loser = null
	while (loser = Entities.FindByClassname(loser, "*"))
	{
		if (loser.GetClassname() == "player" && loser.GetTeam() != team)
		{
			StripWeapons(loser)
		}
	}
}

::OutOfTime <- function()
{
	if (SCORES[0] > SCORES[1])
	{
		TeamWon(2)
	}
	else if (SCORES[1] > SCORES[0])
	{
		TeamWon(3)
	}
	else
	{
		::OVERTIME <- true
		ScriptPrintMessageChatAll("• \x02 OVERTIME - Next to score wins!")
	}
}

/*
::FIRED_MAG7 <- [0, 0]
::FIRED_TEC9 <- [0, 0]

::WeaponFired <- function(data)
{
	if (data.weapon == "weapon_mag7")
	{
		::FIRED_MAG7 <- [Time(), data.userid]
	}
	else if (data.weapon == "weapon_tec9")
	{
		::FIRED_TEC9 <- [Time(), data.userid]
	}
}

::FAN_DEBUG <- false
*/

::BulletImpact <- function(data)
{
	local hit_pos = Vector(data.x, data.y, data.z)
	local nig = null
	while (nig = Entities.FindByClassnameWithin(nig, "player", hit_pos, 100))
	{
		// printl(NormalizeVector(nig.GetOrigin() - hit_pos) * 300)
		nig.SetVelocity(nig.GetVelocity() + (NormalizeVector(nig.GetOrigin() - hit_pos) * 300))
	}
}
