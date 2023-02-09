
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

::StageData <- [
	{
		name = "Phone",
		task = ["Answer phone", "Await instructions"],
		loadout = [
			["weapon_bayonet"],
			["weapon_knife_m9_bayonet"]
		],
		start = function()
		{
			EntFire("phone_sprite", "showsprite")
			EntFire("script", "runscriptcode", "StageEvent(STAGE_START, 0)", 10)

			// hide func_brushes
			EntFire("dough_mound_*", "disable")
			EntFire("oven_pizza_*", "disable")
			EntFire("pizza_delivered", "disable")
		},
		events = [
			function(params)
			{
				EntFire("phone_ring", "playsound")
				EntFire("phone_button", "unlock")
			},
			function(params)
			{
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
			"They're going to make a pizza. Let's make sure that doesn't happen."
		],
		same_loadout = true,
		loadout = [
			["weapon_bayonet"],
			["weapon_knife_m9_bayonet"]
		],
		start = function()
		{
			::PROG <- 0
			::MAX <- 0
			local ent = null
			while (ent = Entities.FindByName(ent, "rubbish"))
				::MAX++
		},
		events = [
			function(params)
			{
				local ent = params[0]
				ent.Destroy()
				::PROG++
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
		same_loadout = true,
		loadout = [
			["weapon_bayonet"],
			["weapon_knife_m9_bayonet"]
		],
		start = function()
		{
			::PROG <- 0
			::MAX <- 0
			local ent = null
			while (ent = Entities.FindByName(ent, "wheat_bushel"))
				::MAX++
		},
		events = [
			function(params)
			{
				local ent = params[0]
				if (ent.ValidateScriptScope())
				{
					local ss = ent.GetScriptScope()
					if (!("wheat_health" in ss))
						ss.wheat_health <- 4
					ss.wheat_health--
					if (ss.wheat_health < 1)
					{
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
			["weapon_knife_butterfly", "weapon_elite", "weapon_xm1014"],
			["weapon_knife_butterfly", "weapon_elite", "weapon_xm1014"]
		],
		start = function()
		{
			::PROG <- 0
			::MAX <- 12
			EntFire("dough_mound_0", "enable")
		}
		events = [
			function(params)
			{
				::PROG++
				local cur = floor(PROG / 4)
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
			["weapon_bayonet", "weapon_mac10"],
			["weapon_knife_m9_bayonet", "weapon_mp9"]
		],
		start = function()
		{
			::PROG <- 0
			::MAX <- 3
			local ply = null
			while (ply = Entities.FindByClassname(ply, "player"))
				if (ply.GetTeam() == T)
					::MAX += 2
		},
		events = [
			function(params)
			{
				local ply = params[0]
				if (ply.GetTeam() == T)
				{
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
			"They're going to get cheese in the basement. Stop them!"
		],
		loadout = [
			["weapon_bayonet", "weapon_ak47", "weapon_smokegrenade", "weapon_flashbang"],
			["weapon_knife_m9_bayonet", "weapon_m4a1", "weapon_smokegrenade", "weapon_flashbang"]
		],
		start = function()
		{
			::PROG <- 0
			::MAX <- 10
			local ply = null
			while (ply = Entities.FindByClassname(ply, "player"))
				if (ply.GetTeam() == T)
					::MAX += 5
			EntFire("cheese_timer", "enable")
		},
		events = [
			function(params)
			{
				local cheese_pos = Entities.FindByName(null, "cheese").GetOrigin()
				local cappers = 0
				local ply = null
				while (ply = Entities.FindByClassnameWithin(ply, "player", cheese_pos, 150))
				{
					if (ply.GetHealth() > 0)
					{
						local team = ply.GetTeam()
						EntFire("cheese_hint_" + team, "showmessage", "", 0.0, ply)
						if (team == T)
							cappers++
						else if (team == CT)
							cappers--
					}
				}
				if (cappers != 0)
				{
					::PROG += cappers
					if (PROG > MAX)
						::PROG <- MAX
					ChatPrintAll(" \x9 CHEESE PROGRESS")
					ChatPrintAll(" \x4" + LoopChar("■", PROG) + "\x7" + LoopChar("■", MAX - PROG))
					if (PROG >= MAX)
					{
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
			"Good cheese! We need meat, go kill some cows.",
			"They got the cheese. Protect those cows!"
		],
		loadout = [
			["weapon_bayonet", "weapon_ak47"],
			["weapon_knife_m9_bayonet", "weapon_m4a1"]
		],
		start = function()
		{
			EntFire("cheese_timer", "disable")
			EntFire("cow_template", "forcespawn")
			::PROG <- 0
			::MAX <- 5
		},
		events = [
			function(params)
			{
				local cow = params[0]
				if (cow.GetHealth() < 1800)
				{
					EntFireHandle(cow, "break")
					local pep = Entities.FindByNameNearest("pepperoni", cow.GetOrigin(), 100)
					if (pep != null)
						EntFireHandle(pep, "close")
				}
			},
			function(params)
			{
				local pep = params[0]
				pep.Destroy()
				::PROG++
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
			["weapon_bayonet", "weapon_ak47", "weapon_hegrenade"],
			["weapon_knife_m9_bayonet", "weapon_m4a1"]
		],
		message = [
			"That's enough meat. All we have to do now is cook.",
			"Now they're going to cook. Stop them!"
		],
		start = function()
		{
			EntFire("oven_door_timer", "enable")
				EntFire("oven_pizza_raw", "enable")
		},
		events = [
			function(params)
			{
				for (local i = 1; i < 4; i++)
					EntFire("oven_door_" + i, "close")

				EntFire("oven_door_" + RandomInt(1, 3), "open", "", 2)
			},
			function(params)
			{
				MessageTeams(["The oven is on, keep going!", "Oh no, they turned on the oven!"])
				EntFire("oven_sound_ignite", "playsound")
				EntFire("oven_fire_small", "startfire", "0")
			},
			function(params)
			{
				MessageTeams(["We're almost done cooking!", "They're almost done cooking!"])
				EntFire("oven_fire_big", "startfire", "0")
			},
			function(params)
			{
				MessageTeams(["We're done cooking!", "Shit! They finished cooking..."])
				EntFire("oven_sound_done", "playsound")
				EntFire("oven_fire_*", "Extinguish", "0")
				EntFire("oven_pizza_raw", "disable")
				EntFire("oven_pizza_cooked", "enable")
				EntFire("script", "runscriptcode", "NextStage()", 4)
			}
		]
	},
	{
		name = "Delivery",
		task = ["Cook pizza", "Stop delivery"],
		message = [
			"Nice! The pizza's done. Now deliver it!",
			"They're done cooking. Stop them from delivering that pizza!"
		],
		start = function()
		{
			EntFire("oven_door_timer", "disable")
			EntFire("oven_pizza_cooked", "disable")
			EntFire("pizza_template", "forcespawn")
		},
		loadout = [
			["weapon_bayonet", "weapon_ak47"],
			["weapon_knife_m9_bayonet", "weapon_m4a1"]
		],
		events = [
			function(params)
			{
				local ply = params[0]
				local c4 = null
				while (c4 = Entities.FindByClassname(c4, "weapon_c4"))
					if (c4.GetOwner() == ply)
					{
						NextStage()
						break
					}
			}
		]
	},
	{
		name = "Victory",
		task = ["", ""],
		start = function()
		{
			EntFire("round_ender", "EndRound_TerroristsWin", "7")
			EntFire("pizza_delivered_radio", "playsound")
			EntFire("pizza_delivered", "enable")
			EntFire("thank_god", "playsound")
			EntFire("pizza_prop", "kill")
		},
		loadout = [
			[],
			[]
		]
	}
]

::CURRENT_STAGE <- 0
::STAGE_PROGRESS <- 0

::MessageTeams <- function(message)
{
//	convoluted and niggalicious
//	while (local i = 0; i < 2; i++)
//		ChatPrintTeam(i + 2, " " + [LIME, RED][i] + message[i + 2])
	ChatPrintTeam(T, " " + LIME + message[0])
	ChatPrintTeam(CT, " " + RED + message[1])
}

::UpdateHUD <- function()
{
	local stage = StageData[CURRENT_STAGE]

	local ent = null
	while (ent = Entities.FindByClassname(ent, "player"))
	{
		local team = ent.GetTeam()
		if ("task" in stage && stage.task[team - 2] != "")
		{
			local hint = "hud_task_" + ent.GetTeam()
			EntFire(hint, "settext", "Task: " + stage.task[team - 2])
			EntFire(hint, "display", "", 0.0, ent)
		}
	}
}

::SetStage <- function(stage_index, prog = 0)
{
	::CURRENT_STAGE <- stage_index
	::STAGE_PROGRESS <- prog

	UpdateHUD()

	local stage = StageData[stage_index]

	if ("message" in stage)
		MessageTeams(stage.message)

	if ("start" in stage)
		stage.start()

	if (!("same_loadout" in stage))
	{
		local ply = null
		while (ply = Entities.Next(ply))
			if (ply.GetClassname() == "player")
			{
				GiveWeapons(ply, stage.loadout[ply.GetTeam() - 2])
				GiveWeaponNoStrip(ply, "item_assaultsuit")
			}
	}

	MeleeFixup()
}

::NextStage <- function()
	SetStage(CURRENT_STAGE + 1)

::StageEvent <- function(stage, event, params = [])
{
	if (CURRENT_STAGE != stage)
		return

	StageData[stage].events[event](params)
}

::LoopChar <- function(chr, amt)
{
	local str = ""
	for (local i = 0; i < amt; i++)
		str += chr
	return str
}

::PlayerSpawned <- function(ply)
{
	if (!ply.ValidateScriptScope())
		return

	local ss = ply.GetScriptScope()
	if ("needs_loadout" in ss && ss.needs_loadout)
	{
		ss.needs_loadout <- false
		GiveWeapons(ply, StageData[CURRENT_STAGE].loadout[ply.GetTeam() - 2])
		GiveWeaponNoStrip(ply, "item_assaultsuit")
		MeleeFixup()
	}
}

::IntroCam <- function(num, delay, movement_delay = 0.01)
{
	local cam = "intro_cam" + num
	EntFire(cam, "enable", "", delay)
	EntFire(cam, "startmovement", "", delay + movement_delay)
}

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_default_team_winner_no_objective 3")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_solid_teammates 0")
	SendToConsoleServer("mp_roundtime 15")
	SendToConsoleServer("mp_autokick 0")

	HookToPlayerDeath(function(ply) {
		if (ply.ValidateScriptScope())
			ply.GetScriptScope().needs_loadout <- true
	})

	SetStage(STAGE_START)

	if (!ScriptIsWarmupPeriod() && (!("SEEN_INTRO" in getroottable())))
	{
		::SEEN_INTRO <- true
		EntFire("intro_song", "playsound")
		IntroCam(1, 0, 3.61)
		IntroCam(2, 7.54)
		IntroCam(3, 11.49)
		IntroCam(4, 15.41)
		EntFire("intro_fade", "fade", "", 16)
		EntFire("intro_cam4", "disable", "", 18.5)
		EntFire("intro_fade", "fadereverse", "", 19)
	}
}

Think <- function()
{
	if (CURRENT_STAGE == STAGE_COOK)
	{
		local nade = null
		while (nade = Entities.FindByClassname(nade, "hegrenade_projectile"))
		{
			if (nade.ValidateScriptScope())
			{
				if (!("checked_nade" in nade.GetScriptScope()))
				{
					nade.GetScriptScope().checked_nade <- true
					local owner = nade.GetOwner()
					if (owner != null)
						GiveWeaponNoStrip(owner, "weapon_hegrenade")
				}
			}
		}
	}
}
