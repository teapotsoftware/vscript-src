
IncludeScript("butil")

SendToConsoleServer("mp_maxrounds 9999")
SendToConsoleServer("mp_timelimit 9999")
SendToConsoleServer("mp_anyone_can_pickup_c4 1")
SendToConsoleServer("mp_teammates_are_enemies 0")
SendToConsoleServer("mp_solid_teammates 0")
SendToConsoleServer("mp_autokick 0")
SendToConsoleServer("mp_roundtime 10")

::GAME_NONE <- 0
::GAME_DEATHRUN <- 1
::GAME_DODGEBALL <- 2
::GAME_HOTPOTATO <- 3
::GAME_KNIFEFIGHT <- 4
::GAME_MUSICALCHAIRS <- 5
::GAME_ONEINTHECHAMBER <- 6
::GAME_QUICKDRAW <- 7
::GAME_RACE <- 8
::GAME_TRIVIA <- 9
::GAME_SOCCER <- 10
::GAME_VAMPIRE <- 11
::GAME_JENGA <- 12
::GAME_RAPBATTLE <- 13
::GAME_AWP <- 14

::CURRENT_GAME <- GAME_NONE

::GAME_TO_TECHNAME <- ["", "deathrun", "dodgeball", "potato", "knife", "chairs", "chamber", "quickdraw", "race", "trivia", "soccer", "vampire", "trivia", "rap", "awp"]
::GAME_TO_PRINTNAME <- ["None", "Deathrun", "Dodgeball", "Hot Potato", "Knife Fight", "Musical Chairs", "One in the Chamber", "Quickdraw", "Race", "Trivia", "Soccer", "Vampire Slayers", "Trivia", "Rap Battle", "AWP Battle"]

::StartGame <- function(game)
{
	::CURRENT_GAME <- game
	EntFire("musical_chairs", "disabledraw")
	EntFire("musical_chairs", "disablecollision")
	EntFire("equip_none", "triggerforallplayers")
	ChatPrintAll("You have chosen " + LIME + GAME_TO_PRINTNAME[game] + WHITE + "!")
	local techname = GAME_TO_TECHNAME[game]
	foreach (team in ["_t", "_ct"])
	{
		EntFire("spawn_teleport" + team, "addoutput", "target exit_" + techname + team)
		EntFire("spawn_teleport" + team, "enable")
	}
	EntFire("equip_" + techname, "triggerforallplayers")
	switch(game)
	{
		case GAME_HOTPOTATO:
			SendToConsoleServer("mp_teammates_are_enemies 1")
			EntFire("potato_timer", "enable")
			EntFire("potato_tick", "playsound")
			GivePotato()
			break

		case GAME_ONEINTHECHAMBER:
			ForEachPlayerAndBot(function(ply) {
				if (Alive(ply))
				{
					ply.SetMaxHealth(20)
					ply.SetHealth(20)
				}
			})
			EntFire("weapon_deagle", "setammoamount", "1", 0.1)
			break

		case GAME_QUICKDRAW:
			EntFire("quickdraw_bowow", "playsound")
			local time = RandomFloat(7, 12)
			EntFire("quickdraw_bong", "playsound", "", time)
			EntFire("equip_quickdraw_revolver", "triggerforallplayers", "", time)
			break

		case GAME_RACE:
			EntFire("race_beep", "pitch", "100", 4)
			EntFire("race_beep", "pitch", "100", 5)
			EntFire("race_beep", "pitch", "150", 6)
			EntFire("race_startglass", "break", "", 6)
			break

		case GAME_SOCCER:
			::SOCCER_SCORES <- [0, 0]
			EntFire("soccer_helpers", "close", "", 45)
			break

		case GAME_KNIFEFIGHT:
			SendToConsoleServer("ammo_grenade_limit_flashbang 2")
			ChatPrintAll("You have " + LIME + "10 seconds" + WHITE + " to select a loadout.")
			EntFire("knife_cars_template", "forcespawn")
			EntFire("race_beep", "pitch", "100", 8)
			EntFire("race_beep", "pitch", "100", 9)
			EntFire("race_beep", "pitch", "150", 10)
			EntFire("knife_tp2", "enable", "", 10)
			break

		case GAME_VAMPIRE:
			ForEachPlayerAndBot(function(ply) {
				if (LivingPlayer(ply) && ply.GetTeam() == T)
				{
					GiveWeapons(ply, ["weapon_knife_push", "weapon_decoy"])
					ModifySpeed(ply, 1.4)
					EntFireHandle(ply, "addoutput", "gravity .714")
					ply.SetMaxHealth(500)
					ply.SetHealth(500)
					local mdl = "models/player/custom_player/legacy/tm_balkan_variant" + ["g", "h", "j"][RandomInt(0, 2)] + ".mdl"
					SetModelSafe(ply, mdl)
				}
			})
			SendToConsoleServer("ammo_grenade_limit_flashbang 2")
			ChatPrintAll("You have " + LIME + "10 seconds" + WHITE + " to select a loadout.")
			EntFire("race_beep", "pitch", "100", 8)
			EntFire("race_beep", "pitch", "100", 9)
			EntFire("race_beep", "pitch", "150", 10)
			EntFire("vampire_tp2", "enable", "", 10)
			EntFire("vampire_intro", "playsound", "", 10)
			EntFire("vampire_sunburner", "disable", "", 45)
			EntFire("script", "RunScriptCode", "ChatPrintAll(\" \" + RED + \"Vampire sunburn disabled!\")", 45)
			break

		case GAME_TRIVIA:
			SendToConsoleServer("mp_teammates_are_enemies 1")
			EntFire("script", "RunScriptCode", "PickTrivia()", 4)
			break

		case GAME_MUSICALCHAIRS:
			SendToConsoleServer("mp_teammates_are_enemies 1")
			SendToConsoleServer("mp_solid_teammates 1")
			MusicalChairsRound()
			break
	}
	MeleeFixup()
}

::AddHook("bullet_impact", "quickdraw_ricochets", function(d)
{
	if (CURRENT_GAME == GAME_QUICKDRAW)
	{
		local name = "quickdraw_ric" + RandomInt(1, 4)
		local ent = Entities.FindByName(null, name)
		ent.SetOrigin(Vector(d.x, d.y, d.z))
		EntFire(name, "PlaySound", "")
	}
})

::Victory <- function(ply)
{
	ChatPrintAll(" " + GREEN + GetPlayerName(ply) + " wins!")
	SendToConsoleServer("mp_teammates_are_enemies 1")
	ForEachPlayerAndBot(function(loser) {
		if (LivingPlayer(loser))
			loser.SetOrigin(Entities.FindByName(null, "exit_loser").GetOrigin() + Vector((loser.GetTeam() == 2) ? -40 : 40, 0, 0))
	})
	local winner_exit = Entities.FindByName(null, "exit_winner")
	ply.SetOrigin(winner_exit.GetOrigin())
	local ang = winner_exit.GetAngles()
	ply.SetAngles(ang.x, ang.y, ang.z)
	EntFire("victory_music", "playsound")
}

::GiveDeagleBullet <- function(ply, pickup = false)
{
	local deag = null
	while (deag = Entities.FindByClassname(deag, "weapon_deagle"))
	{
		if (deag.GetOwner() == ply)
		{
			CenterPrint(ply, "Ammo restored!")
			EntFireHandle(deag, "setammoamount", "1")
		}
	}
	if (pickup)
	{
		ply.EmitSound("Weapon_AK47.BoltPull")
		local model = Entities.FindByNameNearest("oitc_pickup", ply.GetOrigin(), 64)
		if (model != null)
			model.Destroy()
	}
}

OnPostSpawn <- function()
{
	::CURRENT_GAME <- GAME_NONE
	HookToPlayerKill(function(ply)
	{
		if (CURRENT_GAME == GAME_ONEINTHECHAMBER)
			GiveDeagleBullet(ply)
	})
	HookToPlayerDeath(function(ply)
	{
		if (RandomInt(1, 3) == 3)
			ply.EmitSound("Hostage.Pain")
	})
}

::GetPlayerList <- function()
{
	local players = []
	local ply = null
	while (ply = GetPlayersAndBots(ply))
	{
		if (ply.GetHealth() > 0)
		{
			players.push(ply)
		}
	}
	return players
}

::MusicalChairsRound <- function()
{
	local players = GetPlayerList()
	if (players.len() > 1)
	{
		EntFire("chairs_hurt", "disable")
		EntFire("musical_chairs", "disabledraw")
		EntFire("musical_chairs", "disablecollision")
		EntFire("chairs_music", "playsound")
		local delay = RandomInt(2, 25)
		local chairs = []
		local chair = null
		while (chair = Entities.FindByName(chair, "musical_chairs"))
			chairs.push(chair)
		for (local i = 0; i < players.len() - 1; i++)
		{
			EntFireHandle(chairs[i], "enabledraw", "", delay)
			EntFireHandle(chairs[i], "enablecollision", "", delay)
		}
		EntFire("chairs_music", "stopsound", "", delay)
		EntFire("chairs_hurt", "enable", "", delay + 2)
		EntFire("script", "RunScriptCode", "MusicalChairsRound()", delay + 7)
	}
	else if (players.len() > 0)
		Victory(players[0])
}

::TriviaChatLetters <- ["A", "B", "C", "D"]
::TriviaChatColors <- [RED, YELLOW, LIME, BLUE]

::TriviaList <- [
	["How many teeth does an adult human have?", [
		["32", true],
		["40", false],
		["26", false],
		["48", false]
	]],
	["What is the hottest planet in the solar system?", [
		["Mercury", false],
		["Earth", false],
		["Uranus", false],
		["Venus", true]
	]],
	["How long do elephant pregnancies last?", [
		["10 months", false],
		["13 months", false],
		["22 months", true],
		["3+ years", false]
	]],
	["The unicorn is the national animal of which country?", [
		["Netherlands", false],
		["Scotland", true],
		["North Korea", false],
		["El Salvador", false]
	]],
	["How many hearts does an octopus have?", [
		["1", false],
		["2", false],
		["3", true],
		["4", false]
	]],
	["Which U.S. state contains Area 51?", [
		["Arizona", false],
		["New Mexico", false],
		["Utah", false],
		["Nevada", true]
	]],
	["Which member of the Beatles married Yoko Ono?", [
		["Paul McCartney", false],
		["John Lennon", true],
		["George Harrison", false],
		["The Drummer", false]
	]],
	["What was the first toy to be advertised on television?", [
		["Slinky", false],
		["Rubix Cube", false],
		["Mr. Potato Head", true],
		["Super Soaker", false]
	]],
	["Which country consumes the most chocolate per capita?", [
		["Switzerland", true],
		["France", false],
		["United States", false],
		["Belgium", false]
	]],
	["Which is the only edible food that never goes bad?", [
		["Flour", false],
		["Sugar", false],
		["Honey", true],
		["Twinkies", false]
	]],
	["Which country invented ice cream?", [
		["England", false],
		["France", false],
		["Russia", false],
		["China", true]
	]],
	["From which country does Gouda cheese originate?", [
		["Netherlands", true],
		["Italian", false],
		["France", false],
		["India", false]
	]],
	["What was the first soft drink in space?", [
		["Pepsi", false],
		["Coca Cola", true],
		["Tang", false],
		["Sprite", false]
	]],
	["How long is an Olympic swimming pool?", [
		["60 meters", false],
		["75 meters", false],
		["50 meters", true],
		["100", false]
	]],
	["What is the biggest technology company in South Korea?", [
		["LG Electronics", false],
		["KIA Motors", false],
		["Hyundai Motors", false],
		["Samsung", true]
	]],
	["Who named the Pacific Ocean?", [
		["Antonio Pacifico", false],
		["Ferdinand Magellan", true],
		["Frederick Cheese", false],
		["Alfred Pescund", false]
	]],
	["What is a \"cynophobe\" afraid of?", [
		["Chinese food", false],
		["Dogs", true],
		["Math", false],
		["Being poisoned", false]
	]],
	["What is the third letter of the alphabet?", [
		["C", true],
		["D", false],
		["F", false],
		["A", false]
	]],
	["Where was Paula Deen born?", [
		["Mississipi", false],
		["Alabama", false],
		["Georgia", true],
		["Florida", false]
	]],
	["What is the capital of Israel?", [
		["Tel-Aviv", true],
		["Jerusalem", true],
		["Mecca", false],
		["You mean Palestine?", true]
	]],
	["Which of the following most accurately represents Planck's Constant? (in m^2*kg/s)", [
		["6.62607004 x 10^-34", true],
		["7.62 x 39", false],
		["6.022 x 10^23", false],
		["3.14159265", false]
	]],
	["Who was the first black president of the United States?", [
		["Malcolm X", false],
		["Barack Obama", true],
		["Alfred Humper", false],
		["Bill Clinton", true]
	]],
	["What is the second most popular pizza topping?", [
		["Pepperoni", false],
		["Sausage", true],
		["Mushrooms", false],
		["Peppers", false]
	]],
	["What is the approximate airspeed velocity of an unladen swallow, in miles per hour?", [
		["30", true],
		["100", false],
		["24", true],
		["9", false]
	]],
	["How do you tame a horse in Minecraft?", [
		["Give it an apple", false],
		["Try to ride it", true],
		["Give it a golden apple", false],
		["Put a saddle on it", false]
	]],
]

::PickTrivia <- function()
{
	local players = GetPlayerList()
	if (players.len() > 1)
	{
		local q = TriviaList[RandomInt(0, TriviaList.len() - 1)]
		ChatPrintAll("Q. " + q[0])
		EntFire("race_beep", "pitch", "110", 8)
		EntFire("race_beep", "pitch", "120", 9)
		EntFire("race_beep", "pitch", "130", 10)
		EntFire("race_beep", "pitch", "140", 11)
		EntFire("race_beep", "pitch", "150", 12)
		EntFire("trivia_divider", "open", "", 10)
		EntFire("trivia_divider", "close", "", 12)
		EntFire("script", "RunScriptCode", "PickTrivia()", 18)
		for (local i = 0; i < 4; i++)
		{
			ChatPrintAll(" " + TriviaChatColors[i] + TriviaChatLetters[i] + ". " + q[1][i][0])
			if (!q[1][i][1])
			{
				EntFire("trivia_platform_" + i, "break", "", 12)
				EntFire("trivia_platform_" + i + "_template", "forcespawn", "", 15)
			}
		}
	}
	else
	{
		if (players.len() > 0)
			Victory(players[0])
	}
}

::DODGEBALL_MODEL <- "models/props_junk/watermelon01.mdl"
::POTATO_HOLDER <- null
::GivePotato <- function()
{
	local players = GetPlayerList()
	if (players.len() > 1)
	{
		local lucky_guy = players[RandomInt(0, players.len() - 1)]
		GiveWeapon(lucky_guy, "weapon_c4")
	}
	else
	{
		EntFire("potato_tick", "volume", "0")
		if (players.len() > 0)
			Victory(players[0])
	}
}

::ExplodePotato <- function()
{
	local ply = Entities.FindByName(null, "potato_holder")
	if (ply != null && ply.GetHealth() > 0)
	{
		ply.SetHealth(1)
		EntFireHandle(ply, "ignitelifetime", "0.1")
		DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), ply.GetOrigin())
		EntFire("potato_explode", "playsound")
		ChatPrintAll(" " + RED + GetPlayerName(ply) + " exploded!")
	}
	local potato = Entities.FindByClassname(null, "weapon_c4")
	if (potato != null)
	{
		potato.Destroy()
		EntFire("script", "runscriptcode", "GivePotato()", 0.8)
	}
}

::MinikitParticles <- function(pos)
	DispatchParticleEffect("firework_crate_explosion_01", pos, pos)

::SOCCER_SCORES <- [0, 0]
::SoccerGoal <- function(team)
{
	::SOCCER_SCORES[team - 2]++
	local won = SOCCER_SCORES[team - 2] > 2
	ChatPrintAll(" " + (team == T ? (YELLOW + "Terrorists ") : (BLUE + "Counter-Terrorists ")) + (won ? "win" : "score") + "!")
	ChatPrintAll(" " + YELLOW + SOCCER_SCORES[0] + WHITE + "  -  " + BLUE + SOCCER_SCORES[1])
	if (won)
	{
		local ply = null
		while (ply = GetPlayersAndBots(ply))
		{
			if (ply.GetTeam() == team)
			{
				GiveWeapon(ply, WEAPON_P90)
			}
		}
	}
}

::GiveKnifeLoadout <- function(ply, num = 0)
{
	StripWeapons(ply)
	switch (num)
	{
		case 1:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_hegrenade", "weapon_molotov"])
			break

		case 2:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_butterfly", "weapon_smokegrenade", "weapon_flashbang", "weapon_flashbang"])
			break

		case 3:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_karambit", "weapon_bumpmine"])
			break

		case 4:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_bayonet", "weapon_shield"])
			break

		default:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife"])
			break
	}
	MeleeFixup()
}

::GiveVampireSlayerLoadout <- function(ply, num = 0)
{
	StripWeapons(ply)
	switch (num)
	{
		case 1:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_xm1014", "weapon_breachcharge", "weapon_hegrenade"])
			break

		case 2:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_butterfly", "weapon_awp", "weapon_elite", "weapon_hegrenade"])
			break

		case 3:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_karambit", "weapon_mp9", "weapon_bumpmine", "weapon_hegrenade"])
			break

		case 4:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_bayonet", "weapon_shield", "weapon_famas", "weapon_hegrenade"])
			break

		default:
			GiveWeapons(ply, ["item_assaultsuit", "weapon_knife", "weapon_ump45", "weapon_hegrenade"])
			break
	}
	MeleeFixup()
}

Think <- function()
{
	local deleted = []
	switch (CURRENT_GAME)
	{
		case 0:
			EntFire("weapon_elite", "setammoamount", "30")
			break

		case GAME_ONEINTHECHAMBER:
			EntFire("weapon_deagle", "setreserveammoamount", "0")
			// ammo pickup SPEEN
			local pickup = null
			while (pickup = Entities.FindByName(pickup, "oitc_pickup"))
			{
				local ang = pickup.GetAngles()
				pickup.SetAngles(ang.x, ang.y + 3, ang.z)
			}
			break

		case GAME_DODGEBALL:
			local nade = null
			while (nade = Entities.FindByClassname(nade, "hegrenade_projectile"))
			{
				if (nade.GetModelName() != DODGEBALL_MODEL)
				{
					SetModelSafe(nade, DODGEBALL_MODEL)
					nade.__KeyValueFromString("rendercolor", "255 0 0")
				}
			}
			break

		case GAME_VAMPIRE:
			local nade = null
			while (nade = Entities.FindByClassname(nade, "hegrenade_projectile"))
			{
				if (!nade.ValidateScriptScope())
					continue
				local ss = nade.GetScriptScope()
				if ("spawn_time" in ss)
				{
					if ((Time() - ss.spawn_time > 1.5) && !("holy_grenade" in ss))
					{
						ss.holy_grenade <- true
						local hhg_snd = Entities.FindByName(null, "vampire_hhg")
						if (hhg_snd != null)
						{
							hhg_snd.SetOrigin(nade.GetOrigin())
							EntFireHandle(hhg_snd, "playsound")
						}
					}
				}
				else
				{
					ss.spawn_time <- Time()
				}
			}
			while (nade = Entities.FindByClassname(nade, "decoy_projectile"))
			{
				if (!nade.ValidateScriptScope())
					continue
				local owner = nade.GetOwner()
				if (owner == null)
					continue
				local ss = nade.GetScriptScope()
				if (!("thrown_knife" in ss))
				{
					ss.thrown_knife <- true
					SetModelSafe(nade, "models/weapons/w_knife_bayonet_dropped.mdl")
					nade.EmitSound("Player.GhostKnifeSwish")
					GiveWeaponNoStrip(owner, "weapon_decoy")
				}
				if (nade.GetVelocity().Length() < 1)
					deleted.push(nade)
				else
				{
					nade.EmitSound("Weapon_Knife.Slash")
					local ply = null
					while (ply = Entities.FindByClassnameWithin(ply, "*", nade.GetOrigin(), 20))
					{
						if (LivingPlayer(ply) && ply.GetTeam() != owner.GetTeam())
						{
							ply.EmitSound("Weapon_Knife.Hit")
							local new_hp = ply.GetHealth() - 25
							if (new_hp < 1)
							{
								ply.SetHealth(1)
								EntFireHandle(ply, "ignitelifetime", "0.1")
							}
							else
								ply.SetHealth(new_hp)
							deleted.push(nade)
						}
					}
				}
			}
			while (nade = Entities.FindByClassname(nade, "predicted_viewmodel"))
			{
				if (nade.GetModelName() == "models/weapons/v_eq_decoy.mdl")
					SetModelSafe(nade, "models/weapons/v_knife_bayonet.mdl")
			}
			break

		case GAME_HOTPOTATO:
			local potato = Entities.FindByClassname(null, "weapon_c4")
			if (potato != null)
			{
				local owner = potato.GetOwner()
				if (owner != null)
				{
					local last_owner = Entities.FindByName(null, "potato_holder")
					if (last_owner != null)
					{
						last_owner.__KeyValueFromString("targetname", "")
					}
					owner.__KeyValueFromString("targetname", "potato_holder")
				}
			}
			break
	}
	foreach (ent in deleted)
	{
		if (ent != null)
			ent.Destroy()
	}
}
