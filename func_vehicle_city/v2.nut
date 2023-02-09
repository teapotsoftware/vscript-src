
IncludeScript("butil")

SendToConsoleServer("mp_roundtime 60")

for (local i = 1; i <= 16; i++) {
	EntFire("car" + i + "-body", "AddOutput", "texframeindex " + RandomInt(0, 17))
	EntFire("car" + i + "-script", "RunScriptCode", "PersonalVehicle = true ")
}

EntFire("heli5-script", "RunScriptCode", "SetStartAltitude(53)")
EntFire("heli6-script", "RunScriptCode", "SetStartAltitude(9)")

::LastDeadPlayer <- null

::PlayerKillPlayer <- function(attacker, victim)
{
	if (attacker.GetModelName() == victim.GetModelName() && SETTINGS[1].state == 1)
	{
		CenterPrint(attacker, "Don't kill friends!")
		Ignite(attacker, 10)
	}
}

::GiveKnife <- function(ply, name) {
	local weps = GetWeapons(ply)
	foreach (wep in weps) {
		local cls = wep.GetClassname()
		if (cls == "weapon_knife" || cls == "weapon_knifegg") {
			wep.Destroy()
		}
	}
	if (name == "bayonet" || name == "knifegg") {
		GiveWeapon(ply, "weapon_" + name)
	} else {
		GiveWeapon(ply, "weapon_knife_" + name)
	}
	MeleeFixup()
}

::PUSHKNIFE <- "push" // used in map I/O

::SetKnife <- function(ply, name) {
	if (ply.ValidateScriptScope()) {
		ply.GetScriptScope().knife <- name
	}

	GiveKnife(ply, name)
}

::LightCandle <- function(candle) {
	if (typeof candle == "integer") {
		candle = Entities.FindByName(null, "666c" + candle)
		if (candle == null)
			return
	}
	SetModelSafe(candle, "models/props/de_aztec/hr_aztec/aztec_lighting/aztec_lighting_candle_02_lit.mdl")
}

::GiveDrugNeedle <- function(ply) {
	GiveWeapon(ply, WEAPON_HEALTHSHOT)
	CenterPrint(ply, "I'm not so sure about this needle...")
}

::GetStoned <- function(ply) {
	EntFireHandle(ply, "AddOutput", "gravity 0.6")
	EntFireHandle(ply, "AddOutput", "gravity 1.0", 45)
}

OnPostSpawn <- function() {
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")

	local precached = false
	local ent = null
	while (ent = Entities.Next(ent)) {
		if (!precached) {
			precached = true
			ent.PrecacheModel("models/weapons/v_models/arms/pirate/v_pirate_watch.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/bare/v_bare_hands.mdl")
			ent.PrecacheModel("models/weapons/v_models/arms/anarchist/v_glove_anarchist.mdl")
		}

		if (ent.ValidateScriptScope()) {
			local classname = ent.GetClassname()
			local name = ent.GetName()

			if (classname == "player") {
				local ss = ent.GetScriptScope()
				ss.insured_loadout <- []
				ss.insured_clothes <- ""
				ss.insured_lives <- 0
				ss.knife <- ""
				ss.owned_cars <- []
				ss.has_keycard <- false
				EntFireHandle(ent, "RunScriptCode", "SpawnCar(self)", 0.1)
			} else if (name == "@cocaine") {
				ent.GetScriptScope().InputUse <- function() {
					if (activator != null && activator.ValidateScriptScope()) {
						local ss = activator.GetScriptScope()
						if (!("last_cocaine" in ss))
							ss.last_cocaine <- -60

						if (Time() - ss.last_cocaine >= 60)
							return true
					}
					return false
				}
			} else if (name == "keycard_reader") {
				ent.GetScriptScope().InputUse <- function()
					return (activator != null && activator.ValidateScriptScope() && ("has_keycard" in activator.GetScriptScope()) && activator.GetScriptScope().has_keycard)
			} else if (name.len() > 8 && name.slice(0, 8) == "@pickup_") {
				ent.GetScriptScope().InputUse <- function() {
					GiveWeapon(activator, self.GetName().slice(8))
				}
			} else if (name.len() > 13  && name.slice(0, 13) == "@knifepickup_") {
				ent.GetScriptScope().InputUse <- function() {
					SetKnife(activator, self.GetName().slice(13))
				}
			}
		}
	}

	HookToPlayerDeath(function(ply) {
		// Disconnected player
		if (ply == null)
			return

		if (ply.ValidateScriptScope())
			ply.GetScriptScope().spawned <- false

		::LastDeadPlayer <- ply
	})

	HookToPlayerKill(function(ply) {
		PlayerKillPlayer(ply, LastDeadPlayer)
	})

	// parent airship turrets
	FixAirshipTurrets()

	// make sure crane starts stopped
	EntFire("script", "RunScriptCode", "StopCrane()", 0.01)

	// blow the map up in an hour
	EntFire("script", "RunScriptCode", "TriggerNuke()", 3585)
}

::BOWLING_BALL_MODEL <- "models/props_junk/watermelon01.mdl"

Think <- function() {
	local decoy = null
	while (decoy = Entities.FindByClassname(decoy, "decoy_projectile")) {
		if (decoy.GetModelName() != BOWLING_BALL_MODEL) {
			SetModelSafe(decoy, BOWLING_BALL_MODEL)
			decoy.__KeyValueFromString("rendercolor", "0 0 0")
		}
		else if (decoy.GetVelocity().Length() == 0)
			decoy.Destroy()
	}
}

::PickupWeapon <- function(pickup, wep) {
	if (wep == "weapon_breachcharge" || wep == "weapon_bumpmine") {
		local deleted = []
		local ent = null
		while (ent = Entities.FindByClassnameWithin(ent, wep, pickup.GetOrigin(), 1000)) {
			if (ent.GetOwner() == null)
				deleted.push(ent)
		}
		foreach (e in deleted)
			e.Destroy()
	}

	GiveWeapon(NearestPlayer(pickup.GetOrigin()), wep)
}

::PickupKeycard <- function(pickup) {
	local ply = NearestPlayer(pickup.GetOrigin())
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if (!("has_keycard" in ss) || !ss.has_keycard) {
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

::SnortCocaine <- function(ply) {
	ModifySpeedTemporarily(ply, 1.5, 60)

	if (ply.ValidateScriptScope())
		ply.GetScriptScope().last_cocaine <- Time()
}

::ChangeClothes <- function(ply) {
	local mannequin = Entities.FindByNameNearest("@mannequin", ply.GetOrigin(), 200)
	if (mannequin != null)
		SetModelSafe(ply, mannequin.GetModelName())
}

::BuyLifeInsurance <- function(ply) {
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
	ss.insured_lives <- 3
	CenterPrint(ply, "Your items have been insured for your next 3 deaths. Pleasure doing business!")
}

::SpawnTrigger <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local ss = ply.GetScriptScope()
		if (!("spawned" in ss && ss.spawned))
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
			if ("knife" in ss && ss.knife != "") {
				GiveKnife(ply, ss.knife)
			}
			EntFireHandle(ply, "RunScriptCode", "SpawnCar(self)", 0.1)
			ss.spawned <- true
		}
	}
}

::CallMechanic <- function(ply)
{
	local spawnpoint = Entities.FindByNameNearest("car_spawnpoint", ply.GetOrigin(), 1000)
	if (spawnpoint != null && ply.ValidateScriptScope())
	{
		local car = Entities.FindByName(null, "car" + ply.entindex() + "-script")
		car.GetScriptScope().Car.SetOrigin(spawnpoint.GetOrigin())
		EntFireHandle(spawnpoint, "PlaySound")
	}
/*
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
*/
}

::SpawnCar <- function(ply) {
	local car = Entities.FindByName(null, "car" + ply.entindex() + "-body")
	car.SetOrigin(ply.GetOrigin() + (ply.GetForwardVector() * 150) + Vector(0, 0, -4))
	local a = ply.GetAngles()
	car.SetAngles(a.x, (a.y + 270) % 360, a.z)
}

::JUKEBOX_SONG <- 0
::JUKEBOX_SONGS <- 10

::CycleJukebox <- function()
{
	EntFire("club_song" + JUKEBOX_SONG, "StopSound")
	::JUKEBOX_SONG = (JUKEBOX_SONG + 1) % JUKEBOX_SONGS
	EntFire("club_song" + JUKEBOX_SONG, "PlaySound")
}

::PUB_JUKEBOX_SONG <- 5
::PUB_JUKEBOX_SONGS <- 6

::CyclePubJukebox <- function()
{
	::PUB_JUKEBOX_SONG = (PUB_JUKEBOX_SONG + 1) % PUB_JUKEBOX_SONGS
	if (PUB_JUKEBOX_SONG > 0) {
		EntFire("pub_jukebox_song" + (PUB_JUKEBOX_SONG - 1), "StopSound")
	}
	if (PUB_JUKEBOX_SONG < 5) {
		EntFire("pub_jukebox_song" + PUB_JUKEBOX_SONG, "PlaySound")
	}
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

::LaunchRocket <- function() {
	Chat(RED + "Launch sequence initiated!")
	local t = 20
	EntFire("rocket_silo_cover", "Open", "", t - 15)
	EntFire("rocket_scaffold_folding", "Open", "", t - 5)
	EntFire("rocket_door", "Close", "", t - 5)
	EntFire("rocket_door", "Lock", "", t - 5)
	EntFire("rocket_booster_trails", "TurnOn", "", t - 3)
	EntFire("rocket_shake", "StartShake", "", t)
	EntFire("rocket_launch_sfx", "PlaySound", "", t)
	EntFire("rocket_booster_sprite", "ShowSprite", "", t)
	EntFire("rocket", "Open", "", t + 3.2)
	EntFire("rocket", "Kill", "", t + 20)
	EntFire("moon_land_sound", "PlaySound", "", t + 20)
	EntFire("moon_land_shake", "StartShake", "", t + 20)
	EntFire("moon_door", "Open", "", t + 25)
}

::CraneInputs <- [false, false, false, false] // back, forward, left, right

::CraneInput <- function(n) {
	if (n < 4) {
		CraneInputs[n] = true
	} else {
		CraneInputs[n % 4] = false
	}
	if (CraneInputs[0] != CraneInputs[1]) {
		EntFire("crane_slider", "Start" + (CraneInputs[0] ? "Forward" : "Backward"))
	} else {
		EntFire("crane_slider", "Stop")
	}
	if (CraneInputs[2] != CraneInputs[3]) {
		EntFire("crane", "Start" + (CraneInputs[2] ? "Forward" : "Backward"))
	} else {
		EntFire("crane", "Stop")
	}
}

::StopCrane <- function() {
	::CraneInputs = [false, false, false, false]
	EntFire("crane", "Stop")
	EntFire("crane_slider", "Stop")
	printl("Crane stopped!")
}

::FixAirshipTurrets <- function() {
	EntFire("airshipturret_port-turret_brush", "SetParent", "airship1-body")
	EntFire("airshipturret_port-turret_button", "SetParent", "airship1-body")
	EntFire("airshipturret_port-turret_legs", "SetParent", "airship1-body")
	EntFire("airshipturret_stbd-turret_brush", "SetParent", "airship1-body")
	EntFire("airshipturret_stbd-turret_button", "SetParent", "airship1-body")
	EntFire("airshipturret_stbd-turret_legs", "SetParent", "airship1-body")
	printl("FixAirshipTurrets OK!")
}
