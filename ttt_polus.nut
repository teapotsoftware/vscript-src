
IncludeScript("butil")

::TTTHooks <- {
	GetHints = function() {
		return [
			"Lava hurts. So do cliffs.",
		]
	},
	OnPostSpawn = function() {
		::TURRET_INPUTS <- {[0] = false, [1] = false, [2] = false, [3] = false}
		::OVERTIME_SABOTAGE_ANNOUNCED <- false
		::O2_CUT <- false

		StopCams()
		EntFire("wpn_turret_cam", "Disable", "", 0.5)
	},
	Think = function() {
		local p = Ent("wpn_turret_rot2").GetAngles().x
		if (p < -45 && TURRET_INPUTS[0]) {
			TURRET_INPUTS(0, false)
		} else if (p > 35 && TURRET_INPUTS[2]) {
			TURRET_INPUTS(2, false)
		}

		if (CAM_PLY != null && !Alive(CAM_PLY)) {
			StopCams()
		}

		EntFire("projector_screen", "AddOutput", "texframeindex " + abs(Time() / 16) % 14)
	},
	ShouldOvertime = function() {
		return O2_CUT
	},
	OnOvertime = function() {
		if (!OVERTIME_SABOTAGE_ANNOUNCED) {
			::OVERTIME_SABOTAGE_ANNOUNCED = true
			Chat(DARK_RED + "OVERTIME: Innocents will win when the facility is repaired.")
		}
	},
	PlayerDeath = function(ply) {
		if (ply == CAM_PLY) {
			CAM_PLY = null
		}
	}
}

IncludeScript("ttt_among_us")

// TURRET

::TurretInput <- function(num, state) {
	TURRET_INPUTS[num] = state
	if (num == 0 || num == 2) {
		if (TURRET_INPUTS[0] == TURRET_INPUTS[2]) {
			EntFire("wpn_turret_rot2", "Stop")
		} else {
			local p = Ent("wpn_turret_rot2").GetAngles().x
			if ((p < -45 && TURRET_INPUTS[0]) || (p > 35 && TURRET_INPUTS[2])) {
				EntFire("wpn_turret_rot2", "Stop")
			} else {
				EntFire("wpn_turret_rot2", "Start" + (TURRET_INPUTS[0] ? "Backward" : "Forward"))
			}
		}
	} else {
		if (TURRET_INPUTS[1] == TURRET_INPUTS[3]) {
			EntFire("wpn_turret_rot1", "Stop")
		} else {
			EntFire("wpn_turret_rot1", "Start" + (TURRET_INPUTS[3] ? "Backward" : "Forward"))
		}
	}
}

// OXYGEN

::CutOxygen <- function(stage = 0) {
	switch (stage) {
		case 0:
			EntFire("script", "RunScriptCode", "CutOxygen(1)", 5)
			EntFire("o2_valve_rot", "StartBackward")
			EntFire("o2_valve_rot", "Stop", "", 8)
			break

		case 1:
			::O2_CUT = true
			Chat(DARK_RED + "WARNING: Atmospheric oxygen level low!")
			EntFire("o2_alarm", "PlaySound")
			EntFire("script", "RunScriptCode", "CutOxygen(2)", 8)
			break

		case 2:
		if (O2_CUT) {
			EntFire("o2_hurt", "Enable")
		}
	}
}

::RestoreOxygen <- function() {
	::O2_CUT = false
	Chat(MINT + "Oxygen level returning to normal...")
	EntFire("o2_alarm", "StopSound")
	EntFire("o2_hurt", "Disable")
	EntFire("o2_valve_rot", "StartForward")
	EntFire("o2_valve_rot", "Stop", "", 8)
}

// COMMS

::DisruptComms <- function() {
	ForEachLivingPlayer(function(ply) {
		ply.SetModel("models/player/custom_player/legacy/tm_jumpsuit_amgusrbw.mdl")
	})

	Chat(DARK_RED + "Comms disrupted!")
}

::FixComms <- function() {
	ForEachLivingPlayer(function(ply) {
		ply.SetModel(PlayerModel(ply.GetScriptScope().round_playermodel))
	})

	Chat(MINT + "Comms fixed!")
	EntFire("comms_lever", "SetAnimation", "closeopen", 1)
	EntFire("comms_lever", "SetAnimation", "idle_closed", 1.5)
}

// CAMERAS

::CAM_PLY <- null
::CAM_INDEX <- 0
::CAM_NAMES <- [
	"PIT",
	"YARD",
	"TURRET",
	"COMMS",
	"BRIDGE",
	"O2"
]
::CAM_MAX <- 6

::SetCam <- function(n) {
	EntFire("cam" + n + "-view", "Enable", "", 0, CAM_PLY)
	//EntFire("cam_snd", "PlaySound")
}

::CycleCam <- function(n) {
	if (CAM_PLY == null) {
		return
	}
	::CAM_INDEX = (CAM_MAX + CAM_INDEX + n) % CAM_MAX
	SetCam(CAM_INDEX)
	if (CAM_PLY.ValidateScriptScope()) {
		CAM_PLY.GetScriptScope().last_cam <- CAM_INDEX
	}
}

::StartCams <- function(ply) {
	::CAM_PLY <- ply
	local cam = 0
	if (ply.ValidateScriptScope()) {
		local scope = ply.GetScriptScope()
		if ("last_cam" in scope) {
			cam = scope.last_cam
		}
	}
	SetCam(cam)
}

::StopCams <- function() {
	for (local i = 0; i < CAM_MAX; i++) {
		EntFire("cam" + i + "-view", "Disable")
	}
	::CAM_PLY = null
}
