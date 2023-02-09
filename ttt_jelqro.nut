
IncludeScript("butil")

::TTTHooks <- {
	GetConfig = function() {
		return [
			["DOOR_TIME", 20, "How long doors should stay closed, in seconds."],
			["CRASH_TIME", 60, "How long should the ship be off course before crashing."]
		]
	},
	GetHints = function() {
		return [
			"When the lights are out, traitors can see slightly farther than everyone else.",
			"Traitors can rig the tester to show both subjects as innocent for a single test.",
			"Traitors can open or close doors at any time, even during a lockdown.",
			"The windows in the traitor room are thick, and will block low-damage weapons.",
			"The AWP in the weapon room can be unlocked by a button in the traitor room.",
			"Some walls in the storage room are in need of maintenance.",
			"You will not suffocate in the simulation room.",
			"We have no idea where this ship is headed.",
			"There is a two-person traitor tester in the admin room."
		]
	},
	OnPostSpawn = function() {
		::TESTER_RIGGED <- false
		::O2_CUT <- false
		::NAV_FUCKED <- false
		::NAV_FUCKED_ANNOUNCED <- false
		::OVERTIME_SABOTAGE_ANNOUNCED <- false

		// hard-coded radar :)
		::MAP_MINS <- Vector(-1472, -1088, 0)
		::MAP_MAXS <- Vector(1184, 832, 0)
		::RADAR_SCALE <- Vector(128.0 / 2656.0, 128.0 / 1920.0, 0)
		::RADAR_MARKER_STORAGE <- Vector(2240, -1290, -192)
		::RADAR_MINS <- Entities.FindByName(null, "radar_mins").GetOrigin()
		::RADAR_MAXS <- Entities.FindByName(null, "radar_maxs").GetOrigin()

		// reset fog
		SetLightsOn(true)
		if (!ScriptIsWarmupPeriod()) {
			EntFire("fog_darkness", "TurnOn")
			EntFire("fog_darkness_traitor", "TurnOn")
			EntFire("fog_default", "TurnOn")
		}

		// reset sprites
		EntFire("tester_light1", "AddOutput", "rendercolor 255 255 255")
		EntFire("tester_light2", "AddOutput", "rendercolor 255 255 255")
		EntFire("bathroom_sprite", "AddOutput", "rendercolor 150 255 150")
		EntFire("yaoi_sprite1", "HideSprite")
		EntFire("yaoi_sprite2", "HideSprite")
	},
	OnPostSpawnPlayer = function(ply) {
		// some people might be stuck in cams from last round
		StopCams(ply)

		// cure them of covid
		if (ply.ValidateScriptScope()) {
			ply.GetScriptScope().infected <- false
		}
	},
	OnPostSpawnEntity = function(ent) {
		if (ent.GetName() == "lockdown_doors" && ent.ValidateScriptScope()) {
			ent.GetScriptScope().InputUse <- function() {
				return GetRole(activator) == TRAITOR
			}
		}
	},
	OnWarRound = function() {
		// disable nav trap on war rounds
		EntFire("traitor_button", "FireUser4")
		EntFire("nav_lever", "SetAnimation", "closeopen")
		EntFire("nav_lever", "SetAnimation", "idle_closed", 0.5)
	},
	PlayerDeath = function(ply) {
		if (CAM_PLY == ply) {
			CenterPrint(ply, "If you're stuck in the camera, just wait for next round. Sorry!")
			StopCams(ply)
		}
	},
	Think = function() {
		if (CAM_PLY != null) {
			EntFire("sec_cam*", "RunScriptCode", "CameraPan(self)")
			EntFire("sec_cam*", "RunScriptCode", "CameraPan(self)", 0.033)
			EntFire("sec_cam*", "RunScriptCode", "CameraPan(self)", 0.067)
		}

		EntFire("hint_monitor", "AddOutput", "texframeindex " + abs(Time() / 16) % 14)
	},
	ShouldOvertime = function() {
		return O2_CUT || NAV_FUCKED
	},
	OnOvertime = function() {
		if (!OVERTIME_SABOTAGE_ANNOUNCED) {
			::OVERTIME_SABOTAGE_ANNOUNCED = true
			Chat(DARK_RED + "OVERTIME: Innocents will win when the ship is repaired.")
		}
	},
	LivingPlayerThink = function(ent) {
		if (!ent.ValidateScriptScope()) {
			return
		}
		local ss = ent.GetScriptScope()
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
}

IncludeScript("ttt_among_us")

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

::TryStopCams <- function() {
	if (CAM_PLY != null)
		StopCams(CAM_PLY)
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
