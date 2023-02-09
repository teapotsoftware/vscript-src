
IncludeScript("butil")

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

	AddConfigValue("DETECTIVE_MIN_PLAYERS", 7, "Minimum players for a Detective to be selected.")
	AddConfigValue("DETECTIVE_MODEL", "models/player/custom_player/legacy/ctm_swat_amgsdtct.mdl", "Detective player model.")
	// AddConfigValue("DETECTIVE_GIVE_SHIELD", true, "Whether to give the detective a shield.")

	AddConfigValue("TRAITOR_PCT", 0.3, "[0-1] Fraction of players selected as Traitor.")

	AddConfigValue("JESTER_MIN_PLAYERS", 4, "Minimum players for a Jester to be selected.")
	AddConfigValue("JESTER_EXTREME", true, "Whether the Jester outright wins when killed.")
	AddConfigValue("JESTER_TESTS_AS_TRAITOR", true, "Whether the Jester tests as a Traitor.")

	AddConfigValue("ROUND_TIME", 120, "Length of a round, in seconds.")
	AddConfigValue("PREP_TIME", 10, "Time before role assignment, in seconds.")
	AddConfigValue("HASTE_ENABLED", true, "Whether haste mode is enabled.")
	AddConfigValue("HASTE_KILL_TIME", 20, "Time extension for an innocent death in haste mode.")

	AddConfigValue("DOOR_TIME", 20, "How long doors should stay closed, in seconds.")
	AddConfigValue("CRASH_TIME", 60, "How long should the ship be off course before crashing.")
}

::TTTPlayerModels <- [
	{mdl = "tm_jumpsuit_amgusred", name = "Red", clr = "255 0 0"},
	{mdl = "tm_jumpsuit_amgusblu", name = "Blue", clr = "0 85 255"},
	{mdl = "tm_jumpsuit_amgusgrn", name = "Green", clr = "10 110 30"},
	{mdl = "tm_jumpsuit_amguspnk", name = "Pink", clr = "230 0 255"},
	{mdl = "tm_jumpsuit_amgusylw", name = "Yellow", clr = "255 255 0"},
	{mdl = "tm_jumpsuit_amguswht", name = "White", clr = "255 255 255"},
	{mdl = "tm_jumpsuit_amgusprp", name = "Purple", clr = "135 0 255"},
	{mdl = "tm_jumpsuit_amguscyn", name = "Cyan", clr = "0 225 255"},
	{mdl = "tm_jumpsuit_amguslim", name = "Lime", clr = "60 255 100"},
	{mdl = "tm_jumpsuit_amgusbrn", name = "Brown", clr = "100 60 0"},
	{mdl = "tm_jumpsuit_amgusorg", name = "Orange", clr = "255 150 0"},
	{mdl = "tm_jumpsuit_amgusgry", name = "Gray", clr = "100 100 100"},
	{mdl = "tm_jumpsuit_amgusblk", name = "Black", clr = "10 10 10"},
	{mdl = "tm_jumpsuit_amgusmrn", name = "Maroon", clr = "100 0 30"},
]

::PlayerColors <- {
	["red"] = 0,
	["blue"] = 1,
	["green"] = 2,
	["pink"] = 3,
	["yellow"] = 4,
	["white"] = 5,
	["purple"] = 6,
	["cyan"] = 7,
	["teal"] = 7,
	["lime"] = 8,
	["brown"] = 9,
	["orange"] = 10,
	["gray"] = 11,
	["grey"] = 11, // bri'ish people
	["black"] = 12,
	["maroon"] = 13,
}

// setup votes table on first round
if (!("Votes" in getroottable())) {
	::Votes <- {
		["war"] = 0,
		["eco"] = 0,
		["all"] = 0,
		["pistols"] = 0,
		["western"] = 0
	}
}


AddHook("player_say", "jelqro_player_say", function(d) {
	local n = d.text.len()
	if (n > 6 && d.text.slice(0, 5).tolower() == "color") {
		local clr = d.text.slice(6, n).tolower()
		if (clr in PlayerColors) {
			local clri = PlayerColors[clr]
			local taken = false
			local ply = null
			while (ply = Entities.FindByClassname(ply, "player")) {
				if (ply.ValidateScriptScope()) {
					local ss = ply.GetScriptScope()
					if ("player_color" in ss && ss.player_color == clri) {
						taken = true
						break // TODO: list available colors?
					}
				}
			}
			if (taken) {
				Chat(RED + "That color isn't available.")
/*
				local taken_colors = {}
				ply = null
				// build taken color table, only human players
				while (ply = Entities.FindByClassname(ply, "player")) {
					if (ply.ValidateScriptScope()) {
						local ss = ply.GetScriptScope()
						if ("player_color" in ss) {
							taken_colors[ss.player_color] <- true
						}
					}
				}
				local str = ""
				local n = taken_colors.len()
				for (local i = 0; i < n; i++) {
					str += TTTPlayerModels[taken_colors[i]].name + (i == n - 1 ? "" : ", ")
				}
				Chat(RED + "Available colors: " + str)
*/
			} else if (d.userid_player.ValidateScriptScope()) {
				Chat(GREEN + "Your color will be " + clr + " starting next round.")
				d.userid_player.GetScriptScope().player_color <- clri
			} else {
				Chat(RED + "Something fucked up.")
			}
		} else {
			Chat(RED + "That color isn't available.")
		}
	} else if (n > 5 && d.text.slice(0, 4).tolower() == "vote") {
		local vote = d.text.slice(5, n).tolower()
		if (vote in Votes) {
			if (d.userid_player.ValidateScriptScope()) {
				local ss = d.userid_player.GetScriptScope()
				if ("vote" in ss && ss.vote) {
					Chat(GREEN + "You change your vote from " + ss.vote + " to " + vote + ".")
					Votes[ss.vote]--
					ss.vote = vote
				} else {
					Chat(GREEN + "You vote for " + vote + ".")
				}
				Votes[vote]++
				ss.vote <- vote
			}
		} else {
			Chat(RED + "Valid votes: all, eco, pistol, western, war")
		}
	}
})

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
// ::CorpseInfoMaker <- EntityGroup[4] // TODO

::INVALID_ROLE <- -1
::INNOCENT <- 0
::TRAITOR <- 1
::DETECTIVE <- 2
::JESTER <- 3

::ROLE_NAME <- ["innocent", "traitor", "detective", "jester"]

::IsRole <- function(ply, role) {return GetRole(ply) == role}
::SetRole <- function(ply, role) {ply.__KeyValueFromString("targetname", "player_" + ROLE_NAME[role])}

::GetRole <- function(ply) {
	if (ply == null) {
		return INVALID_ROLE
	}
	switch (ply.GetName()) {
		case "player_innocent":
			return INNOCENT

		case "player_traitor":
			return TRAITOR

		case "player_detective":
			return DETECTIVE

		case "player_jester":
			return JESTER

		default:
			return INVALID_ROLE
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
	if (!cam.ValidateScriptScope()) {
		return
	}
	local ang = cam.GetAngles()
	local ss = cam.GetScriptScope()
	if (!("start_yaw" in ss)) {
		ss.start_yaw <- ang.y
	}
	cam.SetAngles(ang.x, ss.start_yaw + (sin((Time() + cam.entindex()) * 0.4) * 15), ang.z)
}

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
						// DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), Vector(0, 0, 0))
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
	local radar_players = []
	while (ent = Entities.Next(ent)) {
		local name = ent.GetName()
		local cls = ent.GetClassname()
/*
		if (cls == "predicted_viewmodel") {
			// CenterPrint(ent.GetMoveParent(), "" + ent.GetModelName())
			ent.__KeyValueFromString("rendercolor", "255 0 0")
			ent.SetBodygroup(0, 1)
			ent.SetBodygroup(1, 1)
			continue
		}
*/
		// player tick
		if (cls == "player") {
			UserIDThink(ent)

			// living players only past here
			if (!Alive(ent)) {
				continue
			}

			// add to radar list
			radar_players.push([GetRole(ent), ent.GetOrigin()])
			
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

			if (ent.ValidateScriptScope()) {
				local ss = ent.GetScriptScope()

				// kill invalid fresh-spawns
				if (GetRole(ent) == INVALID_ROLE) {
					SetRole(ent, INNOCENT)
					ent.SetHealth(1)
					EntFireHandle(ent, "IgniteLifetime", "10")
					CenterPrint(ent, "Sorry! You spawned too late for this round.")
				}

				// spread covid
				if ("infected" in ss && ss.infected) {
					// show symptoms
					if (Time() - ss.infected > 20) {
						if ("next_covid" in ss) {
							if (Time() > ss.next_covid) {
								// lower health
								local new_health = ent.GetHealth() - RandomInt(2, 5)
								if (new_health > 0) {
									ent.SetHealth(new_health)
								} else {
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
		} else if (cls == "tagrenade_projectile") {
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
/*
		} else if (cls == "decoy_projectile") {
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
		} else if (cls.len() > 7 && cls.slice(0, 7) == "weapon_" && ent.ValidateScriptScope()) {
			local ss = ent.GetScriptScope()
			local ply = ent.GetOwner()

			if (ply == null)
				continue

			// show detectives dna
			if (GetActiveWeaponClass(ply) == cls && "dna" in ss && ss.dna[0] != null && ss.dna[0] != ply && ply.ValidateScriptScope() && ply.GetName() == "player_detective") {
				local pss = ply.GetScriptScope()
				if ("last_dna_scan" in pss && Time() - pss.last_dna_scan < 2)
					continue

				if (Time() - ss.dna[1] > 45) {
					if (Time() - ss.dna[1] < 50) {
						CenterPrint(ply, "The DNA sample on this weapon has expired.")
						ss.dna <- [ply, Time()]
					}
				} else {
					if (LivingPlayer(ss.dna[0])) {
						local dist_ft = ceil((ss.dna[0].GetOrigin() - ply.GetOrigin()).Length() / 12)
						CenterPrint(ply, "There is a DNA sample on this weapon.\nSource: " + (GetRole(ss.dna[0]) == TRAITOR ? "Unknown extraterrestrial lifeform" : "Human male") + "\nDistance to source: " + dist_ft + "ft")
					} else {
						CenterPrint(ply, "There is a DNA sample on this weapon.\nSource: Deceased\nDistance to source: Unknown")
					}
				}
				pss.last_dna_scan <- Time()
			} else {
				// transfer dna
				if (RandomInt(1, 4) == 1) {
					ss.dna <- [ply, Time()]
				}
			}
*/
		} else if (cls == "breachcharge_projectile") {
			// add to radar list
			radar_players.push([4, ent.GetOrigin()])
		} else if (name.len() > 12 && name.slice(0, 12) == "radarmarker_") {
			ent.SetOrigin(RADAR_MARKER_STORAGE)
		}
	}

	foreach (ent in deleted)
		ent.Destroy()

	// dumb ass hud stuff
	::hud_timer++
	if (::hud_timer > 4) {
		::hud_timer <- 0
		UpdateRoleHints()
	}
	if (PREPARING && !ScriptIsWarmupPeriod()) {
		::role_timer++
		if (role_timer == (TTT_PREP_TIME * 10) - 11) {
			EntFire("tp_sound_up", "PlaySound")
		}
		if (::role_timer > (TTT_PREP_TIME * 10) - 1 && GetPlayerCount() > 1) {
			AssignRoles()
		}
	}

	// update traitor room radar -_-
	local radar_count_i = 0
	local radar_count_t = 0
	local radar_count_b = 0
	foreach (blip in radar_players) {
		local blip_name
		if (blip[0] == 4) {
			blip_name = "radarmarker_b" + radar_count_b
			radar_count_b++
		} else if (blip[0] == DETECTIVE && !WAR) {
			blip_name = "radarmarker_d"
		} else if (blip[0] == TRAITOR || blip[0] == JESTER) {
			blip_name = "radarmarker_t" + radar_count_t
			radar_count_t++
		} else {
			blip_name = "radarmarker_i" + radar_count_i
			radar_count_i++
		}
		local blip_ent = Entities.FindByName(null, blip_name)
		if (blip_ent != null) {
			local pos = Vector(
				RADAR_MINS.x + (RADAR_MAXS.x - RADAR_MINS.x) * ((blip[1].x - MAP_MINS.x) / (MAP_MAXS.x - MAP_MINS.x)),
				RADAR_MINS.y + (RADAR_MAXS.y - RADAR_MINS.y) * ((blip[1].y - MAP_MINS.y) / (MAP_MAXS.y - MAP_MINS.y)),
				RADAR_MINS.z)
			blip_ent.SetOrigin(pos)
		}
	}

	if (!PREPARING && !ROUND_OVER && Time() > ROUND_END_TIME) {
		if (O2_CUT || NAV_FUCKED) {
			if (!OVERTIME_SABOTAGE_ANNOUNCED) {
				::OVERTIME_SABOTAGE_ANNOUNCED = true
				Chat(DARK_RED + "OVERTIME: Innocents will win when the ship is repaired.")
			}
		} else {
			RoundWin(INNOCENT)
		}
	}
}

::GetPlayerCount <- function(role = -2) {
	local count = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*")) {
		if (ply.GetClassname() == "player" && (role == -2 || IsRole(ply, role))) {
			count++
		}
	}
	return count
}

::GetLivingPlayerCount <- function(role = -2) {
	local count = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "*")) {
		if (LivingPlayer(ply) && (role == -2 || IsRole(ply, role))) {
			count++
		}
	}
	return count
}

::PREPARING <- true
::ROUND_OVER <- false
::ShowHintToPlayer <- function(ply, name) {EntFire("hud_" + name, "display", "", 0, ply)}

::RoleHintMe <- function(ply, target = -2) {
	if (PREPARING) {
		ShowHintToPlayer(ply, "preparing")
		return
	}
	if (ROUND_OVER) {
		ShowHintToPlayer(ply, "roundover")
		return
	}
	if (ply.GetHealth() < 1 && target == -2) {
		local spec = Entities.FindByClassnameWithin(ply, "player", ply.GetOrigin(), 15)
		if (LivingPlayer(spec)) {
			RoleHintMe(ply, spec)
			return
		}
		ShowHintToPlayer(ply, "dead")
		return
	}

	if (target == -2)
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
	if (CAM_PLY == ply) {
		CenterPrint(ply, "If you're stuck in the camera, just wait for next round. Sorry!")
		StopCams(ply)
	}
	local role = GetRole(ply)
	if (role == JESTER) {
		JestMaker.SpawnEntityAtLocation(ply.GetOrigin(), Vector(0, 0, 0))
		DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), Vector(0, 0, 0))
		JesterDeathSound.SetOrigin(ply.GetOrigin())
		EntFireHandle(JesterDeathSound, "playsound")
	} else if (role == TRAITOR) {
		TraitorMaker.SpawnEntityAtLocation(ply.GetOrigin(), Vector(0, 0, 0))
	} else if (role != INVALID_ROLE) {
		::ROUND_END_TIME += TTT_HASTE_KILL_TIME
	}
	if (!PREPARING && !ROUND_OVER) {
		if ((GetLivingPlayerCount(INNOCENT) + GetLivingPlayerCount(DETECTIVE)) < 1) {
			RoundWin(TRAITOR)
		} else if (GetLivingPlayerCount(TRAITOR) < 1) {
			RoundWin(INNOCENT)
		}
	}
	UpdateRoleHints()
}

// karma

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

// new karma handling :)
AddHook("player_hurt", "jelqro_player_hurt", function(d) {
	if (PREPARING || ROUND_OVER) {
		return
	}
	local atk = d.attacker_player
	local vtm = d.userid_player
	if (atk == null || vtm == null || atk == vtm) {
		return
	}
	local arole = GetRole(atk)
	local vrole = GetRole(vtm)
	if (vrole == arole || (vrole == DETECTIVE && arole == INNOCENT) || (vrole == INNOCENT && arole == DETECTIVE)) {
		// scale karma penalty by victims karma
		local penalty = Max(d.dmg_health, 100) * GetKarma(vtm) * 0.001
		if (arole == TRAITOR || vrole == DETECTIVE) {
			penalty *= 2
			if (vrole == DETECTIVE) {
				CenterPrint(atk, "Don't shoot the detective!")
			} else {
				if (vtm.ValidateScriptScope()) {
					local ss = vtm.GetScriptScope()
					if ("player_color" in ss) {
						CenterPrint(atk, TTTPlayerModels[ss.player_color].name + " is a fellow traitor!")
					}
				}
			}
		}
		AddKarma(atk, -penalty)
	}
})

::RoundWin <- function(role) {
	EntFire("round_ender", "EndRound_" + (role == INNOCENT ? "" : "Counter") + "TerroristsWin", "7")
	::ROUND_OVER <- true

	local name = ROLE_NAME[role]
	EntFire("win_overlay_" + name, "startoverlays")
	EntFire("win_overlay_" + name, "stopoverlays", "", 6)

	local chats = [
		LIME + "INNOCENTS WIN!",
		RED + "TRAITORS WIN!",
		"",
		MAGENTA + "JESTER WINS!"
	]
	Chat(chats[role])

	// cute after-round hints
	if (true || RandomInt(1, 100) % 2 == 0) {
		local hints = [
			// misc
			"Your chances of losing Russian Roulette are 1 in 6.",
			"There is a two-person traitor tester in the admin room.",
			"The innocents will win when time runs out, unless there is active sabotage.",
			"If you get hurt, you can heal in the medbay.",
			"We have no idea where this ship is headed.",
			"You will not suffocate in the simulation room.",
			"Some walls in the storage room are in need of maintenance.",
			"It's just a game.",
			"Your max health depends on your karma.",
			// traitors
			"Traitors can press E on a health station to make it explode in 20 seconds.",
			"The AWP in the weapon room can be unlocked by a button in the traitor room.",
			"Traitors can open or close doors at any time, even during a lockdown.",
			"When the lights are out, traitors can see slightly farther than everyone else.",
			"Often times, as traitor, you can get the innocents to do your work for you.",
			"Red-colored vents lead to and from the traitor room.",
			"The windows in the traitor room are thick, and will block low-damage weapons.",
			"There is a radar in the traitor room that can be used to locate hiding players.",
			"The map overview shows where vents go in red dotted lines.",
			"Traitors can rig the tester to show both subjects as innocent for a single test.",
			// jester
			"The jester is immune to infectious disease.",
			"The jester can use vents, and will show up as a traitor on radar and when tested.",
			"The jester can win by dying to explosive barrels.",
			"The round will not end if the jester is killed by a traitor.",
			"There will never be more than one jester in a round.",
			// detective
			"There is no way to opt out of being Detective. Consider it your duty.",
		]
		Chat(GRAY + "TIP: " + hints[RandomInt(0, 9999) % hints.len()])
	}
}

::PlayerKilledPlayer <- function(victim, killer) {
	if (PREPARING || ROUND_OVER || victim == killer)
		return

	local vrole = GetRole(victim)
	local krole = GetRole(killer)

	if (vrole == krole || (vrole == DETECTIVE && krole == INNOCENT) || (vrole == INNOCENT && krole == DETECTIVE)) {
/*
		// karma is handled in player_hurt now
		local penalty = GetKarma(victim) / 10
		if (krole == TRAITOR || vrole == DETECTIVE) {
			CenterPrint(killer, "2x Karma penalty for killing " + (vrole == DETECTIVE ? "the detective" : "a fellow traitor") + ".") //F" + (RandomInt(1, 8) == 1 ? "ri" : "u") + "ck you.")
			AddKarma(killer, penalty * -2)
		} else
			AddKarma(killer, penalty * -1)
*/
		// no karma reward next round
		if (killer.ValidateScriptScope())
			killer.GetScriptScope().has_rdmed <- true
	}
	if (vrole == JESTER && krole != TRAITOR) {
		if (TTT_JESTER_EXTREME) {
			RoundWin(JESTER)
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

	if (ply.ValidateScriptScope()) {
		ply.GetScriptScope().round_playermodel <- TTT_DETECTIVE_MODEL
	}

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
	// printl(ply + " hull max: " + ply.GetBoundingMaxs().z)
	local tp = Entities.FindByName(null, "tpexit_innocent_" + ply.entindex())
	for (local i = 0; i < TRAITORS.len(); i++) {
		if (ply == TRAITORS[i])
			tp = Entities.FindByName(null, "tpexit_traitor_" + (i + 1))
	}
	if (tp == null) {
		printl("NULL POCKET DIMENSION EXIT - NOT GOOD!!! (" + ply + ")")
		return
	}
	if (ply.GetBoundingMaxs().z > 60 && ply.GetOrigin().x < 1400) {
		tp.SetOrigin(tp.GetOrigin() + Vector(0, 0, 70))
		// printl("standing! " + ply.GetOrigin().x)
	}
	SwapPlaces(ply, tp)
}

::AssignRoles <- function() {
	::PREPARING <- false
	local plylist = []
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingPlayer(ply)) {
			plylist.push(ply)

/*
			// assign color
			local plymdl = TTTPlayerModels[(ply.entindex() - 1) % TTTPlayerModels.len()]
			SetModelSafe(ply, PlayerModel(plymdl.mdl))
			EntFire("hud_color", "SetTextColor", plymdl.clr)
			EntFire("hud_color", "SetTextColor2", plymdl.clr)
			EntFire("hud_color", "SetText", "YOUR COLOR: " + plymdl.name)
			EntFire("hud_color", "Display", "", 0, ply)
*/

			// show karma
			local karma = GetKarma(ply)
			local remark = ""
			if (karma <= 600)
				remark = " Behave yourself!"
			else if (karma >= 1000)
				remark = " Good job!"
			CenterPrint(ply, "Your Karma for this round is " + karma + "." + remark)

			// starting health is based on karma
			SetHealthAndMaxHealth(ply, Min(karma / 10, 100))

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
	if (WAR) {
		local plylist_shuf = ShuffleArray(plylist)
		local traitor_amt = floor(count / 2)
		if (count % 2 == 1) {
			traitor_amt += (RandomInt(1, 9999) % 2)
		}
		local spawn_index = [0, 0]
		foreach (ply in plylist_shuf) {
			if (traitor_amt > 0) {
				SetRole(ply, TRAITOR)
				TRAITORS.push(ply)
			} else {
				MakeDetective(ply)
			}
			local i = traitor_amt > 0 ? 0 : 1
			local sp = Ent("warspawn_" + ["t", "d"][i] + spawn_index[i])
			ply.SetOrigin(sp.GetOrigin())
			local a = sp.GetAngles()
			ply.SetAngles(a.x, a.y, a.z)
			spawn_index[i]++
			traitor_amt-- // bruh
		}
		Chat(RED + "WAR ROUND!")
		Chat(RED + "If you aren't a detective, you're a traitor.")
	} else {
		local traitor_amt = Clamp(floor(count * TTT_TRAITOR_PCT), 1, count - 1)
		do {
			local index = RandomInt(1, 9999) % plylist.len()
			SetRole(plylist[index], TRAITOR)
			TRAITORS.push(plylist[index])
			plylist.remove(index)
			traitor_amt--
		} while (traitor_amt > 0)
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
				local det = det_candidates[RandomInt(1, 9999) % det_candidates.len()]
				MakeDetective(det)
				for (local i = 0; i < plylist.len(); i++) {
					if (plylist[i] == det) {
						plylist.remove(i)
					}
				}
			}
		}
		if (count >= TTT_JESTER_MIN_PLAYERS && RandomInt(1, 666) % 3 == 0) {
			local index = RandomInt(1, 9999) % plylist.len()
			SetRole(plylist[index], JESTER)
			EntFire("speedmod", "ModifySpeed", "1.05", 0, plylist[index])
			// jester always 100 hp
			SetHealthAndMaxHealth(plylist[index], 100)
			foreach (traitor in TRAITORS) {
				ShowHintToPlayer(traitor, "jester_active")
				ShowHintToPlayer(traitor, "jester_active") // what?
			}
			plylist.remove(index)
		}
	}
	UpdateRoleHints()
	SendToConsoleServer("mp_respawn_on_death_t 0")

	// get to know your fellow traitor
	// EntFire("tp_sound_up", "PlaySound")
	local ts = TRAITORS.len()
	if (ts > 1 && !WAR) {
		local delay = 2 * (ts + 1)
		Chat(DARK_RED + "Traitors, meet your allies.")
		SendAllToPocketDimension()
		EntFire("tp_sound_down", "PlaySound", "", delay - 2.3)
		EntFire("script", "RunScriptCode", "SendAllToPocketDimension()", delay)
		EntFire("script", "RunScriptCode", "StartClock()", delay)
	} else {
		StartClock()
	}

	// replace dummy barrels with actual exploding ones
	EntFire("non_exploding_barrels", "Kill")
	EntFire("barrels_template", "ForceSpawn")
}

::StartClock <- function() {
	::ROUND_END_TIME <- Time() + TTT_ROUND_TIME
	EntFire("script", "RunScriptCode", "OvertimeCheck()", TTT_ROUND_TIME + 0.5)
}

::OvertimeCheck <- function() {
	if (Time() < ROUND_END_TIME) {
		Chat(DARK_RED + "OVERTIME: Traitors have " + TTT_HASTE_KILL_TIME + " extra seconds per dead innocent.")
	}
}

::WepTypes <- {
	weapon_galilar = 1,
	weapon_aug = 1,
	weapon_sg556 = 1,
	weapon_ak47 = 1,
	weapon_famas = 1,
	weapon_m4a1 = 1,
	weapon_m4a1_silencer = 1,
	weapon_mac10 = 1,
	weapon_mp9 = 1,
	weapon_ump45 = 1,
	weapon_bizon = 1,
	weapon_mp7 = 1,
	weapon_mp5sd = 1,
	weapon_p90 = 1,
	weapon_ssg08 = 1,
	weapon_awp = 1,
	weapon_scar20 = 1,
	weapon_g3sg1 = 1,
	weapon_negev = 1,
	weapon_m249 = 1,
	weapon_sawedoff = 1,
	weapon_mag7 = 1,
	weapon_nova = 1,
	weapon_xm1014 = 1,
	weapon_deagle = 2,
	weapon_p250 = 2,
	weapon_cz75a = 2,
	weapon_elite = 2,
	weapon_glock = 2,
	weapon_revolver = 2,
	weapon_usp_silencer = 2,
	weapon_hkp2000 = 2,
	weapon_tec9 = 2,
	weapon_fiveseven = 2,
	weapon_flashbang = -1,
	weapon_smokegrenade = -1,
	weapon_hegrenade = -1,
	weapon_decoy = -1,
	weapon_incgrenade = -1,
	weapon_molotov = -1,
	weapon_taser = -1,
	weapon_bumpmine = 5,
	weapon_breachcharge = 5,
}

::CURRENT_ROUND <- 0

::DroppedWeaponModels <- {
	["ak47"] = "rif_ak47",
	["m4a1"] = "rif_m4a1",
	["xm1014"] = "shot_xm1014",
	["mac10"] = "smg_mac10",
	["mp7"] = "smg_mp7",
	["ump45"] = "smg_ump45",
	["ssg08"] = "snip_ssg08",
	["m249"] = "mach_m249",
	["negev"] = "mach_negev",
	["deagle"] = "pist_deagle",
	["revolver"] = "pist_revolver",
	["cz75a"] = "pist_cz_75",
	["p250"] = "pist_p250",
	["elite"] = "pist_elite",
	["tec9"] = "pist_tec9",
	["fiveseven"] = "pist_fiveseven",
	["glock"] = "pist_glock18",
	["smokegrenade"] = "eq_smokegrenade",
	["flashbang"] = "eq_flashbang",
	["incgrenade"] = "eq_incendiarygrenade",
	["hegrenade"] = "eq_fraggrenade",
	["molotov"] = "eq_molotov",
	["famas"] = "rif_famas",
	["aug"] = "rif_aug",
	["galilar"] = "rif_galilar",
	["sg556"] = "rif_sg556",
	["nova"] = "shot_nova",
	["mp9"] = "smg_mp9",
	["bizon"] = "smg_bizon",
	["p90"] = "smg_p90",
	["sawedoff"] = "shot_sawedoff",
	["mag7"] = "shot_mag7",
	["taser"] = "eq_taser",
}

::GetDroppedWeaponModel <- function(token) {
	if (token == "taser") {
		return ModelPath("weapons/w_" + DroppedWeaponModels[token])
	}
	return ModelPath("weapons/w_" + DroppedWeaponModels[token] + "_dropped")
}

::RoundList <- [{
		name = "Default",
		weps = [
			"ak47", "ak47", "m4a1",
			"xm1014", "xm1014",
			"mac10", "mac10", "mp7", "ump45",
			"ssg08", "ssg08",
			"m249",
			"deagle", "deagle", "cz75a", "elite", "glock", "glock",
			"smokegrenade", "flashbang", "incgrenade"
		]
	}, {
		name = "All But AWP/Auto",
		weps = [
			"ssg08",
			"famas", "galilar", "m4a1", "ak47", "aug", "sg556",
			"mac10", "mp9", "mp7", "ump45", "bizon", "p90",
			"nova", "sawedoff", "mag7", "xm1014",
			"negev", "m249",
			"revolver", "deagle", "glock", "p250", "elite", "tec9", "fiveseven",
			"smokegrenade", "incgrenade", "hegrenade", "flashbang",
			"taser"
		]
	}, /*{
		name = "Classic TTT",
		weps = [
			"m4a1", "ssg08", "xm1014", "mac10", "m249",
			"fiveseven", "deagle", "glock",
			"smokegrenade", "flashbang", "incgrenade"
		]
	},*/ {
		name = "Eco Round",
		weps = [
			"ssg08",
			"mac10", "mp9", "mp7", "ump45", "bizon",
			"nova", "sawedoff", "mag7",
			"tec9", "revolver", "fiveseven", "deagle", "p250", "cz75a", "elite", "glock",
			"smokegrenade", "flashbang", "incgrenade"
		]
	}, {
		name = "Pistols Only",
		weps = [
			"tec9", "revolver", "fiveseven", "deagle", "p250", "cz75a", "elite", "glock",
			"smokegrenade", "flashbang", "incgrenade"
		]
	}, {
		name = "High Noon",
		weps = [
			"ssg08", "nova", "sawedoff",
			"revolver", "deagle",
			"molotov"
		]
	}
]

::GiveKnife <- function(ply, name) {
	local weps = GetWeapons(ply)
	foreach (wep in weps) {
		local cls = wep.GetClassname()
		if (cls == "weapon_knife" || cls == "weapon_knifegg") {
			wep.Destroy()
		}
	}
	if (name == "bayonet" || name == "knifegg") {
		GiveWeapon(ply, "weapon_" + name)
	} else {
		GiveWeapon(ply, "weapon_knife_" + name)
	}
	MeleeFixup()
}

::SetKnife <- function(ply, name) {
	if (ply.ValidateScriptScope()) {
		ply.GetScriptScope().knife <- name
	}

	GiveKnife(ply, name)
}

OnPostSpawn <- function() {
	// reset gerlobals
	::WAR <- false
	::ROUND_END_TIME <- 9999999
	::hs_timer <- 0
	::hud_timer <- 0
	::role_timer <- 0

	if (ScriptIsWarmupPeriod()) {
		Chat(GRAY + "Waiting for warmup to end...")
	} else {
		Chat("Welcome to " + DARK_RED + "TTT" + WHITE +"! Your role is in the top left of your screen.")
		Chat("The " + GREEN + "INNOCENTS" + WHITE + " must stick together, survive, and kill the traitor(s).")
		Chat("The " + RED + "TRAITORS" + WHITE + " have access to special traps, and must kill all the others.")
		Chat("The " + BLUE + "DETECTIVE" + WHITE + " is proven innocent, and must help the innocents win.")
		Chat("The " + MAGENTA + "JESTER" + WHITE + " cannot shoot, but must convince the innocents of his guilt.")
		Chat("Only the " + RED + "TRAITORS" + WHITE + " and " + MAGENTA + "JESTER" + WHITE + " can go through vents.")
		Chat("Type " + GREEN + "\"color <color name>\"" + WHITE + " to manually pick a color!")
	}

	SendToConsoleServer("mp_humanteam t")
	SendToConsoleServer("bot_join_team t")
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_roundtime " + ((TTT_ROUND_TIME + TTT_PREP_TIME) / 60.0))
	SendToConsoleServer("mp_freezetime 0")
	SendToConsoleServer("mp_forcecamera 0")
	SendToConsoleServer("mp_limitteams 30")
	SendToConsoleServer("mp_solid_teammates 1")
	SendToConsoleServer("mp_autoteambalance 0")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_teammates_are_enemies 1")
	SendToConsoleServer("mp_ignore_round_win_conditions 1")
	SendToConsoleServer("mp_timelimit 999999")
	SendToConsoleServer("mp_maxrounds 999999")
	SendToConsoleServer("mp_molotovusedelay 0")

	// doesnt work :(
	// EntFire("broadcaster", "Command", "cl_drawhud_force_deathnotices -1")
	
	::CURRENT_ROUND <- 0

	// check for voted weapon pool
	local majority = ceil(GetPlayerCount() / 2)
	local rounds = ["all", "eco", "pistols", "western"]
	for (local i = 0; i < rounds.len(); i++) {
		if (Votes[rounds[i]] >= majority) {
			CURRENT_ROUND = i + 1
		}
	}
	WAR = Votes["war"] >= majority

	// randomly pick one if we didn't agree on one
	if (CURRENT_ROUND == 0 && RandomInt(1, 99999) % 4 == 0)
		::CURRENT_ROUND <- RandomInt(1, RoundList.len() - 1)

	local RoundData = RoundList[CURRENT_ROUND]
	if (CURRENT_ROUND) {
		Chat("Weapon pool for this round: " + MINT + RoundData.name + WHITE + ".")
	}

	// destroy map-placed weapon pickups
	if (CURRENT_ROUND != 2) {EntFire("pickup_weapon_mp5sd", "Kill")}
	if (CURRENT_ROUND == 2 || CURRENT_ROUND == 3) {EntFire("pickup_weapon_m4a1_silencer", "Kill")}

	::ROUND_OVER <- false
	::PREPARING <- true

	// local knives = ("knives" in RoundData) ? RoundData.knives : RoundList[0].knives
	// local playermodels = ("models" in RoundData) ? RoundData.models : RoundList[0].models

	local knives = ["bayonet", "knife_m9_bayonet", "knife_karambit", "knife_butterfly"]
	// reset players
	if (!ScriptIsWarmupPeriod()) {
		local taken_colors = {}
		local ply = null
		// build taken color table, only human players
		while (ply = Entities.FindByClassname(ply, "player")) {
			if (ply.ValidateScriptScope()) {
				local ss = ply.GetScriptScope()
				if ("player_color" in ss) {
					taken_colors[ss.player_color] <- true
				}
			}
		}
		// this one runs for bots too
		local fallbackcolorindex = 0
		while (ply = Entities.Next(ply)) {
			if (ply.GetClassname() == "player") {
				// debug
				if (ply.ValidateScriptScope()) {
					local ss = ply.GetScriptScope()
					if ("userid" in ss) {
						printl(ply + " userid = " + ss.userid)
					} else {
						printl(ply + " has no userid!")
					}
				}

				// reset player
				SetRole(ply, INNOCENT)
				EntFire("speedmod", "ModifySpeed", "1", 0, ply)
				GiveWeapon(ply, "weapon_" + knives[RandomInt(0, knives.len() - 1)])
				GiveWeapon(ply, "item_kevlar")

				// find our initial desired player color
				local usesPickedColor = false
				local mdlindex = fallbackcolorindex
				if (ply.ValidateScriptScope()) {
					local ss = ply.GetScriptScope()
					if ("player_color" in ss) {
						mdlindex = ss.player_color
						usesPickedColor = true
					}

					// clear votes
					if ("vote" in ss) {
						delete ss.vote
					}

					// oh uh yeah also cure them of covid
					ss.infected <- false
				}

				// if we didn't pick our color, find the first color that isn't taken
				if (!usesPickedColor) {
					local i = 0
					while (mdlindex in taken_colors && i < 14) {
						mdlindex = (mdlindex + 1) % TTTPlayerModels.len()
						i++
					}
					taken_colors[mdlindex] <- true
					fallbackcolorindex = (mdlindex + 1) % TTTPlayerModels.len()
				}

				local plymdl = TTTPlayerModels[mdlindex]
				SetModelSafe(ply, PlayerModel(plymdl.mdl))

				if (ply.ValidateScriptScope()) {
					ply.GetScriptScope().round_playermodel <- plymdl.mdl
				}

				// show them their true colors -_-
				local clrh = Entities.CreateByClassname("game_text")
				clrh.__KeyValueFromString("targetname", "hud_color_" + ply.entindex())
				clrh.__KeyValueFromInt("holdtime", 2)
				clrh.__KeyValueFromInt("effect", 0)
				clrh.__KeyValueFromInt("channel", 3)
				clrh.__KeyValueFromInt("x", -1)
				clrh.__KeyValueFromFloat("y", 0.4)
				clrh.__KeyValueFromFloat("fadein", 0.4)
				clrh.__KeyValueFromFloat("fadeout", 0.4)
				EntFireHandle(clrh, "SetText", "YOUR COLOR: " + plymdl.name.toupper())
				EntFireHandle(clrh, "SetTextColor", plymdl.clr)
				EntFireHandle(clrh, "SetTextColor2", plymdl.clr)
				EntFireHandle(clrh, "Display", "", 0, ply)
				EntFireHandle(clrh, "Kill", "", 5)

				ply.SetMaxHealth(9999)
				ply.SetHealth(9999)
			}
		}
		MeleeFixup()
		UpdateRoleHints()
	}

	// precache wep list
	local weplist = RoundData.weps
	local world = Entities.First()
	foreach (wep in weplist)
		world.PrecacheModel(GetDroppedWeaponModel(wep))

	local ent = null
	while (ent = Entities.Next(ent)) {
		local name = ent.GetName()
		if (name.len() > 6 && name.slice(0, 6) == "vents_") {
			ent.PrecacheSoundScript("MetalVent.ImpactHard")
			if (ent.ValidateScriptScope()) {
				ent.GetScriptScope().InputUse <- function() {
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
		} else {
			switch (name) {
				case "ttt_weapon_spawn":
					local wepname = weplist[RandomInt(0, weplist.len() - 1)]
					local wep = CreateProp("prop_dynamic_override", ent.GetOrigin() - Vector(0, 0, 7), GetDroppedWeaponModel(wepname), 0)
					// hack: dualies clip into the ground when flipped
					wep.SetAngles(0, RandomInt(-180, 180), (wepname == "elite" || RandomInt(1, 2) == 1) ? 90 : -90)
					wep.__KeyValueFromString("targetname", "pickup_weapon_" + wepname)
					break

				case "traitor_button":
					if (ent.ValidateScriptScope()) {
						local ss = ent.GetScriptScope()
						ss.AlreadyUsed <- false
						ss.InputUse <- function() {
							if (GetRole(activator) == TRAITOR) {
								AlreadyUsed = true
								return true
							}
							return AlreadyUsed
						}
					}
					break
			}
		}
	}

	HookToPlayerKill(function(ply) {
		if (::LAST_DEATH != null) {
			PlayerKilledPlayer(::LAST_DEATH, ply)
		}
	})

	HookToPlayerDeath(function(ply) {
		::LAST_DEATH <- ply
		PlayerDeath(ply)
	})

	// reset votes
	::Votes <- {
		["war"] = 0,
		["eco"] = 0,
		["all"] = 0,
		["pistols"] = 0,
		["western"] = 0
	}
}

// sus function
::DisruptComms <- function(b) {
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingPlayer(ply)) {
			if (b) {
				ply.SetModel("models/player/custom_player/legacy/tm_jumpsuit_amgusrbw.mdl")
			} else {
				ply.SetModel(PlayerModel(ply.GetScriptScope().round_playermodel))
			}
		}
	}

	if (b) {
		Chat(DARK_RED + "Comms disrupted!")
	} else {
		Chat(MINT + "Comms fixed!")
		EntFire("comms_lever", "SetAnimation", "closeopen", 1)
		EntFire("comms_lever", "SetAnimation", "idle_closed", 1.5)
	}
}

::AlterCourse <- function() {
	::NAV_FUCKED = true
	EntFire("script", "RunScriptCode", "PostAlterCourse()", 10)
}

::PostAlterCourse <- function() {
	if (!NAV_FUCKED) {
		return
	}
	::NAV_FUCKED_ANNOUNCED = true
	Chat(DARK_RED + "The ship will crash in " + TTT_CRASH_TIME + " seconds if the course is not corrected!")
	EntFire("nav_alarm", "PlaySound")
	EntFire("script", "RunScriptCode", "StartCrashShip()", TTT_CRASH_TIME)
}

::FixCourse <- function() {
	::NAV_FUCKED = false
	if (NAV_FUCKED_ANNOUNCED) {
		EntFire("nav_alarm", "StopSound")
		Chat(MINT + "The ship's course has been corrected.")
		::NAV_FUCKED_ANNOUNCED = false
	}
}

::StartCrashShip <- function() {
	if (!NAV_FUCKED) {
		return
	}
	EntFire("nav_alarm", "FadeOut", "1")
	EntFire("crash_fires", "StartFire")
	EntFire("nav_fade", "Fade")
	EntFire("nav_crash", "PlaySound")
	EntFire("script", "RunScriptCode", "ShipCrashed()", 1.5)
}

::ShipCrashed <- function() {
	RoundWin(TRAITOR)
	local dest = Entities.FindByName(null, "crash_site").GetOrigin()
	local offset = 0
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingPlayer(ply)) {
			if (IsRole(ply, JESTER) || IsRole(ply, TRAITOR)) {
				ply.SetOrigin(dest + Vector(35 * offset, 0, 0))
				offset++
			} else {
				ply.SetOrigin(dest)
				ply.SetHealth(1)
				EntFireHandle(ply, "IgniteLifetime", "0.1")
			}
		}
	}
}

::InfectPlayer <- function(ply) {
	if (LivingPlayer(ply) && ply.ValidateScriptScope()) {
		if (IsRole(ply, JESTER))
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
	EntFire("electrical_lever", "SetAnimation", "closeopen", 1)
	EntFire("electrical_lever", "SetAnimation", "idle_closed", 1.5)
}

::CutOxygen <- function() {
	EntFire("script", "RunScriptCode", "PostCutOxygen()", 5)
	EntFire("o2_valve", "EnableMotion")
	EntFire("o2_motor", "TurnOn")
	EntFire("o2_motor", "SetSpeed", "100")
	EntFire("o2_motor", "TurnOff", "", 3)
	EntFire("o2_valve", "DisableMotion", "", 3)
}

::PostCutOxygen <- function() {
	::O2_CUT = true
	Chat(DARK_RED + "WARNING: Oxygen level low!")
	EntFire("o2_alarm", "PlaySound")
	// EntFire("button_restore_o2", "Unlock", "", 0.1)
	EntFire("script", "RunScriptCode", "PostPostCutOxygen()", 8)
}

::PostPostCutOxygen <- function() {
	if (O2_CUT) {
		EntFire("o2_hurt", "Enable")
	}
}

::RestoreOxygen <- function() {
	::O2_CUT = false
	Chat(MINT + "Oxygen level returning to normal...")
	EntFire("o2_alarm", "StopSound")
	EntFire("o2_hurt", "Disable")
	EntFire("o2_valve", "EnableMotion")
	EntFire("o2_motor", "TurnOn")
	EntFire("o2_motor", "SetSpeed", "-100")
	EntFire("o2_motor", "TurnOff", "", 3)
	EntFire("o2_valve", "DisableMotion", "", 3)
}

::StartLockdown <- function() {
	Chat(DARK_RED + "Lockdown initiated!")
	EntFire("lockdown_doors", "Close")
	EntFire("lockdown_alarm", "PlaySound")
	EntFire("lockdown_alarm", "FadeOut", "5", 3)
	EntFire("lockdown_lever", "SetAnimation", "closeopen", 1)
	EntFire("lockdown_lever", "SetAnimation", "idle_closed", 1.5)
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
	// ClientCMD(CAM_PLY, "playvol weapons/aug/aug_cliphit.wav 0.6") // FIXME
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
	"WST",
	"RCT",
	"ENG",
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
	if (TESTER_RIGGED) {
		return "0 255 0"
	}
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
		EntFire("tester_blip", "pitch", "80")
		return
	}

	for (local i = 0; i < 2; i++) {
		local clr = GetTesterResultColor(subjects[i])
		EntFire("tester_light" + (i + 1), "AddOutput", "rendercolor " + clr)
		EntFire("tester_light" + (i + 1), "AddOutput", "rendercolor 255 255 255", 3)
	}

	EntFire("tester_blip", "pitch", "100")

	// unrig tester after rigged test
	if (TESTER_RIGGED) {
		EntFire("traitor_button", "FireUser3")
	}
}

::GiveMelee <- function(ply, name) {
	local knife = null
	while (knife = Entities.FindByClassname(knife, "weapon_knifegg")) {
		if (knife.GetOwner() == ply) {
			knife.Destroy()
		}
	}
	GiveWeapon(ply, "weapon_" + name)
	MeleeFixup()
}

::HomeDepot <- function(ply) {GiveMelee(ply, "hammer")}
::CreamGravy <- function(ply) {GiveMelee(ply, "spanner")}

::LoseRR <- function(ply) {
	if (ply.GetHealth() > 0) {
		ply.SetHealth(1)
		EntFireHandle(ply, "IgniteLifetime", "0.1")
	}
}

::RussianRoulette <- function(ply) {
	EntFire("rr_gun", "Disable")
	EntFire("rr_snd_spin", "PlaySound")
	EntFire("rr_gun", "Enable", "", 2.4)
	if (RandomInt(1, 666) % 6 == 0) {
		EntFire("rr_snd_lose", "PlaySound", "", 1.5)
		if (GetRole(ply) != JESTER) {
			EntFireHandle(ply, "RunScriptCode", "LoseRR(self)", 1.5)
		}
	} else {
		EntFire("rr_snd_win", "PlaySound", "", 1.5)
	}
}

::JUKEBOX_SONGS <- 7
::JUKEBOX_SONG <- JUKEBOX_SONGS - 1

::CycleJukebox <- function() {
	::JUKEBOX_SONG = (JUKEBOX_SONG + 1) % JUKEBOX_SONGS
	if (JUKEBOX_SONG > 0) {
		EntFire("pub_jukebox_song" + (JUKEBOX_SONG - 1), "StopSound")
	}
	if (JUKEBOX_SONG < JUKEBOX_SONGS) {
		EntFire("pub_jukebox_song" + JUKEBOX_SONG, "PlaySound")
	}
	EntFire("yaoi_placards", JUKEBOX_SONG == 2 ? "Unlock" : "Lock")
}

::PropaneShot <- function(ent) {
	if (!PREPARING) {
		EntFireHandle(ent, "Break")
	}
}

::DoorStatus <- function(door, isClosed) {
	if (door.ValidateScriptScope()) {
		local ss = door.GetScriptScope()
		ss.closed <- isClosed
		ss.lastStatusUpdate <- Time()
		if (isClosed) {
			EntFireHandle(door, "RunScriptCode", "TryOpenDoor(self)", TTT_DOOR_TIME)
		}
	}
}

::TryOpenDoor <- function(door) {
	if (door.ValidateScriptScope()) {
		local ss = door.GetScriptScope()
		if (ss.closed && Time() - ss.lastStatusUpdate > TTT_DOOR_TIME - 0.1) {
			EntFireHandle(door, "Open")
		}
	}
}

::BananaBread <- function() {
	EntFire("banana_bread", "Pitch", "" + RandomInt(75, 125))
}
