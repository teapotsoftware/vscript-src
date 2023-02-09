
::EntFireHandle <- function(t, i, v = "", d = 0.0, a = null, c = null) {EntFireByHandle(t, i, v, d, a, c)}

::PLAYERMODEL_PREFIX <- "models/player/custom_player/legacy/"
::PLAYERMODEL_POSTFIX <- ".mdl"
::PLYMDL <- function(mdl) {return PLAYERMODEL_PREFIX + mdl + PLAYERMODEL_POSTFIX}

::WireMaker <- EntityGroup[0]
::ArmorMaker <- EntityGroup[1]
::ADSMaker <- EntityGroup[2]
::JammerMaker <- EntityGroup[3]
::ShieldMaker <- EntityGroup[4]
::TurretMaker <- EntityGroup[5]
::BarricadeMaker <- EntityGroup[6]
::CastleMaker <- EntityGroup[7]

::DEFENDERS <- 2
::ATTACKERS <- 3

// both teams
::CLASS_RECRUIT <- 0

// defenders
::CLASS_MUTE <- 1
::CLASS_CASTLE <- 2
::CLASS_ROOK <- 3
::CLASS_TACHANKA <- 4
::CLASS_JAGER <- 5

// who has nitro instead of shield (unused)
::HAS_NITRO <- [true, true, false, false, false, true]

// attackers
::CLASS_THATCHER <- 1
::CLASS_THERMITE <- 2
::CLASS_MONTAGNE <- 3
::CLASS_GLAZ <- 4
::CLASS_IQ <- 5

// whole list is [DEF, ATK]
::ClassLists <- [
	[
		{name = "Recruit", weps = ["sawedoff", "hkp2000", "knife_m9_bayonet", "bumpmine", "tagrenade"], speed = 2, model = "tm_phoenix"},
		{name = "Mute", weps = ["nova", "cz75a", "knife_flip", "bumpmine", "tagrenade"], speed = 2, model = "tm_phoenix_variantf"},
		{name = "Castle", weps = ["ump45", "fiveseven", "knife_m9_bayonet", "bumpmine", "tagrenade"], speed = 3, model = "tm_professional_var3"},
		{name = "Rook", weps = ["p90", "revolver", "bayonet", "bumpmine", "tagrenade"], speed = 1, model = "tm_phoenix_heavy"},
		{name = "Tachanka", weps = ["bizon", "usp_silencer", "knife_survival_bowie", "bumpmine", "tagrenade"], speed = 1, model = "tm_balkan_variantf"},
		{name = "Jager", weps = ["mp7", "hkp2000", "bayonet", "bumpmine", "tagrenade"], speed = 3, model = "tm_leet_varianti"},
	],
	[
		{name = "Recruit", weps = ["sawedoff", "hkp2000", "knife_m9_bayonet", "hegrenade", "hegrenade"], speed = 2, model = "ctm_swat"},
		{name = "Thatcher", weps = ["sg556", "cz75a", "knife_flip", "tagrenade", "tagrenade"], speed = 2, model = "ctm_sas_variantf"},
		{name = "Thermite", weps = ["sg556", "fiveseven", "knife_m9_bayonet", "hegrenade", "hegrenade"], speed = 2, model = "ctm_st6_varianti"},
		{name = "Montagne", weps = ["shield", "p250", "bayonet", "smokegrenade", "smokegrenade"], speed = 1, model = "ctm_heavy"},
		{name = "Glaz", weps = ["scar20", "usp_silencer", "knife_survival_bowie", "smokegrenade", "smokegrenade"], speed = 2, model = "ctm_idf"},
		{name = "IQ", weps = ["aug", "usp_silencer", "bayonet", "flashbang", "flashbang", "flashbang"], speed = 3, model = "ctm_fbi_variantb"},
	]
]

::GiveWeapon <- function(ply, weapon, ammo = 999)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1)
}

::GiveLoadout <- function(ply, array)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 3)
	equip.__KeyValueFromInt("item_assaultsuit", 1)
	foreach (wep in array)
	{
		equip.__KeyValueFromInt("weapon_" + wep, 999)
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

::SetClass <- function(ply, cls = 0)
{
	local tab = ClassLists[ply.GetTeam() - 2][cls]
	local hp = 50 * (5 - tab.speed)
	ply.SetMaxHealth(hp)
	ply.SetHealth(hp)
	ply.__KeyValueFromFloat("gravity", 1.2 - (tab.speed * 0.1))
	ModifySpeed(ply, 0.8 + (tab.speed * 0.1))
	GiveLoadout(ply, tab.weps)
	MeleeFixup()
	local mdl = PLYMDL(tab.model)
	ply.PrecacheModel(mdl)
	ply.SetModel(mdl)
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		ss.r6_class <- cls
		ss.castle_barricades <- 3
	}
}

::GetClass <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("r6_class" in ss)
		{
			return ss.r6_class
		}
	}
	return CLASS_RECRUIT
}

// shit function
::ElectronicScanner <- function(ply, on)
{
	if (ply.GetHealth() > 0 && ply.ValidateScriptScope())
	{
		EntFire("fade_iq_" + (on ? "in" : "out"), "fade", 0, ply)
		ply.GetScriptScope().iq_sensor <- on
	}
}

// wall statuses: 0 is normal, 1 is reinforced, 2 is blown up
::VecSum <- function(v) {return v.x + "-" + v.y + "-" + v.z}
::WALL_STATUS <- {}
::REINFORCE_PLY <- null
::REINFORCE_INFO <- 0

::PlayerReinforce <- function(ply)
{
	::REINFORCE_INFO <- 0
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if (!("team_gadgets" in ss))
		{
			ply.GetScriptScope().team_gadgets <- 2
		}
		if (ss.team_gadgets > 0)
		{
			::REINFORCE_PLY <- ply
			::REINFORCE_INFO <- ply.GetTeam() - 1
		}
	}
}

::HasWeapon <- function(ply, wep)
{
	local ent = null
	while (ent = Entities.FindByClassname(ent, wep))
	{
		if (ent.GetOwner() == ply)
		{
			return true
		}
	}
	return false
}

::Kaboom <- function(ent)
{
	DispatchParticleEffect("explosion_hegrenade_brief", ent.GetOrigin(), Vector(-1, 0, 0))
	ent.EmitSound("BaseGrenade.Explode")
}

::ReinforcementPressed <- function(button)
{
	local button_pos = VecSum(button.GetOrigin())
	if (REINFORCE_INFO == 1 && !(button_pos in WALL_STATUS))
	{
		local reinforcement = Entities.FindByNameNearest("reinforcement", button.GetOrigin(), 12)
		if (reinforcement != null)
		{
			EntFireByHandle(reinforcement, "enable", "", 0.0, null, null)
			reinforcement.EmitSound("Metal_Barrel.ImpactHard")
			local wall = Entities.FindByNameNearest("breakable_*", button.GetOrigin(), 12)
			if (wall != null)
			{
				EntFireByHandle(wall, "break", "", 0.0, null, null)
			}
			// reinforcing a wall breaks planted charges (except thermite)
			local charge = Entities.FindByNameNearest("breach_planted", button.GetOrigin(), 18)
			if (charge != null)
			{
				local owner = charge.GetOwner()
				if (owner != null && GetClass(owner) != CLASS_THERMITE)
				{
					charge.Destroy()
				}
			}
			REINFORCE_PLY.GetScriptScope().team_gadgets <- REINFORCE_PLY.GetScriptScope().team_gadgets - 1
			::WALL_STATUS[button_pos] <- 1
		}
	}
	else if (REINFORCE_INFO == 2 && (!(button_pos in WALL_STATUS) || WALL_STATUS[button_pos] != 2))
	{
		local jammer = Entities.FindByNameNearest("mute_jammer", button.GetOrigin(), 140)
		if (jammer != null)
		{
			button.EmitSound("Buttons.snd8")
			return
		}
		local charge_planted = false
		local charge = Entities.FindByNameNearest("breach_planted", button.GetOrigin(), 12)
		if (charge != null)
		{
			local wall = Entities.FindByNameNearest("breakable_*", button.GetOrigin(), 12)
			if (wall != null)
			{
				charge_planted = true
			}
			else if (GetClass(REINFORCE_PLY) == CLASS_THERMITE)
			{
				local reinf = Entities.FindByNameNearest("reinforcement", button.GetOrigin(), 12)
				if (reinf != null)
				{
					charge_planted = true
				}
			}
		}
		if (charge_planted)
		{
			EntFireHandle(charge, "enable")
			charge.EmitSound("c4.plant")
			charge.SetOwner(REINFORCE_PLY)
			if (!HasWeapon(REINFORCE_PLY, "weapon_decoy"))
			{
				GiveWeapon(REINFORCE_PLY, "weapon_decoy")
			}
			REINFORCE_PLY.GetScriptScope().team_gadgets <- REINFORCE_PLY.GetScriptScope().team_gadgets - 1
			::WALL_STATUS[button_pos] <- 2
		}
	}
}

::HasCastleBarricades <- function(ply)
{
	if (ply.GetHealth() > 0 && GetClass(ply) == CLASS_CASTLE)
	{
		local ss = ply.GetScriptScope()
		if (!("castle_barricades" in ss))
		{
			ss.castle_barricades <- 3
		}
		if (ss.castle_barricades > 0)
		{
			return true
		}
	}
	return false
}

::BARRICADE_PLAYER <- null

::PlayerBarricade <- function(ply)
{
	if (ply.GetTeam() == DEFENDERS)
	{
		::BARRICADE_PLAYER <- ply
	}
}

::BarricadePressed <- function(door, dir = false)
{
	if (BARRICADE_PLAYER != null)
	{
		local castlecade = Entities.FindByNameNearest("castle_barricade", door.GetOrigin(), 4)
		if (castlecade == null)
		{
			local cade = Entities.FindByNameNearest("barricade", door.GetOrigin(), 4)
			if (HasCastleBarricades(BARRICADE_PLAYER))
			{
				BARRICADE_PLAYER.GetScriptScope().castle_barricades--
				CastleMaker.SpawnEntityAtLocation(door.GetOrigin(), Vector(0, dir ? 90 : 0, 0))
				door.EmitSound("Wood_Crate.ImpactHard")
				if (cade != null)
				{
					EntFireHandle(cade, "break")
				}
			}
			else if (cade == null)
			{
				BarricadeMaker.SpawnEntityAtLocation(door.GetOrigin(), Vector(0, dir ? 90 : 0, 0))
				door.EmitSound("Wood.ImpactHard")
			}
		}
		::BARRICADE_PLAYER <- null
	}
}

::GoOutside <- function(ply)
{
	if (ply.ValidateScriptScope() && ply.GetTeam() == DEFENDERS)
	{
		local ss = ply.GetScriptScope()
		ss.went_outside <- Time()
		ss.is_outside <- true
	}
}

::GoBackInside <- function(ply)
{
	if (ply.ValidateScriptScope() && ply.GetTeam() == DEFENDERS)
	{
		ply.GetScriptScope().is_outside <- false
	}
}

/*
::DefenderOutside <- function(ply)
{
	if (ply.GetTeam() == DEFENDERS && ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if (!("outside_timer" in ss))
		{
			ss.outside_timer <- 3
		}
		ss.outside_timer--
		if (ss.outside_timer > 0)
		{
			EntFire("hud_detectedoutside", "settext", "YOU WILL BE DETECTED IN 0:0" + ss.outside_timer)
			EntFire("hud_detectedoutside", "display", "", 0, ply)
		}
		else
		{
			EntFire("hud_detectedoutside", "settext", "YOU HAVE BEEN DETECTED")
			EntFire("hud_detectedoutside", "display", "", 0, ply)
			DebugDrawBox(ply.GetOrigin() + Vector(0, 0, 76), Vector(5, 5, 5), Vector(-5, -5, -5), 200, 150, 0, 150, 1)
			local atker = null
			while (atker = Entities.FindByClassname(atker, "player"))
			{
				if (atker.GetTeam() == ATTACKERS)
				{
					EntFire("hud_detectedoutside", "settext", "ENEMY DETECTED OUTSIDE")
					EntFire("hud_detectedoutside", "display", "", 0, atker)
				}
			}
		}
	}
}
*/

::ResetOutsideTimer <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		ply.GetScriptScope().outside_timer <- 3
	}
}

::DefenderSetup <- function()
{
	ScriptPrintMessageChatAll(" \x10 DEFENDER SETUP - 20 SECONDS")
	EntFire("blip", "playsound", "", 17)
	EntFire("blip", "playsound", "", 18)
	EntFire("blip", "playsound", "", 19)
	EntFire("bloop", "playsound", "", 20)
	EntFire("defenders_outside", "enable", "", 20)
	EntFire("attacker_teleport", "enable", "", 20)
	EntFire("defender_blocker", "disable", "", 22)
}

::LAST_DEATH <- null

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_damage_scale_t_head 3")
	SendToConsoleServer("mp_damage_scale_ct_head 3")
	SendToConsoleServer("mp_damage_scale_t_body 0.8")
	SendToConsoleServer("mp_damage_scale_ct_body 0.8")
	SendToConsoleServer("mp_death_drop_grenade 0")
	SendToConsoleServer("mp_death_drop_gun 0")
	SendToConsoleServer("sv_hegrenade_damage_multiplier 3")
	SendToConsoleServer("ammo_grenade_limit_default 2")
	SendToConsoleServer("ammo_grenade_limit_flashbang 3")
	SendToConsoleServer("ammo_grenade_limit_total 999")
	EntFire("reinforcement", "disable")
	EntFire("breach_planted", "disable")
	EntFire("breach_planted", "disablecollision")
	EntFire("defender_blocker", "enable")
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*"))
	{
		if (ply.GetClassname() == "player")
		{
			ply.GetScriptScope().team_gadgets <- 2
		}
	}
	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope())
	{
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function()
		{
			if (::LAST_DEATH != null)
			{
				EntFire("hud_hitmarker", "display", "", 0, activator)
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
			::LAST_DEATH <- activator
		}
	}
	ScriptPrintMessageChatAll(" \x10 OPERATOR SELECT - 20 SECONDS")
	EntFire("blip", "playsound", "", 17)
	EntFire("blip", "playsound", "", 18)
	EntFire("blip", "playsound", "", 19)
	EntFire("bloop", "playsound", "", 20)
	EntFire("opselect_teleporters", "enable", "", 20)
	EntFire("script", "runscriptcode", "DefenderSetup()", 20)
}

::ADSTargetList <- ["hegrenade", "flashbang", "smokegrenade", "tagrenade"]
::AngSum <- function(ang) {return floor(ang.x) + "-" + floor(ang.y) + "-" + floor(ang.z)}
::TICK_COUNT <- 0
::THERMAL <- 0

Think <- function()
{
	::THERMAL <- 0
	::TICK_COUNT++
	local defenders_outside = false
	local deleted = []
	local ent = null
	while (ent = Entities.FindByClassname(ent, "*"))
	{
		if (ent.GetClassname() == "player" && ent.GetHealth() > 0)
		{
			if (ent.GetTeam() == DEFENDERS && TICK_COUNT % 5 == 0)
			{
				ent.__KeyValueFromString("targetname", "defender")
				if (ent.ValidateScriptScope())
				{
					local ss = ent.GetScriptScope()
					if (("is_outside" in ss) && ss.is_outside)
					{
						local time_outside = Time() - ss.went_outside
						if (time_outside < 1)
						{
							EntFire("hud_detectedoutside", "settext", "YOU WILL BE DETECTED IN 0:02")
						}
						else if (time_outside < 2)
						{
							EntFire("hud_detectedoutside", "settext", "YOU WILL BE DETECTED IN 0:01")
						}
						else
						{
							defenders_outside = true
							EntFire("hud_detectedoutside", "settext", "YOU ARE DETECTED")
							DebugDrawBox(ent.EyePosition() + Vector(0, 0, 18), Vector(3, 3, 3), Vector(-3, -3, -3), 200, 150, 0, 150, 0.51)
						}
						EntFire("hud_detectedoutside", "display", "", 0, ent)
					}
				}
			}
			else
			{
				ent.__KeyValueFromString("targetname", "attacker")
			}
			if (TICK_COUNT % 3 == 0 && ent.GetTeam() == ATTACKERS && ent.GetVelocity().Length() > 0)
			{
				local wire = Entities.FindByNameWithin(null, "razor_wire", ent.GetOrigin(), 30)
				if (wire != null)
				{
					wire.EmitSound("ChainLink.ImpactSoft")
				}
			}
			if (ent.ValidateScriptScope())
			{
				local ss = ent.GetScriptScope()
				if (("team_gadgets" in ss) && ss.team_gadgets > 0)
				{
					local txt = ": " + ss.team_gadgets
					if (ent.GetTeam() == DEFENDERS)
					{
						txt = "REINFORCEMENTS" + txt
						if (HasCastleBarricades(ent))
						{
							txt += "     BARRICADES: " + ss.castle_barricades
						}
					}
					else
					{
						txt = "BREACH CHARGES" + txt
					}
					EntFire("hud_teamgadgets", "settext", txt)
					EntFire("hud_teamgadgets", "display", "", 0, ent)
				}
				else if (HasCastleBarricades(ent))
				{
					EntFire("hud_teamgadgets", "settext", "BARRICADES: " + ss.castle_barricades)
					EntFire("hud_teamgadgets", "display", "", 0, ent)
				}
			}
		}
		else if (ent.GetName() == "ads_base" && TICK_COUNT % 5 == 0)
		{
			if (TICK_COUNT % 15 == 0)
			{
				ent.EmitSound("Sensor.WarmupBeep")
			}
			foreach (nadetype in ADSTargetList)
			{
				EntFire(nadetype + "_projectile", "addoutput", "targetname ads_target")
			}
			local nade = null
			while (nade = Entities.FindByNameWithin(nade, "ads_target", ent.GetOrigin(), 90))
			{
				if (nade.GetTeam() == ATTACKERS)
				{
					DispatchParticleEffect("slime_splash_0" + RandomInt(1, 3), nade.GetOrigin(), Vector(0, 0, 0))
					ent.EmitSound("Weapon_CZ75A.Single")
					deleted.push(nade)
					local gun = Entities.FindByNameNearest("ads_gun", ent.GetOrigin(), 12)
					if (gun != null)
					{
						gun.SetForwardVector(nade.GetOrigin() - gun.GetOrigin())
					}
				}
			}
		}
		else if (ent.GetName() == "ads_gun")
		{
			local ang = ent.GetAngles()
			ang.y -= 3
			ent.SetAngles(ang.x, ang.y, ang.z)
		}
		else if (ent.GetName() == "nitro_cell")
		{
			if (ent.ValidateScriptScope())
			{
				local ss = ent.GetScriptScope()
				if (!("changed_model" in ss))
				{
					ss.changed_model <- true
					printl("melleated!!!")
				}
			}
		}
		else if (ent.GetName() == "turret_gun")
		{
			if (ent.ValidateScriptScope())
			{
				local ang = ent.GetAngles()
				local ss = ent.GetScriptScope()
				if ("firing" in ss && ss.firing)
				{
					local fwd = ent.GetForwardVector()
					local pos = ent.GetOrigin()
					local start = pos + (fwd * 18)
					local end = start + (fwd * 600)
					local tr_frac = TraceLine(start, end, null)
					local tr_hitpos = start + (fwd * 600 * tr_frac)
					DebugDrawLine(start, tr_hitpos, 255, 100, 100, true, 0.1)
					ent.EmitSound("Weapon_M249.Single")
				}
				if ("turn_yaw" in ss)
				{
					ang.y -= ss.turn_yaw
				}
				if ("turn_pitch" in ss)
				{
					ang.x += ss.turn_pitch
				}
				ent.SetAngles(ang.x, ang.y, ang.z)
			}
		}
		else if (ent.GetClassname() == "bumpmine_projectile")
		{
			if (ent.ValidateScriptScope())
			{
				local ss = ent.GetScriptScope()
				if (!("last_angles" in ss))
				{
					ss.last_angles <- AngSum(ent.GetAngles())
				}
				else if (ss.last_angles == AngSum(ent.GetAngles()))
				{
					local owner = ent.GetOwner()
					if (owner != null)
					{
						ent.StopSound("Survival.BumpIdle")
						ent.StopSound("Survival.BumpMineSetArmed")
						deleted.push(ent)
						switch (GetClass(owner))
						{
							case CLASS_ROOK:
								ArmorMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
								break

							case CLASS_JAGER:
								ADSMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
								break

							case CLASS_MUTE:
								JammerMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
								break
							
							default:
								WireMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
								break
						}
					}
				}
				else
				{
					ss.last_angles <- AngSum(ent.GetAngles())
				}
			}
		}
		else if (ent.GetClassname() == "tagrenade_projectile")
		{
			if (ent.GetVelocity().Length() == 0)
			{
				local owner = ent.GetOwner()
				if (owner != null)
				{
					ent.StopSound("Sensor.Activate")
					if (owner.GetTeam() == DEFENDERS)
					{
						switch (GetClass(owner))
						{
							case CLASS_TACHANKA:
								TurretMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
								break

							default:
								local ang = owner.GetAngles()
								ang.x = 0
								ShieldMaker.SpawnEntityAtLocation(ent.GetOrigin(), ang)
								break
						}
					}
					else if (owner.GetTeam() == ATTACKERS)
					{
						switch (GetClass(owner))
						{
							case CLASS_THATCHER:
								DestroyGadgetsInRange(ent.GetOrigin(), 100)
								DispatchParticleEffect("explosion_hegrenade_brief", ent.GetOrigin(), Vector(-1, 0, 0))
								DispatchParticleEffect("firework_crate_explosion_01", ent.GetOrigin(), ent.GetOrigin())
								ent.EmitSound("BaseGrenade.Explode")
								ent.EmitSound("ambient.electrical_random_zap_2")
								break

							default:
								local ang = owner.GetAngles()
								ang.x = 0
								ClaymoreMaker.SpawnEntityAtLocation(ent.GetOrigin(), ang)
								break
						}
					}
					deleted.push(ent)
				}
			}
		}
		else if (ent.GetClassname() == "decoy_projectile")
		{
			local owner = ent.GetOwner()
			if (owner.GetTeam() == ATTACKERS)
			{
				local charge = null
				while (charge = Entities.FindByName(charge, "breach_planted"))
				{
					if (charge.GetOwner() == owner)
					{
						local wall = Entities.FindByNameNearest("breakable_*", charge.GetOrigin(), 12)
						if (wall != null)
						{
							EntFireHandle(charge, "disable", "", 1)
							EntFireHandle(charge, "runscriptcode", "Kaboom(self)", 1)
							EntFireHandle(wall, "break", "", 1)
						}
						else if (GetClass(owner) == CLASS_THERMITE)
						{
							local reinf = Entities.FindByNameNearest("reinforcement", charge.GetOrigin(), 12)
							if (reinf != null)
							{
								charge.EmitSound("Molotov.IdleLoop")
								EntFireHandle(charge, "disable", "", 3)
								EntFireHandle(charge, "runscriptcode", "Kaboom(self)", 3)
								EntFireHandle(reinf, "disable", "", 3)
							}
						}
						charge.SetOwner(null)
					}
				}
			}
			else if (owner.GetTeam() == DEFENDERS)
			{
				printl("defender threw decoy??? sure")
			}
			deleted.push(ent)
		}
		else if (TICK_COUNT % 6 == 0 && ent.GetClassname() == "predicted_viewmodel")
		{
			local ply = ent.GetMoveParent()
			if (GetClass(ply) == CLASS_IQ && ent.GetModelName() == "models/weapons/v_pist_223.mdl")
			{
				local found_anything = false
				local device = null
				while (device = Entities.FindByClassnameWithin(device, "*", ply.EyePosition(), 100))
				{
					if (device.GetName() in ElectronicDevices)
					{
						DebugDrawBox(device.GetCenter(), device.GetBoundingMins(), device.GetBoundingMaxs(), 0, 200, 200, 80, 0.65)
						found_anything = true
					}
				}
				if (found_anything)
				{
					ent.EmitSound("Survival.BreachSoundActivate")
				}
			}
			else if (GetClass(ply) == CLASS_GLAZ)
			{
				local ss = ply.GetScriptScope()
				if (!("thermal" in ss))
				{
					ss.thermal <- 0
				}
				if (ent.GetModelName() == "models/weapons/v_snip_scar20.mdl")
				{
					if (ply.GetVelocity().Length() > 12)
					{
						ss.thermal--
						if (ss.thermal < 0)
						{
							ss.thermal <- 0
						}
					}
					else
					{
						ss.thermal++
						if (ss.thermal > 4)
						{
							ss.thermal <- 4
						}
					}
				}
				else
				{
					ss.thermal <- 0
				}
				if (ss.thermal > THERMAL)
				{
					::THERMAL <- ss.thermal
				}
				local str = ""
				for (local i = 0; i < ss.thermal; i++)
				{
					str += "|"
				}
				EntFire("hud_thermal", "settext", str + "                          " + str)
				EntFire("hud_thermal", "display", "", 0, ply)
			}
		}
	}
	foreach (ent in deleted)
	{
		if (ent != null)
		{
			ent.Destroy()
		}
	}
	if (TICK_COUNT % 6 == 0)
	{
		EntFire("defender", "addoutput", "rendercolor 255 255 " + (255 - (::THERMAL * 60)))
	}
	if (defenders_outside)
	{
		local atker = null
		while (atker = Entities.FindByClassname(atker, "player"))
		{
			if (atker.GetTeam() == ATTACKERS)
			{
				EntFire("hud_detectedoutside", "settext", "ENEMY DETECTED OUTSIDE")
				EntFire("hud_detectedoutside", "display", "", 0, atker)
			}
		}
	}
}

::ElectronicDevices <- {ads_base = true, mute_jammer = true, device_signal = true}
::BreakableGadgets <- {ads_base = true, ads_gun = true, mute_jammer = true, mute_jammer_piece = true}

::DestroyGadgetsInRange <- function(pos, range)
{
	local deleted = []
	local ent = null
	while (ent = Entities.FindInSphere(ent, pos, range))
	{
		if (ent.GetName() in BreakableGadgets)
		{
			ent.EmitSound("radio_computer.break")
			deleted.push(ent)
		}
	}
	foreach (ent in deleted)
	{
		if (ent != null)
		{
			ent.Destroy()
		}
	}
}

::BulletImpact <- function(data)
{
	local pos = Vector(data.x, data.y, data.z)
	DestroyGadgetsInRange(pos, 6)
}

::WireBroken <- function(ent)
{
	local wire = null
	while (wire = Entities.FindByNameWithin(wire, "razor_wire", ent.GetOrigin(), 30))
	{
		wire.Destroy()
	}
	EntFireHandle(ent, "break")
}

::ItemEquip <- function(data)
{
	printl(data.item)
}

::LocalPlayer <- function()
{
	return Entities.FindByClassname(null, "player")
}

::TraceTest <- function(ply)
{
	local pos = ply.EyePosition()
	local offset = ply.GetForwardVector() * 500
	local tr = TraceLine(pos, pos + offset, null)
	DebugDrawLine(pos, pos + (offset * tr), 0, 255, 0, true, 5)
	DebugDrawLine(pos + (offset * tr), pos + (offset * tr) + (offset * (1 - tr)), 255, 0, 0, true, 5)
}

/*
::TURRET_USER <- null

::PlayerUsedTurret <- function(ply)
{
	::TURRET_USER <- ply
}

::TurretUsed <- function(turret)
{
	local ply = TURRET_USER
	if (ply != null)
	{
		printl(ply + " used turret!")
		if (ply.ValidateScriptScope() && turret.ValidateScriptScope())
		{
			local ssp = ply.GetScriptScope()
			local sst = turret.GetScriptScope()
			if ("already_used" in sst)
			{
				
			}
			else
			{
				ssp.turret_prev <- [ply.GetHealth(), ply.GetOrigin(), ply.GetAngles()]
			}
		}
	}
}

::TurretEntered <- function(ply)
{
	
}

::TurretLeft <- function(ply)
{
	
}
*/

::TurretPressed <- function(btn)
{
	local game_ui = Entities.FindByNameNearest("turret_gameui", btn.GetOrigin(), 8)
	if (game_ui != null)
	{
		EntFireHandle(game_ui, "activate", "", 0, activator)
		EntFireHandle(btn, "lock")
	}
}

::TurretOn <- function(game_ui)
{
	game_ui.EmitSound("Survival.DroneGunScanForPlayerOutOfRange")
}

::TurretOff <- function(game_ui)
{
	local btn = Entities.FindByNameNearest("turret_button", game_ui.GetOrigin(), 8)
	if (btn != null)
	{
		EntFireHandle(btn, "unlock")
	}
}

::TurretShoot <- function(game_ui, on)
{
	local turret = Entities.FindByNameNearest("turret_gun", game_ui.GetOrigin(), 8)
	if (turret != null && turret.ValidateScriptScope())
	{
		turret.GetScriptScope().firing <- on
	}
}

::TurretYaw <- function(game_ui, amt)
{
	local gun = Entities.FindByNameNearest("turret_gun", game_ui.GetOrigin(), 8)
	if (gun != null && gun.ValidateScriptScope())
	{
		gun.GetScriptScope().turn_yaw <- amt
	}
}

::TurretPitch <- function(game_ui, amt)
{
	local gun = Entities.FindByNameNearest("turret_gun", game_ui.GetOrigin(), 8)
	if (gun != null && gun.ValidateScriptScope())
	{
		gun.GetScriptScope().turn_pitch <- amt
	}
}
