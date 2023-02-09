
IncludeScript("butil")

::CMDs <- [
	"mp_maxrounds 99999",
	"mp_timelimit 99999",
	"mp_death_drop_breachcharge 0",
	"mp_death_drop_grenade 0",
	"mp_death_drop_gun 0",
	"mp_roundtime 10",
	"mp_autokick 0",
	"mp_anyone_can_pickup_c4 1",
	"mp_molotovusedelay 0",
	"mp_round_restart_delay 5",
	"mp_freezetime 1"
]

foreach (cmd in CMDs) {
	SendToConsoleServer(cmd)
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// GERLOBALS //////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

::GAME_NONE <- 0
::GAME_DEATHRUN <- 1
::GAME_DODGEBALL <- 2
::GAME_MURDER <- 3
::GAME_ONEINTHECHAMBER <- 4
::GAME_QUICKDRAW <- 5
::GAME_TRIVIA <- 6
::GAME_VAMPIRE <- 7
::GAME_CASTLESIEGE <- 8
::GAME_AWP <- 9
::GAME_SHOWDOWN <- 10
::GAME_VIP <- 11

::CURRENT_GAME <- GAME_NONE

///////////////////////////////////////////////////////////////////////////////////////////////////
// GAME TABLE /////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

::GAMES <- [
	{ // NONE
		id = "none",
		name = "None",
		think = function() {
			EntFire(WEAPON_P90, "SetAmmoAmount", "50")
		}
	},
	{ // DEATHRUN
		id = "deathrun",
		name = "Deathrun"
	},
	{ // DODGEBALL
		id = "dodgeball",
		name = "Dodgeball",
		start = function() {
			::DODGEBALL_MODEL <- "models/props_junk/watermelon01.mdl"
			::BreakDodgeWall <- function() {
				EntFire("dodgeball_wall", "Break")
				Chat(RED + "You can now cross the line!")
			}
			ForEachLivingPlayer(function(ply) {
				SetHealthAndMaxHealth(ply, 1)
			})
			EntFire("script", "RunScriptCode", "BreakDodgeWall()", 40)
		},
		think_entity = function(ent) {
			if (ent.GetClassname() == "decoy_projectile") {
				if (ent.GetModelName() != DODGEBALL_MODEL) {
					SetModelSafe(ent, DODGEBALL_MODEL)
					ent.__KeyValueFromString("rendercolor", "255 0 0")
				}
				if (ent.GetVelocity().Length() < 1)
					QueueForDeletion(ent)
			}
		}
	},
	{ // MURDER
		id = "murder",
		name = "Murder",
		ffa = true,
		start = function() {
			::MurderClue <- function(ply) {
				if (!ply.ValidateScriptScope())
					return

				local ss = ply.GetScriptScope()
				if ("murder_clues" in ss)
					ss.murder_clues++
				else
					ss.murder_clues <- 1

				if (ply == MURDERER) {
					CenterPrint(ply, "Clue destroyed.")
					return
				}

				CenterPrint(ply, "Collected clues: " + ss.murder_clues + " of 3")

				if (ss.murder_clues >= 3) {
					if (HasWeapon(ply, WEAPON_DEAGLE)) {
						MurderFixDeagle(ply)
					} else {
						GiveWeapon(ply, WEAPON_REVOLVER)
						EntFireHandle(ply, "RunScriptCode", "MurderFixDeagle(self)", 0.1)
					}
					ss.murder_clues = 0
				}
			}

			::MurderFixDeagle <- function(ply) {
				local d = null
				while (d = Entities.FindByClassname(d, WEAPON_DEAGLE)) {
					if (d.GetOwner() == ply)
						EntFireHandle(d, "SetAmmoAmount", "1")
						EntFireHandle(d, "SetReserveAmmoAmount", "1")
				}
			}

			local players = ShuffleArray(GetLivingPlayers())
			::MURDERER <- players[0]
			if (players.len() > 1)
				::VIGILANTE <- players[1]

			ForEachLivingPlayer(function(ply) {
				local loadout = [WEAPON_SNOWBALL]
				if (ply == MURDERER)
					loadout.push("weapon_knifegg")
				else if (ply == VIGILANTE)
					loadout.push(WEAPON_REVOLVER)
				GiveLoadout(ply, loadout)

				SetHealthAndMaxHealth(ply, 25)
				SetModelSafe(ply, "models/player/custom_player/legacy/tm_professional_var" + RandomInt(1, 4) + ".mdl")
				TeleportToEntity(ply, "exit_murder_" + ply.entindex())

				if (ply.ValidateScriptScope())
					ply.GetScriptScope().murder_clues <- 0
			})
			EntFireHandle(VIGILANTE, "RunScriptCode", "MurderFixDeagle(self)", 0.1)
			for (local i = 1; i <= 22; i++) {
				if (RandomInt(1, 100) > 50) {
					EntFire("clue" + i + "-btn", "kill")
					EntFire("clue" + i + "-mdl", "kill")
					EntFire("clue" + i + "-snd", "kill")
				}
			}
			ChatPrintAll("One of you is the " + RED + " Murderer" + WHITE + " with a knife.")
			ChatPrintAll("There is a vigilante among the innocent with a gun.")
		},
		think = function() {
			EntFire(WEAPON_SNOWBALL, "SetReserveAmmoAmount", "2")
		},
		think_entity = function(ent) {
			if (LivingPlayer(ent)) {
				ent.SetHealth(25)
			}
		},
		player_death = function(ply) {
			if (ply == MURDERER) {
				EntFire("round_end", "EndRound_CounterTerroristsWin", "7")
				ChatPrintAll(" " + GREEN + "The Murderer has been killed!")
			} else if (GetLivingPlayers().len() < 2) {
				EntFire("round_end", "EndRound_TerroristsWin", "7")
				ChatPrintAll(" " + RED + "The Murderer wins!")
			}
		}
	},
	{ // ONE IN THE CHAMBER
		id = "chamber",
		name = "One in the Chamber",
		start = function() {
			::GiveDeagleBullet <- function(ply, pickup = false) {
				local deag = null
				while (deag = Entities.FindByClassname(deag, WEAPON_HKP2000)) {
					if (deag.GetOwner() == ply) {
						CenterPrint(ply, "Ammo restored!")
						EntFireHandle(deag, "SetAmmoAmount", "1")
					}
				}
				if (pickup) {
					ply.EmitSound("Weapon_AK47.BoltPull")
					local model = Entities.FindByNameNearest("oitc_pickup", ply.GetOrigin(), 64)
					if (model != null)
						model.Destroy()
				}
			}

			ForEachLivingPlayer(function(ply) {
				SetHealthAndMaxHealth(ply, 10)
			})
			EntFire(WEAPON_HKP2000, "SetAmmoAmount", "1", 0.1)
		},
		think = function() {
			EntFire(WEAPON_HKP2000, "SetReserveAmmoAmount", "0")
		},
		think_entity = function(ent) {
			if (ent.GetName() == "oitc_pickup") {
				local ang = ent.GetAngles()
				ent.SetAngles(ang.x, ang.y + 3, ang.z)
			}
		}
	},
	{ // QUICKDRAW
		id = "quickdraw",
		name = "Quickdraw",
		console = ["sv_infinite_ammo 2"],
		start = function() {
			::QuickdrawStart <- function() {
				ForEachLivingPlayer(function(p) {
					GiveLoadout(p, [ITEM_KEVLAR, WEAPON_REVOLVER, "weapon_knife_stiletto"])
					MeleeFixup()
				})
				EntFire("quickdraw_bong", "playsound")
				EntFire("quickdraw_chests", "Unlock")
			}

			::GiveChestItem <- function(ply) {
				GiveWeapon(ply, RandomFromArray([WEAPON_ELITE, WEAPON_NOVA, WEAPON_SSG08, WEAPON_MOLOTOV]))
			}

			::ChestOpened <- function(chest) {
				EntFireHandle(chest, "SetGlowDisabled")
				SetModelSafe(chest, "models/props/cs_militia/footlocker01_open.mdl")
				local snd = Ent("quickdraw_chestsnd")
				snd.SetOrigin(chest.GetOrigin() + Vector(0, 0, 12))
				EntFireHandle(snd, "PlaySound")
			}

			local whisky = null
			while (whisky = Entities.FindByName(whisky, "quickdraw_whiskey")) {
				if (whisky.ValidateScriptScope()) {
					whisky.GetScriptScope().InputUse <- function() {
						local hp = activator.GetHealth()
						if (hp == 100) {
							local burp = Ent("quickdraw_burp")
							burp.SetOrigin(self.GetOrigin())
							EntFireHandle(burp, "PlaySound")
							return
						}
						activator.SetHealth(Min(hp + 40, 100))
						local drink = Ent("quickdraw_swig" + RandomInt(1, 4))
						drink.SetOrigin(self.GetOrigin())
						EntFireHandle(drink, "PlaySound")
						self.Destroy()
					}
				}
			}

			EntFire("quickdraw_bowow", "playsound")
			local time = RandomFloat(7, 12)
			EntFire("script", "RunScriptCode", "QuickdrawStart()", time)
		},
		bullet_impact = function(d) {
			local ric = Entities.FindByName(null, "quickdraw_ric" + RandomInt(1, 4))
			ric.SetOrigin(Vector(d.x, d.y, d.z))
			EntFireHandle(ric, "Pitch", "" + RandomInt(85, 115))
		}
	},
	{ // TRIVIA
		id = "trivia",
		name = "Trivia",
		ffa = true,
		start = function() {
			::TriviaChatLetters <- ["A", "B", "C", "D"]
			::TriviaChatColors <- [RED, YELLOW, LIME, BLUE]
			::TriviaTimer <- 12

			::TriviaList <- [
				["How many teeth does an adult human have?", [
					["32", true],
					["40", false],
					["26", false],
					["48", false]
				]],
				["Kansas City is in which U.S. state?", [
					["Missouri", true],
					["California", false],
					["Kansas", false],
					["Oklahoma", false]
				]],
				["Oklahoma City is in which U.S. state?", [
					["Missouri", false],
					["California", false],
					["Kansas", false],
					["Oklahoma", true]
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
				["What is the only edible food that never goes bad?", [
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
					["Italy", false],
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
					["B", false],
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
				["Which country hosted the 2012 summer Olympic games?", [
					["Sochi, Russia", false],
					["London, Englad", true],
					["Seoul, Korea", false],
					["Tokyo, Japan", false]
				]],
				["How many holes are in a full round of golf?", [
					["9", false],
					["18", true],
					["21", false],
					["19", false]
				]],
				["Which river flows through London?", [
					["Seine", false],
					["Thames", true],
					["Euphrates", false],
					["Mississippi", false]
				]],
				["How many obsidian blocks are required to build a Nether portal?", [
					["8", false],
					["10", true],
					["14", false],
					["12", false]
				]],
				["What is the largest bone in the human body?", [
					["Spine", false],
					["Femur", true],
					["Skull", false],
					["Clavicle", false]
				]],
			]

			::PickTrivia <- function() {
				local players = GetLivingPlayers()
				if (players.len() > 1) {
					local q = TriviaList[RandomInt(0, TriviaList.len() - 1)]
					ChatPrintAll("Q. " + q[0])
					for (local i = 0; i < 5; i++) {
						EntFire("race_beep", "Pitch", "" + (150 - i * 10), TriviaTimer - i)
					}
					EntFire("trivia_divider", "Open", "", TriviaTimer - 2)
					EntFire("trivia_divider", "Close", "", TriviaTimer)
					EntFire("script", "RunScriptCode", "PickTrivia()", TriviaTimer + 4)
					local answers = ShuffleArray(q[1])
					for (local i = 0; i < 4; i++) {
						ChatPrintAll(" " + TriviaChatColors[i] + TriviaChatLetters[i] + ". " + answers[i][0])
						if (!answers[i][1]) {
							EntFire("trivia_platform_" + i, "Break", "", TriviaTimer)
							EntFire("trivia_platform_" + i + "_template", "ForceSpawn", "", TriviaTimer + 3)
						}
					}
					::TriviaTimer = Max(TriviaTimer - 0.5, 5)
				} else {
					if (players.len() > 0) {
						Chat("Ladies and gentlemen, please congratulate tonight's winner!")
						Chat("They have won: " + RandomFromArray([RED, BLUE, GREEN, MAGENTA]) + RandomFromArray([
							"a new car",
							"an all-expenses paid trip to Belize",
							"nothing",
							"$20 USD",
							"two quid"
						]) + WHITE + "!")
					}
				}
			}

			EntFire("script", "RunScriptCode", "PickTrivia()", 4)
		}
	},
	{ // VAMPIRE SLAYER
		id = "vampire",
		name = "Vampire Slayer",
		console = ["ammo_grenade_limit_flashbang 2", "sv_hegrenade_damage_multiplier 10"],
		start = function() {
			::DownedVampires <- []

			::GiveVampireSlayerLoadout <- function(ply, num = 0) {
				if (num < 1 || num > 3) {
					num = RandomInt(1, 999) % 3
				}
				StripWeapons(ply)
				switch (num) {
					case 1:
						GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_nova", "weapon_fiveseven", "weapon_hegrenade"])
						break

					case 2:
						GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_butterfly", "weapon_awp", "weapon_elite", "weapon_hegrenade"])
						break

					default:
						GiveWeapons(ply, ["item_assaultsuit", "weapon_knife_karambit", "weapon_bizon", "weapon_deagle", "weapon_hegrenade"])
						break
				}
				MeleeFixup()
			}

			::DisableSunburn <- function() {
				EntFire("vampire_sunburner", "disable")
				Chat(RED + "Vampire sunburn disabled!")
			}

			::VampireStaked <- function(ent) {
				local body = Entities.FindByNameNearest("vampire_downed_mdl", ent.GetOrigin() - ent.GetForwardVector() * 38, 100)
				if (body != null) {
					body.Destroy()
				}
				local pos = ent.GetOrigin()
				local nearest_vamp = null
				local nearest_vamp_dist = INT_MAX
				foreach (vamp in DownedVampires) {
					if (vamp[0] == null || !Alive(vamp[0])) {
						continue
					}
					local dist = DistToSqr(pos, vamp[1])
					if (dist < nearest_vamp_dist) {
						nearest_vamp_dist = dist
						nearest_vamp = vamp[0]
					}
				}
				printl("staking vampire " + nearest_vamp)
				if (nearest_vamp != null) {
					nearest_vamp.SetHealth(1)
					EntFireHandle(nearest_vamp, "IgniteLifetime", "0.1")
					/*
					nearest_vamp.__KeyValueFromString("targetname", "vampire_stake_target")
					EntFire("vampire_stake_hurt", "Hurt", "", 0, Entities.FindByClassnameNearest("player", pos, 100))
					EntFireHandle(nearest_vamp, "AddOutput", "targetname \"\"", 0.1)
					printl("should be staked? " + nearest_vamp)
					*/
				}
				EntFireHandle(ent, "Break")
			}

			::ResVampire <- function(plyindex) {
				local ply = GetPlayerFromUserID(plyindex)
				if (ply == null || !Alive(ply)) {
					return
				}
				local us = null
				foreach (i, vamp in DownedVampires) {
					if (vamp[0] == ply) {
						us = [vamp[0], vamp[1]]
						DownedVampires.remove(i)
					}
				}
				if (us == null) {
					printl("BAD RES!!!")
				}
				printl("resurrecting vampire: " + us[0] + ", " + us[1])
				ply.SetOrigin(us[1])
				ply.SetHealth(600)
				local body = Entities.FindByNameNearest("vampire_downed_mdl", us[1], 100)
				if (body != null) {
					body.Destroy()
				}
				local brk = Entities.FindByNameNearest("vampire_downed_brk", us[1], 100)
				if (brk != null) {
					brk.Destroy()
				}
			}

			ForEachLivingPlayer(function(ply) {
				switch (ply.GetTeam()) {
					case T:
						SetModelSafe(ply, "models/player/custom_player/legacy/tm_balkan_varianth.mdl")
						GiveLoadout(ply, ["item_kevlar", "weapon_knife_push", "weapon_decoy"])
						ModifySpeed(ply, 1.4)
						EntFireHandle(ply, "addoutput", "gravity .714")
						SetHealthAndMaxHealth(ply, 1000)
						break

					case CT:
						SetModelSafe(ply, "models/player/custom_player/legacy/ctm_swat_variantj.mdl")
						GiveVampireSlayerLoadout(ply)
						break
				}
			})

			ChatPrintAll("You have " + LIME + "10 seconds" + WHITE + " to select a loadout.")
			EntFire("race_beep", "pitch", "100", 8)
			EntFire("race_beep", "pitch", "100", 9)
			EntFire("race_beep", "pitch", "150", 10)
			EntFire("vampire_tp2", "enable", "", 10)
			EntFire("vampire_intro", "playsound", "", 10)
			local striketime = RandomFloat(12, 15)
			EntFire("vampire_thunder", "playsound", "", striketime)
			EntFire("vampire_lightning", "turnon", "", striketime)
			EntFire("vampire_lightning", "turnoff", "", striketime + 0.2)
			EntFire("script", "RunScriptCode", "DisableSunburn()", 60)
		},
		player_hurt = function(d) {
			local ply = d.userid_player
			if (ply != null && ply.GetTeam() == T && d.health <= 500 && d.health > 0) {
				local pos = ply.GetOrigin()
				if (pos.z < -768) {
					return
				}
				printl("vampire downed: " + ply + ", " + pos)
				DownedVampires.push([ply, pos])
				local maker = Ent("vampire_downed_maker")
				if (maker != null) {
					maker.SpawnEntityAtLocation(pos, Vector(0, ply.GetAngles().y, 0))
				}
				local box = Ent("vampire_downed_box")
				if (box != null) {
					ply.SetOrigin(box.GetOrigin())
				}
				CenterPrint(ply, "You will resurrect in 4 seconds unless you are staked.")
				EntFire("script", "RunScriptCode", "ResVampire(" + GetUserID(ply) + ")", 4)
			}
		},
		think_entity = function(ent) {
			local cls = ent.GetClassname()
			switch (cls) {
				case "hegrenade_projectile":
					if (!ent.ValidateScriptScope())
						return
					local ss = ent.GetScriptScope()
					if ("spawn_time" in ss) {
						if ((Time() - ss.spawn_time > 1.5) && !("holy_grenade" in ss)) {
							ss.holy_grenade <- true
							local hhg_snd = Entities.FindByName(null, "vampire_hhg")
							if (hhg_snd != null) {
								hhg_snd.SetOrigin(ent.GetOrigin())
								EntFireHandle(hhg_snd, "playsound")
							}
						}
					} else {
						ss.spawn_time <- Time()
					}
					break

				case "decoy_projectile":
					if (!ent.ValidateScriptScope())
						return
					local owner = ent.GetOwner()
					if (owner == null)
						return
					local ss = ent.GetScriptScope()
					if (!("thrown_knife" in ss)) {
						ss.thrown_knife <- true
						SetModelSafe(ent, "models/weapons/w_knife_skeleton_dropped.mdl")
						ent.EmitSound("Player.GhostKnifeSwish")
						GiveWeaponNoStrip(owner, "weapon_decoy")
					}
					if (ent.GetVelocity().Length() < 1) {
						QueueForDeletion(ent)
					} else {
						ent.EmitSound("Weapon_Knife.Slash")
						local ply = null
						while (ply = Entities.FindByClassnameWithin(ply, "*", ent.GetOrigin(), 20)) {
							if (LivingPlayer(ply) && ply.GetTeam() != owner.GetTeam()) {
								ply.EmitSound("Weapon_Knife.Hit")
								ply.__KeyValueFromString("targetname", "vampire_thrownknife_target")
								EntFire("vampire_thrownknife_hurt", "Hurt", "", 0, owner)
								EntFire("vampire_thrownknife_target", "AddOutput", "targetname \"\"", 0.1)
								QueueForDeletion(ent)
							}
						}
					}
					break
			}
		}
	},
	{ // CASTLE SIEGE
		id = "castle",
		name = "Castle Siege",
		console = ["sv_falldamage_scale 0.1"],
		start = function() {
			ForEachLivingPlayer(function(ply) {
				GiveWeapons(ply, ["item_kevlar", RandomFromArray([
					"weapon_bayonet",
					"weapon_knife_m9_bayonet",
					"weapon_knife_karambit",
					"weapon_knife_css"
				])])
			})
			EntFire("castle_ambient", "PlaySound")
		}
	},
	{ // AWP BATTLE
		id = "awp",
		name = "AWP Battle"
	},
	{ // SHOWDOWN
		id = "showdown",
		name = "Showdown",
		start = function() {
			::ShowdownLoadouts <- [
				["M4A1", ["item_assaultsuit", "weapon_m4a1", "weapon_bayonet"]],
				["M4A1 + Flash", ["item_assaultsuit", "weapon_m4a1", "weapon_bayonet", "weapon_flashbang"]],
				["M4A1 + HE", ["item_assaultsuit", "weapon_m4a1", "weapon_bayonet", "weapon_hegrenade"]],
				["AK-47", ["item_assaultsuit", "weapon_ak47", "weapon_knife_m9_bayonet"]],
				["AK-47 + Flash", ["item_assaultsuit", "weapon_ak47", "weapon_knife_m9_bayonet", "weapon_flashbang"]],
				["AK-47 + HE", ["item_assaultsuit", "weapon_ak47", "weapon_knife_m9_bayonet", "weapon_hegrenade"]],
				["AWP", ["item_assaultsuit", "weapon_awp", "weapon_knife_karambit"]],
				["AWP + Flash", ["item_assaultsuit", "weapon_awp", "weapon_knife_karambit", "weapon_flashbang"]],
				["Deagle", ["item_assaultsuit", "weapon_deagle", "weapon_knife_butterfly"]],
				["Deagle + Flash", ["item_assaultsuit", "weapon_deagle", "weapon_knife_butterfly", "weapon_flashbang"]],
				["USP", ["item_kevlar", "weapon_hkp2000", "weapon_bayonet"]],
				["USP + Flash", ["item_kevlar", "weapon_hkp2000", "weapon_bayonet", "weapon_flashbang"]],
				["FAMAS", ["item_kevlar", "weapon_famas", "weapon_bayonet"]],
				["Galil", ["item_kevlar", "weapon_galilar", "weapon_knife_m9_bayonet"]],
				["Glock", ["item_kevlar", "weapon_glock", "weapon_knife_m9_bayonet"]],
				["CZ75", ["item_kevlar", "weapon_cz75a", "weapon_knife_butterfly"]],
			]

			::ShowdownMaps <- [
				"Liminal",
				"Street",
				"Orange",
				"Aztec",
				"Dust"
			]

			::LastShowdownArena <- -1
			::ShowdownArena <- 2
			::ShowdownCompetitors <- [null, null]
			::ShowdownLoadout <- -1

			::ShowdownRound <- function() {
				local plys = [ShuffleArray(GetLivingPlayers(T)), ShuffleArray(GetLivingPlayers(CT))]
				for (local i = 0; i < 2; i++) {
					if (plys[i].len() < 1) {
						return
					}
					if (ShowdownCompetitors[i] == null || !Alive(ShowdownCompetitors[i])) {
						ShowdownCompetitors[i] = plys[i][0]
					}
				}

				::LastShowdownArena = ShowdownArena
				::ShowdownArena = RandomInt(1, 99999) % 5
				::ShowdownLoadout = RandomFromArray(ShowdownLoadouts)
				ForEachPlayerAndBot(function(ply) {
					local spectator = true
					for (local i = 0; i < 2; i++) {
						if (ply == ShowdownCompetitors[i]) {
							TeleportToEntity(ply, "exit_showdown_" + (i == 0 ? "" : "c") + "t_" + ShowdownArena)
							GiveLoadout(ply, ShowdownLoadout[1])
							CenterPrint(ply, "Arena: " + ShowdownMaps[ShowdownArena] + "\nWeapon: " + ShowdownLoadout[0])
							SetHealthAndMaxHealth(ply, 100)
							spectator = false
						}
					}
					if (spectator && Alive(ply)) {
						local pos = ply.GetOrigin()
						pos.x += (ShowdownArena - LastShowdownArena) * 960
						ply.SetOrigin(pos)
						GiveLoadout(ply, [WEAPON_KNIFE_STILETTO, WEAPON_SNOWBALL])
						SetHealthAndMaxHealth(ply, 9999)
					}
				})
				MeleeFixup()

				// EntFire("race_beep", "pitch", "110")
				EntFire("quickdraw_bong", "Pitch", "90")
				// ChatPrintAll("FIGHT!")
				::NextShowdownRound = -1
			}

			ChatPrintAll("Prepare to fight in 5 seconds...")
			::NextShowdownRound <- Time() + 5
		},
		think = function() {
			if (NextShowdownRound != -1 && Time() >= NextShowdownRound)
				ShowdownRound()
		},
		player_death = function(ply) {
			if (ply == ShowdownCompetitors[0] || ply == ShowdownCompetitors[1]) {
				// EntFire("quickdraw_bong", "Pitch", "90")
				::NextShowdownRound = Time() + 1.6
			}	
		}
	},
	{ // ASSASSINATION
		id = "vip",
		name = "Assassination",
		start = function() {
			::VIP <- RandomFromArray(GetLivingPlayers(CT))
			SetModelSafe(VIP, "models/player/custom_player/legacy/tm_professional_var" + RandomInt(1, 4) + ".mdl")
			CenterPrint(VIP, "You are the VIP.")

			ForEachLivingPlayer(function(ply) {
				if (ply.GetTeam() == T) {
					GiveLoadout(ply, ["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_ak47", "weapon_glock", "weapon_hegrenade"])
				} else {
					if (ply == VIP)
						GiveLoadout(ply, ["item_assaultsuit", "weapon_bayonet", "weapon_usp_silencer"])
					else
						GiveLoadout(ply, ["item_assaultsuit", "weapon_bayonet", "weapon_p250", "weapon_m4a1"])
				}
			})
		},
		player_death = function(ply) {
			if (ply == VIP) {
				::VIP <- null
				ChatPrintAll(" " + DARK_RED + "The VIP has been killed!")
				EntFire("round_end", "EndRound_TerroristsWin", "7")
				local n = 2
				if (RandomInt(1, 5) == 5) {
					n = 1
					if (RandomInt(1, 5) == 5)
						n = 3
				}
				EntFire("vipdown" + n, "playsound")
			}
		}
	}
]

///////////////////////////////////////////////////////////////////////////////////////////////////
// MAIN MAP LOGIC /////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

::StartGame <- function(gameid) {
	::CURRENT_GAME <- gameid
	local game = GAMES[gameid]
	if ("ffa" in game) {
		SendToConsoleServer("mp_teammates_are_enemies 1")
	} else {
		SendToConsoleServer("mp_solid_teammates 2")
	}
	if ("console" in game) {
		foreach (cmd in game.console) {
			SendToConsoleServer(cmd)
		}
	}
	EntFire("jukebox_tp", "Enable")
	ChatPrintAll("You have chosen " + LIME + game.name + WHITE + "!")
	foreach (team in ["_t", "_ct"]) {
		EntFire("spawn_teleport" + team, "addoutput", "target exit_" + game.id + team)
		EntFire("spawn_teleport" + team, "enable")
	}
	EntFire("equip_none", "TriggerForAllPlayers")
	EntFire("equip_" + game.id, "TriggerForAllPlayers")
	if ("start" in game) {
		game.start()
	}
	MeleeFixup()
}

OnPostSpawn <- function() {
	SendToConsoleServer("mp_teammates_are_enemies 0")
	SendToConsoleServer("mp_solid_teammates 1")
	SendToConsoleServer("sv_hegrenade_damage_multiplier 1")
	SendToConsoleServer("sv_falldamage_scale 1")
	SendToConsoleServer("sv_infinite_ammo 0")

	for (local i = 0; i < 5; i++) {
		if (RorysFound[i]) {
			EntFire("rory_" + i, "Kill")
			EntFire("rory_button_" + i, "Kill")
		}
	}

	for (local i = 0; i < 6; i++) {
		if (Yaoichievements[i]) {
			EntFire("yaoi_lock_" + i, "Break")
		}
	}

	::CURRENT_GAME <- GAME_NONE

	HookToPlayerKill(function(ply) {
		if (CURRENT_GAME == GAME_ONEINTHECHAMBER) {
			GiveDeagleBullet(ply)
		}

		if (LastDeadPlayer != null) {
			if (LastDeadPlayer == ply) {
				printl("Suicide!")
				::Suicides++
				if (Suicides == 17) {
					UnlockYaoi(YAOI_HOONI)
				}
			}
		}

		::LastDeadPlayer <- null
	})

	HookToPlayerDeath(function(ply) {
		if (ply != null && ((CURRENT_GAME == GAME_VIP && ply == VIP) || (CURRENT_GAME == GAME_MURDER && ply == MURDERER) || (CURRENT_GAME != GAME_MURDER && RandomInt(1, 9999) % 3 == 0))) {
			local emitter = Entities.FindByName(null, "deathsound_" + RandomInt(1, 7))
			if (emitter != null) {
				emitter.SetOrigin(ply.GetOrigin() + Vector(0, 0, 24))
				EntFireHandle(emitter, "PlaySound")
			}
		}

		local game = GAMES[CURRENT_GAME]
		if ("player_death" in game) {
			game.player_death(ply)
		}

		::LastDeadPlayer <- ply
	})

	local ply = null
	local mdlclr = ["red", "blu"]
	local mdlcnt = [0, 0]
	while (ply = Entities.Next(ply)) {
		if (ply.GetClassname() == "player") {
			local t = ply.GetTeam() - T
			ply.SetModel("models/player/custom_player/legacy/tm_jumpsuit_fujo" + mdlclr[t] + (mdlcnt[t] + 1) + ".mdl")
			mdlcnt[t] = (mdlcnt[t] + 1) % 3
		}
	}
}

Think <- function() {
	local game = GAMES[CURRENT_GAME]
	if ("think" in game) {
		game.think()
	}
	if ("think_entity" in game) {
		local ent = null
		while (ent = Entities.Next(ent)) {
			if (ent.GetClassname() == "player") {
				UserIDThink(ent)
			}
			game.think_entity(ent)
		}
		FlushDeletionQueue()
	}
}

AddHook("player_hurt", "fujo_multigames", function(data) {
	local game = GAMES[CURRENT_GAME]
	if ("player_hurt" in game) {
		game.player_hurt(data)
	}
})

AddHook("bullet_impact", "fujo_multigames", function(data) {
	local game = GAMES[CURRENT_GAME]
	if ("bullet_impact" in game) {
		game.bullet_impact(data)
	}
})

AddHook("inspect_weapon", "fujo_multigames", function(data) {
	local game = GAMES[CURRENT_GAME]
	if ("inspect_weapon" in game) {
		game.inspect_weapon(data)
	}
})

::JukeboxTP <- function(ply) {
	ply.SetOrigin(Vector(-6272, 2112, 212))
	ply.SetAngles(0, 0, 0)
}

::MinikitParticles <- function(pos)
	DispatchParticleEffect("firework_crate_explosion_01", pos, pos)

::PlayerSpawn <- function(ply) {} // TODO

///////////////////////////////////////////////////////////////////////////////////////////////////
// YAOI SHIT //////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

if (!("Yaoichievements" in getroottable())) {
	::YAOI_CMBYN <- 0 // say "i am become fujoshi" in chat
	::YAOI_TOY <- 1 // collect all 6 lion plushies
	::YAOI_ARH <- 2 // cook meth in the murder level
	::YAOI_HOONI <- 3 // kill yourself 17 times
	::YAOI_CREEK <- 4 // north korea missile
	::YAOI_SQUID <- 5 // shoot at the squid game snipers

	::Yaoichievements <- [false, false, false, false, false, false]
	::YaoichievementNames <- [
		"Creator of CS maps",
		"Duck this time, yeah?",
		"Jesse, it is always raining here",
		"This time, I'm really gonna do it",
		"Uunnggc, cupcakes?",
		"Did somebody say SQUID GAME?"
	]
	::RorysFound <- [false, false, false, false, false, false]
	::Suicides <- 0
}

::UnlockYaoi <- function(n) {
	if (Yaoichievements[n]) {
		return
	}
	::Yaoichievements[n] = true
	EntFire("yaoi_lock_" + n, "Break")
	Chat(WHITE + "Yaoichievement unlocked: " + VIOLET + YaoichievementNames[n])
}

::AddHook("player_say", "read_chat", function(d) {
	if (d.text == "i am become fujoshi") {
		UnlockYaoi(YAOI_CMBYN)
	}

	local txt = d.text.tolower()
	if (txt.len() == 5) {
		local isWord = true
		local isCorrect = true
		local response = ""
		for (local i = 0; i < 5; i++) {
			local chr = txt.slice(i, i + 1)
			if (chr >= "a" && chr <= "z") {
				local colour = RED
				if (chr == WORDLE.slice(i, i + 1)) {
					colour = GREEN
				} else {
					isCorrect = false
					if (WORDLE.find(chr) != null) {
						colour = YELLOW
					}
				}
				response += colour + chr
			} else {
				isWord = false
			}
		}
		if (isWord)
			Chat(response)
		if (isCorrect)
			Chat(GREEN + "Good job! A new word has been chosen.")
	}
})

::MethIngredients <- [0, 0, 0]
::MethIngredientNames <- [
	"Hydrogen Chloride",
	"Caustic Soda",
	"Muriatic Acid"
]

::MethCollect <- function(i) {
	::MethIngredients[i]++
	Chat(LIGHT_BLUE + MethIngredientNames[i] + ": " + MethIngredients[i] + "/3")
	if (MethIngredients[0] >= 3 && MethIngredients[1] >= 3 && MethIngredients[2] >= 3) {
		EntFire("meth_template", "ForceSpawn")
	}
}

::MethEmpty <- function(p) {
	CenterPrint(p, "These are empty, we need more ingredients.")
}

::MethBreak <- function() {
	UnlockYaoi(YAOI_ARH)
}

::PickupRory <- function(n) {
	EntFire("rory_" + n, "Kill")
	if (RorysFound[n]) {
		return
	}
	RorysFound[n] = true
	local total = 0
	for (local i = 0; i < 6; i++) {
		if (RorysFound[i]) {
			total++
		}
	}
	Chat(VIOLET + "Plushies: " + total + "/6")
	if (total >= 6) {
		UnlockYaoi(YAOI_TOY)
	}
}

if (!("WORDLE" in getroottable())) {
	::WORDLES <- ["cigar", "rebut", "sissy", "humph", "awake", "blush", "focal", "evade", "naval", "serve", "heath", "dwarf", "model", "karma", "stink", "grade", "quiet", "bench", "abate", "feign", "major", "death", "fresh", "crust", "stool", "colon", "abase", "marry", "react", "batty", "pride", "floss", "helix", "croak", "staff", "paper", "unfed", "whelp", "trawl", "outdo", "adobe", "crazy", "sower", "repay", "digit", "crate", "cluck", "spike", "mimic", "pound", "maxim", "linen", "unmet", "flesh", "booby", "forth", "first", "stand", "belly", "ivory", "seedy", "print", "yearn", "drain", "bribe", "stout", "panel", "crass", "flume", "offal", "agree", "error", "swirl", "argue", "bleed", "delta", "flick", "totem", "wooer", "front", "shrub", "parry", "biome", "lapel", "start", "greet", "goner", "golem", "lusty", "loopy", "round", "audit", "lying", "gamma", "labor", "islet", "civic", "forge", "corny", "moult", "basic", "salad", "agate", "spicy", "spray", "essay", "fjord", "spend", "kebab", "guild", "aback", "motor", "alone", "hatch", "hyper", "thumb", "dowry", "ought", "belch", "dutch", "pilot", "tweed", "comet", "jaunt", "enema", "steed", "abyss", "growl", "fling", "dozen", "boozy", "erode", "world", "gouge", "click", "briar", "great", "altar", "pulpy", "blurt", "coast", "duchy", "groin", "fixer", "group", "rogue", "badly", "smart", "pithy", "gaudy", "chill", "heron", "vodka", "finer", "surer", "radio", "rouge", "perch", "retch", "wrote", "clock", "tilde", "store", "prove", "bring", "solve", "cheat", "grime", "exult", "usher", "epoch", "triad", "break", "rhino", "viral", "conic", "masse", "sonic", "vital", "trace", "using", "peach", "champ", "baton", "brake", "pluck", "craze", "gripe", "weary", "picky", "acute", "ferry", "aside", "tapir", "troll", "unify", "rebus", "boost", "truss", "siege", "tiger", "banal", "slump", "crank", "gorge", "query", "drink", "favor", "abbey", "tangy", "panic", "solar", "shire", "proxy", "point", "robot", "prick", "wince", "crimp", "knoll", "sugar", "whack", "mount", "perky", "could", "wrung", "light", "those", "moist", "shard", "pleat", "aloft", "skill", "elder", "frame", "humor", "pause", "ulcer", "ultra", "robin", "cynic", "agora", "aroma", "caulk", "shake", "pupal", "dodge", "swill", "tacit", "other", "thorn", "trove", "bloke", "vivid", "spill", "chant", "choke", "rupee", "nasty", "mourn", "ahead", "brine", "cloth", "hoard", "sweet", "month", "lapse", "watch", "today", "focus", "smelt", "tease", "cater", "movie", "lynch", "saute", "allow", "renew", "their", "slosh", "purge", "chest", "depot", "epoxy", "nymph", "found", "shall", "harry", "stove", "lowly", "snout", "trope", "fewer", "shawl", "natal", "fibre", "comma", "foray", "scare", "stair", "black", "squad", "royal", "chunk", "mince", "slave", "shame", "cheek", "ample", "flair", "foyer", "cargo", "oxide", "plant", "olive", "inert", "askew", "heist", "shown", "zesty", "hasty", "trash", "fella", "larva", "forgo", "story", "hairy", "train", "homer", "badge", "midst", "canny", "fetus", "butch", "farce", "slung", "tipsy", "metal", "yield", "delve", "being", "scour", "glass", "gamer", "scrap", "money", "hinge", "album", "vouch", "asset", "tiara", "crept", "bayou", "atoll", "manor", "creak", "showy", "phase", "froth", "depth", "gloom", "flood", "trait", "girth", "piety", "payer", "goose", "float", "donor", "atone", "primo", "apron", "blown", "cacao", "loser", "input", "gloat", "awful", "brink", "smite", "beady", "rusty", "retro", "droll", "gawky", "hutch", "pinto", "gaily", "egret", "lilac", "sever", "field", "fluff", "hydro", "flack", "agape", "wench", "voice", "stead", "stalk", "berth", "madam", "night", "bland", "liver", "wedge", "augur", "roomy", "wacky", "flock", "angry", "bobby", "trite", "aphid", "tryst", "midge", "power", "elope", "cinch", "motto", "stomp", "upset", "bluff", "cramp", "quart", "coyly", "youth", "rhyme", "buggy", "alien", "smear", "unfit", "patty", "cling", "glean", "label", "hunky", "khaki", "poker", "gruel", "twice", "twang", "shrug", "treat", "unlit", "waste", "merit", "woven", "octal", "needy", "clown", "widow", "irony", "ruder", "gauze", "chief", "onset", "prize", "fungi", "charm", "gully", "inter", "whoop", "taunt", "leery", "class", "theme", "lofty", "tibia", "booze", "alpha", "thyme", "eclat", "doubt", "parer", "chute", "stick", "trice", "alike", "sooth", "recap", "saint", "liege", "glory", "grate", "admit", "brisk", "soggy", "usurp", "scald", "scorn", "leave", "twine", "sting", "bough", "marsh", "sloth", "dandy", "vigor", "howdy", "enjoy", "valid", "ionic", "equal", "unset", "floor", "catch", "spade", "stein", "exist", "quirk", "denim", "grove", "spiel", "mummy", "fault", "foggy", "flout", "carry", "sneak", "libel", "waltz", "aptly", "piney", "inept", "aloud", "photo", "dream", "stale", "vomit", "ombre", "fanny", "unite", "snarl", "baker", "there", "glyph", "pooch", "hippy", "spell", "folly", "louse", "gulch", "vault", "godly", "threw", "fleet", "grave", "inane", "shock", "crave", "spite", "valve", "skimp", "claim", "rainy", "musty", "pique", "daddy", "quasi", "arise", "aging", "valet", "opium", "avert", "stuck", "recut", "mulch", "genre", "plume", "rifle", "count", "incur", "total", "wrest", "mocha", "deter", "study", "lover", "safer", "rivet", "funny", "smoke", "mound", "undue", "sedan", "pagan", "swine", "guile", "gusty", "equip", "tough", "canoe", "chaos", "covet", "human", "udder", "lunch", "blast", "stray", "manga", "melee", "lefty", "quick", "paste", "given", "octet", "risen", "groan", "leaky", "grind", "carve", "loose", "sadly", "spilt", "apple", "slack", "honey", "final", "sheen", "eerie", "minty", "slick", "derby", "wharf", "spelt", "coach", "erupt", "singe", "price", "spawn", "fairy", "jiffy", "filmy", "stack", "chose", "sleep", "ardor", "nanny", "niece", "woozy", "handy", "grace", "ditto", "stank", "cream", "usual", "diode", "valor", "angle", "ninja", "muddy", "chase", "reply", "prone", "spoil", "heart", "shade", "diner", "arson", "onion", "sleet", "dowel", "couch", "palsy", "bowel", "smile", "evoke", "creek", "lance", "eagle", "idiot", "siren", "built", "embed", "award", "dross", "annul", "goody", "frown", "patio", "laden", "humid", "elite", "lymph", "edify", "might", "reset", "visit", "gusto", "purse", "vapor", "crock", "write", "sunny", "loath", "chaff", "slide", "queer", "venom", "stamp", "sorry", "still", "acorn", "aping", "pushy", "tamer", "hater", "mania", "awoke", "brawn", "swift", "exile", "birch", "lucky", "freer", "risky", "ghost", "plier", "lunar", "winch", "snare", "nurse", "house", "borax", "nicer", "lurch", "exalt", "about", "savvy", "toxin", "tunic", "pried", "inlay", "chump", "lanky", "cress", "eater", "elude", "cycle", "kitty", "boule", "moron", "tenet", "place", "lobby", "plush", "vigil", "index", "blink", "clung", "qualm", "croup", "clink", "juicy", "stage", "decay", "nerve", "flier", "shaft", "crook", "clean", "china", "ridge", "vowel", "gnome", "snuck", "icing", "spiny", "rigor", "snail", "flown", "rabid", "prose", "thank", "poppy", "budge", "fiber", "moldy", "dowdy", "kneel", "track", "caddy", "quell", "dumpy", "paler", "swore", "rebar", "scuba", "splat", "flyer", "horny", "mason", "doing", "ozone", "amply", "molar", "ovary", "beset", "queue", "cliff", "magic", "truce", "sport", "fritz", "edict", "twirl", "verse", "llama", "eaten", "range", "whisk", "hovel", "rehab", "macaw", "sigma", "spout", "verve", "sushi", "dying", "fetid", "brain", "buddy", "thump", "scion", "candy", "chord", "basin", "march", "crowd", "arbor", "gayly", "musky", "stain", "dally", "bless", "bravo", "stung", "title", "ruler", "kiosk", "blond", "ennui", "layer", "fluid", "tatty", "score", "cutie", "zebra", "barge", "matey", "bluer", "aider", "shook", "river", "privy", "betel", "frisk", "bongo", "begun", "azure", "weave", "genie", "sound", "glove", "braid", "scope", "wryly", "rover", "assay", "ocean", "bloom", "irate", "later", "woken", "silky", "wreck", "dwelt", "slate", "smack", "solid", "amaze", "hazel", "wrist", "jolly", "globe", "flint", "rouse", "civil", "vista", "relax", "cover", "alive", "beech", "jetty", "bliss", "vocal", "often", "dolly", "eight", "joker", "since", "event", "ensue", "shunt", "diver", "poser", "worst", "sweep", "alley", "creed", "anime", "leafy", "bosom", "dunce", "stare", "pudgy", "waive", "choir", "stood", "spoke", "outgo", "delay", "bilge", "ideal", "clasp", "seize", "hotly", "laugh", "sieve", "block", "meant", "grape", "noose", "hardy", "shied", "drawl", "daisy", "putty", "strut", "burnt", "tulip", "crick", "idyll", "vixen", "furor", "geeky", "cough", "naive", "shoal", "stork", "bathe", "aunty", "check", "prime", "brass", "outer", "furry", "razor", "elect", "evict", "imply", "demur", "quota", "haven", "cavil", "swear", "crump", "dough", "gavel", "wagon", "salon", "nudge", "harem", "pitch", "sworn", "pupil", "excel", "stony", "cabin", "unzip", "queen", "trout", "polyp", "earth", "storm", "until", "taper", "enter", "child", "adopt", "minor", "fatty", "husky", "brave", "filet", "slime", "glint", "tread", "steal", "regal", "guest", "every", "murky", "share", "spore", "hoist", "buxom", "inner", "otter", "dimly", "level", "sumac", "donut", "stilt", "arena", "sheet", "scrub", "fancy", "slimy", "pearl", "silly", "porch", "dingo", "sepia", "amble", "shady", "bread", "friar", "reign", "dairy", "quill", "cross", "brood", "tuber", "shear", "posit", "blank", "villa", "shank", "piggy", "freak", "which", "among", "fecal", "shell", "would", "algae", "large", "rabbi", "agony", "amuse", "bushy", "copse", "swoon", "knife", "pouch", "ascot", "plane", "crown", "urban", "snide", "relay", "abide", "viola", "rajah", "straw", "dilly", "crash", "amass", "third", "trick", "tutor", "woody", "blurb", "grief", "disco", "where", "sassy", "beach", "sauna", "comic", "clued", "creep", "caste", "graze", "snuff", "frock", "gonad", "drunk", "prong", "lurid", "steel", "halve", "buyer", "vinyl", "utile", "smell", "adage", "worry", "tasty", "local", "trade", "finch", "ashen", "modal", "gaunt", "clove", "enact", "adorn", "roast", "speck", "sheik", "missy", "grunt", "snoop", "party", "touch", "mafia", "emcee", "array", "south", "vapid", "jelly", "skulk", "angst", "tubal", "lower", "crest", "sweat", "cyber", "adore", "tardy", "swami", "notch", "groom", "roach", "hitch", "young", "align", "ready", "frond", "strap", "puree", "realm", "venue", "swarm", "offer", "seven", "dryer", "diary", "dryly", "drank", "acrid", "heady", "theta", "junto", "pixie", "quoth", "bonus", "shalt", "penne", "amend", "datum", "build", "piano", "shelf", "lodge", "suing", "rearm", "coral", "ramen", "worth", "psalm", "infer", "overt", "mayor", "ovoid", "glide", "usage", "poise", "randy", "chuck", "prank", "fishy", "tooth", "ether", "drove", "idler", "swath", "stint", "while", "begat", "apply", "slang", "tarot", "radar", "credo", "aware", "canon", "shift", "timer", "bylaw", "serum", "three", "steak", "iliac", "shirk", "blunt", "puppy", "penal", "joist", "bunny", "shape", "beget", "wheel", "adept", "stunt", "stole", "topaz", "chore", "fluke", "afoot", "bloat", "bully", "dense", "caper", "sneer", "boxer", "jumbo", "lunge", "space", "avail", "short", "slurp", "loyal", "flirt", "pizza", "conch", "tempo", "droop", "plate", "bible", "plunk", "afoul", "savoy", "steep", "agile", "stake", "dwell", "knave", "beard", "arose", "motif", "smash", "broil", "glare", "shove", "baggy", "mammy", "swamp", "along", "rugby", "wager", "quack", "squat", "snaky", "debit", "mange", "skate", "ninth", "joust", "tramp", "spurn", "medal", "micro", "rebel", "flank", "learn", "nadir", "maple", "comfy", "remit", "gruff", "ester", "least", "mogul", "fetch", "cause", "oaken", "aglow", "meaty", "gaffe", "shyly", "racer", "prowl", "thief", "stern", "poesy", "rocky", "tweet", "waist", "spire", "grope", "havoc", "patsy", "truly", "forty", "deity", "uncle", "swish", "giver", "preen", "bevel", "lemur", "draft", "slope", "annoy", "lingo", "bleak", "ditty", "curly", "cedar", "dirge", "grown", "horde", "drool", "shuck", "crypt", "cumin", "stock", "gravy", "locus", "wider", "breed", "quite", "chafe", "cache", "blimp", "deign", "fiend", "logic", "cheap", "elide", "rigid", "FALSE", "renal", "pence", "rowdy", "shoot", "blaze", "envoy", "posse", "brief", "never", "abort", "mouse", "mucky", "sulky", "fiery", "media", "trunk", "yeast", "clear", "skunk", "scalp", "bitty", "cider", "koala", "duvet", "segue", "creme", "super", "grill", "after", "owner", "ember", "reach", "nobly", "empty", "speed", "gipsy", "recur", "smock", "dread", "merge", "burst", "kappa", "amity", "shaky", "hover", "carol", "snort", "synod", "faint", "haunt", "flour", "chair", "detox", "shrew", "tense", "plied", "quark", "burly", "novel", "waxen", "stoic", "jerky", "blitz", "beefy", "lyric", "hussy", "towel", "quilt", "below", "bingo", "wispy", "brash", "scone", "toast", "easel", "saucy", "value", "spice", "honor", "route", "sharp", "bawdy", "radii", "skull", "phony", "issue", "lager", "swell", "urine", "gassy", "trial", "flora", "upper", "latch", "wight", "brick", "retry", "holly", "decal", "grass", "shack", "dogma", "mover", "defer", "sober", "optic", "crier", "vying", "nomad", "flute", "hippo", "shark", "drier", "obese", "bugle", "tawny", "chalk", "feast", "ruddy", "pedal", "scarf", "cruel", "bleat", "tidal", "slush", "semen", "windy", "dusty", "sally", "igloo", "nerdy", "jewel", "shone", "whale", "hymen", "abuse", "fugue", "elbow", "crumb", "pansy", "welsh", "syrup", "terse", "suave", "gamut", "swung", "drake", "freed", "afire", "shirt", "grout", "oddly", "tithe", "plaid", "dummy", "broom", "blind", "torch", "enemy", "again", "tying", "pesky", "alter", "gazer", "noble", "ethos", "bride", "extol", "decor", "hobby", "beast", "idiom", "utter", "these", "sixth", "alarm", "erase", "elegy", "spunk", "piper", "scaly", "scold", "hefty", "chick", "sooty", "canal", "whiny", "slash", "quake", "joint", "swept", "prude", "heavy", "wield", "femme", "lasso", "maize", "shale", "screw", "spree", "smoky", "whiff", "scent", "glade", "spent", "prism", "stoke", "riper", "orbit", "cocoa", "guilt", "humus", "shush", "table", "smirk", "wrong", "noisy", "alert", "shiny", "elate", "resin", "whole", "hunch", "pixel", "polar", "hotel", "sword", "cleat", "mango", "rumba", "puffy", "filly", "billy", "leash", "clout", "dance", "ovate", "facet", "chili", "paint", "liner", "curio", "salty", "audio", "snake", "fable", "cloak", "navel", "spurt", "pesto", "balmy", "flash", "unwed", "early", "churn", "weedy", "stump", "lease", "witty", "wimpy", "spoof", "saner", "blend", "salsa", "thick", "warty", "manic", "blare", "squib", "spoon", "probe", "crepe", "knack", "force", "debut", "order", "haste", "teeth", "agent", "widen", "icily", "slice", "ingot", "clash", "juror", "blood", "abode", "throw", "unity", "pivot", "slept", "troop", "spare", "sewer", "parse", "morph", "cacti", "tacky", "spool", "demon", "moody", "annex", "begin", "fuzzy", "patch", "water", "lumpy", "admin", "omega", "limit", "tabby", "macho", "aisle", "skiff", "basis", "plank", "verge", "botch", "crawl", "lousy", "slain", "cubic", "raise", "wrack", "guide", "foist", "cameo", "under", "actor", "revue", "fraud", "harpy", "scoop", "climb", "refer", "olden", "clerk", "debar", "tally", "ethic", "cairn", "tulle", "ghoul", "hilly", "crude", "apart", "scale", "older", "plain", "sperm", "briny", "abbot", "rerun", "quest", "crisp", "bound", "befit", "drawn", "suite", "itchy", "cheer", "bagel", "guess", "broad", "axiom", "chard", "caput", "leant", "harsh", "curse", "proud", "swing", "opine", "taste", "lupus", "gumbo", "miner", "green", "chasm", "lipid", "topic", "armor", "brush", "crane", "mural", "abled", "habit", "bossy", "maker", "dusky", "dizzy", "lithe", "brook", "jazzy", "fifty", "sense", "giant", "surly", "legal", "fatal", "flunk", "began", "prune", "small", "slant", "scoff", "torus", "ninny", "covey", "viper", "taken", "moral", "vogue", "owing", "token", "entry", "booth", "voter", "chide", "elfin", "ebony", "neigh", "minim", "melon", "kneed", "decoy", "voila", "ankle", "arrow", "mushy", "tribe", "cease", "eager", "birth", "graph", "odder", "terra", "weird", "tried", "clack", "color", "rough", "weigh", "uncut", "ladle", "strip", "craft", "minus", "dicey", "titan", "lucid", "vicar", "dress", "ditch", "gypsy", "pasta", "taffy", "flame", "swoop", "aloof", "sight", "broke", "teary", "chart", "sixty", "wordy", "sheer", "leper", "nosey", "bulge", "savor", "clamp", "funky", "foamy", "toxic", "brand", "plumb", "dingy", "butte", "drill", "tripe", "bicep", "tenor", "krill", "worse", "drama", "hyena", "think", "ratio", "cobra", "basil", "scrum", "bused", "phone", "court", "camel", "proof", "heard", "angel", "petal", "pouty", "throb", "maybe", "fetal", "sprig", "spine", "shout", "cadet", "macro", "dodgy", "satyr", "rarer", "binge", "trend", "nutty", "leapt", "amiss", "split", "myrrh", "width", "sonar", "tower", "baron", "fever", "waver", "spark", "belie", "sloop", "expel", "smote", "baler", "above", "north", "wafer", "scant", "frill", "awash", "snack", "scowl", "frail", "drift", "limbo", "fence", "motel", "ounce", "wreak", "revel", "talon", "prior", "knelt", "cello", "flake", "debug", "anode", "crime", "salve", "scout", "imbue", "pinky", "stave", "vague", "chock", "fight", "video", "stone", "teach", "cleft", "frost", "prawn", "booty", "twist", "apnea", "stiff", "plaza", "ledge", "tweak", "board", "grant", "medic", "bacon", "cable", "brawl", "slunk", "raspy", "forum", "drone", "women", "mucus", "boast", "toddy", "coven", "tumor", "truer", "wrath", "stall", "steam", "axial", "purer", "daily", "trail", "niche", "mealy", "juice", "nylon", "plump", "merry", "flail", "papal", "wheat", "berry", "cower", "erect", "brute", "leggy", "snipe", "sinew", "skier", "penny", "jumpy", "rally", "umbra", "scary", "modem", "gross", "avian", "greed", "satin", "tonic", "parka", "sniff", "livid", "stark", "trump", "giddy", "reuse", "taboo", "avoid", "quote", "devil", "liken", "gloss", "gayer", "beret", "noise", "gland", "dealt", "sling", "rumor", "opera", "thigh", "tonga", "flare", "wound", "white", "bulky", "etude", "horse", "circa", "paddy", "inbox", "fizzy", "grain", "exert", "surge", "gleam", "belle", "salvo", "crush", "fruit", "sappy", "taker", "tract", "ovine", "spiky", "frank", "reedy", "filth", "spasm", "heave", "mambo", "right", "clank", "trust", "lumen", "borne", "spook", "sauce", "amber", "lathe", "carat", "corer", "dirty", "slyly", "affix", "alloy", "taint", "sheep", "kinky", "wooly", "mauve", "flung", "yacht", "fried", "quail", "brunt", "grimy", "curvy", "cagey", "rinse", "deuce", "state", "grasp", "milky", "bison", "graft", "sandy", "baste", "flask", "hedge", "girly", "swash", "boney", "coupe", "endow", "abhor", "welch", "blade", "tight", "geese", "miser", "mirth", "cloud", "cabal", "leech", "close", "tenth", "pecan", "droit", "grail", "clone", "guise", "ralph", "tango", "biddy", "smith", "mower", "payee", "serif", "drape", "fifth", "spank", "glaze", "allot", "truck", "kayak", "virus", "testy", "tepee", "fully", "zonal", "metro", "curry", "grand", "banjo", "axion", "bezel", "occur", "chain", "nasal", "gooey", "filer", "brace", "allay", "pubic", "raven", "plead", "gnash", "flaky", "munch", "dully", "eking", "thing", "slink", "hurry", "theft", "shorn", "pygmy", "ranch", "wring", "lemon", "shore", "mamma", "froze", "newer", "style", "moose", "antic", "drown", "vegan", "chess", "guppy", "union", "lever", "lorry", "image", "cabby", "druid", "exact", "truth", "dopey", "spear", "cried", "chime", "crony", "stunk", "timid", "batch", "gauge", "rotor", "crack", "curve", "latte", "witch", "bunch", "repel", "anvil", "soapy", "meter", "broth", "madly", "dried", "scene", "known", "magma", "roost", "woman", "thong", "punch", "pasty", "downy", "knead", "whirl", "rapid", "clang", "anger", "drive", "goofy", "email", "music", "stuff", "bleep", "rider", "mecca", "folio", "setup", "verso", "quash", "fauna", "gummy", "happy", "newly", "fussy", "relic", "guava", "ratty", "fudge", "femur", "chirp", "forte", "alibi", "whine", "petty", "golly", "plait", "fleck", "felon", "gourd", "brown", "thrum", "ficus", "stash", "decry", "wiser", "junta", "visor", "daunt", "scree", "impel", "await", "press", "whose", "turbo", "stoop", "speak", "mangy", "eying", "inlet", "crone", "pulse", "mossy", "staid", "hence", "pinch", "teddy", "sully", "snore", "ripen", "snowy", "attic", "going", "leach", "mouth", "hound", "clump", "tonal", "bigot", "peril", "piece", "blame", "haute", "spied", "undid", "intro", "basal", "shine", "gecko", "rodeo", "guard", "steer", "loamy", "scamp", "scram", "manly", "hello", "vaunt", "organ", "feral", "knock", "extra", "condo", "adapt", "willy", "polka", "rayon", "skirt", "faith", "torso", "match", "mercy", "tepid", "sleek", "riser", "twixt", "peace", "flush", "catty", "login", "eject", "roger", "rival", "untie", "refit", "aorta", "adult", "judge", "rower", "artsy", "rural", "shave"]
	::WORDLE <- RandomFromArray(WORDLES)
}
