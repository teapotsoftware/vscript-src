
IncludeScript("butil")

::STAGE_START <- 0
::STAGE_CLEAN <- 1
::STAGE_WHEAT <- 2
::STAGE_DOUGH <- 3
::STAGE_SAUCE <- 4
::STAGE_CHEESE <- 5
::STAGE_MEAT <- 6
::STAGE_COOK <- 7
::STAGE_DELIVERY <- 8
::STAGE_END <- 9

::CLASS_SOLDIER <- 0
::CLASS_SUPPORT <- 1
::CLASS_SNIPER <- 2
::CLASS_SNEAKO <- 3

::CFG_FIRST_TASK <- 0
::CFG_LAST_TASK <- 1
::CFG_TIME_LIMIT <- 2
::CFG_RESPAWN_TIME <- 3
::CFG_COMP_MODE <- 4

// Competitive rules:
//   - Stopwatch mode is enabled
//   - Cheese progress cannot be reverted by CTs
//   - Instead of dropping pepperoni, killing
//       cows immediately adds to the meat counter
::USE_COMPETITIVE_RULES <- function() {return CONFIG[CFG_COMP_MODE] == 1}

if (!("STOPWATCH" in getroottable())) {
	::STOPWATCH <- {
		IS_SECOND_ROUND = false,
		START_TIME = -1,
		TIME_TO_BEAT = -1,
		CLOCK_ACTIVE = false
	}
}

::StartClock <- function() {
	::STOPWATCH.START_TIME = Time()
	::STOPWATCH.CLOCK_ACTIVE = true
}

::StopClock <- function() {
	::STOPWATCH.TIME_TO_BEAT = Time() - STOPWATCH.START_TIME
	::STOPWATCH.CLOCK_ACTIVE = false
}

::GetNumPlayers <- function() {
	local cnt = {
		[T] = 0,
		[CT] = 0
	}
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
		if (ply.GetTeam() in cnt)
			cnt[ply.GetTeam()]++
	return max(cnt[T], cnt[CT])
}

::GetNumTPlayers <- function() {
	local cnt = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
		if (ply.GetTeam() == T)
			cnt++
	return cnt
}

::StageData <- [
	{
		name = "Phone",
		task = ["Answer phone", "Await instructions"],
		loadout = [
			["item_kevlar", "weapon_bayonet"],
			["item_kevlar", "weapon_knife_m9_bayonet"]
		],
		start = function() {
			// phone ringing
			EntFire("phone_sprite", "showsprite")
			EntFire("script", "runscriptcode", "StageEvent(STAGE_START, 0)", 8)

			// randomize wheat
			local ent = null
			while (ent = Entities.FindByName(ent, "wheat_bushel")) {
				ent.SetOrigin(ent.GetOrigin() + Vector(RandomFloat(-20, 20), RandomFloat(-20, 20), RandomFloat(-4, 0)))
				ent.SetAngles(0, RandomFloat(-180, 180), RandomFloat(-10, 10))
			}

			// reset spawns
			EntFire("spawns_default", "SetEnabled")
			EntFire("spawns_delivery", "SetDisabled")

			// disable the safety teleports after a short delay
			// they're there in case the old spawns are still used for the first spawn
			EntFire("safety_teleports", "Disable", "", 0.5)
		},
		events = [
			function(params) {
				EntFire("phone_ring", "playsound")
				EntFire("phone_button", "unlock")
			},
			function(params) {
				EntFire("phone_order", "playsound")
				EntFire("phone_ring", "stopsound")
				EntFire("phone_button", "lock")
				EntFire("phone_sprite", "color", "0 255 0")
				EntFire("phone_sprite", "hidesprite", "", 9)
				EntFire("script", "runscriptcode", "NextStage()", 9)
			}
		]
	},
	{
		name = "Cleaning",
		task = ["Clean restaurant", "Delay cleaning"],
		message = [
			"This joint is in no shape for customers. Let's clean up a little.",
			"If we delay our rival's delivery for 15 minutes, the pizza will be free."
		],
		loadout = [
			["item_kevlar", "weapon_bayonet"],
			["item_kevlar", "weapon_knife_m9_bayonet"]
		],
		same_loadout = true,
		start = function() {
			::PROG <- 0
			::MAX <- 0
			::LAST_PROG <- Time()
			local ent = null
			while (ent = Entities.FindByName(ent, "rubbish")) {
				ent.PrecacheScriptSound("Paintcan.ImpactSoft")
				::MAX++
			}
		},
		think = function() {
			if (Time() - LAST_PROG > 30) {
				::LAST_PROG <- Time()
				local ent = null
				while (ent = Entities.FindByName(ent, "rubbish")) {
					local mdl = ent.GetModelName()
					if (mdl == "models/props_junk/shoe001a.mdl") {
						ChatTeam(T, GRAY + "Hint: Keep your shoes off the counter, please!")
						break
					}
					else if (mdl == "models/props/de_inferno/goldfish.mdl" || mdl == "models/props_junk/garbage_carboard002a.mdl" || mdl == "models/props_junk/garbage128_composite001b.mdl") {
						ChatTeam(T, GRAY + "Hint: Make sure you clean the bathrooms!")
						break
					}
					else if (mdl == "models/props_junk/garbage_takeoutcarton001a.mdl" || mdl == "models/props_junk/garbage_sixpackbox01a_fullsheet.mdl") {
						ChatTeam(T, GRAY + "Hint: Remember to wipe down the tables!")
						break
					}
				}
				
				
			}
		},
		events = [
			function(params) {
				local ent = params[0]
				ent.EmitSound("Paintcan.ImpactSoft")
				ent.Destroy()
				::PROG++
				::LAST_PROG <- Time()
				ChatPrintTeam(T, " " + LIME + "Rubbish: " + PROG + "/" + MAX)
				if (PROG >= MAX)
					NextStage()
			}
		]
	},
	{
		name = "Wheat",
		task = ["Harvest wheat", "Protect wheat"],
		message = [
			"Looking peachy! Let's harvest some wheat from the fields.",
			"They're going to harvest some wheat for the dough. Fight them."
		],
		loadout = [
			["item_kevlar", "weapon_bayonet", "weapon_flashbang"],
			["item_kevlar", "weapon_knife_m9_bayonet"]
		],
		start = function() {
			::PROG <- 0
			::MAX <- 0
			local ent = null
			while (ent = Entities.FindByName(ent, "wheat_bushel"))
				::MAX++
		},
		events = [
			function(params) {
				local ent = params[0]
				if (ent.ValidateScriptScope()) {
					local ss = ent.GetScriptScope()
					if (!("wheat_health" in ss))
						ss.wheat_health <- Clamp(GetNumTPlayers() - 2, 1, 3)
					ss.wheat_health--
					if (ss.wheat_health < 1) {
						EntFireHandle(ent, "break")
						::PROG++
						ChatPrintTeam(T, " " + LIME + "Wheat: " + PROG + "/" + MAX)
						if (PROG >= MAX)
							NextStage()
					}
					else
						ent.EmitSound("Breakable.MatWood")
				}
			}
		]
	},
	{
		name = "Dough",
		task = ["Knead dough", "Waste time"],
		message = [
			"That's all the wheat. Now knead it into dough.",
			"Now they're kneading dough. Waste their time."
		],
		loadout = [
			["item_kevlar", "weapon_bayonet", "weapon_glock"],
			["item_kevlar", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_hegrenade"]
		],
		start = function() {
			::PROG <- 0
			::MAX <- 9
			EntFire("dough_mound_0", "enable")
		}
		events = [
			function(params) {
				::PROG++
				local cur = floor(PROG / 3)
				for (local i = 0; i < 4; i++)
					EntFire("dough_mound_" + i, ((i == cur) ? "en" : "dis") + "able")
				if (PROG >= MAX)
					NextStage()
			}
		]
	},
	{
		name = "Sauce",
		task = ["Grind sauce", "Defend grinder"],
		message = [
			"The dough's ready for some sauce. Hop in that grinder!",
			"The dough's done. Defend the sauce grinder!"
		],
		loadout = [
			["item_kevlar", "weapon_bayonet", "weapon_glock", "weapon_mac10"],
			["item_kevlar", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_mp9"]
		],
		start = function() {
			::PROG <- 0
			::MAX <- 1 + GetNumTPlayers() * 2
		},
		events = [
			function(params) {
				local ply = params[0]
				if (ply.GetTeam() == T) {
					::PROG++
					if (PROG >= MAX)
						NextStage()
				}
			}
		]
	},
	{
		name = "Cheese",
		task = ["Capture cheese", "Protect cheese"],
		message = [
			"That's enough sauce. Go grab some cheese from the basement.",
			"They're going to get cheese from the basement. Stop them!"
		],
		loadout = [
			["item_kevlar", "weapon_bayonet", "weapon_glock", "weapon_galilar"],
			["item_kevlar", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_famas"]
		],
		start = function() {
			::PROG <- 0
			::MAX <- 10 + GetNumTPlayers() * (USE_COMPETITIVE_RULES() ? 10 : 5)
			EntFire("cheese_timer", "enable")
		},
		events = [
			function(params) {
				local cheese_pos = Entities.FindByName(null, "cheese").GetOrigin()
				local cappers = 0
				local ply = null
				while (ply = Entities.FindByClassnameWithin(ply, "player", cheese_pos, 150)) {
					if (ply.GetHealth() > 0) {
						local team = ply.GetTeam()
						EntFire("cheese_hint_" + team, "showmessage", "", 0.0, ply)
						if (team == T)
							cappers++
						else if (team == CT && USE_COMPETITIVE_RULES())
							cappers--
					}
				}
				local newProg = Clamp(PROG + cappers, 0, MAX)
				if (PROG != newProg) {
					::PROG = newProg
					ChatPrintAll(" \x9 CHEESE PROGRESS")
					ChatPrintAll(" \x4" + LoopChar("■", PROG) + "\x7" + LoopChar("■", MAX - PROG))
					if (PROG >= MAX) {
						ChatPrintAll(" \x9 CHEESE CAPTURED!")
						NextStage()
					}
				}
			}
		]
	},
	{
		name = "Meat",
		task = ["Kill cows", "Protect cows"],
		message = [
			"Good cheese! Go kill some cows and collect their pepperoni.",
			"They got the cheese. Protect those cows!"
		],
		loadout = [
			["item_assaultsuit", "weapon_bayonet", "weapon_glock", "weapon_ak47"],
			["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_m4a1"]
		],
		start = function() {
			EntFire("cheese_timer", "disable")
			EntFire("cow_template", "forcespawn")
			::PROG <- 0
			::MAX <- 6
			::LAST_PROG <- Time()
		},
		think = function() {
			if (!USE_COMPETITIVE_RULES() && Time() - LAST_PROG > 40) {
				::LAST_PROG <- Time()

				local cows = 0
				local pep = 0
				local ent
				while (ent = Entities.Next(ent)) {
					if (ent.GetName() == "cows")
						cows++
					else if (ent.GetName() == "pepperoni")
						pep++
				}

				if (pep > cows) {
					ChatTeam(T, GRAY + "Hint: Did you forget to pick up pepperoni?")
				}
			}
		},
		events = [
			function(params) {
				local cow = params[0]
				if (cow.GetHealth() < 1800) {
					EntFireHandle(cow, "break")
					local pep = Entities.FindByNameNearest("pepperoni", cow.GetOrigin(), 100)
					if (pep != null) {
						if (USE_COMPETITIVE_RULES()) {
							pep.Destroy()
							::PROG++
							::LAST_PROG <- Time()
							ChatPrintTeam(T, " " + LIME + "Meat: " + PROG + "/" + MAX)
							if (PROG >= MAX)
								NextStage()
						} else {
							EntFireHandle(pep, "close")
						}
					}
					local labels = null
					while (labels = Entities.FindByNameWithin(labels, "cow_labels", cow.GetOrigin(), 100))
						labels.Destroy()
					::LAST_PROG <- Time()
				}
				local snd = Entities.FindByNameNearest("cow_hurt", cow.GetOrigin(), 100)
				if (snd != null)
					EntFireHandle(snd, "PlaySound")
			},
			function(params) {
				if (USE_COMPETITIVE_RULES())
					return

				local pep = params[0]
				pep.Destroy()
				::PROG++
				::LAST_PROG <- Time()
				ChatPrintTeam(T, " " + LIME + "Meat: " + PROG + "/" + MAX)
				if (PROG >= MAX)
					NextStage()
			}
		]
	},
	{
		name = "Cooking",
		task = ["Cook pizza", "Sabotage oven"],
		loadout = [
			["item_assaultsuit", "weapon_bayonet", "weapon_glock", "weapon_ak47", "weapon_hegrenade"],
			["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_m4a1"]
		],
		message = [
			"Ok, now it's cooking time! Throw grenades into the oven doors to cook.",
			"Now they're going to cook. Stop them!"
		],
		start = function() {
			EntFire("oven_door_timer", "enable")
			EntFire("oven_pizza_raw", "enable")
		},
		think = function() {
			local nade = null
			while (nade = Entities.FindByClassname(nade, "hegrenade_projectile")) {
				if (nade.ValidateScriptScope()) {
					if (!("checked_nade" in nade.GetScriptScope())) {
						nade.GetScriptScope().checked_nade <- true
						local owner = nade.GetOwner()
						if (owner != null)
							GiveWeaponNoStrip(owner, "weapon_hegrenade")
					}
				}
			}
		},
		events = [
			function(params) {
				for (local i = 1; i < 4; i++)
					EntFire("oven_door_" + i, "close")

				EntFire("oven_door_" + RandomInt(1, 3), "open", "", 2)
			},
			function(params) {
				MessageTeams(["The oven is on, keep going!", "Oh no, they turned on the oven!"])
				EntFire("oven_sound_ignite", "playsound")
				EntFire("oven_fire_small", "startfire", "0")
				EntFire("oven_smoke", "turnon")
			},
			function(params) {
				MessageTeams(["We're almost done cooking!", "They're almost done cooking!"])
				EntFire("oven_fire_big", "startfire", "0")
			},
			function(params) {
				MessageTeams(["We're done cooking!", "Shit! They finished cooking..."])
				EntFire("oven_sound_done", "playsound")
				EntFire("oven_fire_*", "Extinguish", "0")
				EntFire("oven_pizza_raw", "disable")
				EntFire("oven_pizza_cooked", "enable")
				EntFire("oven_smoke", "turnoff")
				EntFire("script", "runscriptcode", "NextStage()", 4)
			}
		]
	},
	{
		name = "Delivery",
		task = ["Deliver pizza", "Stop delivery"],
		message = [
			"Nice! The pizza's done. Now deliver it!",
			"They're done cooking. Stop them from delivering that pizza!"
		],
		start = function() {
			EntFire("oven_door_timer", "disable")
			EntFire("oven_pizza_cooked", "disable")
			EntFire("pizza_template", "forcespawn")

			// use loadout selection spawns for delivery
			EntFire("spawns_default", "SetDisabled")
			EntFire("spawns_delivery", "SetEnabled")

			// start as true to pass the carry check once at the start
			::PIZZA_CARRIED <- true
		},
		loadout = [
			["item_assaultsuit", "weapon_bayonet", "weapon_glock", "weapon_ak47", "weapon_hegrenade"],
			["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_m4a1", "weapon_hegrenade"]
		],
		think = function() {
			local c4 = Entities.FindByClassname(null, "weapon_c4")
			if (c4 != null) {
				local carried = c4.GetOwner() != null
				if (carried != PIZZA_CARRIED) {
					EntFire("pizza_dropped", (carried ? "Dis" : "En") + "ableDraw")
					EntFire("pizza_carried", (carried ? "En" : "Dis") + "ableDraw")
					::PIZZA_CARRIED <- carried
				}
			}
		},
		events = [
			function(params) {
				local ply = params[0]
				local c4 = null
				while (c4 = Entities.FindByClassname(c4, "weapon_c4"))
					if (c4.GetOwner() == ply) {
						NextStage()
						break
					}
			}
		]
	},
	{
		name = "End",
		task = ["", ""],
		start = function() {
			local pizzaDelivered = true

			if (USE_COMPETITIVE_RULES()) {
				if (STOPWATCH.IS_SECOND_ROUND) {
					if (Time() - STOPWATCH.START_TIME <= STOPWATCH.TIME_TO_BEAT) {
						EntFire("round_ender", "EndRound_TerroristsWin", "15")
					} else {
						EntFire("round_ender", "EndRound_CounterTerroristsWin", "15")
						pizzaDelivered = false
					}
				}

				// ghetto team swap
				Chat(GRAY + "Teams will swap in 10 seconds...")
				EntFire("script", "RunScriptCode", "SwapTeams()", 10)

				// stop clock after time logic
				StopClock()
				::STOPWATCH.IS_SECOND_ROUND = !STOPWATCH.IS_SECOND_ROUND
			} else {
				EntFire("round_ender", "EndRound_TerroristsWin", "10")
			}

			if (pizzaDelivered) {
				EntFire("pizza_delivered_radio", "playsound")
				EntFire("delivery_pizza_" + DELIVERY_NUM, "enable")
				EntFire("pizza_dropped", "kill")
				EntFire("pizza_carried", "kill")
			}
		},
		loadout = [
			[],
			[]
		]
	}
]

::SwapTeams <- function() {
	Chat("TEAMS SWAPPED")
	ForEachPlayerAndBot(function(ply) {
		local team = ply.GetTeam()
		if (team == T)
			ply.SetTeam(CT)
		else if (team == CT)
			ply.SetTeam(T)
	})
	SendToConsoleServer("mp_restartgame 1")
	SendToConsole("mp_restartgame 1")
}

::CfgData <- [
	{
		name = "First task",
		range = [0, 8],
		format = function(v) {return ::StageData[v].name},
		onChange = function(v) {
			if (v > CONFIG[CFG_LAST_TASK])
				AddConfig(CFG_LAST_TASK, 1)
		}
	},
	{
		name = "Last task",
		range = [0, 8],
		format = function(v) {return ::StageData[v].name},
		onChange = function(v) {
			if (v < CONFIG[CFG_FIRST_TASK])
				AddConfig(CFG_FIRST_TASK, -1)
		}
	},
	{
		name = "Time limit",
		range = [1, 30],
		format = function(v) {return v + " minute" + (v == 1 ? "" : "s")},
		onChange = function(v) {
			SendToConsoleServer("mp_roundtime " + v + ".25")
		}
	},
	{
		name = "Respawn time",
		range = [0, 20],
		format = function(v) {return v == 0 ? "Instant" : v + " second" + (v == 1 ? "" : "s")}
	},
	{
		name = "Competitive mode",
		range = [0, 1],
		format = function(v) {return "O" + (v == 0 ? "FF" : "N")},
		onChange = function(v) {
			EntFire("cfg_val4", "AddOutput", "color " + (v == 0 ? "255 0 0" : "0 255 0"))
		}
	}
]

::SetConfig <- function(i, v) {
	local data = CfgData[i]
	local val = Clamp(v, data.range[0], data.range[1])
	if (!(i in CONFIG) || CONFIG[i] != val) {
		::CONFIG[i] <- v
		Chat(LIME + data.name + WHITE + " has been changed to " + LIGHT_BLUE + data.format(val) + WHITE + ".")
		local label = Entities.FindByName(null, "cfg_val" + i)
		if (label != null)
			EntFireHandle(label, "AddOutput", "message " + data.format(val))
		if ("onChange" in data)
			data.onChange(v)
	}
}

::AddConfig <- function(i, v)
	SetConfig(i, CONFIG[i] + v)

if (!("CONFIG" in getroottable())) {
	::CONFIG <- {
		[CFG_FIRST_TASK] = STAGE_START,
		[CFG_LAST_TASK] = STAGE_DELIVERY,
		[CFG_TIME_LIMIT] = 15,
		[CFG_RESPAWN_TIME] = 7,
		[CFG_COMP_MODE] = 1,
	}
}

::ResetConfig <- function() {
	SetConfig(CFG_FIRST_TASK, STAGE_START)
	SetConfig(CFG_LAST_TASK, STAGE_DELIVERY)
	SetConfig(CFG_TIME_LIMIT, 15)
	SetConfig(CFG_RESPAWN_TIME, 7)
	SetConfig(CFG_COMP_MODE, 1)
}

::EndWarmup <- function()
	SendToConsole("mp_warmup_end")

::ClassLoadouts <- [
	[
		["item_assaultsuit", "weapon_bayonet", "weapon_glock", "weapon_ak47", "weapon_hegrenade"],
		["item_assaultsuit", "weapon_bayonet", "weapon_glock", "weapon_p90", "weapon_molotov", "weapon_flashbang", "weapon_flashbang"],
		["item_assaultsuit", "weapon_bayonet", "weapon_deagle", "weapon_awp"],
		["item_assaultsuit", "weapon_bayonet", "weapon_usp_silencer", "weapon_m4a1_silencer", "weapon_smokegrenade"]
	],
	[
		["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_m4a1", "weapon_hegrenade"],
		["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_hkp2000", "weapon_p90", "weapon_incgrenade", "weapon_flashbang", "weapon_flashbang"],
		["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_deagle", "weapon_awp"],
		["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_usp_silencer", "weapon_m4a1_silencer", "weapon_smokegrenade"]
	]
]

::PickClass <- function(ply, cls) {
	GiveLoadout(ply, ClassLoadouts[ply.GetTeam() - 2][cls])
	MeleeFixup()
	if (ply.ValidateScriptScope())
		ply.GetScriptScope().picked_class <- cls
}

::CURRENT_STAGE <- 0
::STAGE_PROGRESS <- 0

::MessageTeams <- function(message) {
	ChatPrintTeam(T, " " + LIME + message[0])
	ChatPrintTeam(CT, " " + RED + message[1])
}

::SetClockTime <- function(timeSeconds) {
	local intTime = ceil(timeSeconds).tointeger()
	local m = (intTime / 60)
	local s = (intTime % 60)
	local strM = m < 10 ? "0" + m : m.tostring()
	local strS = s < 10 ? "0" + s : s.tostring()
	EntFire("hud_clock", "SetText", strM + ":" + strS)
}

::UpdateHUD <- function() {
	local stage = StageData[CURRENT_STAGE]

	local ent = null
	while (ent = Entities.FindByClassname(ent, "player")) {
		local team = ent.GetTeam()
		if (team > 1 && "task" in stage && stage.task[team - 2] != "") {
			local hint = "hud_task_" + ent.GetTeam()
			EntFire(hint, "SetText", "Task: " + stage.task[team - 2])
			EntFire(hint, "Display", "", 0.0, ent)
		}

		if (USE_COMPETITIVE_RULES()) {
			if (STOPWATCH.CLOCK_ACTIVE) {
				local timeSeconds = Time() - STOPWATCH.START_TIME
				if (STOPWATCH.IS_SECOND_ROUND) {
					timeSeconds = STOPWATCH.TIME_TO_BEAT - timeSeconds
				}
				SetClockTime(timeSeconds)
			}
			EntFire("hud_clock", "Display", "", 0.0, ent)
		}
	}
}

::SetStage <- function(stage_index, prog = 0) {
	// end early if specified in config
	if (stage_index == CONFIG[CFG_LAST_TASK] + 1 && stage_index != STAGE_END) {
		SetStage(STAGE_END)
		return
	}

	::CURRENT_STAGE <- stage_index
	::STAGE_PROGRESS <- prog

	UpdateHUD()

	local stage = StageData[stage_index]

	if ("message" in stage)
		MessageTeams(stage.message)

	if ("start" in stage)
		stage.start()

	if (!("same_loadout" in stage)) {
		local ply = null
		while (ply = Entities.Next(ply))
			if (ply.GetClassname() == "player" && !(ply.ValidateScriptScope() && "in_enemy_spawn" in ply.GetScriptScope() && ply.GetScriptScope().in_enemy_spawn))
				GiveLoadout(ply, stage.loadout[ply.GetTeam() - 2])
	}

	MeleeFixup()
}

::NextStage <- function()
	SetStage(CURRENT_STAGE + 1)

::StageEvent <- function(stage, event, params = []) {
	if (CURRENT_STAGE != stage)
		return

	StageData[stage].events[event](params)
}

::LoopChar <- function(chr, amt) {
	local str = ""
	for (local i = 0; i < amt; i++)
		str += chr
	return str
}

::PlayerSpawned <- function(ply) {
	if (!("LOADED_PIZZA" in getroottable())) {
		SendToConsole("mp_do_warmup_offine 1")
		SendToConsole("mp_restartgame 1")
		SendToConsoleServer("mp_do_warmup_offine 1")
		SendToConsoleServer("mp_restartgame 1")
		::LOADED_PIZZA <- true
		return
	}

	if (ScriptIsWarmupPeriod()) {
		local warmupSpawn = Entities.FindByName(null, "warmup_spawn_" + ply.GetTeam())
		if (warmupSpawn != null) {
			ply.SetOrigin(warmupSpawn.GetOrigin())
			local a = warmupSpawn.GetAngles()
			ply.SetAngles(a.x, a.y, a.z)
		}

		GiveLoadout(ply, ["item_assaultsuit", "weapon_usp_silencer"])
		return
	}

	if (!ply.ValidateScriptScope())
		return

	local ss = ply.GetScriptScope()
	if ("needs_loadout" in ss && ss.needs_loadout) {
		ss.needs_loadout <- false
		GiveLoadout(ply, StageData[CURRENT_STAGE].loadout[ply.GetTeam() - 2])
		MeleeFixup()
	}
}

// formatted [floor, room]
::DeliveryRooms <- [
	[2, 3],
	[5, 2],
	[3, 4],
	[4, 3],
	[3, 1],
]

::IntroCam <- function(num, delay, movement_delay = 0.01) {
	local cam = "intro_cam" + num
	EntFire(cam, "enable", "", delay)
	EntFire(cam, "startmovement", "", delay + movement_delay)
}

OnPostSpawn <- function() {
	SendToConsoleServer("ammo_grenade_limit_flashbang 2")
	SendToConsoleServer("mp_default_team_winner_no_objective 3")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_solid_teammates 0")
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_death_drop_gun 0")
	SendToConsoleServer("mp_respawnwavetime_t " + CONFIG[CFG_RESPAWN_TIME])
	SendToConsoleServer("mp_respawnwavetime_ct " + CONFIG[CFG_RESPAWN_TIME])
	SendToConsoleServer("mp_use_respawn_waves " + (CONFIG[CFG_RESPAWN_TIME] == 0 ? 0 : 1))
	if (USE_COMPETITIVE_RULES()) {
		SendToConsoleServer("mp_roundtime 9999")
	} else {
		SendToConsoleServer("mp_roundtime " + CONFIG[CFG_TIME_LIMIT] + ".25")
	}

	if (ScriptIsWarmupPeriod()) {
		// sorry bud, gotta reload the map
		if ("HAD_WARMUP" in getroottable()) {
			EndWarmup()
		}

		SendToConsoleServer("mp_freezetime 26")

		// setup convars for config room
		SendToConsoleServer("mp_warmup_pausetimer 1")
		SendToConsoleServer("sv_infinite_ammo 1")
		SendToConsoleServer("mp_damage_scale_t_body 0")
		SendToConsoleServer("mp_damage_scale_t_head 0")
		SendToConsoleServer("mp_damage_scale_ct_body 0")
		SendToConsoleServer("mp_damage_scale_ct_head 0")

		// setup config labels
		for (local i = 0; i < 4; i++) {
			local label = Entities.FindByName(null, "cfg_val" + i)
			if (label != null)
				EntFireHandle(label, "AddOutput", "message " + CfgData[i].format(CONFIG[i]))
		}

		::HAD_WARMUP <- true
		return
	}

	// reset convars if not warmup
	SendToConsoleServer("sv_infinite_ammo 0")
	SendToConsoleServer("mp_damage_scale_t_body 1")
	SendToConsoleServer("mp_damage_scale_t_head 1")
	SendToConsoleServer("mp_damage_scale_ct_body 1")
	SendToConsoleServer("mp_damage_scale_ct_head 1")

	ForEachPlayerAndBot(function(ply) {
		if (ply.ValidateScriptScope())
			ply.GetScriptScope().needs_loadout <- true
	})

	HookToPlayerDeath(function(ply) {
		if (ply != null && ply.ValidateScriptScope())
			ply.GetScriptScope().needs_loadout <- true

		// death turns off flashlight
		EntFireHandle(ply, "AddOutput", "effects 0")
	})

	// pick a random room for delivery
	if (!USE_COMPETITIVE_RULES() || !STOPWATCH.IS_SECOND_ROUND) {
		::DELIVERY_NUM <- RandomInt(1, 5)
		if (USE_COMPETITIVE_RULES())
			Chat(RED + "This round's pizza will be delivered to room " + DeliveryRooms[DELIVERY_NUM - 1][0] + "0" + DeliveryRooms[DELIVERY_NUM - 1][1])
	}
	EntFire("delivery_template_" + DELIVERY_NUM, "forcespawn")
	local room = "room " + DeliveryRooms[DELIVERY_NUM - 1][0] + "0" + DeliveryRooms[DELIVERY_NUM - 1][1]
	::StageData[STAGE_DELIVERY].task[0] = "Deliver pizza to " + room
	::StageData[STAGE_DELIVERY].task[1] = "Defend " + room

	// hide func_brushes before setting start stage
	EntFire("dough_mound_*", "disable")
	EntFire("oven_pizza_*", "disable")
	EntFire("delivery_pizza_*", "disable")
	EntFire("pizza_delivered", "disable")

	SetStage(CONFIG[CFG_FIRST_TASK])

	// set the clock to the right value
	STOPWATCH.CLOCK_ACTIVE = false
	if (USE_COMPETITIVE_RULES()) {
		if (STOPWATCH.IS_SECOND_ROUND) {
			SetClockTime(STOPWATCH.TIME_TO_BEAT)
		} else {
			SetClockTime(0)
		}
	}

	if (!ScriptIsWarmupPeriod() && ("HAD_WARMUP" in getroottable()) && (!("SEEN_INTRO" in getroottable()))) {
		::SEEN_INTRO <- true
		EntFire("intro_song", "PlaySound")
		IntroCam(1, 0, 3.61)
		IntroCam("1a", 5.575)
		IntroCam(2, 7.54)
		IntroCam("2a", 9.51)
		IntroCam(3, 11.49)
		IntroCam(4, 15.41)
		EntFire("intro_fade", "Fade", "", 16)
		EntFire("intro_cam4", "Disable", "", 18.5)
		EntFire("intro_fade", "FadeReverse", "", 19)

		// we don't need as much freezetime after intro plays
		SendToConsoleServer("mp_freezetime 8")

		// custom knives cant be given during the intro for some reason
		// give the default knife instead because we actually kind of need one
		ForEachPlayerAndBot(function(ply) {
			GiveWeapon(ply, "weapon_knife")
		})

		if (USE_COMPETITIVE_RULES())
			EntFire("script", "RunScriptCode", "StartClock()", 26)
	} else {
		if (USE_COMPETITIVE_RULES())
			EntFire("script", "RunScriptCode", "StartClock()", 8)
	}
}

Precache <- function() {
	self.PrecacheScriptSound("c4.Explode")
}


Think <- function() {
	if ("think" in StageData[CURRENT_STAGE])
		StageData[CURRENT_STAGE].think()

	local decoy = null
	while (decoy = Entities.FindByClassname(decoy, "decoy_projectile")) {
		if (decoy.ValidateScriptScope()) {
			local ss = decoy.GetScriptScope()
			if (!("chicken_nuke" in ss)) {
				ss.chicken_nuke <- true
				SetModelSafe(decoy, "models/chicken/chicken.mdl")
				Chat(RED + "Chicken nuke launched!!!")
				EntFire("chicken_nuke_alarm", "PlaySound")
			}
		}
		if (decoy.GetVelocity().LengthSqr() == 0) {
			local owner = decoy.GetOwner()
			local origin = decoy.GetOrigin()

			local explosion = Entities.CreateByClassname("env_explosion")
			explosion.__KeyValueFromInt("iMagnitude", 1500)
			explosion.SetOrigin(origin)
			explosion.SetOwner(owner)	

			EntFireHandle(explosion, "Explode", "", 0.1, owner, owner)
			DispatchParticleEffect("explosion_c4_500", origin, origin)

			decoy.EmitSound("c4.Explode")
			decoy.Destroy()
		}
	}

	// end game if gone over time
	if (USE_COMPETITIVE_RULES() && STOPWATCH.CLOCK_ACTIVE && STOPWATCH.IS_SECOND_ROUND && Time() - STOPWATCH.START_TIME > STOPWATCH.TIME_TO_BEAT) {
		Chat(RED + "Terrorists ran out of time!")
		SetStage(STAGE_END)
	}

	// frick it, update hud every think
	UpdateHUD()
}

::FlushToilet <- function(ent) {
	if (!ent.ValidateScriptScope())
		return;

	local ss = ent.GetScriptScope()
	if (!("last_flush" in ss))
		ss.last_flush <- -10;

	if (Time() - ss.last_flush > 10) {
		EntFireHandle(Entities.FindByNameNearest("toilet_flush", ent.GetOrigin(), 32.0), "PlaySound")
		ss.last_flush <- Time()
	}
}

::PickupChickenNuke <- function(ply) {
	GiveWeapon(ply, WEAPON_DECOY)
	CenterPrint(ply, "Picked up Chicken Nuke.")
}

::PlayerFlashlight <- function(ply, b) {
	EntFireHandle(ply, "AddOutput", "effects " + (b ? 4 : 0))
	CenterPrint(ply, "Flashlight O" + (b ? "N" : "FF"))
}

::SpawnWarning <- function(ply, b) {
	// special case so the pizza doesn't get deleted
	if (ply.GetTeam() == T && CURRENT_STAGE == STAGE_DELIVERY)
		return

	if (b) {
		CenterPrint(ply, "You're not allowed to be here!")
		if (ply.ValidateScriptScope()) {
			ply.GetScriptScope().had_nuke <- HasWeapon(ply, WEAPON_DECOY)
			ply.GetScriptScope().in_enemy_spawn <- true
		}
		StripWeapons(ply)
	} else {
		if (LivingPlayer(ply)) {
			local ss = ply.GetScriptScope()
			if (CURRENT_STAGE == STAGE_DELIVERY && "picked_class" in ss)
				GiveLoadout(ply, ClassLoadouts[ply.GetTeam() - 2][ss.picked_class])
			else
				GiveLoadout(ply, StageData[CURRENT_STAGE].loadout[ply.GetTeam() - 2])
			if ("had_nuke" in ss && ss.had_nuke)
				GiveWeapon(ply, WEAPON_DECOY)
			ss.in_enemy_spawn <- false
			MeleeFixup()
		}
	}
}

// jukebox

::JUKEBOX_SONG <- 0
::JUKEBOX_SONGS <- 10

::CycleJukebox <- function() {
	EntFire("club_song" + JUKEBOX_SONG, "StopSound")
	::JUKEBOX_SONG = (JUKEBOX_SONG + 1) % JUKEBOX_SONGS
	EntFire("club_song" + JUKEBOX_SONG, "PlaySound")
}
