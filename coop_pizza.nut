
::T <- 2
::CT <- 3

// FIXME: ENEMY SPAWNS ARE STUCK IN FLOOR

::FirstWaveSpawned <- false

::SpawnEnemies <- function(name, amt = 999)
{
	EntFire("enemies_*", "SetDisabled")
	EntFire("enemies_" + name, "SetEnabled")
	if (!FirstWaveSpawned)
	{
		FirstWaveSpawned <- true
		ScriptCoopMissionSpawnFirstEnemies(amt)
	}
	else
		ScriptCoopMissionSpawnNextWave(amt)
}

::MessageCT <- function(txt)
	ScriptPrintMessageChatTeam(CT, txt)

::MessageAll <- function(txt)
	ScriptPrintMessageChatAll(txt)

::CURRENT_TASK <- "None"

::UpdateHUD <- function(task)
{
	::CURRENT_TASK <- task
	ShowHUD()
}

::ShowHUD <- function()
{
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
	{
		if (ply.GetTeam() == CT)
		{
			EntFire("hud_task_ct", "settext", "TASK: " + CURRENT_TASK)
			EntFire("hud_task_ct", "display", "", 0, ply)
		}
	}
}

::GiveWeapon <- function(ply, weapon, ammo = 99999, everybody = false)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, everybody ? "TriggerForAllPlayers" : "Use", "", 0.0, ply, null)
	equip.Destroy()
}

::GiveKnife <- function(ply, knife)
{
	GiveWeapon(ply, knife)
	EntFire("weapon_knife", "addoutput", "classname weapon_knifegg")
	local ent = null
	while (ent = Entities.FindByClassname(null, "weapon_knife"))
	{
		if (ent.GetOwner() == null)
			ent.Destroy()
	}
}

::GiveBayonet <- function(ply) {GiveKnife(ply, "weapon_bayonet")}
::GiveGrenade <- function(ply) {GiveWeapon(ply, "weapon_hegrenade")}
::GiveAK <- function(ply) {GiveWeapon(ply, "weapon_m4a1")} // THIS IS RETARDED BUT WORKS
::GiveDualies <- function(ply) {GiveWeapon(ply, "weapon_elite")}
::GiveNegev <- function(ply) {GiveWeapon(ply, "weapon_negev")}
::GiveP90 <- function(ply) {GiveWeapon(ply, "weapon_p90")}
::GiveDeagle <- function(ply) {GiveWeapon(ply, "weapon_deagle")}
::GiveNova <- function(ply) {GiveWeapon(ply, "weapon_nova")}
::GiveSmoke <- function(ply) {GiveWeapon(ply, "weapon_smokegrenade")}
::GiveSSG08 <- function(ply) {GiveWeapon(ply, "weapon_ssg08")}
::GiveM249 <- function(ply) {GiveWeapon(ply, "weapon_m249")}

::ResetGlobalVars <- function()
{
	::RUBBISH_COLLECTED <- 0
	::WHEAT_COLLECTED <- 0
	::DOUGH_PROGRESS <- -1
	::NEEDED_SAUCE <- -1
	::CHEESE_PROGRESS <- 0
}
ResetGlobalVars()

::PhoneRing <- function()
{
	EntFire("phone_ring", "playsound")
	EntFire("phone_button", "unlock")
}

::BeginRubbish <- function()
{
	MessageCT(" \x4 Alright folks, let's get to work.")
	MessageCT(" \x4 This joint is filthy, clean up all this rubbish.")
	SpawnEnemies("rubbish")
	UpdateHUD("Clean restaurant")
}

::CollectRubbish <- function()
{
	::RUBBISH_COLLECTED++
	MessageT("Rubbish collected: " + RUBBISH_COLLECTED + "/20")
	if (RUBBISH_COLLECTED > 19)
	{
		MessageCT(" \x4 Looks great! Now we need to start that pizza.")
		MessageCT(" \x4 Go harvest some wheat for the dough!")
		SpawnEnemies("wheat")
		UpdateHUD("Harvest wheat")
		EntFire("wheat_template", "forcespawn")
	}
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireByHandle(strip, "Strip", "", 0.0, ply, null)
	strip.Destroy()
}

::WheatHit <- function(plant)
{
	EntFireByHandle(plant, "Break", "", 0.0, null, null)
	::WHEAT_COLLECTED++
	if (WHEAT_COLLECTED > 29)
	{
		MessageCT(" \x4 Wheat harvested! :]")
		MessageCT(" \x4 Now knead that dough!")
		SpawnEnemies("knead")
//		MessageCT(" \xb WEAPON UNLOCK: Dual Elites")
//		MessageAll(" \x3 GUN STORE UNLOCKS: DEAGLE + NOVA")
//		MessageAll(" \x2 LMG, MOUNTED AND LOADED!")
		UpdateHUD("Knead dough")
		EntFire("turret_cage", "break")
		EntFire("equip_template1", "forcespawn")
		EntFire("equip_model1", "addoutput", "renderamt 255")
		::DOUGH_PROGRESS <- 0
		ShowDoughMound()
	}
}

::RollPin <- function()
{
	if (DOUGH_PROGRESS < 0)
		return

	::DOUGH_PROGRESS++
	// abs truncates to int
	ShowDoughMound(abs(DOUGH_PROGRESS / 4))
	if (DOUGH_PROGRESS > 11)
	{
		::DOUGH_PROGRESS <- -1
		EntFire("dough_mound*", "disable", "", 2)
		EntFire("script", "RunScriptCode", "AnnounceSauce_Workaround()", 2)
		EntFire("prep_stage*", "disable", "", 2)
		EntFire("prep_stage0", "enable", "", 2)
	}
	else
		SpawnEnemies("knead", 3)
}

::AnnounceSauce_Workaround <- function()
{
	// set sauce number to 3 times living CTs, clamped  in [5, 18]
	local sauce = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
	{
		if (ply.GetTeam() == CT)
			sauce += 3
	}

	if (sauce > 18)
		sauce = 18
	else if (sauce < 5)
		sauce = 5

	::NEEDED_SAUCE <- sauce

	MessageCT(" \x4 The dough is ready for sauce, hop in that grinder!")
	SpawnEnemies("sauce")
	UpdateHUD("Grind sauce")
}

::GrindSauce <- function()
{
	if (NEEDED_SAUCE == -1)
	{
		return
	}
	::NEEDED_SAUCE--
	if (NEEDED_SAUCE < 1)
	{
		::NEEDED_SAUCE <- -1
		ShowPrepStage(1)
		EntFire("cheese_gate", "kill")
		EntFire("cheese_timer", "enable")
		EntFire("equip_template2", "forcespawn")
		EntFire("equip_model2", "addoutput", "renderamt 255")
		MessageCT(" \x4 Y'all got the sauce, we need some cheese!")
//		MessageCT(" \xb WEAPON UNLOCK: AK-47")
//		MessageAll(" \x3 GUN STORE UNLOCKS: NEGEV + P90")
		UpdateHUD("Acquire cheese")
	}
	else
		SpawnEnemies("sauce", 3)
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

::CHEESE_MAX <- 40

::CheeseThink <- function()
{
	local cheese_pos = Entities.FindByName(null, "cheese").GetOrigin()
	local cappers = 1
	local ply = null
	while (ply = Entities.FindByClassnameWithin(ply, "player", cheese_pos, 80))
	{
		if (ply.GetTeam() == CT)
		{
			EntFire("cheese_hint", "showmessage", "", 0.0, ply)
			cappers += 3
		}
	}
	if (cappers < 2 && CHEESE_PROGRESS > 0)
		cappers = -1
	if (cappers != 0)
	{
		::CHEESE_PROGRESS += cappers
		if (CHEESE_PROGRESS >= CHEESE_MAX)
		{
			CollectCheese()
			::CHEESE_PROGRESS <- CHEESE_MAX
		}
		MessageAll(" \x9 CHEESE PROGRESS")
		MessageAll(" \x4" + LoopChar("¦ ", CHEESE_PROGRESS) + "\x7" + LoopChar("¦ ", CHEESE_MAX - CHEESE_PROGRESS))
	}
}

::CollectCheese <- function()
{
	ShowPrepStage(2)
	EntFire("cheese_timer", "disable")
	EntFire("cheese", "kill")
	EntFire("prep_stage*", "disable", "", 2)
	EntFire("oven_breakable_template", "forcespawn", "", 2)
	EntFire("oven_pizza_raw", "enable", "", 2)
	SpawnEnemies("cook")
	MessageCT(" \x4 Good job getting that cheese, now cook that sucker!")
	UpdateHUD("Cook pizza")
}

OvenProgress <- [
	"The pizza is cooking!",
	"It's almost done, keep going!",
	"Pizza's done!"
]

::OvenProgress <- function(lvl)
{
	MessageCT(" \x4 " + OvenProgress[lvl])
	switch (lvl)
	{
		case 0:
			EntFire("oven_smallfire", "StartFire", "0")
			EntFire("oven_sound", "PlaySound")
			break;

		case 1:
			EntFire("oven_smallfire", "Extinguish", "0")
			EntFire("oven_bigfire", "StartFire", "0")
			EntFire("oven_sound", "PlaySound")
			break;

		case 2:
			EntFire("oven_bigfire", "Extinguish", "0")
			EntFire("oven_extinguishsound", "PlaySound")
			EntFire("oven_pizza_raw", "disable")
			EntFire("oven_pizza_ready", "enable")
			EntFire("oven_pizza_ready", "disable", "", 2)
			EntFire("pizza_deliver_trigger", "enable", "", 2)
			SpawnEnemies("deliver")
			MessageCT(" \x4 Now all we have to do is deliver it.")
			MessageCT(" \x4 Don't let up now, we're so close!")
			UpdateHUD("Deliver pizza")
			break;
	}
}

::ShowDoughMound <- function(tier = 0)
{
	EntFire("dough_mound*", "disable")
	EntFire("dough_mound" + tier, "enable")
}

::ShowPrepStage <- function(tier = 0)
{
	EntFire("prep_stage*", "disable")
	EntFire("prep_stage" + tier, "enable")
}

OnPostSpawn <- function()
{
	// switch to CO-OP STRIKE if we aren't already
	if (ScriptGetGameMode() != 1 || ScriptGetGameType() != 4)
		SendToConsole("mp_roundtime_deployment 45; game_mode 1; game_type 4; changelevel " + GetMapName())
	EntFire("func_brush", "disable")
	ResetGlobalVars()
	ShowIntro()
}

::IntroCam <- function(num, delay, movement_delay = 0.01)
{
	local cam = "intro_cam" + (num < 10 ? "0" + num : num)
	EntFire(cam, "enable", "", delay)
	EntFire(cam, "startmovement", "", delay + movement_delay)
}

::SkipThatShit <- false

::IntroWarning <- function()
{
	if (!ScriptIsWarmupPeriod())
		return
	MessageAll("Type \"skip intro\" to skip intro.")
}

::PlayerChat <- function(data)
{
	local txt = data.text
	if (txt == "skip intro")
	{
		if (SkipThatShit)
			return
		MessageAll(" \x3 Intro will be skipped!")
		SkipThatShit = true
	}
	else if (txt == "HESOYAM")
	{
		MessageAll(" \x3 Get The Water, Man! Mother Fucking Bootleg Fireworks!")
		MessageAll(" \x10 Cheat activated: Burn, baby, burn!")
		EntFire("player", "ignitelifetime", 5)
	}
	else if (txt == "BUBBLECARS")
	{
		MessageAll(" \x3 Just Got Them Jordans In The Mail")
		MessageAll(" \x10 Cheat activated: Moon gravity (20s)")
		EntFire("lowgrav", "enable")
		EntFire("lowgrav", "disable", "", 20)
	}
}

::ShowIntro <- function()
{
	if (SkipThatShit || ScriptIsWarmupPeriod() || ("SEEN_INTRO" in getroottable()))
		return
	::SEEN_INTRO <- true
	EntFire("intro_song", "playsound")
	IntroCam(01, 0, 2)
	EntFire("intro_door1", "open", "", 2 + 2)
	EntFire("intro_door1", "close", "", 2 + 2 + 3.5)
	IntroCam(02, 2 + 3)
	IntroCam(03, 2 + 3 + 3)
	IntroCam(04, 2 + 3 + 3 + 2)
	IntroCam(05, 2 + 3 + 3 + 2 + 2)
	IntroCam(06, 2 + 3 + 3 + 2 + 2 + 1)
	IntroCam(07, 2 + 3 + 3 + 2 + 2 + 1 + 1)
	EntFire("intro_door2", "open", "", 2 + 3 + 3 + 2 + 2 + 1 + 1 + 0.6)
	EntFire("intro_door2", "close", "", 2 + 3 + 3 + 2 + 2 + 1 + 1 + 3.6)
	IntroCam(08, 2 + 3 + 3 + 2 + 2 + 1 + 1 + 2)
	IntroCam(09, 2 + 3 + 3 + 2 + 2 + 1 + 1 + 2 + 2)
	IntroCam(10, 2 + 3 + 3 + 2 + 2 + 1 + 1 + 2 + 2 + 2)
}

::RADIO_SONG <- 0

::CycleRadio <- function()
{
	::RADIO_SONG <- (RADIO_SONG + 1) % 10
	// EntFire("radio_song_*", "volume", "0")
	EntFire("radio_song_" + RADIO_SONG, "volume", "10")
}

if (!("NameList" in getroottable()))
{
	::NameList <- []
}

::PlayerConnect <- function(data)
{
	NameList.push(data.name)
}

// btc means "Blimp Text Color"
::btc_index <- 0
::btc_list <- [
	"255 0 0",
	"255 150 0",
	"255 255 0",
	"0 255 0",
	"0 150 255",
	"255 0 255"
]

::BlimpTimer <- function()
{
	local listlen = NameList.len()
	if (listlen < 1)
		return
	local name = NameList[RandomInt(0, listlen - 1)]
	if (name.len() < 16)
	{
		for (local i = 0; i < (17 - name.len()) / 2; i++)
		{
			name = " " + name
		}
	}
	EntFire("blimp_text", "addoutput", "message " + name)
	EntFire("blimp_text", "addoutput", "color " + btc_list[btc_index])
	btc_index = (btc_index + 1) % 6
}

::UWU <- function()
{
	local furfagfaces = [
		"^-^",
		"UwU",
		"w_w",
		">w<",
		">_<",
		"T_T",
		"u_u"
	]
	EntFire("uwu", "addoutput", "message " + furfagfaces[RandomInt(0, furfagfaces.len() - 1)])
}
