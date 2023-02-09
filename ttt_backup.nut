
IncludeScript("butil")

// gamemode config

::AddConfigValue <- function(name, val, desc = "") {
	local key = "TTT_" + name
	getroottable()[key] <- val
	::TTT_CONFIG.push([name, desc])
}

if (!("TTT_CONFIG" in getroottable())) {
	::TTT_CONFIG <- []

	Chat(GRAY + "Setting up TTT config. You should only see this once.")

	AddConfigValue("KARMA_PENALTY", 100, "Karma penalty for normal RDM.")
	AddConfigValue("KARMA_TEAMKILL_MULTIPLIER", 2, "Karma penalty multiplier for RDMing a known teammate.")
	AddConfigValue("KARMA_DEFAULT", 1000, "Default karma.")
	AddConfigValue("KARMA_MIN", 50, "Minimum karma.")
	AddConfigValue("KARMA_MAX", 1200, "Maximum karma.")

	AddConfigValue("DETECTIVE_MIN_PLAYERS", 5, "Minimum players for a Detective to be selected.")
	AddConfigValue("DETECTIVE_MODEL", "models/player/custom_player/legacy/ctm_sas_varianta.mdl", "Detective player model.")
	// AddConfigValue("DETECTIVE_GIVE_SHIELD", true, "Whether to give the detective a shield.")

	AddConfigValue("TRAITOR_PCT", 0.3, "[0-1] Fraction of players selected as Traitor.")

	AddConfigValue("JESTER_MIN_PLAYERS", 4, "Minimum players for a Jester to be selected.")
	AddConfigValue("JESTER_EXTREME", true, "Whether the Hester outright wins when killed.")
	AddConfigValue("JESTER_TESTS_AS_TRAITOR", true, "Whether the Jester tests as a Traitor.")
}

// script start

::GiveWeapon <- function(ply, weapon, ammo = 999) {
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 1)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	EntFireByHandle(equip, "Kill", "", 0.1, null, null)
}

::HSMaker <- EntityGroup[0]
::TraitorMaker <- EntityGroup[1]
::JestMaker <- EntityGroup[2]
::JesterDeathSound <- EntityGroup[3]

::INNOCENT <- 0
::TRAITOR <- 1
::DETECTIVE <- 2
::JESTER <- 3

::ROLE_NAME <- ["innocent", "traitor", "detective", "jester"]

::IsRole <- function(ply, role) {return GetRole(ply) == role}
::SetRole <- function(ply, role) {ply.__KeyValueFromString("targetname", "player_" + ROLE_NAME[role])}

::GetRole <- function(ply) {
	switch (ply.GetName()) {
		case "player_traitor":
			return TRAITOR

		case "player_detective":
			return DETECTIVE

		case "player_jester":
			return JESTER

		default:
			return INNOCENT
	}
}

::SetHSAngles <- function(x, y, z) {
	local hs = null
	while (hs = Entities.FindByName(hs, "health_station")) {
		if (hs.ValidateScriptScope()) {
			local ss = hs.GetScriptScope()
			if (!("angles_set" in ss)) {
				ss.angles_set <- true
				hs.SetAngles(x, y, z)

				// in SetHSAngles cmonBruh
				ss.InputUse <- function() {
					if (self.ValidateScriptScope() && GetRole(activator) == TRAITOR) {
						local ss = self.GetScriptScope()
						if (!("bomb_planted" in ss) || ss.bomb_planted == 0) {
							ss.bomb_planted <- Time()
							ss.bomb_planter <- activator
							CenterPrint(activator, "Bomb planted! Health station will explode in 20 seconds.")
						}
					}
				}
			}
		}
	}
}

::CameraPan <- function(cam) {
	local ang = cam.GetAngles()
	cam.SetAngles(ang.x, ang.y + (sin(Time() / 3) / 3), ang.z)
}

::hs_timer <- 0
::hud_timer <- 0
::role_timer <- 0

Think <- function() {
	local deleted = []

	::hs_timer++
	if (::hs_timer > 9) {
		::hs_timer <- 0
		local hs = null
		while (hs = Entities.FindByName(hs, "health_station")) {
			// timebomb
			if (hs.ValidateScriptScope()) {
				local ss = hs.GetScriptScope()
				if ("bomb_planted" in ss && ss.bomb_planted > 0) {
					local fuze = Time() - ss.bomb_planted
					if (fuze > 19) {
						// later nerds
						local pos = hs.GetOrigin()
						local culprit = ("bomb_planter" in ss) ? ss.bomb_planter : hs

						local boom = Entities.CreateByClassname("env_explosion")
						boom.__KeyValueFromInt("iMagnitude", 300)
						boom.SetOrigin(pos)
						boom.SetOwner(culprit)

						EntFireByHandle(boom, "Explode", "", 0.1, culprit, culprit)
						DispatchParticleEffect("explosion_hegrenade_brief", pos, Vector(-1, 0, 0))
						hs.EmitSound("basegrenade.explode")
						deleted.push(hs)
						continue
					} else if (fuze > 18) {
						// one second warning
						hs.EmitSound("c4.click")
						continue
					}
				}
			}

			// healing
			local healed = false
			local ply = null
			while (ply = Entities.FindByClassnameWithin(ply, "*", hs.GetOrigin(), 120)) {
				if (LivingPlayer(ply) && TraceLine(hs.GetOrigin(), ply.GetOrigin() + Vector(0, 0, 20), hs) == 1) {
					local healing = Clamp(5, 0, ply.GetMaxHealth() - ply.GetHealth())
					ply.SetHealth(ply.GetHealth() + healing)
					if (healing > 0) {
						DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), Vector(0, 0, 0))
						healed = true
					}
				}
			}
			if (healed)
				hs.EmitSound("HealthShot.Pickup")
		}
	}

	// tick all entities at once
	local ent = null
	while (ent = Entities.Next(ent)) {
		// player tick
		if (LivingPlayer(ent)) {
			// pickup weapons
			local pickup = Entities.FindByNameNearest("pickup_*", ent.GetOrigin(), 40)
			if (pickup != null) {
				local wepname = pickup.GetName().slice(7)
				local weptype = (wepname in WepTypes) ? WepTypes[wepname] : -1
				local already_has = false
				local wep = null
				if (weptype == -1) {
					while (wep = Entities.FindByClassname(wep, wepname)) {
						if (wep.GetOwner() == ent && wep.GetClassname() == wepname) {
							already_has = true
							break
						}
					}
				} else {
					while (wep = Entities.FindByClassname(wep, "weapon_*")) {
						local cls = wep.GetClassname()
						if (!(cls in WepTypes))
							continue
						if (wep.GetOwner() == ent && WepTypes[cls] == weptype) {
							already_has = true
							break
						}
					}
				}
				if (!already_has) {
					GiveWeapon(ent, wepname)
					pickup.Destroy()
				}
			}

			// spread covid
			if (ent.ValidateScriptScope()) {
				local ss = ent.GetScriptScope()
				if ("infected" in ss && ss.infected) {
					// show symptoms
					if (Time() - ss.infected > 20) {
						if ("next_covid" in ss) {
							if (Time() > ss.next_covid) {
								// lower health
								local new_health = ent.GetHealth() - RandomInt(2, 5)
								if (new_health > 0) {
									ent.SetHealth(new_health)
								}
								else {
									ent.SetHealth(1)
									EntFireHandle(ent, "IgniteLifetime", "0.1", 0.1)
								}

								// aagahghghghghg im coofing!!!!!!!!!!
								local coof = Entities.FindByName(null, "covid_snd" + RandomInt(1, 8))
								if (coof != null) {
									coof.SetOrigin(ent.EyePosition())
									EntFireHandle(coof, "playsound")
								}

								// set next
								ss.next_covid <- Time() + RandomFloat(2, 8)
							}
						} else {
							ss.next_covid <- Time() + RandomFloat(0, 3)
						}
					}

					// spread the disease
					if (RandomInt(1, 10) == 1) {
						local nearby = null
						while (nearby = Entities.FindByNameWithin(nearby, "player_*", ent.GetOrigin(), 200)) {
							if (nearby != ent)
								InfectPlayer(nearby)
						}
					}
				}
			}
		} else if (ent.GetClassname() == "tagrenade_projectile") {
			if (ent.GetVelocity().Length() == 0) {
				local owner = ent.GetOwner()
				if (owner != null) {
					HSMaker.SpawnEntityAtLocation(ent.GetOrigin(), Vector(0, 0, 0))
					ent.StopSound("Sensor.Activate")
					EntFire("health_station", "color", "100 100 255")
					local ang = ent.GetAngles()
					if (ent.ValidateScriptScope()) {
						local ss = ent.GetScriptScope()
						if ("last_angles" in ss)
							ang = ent.GetScriptScope().last_angles
					}
					SetHSAngles(ang.x, ang.y, ang.z)
					deleted.push(ent)
				}
			} else if (ent.ValidateScriptScope()) {
				local ss = ent.GetScriptScope()
				if (!("microwave" in ss)) {
					ss.microwave <- true
					ent.SetModel("models/props/cs_office/microwave.mdl")
					ent.__KeyValueFromString("rendercolor", "100 100 255")
				}
				// store in-motion angles so it doesn't use landing normal for microwave
				ss.last_angles <- ent.GetAngles()
			}
		} else if (ent.GetClassname() == "decoy_projectile") {
			if (ent.GetVelocity().Length() == 0) {
				DispatchParticleEffect("explosion_hegrenade_brief", ent.GetOrigin(), Vector(-1, 0, 0))
				DispatchParticleEffect("firework_crate_explosion_01", ent.GetOrigin(), Vector(0, 0, 0))
				ent.EmitSound("BaseGrenade.Explode")

				local ply = null
				while (ply = Entities.Next(ply)) {
					if (LivingPlayer(ply) && DistToSqr(ent.GetOrigin(), ply.GetOrigin()) < 62500) {
						local ang = ply.GetAngles()
						ply.SetAngles(ang.x + RandomInt(-10, 10), ang.y + RandomInt(-10, 10), 0)
						local vel = NormalizeVector(ply.GetOrigin() - ent.GetOrigin()) * RandomFloat(250, 260)
						vel.z = Max(vel.z, RandomInt(300, 400))
						ply.SetVelocity(vel)
						ply.EmitSound("ambient.electrical_random_zap_2")
					}
				}

				deleted.push(ent)
			}
		}
	}

	foreach (ent in deleted)
		ent.Destroy()

	if (CAM_PLY != null) {
		EntFire("sec_cam*", "RunScriptCode", "CameraPan(self)")
		EntFire("sec_cam*", "RunScriptCode", "CameraPan(self)", 0.05)
	}

	// dumb ass hud stuff
	::hud_timer++
	if (::hud_timer > 4) {
		::hud_timer <- 0
		UpdateRoleHints()
	}
	if (PREPARING && !ScriptIsWarmupPeriod()) {
		::role_timer++
		if (::role_timer > 99 && GetPlayerCount() > 1) {
			AssignRoles()
		}
	}
}

::GetPlayerCount <- function(role = -1) {
	local count = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*")) {
		if (ply.GetClassname() == "player" && (role == -1 || IsRole(ply, role))) {
			count++
		}
	}
	return count
}

::GetLivingPlayerCount <- function(role = -1) {
	local count = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*")) {
		if (LivingPlayer(ply) && (role == -1 || IsRole(ply, role))) {
			count++
		}
	}
	return count
}

::PREPARING <- true
::ROUND_OVER <- false
::ShowHintToPlayer <- function(ply, name) {EntFire("hud_" + name, "display", "", 0, ply)}

::RoleHintMe <- function(ply, target = -1) {
	if (PREPARING) {
		ShowHintToPlayer(ply, "preparing")
		return
	}
	if (ROUND_OVER) {
		ShowHintToPlayer(ply, "roundover")
		return
	}
	if (ply.GetHealth() < 1 && target == -1) {
		local spec = Entities.FindByClassnameWithin(ply, "player", ply.GetOrigin(), 15)
		if (LivingPlayer(spec)) {
			RoleHintMe(ply, spec)
			return
		}
		ShowHintToPlayer(ply, "dead")
		return
	}

	if (target == -1)
		target = ply

	switch (GetRole(target)) {
		case TRAITOR:
			ShowHintToPlayer(ply, "traitor")
			break
		case DETECTIVE:
			ShowHintToPlayer(ply, "detective")
			break
		case JESTER:
			ShowHintToPlayer(ply, "jester")
			break
		default:
			ShowHintToPlayer(ply, "innocent")
			break
	}
}

::UpdateRoleHints <- function()
	ForEachPlayerAndBot(RoleHintMe)

::InspectBody <- function(ply, role)
	CenterPrint(ply, "This is the body of a " + ROLE_NAME[role].toupper() + "!")

::PlayerDeath <- function(ply) {
	if (GetRole(ply) == JESTER) {
		JestMaker.SpawnEntityAtLocation(ply.GetOrigin(), Vector(0, 0, 0))
		DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), Vector(0, 0, 0))
		JesterDeathSound.SetOrigin(ply.GetOrigin())
		EntFireHandle(JesterDeathSound, "playsound")
	} else if (GetRole(ply) == TRAITOR) {
		TraitorMaker.SpawnEntityAtLocation(ply.GetOrigin(), Vector(0, 0, 0))
	}
	if (!PREPARING && !ROUND_OVER) {
		if ((GetLivingPlayerCount(INNOCENT) + GetLivingPlayerCount(DETECTIVE)) < 1) {
			RoundWin("traitor")
		} else if (GetLivingPlayerCount(TRAITOR) < 1) {
			RoundWin("innocent")
		}
	}
	UpdateRoleHints()
}

// karma

::KARMA_DEFAULT <- 1000
::KARMA_MIN <- 200
::KARMA_MAX <- 1200

::SetKarma <- function(ply, karma) {
	if (ply.ValidateScriptScope())
		ply.GetScriptScope().ttt_karma <- Clamp(karma, TTT_KARMA_MIN, TTT_KARMA_MAX)
}

::GetKarma <- function(ply) {
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if (!("ttt_karma" in ss))
			ss.ttt_karma <- TTT_KARMA_DEFAULT
		return ss.ttt_karma
	}
	return TTT_KARMA_DEFAULT
}

::AddKarma <- function(ply, karma)
	SetKarma(ply, GetKarma(ply) + karma)

::RoundWin <- function(role) {
	EntFire("round_ender", "EndRound_" + (role == "innocent" ? "" : "Counter") + "TerroristsWin", "7")
	::ROUND_OVER <- true

	EntFire("win_overlay_" + role, "startoverlays")
	EntFire("win_overlay_" + role, "stopoverlays", "", 6)

	switch (role) {
		case "traitor":
			Chat(RED + "TRAITORS WIN!")
			break

		case "jester":
			Chat(MAGENTA + "JESTER WINS!")
			break

		case "innocent":
			Chat(LIME + "INNOCENTS WIN!")
			break
	}

	// TEMP: funny after-round hints
	if (RandomInt(1, 4) == 1) {
		local hints = [
			"The hatch to the reactor can be opened by two people.",
			"The detective is immune to infection, but will still suffocate without oxygen.",
			"Often times, as Traitor, you can get the Innocents to do your work for you.",
			"If you're an Innocent, don't shoot the fucking Jester.",
			"It's easy to accidentally kill your Traitor buddy. Make sure to leverage it in your favor.",
			"Your chances of losing Russian Roulette are 1 in 6.",
			"Decoy grenades discombobulate nearby gamers when they detonate.",
			"When the lights are out, Traitors can see slightly farther than everyone else.",
			"If there are multiple Traitors, it's possible to start a lockdown and cut oxygen at the same time.",
			"If you get hurt, you can regenerate health in the Medbay.",
			"Traitors can press E on a health station to make it explode in 20 seconds.",
			"In the Traitor room, there is a button to unlock the AWP in the weapons room."
		]
		Chat(GRAY + "TIP: " + hints[RandomInt(0, hints.len() - 1)])
	}
}

::PlayerKilledPlayer <- function(victim, killer) {
	if (PREPARING || ROUND_OVER || victim == killer)
		return

	local vrole = GetRole(victim)
	local krole = GetRole(killer)

	if (vrole == krole || (vrole == DETECTIVE && krole == INNOCENT) || (vrole == INNOCENT && krole == DETECTIVE)) {
		local penalty = GetKarma(victim) / 10
		if (krole == TRAITOR || vrole == DETECTIVE) {
			CenterPrint(killer, "2x Karma penalty for killing " + (vrole == DETECTIVE ? "the detective" : "a fellow traitor") + ".") //F" + (RandomInt(1, 8) == 1 ? "ri" : "u") + "ck you.")
			AddKarma(killer, penalty * -2)
		} else
			AddKarma(killer, penalty * -1)
		// no karma reward next round
		if (killer.ValidateScriptScope())
			killer.GetScriptScope().has_rdmed <- true
	}
	if (vrole == JESTER && krole != TRAITOR) {
		if (TTT_JESTER_EXTREME) {
			RoundWin("jester")
		} else {
			CenterPrint(killer, "You killed the Jester!")
			EntFireHandle(killer, "IgniteLifetime", "30")
		}
	}
}

::LAST_DEATH <- null

::Debug_PrintRoles <- function() {
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (ply.GetClassname() == "player") {
			if (ply.GetHealth() > 0) {
				printl(ply)
			} else {
				printl(ply + " - DEAD")
			}
		}
	}
}

// TODO: Model() function with auto-precaching

::Debug_ModelTest <- function(mdl = "models/player/custom_player/legacy/tm_phoenix_varianta.mdl") {
	local ent = null
	while (ent = Entities.FindByModel(ent, mdl))
		printl(ent)
}

::MakeDetective <- function(ply) {
	SetRole(ply, DETECTIVE)
	ply.PrecacheModel(TTT_DETECTIVE_MODEL)
	ply.SetModel(TTT_DETECTIVE_MODEL)

	// GiveWeapon(ply, "weapon_shield")
	GiveWeapon(ply, "weapon_tagrenade")
	GiveWeapon(ply, "item_assaultsuit")

	/*
	if (CURRENT_ROUND == 0) {
		GiveWeapon(ply, "weapon_aug")
		GiveWeapon(ply, "weapon_fiveseven")
	}
	*/
}

::TRAITORS <- []

::SendAllToPocketDimension <- function() {
	ForEachPlayerAndBot(PocketDimension)
	EntFire("tp_fade", "fade")
}

::SwapPlaces <- function(ply, marker) {
	local pos = ply.GetOrigin()
	local ang = ply.GetAngles()
	local mang = marker.GetAngles()
	ply.SetOrigin(marker.GetOrigin())
	ply.SetAngles(mang.x, mang.y, mang.z)
	marker.SetAngles(ang.x, ang.y, ang.z)
	marker.SetOrigin(pos)
}

::PocketDimension <- function(ply) {
	local tp = Entities.FindByName(null, "tpexit_innocent_" + ply.entindex())
	for (local i = 0; i < TRAITORS.len(); i++) {
		if (ply == TRAITORS[i])
			tp = Entities.FindByName(null, "tpexit_traitor_" + (i + 1))
	}
	if (tp == null) {
		printl("NULL POCKET DIMENSION EXIT - NOT GOOD!!! (" + ply + ")")
		return
	}
	SwapPlaces(ply, tp)
}

::MeetingTP <- function(ply) {
	local tp = Entities.FindByName(null, "tpexit_meeting_" + ply.entindex())
	if (tp == null) {
		printl("NULL EMERGENCY MEETING EXIT - NOT GOOD!!! (" + ply + ")")
		return
	}
	SwapPlaces(ply, tp)
}

::EndEmergencyMeeting <- function() {
	ForEachPlayerAndBot(MeetingTP)
	SendToConsoleServer("mp_damage_scale_t_head 1.0")
	SendToConsoleServer("mp_damage_scale_t_body 1.0")
}

::EmergencyMeeting <- function(ply) {
	if (GetRole(ply) != DETECTIVE) {
		CenterPrint(ply, "Only the Detective can call an emergency meeting!")
		return
	}
	EntFire("button_emergency_meeting", "kill")
	ForEachPlayerAndBot(MeetingTP)
	EntFire("tp_fade", "fade")
	local delay = 25
	Chat(BLUE + "An EMERGNECY MEETING has been called!")
	Chat(BLUE + "You have " + delay + " seconds to deliberate.")
	Chat(BLUE + "Gun damage is reduced by 70%.")
	SendToConsoleServer("mp_damage_scale_t_head 0.3")
	SendToConsoleServer("mp_damage_scale_t_body 0.3")
	EntFire("tp_sound_up", "playsound")
	EntFire("tp_sound_down", "playsound", "", delay - 3.5)
	EntFire("script", "RunScriptCode", "EndEmergencyMeeting()", delay)
}

if (!("KITTYS" in getroottable()))
	::KITTYS <- false

::AssignRoles <- function() {
	::PREPARING <- false
	local plylist = []
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingPlayer(ply)) {
			plylist.push(ply)
			local karma = GetKarma(ply)
			local remark = ""
			if (karma <= 600)
				remark = " Behave yourself, yeah?"
			else if (karma >= 1000)
				remark = " Good job!"
			CenterPrint(ply, "Your Karma for this round is " + karma + "." + remark)
			local hp = Min(karma / 10, 100)
			ply.SetMaxHealth(hp)
			ply.SetHealth(hp)
			// replace eaten armor from prep time
			GiveWeapon(ply, "item_kevlar")
			// reward players with good behavior
			// do it afterwards so it takes 2 rounds
			if (ply.ValidateScriptScope()) {
				local ss = ply.GetScriptScope()
				if (!("has_rdmed" in ss))
					ss.has_rdmed <- true
				if (!ss.has_rdmed)
					AddKarma(ply, (karma < 1000) ? 100 : 50)
				ss.has_rdmed <- false
			}
		}
	}
	local count = GetPlayerCount()
	::TRAITORS <- []
	local traitor_amt = Clamp(floor(count * TTT_TRAITOR_PCT), 1, count - 1)
	do {
		local index = RandomInt(1, plylist.len()) - 1
		SetRole(plylist[index], TRAITOR)
		TRAITORS.push(plylist[index])
		plylist.remove(index)
		traitor_amt--
	}
	while (traitor_amt > 0)
	if (count >= TTT_DETECTIVE_MIN_PLAYERS) {
		local det_candidates = []
		foreach (pl in plylist) {
			if (pl.ValidateScriptScope()) {
				local ss = pl.GetScriptScope()
				if (!("detpref" in ss))
					ss.detpref <- true

				if (ss.detpref)
					det_candidates.push(pl)
			}
		}
		if (det_candidates.len() > 0) {
			local det = det_candidates[RandomInt(1, det_candidates.len()) - 1]
			MakeDetective(det)
			for (local i = 0; i < plylist.len(); i++) {
				if (plylist[i] == det) {
					plylist.remove(i)
				}
			}
		}
	}
	if (count >= TTT_JESTER_MIN_PLAYERS && RandomInt(1, 3) == 1) {
		local index = RandomInt(1, plylist.len()) - 1
		SetRole(plylist[index], JESTER)
		EntFire("speedmod", "ModifySpeed", "1.05", 0, plylist[index])
		foreach (traitor in TRAITORS) {
			ShowHintToPlayer(traitor, "jester_active")
		}
		plylist.remove(index)
	}
	UpdateRoleHints()
	SendToConsoleServer("mp_respawn_on_death_t 0")
	if (KITTYS) {
		EntFire("kitty_overlay", "startoverlays")
		EntFire("kitty_overlay", "stopoverlays", "", 0.1)
		::KITTYS <- false
	}

	// get to know your fellow traitor
	local ts = TRAITORS.len()
	if (ts > 1) {
		local delay = 2 * (ts + 1)
		Chat(DARK_RED + "Traitors, meet your allies.")
		SendAllToPocketDimension()
		EntFire("tp_sound_up", "playsound")
		EntFire("tp_sound_down", "playsound", "", delay - 3.5)
		EntFire("script", "RunScriptCode", "SendAllToPocketDimension()", delay)
	}
}

::WepTypes <- {
	weapon_famas = 1,
	weapon_ak47 = 1,
	weapon_m4a1 = 1,
	weapon_m4a1_silencer = 1,
	weapon_xm1014 = 1,
	weapon_mac10 = 1,
	weapon_mp7 = 1,
	weapon_ump45 = 1,
	weapon_ssg08 = 1,
	weapon_m249 = 1,
	weapon_sawedoff = 1,
	weapon_awp = 1,
	weapon_mp5sd = 1,
	weapon_bizon = 1,
	weapon_deagle = 2,
	weapon_p250 = 2,
	weapon_cz75a = 2,
	weapon_elite = 2,
	weapon_glock = 2,
	weapon_revolver = 2,
	weapon_usp_silencer = 2,
	weapon_smokegrenade = -1,
	weapon_decoy = -1,
	weapon_incgrenade = -1,
	weapon_molotov = -1,
	weapon_bumpmine = -1,
	weapon_taser = -1,
}

::CURRENT_ROUND <- 0

::RoundList <- [ {
		name = "Default",
		weps = [
			["weapon_famas", "weapons/w_rif_famas_dropped"],
			["weapon_ak47", "weapons/w_rif_ak47_dropped"],
			["weapon_m4a1", "weapons/w_rif_m4a1_dropped"],
			["weapon_xm1014", "weapons/w_shot_xm1014_dropped"],
			["weapon_xm1014", "weapons/w_shot_xm1014_dropped"],
			["weapon_mac10", "weapons/w_smg_mac10_dropped"],
			["weapon_mac10", "weapons/w_smg_mac10_dropped"],
			["weapon_mp7", "weapons/w_smg_mp7_dropped"],
			["weapon_ump45", "weapons/w_smg_ump45_dropped"],
			["weapon_ssg08", "weapons/w_snip_ssg08_dropped"],
			["weapon_ssg08", "weapons/w_snip_ssg08_dropped"],
			["weapon_m249", "weapons/w_mach_m249_dropped"],
			["weapon_deagle", "weapons/w_pist_deagle_dropped"],
			["weapon_deagle", "weapons/w_pist_deagle_dropped"],
			["weapon_cz75a", "weapons/w_pist_cz_75_dropped"],
			["weapon_elite", "weapons/w_pist_elite_dropped"],
			["weapon_glock", "weapons/w_pist_glock18_dropped"],
			["weapon_glock", "weapons/w_pist_glock18_dropped"],
			// grenades
			["weapon_smokegrenade", "weapons/w_eq_smokegrenade_dropped"],
			["weapon_decoy", "weapons/w_eq_decoy_dropped"],
			["weapon_incgrenade", "weapons/w_eq_incendiarygrenade_dropped"],
		],
		knives = ["bayonet", "knife_m9_bayonet", "knife_karambit", "knife_butterfly", "knife_survival_bowie"],
		models = ["tm_phoenix_varianta", "tm_phoenix_variantb", "tm_phoenix_variantc", "tm_phoenix_variantd"]
	}, {
		name = "Frontier Justice",
		weps = [
			["weapon_ssg08", "weapons/w_snip_ssg08_dropped"],
			["weapon_sawedoff", "weapons/w_shot_sawedoff_dropped"],
			["weapon_nova", "weapons/w_shot_nova_dropped"],
			["weapon_revolver", "weapons/w_pist_revolver_dropped"],
			["weapon_deagle", "weapons/w_pist_deagle_dropped"],
			["weapon_elite", "weapons/w_pist_elite_dropped"],
			["weapon_molotov", "weapons/w_eq_molotov_dropped"],
		],
		knives = ["fists"],
		models = ["tm_leet_varianta", "tm_leet_variantc", "tm_leet_variante"]
	}, {
		name = "Que Ota?",
		weps = [
			["weapon_deagle", "weapons/w_pist_deagle_dropped"],
		],
		knives = ["knife_css"],
		models = ["tm_leet_varianta", "tm_leet_variantc", "tm_leet_variante"]
	}, {
/*
		name = "Bad Business",
		weps = [
			["weapon_awp", "weapons/w_snip_awp_dropped"],
			["weapon_ak47", "weapons/w_rif_ak47_dropped"],
			["weapon_m4a1", "weapons/w_rif_m4a1_dropped"],
			["weapon_deagle", "weapons/w_pist_deagle_dropped"],
			["weapon_elite", "weapons/w_pist_elite_dropped"],
		],
		knives = ["knife_css"],
		models = ["tm_professional_varf", "tm_professional_varg", "tm_professional_varh", "tm_professional_vari", "tm_professional_varj"]
	}, {
*/
		name = "249 Problems (But Ammo Aint One)",
		weps = [
			["weapon_m249", "weapons/w_mach_m249_dropped"],
		],
		knives = ["knife_m9_bayonet"],
		models = ["tm_professional_varf", "tm_professional_varg", "tm_professional_varh", "tm_professional_vari", "tm_professional_varj"]
	}, {
		name = "When the AWP is SUS!",
		weps = [
			["weapon_awp", "weapons/w_snip_awp_dropped"],
		],
		knives = ["knife_karambit"],
		models = ["tm_professional_varf", "tm_professional_varg", "tm_professional_varh", "tm_professional_vari", "tm_professional_varj"]
	}, {
		name = "Sneaky Beaky",
		weps = [
			["weapon_mp5sd", "weapons/w_smg_mp5sd_dropped"],
			["weapon_usp_silencer", "weapons/w_pist_223_dropped"],
			["weapon_smokegrenade", "weapons/w_eq_smokegrenade_dropped"],
		],
		models = ["tm_phoenix_variantf"]
	}
]

::CURRENT_WEAPONLIST <- 0

::WeaponLists <- [
	{
		name = "Kafkaesque",
		[]
	}
]

::TryStopCams <- function() {
	if (CAM_PLY != null)
		StopCams(CAM_PLY)
}

OnPostSpawn <- function() {
	TryStopCams()

	if (ScriptIsWarmupPeriod()) {
		Chat(GRAY + "Waiting for warmup to end...")
	} else {
		Chat("Welcome to " + DARK_RED + "TTT" + WHITE +"! Your role is in the top left of your screen.")
		Chat("The " + GREEN + "INNOCENTS" + WHITE + " must stick together, survive, and kill the traitor.")
		Chat("The " + RED + "TRAITORS" + WHITE + " have access to special traps, and must kill all the others.")
		Chat("The " + BLUE + "DETECTIVE" + WHITE + " is proven innocent, and must help the innocents win.")
		Chat("The " + MAGENTA + "JESTER" + WHITE + " cannot shoot, but must convince the innocents of his guilt.")
		Chat("Only the " + RED + "TRAITORS" + WHITE + " and " + MAGENTA + "JESTER" + WHITE + " can go through vents.")
	}

	SendToConsoleServer("mp_humanteam t")
	SendToConsoleServer("bot_join_team t")
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_roundtime 5")
	SendToConsoleServer("mp_freezetime 0")
	SendToConsoleServer("mp_forcecamera 0")
	SendToConsoleServer("mp_limitteams 30")
	SendToConsoleServer("mp_solid_teammates 1")
	SendToConsoleServer("mp_autoteambalance 0")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_teammates_are_enemies 1")
	SendToConsoleServer("mp_damage_scale_t_head 1.0")
	SendToConsoleServer("mp_damage_scale_t_body 1.0")

	// doesnt work :(
	// EntFire("broadcaster", "Command", "cl_drawhud_force_deathnotices -1")

	// reset fog
	SetLightsOn(true)
	if (!ScriptIsWarmupPeriod()) {
		EntFire("fog_darkness", "TurnOn")
		EntFire("fog_darkness_traitor", "TurnOn")
		EntFire("fog_default", "TurnOn")
	}
	
	::CURRENT_ROUND <- 0
	if (RandomInt(1, 6) == 1)
		::CURRENT_ROUND <- RandomInt(0, RoundList.len() - 1)

	local RoundData = RoundList[CURRENT_ROUND]

	if (CURRENT_ROUND) {
		Chat("Special round: " + MINT + RoundData.name + WHITE + ".")

		// destroy map-placed weapon pickups
		// EntFire("pickup_weapon_awp", "kill") // FIXME
		EntFire("pickup_weapon_bizon", "kill")
		EntFire("pickup_weapon_m4a1_silencer", "kill")
	}

	::ROUND_OVER <- false
	::PREPARING <- true

	local knives = ("knives" in RoundData) ? RoundData.knives : RoundList[0].knives
	local playermodels = ("models" in RoundData) ? RoundData.models : RoundList[0].models

	// reset players
	if (!ScriptIsWarmupPeriod()) {
		local ply = null
		while (ply = Entities.Next(ply)) {
			if (ply.GetClassname() == "player") {
				SetRole(ply, INNOCENT)
				EntFire("speedmod", "ModifySpeed", "1", 0, ply)
				GiveWeapon(ply, "weapon_" + knives[RandomInt(0, knives.len() - 1)])
				GiveWeapon(ply, "item_kevlar")
		
				local mdl = PlayerModel(playermodels[RandomInt(0, playermodels.len() - 1)])
				ply.PrecacheModel(mdl)
				ply.SetModel(mdl)

				ply.SetMaxHealth(9999)
				ply.SetHealth(9999)

				if (ply.ValidateScriptScope())
					ply.GetScriptScope().infected <- false
			}
		}
		MeleeFixup()
		UpdateRoleHints()
	}

	// precache wep list
	local weplist = RoundData.weps
	local world = Entities.First()
	foreach (wep in weplist)
		world.PrecacheModel(ModelPath(wep[1]))

	// weapon spawning
	local wepspawn = null
	while (wepspawn = Entities.FindByName(wepspawn, "ttt_weapon_spawn")) {
		local wepdata = weplist[RandomInt(0, weplist.len() - 1)]
		local wep = CreateProp("prop_dynamic_override", wepspawn.GetOrigin() - Vector(0, 0, 7), ModelPath(wepdata[1]), 0)
		// hack: dualies clip into the ground when flipped
		wep.SetAngles(0, RandomInt(-180, 180), (wepdata[0] == "weapon_elite" || RandomInt(1, 2) == 1) ? 90 : -90)
		wep.__KeyValueFromString("targetname", "pickup_" + wepdata[0])
	}

	// vent init
	local vent = null
	while (vent = Entities.FindByName(vent, "vents_*")) {
		vent.PrecacheSoundScript("MetalVent.ImpactHard")
		if (vent.ValidateScriptScope()) {
			local ss = vent.GetScriptScope()
			ss.InputUse <- function() {
				local role = GetRole(activator)
				if (role == TRAITOR || role == JESTER) {
					local next = Entities.FindByName(self, self.GetName())
					if (next == null)
						next = Entities.FindByName(null, self.GetName())
					activator.SetOrigin(next.GetOrigin() + Vector(0, 0, 20))
					next.EmitSound("MetalVent.ImpactHard")
				}
			}
		}
	}

	// traitor buttons can only used by traitors
	local tbutton = null
	while (tbutton = Entities.FindByName(tbutton, "traitor_button")) {
		if (tbutton.ValidateScriptScope()) {
			local ss = tbutton.GetScriptScope()
			ss.InputUse <- function() {
				return GetRole(activator) == TRAITOR
			}
		}
	}

	KillEvent <- Entities.CreateByClassname("trigger_brush")
	KillEvent.__KeyValueFromString("targetname", "game_playerkill")
	if (KillEvent.ValidateScriptScope()) {
		KillEvent.ConnectOutput("OnUse", "OnKill")
		KillEvent.GetScriptScope().OnKill <- function() {
			if (::LAST_DEATH != null) {
				PlayerKilledPlayer(::LAST_DEATH, activator)
			}
		}
	}

	DeathEvent <- Entities.CreateByClassname("trigger_brush")
	DeathEvent.__KeyValueFromString("targetname", "game_playerdie")
	if (DeathEvent.ValidateScriptScope()) {
		DeathEvent.ConnectOutput("OnUse", "OnDeath")
		DeathEvent.GetScriptScope().OnDeath <- function() {
			::LAST_DEATH <- activator
			PlayerDeath(activator)
		}
	}

	// kittys!
	if (KITTYS) {
		EntFire("kitty_overlay", "startoverlays")
		EntFire("kitty_overlay", "stopoverlays", "", 0.1)
		::KITTYS <- false
	}
}

::ChangeCostume <- function() {
	local costume = Entities.FindByNameNearest("costume", self.GetOrigin(), 6)
	local ply = Entities.FindByNameNearest("player_*", self.GetOrigin(), 100)
	if (costume != null && ply != null) {
		local mdl = costume.GetModelName()
		ply.PrecacheModel(mdl)
		ply.SetModel(mdl)
		costume.EmitSound("Player.EquipArmor_T")
	}
}

::InfectPlayer <- function(ply) {
	if (LivingPlayer(ply) && ply.ValidateScriptScope()) {
		local role = GetRole(ply)
		if (role == DETECTIVE || role == JESTER)
			return
		local ss = ply.GetScriptScope()
		if (!("infected" in ss) || !ss.infected)
			ss.infected <- Time()
	}
}

::SpinSpinner <- function() {
	EntFire("spinner", "start")
	EntFire("spinner_button", "lock")
	local delay = RandomFloat(6, 9)
	EntFire("spinner", "stop", "", delay)
	EntFire("spinner_button", "unlock", "", delay + 2)
}

::SetLightsOn <- function(on) {
	if (on) {
		ForEachPlayerAndBot(function(ply) {
			EntFireHandle(ply, "SetFogController", "fog_default")
		})
	} else {
		ForEachPlayerAndBot(function(ply) {
			EntFireHandle(ply, "SetFogController", "fog_darkness" + (IsRole(ply, TRAITOR) ? "_traitor" : ""))
		})
	}
}

::KillLights <- function() {
	SetLightsOn(false)
	EntFire("power_down", "playsound")
	EntFire("button_restore_lights", "unlock", "", 3)
}

::FixLights <- function() {
	SetLightsOn(true)
	EntFire("power_up", "playsound")
}

::CutOxygen <- function() {
	EntFire("script", "RunScriptCode", "PostCutOxygen()", 3)
}

::PostCutOxygen <- function() {
	Chat(DARK_RED + "WARNING: Oxygen level low!")
	EntFire("o2_alarm", "playsound")
	EntFire("button_restore_o2", "unlock", "", 8.1)
	EntFire("o2_hurt", "enable", "", 8)
	// ::O2_FUCKED <- true
}

::RestoreOxygen <- function() {
	Chat(LIME + "Oxygen level returning to normal...")
	EntFire("o2_alarm", "stopsound")
	EntFire("o2_hurt", "disable")
	// ::O2_FUCKED <- false
}

::StartLockdown <- function() {
	Chat(DARK_RED + "Lockdown initiated!")
	EntFire("lockdown_doors", "close")
	EntFire("lockdown_alarm", "playsound")
	EntFire("lockdown_alarm", "stopsound", "", 15)
	EntFire("lockdown_doors", "open", "", 15)
}

// security cameras

if (!("CAM_PLY" in getroottable()))
	::CAM_PLY <- null

::CurCam <- 0

::UpdateCam <- function() {
	EntFire("sec_cam" + CurCam, "enable", "", 0, CAM_PLY)
	EntFire("camsprite_*", "hidesprite")
	EntFire("camsprite_" + CurCam, "showsprite", "", 0.1)
	CenterPrint(CAM_PLY, "CAM_" + (CurCam < 9 ? "0" : "") + (CurCam + 1) + ": " + CamName[CurCam])
	ClientCMD(CAM_PLY, "playvol weapons/aug/aug_cliphit.wav 0.6")
}

::CamName <- [
	"CAF_LWR",
	"CAF_UPR",
	"WPN",
	"NAV",
	"OXY",
	"COM",
	"STRG",
	"ELEC",
	"MED",
	"ENG_LWR",
	"RCT",
	"ENG_UPR",
]

::CycleCams <- function(amt) {
	::CurCam = (12 + (CurCam + amt)) % 12
	UpdateCam()
}

::StartCams <- function(ply) {
	::CAM_PLY <- ply
	UpdateCam()
}

::StopCams <- function(ply) {
	::CAM_PLY <- null
	EntFire("sec_cam*", "disable", "", 0, ply)
	EntFire("camsprite_*", "hidesprite")
}

::SetDetectivePreference <- function(ply, b) {
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if (!("detpref" in ss))
			ss.detpref <- !b

		if (ss.detpref != b) {
			CenterPrint(ply, "Opted " + (b ? "IN to" : "OUT of") + " detective selection.")
			ss.detpref = b
		}
	}
}

::GetTesterResultColor <- function(ply) {
	switch (ply.GetName()) {
		case "player_detective":
			return "0 0 255"

		case "player_jester":
			return TTT_JESTER_TESTS_AS_TRAITOR ? "255 0 0" : "255 100 255"

		case "player_traitor":
			return "255 0 0"
	}
	return "0 255 0"
}

::TraitorTester <- function() {
	local targets = []
	for (local i = 1; i < 3; i++)
		targets.push(Entities.FindByName(null, "tester_target" + i))

	if (targets[0] == null || targets[1] == null)
		return

	local subjects = []
	for (local i = 0; i < 2; i++) {
		local ply = null
		while (ply = Entities.FindByClassnameWithin(ply, "*", targets[i].GetOrigin(), 16)) {
			if (LivingPlayer(ply))
				subjects.push(ply)
		}
	}

	if (subjects.len() < 2) {
		EntFire("tester_blip", "pitch", "60")
		return
	}

	for (local i = 0; i < 2; i++) {
		EntFire("tester_sprite" + (i + 1), "addoutput", "rendercolor " + GetTesterResultColor(subjects[i]))
		EntFire("tester_sprite" + (i + 1), "addoutput", "rendercolor 255 255 255", 3)
	}

	EntFire("tester_blip", "pitch", "80")
}

::HomeDepot <- function(ply) {
	local knife = null
	while (knife = Entities.FindByClassname(knife, "weapon_knifegg"))
		if (knife.GetOwner() == ply)
			knife.Destroy()
	GiveWeapon(ply, "weapon_hammer")
	MeleeFixup()
}

::LoseRR <- function(ply) {
	if (ply.GetHealth() > 0) {
		ply.SetHealth(1)
		EntFireHandle(ply, "ignitelifetime", "0.1")
	}
}

::RussianRoulette <- function(ply) {
	EntFire("rr_gun", "disable")
	EntFire("rr_snd_spin", "playsound")
	EntFire("rr_gun", "enable", "", 2.4)
	if (RandomInt(1, 6) == 6) {
		EntFire("rr_snd_lose", "playsound", "", 1.5)
		EntFireHandle(ply, "runscriptcode", "LoseRR(self)", 1.5)
	} else {
		EntFire("rr_snd_win", "playsound", "", 1.5)
	}
}

// ttt_clintonbeach - map specific

::BushRustle <- function(ply) {
	if (ply.GetVelocity().Length() > 30) {
		ply.EmitSound("Player.Wade")
	}
}

::RollDie <- function() {
	local die_maker = Entities.FindByName(null, "die_maker")
	if (die_maker == null) {
		return
	}
	die_maker.SpawnEntityAtLocation(die_maker.GetOrigin(), Vector(RandomFloat(-180, 180), RandomFloat(-180, 180), RandomFloat(-180, 180)))
}
