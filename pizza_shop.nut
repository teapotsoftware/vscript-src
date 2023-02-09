
::T <- 2
::CT <- 3

::MessageT <- function(txt)
	ScriptPrintMessageChatTeam(T, txt)

::MessageCT <- function(txt)
	ScriptPrintMessageChatTeam(CT, txt)

::MessageAll <- function(txt)
	ScriptPrintMessageChatAll(txt)

::TASK_T <- "None"
::TASK_CT <- "None"

::UpdateHUD <- function(task_t, task_ct)
{
	::TASK_T <- task_t
	::TASK_CT <- task_ct
	ShowHUD()
}

::ShowHUD <- function()
{
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
	{
		if (ply.GetTeam() == T)
		{
			EntFire("hud_task_t", "settext", "TASK: " + TASK_T)
			EntFire("hud_task_t", "display", "", 0, ply)
		}
		else if (ply.GetTeam() == CT)
		{
			EntFire("hud_task_ct", "settext", "TASK: " + TASK_CT)
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
		{
			ent.Destroy()
		}
	}
}

::GiveBayonet <- function(ply) {GiveKnife(ply, "weapon_bayonet")}
::GiveM9 <- function(ply) {GiveKnife(ply, "weapon_knife_m9_bayonet")}
::GiveGrenade <- function(ply) {GiveWeapon(ply, "weapon_hegrenade")}
::GiveFlashbang <- function(ply) {GiveWeapon(ply, "weapon_flashbang")}
::GiveAK <- function(ply) {GiveWeapon(ply, "weapon_ak47")}
::GiveFAMAS <- function(ply) {GiveWeapon(ply, "weapon_m4a1")}
::GiveDualies <- function(ply) {GiveWeapon(ply, "weapon_elite")}
::GiveP250 <- function(ply) {GiveWeapon(ply, "weapon_p250")}
::GiveNegev <- function(ply) {GiveWeapon(ply, "weapon_negev")}
::GiveP90 <- function(ply) {GiveWeapon(ply, "weapon_p90")}
::GiveDeagle <- function(ply) {GiveWeapon(ply, "weapon_deagle")}
::GiveNova <- function(ply) {GiveWeapon(ply, "weapon_nova")}
::GiveSmoke <- function(ply) {GiveWeapon(ply, "weapon_smokegrenade")}
::GiveSSG08 <- function(ply) {GiveWeapon(ply, "weapon_ssg08")}
::GiveM249 <- function(ply) {GiveWeapon(ply, "weapon_m249")}

::FireCannon <- function()
{
	local pick = RandomInt(1, 6)
	EntFire("mortar_sound" + pick, "playsound")
	EntFire("mortar_explode" + pick, "explode", "", 1.85)
}

::SuperCannon <- function()
{
	EntFire("cannon_button", "addoutput", "speed 999")
	EntFire("cannon_button", "addoutput", "wait 0")
}

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
	MessageT(" \x4 Alright folks, let's get to work.")
	MessageT(" \x4 This joint is filthy, clean up all this rubbish.")
	MessageT(" \x4 よし、仕事に行こう。この関節は不潔で、すべてのゴミを片付けます。")
	MessageCT(" \x7 Those low-lifes are trying to make a pizza.")
	MessageCT(" \x7 We need to stop them by any means necessary.")
	MessageCT(" \x7 それらの低命はピザを作ろうとしています。必要な手段でそれらを止める必要があります。")
	UpdateHUD("Clean restaurant", "Delay cleaning")
}

::CollectRubbish <- function()
{
	::RUBBISH_COLLECTED++
	MessageT("Rubbish collected: " + RUBBISH_COLLECTED + "/20")
	if (RUBBISH_COLLECTED > 19)
	{
		MessageT(" \x4 Looks great! Now we need to start that pizza.")
		MessageT(" \x4 Go harvest some wheat for the dough!")
		MessageT(" \x4 素晴らしく見える！次に、そのピザを開始する必要があります。生地に小麦を収穫しに行きます！")
		MessageCT(" \x7 No! They're going to make a pizza!")
		MessageCT(" \x7 Stop them from harvesting the wheat!")
		MessageCT(" \x7 番号！彼らはピザを作ります！彼らが小麦を収穫するのを止めてください！")
		UpdateHUD("Harvest wheat", "Defend wheat")
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
		MessageT(" \x4 Wheat harvested! :]")
		MessageT(" \x4 Now knead that dough!")
		MessageT(" \x4 小麦収穫！今、その生地をこねる！")
		MessageT(" \xb WEAPON UNLOCK: Dual Elites")
		MessageT(" \xb 武器のロック解除： デュアルエリート")
		MessageCT(" \x7 They got the wheat...")
		MessageCT(" \x7 Don't let them knead the dough!")
		MessageCT(" \x7 彼らは小麦を手に入れました...生地をこねないでください！")
		MessageCT(" \xb WEAPON UNLOCK: P250")
		MessageCT(" \xb 武器のロック解除： P250")
		MessageAll(" \x3 GUN STORE UNLOCKS: DEAGLE + NOVA")
		MessageAll(" \x3 ガンストアアンロック：ディーグル+ノバ")
		MessageAll(" \x2 LMG, MOUNTED AND LOADED!")
		MessageAll(" \x2 LMG、マウントおよびロード！")
		UpdateHUD("Knead dough", "Delay kneading")
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
}

::AnnounceSauce_Workaround <- function()
{
	// set sauce number to 3 times living Ts, clamped  in [5, 18]
	local sauce = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
	{
		if (ply.GetTeam() == 2)
			sauce += 3
	}

	if (sauce > 18)
		sauce = 18
	else if (sauce < 5)
		sauce = 5

	::NEEDED_SAUCE <- sauce

	MessageT(" \x4 The dough is ready for sauce, hop in that grinder!")
	MessageT(" \x4 生地はソースの準備ができています、そのグラインダーにホップ！")
	MessageCT(" \x7 They're making sauce, don't let them grind it!")
	MessageCT(" \x7 彼らはソースを作っています、彼らにそれを粉砕させないでください！")
	UpdateHUD("Grind sauce", "Defend grinder")
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
		MessageT(" \x4 Y'all got the sauce, we need some cheese!")
		MessageT(" \x4 おいおい、チーズが必要だ！")
		MessageCT(" \x7 They ground the sauce, protect the cheese!")
		MessageCT(" \x7 彼らはソースを挽き、チーズを守ります！")
		MessageT(" \xb WEAPON UNLOCK: AK-47")
		MessageT(" \xb 武器のロック解除： AK-47")
		MessageCT(" \xb WEAPON UNLOCK: M4A4")
		MessageCT(" \xb 武器のロック解除： M4A4")
		MessageAll(" \x3 GUN STORE UNLOCKS: NEGEV + P90")
		MessageAll(" \x3 ガンストアアンロック： NEGEV + P90")
		UpdateHUD("Acquire cheese", "Defend cheese")
	}
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
		if (ply.GetTeam() == T)
		{
			EntFire("cheese_hint", "showmessage", "", 0.0, ply)
			cappers++
		}
	}
	if (cappers < 2 && CHEESE_PROGRESS > 0)
		cappers = -1
	else if (cappers > 3)
		cappers = 3
	if (cappers != 0)
	{
		::CHEESE_PROGRESS += cappers
		if (CHEESE_PROGRESS >= CHEESE_MAX)
		{
			CollectCheese()
			::CHEESE_PROGRESS <- CHEESE_MAX
		}
		MessageAll(" \x9 CHEESE PROGRESS")
		MessageAll(" \x4" + LoopChar("■ ", CHEESE_PROGRESS) + "\x7" + LoopChar("■ ", CHEESE_MAX - CHEESE_PROGRESS))
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
	MessageT(" \x4 Good job getting that cheese, now cook that sucker!")
	MessageT(" \x4 そのチーズを手に入れられたので、今度はその吸盤を調理してください！")
	MessageCT(" \x7 They got the cheese, stop them from cooking!")
	MessageCT(" \x7 彼らはチーズを手に入れました、料理を止めてください！")
	UpdateHUD("Cook pizza", "Sabotage oven")
}

OvenProgressT <- [
	"The pizza is cooking!",
	"It's almost done, keep going!",
	"Pizza's done!"
]

OvenProgressCT <- [
	"They turned on the oven!",
	"They're almost done cooking!",
	"They cooked the pizza!"
]

OvenProgressT_nip <- [
	"ピザは料理中です！",
	"あと少しで終わりです！",
	"ピザができました！"
]

OvenProgressCT_nip <- [
	"彼らはオーブンをつけた！",
	"彼らはほとんど料理を終えました！",
	"彼らはピザを作りました！"
]

::OvenProgress <- function(lvl)
{
	MessageT(" \x4 " + OvenProgressT[lvl])
	MessageT(" \x4 " + OvenProgressT_nip[lvl])
	MessageCT(" \x7 " + OvenProgressCT[lvl])
	MessageCT(" \x7 " + OvenProgressCT_nip[lvl])
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
			MessageT(" \x4 Now all we have to do is deliver it.")
			MessageT(" \x4 Don't let up now, we're so close!")
			MessageT(" \x4 今、私たちがしなければならないすべてはそれを提供することです。今すぐあきらめないでください、私たちはとても近いです！")
			MessageCT(" \x7 Stop them from delivering it!")
			MessageCT(" \x7 This is our last chance, give 'em all you got!")
			MessageCT(" \x7 彼らがそれを提供するのを止めてください！これが私たちの最後のチャンスです。あなたが手に入れたものをすべてあげてください！")
			UpdateHUD("Deliver pizza", "Defend apartment")
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

// □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □
// □ ■ □ □ □ ■ □ ■ ■ ■ ■ □ □ □ □ □ □ ■ ■ ■ □ ■ □ ■ ■ ■ □ ■ ■ ■ □ □ ■ □ □
// □ ■ ■ □ ■ ■ □ ■ □ □ □ □ □ □ □ □ □ ■ □ ■ □ □ □ □ □ ■ □ □ □ ■ □ ■ □ ■ □
// □ ■ □ ■ □ ■ □ ■ □ ■ ■ □ □ □ □ □ □ ■ ■ ■ □ ■ □ □ ■ □ □ □ ■ □ □ ■ ■ ■ □
// □ ■ □ □ □ ■ □ ■ □ □ ■ □ □ □ □ □ □ ■ □ □ □ ■ □ ■ □ □ □ ■ □ □ □ ■ □ ■ □
// □ ■ □ □ □ ■ □ ■ ■ ■ ■ □ ■ ■ ■ ■ □ ■ □ □ □ ■ □ ■ ■ ■ □ ■ ■ ■ □ ■ □ ■ □
// □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □

// □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □
// □ ■ ■ ■ □ ■ □ ■ ■ ■ □ ■ ■ ■ □ □ ■ □ □
// □ ■ □ ■ □ □ □ □ □ ■ □ □ □ ■ □ ■ □ ■ □
// □ ■ ■ ■ □ ■ □ □ ■ □ □ □ ■ □ □ ■ ■ ■ □
// □ ■ □ □ □ ■ □ ■ □ □ □ ■ □ □ □ ■ □ ■ □
// □ ■ □ □ □ ■ □ ■ ■ ■ □ ■ ■ ■ □ ■ □ ■ □
// □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □

::PizzaLogo <- [
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
	"abaaababbbbaaaaaabbbababbbabbbaabaa",
	"abbabbabaaaaaaaaababaaaaabaaabababa",
	"abababababbaaaaaabbbabaabaaabaabbba",
	"abaaababaabaaaaaabaaababaaabaaababa",
	"abaaababbbbabbbbabaaababbbabbbababa",
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
]

::PrintPizzaLogo <- function()
{
	local fin = ""
	foreach (str in PizzaLogo)
	{
		local line = " "
		foreach (c in str)
		{
			if (c == 'b')
			{
				line += "\x4 ■"
			}
			else
			{
				line += "\xb ■"
			}
		}
		MessageAll(line)
	}
}

OnPostSpawn <- function()
{
	PrintPizzaLogo()
	// MessageAll("Welcome to MG_PIZZA!")
	EntFire("func_brush", "disable")
	ResetGlobalVars()
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_solid_teammates 0")
	SendToConsoleServer("mp_roundtime 12")
	SendToConsoleServer("mp_default_team_winner_no_objective 3")
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
	MessageAll("\"skip intro\"と入力して、イントロをスキップします")
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

::CAM_PLY <- null
::CurCam <- 1

::UpdateCam <- function()
{
	EntFire("sec_cam" + CurCam, "enable", "", 0, CAM_PLY)
}

::CycleCams <- function(amt)
{
	::CurCam = (4 + (CurCam + amt)) % 4
	UpdateCam()
}

::StartCams <- function(ply)
{
	::CAM_PLY <- ply
	UpdateCam()
}

::StopCams <- function(ply)
{
	::CAM_PLY <- null
	EntFire("sec_cam*", "disable", "", 0, ply)
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
