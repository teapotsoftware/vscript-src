
// Playtest #1 notes:
// [X] Lock stair trigger in first level until first wave is complete
// [X] Teleport respawned players to alive players
// [ ] Add Ram Ranch secret in prison level
// [X] Put red light in vent
// [X] Light above exit door in prison (or maybe leave it open)
// [X] Ghost knife is fucked when you whip it out
// [X] Different song when level is over
// [X] Remember to include phone call MP3s

// Playtest #2 notes:
// [X] Stair trigger isn't enabled
// [X] Only players in the level are respawned (kms)
// [X] Michael volume too loud (Add volume slider)

// Playtest #3 notes:
// [X] Knife in the toaster that starts with a taser
// [ ] Color tiers for knives that penalize or reward points depending on how OP they are

////////////////////////////////////////////////////////////////////////////////
////////// SETUP ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::CMDs <- [
	"mp_roundtime_deployment 15",
	"mp_autokick 0",
	"mp_freezetime 1",
	"mp_round_restart_delay 2",
	"mp_molotovusedelay 0",
	"mp_maxrounds 99999",
	"bot_chatter off",
	"ammo_grenade_limit_default 3"
]

foreach (cmd in CMDs) {
	SendToConsole(cmd)
	SendToConsoleServer(cmd)
}

// force co-op strike
if (ScriptGetGameMode() != 1 || ScriptGetGameType() != 4) {
	SendToConsole("game_mode 1; game_type 4; changelevel " + GetMapName())
}

if (ScriptIsWarmupPeriod()) {
	SendToConsole("mp_warmup_end")
}

////////////////////////////////////////////////////////////////////////////////
////////// MISC ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::LEVEL_HOUSE <- 0
::LEVEL_CLUB <- 1
::LEVEL_OFFICE <- 2
::LEVEL_PRISON <- 3
::LEVEL_MAFIA <- 4

if (!("config" in getroottable())) {
	::config <- {
		dreams = false,
		respawns = true,
		volume = 6,
		music = 2,
		difficulty = 0,
		combolock = [0, 0, 0, 0]
	}
	::MET_SPY <- false
	::CurLevel <- 0
	::PRINT_SCORES <- false
	::SCORE_INDEX <- 0
	::LEVEL_MAX <- 4
}

::TRANSLATE_VOLUME <- ["0", "4", "5", "6", "7", "8", "9", "10"]

::LOCKED_IN <- false
::STARTED <- false
::COMBO_TIME <- -3
::COMBO <- 0
::ALL_HEADSHOTS <- true
::TIME_START <- 0
::TIME_END <- 0
::TIME_TAKEN <- 0
::SINKS_RUNNING <- 0
::BECAME_GUARDS <- false

::TRACK_BLIZZARD <- ["blizzard", 185.15]
::TRACK_PARIS <- ["paris", 103.53]
::TRACK_DRONE <- ["drone", 72.28]
::TRACK_WERESORRY <- ["weresorry", 122.94]
::TRACK_DISCO <- ["miamidisco", 266.06]
::TRACK_DUST <- ["dust", 99.44]
::TRACK_SILVERLIGHTS <- ["silverlights", 106.95]
::TRACK_FUTURECLUB <- ["futureclub", 281.54]
::TRACK_LEPERV <- ["leperv", 256]
::TRACK_BURNINGCOALS <- ["burningcoals", 172.91]

::TRACK_BLIZZARD_METAL <- ["blizzard_metal", 164.56]
::TRACK_PARIS_METAL <- ["paris_metal", 95.99]
::TRACK_DISCO_METAL <- ["miamidisco_metal", 265.14]
::TRACK_FUTURECLUB_METAL <- ["futureclub_metal", 235.53]
::TRACK_LEPERV_METAL <- ["leperv_metal", 256]
::TRACK_BURNINGCOALS_METAL <- ["burningcoals_metal", 130.65]

::PLAYER_MODELS <- [
	"models/player/custom_player/legacy/tm_anarchist_variantd.mdl",
	"models/player/custom_player/legacy/tm_anarchist_varianta.mdl",
	"models/player/custom_player/legacy/tm_anarchist.mdl", // not black!!!
	"models/player/custom_player/legacy/tm_anarchist_variantb.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantc.mdl"
]

::PRISONER_MODELS <- [
	"models/player/custom_player/legacy/tm_jumpsuit_variantb.mdl",
	"models/player/custom_player/legacy/tm_jumpsuit_variantc.mdl",
	"models/player/custom_player/legacy/tm_jumpsuit_varianta.mdl", // black
	"models/player/custom_player/legacy/tm_jumpsuit_variantb.mdl",
	"models/player/custom_player/legacy/tm_jumpsuit_variantc.mdl",
]

::GUARD_MODELS <- [
	"models/player/custom_player/legacy/ctm_swat.mdl",
	"models/player/custom_player/legacy/ctm_swat_varianta.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantb.mdl", // black
	"models/player/custom_player/legacy/ctm_swat_variantc.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantd.mdl"
]

::MAFIA_MODELS <- [
	"models/player/custom_player/legacy/tm_professional.mdl",
	"models/player/custom_player/legacy/tm_professional_var1.mdl",
	"models/player/custom_player/legacy/tm_professional_var4.mdl", // black
	"models/player/custom_player/legacy/tm_professional_var2.mdl",
	"models/player/custom_player/legacy/tm_professional_var3.mdl",
]

::DREAMS <- [
	[ // HOUSE
		[1, "Ah, who do we have here?"],
		[1, "Actually, nevermind. I don't care."],
		[1, "Are you enjoying yourself?"],
		[2, "You really shouldn't be."],
		[2, "If only you knew what you were doing..."],
		[0, "You would love yourself!"],
		[0, "And, at the end of the day..."],
		[0, "Love is all there is."],
		[1, "I hope we're not confusing you."],
		[1, "Actually, I don't care about that either."],
		[1, "You will soon discover something very important."],
		[1, "Ciao for now."]
	], [ // CLUB
		[1, "You seem troubled."],
		[1, "Your discovery, was it unpleasant?"],
		[2, "Unreal things can have the most real consequences."],
		[2, "Perhaps you should be more careful how you think."],
		[0, "Or, for once, maybe..."],
		[0, "You could put your thoughts into action."],
		[1, "There isn't much time right now."],
		[1, "We will see you soon."]
	], [ // OFFICE
		[1, "Welcome back."],
		[1, "That was an impressive display, but..."],
		[1, "I get the feeling you’re holding back."],
		[0, "At this rate, you will not make it."],
		[0, "Soon, this will be over. But until then..."],
		[0, "You are going to have a very bad time."],
		[2, "Perhaps if you insist on self-destruction..."],
		[2, "Have you considered you may not survive?"],
		[2, "It may be time to re-evaluate."],
		[0, "..."],
		[0, "I've always hated you."],
		[2, "You..."],
		[2, "What I would give to be rid of you..."],
		[0, "You've had a lifetime to try...", 2],
		[-1, "", 0],
		[1, "Our time here will soon come to a close."],
		[1, "Consider your options carefully."]
	], [ // PRISON
		[1, "Hello, old friend."],
		[1, "I'm still here, as you can see."],
		[1, "But it looks like you don't need me anymore."],
		[1, "It’s done now."],
		[1, "You can have this moment of clarity. Enjoy it."],
		[1, "One day, you will be ready to leave this place."],
		[1, "Until then... we’ll be seeing you soon."],
		[1, "Ciao for now."],
		[-1, "", 1],
		[-1, ""]
	], [ // MAFIA
		[0, "TRIPLE SIX"],
		[1, "FIVE"],
		[2, "FORKED TONGUE"],
		[0, "SUBATOMIC PENETRATION RAPID FIRE THROUGH YOUR SKULL"],
		[1, "HOW I SHOT IT ON ONE TAKING IT BACK TO THE DAYS OF TRYING TO LOSE CONTROL"],
		[2, "SWERVING IN A BLAZE OF FIRE, RAGING THROUGH MY BONES"],
		[0, "OH SHIT IM FEELING IT"],
		[1, "TAKYON!"],
		[2, "HELL YEAH, FUCK YEAH"],
		[0, "I FEEL LIKE KILLING IT"],
		[1, "TAKYON!"],
		[2, "ALRIGHT THAT'S TIGHT"],
		[0, "WHAT IT'S LIKE TO EXPERIENCE"],
		[1, "TAKYON!"],
		[2, "Ahem."],
		[2, "Thank you for attending our concert."],
		[1, "TAKYON!"],
		[0, "..."],
		[2, "..."],
		[0, "..."],
		[2, "..."],
		[1, "..."],
		[1, "..."],
		[1, "TAKYON!"]
	],
]

::LeetSpeak <- {
	["o"] = "0",
	["i"] = "1",
	["e"] = "3",
	["a"] = "4",
	["t"] = "7",
	["s"] = "$",
	["n"] = "|\\|",
	["m"] = "|V|",
}

::Chat <- function(txt) {
	if (config.combolock[0] == 1 && config.combolock[1] == 3 && config.combolock[2] == 3 && config.combolock[3] == 7) {
		local newTxt = ""
		for (local i = 0; i < txt.len(); i++) {
			local chr = txt.slice(i, i + 1)
			if (chr.tolower() in LeetSpeak) {
				newTxt += LeetSpeak[chr.tolower()]
			} else {
				newTxt += chr
			}
		}
		ScriptPrintMessageChatAll(" " + newTxt)
	} else {
		ScriptPrintMessageChatAll(" " + txt)
	}
}

::BreakString <- function(txt) {
	for (local i = 0; i < txt.len(); i++) {
		local chr = txt.slice(i, i + 1)
		printl("\"" + chr + "\"")
	}
}

::LivingCT <- function(ply) {
	return ply.GetClassname() == "player" && ply.GetTeam() == 3 && ply.GetHealth() > 0
}

::ShowHUD <- function(id, txt, ply = null) {
	EntFire("hud_" + id, "SetText", txt)
	EntFire("hud_" + id, "Display", "", 0, ply)
}

////////////////////////////////////////////////////////////////////////////////
////////// LEVELS //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::Levels <- [
	{
		id = "house",
		name = "Breakage",
		setting = "210 Joyce St.",
		tracks = [TRACK_PARIS_METAL, TRACK_PARIS],
		callDuration = 10.7,
		firstEnemies = 5,
		maxScore = 26000,
		maxTime = 120,
		hint = "...seven days a week...",
		waves = [
			function() {
				EntFire("house_stairblocker", "Kill")
				EntFire("house_stairs_trigger", "Enable")
			},
			function() {
				EntFire("briefcase_button", "Unlock")
				EntFire("briefcase", "SetGlowEnabled")
				EntFire("house_crowbar_button", "Unlock")
				if (KnifeActive("ghost")) {
					EntFire("house_crowbar", "SetGlowEnabled")
				}
			},
			function() {
				EntFire("sewer_blocker", "Break")
			},
			function() {
				if (config.music > 0) {
					EZTrack(TRACK_DRONE)
				}
			}
		]
	}, {
		id = "club",
		name = "Penetration",
		setting = "731 NE Blvd.",
		tracks = [TRACK_DISCO_METAL, TRACK_DISCO],
		callDuration = 9.6,
		firstEnemies = 15,
		maxScore = 26000,
		maxTime = 120,
		hint = "...seven men see...",
		waves = [
			function() {
				TryRespawnPlayers()
				EntFire("club_dbl2_right", "Unlock")
				EntFire("club_dbl2_right", "SetBreakable")
				EntFire("club_dbl2_right", "SetGlowEnabled")
				EntFire("club_dbl2_left", "Unlock")
				EntFire("club_dbl2_left", "SetBreakable")
				EntFire("club_dbl2_left", "SetGlowEnabled")
				EntFire("club_phone_busy", "PlaySound")
				EntFire("script", "RunScriptCode", "SpawnNextWave(3)", 0.1)
			},
			function() {
				EntFire("club_van_screech", "PlaySound")
				EntFire("club_van", "Enable", "", 1.5)
				EntFire("club_van_smoke", "TurnOn", "", 1.5)
				EntFire("script", "RunScriptCode", "SpawnNextWave(6)", 1.5)
			},
			function() {
				EntFire("club_phone_busy", "StopSound")
				EntFire("club_end", "Enable")
				EntFire("level_complete", "PlaySound")
				if (config.music > 0) {
					EZTrack(TRACK_DRONE)
				}
			}
		]
	}, {
		id = "office",
		name = "Downsizing",
		setting = "211 Joyce St.",
		tracks = [TRACK_FUTURECLUB_METAL, TRACK_FUTURECLUB],
		callDuration = 15.2,
		firstEnemies = 9,
		maxScore = 35000,
		maxTime = 240,
		hint = "...five corpses lie...",
		waves = [
			function() {
				EntFire("office_door_stairs", "Unlock")
				EntFire("office_door_stairs", "SetGlowEnabled")
				EntFire("office_door_stairs", "SetBreakable")
			},
			function() {
				TryRespawnPlayers()
				EntFire("script", "RunScriptCode", "SpawnNextWave(6)", 1)
				foreach (b in ["", "_left"]) {
					EntFire("office_door_ceo" + b, "SetGlowEnabled")
					EntFire("office_door_ceo" + b, "Unlock", "", 2)
					EntFire("office_door_ceo" + b, "SetBreakable", "", 2)
				}
				EntFire("office_swatvan_template", "ForceSpawn", "", 5)
				EntFire("office_sirenloop", "Volume", "0", 5)
				EntFire("office_sirenloop", "FadeIn", "8", 5)
			},
			function() {
				EntFire("script", "RunScriptCode", "SpawnNextWave(6)", 0.5)
				EntFire("office_end", "Enable")
				EntFire("club_end", "Enable")
			}
		]
	}, {
		id = "prison",
		name = "Redemption",
		setting = "Federal Detention Center",
		tracks = [TRACK_LEPERV_METAL, TRACK_LEPERV],
		callDuration = 6.7,
		firstEnemies = 3,
		maxScore = 36000,
		maxTime = 300,
		hint = "...zero caution taken...",
		waves = [
			function() {
				TryRespawnPlayers()

				EntFire("prison_outsidedbl_left", "Unlock")
				EntFire("prison_outsidedbl_left", "SetGlowEnabled")
				EntFire("prison_outsidedbl_left", "SetBreakable")
				EntFire("prison_outsidedbl_right", "Unlock")
				EntFire("prison_outsidedbl_right", "SetGlowEnabled")
				EntFire("prison_outsidedbl_right", "SetBreakable")

				// getting shanked is kinda bullshit
				local ply = null
				while (ply = Entities.Next(ply)) {
					if (ply.GetClassname() == "player" && ply.GetTeam() == 3) {
						ply.SetHealth(100)
					}
				}

				// spawn next wave right away
				EntFire("script", "RunScriptCode", "SpawnNextWave(8)", 0.1)
			},
			function() {
				EntFire("warden_keyboard_model", "SetGlowEnabled")
				EntFire("warden_keyboard_button", "Unlock")
			},
			function() {
				TryRespawnPlayers()
			},
			function() {
				EntFire("prison_keycard_door1", "Unlock")
				EntFire("prison_keycard_door1", "SetGlowEnabled")
			},
			function() {
				EntFire("prison_deathrow_door", "Unlock")
				EntFire("prison_deathrow_door", "SetGlowEnabled")
				EntFire("prison_deathrow_door", "SetBreakable")
			},
			function() {
				EntFire("prison_keycard_door4", "Unlock")
				EntFire("prison_keycard_door4", "SetGlowEnabled")
			}
		]
	}, {
		id = "mafia",
		name = "Takeover",
		setting = "731 NE Blvd.",
		tracks = [TRACK_BURNINGCOALS_METAL, TRACK_BURNINGCOALS],
		callDuration = 9.6,
		firstEnemies = 13,
		maxScore = 20000,
		maxTime = 120,
		hint = "...map by teapot :3",
		waves = [
			function() {
				TryRespawnPlayers()
				EntFire("club_dbl2_right", "Unlock", "", 2)
				EntFire("club_dbl2_right", "SetBreakable", "", 2)
				EntFire("club_dbl2_right", "SetGlowEnabled")
				EntFire("club_dbl2_left", "Unlock", "", 2)
				EntFire("club_dbl2_left", "SetBreakable", "", 2)
				EntFire("club_dbl2_left", "SetGlowEnabled")
				EntFire("script", "RunScriptCode", "SpawnSewerClones()", 0.1)
			},
			function() {
				EntFire("club_end", "Enable")
				EntFire("level_complete", "PlaySound")
				if (config.music > 0) {
					EZTrack(TRACK_DRONE)
				}
			}
		]
	}
]

// TODO: this stuff is all fucked up
::StartDeco <- [
	[function() { // HOUSE
		EntFire("club_van", "Disable")
		EntFire("club_van", "DisableCollision")
	}, function() {
	}],
	[function() { // CLUB
		EntFire("start_deco1", "Enable")
	}, function() {
		EntFire("start_deco1", "Disable")
	}],
	[function() { // OFFICE
		EntFire("club_van", "Enable")
		EntFire("club_van", "EnableCollision")
		EntFire("office_van", "Disable")
		EntFire("office_van", "DisableCollision")
	}, function() {
		EntFire("club_van", "Disable")
		EntFire("club_van", "DisableCollision")
		EntFire("office_van", "Enable")
		EntFire("office_van", "EnableCollision")
	}],
	[function() { // PRISON
		EntFire("cop_props", "Enable")
		EntFire("cop_props", "EnableCollision")
		EntFire("cop_timer", "Enable")
		EntFire("cop_spotlight", "TurnOn")
	}, function() {
		EntFire("cop_props", "Disable")
		EntFire("cop_props", "DisableCollision")
		EntFire("cop_timer", "Disable")
		EntFire("cop_spotlight", "TurnOff")
		for (local i = 1; i < 5; i++) {
			EntFire("cop_lights" + i, "HideSprite")
		}
	}],
	[function() { // MAFIA
	}, function() {
	}],
]

::SetLevel <- function(l) {
	if (CurLevel == l)
		return

	StartDeco[CurLevel][1]()
	::CurLevel = l
	StartDeco[l][0]()

	EntFire("whiteboard_chapter", "AddOutput", "texframeindex " + l)
	EntFire("whiteboard_title", "AddOutput", "texframeindex " + l)
}

::CycleLevel <- function(i) {
	SetLevel((LEVEL_MAX + CurLevel + i) % LEVEL_MAX)
}

::RankNums <- [1, 4, 7, 10, 12, 14, 16, 18]

::UpdateRank <- function() {
	local rank = Entities.FindByName(null, "whiteboard_rank")
	if (rank != null) {
		rank.SetModel("models/inventory_items/skillgroups/skillgroup" + RankNums[config.difficulty] + ".mdl")
	}
}

::CycleDifficulty <- function(i) {
	::config.difficulty = (8 + config.difficulty + i) % 8
	SendToConsoleServer("mp_coopmission_bot_difficulty_offset " + config.difficulty)
	UpdateRank()
}

////////////////////////////////////////////////////////////////////////////////
////////// SCORING /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::AddBonus <- function(name, amt) {
	Score.Bonuses.push([name, amt])
	Score.Total += amt
}

// x is combo kills minus 1
// this is how hlm1 does it
::GetComboScore <- function(x) {
	local y = (x + 1.4)
	return 125 * y * y - 20
}

// similiar to how hlm2 does it
::GetTimeBonus <- function() {
	local bns = ceil(9000 - 9000 * (TIME_TAKEN / 300))
	if (bns < 0) return 0
	return bns
}

// i just made this one up
::GetFlexBonus <- function() {
	local total = 0
	foreach (k, v in Score.WeaponsUsed) {
		total += 400 - 50 * v
	}
	return total
}

::GetTotalScore <- function() {
	return Score.Total + GetFlexBonus() + GetTimeBonus()
}

// similiar to hlm1, but with S
::GetGrade <- function(score, max) {
	if (score > max) return "S"
	if (score == max) return "A+"
	local grades = ["F-", "F", "F+", "D-", "D", "D+", "C-", "C", "C+", "B-", "B", "B+", "A-", "A", "A+"]
	return grades[floor((score / max) * 15)]
}

::GetComboTime <- function() {
	return KnifeActive("ursus") ? 4 : 3
}

::CheckCombo <- function() {
	if (COMBO > 0 && Time() - COMBO_TIME > GetComboTime()) {
		AddBonus((COMBO + 1) + "x Combo", GetComboScore(COMBO))
		::COMBO = 0
	}
}

////////////////////////////////////////////////////////////////////////////////
////////// SCRIPT HOOKS ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

OnPostSpawn <- function() {
	local precached = false
	local ent = null
	while (ent = Entities.Next(ent)) {
		if (!precached) {
			precached = true
			ent.PrecacheModel("models/weapons/v_models/arms/bare/v_bare_hands.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/anarchist/v_glove_anarchist.mdl")
			foreach (num in RankNums) {
				ent.PrecacheModel("models/inventory_items/skillgroups/skillgroup" + num + ".mdl")
			}
			// foreach (mdl in PLAYER_MODELS) {ent.PrecacheModel(mdl)}
			foreach (mdl in PRISONER_MODELS) {ent.PrecacheModel(mdl)}
			foreach (mdl in GUARD_MODELS) {ent.PrecacheModel(mdl)}
			foreach (mdl in MAFIA_MODELS) {ent.PrecacheModel(mdl)}
		}

		if (ent.ValidateScriptScope()) {
			local classname = ent.GetClassname()
			local name = ent.GetName()

			if (name.len() > 6  && name.slice(0, 6) == "knife_") {
				ent.GetScriptScope().InputUse <- function() {
					SetKnife(activator, self.GetName().slice(6))
				}
			} else if (name == "helmet_pickup") {
				ent.GetScriptScope().InputUse <- function() {
					EntFire("equip_helmet", "Use", "", 0, activator)
					AddBonus("Safety First", 200)
					self.Destroy()
				}
			}
		}
	}

	// clear start deco
	for (local i = 0; i < LEVEL_MAX; i++) {
		if (i != CurLevel) {
			StartDeco[i][1]()
		}
	}

	// do deco for CurLevel last, big brain
	StartDeco[CurLevel][0]()

	if (config.music > 0) {
		EZTrack([TRACK_BLIZZARD_METAL, TRACK_BLIZZARD][config.music - 1])
	}

	// chapter number and title are func_brush but rank prop_dynamic is reset every round
	// volume display is also func_brush
	UpdateRank()
	UpdateJukeboxGlow()
	UpdateBedGlow()
	CheckComboLock()
	EntFire("whiteboard_respawns_checkbox", "AddOutput", "texframeindex " + (config.respawns ? 2 : 0))
	// EntFire("start_sink_water", "Disable") // start sink will stay on if left on :)
	EntFire("house_sink_water", "Disable")
	EntFire("house_sink_water2", "Disable")
	EntFire("house_sink_water3", "Disable")
	EntFire("house_sink_water4", "Disable")
	EntFire("club_sink_water", "Disable")
	EntFire("office_sink_water", "Disable")
	EntFire("prison_sink_water", "Disable")
	EntFire("prison_sink_water2", "Disable")
	EntFire("prison_suicidedeag", "SetAmmoAmount", "6")
	EntFire("prison_suicidedeag", "SetReserveAmmoAmount", "35")
	EntFire("prison_suicidem4", "SetAmmoAmount", "29")
	EntFire("prison_suicidem4", "SetReserveAmmoAmount", "90")
	EntFire("office_mp5", "SetAmmoAmount", "19")
	EntFire("office_mp5", "SetReserveAmmoAmount", "85")
	EntFire("vhs_precache", "Kill")
	EntFire("office_trash", "Break")
}

Think <- function() {
	local deleteme = []
	local ent = null
	while (ent = Entities.Next(ent)) {
		local classname = ent.GetClassname()
		local name = ent.GetName()

		if (classname.len() > 7 && classname.slice(0, 7) == "weapon_") {
			local owner = ent.GetOwner()
			if (owner != null && GetKnife(owner) == "karambit") {
				EntFireByHandle(ent, "SetReserveAmmoAmount", "0", 0, null, null)
			}
		} else if (classname == "decoy_projectile") {
			if (!ent.ValidateScriptScope()) {
				continue
			}
			local owner = ent.GetOwner()
			if (owner == null) {
				continue
			}
			local ss = ent.GetScriptScope()
			if (!("thrown_knife" in ss)) {
				ss.thrown_knife <- true
				ent.SetModel("models/weapons/w_knife_skeleton_dropped.mdl")
				ent.EmitSound("Player.GhostKnifeSwish")
			}
			if (ent.GetVelocity().LengthSqr() < 1) {
				EntFire("equip_decoy", "Use", "", 0, owner)
				deleteme.push(ent)
			} else {
				ent.EmitSound("Weapon_Knife.Slash")
				local ply = null
				while (ply = Entities.FindByClassnameWithin(ply, "cs_bot", ent.GetOrigin(), 20)) {
					if (ply.GetTeam() != owner.GetTeam() && ply.GetHealth() > 0) {
						ply.EmitSound("Weapon_Knife.Hit")
						ply.__KeyValueFromString("targetname", "thrown_knife_target")
						EntFire("thrown_knife_hurt", "Hurt", "", 0, owner)
						EntFire("thrown_knife_target", "AddOutput", "targetname \"\"", 0.1)
						deleteme.push(ent)
					}
				}
			}
		} else if (classname == "predicted_viewmodel") {
			if (ent.GetModelName() == "models/weapons/v_eq_decoy.mdl") {
				ent.SetModel("models/weapons/v_knife_skeleton.mdl")
			}
		}
	}
	foreach (del in deleteme) {
		del.Destroy()
	}

	if (PRINT_SCORES) {
		local msg = "\xC "
		local bonuslen = Score.Bonuses.len()
		if (SCORE_INDEX == 0) {
			msg += "BONUSES:"
		} else if (SCORE_INDEX <= bonuslen) {
			local bonus = Score.Bonuses[SCORE_INDEX - 1]
			msg += ">\xB " + bonus[0] + (bonus[1] > 0 ? "\xE +" : "\x7 ") + bonus[1]
		} else if (SCORE_INDEX == bonuslen + 1) {
			msg += "FLEXIBILITY:\xE " + GetFlexBonus()
		} else if (SCORE_INDEX == bonuslen + 2) {
			msg += "TIME BONUS:\xE " + GetTimeBonus()
		} else if (SCORE_INDEX == bonuslen + 3) {
			msg += "TOTAL SCORE:\xE " + GetTotalScore()
		} else {
			msg += "GRADE:\xE " + GetGrade(GetTotalScore(), Levels[CurLevel].maxScore)
			::PRINT_SCORES = false
		}
		Chat(msg)
		::SCORE_INDEX++
	}
}

////////////////////////////////////////////////////////////////////////////////
////////// EVENT LISTENERS /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::WeaponBonuses <- {
	["flashbang"] = ["Enormous Balls", 1200],
	["breachcharge_projectile"] = ["Jeep Stuff", 300],
	["taser"] = ["Shock Therapy", 600],
	["trigger_hurt"] = ["Letting Off Steam", 500],
	["point_hurt"] = ["Shurikenjutsu", 100],
	["usp_silencer_off"] = ["Going Loud", 50]
}

::WeaponBonuses["m4a1_silencer_off"] <- ::WeaponBonuses["usp_silencer_off"]

::Event_PlayerDeath <- function(data) {
/*
	printl("[player_death]")
	printl(" >   weapon: " + data.weapon)
	printl(" > headshot: " + data.headshot)
	printl(" > wallbang: " + data.penetrated)
	printl(" > distance: " + data.distance)
*/

	local t = Time()
	local combotime = GetComboTime()
	if (t - COMBO_TIME <= combotime) {
		::COMBO++
		ShowHUD("combo", (COMBO + 1) + "x")
	}
	::COMBO_TIME = t
	EntFire("script", "RunScriptCode", "CheckCombo()", combotime + 0.1)

	if (data.weapon.len() >= 5 && data.weapon.slice(0, 5) == "knife") {
		AddBonus("Regards Sent", 400)
	} else if (data.weapon in WeaponBonuses) {
		local bns = WeaponBonuses[data.weapon]
		AddBonus(bns[0], bns[1])
	} else {
		if (data.penetrated) {
			if (data.headshot) AddBonus("Surgical Penetration", 400)
			else if (data.penetrated > 1) AddBonus("Double Penetration", 400)
			else AddBonus("Wallbang", 200)
		}

		if (data.distance < 1) AddBonus("In Your Face", 200)
		else if (data.distance > 18) AddBonus("Long Shot", 200)
		if (data.noscope && data.weapon == "awp") AddBonus("Get the Camera", 300)
		if (!data.headshot) ::ALL_HEADSHOTS = false
	}

	if (data.attackerblind) AddBonus("Blind Luck", 200)

	if (data.weapon in Score.WeaponsUsed) {
		Score.WeaponsUsed[data.weapon]++
	} else {
		Score.WeaponsUsed[data.weapon] <- 1
	}
}

::LastLegKill <- 0

::Event_PlayerHurt <- function(data) {
/*
	printl("[player_hurt]")
	printl(" >   weapon: " + data.weapon)
	printl(" >   health: " + data.health)
	printl(" > hitgroup: " + data.hitgroup)
*/

	if (data.weapon == "flashbang") AddBonus("Big Balls", 400)
	if (Time() > LastLegKill && data.health == 0 && (data.hitgroup == 6 || data.hitgroup == 7)) {
		::LastLegKill = Time()
		AddBonus("That's the Concept", 50)
	}
}

////////////////////////////////////////////////////////////////////////////////
////////// NICK'S CO-OP ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::GivePlayerModel <- function(ply, list) {
	ply.SetModel(list[(ply.entindex() - 1) % list.len()])
}

::PlayerSpawn <- function(ply) {
	GivePlayerModel(ply, PLAYER_MODELS)

	// respawning players don't get knife perks, sorry not sorry
	local isRespawner = (STARTED && ply.GetOrigin().x > 0)
	if (isRespawner) {
		if (CurLevel == LEVEL_PRISON) {
			if (CurWave > 3) {
				GiveKnife(ply, "guard")
				GivePlayerModel(ply, GUARD_MODELS)
			} else {
				GiveKnife(ply, "shiv")
				GivePlayerModel(ply, PRISONER_MODELS)
			}
		} else if (CurLevel == LEVEL_MAFIA) {
			GiveKnife(ply, "none")
			GivePlayerModel(ply, MAFIA_MODELS)
		} else {
			GiveKnife(ply, "none")
		}
	} else {
		GiveKnife(ply, GetKnife(ply))
	}
	if (ply.ValidateScriptScope()) {
		ply.GetScriptScope().spawnedAfterStart <- isRespawner
	}

	// nice! :)
	if (isRespawner) {
		local ply2 = null
		while (ply2 = Entities.Next(ply2)) {
			if (LivingCT(ply2) && ply2.GetOrigin().x < 0) {
				ply.SetOrigin(ply2.GetOrigin())
			}
		}
	}

	EntFire("weapon_knife", "AddOutput", "classname weapon_knifegg")
}

::LockIn <- function() {
	::LOCKED_IN = true

	EntFire("whiteboard_buttons", "Kill")
	EntFire("start_button", "Lock")
	EntFire("start_button_model", "SetAnimation", "on")
	EntFire("start_button_model", "SetGlowDisabled")
	EntFire("phone_glow", "SetGlowEnabled", "", 1.5) // doesn't work
	// TODO: literally make brush outline of phone and propper it to glow like the manhole
	EntFire("phone_ring", "PlaySound", "", 1.5)

	if (CurLevel == LEVEL_MAFIA) {
		if (CurrentTrack != null) {
			EntFire("track_" + CurrentTrack, "Volume", "0", 1.9)
			// EntFire("script", "RunScriptCode", "SetTrack(null, 999)", 1.9)
		}
		EntFire("vhs_rewind", "PlaySound", "", 1.9)
		EntFire("phone_ring", "StopSound", "", 2.1)
		EntFire("start_beds", "SetGlowDisabled", "", 2.1)
		EntFire("jukebox_mdl", "SetGlowDisabled", "", 2.1)
		EntFire("jukebox_body", "SetGlowDisabled", "", 2.1)
		EntFire("vhs_overlay", "StartOverlays", "", 2.1)
		EntFire("script", "RunScriptCode", "StartMafia()", 7)
		EntFire("vhs_overlay", "StopOverlays", "", 7.1)
	} else {
		EntFire("phone_button", "Unlock", "", 1.5)
	}
}

::StartMafia <- function() {
	EntFire("office_moneypallets", "Disable")
	EntFire("office_moneypallets", "DisableCollision")
	EntFire("office_door_stairs", "Unlock")
	EntFire("office_stairs_trigger", "Disable")
	EntFire("office_dbldoor_right", "Lock")
	EntFire("office_dbldoor_right", "SetUnbreakable")
	EntFire("office_dbldoor_left", "SetUnbreakable")
	EntFire("office_coke", "Kill") // :(
	EntFire("office_recroom_mess", "Kill")

	foreach (b in ["", "_left"]) {
		EntFire("office_door_ceo" + b, "SetGlowEnabled")
		EntFire("office_door_ceo" + b, "Unlock", "", 2)
		EntFire("office_door_ceo" + b, "SetBreakable", "", 2)
	}

	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingCT(ply)) {
			Teleport(ply, "levelstart_mafia_" + ((ply.entindex() - 1) % 6))
			GivePlayerModel(ply, MAFIA_MODELS)
			EntFire("equip_none", "Use", "", 0, ply)
			ply.SetMaxHealth(100)
			ply.SetHealth(100)
		}
	}

	// TODO: unique track for mafia start?
	if (config.music > 0) {
		EZTrack([TRACK_BLIZZARD_METAL, TRACK_BLIZZARD][config.music - 1])
	}
}

::AnswerPhone <- function() {
	EntFire("phone_glow", "SetGlowDisabled")
	EntFire("phone_glow", "Kill")
	EntFire("phone_receiver", "Disable")
	EntFire("phone_ring", "StopSound")
	EntFire("phone_pickup", "PlaySound")
	EntFire("phone_call_" + CurLevel, "PlaySound")
	EntFire("phone_button", "Lock")
	EntFire("start_door", "Unlock")
	EntFire("start_door", "SetBreakable")
	EntFire("start_door", "Open", "", 0.5)
	local t = Levels[CurLevel].callDuration
	EntFire("phone_pickup", "PlaySound", "", t)
	EntFire("phone_receiver", "Enable", "", t)
}

::CheckForStart <- function() {
	if (STARTED) {
		return
	}

	local mins = Entities.FindByName(null, "start_room_mins").GetOrigin()
	local maxs = Entities.FindByName(null, "start_room_maxs").GetOrigin()

	local ply = null
	while (ply = Entities.Next(ply)) {
		if (ply.GetClassname() != "player" || ply.GetTeam() != 3) {
			continue
		}

		if (ply.GetHealth() <= 0) {
			return
		}

		local pos = ply.GetOrigin()
		if (pos.x < mins.x || pos.y < mins.y || pos.x > maxs.x || pos.y > maxs.y) {
			return
		}
	}

	::STARTED = true

	EntFire("car_start", "PlaySound")
	EntFire("garage", "Open")

	if (CurLevel == LEVEL_PRISON) {
		EntFire("cop_flash_maker", "ForceSpawn")
		EntFire("fade_copflash", "Fade", "", 1.67)
		EntFire("script", "RunScriptCode", "StartLevel()", 3.5)
	} else {
		EntFire("fade_levelstart", "Fade")
		EntFire("script", "RunScriptCode", "StartLevel()", 2.0)
	}
}

::Teleport <- function(ply, exitname) {
	local exit = Entities.FindByName(null, exitname)
	if (exit == null)
		return
	local a = exit.GetAngles()
	ply.SetOrigin(exit.GetOrigin())
	ply.SetAngles(a.x, a.y, a.z)
}

::TeleportAll <- function(exitname) {
	local exit = Entities.FindByName(null, exitname)
	if (exit == null)
		return
	local a = exit.GetAngles()
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player")) {
		ply.SetOrigin(exit.GetOrigin())
		ply.SetAngles(a.x, a.y, a.z)
	}
}

::StartMafiaLevel <- function() {
	EntFire("fade_levelstart", "Fade")
	EntFire("office_dbldoor_right", "SetGlowDisabled")
	EntFire("office_dbldoor_left", "SetGlowDisabled")
	EntFire("club_van_col", "Break")
	EntFire("script", "RunScriptCode", "BuildMafiaLoadouts()", 1.9)
	EntFire("script", "RunScriptCode", "StartLevel()", 2.0)
	EntFire("hud_mafia0", "Kill")
	EntFire("hud_mafia1", "Kill")
}

::BuildMafiaLoadouts <- function() {
	local ent = null
	while (ent = Entities.Next(ent)) {
		if (LivingCT(ent) && ent.ValidateScriptScope()) {
			ent.GetScriptScope().mafia_loadout <- ["item_assaultsuit"]
		}
	}
	while (ent = Entities.Next(ent)) {
		local cls = ent.GetClassname()
		if (cls.len() > 7 && cls.slice(0, 7) == "weapon_") {
			local owner = ent.GetOwner()
			if (owner != null && owner.GetTeam() == 3 && owner.ValidateScriptScope()) {
				owner.GetScriptScope().mafia_loadout.push(cls)
			}
		}
	}
}

::StartLevel <- function() {
	::CurWave = 0
	local lvl = Levels[CurLevel]
	EntFire("wave_*", "SetDisabled")
	EntFire("wave_" + lvl.id + "_1", "SetEnabled")
	EntFire("garage", "Close")
	EntFire("start_door", "Close")
	EntFire("start_door", "Lock")
	ShowHUD("setting", lvl.setting + "\n" + (CurLevel == LEVEL_PRISON ? "Union County" : "Miami") + ", Florida")

	if (config.music > 0) {
		EZTrack(lvl.tracks[config.music - 1])
	}

	local spawned_coke = false
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingCT(ply)) {
			Teleport(ply, "levelstart_" + (CurLevel == LEVEL_MAFIA ? "club" : lvl.id) + "_" + ((ply.entindex() - 1) % 6))
			if (CurLevel == LEVEL_MAFIA) {
				GivePlayerModel(ply, MAFIA_MODELS)
				if (ply.ValidateScriptScope()) {
					local ss = ply.GetScriptScope()
					if ("mafia_loadout" in ss) {
						local equip = Entities.CreateByClassname("game_player_equip")
						equip.__KeyValueFromInt("spawnflags", 3)
						foreach (wep in ss.mafia_loadout) {
							equip.__KeyValueFromInt(wep, 999)
						}
						EntFireByHandle(equip, "Use", "", 0, ply, null)
						EntFireByHandle(equip, "Kill", "", 0.1, null, null)
					}
				}
			} else {
				local knife = GetKnife(ply)
				if (CurLevel == LEVEL_PRISON) {
					GivePlayerModel(ply, PRISONER_MODELS)
					EntFire("equip_empty", "Use", "", 0, ply)
					EntFire("speedmod", "ModifySpeed", "1.0", 0, ply)
				} else {
					GiveKnife(ply, knife)
					if (knife == "falchion" && !spawned_coke) {
						EntFire("carcoke_template", "ForceSpawn")
						spawned_coke = true
					}
				}
				if (knife == "ghost") {
					EntFire("book_" + lvl.id, "SetGlowEnabled")
				}
			}
			if (ply.GetHealth() < 100) {
				ply.SetHealth(100)
			}
		}
	}

	::Score <- {
		Bonuses = [],
		WeaponsUsed = {},
		Total = 0
	}
	::COMBO = 0
	::COMBO_TIME = -3
	::ALL_HEADSHOTS = true
	::TIME_START = Time()
	::SINKS_RUNNING = 0
	::BECAME_GUARDS = false // bruh

	// omg bruh
	::STARTED = true

	EntFire("script", "RunScriptCode", "SpawnFirstEnemies(" + lvl.firstEnemies + ")", 0.1)

	if (CurLevel == LEVEL_PRISON) {
		EntFire("prison_shiv_model", "SetGlowEnabled")
	} else if (CurLevel == LEVEL_MAFIA) {
		EntFire("club_car", "Disable")
		EntFire("club_car", "DisableCollision")
	} else {
		EntFire("weapon_knife", "AddOutput", "classname weapon_knifegg")
		if (CurLevel == LEVEL_HOUSE) {
			EntFire("office_dbldoor_right", "Lock")
			EntFire("office_dbldoor_right", "SetUnbreakable")
			EntFire("office_dbldoor_left", "SetUnbreakable")
			EntFire("club_car", "Disable")
			EntFire("club_car", "DisableCollision")
		} else if (CurLevel == LEVEL_OFFICE) {
			EntFire("office_windowblocker", "Kill")
			EntFire("office_recroom_clean", "Kill")
			EntFire("office_secdoor_trigger", "Enable")
			EntFire("office_boss", "Kill")
			EntFire("office_boss_controller", "Kill")
			EntFire("office_boss_chair", "EnableMotion")
			EntFire("house_frontdoor", "Lock")
			EntFire("house_frontdoor", "SetUnbreakable")
		} else if (CurLevel == LEVEL_CLUB) {
			EntFire("mafia_van", "Disable")
			EntFire("mafia_van", "DisableCollision")
		}
	}

	// idfk
	ScriptCoopResetRoundStartTime()
}

::GetInCar <- function() {
	if (!STARTED) {
		return
	}
	if (CurLevel == LEVEL_OFFICE) {
		EntFire("office_sirenloop", "FadeOut", "1")
	}
	EntFire("fade_levelstart", "Fade")
	EntFire("car_start", "PlaySound")
	if (config.music > 0) {
		EZTrack(TRACK_DUST)
	}
	::STARTED <- false
	::TIME_END = Time()
	::TIME_TAKEN = TIME_END - TIME_START
	EntFire("script", "RunScriptCode", "LevelComplete()", 2)
}

::LevelComplete <- function() {
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (ply.GetClassname() == "player" && ply.GetTeam() == 3) {
			local hp = ply.GetHealth()
			if (hp > 0) {
				if (hp == 100) {
					AddBonus("Not a Scratch", 200)
				} else if (hp < 10) {
					if (hp == 1) {
						AddBonus("Skin of Your Teeth", 400)
					} else {
						AddBonus("Close Call", 100)
					}
				}
			}
			if (CurLevel != LEVEL_MAFIA) {
				local knife = Knives[GetKnife(ply)]
				if (knife[2] != 0) {
					AddBonus(knife[0] + " " + (knife[2] > 0 ? "Bonus" : "Penalty"), knife[2])
				}
			}
		}
	}
	for (local i = 0; i < SINKS_RUNNING; i++) {
		AddBonus("Wet Bandit", 100)
	}
	if (ALL_HEADSHOTS) AddBonus("Mr. Wick", 1000)
	::CurWave = 0
	EntFire("spawns_start", "SetEnabled")
	EntFire("spawns_restart", "SetDisabled")
	TeleportAll("score_tp")
	::SCORE_INDEX = 0
	::PRINT_SCORES = true
}

::GiveUp <- function() {
	TeleportAll("start_tp")
}

::GoHome <- function() {
	if (config.dreams) {
		EntFire("fade_levelstart", "Fade")
		EntFire("script", "RunScriptCode", "FallAsleep()", 2.0)
	} else {
		NextDay()
	}
}

::NextDay <- function() {
	CycleLevel(1)
	EntFire("round_end", "EndRound_Draw", "0")
}

::FallAsleep <- function() {
	if (config.music > 0) {
		EZTrack(TRACK_SILVERLIGHTS)
	}
	TeleportAll("dream_tp")
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingCT(ply)) {
			EntFire("equip_empty", "Use", "", 0, ply)
		}
	}
	if (CurLevel == LEVEL_PRISON) {
		EntFire("dream_guy0", "Kill")
		EntFire("dream_guy2", "Kill")
		EntFire("dream_mask0", "Kill")
		EntFire("dream_mask2", "Kill")
	}
}

::StartDream <- function() {
	local dream = DREAMS[CurLevel]
	local n = dream.len()
	for (local i = 0; i < n; i++) {
		local t = i * 2
		if (dream[i][0] == -1 && dream[i - 1][0] != -1) {
			EntFire("dream_light" + dream[i - 1][0], "TurnOff", "", t)
		} else {
			if (i > 0 && dream[i - 1][0] != dream[i][0]) {
				EntFire("dream_light" + dream[i - 1][0], "TurnOff", "", t)
			}
			EntFire("dream_light" + dream[i][0], "TurnOn", "", t)
			EntFire("hud_dream" + dream[i][0], "SetText", dream[i][1], t)
			EntFire("hud_dream" + dream[i][0], "Display", "", t)
		}

		if (dream[i].len() > 2) {
			local g = dream[i][2]
			EntFire("dream_guy" + g, "Kill", "", t)
			// EntFire("dream_mask" + g, "EnableMotion", "", t) // FIXME
			EntFire("dream_mask" + g, "Kill", "", t)
			EntFire("dream_fade" + g, "Fade", "", t)
			EntFire("book_snd", "Pitch", "" + (100 - 20 * g), t)
		}
	}
	local ft = n * 2
	EntFire("dream_light" + dream[n - 1][0], "TurnOff", "", ft)
	EntFire("script", "RunScriptCode", "NextDay()", ft)
	EntFire("round_end", "EndRound_Draw", "0", ft)
}

::UpdateBedGlow <- function() {
	EntFire("start_beds", "SetGlowColor", config.dreams ? "0 255 0" : "255 0 0")
}

::ToggleDreams <- function() {
	::config.dreams = !config.dreams
	Chat("\xC DREAM SEQUENCES:" + (config.dreams ? "\x6 ON" : "\x7 OFF"))
	UpdateBedGlow()
}

::ToggleRespawns <- function() {
	::config.respawns = !config.respawns
	ScriptCoopMissionSetDeadPlayerRespawnEnabled(config.respawns)
	Chat("\xC PLAYER RESPAWNING:" + (config.respawns ? "\x6 ON" : "\x7 OFF"))
	EntFire("whiteboard_respawns_checkbox", "AddOutput", "texframeindex " + (config.respawns ? 2 : 0))
}

::TryRespawnPlayers <- function() {
	if (true) {
		printl("Called TryRespawnPlayers but we don't used that function anymore!")
		return
	}
	if (!config.respawns) {
		return
	}
	ScriptCoopMissionRespawnDeadPlayers()
	EntFire("script", "RunScriptCode", "TeleportRespawnedPlayers()", 0.1)
}

::TeleportRespawnedPlayers <- function() {
	local living_players = []
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingCT(ply) && ply.GetOrigin().x < 0) {
			living_players.push(ply)
		}
	}
	if (living_players[0] != null) {
		local i = 0
		while (ply = Entities.Next(ply)) {
			if (LivingCT(ply) && ply.GetOrigin().x > 0) {
				ply.SetOrigin(living_players[i % living_players.len()].GetOrigin())
				i++
			}
		}
	}
}

::ComboLock <- function(i, n) {
	::config.combolock[i] = (config.combolock[i] + 10 + n) % 10
	EntFire("combolock_digit" + i, "AddOutput", "texframeindex " + config.combolock[i])
	if (CheckComboLock()) {
		Chat("\xC Bonus chapter unlocked! :]")
		if (!LOCKED_IN) {
			SetLevel(LEVEL_MAFIA)
		}
	}
}

::CheckComboLock <- function() {
	if (config.combolock[0] == 7 && config.combolock[1] == 7 && config.combolock[2] == 5 && config.combolock[3] == 0) {
		EntFire("combolock_buttons", "Kill")
		::LEVEL_MAX = 5
		return true
	} else if (!MET_SPY && config.combolock[0] == 1 && config.combolock[1] == 1 && config.combolock[2] == 1 && config.combolock[3] == 1) {
		::MET_SPY = true
		EntFire("meet_the_spy", "PlaySound")
	}
	return false
}

////////////////////////////////////////////////////////////////////////////////
////////// UNIQUE //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::KnifeActive <- function(knife) {
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingCT(ply) && GetKnife(ply) == knife && ply.ValidateScriptScope()) {
			local ss = ply.GetScriptScope()
			if (("spawnedAfterStart" in ss) && !ss.spawnedAfterStart) {
				return true
			}
		}
	}
	return false
}

::PickupBriefcase <- function() {
	EntFire("briefcase", "Kill")
	EntFire("briefcase_button", "Kill")
	EntFire("house_end", "Enable")
	EntFire("level_complete", "PlaySound")
	if (config.music > 0) {
		EZTrack(TRACK_DRONE)
	}
}

::PickupCrowbar <- function() {
	EntFire("house_crowbar", "Kill")
	EntFire("house_crowbar_button", "Kill")
	EntFire("house_manhole", "Unlock")
	if (KnifeActive("ghost")) {
		EntFire("house_manhole_cover", "SetGlowEnabled")
	}
}

::OpenManhole <- function() {
	TryRespawnPlayers()
	EntFire("house_manhole_cover", "SetGlowDisabled")
	EntFire("sewer_open", "PlaySound")
	if (config.music > 0) {
		EZTrack(TRACK_WERESORRY)
	}
}

::SpawnSewerClones <- function() {
	::SewerLoadouts <- {}
	local count = 0
	local ent = null
	while (ent = Entities.Next(ent)) {
		local cls = ent.GetClassname()
		if (cls == "player" && ent.GetTeam() == 3 && ent.GetHealth() > 0) {
			count++
		} else if (cls.len() > 7 && cls.slice(0, 7) == "weapon_") {
			local owner = ent.GetOwner()
			if (owner != null && owner.GetTeam() == 3) {
				local i = owner.entindex()
				if (i in SewerLoadouts) {
					::SewerLoadouts[i].weps.push(cls)
				} else {
					::SewerLoadouts[i] <- {mdl = owner.GetModelName(), weps = [cls]}
				}
			}
		}
	}
	if (CurLevel == LEVEL_MAFIA) {
		count++
	}
	SpawnNextWave(count)
	EntFire("script", "RunScriptCode", "EquipSewerClones()", 1.2)
}

::EquipSewerClones <- function() {
	local loadouts = []
	foreach (ldt in SewerLoadouts) {
		loadouts.push(ldt)
	}
	local enemy_index = 0
	local ent = null
	while (ent = Entities.Next(ent)) {
		local cls = ent.GetClassname()
		if (cls == "player" && ent.GetTeam() == 2 && ent.GetHealth() > 0 && ent.GetModelName() != "models/player/custom_player/legacy/tm_jungle_raider_varianta.mdl") {
			ent.SetModel(loadouts[enemy_index].mdl)
			local equip = Entities.CreateByClassname("game_player_equip")
			equip.__KeyValueFromInt("spawnflags", 3)
			equip.__KeyValueFromInt("item_assaultsuit", 1)
			foreach (wep in loadouts[enemy_index].weps) {
				equip.__KeyValueFromInt(wep, 1)
			}
			EntFireByHandle(equip, "Use", "", 0, ent, null)
			EntFireByHandle(equip, "Kill", "", 0.1, null, null)
			enemy_index++
			if (!(enemy_index in loadouts)) {
				break
			}
		}
	}
}

::PickupShiv <- function(ply) {
	// bot might accidentally run over it
	if (ply.GetTeam() != 3) {
		return
	}

	// manually destroy knife if we have one already
	local wep = null
	while (wep = Entities.FindByClassname(wep, "weapon_*")) {
		if (wep.GetOwner() == ply) {
			local cls = wep.GetClassname()
			if (cls == "weapon_knife" || cls == "weapon_knifegg") {
				wep.Destroy()
			}
		}
	}

	EntFire("equip_shiv", "Use", "", 0, ply)
	EntFire("weapon_knife", "AddOutput", "classname weapon_knifegg")
}

::PickupBook <- function() {
	local lvl = Levels[CurLevel]
	Chat("\x3 " + lvl.hint)
	local id = CurLevel == LEVEL_MAFIA ? (STARTED ? "club" : "office") : lvl.id
	local book = Entities.FindByName(null, "book_" + id)
	if (book != null) {
		book.SetModel("models/props/de_nuke/hr_nuke/nuke_office_desk/nuke_office_desk_notebook.mdl")
		EntFire("book_" + id, "SetGlowDisabled")
	}
	EntFire("book_snd", "Pitch", "100")
}

::WardenKeyboard <- function() {
	EntFire("warden_keyboard_model", "SetGlowDisabled")
	EntFire("warden_keyboard_snd", "PlaySound")
	EntFire("prison_alarm", "PlaySound")
	EntFire("prison_light", "TurnOff")
	EntFire("prison_light_alarm", "TurnOn")
	EntFire("prison_wardengates", "Unlock", "", 2)
	EntFire("prison_wardengates", "Open", "", 2)
	SpawnNextWave(7)
}

::BecomeGuard <- function(ply) {
	if (ply.GetTeam() != 3 || ply.GetHealth() <= 0) {
		return
	}
	local mdl = GUARD_MODELS[(ply.entindex() - 1) % GUARD_MODELS.len()]
	if (ply.GetModelName() == mdl) {
		return
	}
	EntFire("equip_guard", "Use", "", 0, ply)
	EntFire("fade_guard", "Fade", "", 0, ply)
	ply.SetModel(mdl)
	if (!BECAME_GUARDS) {
		::BECAME_GUARDS = true
		TryRespawnPlayers()
		EntFire("script", "RunScriptCode", "SpawnNextWave(8)")
		EntFire("prison_wardengates", "Close")
		EntFire("prison_wardengates", "Lock")
		EntFire("prison_secret_armory_door", "Unlock")
		if (KnifeActive("ghost")) {
			EntFire("prison_secret_armory_door", "SetGlowEnabled")
		}
	}
}

::OpenArmoryDoor <- function() {
	EntFire("prison_guardrag", "EnableMotion")
	EntFire("prison_breakwall", "Break")
	// fuck it
	GibHelmetPlox()
	EntFire("script", "RunScriptCode", "GibHelmetPlox()", 1.0)
}

::GibHelmetPlox <- function() {
	local m4 = null
	while (m4 = Entities.FindByClassname(m4, "weapon_m4a1")) {
		local owner = m4.GetOwner()
		if (owner != null && owner.GetTeam() == 2 && owner.GetHealth() > 0) {
			owner.__KeyValueFromInt("body", 6)
		}
	}
}

::GibHelmetsPlox <- function(b = true) {
	local bot = null
	while (bot = Entities.Next(bot)) {
		if (bot.GetClassname() == "player" && bot.GetTeam() == 2 && bot.GetHealth() > 0 && bot.GetModelName() != "models/player/custom_player/legacy/tm_phoenix_heavy.mdl") {
			bot.__KeyValueFromInt("body", b ? 6 : 0)
		}
	}
}

::EscapePrison <- function() {
	Chat("\xC We're evacuating survivors, get the fuck out of here!")
	// EntFire("prison_blastdoor_*", "Open")
}

::DoCoke <- function(ply) {
	local hp = ply.GetHealth() + 30
	if (hp > ply.GetMaxHealth()) {
		ply.SetMaxHealth(hp)
	}
	ply.SetHealth(hp)
	AddBonus("Booger Sugar", 100)
}

::Coke <- function(ent) {
	ent.Destroy() // bruh
/*
	local pos = ent.GetOrigin()
	pos.z -= 1
	ent.SetAbsOrigin(pos)
*/
}

::OpenCEODoor <- function() {
	if (CurLevel != LEVEL_MAFIA) {
		return
	}

	MafiaConvo()
}

::MafiaConvo <- function() {
	local convo = [
		[0, "Ah! If it isn't my finest man!"],
		[0, "One sec, I'm about to beat this."],
		[0, "..."],
		[0, "..."],
		[0, "Ok, what's the business?"],
		[1, "Boss, I... look..."],
		[1, "We've known each other for a while now..."],
		[0, "Right, ok. Don't sugar coat it."],
		[1, "I just... I think I want out."],
		[0, "..."],
		[0, "Sure."],
		[1, "..."],
		[1, "Really?"],
		[0, "Yeah."],
		[0, "You want out? You're out."],
		[0, "There's only one thing I need from you before you go."],
		[0, "We have an issue. With the Cartel."],
		[1, "I thought we wiped out the Cartel, boss."],
		[0, "Yeah, so did I. But they're back."],
		[0, "I found a whole den of those pests."],
		[0, "They're holed up in a strip club on NE boulevard."],
		[0, "I need you to take care of it."],
		[0, "This should be easy for you. Just make them go away."],
		[0, "Then, you're off the hook. Deal?"],
		[1, "You got it, boss. Consider it done."],
		[0, "Alright. Give me a call if you ever want back in."]
	]
	local n = convo.len()
	for (local i = 0; i < n; i++) {
		local t = i * 2
		EntFire("hud_mafia" + convo[i][0], "SetText", convo[i][1], t)
		EntFire("hud_mafia" + convo[i][0], "Display", "", t)
	}
	local ft = n * 2
	EntFire("mafia_leave_trigger", "Enable")
	EntFire("office_dbldoor_right", "SetGlowEnabled")
	EntFire("office_dbldoor_left", "SetGlowEnabled")
}

////////////////////////////////////////////////////////////////////////////////
////////// CO-OP ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::CurWave <- 0

function RoundInit() {
	// printl("RoundInit")
	::CurWave = 0

	SendToConsoleServer("mp_coopmission_bot_difficulty_offset " + config.difficulty)
	ScriptCoopSetBotQuotaAndRefreshSpawns(0)
	ScriptCoopMissionSetDeadPlayerRespawnEnabled(config.respawns) // w0t??????
}

function OnMissionCompleted() {}
function OnRoundLostKilled() {
	EntFire("spawns_start", "SetDisabled")
	EntFire("spawns_restart", "SetEnabled")
	::CurWave = 0
}
function OnRoundLostTime() {
	::CurWave = 0
}

function OnRoundReset() {
	// printl("OnRoundReset")
	RoundInit()
}

function OnSpawnsReset() {
	// printl("OnSpawnsReset")
	EntFire("wave_*", "SetDisabled")
	EntFire("wave_" + Levels[CurLevel].id + "_1", "SetEnabled")
	// EntFire("spawns_start", "SetEnabled")
	// EntFire("spawns_restart", "SetDisabled")
}

function SpawnFirstEnemies(amount) {
	// printl("Spawning " + amount + " enemies... (FIRST)")
	ScriptCoopMissionSpawnFirstEnemies(amount)
	CurWave++
}

function SpawnNextWave(amount) {
	// printl("Spawning " + amount + " enemies...")
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (LivingCT(ply) && ply.GetHealth() < 100) {
			ply.SetHealth(100)
		}
	}
	ScriptCoopMissionSpawnNextWave(amount)
	CurWave++
}

function OnWaveCompleted() {
	// printl("Wave " + CurLevel + " -> " + CurWave + " completed!")
	EntFire("wave_*", "SetDisabled")
	EntFire("wave_" + Levels[CurLevel].id + "_" + (CurWave + 1), "SetEnabled")

	if ("waves" in Levels[CurLevel] && (CurWave - 1) in Levels[CurLevel].waves) {
		Levels[CurLevel].waves[CurWave - 1]()
	}

	// TryRespawnPlayers()
}

////////////////////////////////////////////////////////////////////////////////
////////// KNIVES //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::Knives <- {
	["none"] = ["Olivia", "No effect", 0],
	["bayonet"] = ["Michaela", "Twin sisters", 0],
	["m9_bayonet"] = ["Scarlet", "Something robust, precise", -500],
	["karambit"] = ["Dixie", "No reloads", 400],
	["tactical"] = ["Kolbey", "Start with nailgun", 0],
	["butterfly"] = ["Jackie", "Walk fast, no armor", 600],
	["survival_bowie"] = ["Demorah", "Start with breach charges", 0],
	["css"] = ["Angela", "Color filter", 0],
	["ghost"] = ["Rasmine", "Eye for secrets", 0],
	["gut"] = ["Lu-Anne", "Beginnen sie mit Akkuschrauber", -200],
	["gypsy_jackknife"] = ["Cassidy", "Start wth revolver", 0],
	["falchion"] = ["Toni", "Blow on the bonnet", 0],
	["axe"] = ["Jacyn", "Axe-swinging slasher", 0],
	["outdoor"] = ["Ramona", "Firepower", -800],
	["ursus"] = ["Zara", "Longer combo window", 0],
	["fists"] = ["Ali", "Who needs guns?", 200],
	["stiletto"] = ["Cassandra", "Blinded by the light", 0, function(ply) {
		EntFire("equip_flash", "Use", "", 0, ply)
	}],
	["push"] = ["Sari", "Throwing knives", 0, function(ply) {
		EntFire("equip_decoy", "Use", "", 0, ply)
		EntFire("equip_decoy", "Use", "", 0, ply)
	}],
	["canis"] = ["Theresa", "Electrical engineering", 0, function(ply) {
		EntFire("equip_taser", "Use", "", 0.1, ply)
	}],
	["cord"] = ["Cesarine", "CZ-PZ", 0],
	["widowmaker"] = ["Shauna", "AWP around the clock", -800],
}

::GiveKnife <- function(ply, name) {
	EntFire("equip_" + name, "Use", "", 0, ply)
	EntFire("weapon_" + (name == "axe" ? "melee" : (name == "fists" ? name : "knife")), "AddOutput", "classname weapon_knifegg")
	EntFire("speedmod", "ModifySpeed", name == "butterfly" ? 1.1 : 1.0, 0.0, ply)

	if (3 in Knives[name]) {
		Knives[name][3](ply)
	}

	// this check is different from KnifeActive because we don't care about health 
	local colorfilter = false
	local ply = null
	while (ply = Entities.Next(ply)) {
		if (ply.GetClassname() == "player" && ply.GetTeam() == 3 && GetKnife(ply) == "css") {
			colorfilter = true
			break
		}
	}
	EntFire("cc_noir", (colorfilter ? "En" : "Dis") + "able", "", 0, ply)
	EntFire("cc_default", (colorfilter ? "Dis" : "En") + "able", "", 0, ply)
}

::SetKnife <- function(ply, name) {
	if (ply.ValidateScriptScope()) {
		ply.GetScriptScope().knife <- name
	}

	GiveKnife(ply, name)
	ShowHUD("knife", Knives[name][0] + "\n" + Knives[name][1], ply)
}

::GetKnife <- function(ply) {
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if ("knife" in ss) {
			return ss.knife
		}
	}
	return "none"
}

////////////////////////////////////////////////////////////////////////////////
////////// MUSIC ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

::LoopNumber <- 0
::CurrentTrack <- null

::EZTrack <- function(track) {SetTrack(track[0], track[1])}

::SetTrack <- function(name, duration) {
	::LoopNumber++
	if (CurrentTrack != null && CurrentTrack != name) {
		EntFire("track_" + CurrentTrack, "Volume", "0")
	}
	::CurrentTrack <- name
	EntFire("track_" + CurrentTrack, "PlaySound")
	EntFire("track_" + CurrentTrack, "Volume", TRANSLATE_VOLUME[config.volume])
	EntFire("script", "RunScriptCode", "RefreshTrack(\"" + name + "\", " + duration + ", " + LoopNumber + ")", duration)
}

::ChangeVolume <- function(amt) {
	local vol = config.volume + amt
	if (vol < 0 || vol > 7) {
		return
	}
	::config.volume = (config.volume + amt)
	if (CurrentTrack != null && config.music > 0) {
		EntFire("track_" + CurrentTrack, "Volume", TRANSLATE_VOLUME[config.volume])
		::LoopNumber++
	}
	EntFire("whiteboard_volume_display", "AddOutput", "texframeindex " + config.volume)
}

::RefreshTrack <- function(name, duration, lp) {
	if (lp == LoopNumber && CurrentTrack == name) {
		SetTrack(name, duration)
	}
}

::UpdateJukeboxGlow <- function() {
	local clrs = ["255 0 0", "0 0 255", "0 255 0"]
	local clr = clrs[config.music]
	EntFire("jukebox_mdl", "SetGlowColor", clr)
	EntFire("jukebox_body", "SetGlowColor", clr)
}

::ToggleMusic <- function() {
	::config.music = (config.music + 1) % 3
	if (config.music > 0) {
		local snd = [TRACK_BLIZZARD_METAL, TRACK_BLIZZARD]
		EZTrack(snd[config.music - 1])
	} else if (CurrentTrack != null) {
		EntFire("track_" + CurrentTrack, "Volume", "0")
	}
	::LoopNumber++
	Chat("\xC MUSIC:" + ["\x7 OFF", "\xB METAL", "\x6 DEFAULT"][config.music])
	UpdateJukeboxGlow()
}
