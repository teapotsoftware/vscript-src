
IncludeScript("butil")

SendToConsoleServer("mp_roundtime 60")

for (local i = 1; i <= 2; i++)
	EntFire("limo" + i + "-body", "AddOutput", "texframeindex " + 2)

for (local i = 1; i <= 4; i++)
	EntFire("miltaryheli" + i + "-body", "AddOutput", "texframeindex " + 23)
	
for (local i = 1; i <= 48; i++)
	EntFire("car" + i + "-body", "AddOutput", "texframeindex " + RandomInt(0, 17))

::LastDeadPlayer <- null

::PlayerKillPlayer <- function(attacker, victim)
{
	if (attacker.GetModelName() == victim.GetModelName() && SETTINGS[1].state == 1)
	{
		CenterPrint(attacker, "Don't kill your own kind!")
		Ignite(attacker, 10)
	}
}

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")

	local precached = false
	local ent = null
	while (ent = Entities.Next(ent))
	{
		if (!precached)
		{
			precached = true
			ent.PrecacheModel("models/weapons/v_models/arms/pirate/v_pirate_watch.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/bare/v_bare_hands.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/anarchist/v_glove_anarchist.mdl")
		}

		if (ent.ValidateScriptScope())
		{
			if (ent.GetClassname() == "player")
			{
				local ss = ent.GetScriptScope()
				ss.insured_loadout <- []
				ss.insured_clothes <- ""
				ss.insured_lives <- 0
				ss.owned_cars <- []
				ss.has_keycard <- false
			}
			else if (ent.GetName() == "cocaine")
			{
				ent.GetScriptScope().InputUse <- function()
				{
					if (activator != null && activator.ValidateScriptScope())
					{
						local ss = activator.GetScriptScope()
						if (!("last_cocaine" in ss))
							ss.last_cocaine <- -60

						if ("last_cocaine" in ss && Time() - ss.last_cocaine >= 60)
							return true
					}
					return false
				}
			}
			else if (ent.GetName() == "keycard_reader")
			{
				ent.GetScriptScope().InputUse <- function()
					return (activator != null && activator.ValidateScriptScope() && ("has_keycard" in activator.GetScriptScope()) && activator.GetScriptScope().has_keycard)
			}
		}
	}

	HookToPlayerDeath(function(ply) {
		// Disconnected player
		if (ply == null)
			return

		if (ply.ValidateScriptScope())
			ply.GetScriptScope().died <- true

		::LastDeadPlayer <- ply
	})

	HookToPlayerKill(function(ply) {
		PlayerKillPlayer(ply, LastDeadPlayer)
	})

	// blow the map up in an hour
	EntFire("script", "RunScriptCode", "TriggerNuke()", 3585)
}

::BOWLING_BALL_MODEL <- "models/props_junk/watermelon01.mdl"

Think <- function()
{
	local decoy = null
	while (decoy = Entities.FindByClassname(decoy, "decoy_projectile"))
	{
		if (decoy.GetModelName() != BOWLING_BALL_MODEL)
		{
			SetModelSafe(decoy, BOWLING_BALL_MODEL)
			decoy.__KeyValueFromString("rendercolor", "0 0 0")
		}
		else if (decoy.GetVelocity().Length() == 0)
			decoy.Destroy()
	}
}

::PickupWeapon <- function(pickup, wep)
{
	if (wep == "weapon_breachcharge" || wep == "weapon_bumpmine")
	{
		local deleted = []
		local ent = null
		while (ent = Entities.FindByClassnameWithin(ent, wep, pickup.GetOrigin(), 1000))
		{
			if (ent.GetOwner() == null)
				deleted.push(ent)
		}
		foreach (e in deleted)
			e.Destroy()
	}

	GiveWeapon(NearestPlayer(pickup.GetOrigin()), wep)
}

::PickupKeycard <- function(pickup)
{
	local ply = NearestPlayer(pickup.GetOrigin())
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if (!("has_keycard" in ss) || !ss.has_keycard)
		{
			ss.has_keycard <- true
			CenterPrint(ply, "Picked up keycard.")
			self.EmitSound("Player.PickupGrenade")
		}
	}
}

::EatChicken <- function(ply)
	ply.SetHealth(Clamp(ply.GetHealth() + 40, 0, ply.GetMaxHealth()))

::EatPizza <- function(ply)
	ply.SetHealth(Clamp(ply.GetHealth() + 10, 0, ply.GetMaxHealth()))

::DrinkBeer <- function(ply)
	ply.SetHealth(Clamp(ply.GetHealth() + 10, 0, ply.GetMaxHealth()))

::SnortCocaine <- function(ply)
{
	ModifySpeedTemporarily(ply, 1.5, 60)

	if (ply.ValidateScriptScope())
		ply.GetScriptScope().last_cocaine <- Time()
}

::ChangeClothes <- function(ply)
{
	local mannequin = Entities.FindByNameNearest("@mannequin", ply.GetOrigin(), 200)
	if (mannequin != null)
		SetModelSafe(ply, mannequin.GetModelName())
}

::BuyLifeInsurance <- function(ply)
{
	if (!ply.ValidateScriptScope())
		return

	EntFire("yuledai_covered_*", "StopSound") // doesn't work :(
	EntFire("yuledai_covered_" + ((RandomInt(2, 999999) % 2) + 1), "PlaySound")

	local ss = ply.GetScriptScope()
	ss.insured_loadout <- []
	local wep = null
	while (wep = Entities.FindByClassname(wep, "weapon_*"))
	{
		if (wep.GetOwner() == ply && wep.GetClassname() != "weapon_knife")
			ss.insured_loadout.push(wep.GetClassname())
	}
	ss.insured_clothes <- ply.GetModelName()
	ss.insured_lives <- 2
	CenterPrint(ply, "Your items have been insured for your next 2 deaths. Pleasure doing business!")
}

::SpawnTrigger <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("died" in ss && ss.died)
		{
			if ("insured_lives" in ss && ss.insured_lives > 0)
			{
				ss.insured_lives--
				GiveWeapons(ply, ss.insured_loadout)
				SetModelSafe(ply, ss.insured_clothes)
				if (ss.insured_lives == 0)
					CenterPrint(ply, "Your insurance policy is now expired!")
				else
					CenterPrint(ply, "You have " + ss.insured_lives + " li" + (ss.insured_lives == 1 ? "fe" : "ves") + " remaining on your insurance policy.")
			}
			ss.died <- false
		}
	}
}

::CallMechanic <- function(ply)
{
	local spawnpoint = Entities.FindByNameNearest("car_spawnpoint", ply.GetOrigin(), 1000)
	if (spawnpoint != null && ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if ("owned_cars" in ss)
		{
			foreach (car in ss.owned_cars)
			{
				if (car.ValidateScriptScope() && car.GetScriptScope().LastDriver == ply)
				{
					car.GetScriptScope().Car.SetOrigin(spawnpoint.GetOrigin())
					EntFireHandle(spawnpoint, "PlaySound")
					break
				}
			}
		}
	}
}

::JUKEBOX_SONG <- 0
::JUKEBOX_SONGS <- 10

::CycleJukebox <- function()
{
	EntFire("club_song" + JUKEBOX_SONG, "StopSound")
	::JUKEBOX_SONG = (JUKEBOX_SONG + 1) % JUKEBOX_SONGS
	EntFire("club_song" + JUKEBOX_SONG, "PlaySound")
}

::OpenAdminRoom <- function()
	EntFire("admin_door", "toggle")

::NUKE_TRIGGERED <- false

::TriggerNuke <- function()
{
	if (NUKE_TRIGGERED)
		return

	::NUKE_TRIGGERED <- true

	ChatPrintAll(" " + RED + "OH SHIT!!! WE'RE GETTING NUKED!!!")
	EntFire("nuke_alarm", "PlaySound")
	EntFire("nuke_siren", "PlaySound", "", 1)
	EntFire("script", "RunScriptCode", "NukeKill()", 12)
}

::NukeKill <- function()
{
	SendToConsoleServer("mp_respawn_on_death_t 0")
	SendToConsoleServer("mp_respawn_on_death_ct 0")
	EntFire("nuke_roundend", "EndRound_Draw", "7")
	EntFire("nuke_death", "PlaySound")
	EntFire("nuke_fade", "Fade")
	EntFire("nuke_hurt", "Enable")
	EntFire("nuke_hurt", "Disable", "", 0.1)
	EntFire("nuke_fade", "FadeReverse", "", 2)
}

::SECRETS_FOUND <- 0

::FindSecret <- function(i)
{
	EntFire("secret_sprite_" + i, "EnableDraw")
	EntFire("secret_find_sound", "PlaySound")
	::SECRETS_FOUND++

/*
	if (SECRETS_FOUND < 7)
		ChatPrintAll(" " + RED + SECRETS_FOUND + "/7")
	else
		ChatPrintAll(" " + RED + "Ready")
*/
}

::TrySecret <- function()
{
	if (SECRETS_FOUND < 7)
		return

	EntFire("secret_shake", "StartShake")
	EntFire("secret_sound", "PlaySound")
	EntFire("skybox_gargoyle_template", "ForceSpawn")
	EntFire("lake_hatch", "open", "", 20)
}

::SETTINGS <- [
	{
		name = "Teammates are enemies",
		state = 0,
		options = [
			[RED + "OFF", "mp_teammates_are_enemies 0"],
			[GREEN + "ON", "mp_teammates_are_enemies 1"]
		]
	},
	{
		name = "Punish for killing same skin",
		state = 0,
		options = [
			[RED + "OFF", false],
			[GREEN + "ON", false]
		]
	},
	{
		name = "Weapon spread",
		state = 1,
		options = [
			[RED + "OFF", "weapon_accuracy_nospread 1"],
			[GREEN + "ON", "weapon_accuracy_nospread 0"]
		]
	},
	{
		name = "Auto bunny hopping",
		state = 0,
		options = [
			[RED + "OFF", "sv_autobunnyhopping 0"],
			[GREEN + "ON", "sv_autobunnyhopping 1"]
		]
	},
	{
		name = "Gravity",
		state = 0,
		options = [
			[RED + "NORMAL", "sv_gravity 800"],
			[YELLOW + "LOWER", "sv_gravity 400"],
			[GREEN + "LOWEST", "sv_gravity 200"]
		]
	},
	{
		name = "Fall damage",
		state = 0,
		options = [
			[RED + "FULL", "sv_falldamage_scale 1"],
			[YELLOW + "REDUCED", "sv_falldamage_scale 0.15"],
			[GREEN + "OFF", "sv_falldamage_scale 0"]
		]
	},
	{
		name = "Infinite ammo",
		state = 0,
		options = [
			[RED + "OFF", "sv_infinite_ammo 0"],
			[YELLOW + "WITH RELOAD", "sv_infinite_ammo 2"],
			[GREEN + "ON", "sv_infinite_ammo 1"]
		]
	}
]

::CycleSetting <- function(i)
{
	::SETTINGS[i].state = (SETTINGS[i].state + 1) % SETTINGS[i].options.len()
	ChatPrintAll(SETTINGS[i].name + ": " + SETTINGS[i].options[SETTINGS[i].state][0])
	EntFire("admin_button_" + i, "AddOutput", "texframeindex " + SETTINGS[i].state)

	if (SETTINGS[i].options[SETTINGS[i].state][1])
		SendToConsoleServer(SETTINGS[i].options[SETTINGS[i].state][1])
}

::SwipeKeycard <- function()
{
	local n = (GetLivingPlayers().len() < 2) ? 2 : 1
	EntFire("hideout_counter", "add", n)
	EntFire("hideout_counter", "subtract", n, 0.5)
}

::GodSay <- function(txt)
	ChatPrintAll(" " + RED + " The Lion :" + WHITE + " " + txt)

::APOLLYON_ACTIVATED <- false

::StartConvo <- function()
{
	GodSay("How now, mortal. What is it you want from me?")
	::APOLLYON_ACTIVATED <- true
}
