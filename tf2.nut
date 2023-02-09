
::SentryMaker <- EntityGroup[0]
::NadeMaker <- EntityGroup[1]
::DispenserMakers <- [EntityGroup[2], EntityGroup[3]]
::CapFountain <- EntityGroup[4]

ScriptPrintMessageChatAll("Welcome to Team Fortress 2!")
ScriptPrintMessageChatAll("After 9 years in development, hopefully it will have been worth the wait.")

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

::SMALL <- 0
::MEDIUM <- 1
::LARGE <- 2

::PickupHealth <- function(ply, type = MEDIUM)
{
	local heal_amt = ply.GetMaxHealth()
	if (type == SMALL)
	{
		heal_amt = ceil(ply.GetMaxHealth() / 5)
	}
	else if (type == MEDIUM)
	{
		heal_amt = ceil(ply.GetMaxHealth() / 2)
	}
	local new_health = ClampValue(ply.GetHealth() + heal_amt, 0, ply.GetMaxHealth())
	ply.SetHealth(new_health)
}

::PLAYERMODEL_PREFIX <- "models/player/custom_player/legacy/"
::PLAYERMODEL_POSTFIX <- ".mdl"
::PLYMDL <- function(mdl) {return PLAYERMODEL_PREFIX + mdl + PLAYERMODEL_POSTFIX}

::CLASS_NONE <- 0
::CLASS_SCOUT <- 1
::CLASS_SOLDIER <- 2
::CLASS_PYRO <- 3
::CLASS_DEMOMAN <- 4
::CLASS_HEAVY <- 5
::CLASS_ENGINEER <- 6
::CLASS_MEDIC <- 7
::CLASS_SNIPER <- 8
::CLASS_SPY <- 9

// model is [T, CT]
::ClassList <- [
	{weps = [], health = 125, speed = 1, models = ["tm_balkan_variantg", "ctm_swat"]},
	{weps = ["weapon_mag7", "weapon_fiveseven", "weapon_bayonet"], health = 125, speed = 1.1, gravity = 0.9, models = ["tm_balkan_variantg", "ctm_fbi_variantf"]},
	{weps = ["weapon_ump45", "weapon_knife_m9_bayonet", "weapon_bumpmine"], health = 200, speed = 0.8, gravity = 1.3, models = ["tm_balkan_variantc", "ctm_swat"]},
	{weps = ["weapon_tec9", "weapon_axe"], health = 175, speed = 1, models = ["tm_separatist", "ctm_sas_varianta"]},
	{weps = ["weapon_xm1014", "weapon_knife_flip", "weapon_hegrenade", "weapon_breachcharge"], health = 175, speed = 0.9, gravity = 1.15, models = ["tm_leet_varianth", "ctm_fbi_variantc"]},
	{weps = ["weapon_negev", "weapon_fists", "weapon_healthshot", "weapon_healthshot", "weapon_healthshot"], health = 300, speed = 0.7, gravity = 1.6, models = ["tm_phoenix_heavy", "ctm_heavy"]},
	{weps = ["weapon_nova", "weapon_fiveseven", "weapon_spanner", "weapon_tagrenade", "weapon_bumpmine"], health = 125, speed = 1, models = ["tm_leet_varianti", "ctm_st6_variantm"]},
	{weps = ["weapon_bizon", "weapon_knife_gut", "weapon_tagrenade"], health = 150, speed = 1, models = ["tm_balkan_varianth", "ctm_st6_variante"]},
	{weps = ["weapon_ssg08", "weapon_cz75a", "weapon_knife_survival_bowie", "weapon_tagrenade"], health = 125, speed = 1, models = ["tm_professional_var1", "ctm_st6_varianti"]},
	{weps = ["weapon_deagle", "weapon_knife_butterfly", "weapon_smokegrenade", "weapon_bumpmine"], health = 125, speed = 1, models = ["tm_phoenix_variantf", "ctm_sas_variantf"]}
]

::CloakPlayer <- function(ply, cloak)
{
	if (cloak)
	{
		EntFireHandle(ply, "DisableDraw")
		ply.__KeyValueFromString("targetname", "cloaked_spy")
	}
	else
	{
		EntFireHandle(ply, "EnableDraw")
		ply.__KeyValueFromString("targetname", "")
	}
}

::ToggleCloak <- function(ply)
{
	if (ply.GetName() == "cloaked_spy")
	{
		GiveLoadout(ply, ClassList[CLASS_SPY].weps)
		MeleeFixup()
		CenterPrint(ply, "Cloak OFF")
		CloakPlayer(ply, false)
	}
	else
	{
		StripWeapons(ply)
		CenterPrint(ply, "Cloak ON")
		CloakPlayer(ply, true)
	}
}

::UberPlayer <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		ClearJarate(ply)
		local ss = ply.GetScriptScope()
		ss.ubered <- true
		ss.ubered_time <- Time()
		if (ply.GetTeam() == 2)
		{
			ply.__KeyValueFromString("rendercolor", "255 0 0")
		}
		else
		{
			ply.__KeyValueFromString("rendercolor", "0 0 255")
		}
		CenterPrint(ply, "*** UBERCHARGED ***")
		ply.SetHealth(9999)
		ply.SetMaxHealth(9999)
		EntFireByHandle(ply, "RunScriptCode", "UberCheck(self)", 9, null, null)
		EntFire("fade_uber_" + ply.GetTeam(), "fade", "", 0, ply)
	}
}

::UberCheck <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("ubered" in ss && ss.ubered && ss.ubered_time + 8.5 < Time())
		{
			ply.__KeyValueFromString("rendercolor", "255 255 255")
			ss.ubered <- false
			CenterPrint(ply, "*** UBER WORE OFF ***")
			local hp = ClassList[GetClass(ply)].health
			ply.SetHealth(hp)
			ply.SetMaxHealth(hp)
		}
	}
}

/*
::Distance2D <- function(v1,v2)
{
	local a = (v2.x-v1.x);
	local b = (v2.y-v1.y);
	
	return sqrt((a*a)+(b*b));
}

::AngleBetween <- function(v1,v2)
{
	local aZ = atan2((v1.y - v2.y),(v1.x - v2.x))+PI;	
	local aY = atan2((v1.z - v2.z),Distance2D(v1,v2))+PI;	
	return Vector(aY,aZ,0.0);
}

::deg <- function(n)
{
	return n * 57.295779513082320876798154814105
}

::PointSentryTowards <- function(sentry, pos)
{
	local ang = AngleBetween(pos, sentry.GetOrigin())
	local new_pitch = ((deg(ang.x) / 2) - 90) * -2
	local new_yaw = ((deg(ang.y) + 360) % 360) - 180
	sentry.SetAngles(new_pitch, new_yaw, 0)
}

::WrangleSentries <- function(pos, team)
{
	printl("wranglin' at " + pos + " on team " + team)
	local sentry = null
	while (sentry = Entities.FindByClassname(sentry, "dronegun"))
	{
		PointSentryTowards(sentry, pos)
		printl(sentry)
	}
}

::WRENCH_MODEL <- "models/weapons/w_spanner_dropped.mdl"
*/

::FadeOut <- function(ent, delay = 0)
{
	if (ent.GetClassname() == "weapon_knifegg")
	{
		if (TraceLine(ent.GetOrigin(), ent.GetOrigin() - Vector(0, 0, 8), ent) == 1)
		{
			return
		}
		/*
		else if (ent.ValidateScriptScope() && ent.GetModelName() == WRENCH_MODEL)
		{
			local ss = ent.GetScriptScope()
			if (!("wrangled" in ss))
			{
				ss.wrangled <- true
				WrangleSentries(ent.GetOrigin(), ent.GetTeam())
			}
		}
		*/
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

::BuiltByPlayer <- function(building, ply)
{
	if (building.ValidateScriptScope())
	{
		local ss = building.GetScriptScope()
		if ("builder_index" in ss && ss.builder_index == ply.entindex())
		{
			return true
		}
	}
	return false
}

::SetClass <- function(ply, cls = 0)
{
	local tab = ClassList[cls]
	ply.SetMaxHealth(tab.health)
	ply.SetHealth(tab.health)
	GiveLoadout(ply, tab.weps)
	ModifySpeed(ply, tab.speed)
	MeleeFixup()
	ClearJarate(ply)
	CloakPlayer(ply, false)
	local mdl = PLYMDL(tab.models[ply.GetTeam() - 2])
	ply.PrecacheModel(mdl)
	ply.SetModel(mdl)
	if ("gravity" in tab)
	{
		ply.__KeyValueFromInt("gravity", tab.gravity)
	}
	else
	{
		ply.__KeyValueFromInt("gravity", 1)
	}
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		ss.last_health <- tab.health
		if (!("tf_class" in ss))
		{
			ss.tf_class <- CLASS_NONE
		}
		if ("on_fire" in ss && ss.on_fire)
		{
			ExtinguishPlayer(ply)
		}
		if (cls != ss.tf_class)
		{
			LostKillstreak(ply)
		}
		if (ss.tf_class == CLASS_ENGINEER && cls != CLASS_ENGINEER)
		{
			local sentry = null
			while (sentry = Entities.FindByClassname(sentry, "dronegun"))
			{
				if (BuiltByPlayer(sentry, ply))
				{
					sentry.__KeyValueFromInt("health", 1)
					EntFireHandle(sentry, "ignite")
				}
			}
			local disp = null
			while (disp = Entities.FindByName(disp, "dispenser_" + ((ply.GetTeam() == 2) ? "red" : "blue")))
			{
				if (BuiltByPlayer(disp, ply))
				{
					EntFireHandle(disp, "break")
				}
			}
		}
		if (cls == CLASS_MEDIC)
		{
			if (ss.tf_class != CLASS_MEDIC)
			{
				ss.built_uber <- 0
			}
			else if (ss.built_uber >= 100)
			{
				GiveWeapon(ply, "weapon_bumpmine")
			}
		}
		ss.tf_class <- cls
	}
}

::GetClass <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("tf_class" in ss)
		{
			return ss.tf_class
		}
	}
	return CLASS_NONE
}

::JaratePlayer <- function(ply)
{
	if (LivingPlayer(ply) && ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if (!("ubered" in ss) || !ss.ubered)
		{
			ss.jarate <- true
			ss.jarate_time <- Time()
			ply.__KeyValueFromString("rendercolor", "255 255 0")
			EntFireByHandle(ply, "RunScriptCode", "JarateCheck(self)", 5, null, null)
			EntFire("fade_jarate", "fade", "", 0, ply)
			return true
		}
	}
	else
	{
		return false
	}
}

::ClearJarate <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("jarate" in ss && ss.jarate)
		{
			ss.jarate <- false
			ply.__KeyValueFromString("rendercolor", "255 255 255")
		}
	}
}

::ShieldCharge <- function(ply = -1)
{
	if (ply == -1)
	{
		ply = Entities.FindByClassname(null, "player")
	}
	ply.SetOrigin(ply.GetOrigin() + Vector(0, 0, 20))
	ply.SetVelocity(ply.GetForwardVector() * 1500)
}

::PrintFate <- function(txt)
{
	ScriptPrintMessageChatAll("FATE: " + txt + "!")
}

::ChooseFate <- function(fate = -1)
{
	if (fate == -1)
	{
		fate = RandomInt(1, 3)
	}
	switch (fate)
	{
		case 1:
			PrintFate("Nothing")
			break

		case 2:
			PrintFate("Free uber")
			local ply = null
			while (ply = Entities.FindByClassname(ply, "*"))
			{
				if (LivingPlayer(ply))
				{
					UberPlayer(ply)
				}
			}
			break

		case 3:
			PrintFate("Covered in pee")
			local ply = null
			while (ply = Entities.FindByClassname(ply, "*"))
			{
				if (JaratePlayer(ply))
				{
					DispatchParticleEffect("explosion_basic_water", ply.GetOrigin(), ply.GetOrigin())
					ply.EmitSound("Glass.Break")
				}
			}
			break
	}
}

::CanCapture <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if (ply.GetName() == "cloaked_spy" || ("ubered" in ss && ss.ubered))
		{
			return false
		}
		return true
	}
	return false
}

::Resupply <- function(ply) {SetClass(ply, GetClass(ply))}
::IsClass <- function(ply, cls) {return GetClass(ply) == cls}
::Alive <- function(ply) {return ply.GetHealth() > 0}
::LivingPlayer <- function(ent) {return ent.GetClassname() == "player" && ent.GetHealth() > 0}
::AngSum <- function(ang) {return floor(ang.x) + "-" + floor(ang.y) + "-" + floor(ang.z)}
::MidAir <- function(ply) {return TraceLine(ply.GetOrigin(), ply.GetOrigin() - Vector(0, 0, 40), ply) == 1}
::LocalPlayer <- function() {return Entities.FindByClassname(null, "player")}

::JARATE_MODEL <- "models/props_junk/garbage_glassbottle001a.mdl"
::SENTRY_MODEL <- "models/props_survival/dronegun/dronegun_gib5.mdl"
::HEALTH_MODEL <- "models/weapons/w_eq_healthshot_dropped.mdl"

::HasWeapon <- function(ply, cls, dont_clear = false)
{
	local has = false
	local wep = null
	while (wep = Entities.FindByClassname(wep, cls))
	{
		local owner = wep.GetOwner()
		if (owner == null && !dont_clear)
		{
			FadeOut(wep)
		}
		if (owner == ply)
		{
			has = true
		}
	}
	return has
}

::HealthExplosion <- function(pos, heal_amt, radius, team = -1)
{
	local total_healing = 0
	local ply = null
	while (ply = Entities.FindByClassnameWithin(ply, "*", pos, radius))
	{
		if (LivingPlayer(ply) && (ply.GetTeam() == team || team == -1) && TraceLine(pos, ply.GetOrigin() + Vector(0, 0, 24), ply) == 1)
		{
			local healing = ClampValue(heal_amt, 0, ply.GetMaxHealth() - ply.GetHealth())
			ply.SetHealth(ply.GetHealth() + healing)
			total_healing += healing
		}
	}
	return total_healing
}

::LoopChar <- function(chr, amt)
{
	local str = ""
	for (local i = 0; i < amt; i++)
	{
		str += chr
	}
	return str
}

::CAPTURE_PROGRESS <- 0
::cap_timer <- 0
::melee_timer <- 0

Think <- function()
{
	local fuck = true // yeah
	local smoke = null
	while (smoke = Entities.FindByClassname(smoke, "smokegrenade_projectile"))
	{
		local owner = smoke.GetOwner()
		if (owner != null && owner.GetHealth() > 0 && fuck)
		{
			fuck = false
			ToggleCloak(owner)
			GiveWeapon(owner, "weapon_smokegrenade")
			smoke.EmitSound("Buttons.snd16")
			smoke.Destroy()
		}
	}
	fuck = true
	local nade = null
	while (nade = Entities.FindByClassname(nade, "hegrenade_projectile"))
	{
		if (nade.ValidateScriptScope() && nade.GetOwner() != null && !("given_new" in nade.GetScriptScope()))
		{
			nade.GetScriptScope().given_new <- true
			GiveWeapon(nade.GetOwner(), "weapon_hegrenade")
		}
	}
	local ply = null
	while (ply = Entities.FindByName(ply, "cloaked_spy"))
	{
		local blinking = false
		if (ply.ValidateScriptScope())
		{
			local ss = ply.GetScriptScope()
			if (("jarate" in ss && ss.jarate) || ("on_fire" in ss && ss.on_fire))
			{
				blinking = true
			}
		}
		if (!blinking)
		{
			local ent = null
			while (ent = Entities.FindByClassnameWithin(ent, "*", ply.GetOrigin(), 35))
			{
				if (LivingPlayer(ent) && ent.GetTeam() != ply.GetTeam())
				{
					blinking = true
				}
			}
		}
		// dont replace this with 'else'
		// read it first, lard ass
		if (blinking)
		{
			EntFireHandle(ply, "EnableDraw")
			ply.__KeyValueFromInt("rendermode", 1)
			ply.__KeyValueFromInt("renderamt", 100)
		}
		else
		{
			EntFireHandle(ply, "DisableDraw")
			ply.__KeyValueFromInt("rendermode", 0)
			ply.__KeyValueFromInt("renderamt", 255)
		}
	}
	fuck = true
	local bump = null
	while (bump = Entities.FindByClassname(bump, "bumpmine_projectile"))
	{
		if (bump.ValidateScriptScope())
		{
			local ss = bump.GetScriptScope()
			if (!("last_angles" in ss))
			{
				ss.last_angles <- AngSum(bump.GetAngles())
			}
			else if (ss.last_angles == AngSum(bump.GetAngles()))
			{
				local owner = bump.GetOwner()
				if (IsClass(owner, CLASS_SOLDIER))
				{
					continue
				}
				if (owner != null && fuck)
				{
					fuck = false
					switch (GetClass(owner))
					{
						case CLASS_MEDIC:
							local target = null
							while (target = Entities.FindByClassnameWithin(target, "*", bump.GetOrigin(), 16))
							{
								if (LivingPlayer(target) && target.GetTeam() == owner.GetTeam() && owner.ValidateScriptScope())
								{
									local ss = owner.GetScriptScope()
									if ("built_uber" in ss && ss.built_uber >= 100)
									{
										ss.built_uber <- 0
										UberPlayer(target)
										if (Alive(owner))
										{
											UberPlayer(owner)
										}
										break
									}
								}
							}
							DispatchParticleEffect("slime_splash_0" + RandomInt(1, 3), bump.GetOrigin(), bump.GetOrigin())
							bump.EmitSound("Survival.BumpMineDetonate")
							break

						case CLASS_SPY:
							local target = null
							while (target = Entities.FindByClassnameWithin(target, "dronegun", bump.GetOrigin(), 16))
							{
								if (target != null)
								{
									target.EmitSound("Survival.DroneGunBreakApart")
									DispatchParticleEffect("explosion_basic", target.GetOrigin(), target.GetOrigin())
									target.Destroy()
									break
								}
							}
							if (target == null)
							{
								while (target = Entities.FindByClassnameWithin(target, "prop_dynamic", bump.GetOrigin(), 16))
								{
									if (target != null && (target.GetName() == "dispenser_red" || target.GetName() == "dispenser_blue"))
									{
										target.EmitSound("Survival.DroneGunBreakApart")
										DispatchParticleEffect("explosion_basic", target.GetOrigin(), target.GetOrigin())
										target.Destroy()
										break
									}
								}
							}
							DispatchParticleEffect("slime_splash_0" + RandomInt(1, 3), bump.GetOrigin(), bump.GetOrigin())
							bump.EmitSound("Survival.BumpMineDetonate")
							break

						case CLASS_ENGINEER:
							DispenserMakers[owner.GetTeam() - 2].SpawnEntityAtLocation(bump.GetOrigin(), Vector(0, ((owner.GetAngles().y + 360) % 360) - 180, 0))
							local disp = Entities.FindByClassnameNearest("prop_dynamic", bump.GetOrigin(), 20)
							if (disp != null)
							{
								if (disp.ValidateScriptScope())
								{
									disp.GetScriptScope().builder_index <- owner.entindex()
								}
							}
							bump.EmitSound("Survival.ContainerDamage")
							break
					}
					bump.StopSound("Survival.BumpIdle")
					bump.StopSound("Survival.BumpMineSetArmed")
					bump.Destroy()
				}
			}
			else
			{
				ss.last_angles <- AngSum(bump.GetAngles())
			}
		}
	}
	fuck = true
	local tac = null
	while (tac = Entities.FindByClassname(tac, "tagrenade_projectile"))
	{
		if (tac.GetVelocity().Length() == 0 && fuck)
		{
			local owner = tac.GetOwner()
			if (owner != null)
			{
				fuck = false
				tac.StopSound("Sensor.Activate")
				switch (GetClass(owner))
				{
					case CLASS_ENGINEER:
						SentryMaker.SpawnEntityAtLocation(tac.GetOrigin(), Vector(0, 0, 0))
						local sentry = Entities.FindByClassnameNearest("dronegun", tac.GetOrigin(), 20)
						if (sentry != null)
						{
							sentry.SetMaxHealth(600)
							sentry.SetHealth(600)
							EntFireHandle(sentry, "color", (owner.GetTeam() == 2) ? "255 0 0" : "0 0 255")
							if (sentry.ValidateScriptScope())
							{
								sentry.GetScriptScope().builder_index <- owner.entindex()
							}
						}
						tac.EmitSound("Survival.DroneGunScanForPlayer")
						EntFire("env_gunfire", "addoutput", "weaponname weapon_aug", 1)
						break

					case CLASS_SNIPER:
						local ply = null
						while (ply = Entities.FindByClassnameWithin(ply, "*", tac.GetOrigin(), 300))
						{
							if (LivingPlayer(ply) && TraceLine(tac.GetOrigin(), ply.GetOrigin() + Vector(0, 0, 24), ply) == 1)
							{
								if (ply.GetTeam() == owner.GetTeam())
								{
									ExtinguishPlayer(ply)
								}
								else
								{
									JaratePlayer(ply)
								}
							}
						}
						DispatchParticleEffect("explosion_basic_water", tac.GetOrigin(), tac.GetOrigin())
						tac.EmitSound("Glass.Break")
						break

					case CLASS_MEDIC:
						local total_healing = HealthExplosion(tac.GetOrigin(), 20, 200, owner.GetTeam())
						if (total_healing > 0)
						{
							if (owner.ValidateScriptScope())
							{
								local ss = owner.GetScriptScope()
								if (ss.built_uber < 100)
								{
									ss.built_uber = ClampValue(ss.built_uber + ceil(total_healing / 3), 0, 100)
									if (ss.built_uber >= 100)
									{
										CenterPrint(owner, "UBER FULLY CHARGED")
										GiveWeapon(owner, "weapon_bumpmine")
									}
									else
									{
										CenterPrint(owner, "UBER: " + ss.built_uber + "%")
									}
								}
							}
						}
						tac.EmitSound("HealthShot.Pickup")
						DispatchParticleEffect("firework_crate_explosion_01", tac.GetOrigin(), tac.GetOrigin())
						if (Alive(owner))
						{
							GiveWeapon(owner, "weapon_tagrenade")
						}
						break
				}
				tac.Destroy()
			}
		}
	}
	local disp = null
	while (disp = Entities.FindByName(disp, "dispenser_*"))
	{
		if (disp.GetName() == "dispenser_red")
		{
			HealthExplosion(disp.GetOrigin() + Vector(0, 0, 50), 1, 80, 2)
		}
		else if (disp.GetName() == "dispenser_blue")
		{
			HealthExplosion(disp.GetOrigin() + Vector(0, 0, 50), 1, 80, 3)
		}
	}
	melee_timer++
	if (melee_timer > 5)
	{
		melee_timer = 0
		local boi = null
		while (boi = Entities.FindByClassname(boi, "player"))
		{
			if (Alive(boi) && (IsClass(boi, CLASS_PYRO) || IsClass(boi, CLASS_ENGINEER)) && !HasWeapon(boi, "weapon_knifegg"))
			{
				GiveWeapon(boi, IsClass(boi, CLASS_PYRO) ? "weapon_axe" : "weapon_spanner")
			}
		}
		MeleeFixup()
	}
	cap_timer++
	if (cap_timer > 19 && abs(CAPTURE_PROGRESS) < 50)
	{
		cap_timer = 0
		local cappers = 0
		local capper = null
		while (capper = Entities.FindByClassnameWithin(capper, "*", CapFountain.GetOrigin(), 250))
		{
			if (LivingPlayer(capper) && CanCapture(capper))
			{
				local cap_amt = IsClass(capper, CLASS_SCOUT) ? 2 : 1
				if (capper.GetTeam() == 2)
				{
					cappers += cap_amt
				}
				else
				{
					cappers -= cap_amt
				}
				EntFire("cp_hint", "showmessage", "", 0, capper)
			}
		}
		::CAPTURE_PROGRESS <- ClampValue(CAPTURE_PROGRESS + cappers, -50, 50)
		if (CAPTURE_PROGRESS != 0 && cappers != 0 && CAPTURE_PROGRESS % 5 == 0)
		{
			local amt = abs(CAPTURE_PROGRESS) / 5
			if (CAPTURE_PROGRESS > 0)
			{
				ScriptPrintMessageChatTeam(2, " \x0B BLU \x01 |□□□□□□□□□□|\x07" + LoopChar("■", amt) + "\x01" + LoopChar("□", 10 - amt) + "| \x07 RED")
				ScriptPrintMessageChatTeam(3, " \x07 RED \x01 |" + LoopChar("□", 10 - amt) + "\x07" + LoopChar("■", amt) + "\x01|□□□□□□□□□□| \x0B BLU")
			}
			else
			{
				ScriptPrintMessageChatTeam(2, " \x0B BLU \x01 |" + LoopChar("□", 10 - amt) + "\x0B" + LoopChar("■", amt) + "\x01|□□□□□□□□□□| \x07 RED")
				ScriptPrintMessageChatTeam(3, " \x07 RED \x01 |□□□□□□□□□□|\x0B" + LoopChar("■", amt) + "\x01" + LoopChar("□", 10 - amt) + "| \x0B BLU")
			}
		}
		if (abs(CAPTURE_PROGRESS) > 49)
		{
			if (CAPTURE_PROGRESS > 0)
			{
				EntFire("game_ender", "EndRound_TerroristsWin", "8")
				ScriptPrintMessageChatTeam(2, "GAME OVER - VICTORY!")
				ScriptPrintMessageChatTeam(3, "GAME OVER - DEFEAT!")
				SendToConsoleServer("mp_respawn_on_death_ct 0")
				EntFire("spawnblocker_blue", "disable")
				EntFire("classtriggers_blue", "disable")
				EntFire("resupply_blue", "disable")
				EntFire("spawnopener_blue", "disable")
				EntFire("spawndoor_blue*", "open")
				local loser = null
				while (loser = Entities.FindByClassname(loser, "*"))
				{
					if (LivingPlayer(loser) && loser.GetTeam() == 3)
					{
						StripWeapons(loser)
					}
				}
			}
			else
			{
				EntFire("game_ender", "EndRound_CounterTerroristsWin", "8")
				ScriptPrintMessageChatTeam(2, "GAME OVER - DEFEAT!")
				ScriptPrintMessageChatTeam(3, "GAME OVER - VICTORY!")
				SendToConsoleServer("mp_respawn_on_death_t 0")
				EntFire("spawnblocker_red", "disable")
				EntFire("classtriggers_red", "disable")
				EntFire("resupply_red", "disable")
				EntFire("spawnopener_red", "disable")
				EntFire("spawndoor_red*", "open")
				local loser = null
				while (loser = Entities.FindByClassname(loser, "*"))
				{
					if (LivingPlayer(loser) && loser.GetTeam() == 2)
					{
						StripWeapons(loser)
					}
				}
			}
		}
		local red = (CAPTURE_PROGRESS + 50) * 2.55
		CapFountain.__KeyValueFromString("rendercolor", red + " 0 " + (255 - red))
	}
}

::IncreaseKillstreak <- function(ply)
{
	if (ply.GetHealth() > 0 && ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("killstreak" in ss)
		{
			ss.killstreak++
		}
		else
		{
			ss.killstreak <- 1
		}
		if (ss.killstreak % 5 == 0)
		{
			ScriptPrintMessageChatAll(ss.killstreak + " killstreak!")
			EntFire("killstreak_sound", "PlaySound")
		}
		printl(ply + "'s killstreak: " + ss.killstreak)
	}
}

::LostKillstreak <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		ply.GetScriptScope().killstreak <- 0
	}
}

::JarateCheck <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("jarate_time" in ss && ss.jarate && ss.jarate_time + 4 < Time())
		{
			ClearJarate(ply)
		}
	}
}

::SentryDebug <- function(cls = "env_gunfire")
{
	local gun = null
	while (gun = Entities.FindByClassname(gun, cls))
	{
		printl(gun + " ANG -> " + gun.GetAngles())
		printl(gun + " FOR -> " + gun.GetForwardVector())
		DebugDrawLine(gun.GetOrigin(), gun.GetOrigin() + gun.GetForwardVector() * 256, 0, 255, 0, false, 3)
	}
}

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_damage_scale_t_head 0.8")
	SendToConsoleServer("mp_damage_scale_ct_head 0.8")
	SendToConsoleServer("sv_falldamage_scale 0.2")
	SendToConsoleServer("mp_teamname_1 BLU")
	SendToConsoleServer("mp_teamname_2 RED")
	SendToConsoleServer("mp_ignore_round_win_conditions 1")
	SendToConsoleServer("mp_solid_teammates 0")
	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope())
	{
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function()
		{
			IncreaseKillstreak(activator)
		}
	}
	DeathEvent <- Entities.CreateByClassname("trigger_brush")
	DeathEvent.__KeyValueFromString("targetname", "game_playerdie")
	if (DeathEvent.ValidateScriptScope())
	{
		DeathEvent.ConnectOutput("OnUse", "OnDeath")
		DeathEvent.GetScriptScope().OnDeath <- function()
		{
			if (activator != null)
			{
				if (activator.ValidateScriptScope())
				{
					local ss = activator.GetScriptScope()
					if ("jarate" in ss && ss.jarate)
					{
						activator.EmitSound("Weapon_Taser.Single")
						ClearJarate(activator)
					}
					if ("on_fire" in ss && ss.on_fire)
					{
						ss.on_fire <- false
					}
				}
				LostKillstreak(activator)
				SetClass(activator, CLASS_NONE)
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

::ClampValue <- function(val, min, max)
{
	if (val > max)
	{
		return max
	}
	if (val < min)
	{
		return min
	}
	return val
}

::PrintTable <- function(tab, printfunc = printl, indent = "")
{
	foreach (k, v in tab)
	{
		if (typeof v == "table")
		{
			PrintTable(v, printfunc, indent + "   ");
		}
		else
		{
			printfunc(k + " = " + v)
		}
	}
}

::IgnitePlayer <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		ss.on_fire <- true
		ss.ignite_time <- Time()
		EntFireByHandle(ply, "ignitelifetime", "5", 0, null, null)
		EntFireByHandle(ply, "runscriptcode", "IgniteCheck(self)", 5, null, null)
	}
}

::ExtinguishPlayer <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("on_fire" in ss && ss.on_fire)
		{
			ss.on_fire <- false
			EntFireByHandle(ply, "ignitelifetime", "0", 0, null, null)
			ply.EmitSound("Molotov.Extinguish")
		}
	}
}

::IgniteCheck <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("on_fire" in ss && ss.ignite_time + 4 < Time())
		{
			ss.on_fire <- false
		}
	}
}

::RANDOM_CRITS <- false
::ALL_CRIT <- false

::ToggleRandomCrits <- function()
{
	::RANDOM_CRITS <- !RANDOM_CRITS
	ScriptPrintMessageChatAll("Random crits: " + (RANDOM_CRITS ? "EN" : "DIS") + "ABLED.")
}

::ToggleAllCrits <- function()
{
	::ALL_CRIT <- !ALL_CRIT
	ScriptPrintMessageChatAll("100% crits: " + (ALL_CRIT ? "EN" : "DIS") + "ABLED.")
}

::Max <- function(a, b)
{
	if (a > b)
	{
		return a
	}
	return b
}

::PlayerHurt <- function(data)
{
	// PrintTable(data)
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*"))
	{
		if (ply.GetClassname() == "player" && ply.ValidateScriptScope())
		{
			local ss = ply.GetScriptScope()
			ss.health <- ClampValue(ply.GetHealth(), 0, ply.GetMaxHealth())
			if (!("last_health" in ss))
			{
				ss.last_health <- ply.GetMaxHealth()
			}
			local is_valid_data = (data.dmg_health == ss.last_health - ss.health) && data.health == ss.health
			if (is_valid_data && (ss.health < ss.last_health))
			{
				local crit_chance = (data.weapon == "knifegg") ? RandomInt(1, 6) : RandomInt(1, 20)
				local should_crit = data.weapon != "" && ((RANDOM_CRITS && crit_chance == 1) || ALL_CRIT)
				local damage_multiplier = 1
				if (ply.ValidateScriptScope() && !should_crit)
				{
					local ss = ply.GetScriptScope()
					if (("jarate" in ss && ss.jarate) || ("on_fire" in ss && ss.on_fire && data.weapon == "knifegg" && (data.dmg_health == 30 || data.dmg_health == 20 || data.dmg_health == 17)) || (data.weapon == "ump45" && MidAir(ply)) || (data.weapon == "ssg08" && data.hitgroup == 1))
					{
						should_crit = true
					}
				}
				// backstab check
				if (!should_crit && data.weapon == "knifegg" && ((data.dmg_health == 153 || data.dmg_health == 76) || (data.dmg_armor == 0 && data.armor == 0 && data.dmg_health == 90)))
				{
					printl("found a backstab")
					local spy = null
					while (spy = Entities.FindByClassnameWithin(spy, "*", ply.GetOrigin(), 50))
					{
						if (LivingPlayer(spy) && IsClass(spy, CLASS_SPY) && spy.GetTeam() != ply.GetTeam())
						{
							printl("found a spy --> (" + spy.GetAngles().y + " ) ply --> [" + ply.GetAngles().y + "]")
							local yaw_diff = abs((((ply.GetAngles().y - spy.GetAngles().y) + 180) % 360) - 180)
							printl("yaw diff: " + (ply.GetAngles().y - spy.GetAngles().y))
							printl("yaw diff (adjusted): " + yaw_diff)
							if (yaw_diff < 45)
							{
								printl("BACKSTAB!")
							}
							ply.SetHealth(1)
							should_crit = true
							break
						}
					}
				}
				if (should_crit)
				{
					if (ply.GetHealth() > 0)
					{
						local new_health = ClampValue(ss.health - ((ss.last_health - ss.health) * 2), 0, ply.GetMaxHealth())
						if (new_health == 0)
						{
							ply.SetHealth(1)
							EntFireHandle(ply, "ignitelifetime", "0.1")
						}
						else
						{
							ply.SetHealth(new_health)
						}
						ply.EmitSound("Weapon_Taser.Single")
					}
				}
				if (!IsClass(ply, CLASS_PYRO) && data.weapon == "tec9")
				{
					IgnitePlayer(ply)
				}
				if (data.weapon == "bizon")
				{
					local med = null
					while (med = Entities.FindByClassname(med, "*"))
					{
						if (LivingPlayer(med) && med.GetTeam() != ply.GetTeam())
						{
							local healing = ClampValue(data.dmg_health / 5, 0, med.GetMaxHealth() - med.GetHealth())
							med.SetHealth(med.GetHealth() + healing)
						}
					}
				}
				if (data.armor < 10)
				{
					GiveWeapon(ply, "item_assaultsuit")
				}
			}
			ss.last_health <- ClampValue(ply.GetHealth(), 0, ply.GetMaxHealth())
		}
	}
	if (data.weapon == "envgunfire")
	{
		local gun = null
		while (gun = Entities.FindByClassname(gun, "env_gunfire"))
		{
			if (gun.ValidateScriptScope())
			{
				local ss = gun.GetScriptScope()
				if (!("last_nade" in ss && ss.last_nade + 5 > Time()))
				{
					local pos = gun.GetOrigin()
					local fwd = gun.GetForwardVector() * 2000
					local tr = TraceLine(pos, pos + fwd, gun)
					// DebugDrawLine(pos, pos + (fwd * tr), 255, 0, 255, false, 5)
					// check 10 points from the gun to the hit pos for a player
					// that is within 80 units. if we find one, launch a nade.
					for (local i = 1; i < 11; i++)
					{
						local hit_pos = pos + (fwd * tr * (i.tofloat() / 10))
						local targ = null
						while (targ = Entities.FindByClassnameWithin(targ, "*", hit_pos, 80))
						{
							if (LivingPlayer(targ) && TraceLine(hit_pos, targ.GetOrigin(), targ) == 1)
							{
								local nade_pos = pos + Vector(0, 0, 10)
								NadeMaker.SpawnEntityAtLocation(nade_pos, Vector(0, 0, 0))
								local nade = Entities.FindByClassnameNearest("flashbang_projectile", nade_pos, 5)
								if (nade != null)
								{
									gun.EmitSound("Flashbang.Bounce")
									nade.SetAngularVelocity(RandomFloat(-30, 30), RandomFloat(-30, 30), RandomFloat(-30, 30))
									nade.SetVelocity(gun.GetForwardVector() * 80)
									EntFireByHandle(nade, "InitializeSpawnFromWorld", "", 0, null, null)
									ss.last_nade <- Time()
									return
								}
							}
						}
					}
				}
			}
		}
	}
}

::GrenadeThrown <- function()
{
	local tac = null
	while (tac = Entities.FindByClassname(tac, "tagrenade_projectile"))
	{
		if (tac.ValidateScriptScope())
		{
			local ss = tac.GetScriptScope()
			if (!("replaced_model" in ss))
			{
				local ply = tac.GetOwner()
				if (ply != null)
				{
					if (IsClass(ply, CLASS_ENGINEER))
					{
						tac.PrecacheModel(SENTRY_MODEL)
						tac.SetModel(SENTRY_MODEL)
					}
					else if (IsClass(ply, CLASS_MEDIC))
					{
						tac.PrecacheModel(HEALTH_MODEL)
						tac.SetModel(HEALTH_MODEL)
					}
					else
					{
						tac.PrecacheModel(JARATE_MODEL)
						tac.SetModel(JARATE_MODEL)
					}
				}
				ss.replaced_model <- true
			}
		}
	}
	/*
	local decoy = null
	while (decoy = Entities.FindByClassname(decoy, "decoy_projectile"))
	{
		if (decoy.GetVelocity().Length() == 0)
		{
			local owner = decoy.GetOwner()
			if (owner != null && LivingPlayer(owner) && IsClass(owner, CLASS_ENGINEER))
			{
				
			}
			decoy.Destroy()
		}
	}
	*/
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

::BulletImpact <- function(data)
{
	if (FIRED_MAG7[0] == Time() && FIRED_MAG7[1] == data.userid)
	{
		::FIRED_MAG7 <- [0, 0]
		local hit_pos = Vector(data.x, data.y, data.z)
		local scout = Entities.FindByClassnameNearest("player", hit_pos, 100)
		if (scout != null && Alive(scout) && IsClass(scout, CLASS_SCOUT))
		{
			scout.SetVelocity(scout.GetVelocity() + (NormalizeVector(scout.GetOrigin() - hit_pos) * 300))
			DispatchParticleEffect("explosion_hegrenade_brief", hit_pos, Vector(-1, 0, 0))
		}
	}
	if (FIRED_TEC9[0] == Time() && FIRED_TEC9[1] == data.userid)
	{
		::FIRED_TEC9 <- [0, 0]
		local hit_pos = Vector(data.x, data.y, data.z)
		DispatchParticleEffect("impact_generic_burn", hit_pos, Vector(0, 0, 1))
		DispatchParticleEffect("impact_generic_burn", hit_pos, Vector(0, 0, 1))
	}
	if (FAN_DEBUG)
	{
		local hit_pos = Vector(data.x, data.y, data.z)
		local nig = Entities.FindByClassnameNearest("player", hit_pos, 100)
		if (nig != null)
		{
			nig.SetVelocity(nig.GetVelocity() + (NormalizeVector(nig.GetOrigin() - hit_pos) * 300))
		}
	}
}
