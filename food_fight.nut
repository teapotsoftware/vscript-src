
IncludeScript("butil")

::SandbagMaker <- EntityGroup[0]
::SpawnPointMakers <- [null, null, EntityGroup[1], EntityGroup[2]]
::SpawnPointMarkerMaker <- EntityGroup[3]
::SpawnPointDisplays <- [null, null, EntityGroup[4], EntityGroup[5]]

::WEPTYPE_NULL <- 0
::WEPTYPE_PRIMARY <- 1
::WEPTYPE_SECONDARY <- 2
::WEPTYPE_KNIFE <- 3
::WEPTYPE_GRENADE <- 4
::WEPTYPE_UTILITY <- 5
::WEPTYPE_SHIELD <- 6

::WepNameToWepType <- {
	// knife
	knife = WEPTYPE_KNIFE,
	knifegg = WEPTYPE_KNIFE,
	// pistols
	glock = WEPTYPE_SECONDARY,
	hkp2000 = WEPTYPE_SECONDARY,
	p250 = WEPTYPE_SECONDARY,
	deagle = WEPTYPE_SECONDARY,
	revolver = WEPTYPE_SECONDARY,
	tec9 = WEPTYPE_SECONDARY,
	fiveseven = WEPTYPE_SECONDARY,
	cz75a = WEPTYPE_SECONDARY,
	elite = WEPTYPE_SECONDARY,
	// assault rifles
	famas = WEPTYPE_PRIMARY,
	m4a1 = WEPTYPE_PRIMARY,
	aug = WEPTYPE_PRIMARY,
	galilar = WEPTYPE_PRIMARY,
	ak47 = WEPTYPE_PRIMARY,
	sg556 = WEPTYPE_PRIMARY,
	// sniper rifles
	ssg08 = WEPTYPE_PRIMARY,
	awp = WEPTYPE_PRIMARY,
	g3sg1 = WEPTYPE_PRIMARY,
	scar20 = WEPTYPE_PRIMARY,
	// smgs
	mp9 = WEPTYPE_PRIMARY,
	mac10 = WEPTYPE_PRIMARY,
	mp7 = WEPTYPE_PRIMARY,
	ump45 = WEPTYPE_PRIMARY,
	p90 = WEPTYPE_PRIMARY,
	// shotguns
	nova = WEPTYPE_PRIMARY,
	sawedoff = WEPTYPE_PRIMARY,
	mag7 = WEPTYPE_PRIMARY,
	xm1014 = WEPTYPE_PRIMARY,
	// machine guns
	m249 = WEPTYPE_PRIMARY,
	negev = WEPTYPE_PRIMARY,
}

::wars <- {
	effects = {
		// bad
		jam = {
			name = "Dirty",
			color = "150 150 100",
			desc = "Constantly gets jammed", 
			weapon_fire = function(ply, data)
			{
				if (RandomInt(1, 12) == 1)
				{
					local wep = GetActiveWeapon(ply)
					if (wep == null)
						return
					EntFireHandle(wep, "SetAmmoAmount", "0")
					ShowHint(ply, "loot", "Jam!")
					ply.EmitSound("Weapon_P90.BoltForward")
				}
			}
		},
		recoil = {
			name = "Busted",
			color = "150 150 100",
			desc = "Terrible recoil", 
			weapon_fire = function(ply, data)
			{
				local ang = ply.GetAngles()
				ply.SetAngles(ang.x + RandomInt(2, 5), ang.y, 0)
			}
		},
		rocks = {
			name = "Rocky",
			color = "150 150 100",
			desc = "Uses rocks as ammo", 
			weapon_fire = function(ply, data)
			{
				if (HasItem(ply, "rocks"))
					GiveItem(ply, "rocks", -1)
				else
				{
					ply.EmitSound("Weapon_SSG08.BoltForward")
					ClientCMD(ply, "lastinv")
					ShowHint(ply, "loot", "No rocks!")
				}
			}
		},
		backfire = {
			name = "Shoddy",
			color = "150 150 100",
			desc = "Backfires occasionally", 
			weapon_fire = function(ply, data)
			{
				if (RandomInt(1, 5) == 1)
				{
					local wep = GetActiveWeapon(ply)
					if (wep == null)
						return
					if (ply.GetHealth() <= 10)
					{
						ply.SetHealth(1)
						EntFireHandle(ply, "IgniteLifetime", "0.1")
					}
					else
					{
						ply.SetHealth(ply.GetHealth() - 10)
						ShowHint(ply, "loot", "Backfire!")
					}
					ply.EmitSound("Weapon_SSG08.BoltForward")
				}
			}
		},
		curse = {
			name = "Cursed",
			color = "150 150 100",
			desc = "Hurts yourself for 20% of damage done", 
			player_hurt = function(ply, data)
			{
				local attacker = data.attacker_player
				local newhealth = attacker.GetHealth() - ceil(data.dmg_health * 0.2)
				if (newhealth < 1)
				{
					attacker.SetHealth(1)
					EntFireHandle(attacker, "IgniteLifetime", "0.1")
				}
				else
					attacker.SetHealth(newhealth)
			}
		},
		blood = {
			name = "Bloodborne",
			color = "150 150 100",
			desc = "Uses your health as ammo", 
			weapon_fire = function(ply, data)
			{
				local attacker = data.userid_player
				local newhealth = attacker.GetHealth() - 1
				if (newhealth < 1)
				{
					attacker.SetHealth(1)
					EntFireHandle(attacker, "IgniteLifetime", "0.1")
				}
				else
					attacker.SetHealth(newhealth)
			}
		},
		// neutral
		none = {
			name = "Default",
			color = "255 255 255",
			desc = "No effect"
		},
		// good
		vampire = {
			name = "Bloodslurp",
			color = "200 50 0",
			desc = "Gain 60% of damage done as health",
			player_hurt = function(ply, data)
			{
				local attacker = data.attacker_player
				local newhealth = attacker.GetHealth() + ceil(data.dmg_health * 0.6)
				local max = attacker.GetMaxHealth()
				attacker.SetHealth(newhealth > max ? max : newhealth)
			}
		},
		rocket = {
			name = "Blast Off",
			color = "230 230 0",
			desc = "Rockets target upward",
			player_hurt = function(ply, data)
			{
				local attacker = data.attacker_player
				if (!LivingPlayer(ply))
					return
				EntFireHandle(ply, "AddOutput", "basevelocity 0 0 " + (data.dmg_health * 12))
			}
		},
		ammo = {
			name = "Bottomless",
			color = "150 100 255",
			desc = "Refills ammo on hit",
			player_hurt = function(ply, data)
			{
				local attacker = data.attacker_player
				local wep = GetActiveWeapon(attacker)
				if (wep == null)
					return
				local cls = wep.GetClassname()
				local wepammo = {weapon_scar20 = 20, weapon_famas = 25, weapon_galilar = 35, weapon_negev = 150, weapon_m249 = 100, weapon_p90 = 50, weapon_bizon = 64, weapon_xm1014 = 7, weapon_deagle = 7, weapon_p250 = 13, weapon_tec9 = 18, weapon_elite = 30, weapon_fiveseven = 20}
				local ammo = 30
				if (cls in wepammo)
					ammo = wepammo[cls]
				EntFireHandle(wep, "SetAmmoAmount", ammo.tostring())
			}
		},
		fire = {
			name = "Sizzlin'",
			color = "255 0 0",
			desc = "Sets target on fire",
			player_hurt = function(ply, data)
			{
				local attacker = data.attacker_player
				if (!LivingPlayer(ply))
					return
				EntFireHandle(ply, "IgniteLifetime", (data.dmg_health * 0.05).tostring())
			}
		},
		frost = {
			name = "Frostbite",
			color = "50 200 255",
			desc = "Slows down target",
			player_hurt = function(ply, data)
			{
				local duration = data.dmg_health * 0.03
				local attacker = data.attacker_player
				ply.EmitSound("Glass.BulletImpact")
				if (!LivingPlayer(ply))
					return
				ModifySpeedTemporarily(ply, 0.2, duration)
				EntFireHandle(ply, "AddOutput", "rendercolor 100 100 255")
				EntFireHandle(ply, "AddOutput", "rendercolor 255 255 255", duration)
			}
		},
		hypno = {
			name = "Hypnotic",
			color = "0 255 200",
			desc = "Dazes and confuses target",
			player_hurt = function(ply, data)
			{
				local attacker = data.attacker_player
				if (!LivingPlayer(ply))
					return
				EntFire("hypno_fade", "fade", "", 0, ply)
				//local ang = ply.GetAngles()
				//ply.SetAngles(ang.x + RandomInt(2, 5), ang.y, 0)
			}
		},
		boom = {
			name = "Boom Bullets",
			color = "100 50 0",
			desc = "Explosive bullet impacts",
			bullet_impact = function(ply, data)
			{
				local pos = data.vector
				local exp = Entities.CreateByClassname("env_explosion")
				exp.__KeyValueFromInt("iMagnitude", 100)
				exp.SetOrigin(pos)
				exp.SetOwner(ply)
				EntFireByHandle(exp, "Explode", "", 0.1, ply, ply)
				DispatchParticleEffect("explosion_basic", pos, pos)
			}
		},
		speed = {
			name = "Finesse",
			color = "150 255 150",
			desc = "Short speed boost on hit",
			player_hurt = function(ply, data)
			{
				ModifySpeedTemporarily(data.attacker_player, 2, 2)
			}
		},
		armor = {
			name = "Tactical",
			color = "0 0 150",
			desc = "Refills armor on hit",
			player_hurt = function(ply, data)
			{
				GiveWeaponNoStrip(data.attacker_player, "item_assaultsuit")
			}
		},
		miner = {
			name = "Miner",
			color = "220 220 220",
			desc = "Gain 25% of damage done as rocks",
			player_hurt = function(ply, data)
			{
				GiveItem(data.attacker_player, "rocks", ceil(data.dmg_health / 4))
			}
		},
		// combo bad & bad
		broken = {
			name = "Broken",
			combo = ["jam", "recoil"]
		},
		masochist = {
			name = "Masochist",
			combo = ["curse", "backfire"]
		},
		// combo good & bad
		frenzy = {
			name = "Frenzy",
			combo = ["fire", "backfire"]
		},
		manic = {
			name = "Manic",
			combo = ["vampire", "recoil"]
		},
		frozen = {
			name = "Frozen",
			combo = ["frost", "jam"]
		},
		cannon = {
			name = "Loose Cannon",
			combo = ["boom", "recoil"]
		},
		campfire = {
			name = "Campfire",
			combo = ["fire", "rocks"]
		},
		// combo good & good
		frostburn = {
			name = "Frostburn",
			combo = ["fire", "frost"]
		},
		brainfreeze = {
			name = "Brain Freeze",
			combo = ["hypno", "frost"]
		},
		challenger = {
			name = "Challenger",
			combo = ["rocket", "fire"]
		},
		leech = {
			name = "Leech",
			combo = ["vampire", "ammo"]
		},
		skater = {
			name = "Tony Hawk",
			combo = ["ammo", "speed"]
		},
		restock = {
			name = "Restock",
			combo = ["ammo", "armor"]
		},
		guard = {
			name = "Guard",
			combo = ["vampire", "armor"]
		},
	},
	weapons = {
		// pistols
		p250 = {
			name = "P250",
			probability = 12,
			recipe = [["metal", 8]],
			effects = {
				good = ["ammo", "armor", "speed", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		deagle = {
			name = "Desert Eagle",
			probability = 10,
			recipe = [["metal", 14]],
			effects = {
				good = ["ammo", "armor", "boom", "frost", "hypno"],
				bad = ["jam", "backfire", "curse", "rocks", "blood"]
			}
		},
		tec9 = {
			name = "Tec-9",
			probability = 10,
			recipe = [["metal", 10]],
			effects = {
				good = ["ammo", "armor", "fire", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		elite = {
			name = "Dual Berettas",
			probability = 8,
			recipe = [["metal", 10]],
			effects = {
				good = ["ammo", "armor", "speed", "boom", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		fiveseven = {
			name = "Five Seven",
			probability = 8,
			recipe = [["metal", 10]],
			effects = {
				good = ["ammo", "armor", "speed", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		// smgs
		ump45 = {
			name = "UMP .45",
			probability = 10,
			recipe = [["metal", 12], ["tech", 1]],
			effects = {
				good = ["rocket", "armor", "fire", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		mac10 = {
			name = "MAC-10",
			probability = 10,
			recipe = [["metal", 10], ["tech", 1]],
			effects = {
				good = ["ammo", "armor", "speed", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		mp9 = {
			name = "MP9",
			probability = 8,
			recipe = [["metal", 10], ["tech", 1]],
			effects = {
				good = ["ammo", "armor", "speed", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		p90 = {
			name = "P90",
			probability = 5,
			recipe = [["metal", 20], ["tech", 3]],
			effects = {
				good = ["ammo", "armor", "speed", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		// machine guns
		m249 = {
			name = "M249",
			probability = 2,
			recipe = [["metal", 20], ["tech", 2]],
			effects = {
				good = ["ammo", "armor", "rocket", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		negev = {
			name = "Negev",
			probability = 3,
			recipe = [["metal", 20], ["tech", 2]],
			effects = {
				good = ["ammo", "armor", "vampire", "speed"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		// shotguns
		nova = {
			name = "Nova",
			probability = 8,
			recipe = [["metal", 12]],
			effects = {
				good = ["fire", "armor", "speed", "frost", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse"]
			}
		},
		mag7 = {
			name = "MAG-7",
			probability = 8,
			recipe = [["metal", 15], ["tech", 1]],
			effects = {
				good = ["frost", "armor", "speed", "hypno", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse"]
			}
		},
		sawedoff = {
			name = "Sawed-Off",
			probability = 8,
			recipe = [["metal", 10]],
			effects = {
				good = ["fire", "armor", "speed", "hypno", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse"]
			}
		},
		xm1014 = {
			name = "XM1014",
			probability = 6,
			recipe = [["metal", 20], ["tech", 2]],
			effects = {
				good = ["ammo", "armor", "speed", "miner", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		// assault rifles
		famas = {
			name = "FAMAS",
			probability = 4,
			recipe = [["metal", 20], ["tech", 2]],
			effects = {
				good = ["ammo", "armor", "frost", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		galilar = {
			name = "Galil AR",
			probability = 4,
			recipe = [["metal", 20], ["tech", 2]],
			effects = {
				good = ["ammo", "armor", "fire", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		ak47 = {
			name = "AK-47",
			probability = 3,
			recipe = [["metal", 25], ["tech", 2]],
			effects = {
				good = ["ammo", "armor", "fire", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		m4a1 = {
			name = "M4A4",
			probability = 3,
			recipe = [["metal", 25], ["tech", 2]],
			effects = {
				good = ["ammo", "armor", "frost", "vampire"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
		// sniper rifles
		ssg08 = {
			name = "SSG 08",
			probability = 4,
			recipe = [["metal", 20], ["tech", 1]],
			effects = {
				good = ["boom", "frost", "hypno", "vampire"],
				bad = ["jam", "backfire"]
			}
		},
		awp = {
			name = "AWP",
			probability = 1,
			recipe = [["metal", 30], ["tech", 4]],
			effects = {
				good = ["boom", "rocket", "hypno", "vampire"],
				bad = ["jam", "backfire"]
			}
		},
		scar20 = {
			name = "SCAR-20",
			probability = 1,
			recipe = [["metal", 35], ["tech", 5]],
			effects = {
				good = ["ammo", "armor", "vampire", "speed"],
				bad = ["jam", "backfire", "recoil", "curse", "rocks", "blood"]
			}
		},
	},
	loot = {
		["models/props/coop_cementplant/coop_foot_locker/coop_foot_locker_closed.mdl"] = {
			open = "models/props/coop_cementplant/coop_foot_locker/coop_foot_locker_open.mdl",
			weapon = true,
			sound = "Player.PickupGrenade"
		},
		["models/props/coop_cementplant/coop_ammo_stash/coop_ammo_stash_full.mdl"] = {
			open = "models/props/coop_cementplant/coop_ammo_stash/coop_ammo_stash_empty.mdl",
			ammo = true,
			// items = ["tech", [4, 5]],
			sound = "Weapon_AK47.BoltPull"
		},
		["models/props/de_nuke/hr_nuke/nuke_locker/nuke_lockers_single.mdl"] = {
			open = "models/props/de_nuke/hr_nuke/nuke_locker/nuke_lockers_single_open.mdl",
			items = ["cloth", [3, 4]],
			sound = "Doors.Move3"
		},
		["models/props/de_nuke/hr_nuke/nuke_file_cabinet/nuke_file_cabinet_closed.mdl"] = {
			open = "models/props/de_nuke/hr_nuke/nuke_file_cabinet/nuke_file_cabinet_opened.mdl",
			items = ["cloth", [4, 5]],
			sound = "Doors.Move3"
		},
		["models/props/cs_militia/footlocker01_closed.mdl"] = {
			open = "models/props/cs_militia/footlocker01_open.mdl",
			items = ["metal", [2, 3]]
		},
		["models/props/de_vertigo/tool_lockbox_closed.mdl"] = {
			open = "models/props/de_vertigo/tool_lockbox_open.mdl",
			items = ["metal", [4, 5]]
		},
		["models/props/coop_cementplant/grenade_box/grenade_box_closed.mdl"] = {
			open = "models/props/coop_cementplant/grenade_box/grenade_box_empty.mdl",
			items = ["tech", [3, 4]],
			sound = "Player.PickupGrenade"
		},
		["models/props/de_dust/hr_dust/dust_garbage_container/dust_garbage_container.mdl"] = {
			open = "models/props/de_dust/hr_dust/dust_garbage_container/dust_garbage_container_open.mdl",
			items = ["tech", [5, 6]],
			sound = "Player.PickupGrenade"
		},
		["models/props/cs_italy/it_mkt_container1a.mdl"] = {
			open = "models/props/cs_italy/it_mkt_container1.mdl",
			items = ["herbs", [1, 2]],
			sound = "Knife.Stilleto.Draw.01"
		},
		["models/props_foliage/urban_balcony_planter01a.mdl"] = {
			open = "models/props_foliage/urban_balcony_planter01.mdl",
			items = ["herbs", [2, 3]],
			sound = "Knife.Stilleto.Draw.01"
		}
	}
}

::TeamProgress <- []

::ArmorResearch <- function(ply)
{
	local team = ply.GetTeam()
	if (TeamProgress[team].armor >= 200)
		ShowHint(ply, "loot", "Armor already researched to max")
	else if (HasItem(ply, "cloth", 30))
	{
		GiveItem(ply, "cloth", -30)
		TeamProgress[team].armor += 20
		ChatPrintTeam(team, "Armor research complete! Default health incrased to " + TeamProgress[team].armor)
	}
	else
		ShowHint(ply, "loot", "Not enough cloth")
}

::UpdateWeaponResearchDisplays <- function()
{
	foreach (team in [2, 3])
	{
		local display = "weapon_research_display_" + [0, 0, "red", "blue"][team]
		local prog = TeamProgress[team].loadout_upgrades
		if (prog >= 3)
			EntFire(display, "addoutput", "message Maxed out")
		else
			EntFire(display, "addoutput", "message Cost: " + (85 + (prog * 35)) + " Metal")
	}
}

::WeaponResearch <- function(ply)
{
	local team = ply.GetTeam()
	if (TeamProgress[team].loadout_upgrades >= 3)
		ShowHint(ply, "loot", "Weapons already researched to max")
	else if (HasItem(ply, "metal", 85))
	{
		GiveItem(ply, "metal", -85)
		// REALLY AWFUL HACK
		if (TeamProgress[team].loadout_upgrades != 1)
			TeamProgress[team].loadout.pop()
		local wep = LoadoutUpgrades[team][TeamProgress[team].loadout_upgrades]
		TeamProgress[team].loadout.push("weapon_" + wep)
		ChatPrintTeam(team, "Weapon research complete! New default weapon: " + wars.weapons[wep].name)
		TeamProgress[team].loadout_upgrades++
	}
	else
		ShowHint(ply, "loot", "Not enough metal")
}

// AWFUL WORKAROUND
// every 16th game_text display breaks the entity (?),
// but only for that player (?) so you need to reload
// the hud from console (?) to make it work again (?).
// this shit took me 3 hours to figure out.
::IncrementHUDCounter <- function(ply, hintname)
{
	local varname = "hud_counter_" + hintname
	SetScopeVar(ply, varname, GetScopeVar(ply, varname, 0) + 1)
	if (GetScopeVar(ply, varname, 0) >= 15)
	{
		// reset the counters and reload the HUD in 2s
		foreach (hud in ["loot", "weapon", "inventory"])
			SetScopeVar(ply, "hud_counter_" + hud, 0)
		ClientCMD(ply, "hud_reloadscheme", 2)
	}
}

::SpawnPointBroken <- function(team)
{
	printl(((team == T) ? "Terrorist" : "CT") + " spawn point broken!")
	local name = "spawnpoint_" + ((team == T) ? "red" : "blue")
	local spawn = null
	while (spawn = Entities.FindByName(spawn, name))
	{
		local markerPos = RemapPoint([Vector(0, 0, 0), SpawnPointDisplays[team].GetOrigin()], [["x", "y"], ["x", "z"]], Vector(0.03125, 0, 0.03125 * ((team == CT) ? -1 : 1)), spawn.GetOrigin())
		local marker = Entities.FindByNameNearest("spawnpoint_marker", markerPos, 1)
		if (marker != null)
		{
			marker.Destroy()
			return
		}
	}
}

::SpawnPointPressed <- function(ply, button)
{
	local team = ply.GetTeam()
	local pos = RemapPoint([SpawnPointDisplays[team].GetOrigin(), Vector(0, 0, 0)], [["x", "z"], ["x", "y"]], Vector(32, 32 * ((team == CT) ? -1 : 1), 0), button.GetOrigin())
	local name = "spawnpoint_" + ((team == T) ? "red" : "blue")
	local spawn = null
	while (spawn = Entities.FindByName(spawn, name))
	{
		local test = spawn.GetOrigin()
		if (abs(test.x - pos.x) + abs(test.y - pos.y) < 4)
		{
			pos = test
			pos.z += 12
			ply.SetOrigin(pos)
			ply.EmitSound("Player.Respawn")
			return
		}
	}
	// no spawnpoint, kill button
	button.Destroy()
}

// TODO
::RecycleWeapon <- function(ply)
{
	local cls = GetActiveWeaponClass(ply)
	local name = cls.slice(7)
}

::PickEffect <- function(wepeffects, reforge = false)
{
	local list
	local rand = RandomInt(1, 10)
	if (rand == 2)
		return "none"
	else if (rand <= (reforge ? 4 : 6))
		list = wepeffects.bad
	else if (rand <= 8)
		list = wepeffects.good
	else
	{
		// pick a combo - fancy fuckin' shit
		local combos = []
		local effects = []
		effects.extend(wepeffects.bad)
		effects.extend(wepeffects.good)
		foreach (k, v in wars.effects)
		{
			if ("combo" in v)
			{
				local found = [false, false]
				for (local i = 0; i < 2; i++)
					foreach (eff in effects)
						if (eff == v.combo[i])
							found[i] = true
				if (found[0] && found[1])
					combos.push(k)
			}
		}
		if (combos.len() > 0)
			list = combos
		else
			list = effects
	}
	return list[RandomInt(0, list.len() - 1)]
}

::ReforgeWeapon <- function(ply)
{
	if (!LivingPlayer(ply))
		return

	local wep = GetActiveWeapon(ply)
	if (wep == null)
		return

	local cls = wep.GetClassname()
	local name = cls.slice(7)
	if (!(name in wars.weapons))
	{
		ShowHint(ply, "loot", "Can't reforge this")
		return
	}

	if (HasItem(ply, "tech", 12))
	{
		GiveItem(ply, "tech", -12)
		local effect = PickEffect(wars.weapons[name].effects, true)
		SetScopeVar(wep, "effect", effect)
		EntFireHandle(wep, "color", wars.effects[effect].color)
		ShowWeaponStats(ply, wep)
		ply.EmitSound("Weapon_bizon.BoltForward")
	}
	else
		ShowHint(ply, "loot", "Not enough tech")
}

::CraftHealthshot <- function(ply)
{
	if (!LivingPlayer(ply))
		return

	if (HasItem(ply, "herbs", 6))
	{
		GiveItem(ply, "herbs", -6)
		GiveWeaponNoStrip(ply, "weapon_healthshot")
	}
	else
		ShowHint(ply, "loot", "Not enough herbs")
}

::CraftBarricade <- function(ply)
{
	if (!LivingPlayer(ply))
		return

	if (HasItem(ply, "rocks", 30))
	{
		GiveItem(ply, "rocks", -30)
		GiveWeaponNoStrip(ply, "weapon_bumpmine")
	}
	else
		ShowHint(ply, "loot", "Not enough rocks")
}

::CraftSpawnpoint <- function(ply)
{
	if (!LivingPlayer(ply))
		return

	if (HasItem(ply, "metal", 40))
	{
		GiveItem(ply, "metal", -40)
		GiveWeaponNoStrip(ply, "weapon_tagrenade")
	}
	else
		ShowHint(ply, "loot", "Not enough metal")
}

::SmeltRocks <- function(ply)
{
	if (!LivingPlayer(ply))
		return

	if (HasItem(ply, "rocks", 20))
	{
		GiveItem(ply, "rocks", -20)
		GiveItem(ply, "metal", RandomInt(1, 3))
		ply.EmitSound("Inferno.FadeOut")
	}
	else
		ShowHint(ply, "loot", "Not enough rocks")
}

::CombineColors <- function(a, b)
{
	local color = ""
	for (local i = 0; i < 3; i++)
	{
		color += ((split(a, " ")[i].tointeger() + split(b, " ")[i].tointeger()) / 2).tostring() + (i < 2 ? " " : "")
	}
	return color
}

::PickWeapon <- function()
{
	local weps = []
	foreach (k, v in wars.weapons)
	{
		for (local i = 0; i < v.probability; i++)
			weps.push(k)
	}
	return "weapon_" + weps[RandomInt(0, weps.len() - 1)]
}

::ShowHint <- function(ply, name, text = false, color = false)
{
	local hint = "hud_" + name

	if (text)
		EntFire(hint, "settext", text, 0, ply)

	if (color)
		EntFire(hint, "settextcolor", color, 0, ply)

	EntFire(hint, "display", "", 0, ply)
	// fucking workaround
	// IncrementHUDCounter(ply, name)
	if (name == "loot" || name == "weapon")
		SetScopeVar(ply, "last_hud_" + name, Time())
}

::ShowWeaponStats <- function(ply, wep)
{
	local wepname = wep.GetClassname().slice(7)
	if (!(wepname in wars.weapons))
		return
	local weptab = wars.weapons[wepname]
	local effect = wars.effects[GetScopeVar(wep, "effect", "none")]
	local str = weptab.name + " - " + effect.name + "\n" + effect.desc
	local clr = effect.color
	ShowHint(ply, "weapon", str, clr)
}

::RestockPlayer <- function(ply)
{
	if (!LivingPlayer(ply))
		return
	local team = TeamProgress[ply.GetTeam()]
//	GiveWeaponNoStrip(ply, "item_assaultsuit")
	RefillAmmo(ply)
	local hp = team.armor
	ply.SetMaxHealth(hp)
	if (GetScopeVar(ply, "needs_restock", false))
	{
		SetScopeVar(ply, "needs_restock", false)
		ply.SetHealth(hp)
		GiveWeapons(ply, team.loadout)
		MeleeFixup()
	}
//	ply.EmitSound("Player.EquipArmor_CT")
//	ClientCMD(ply, "lastinv")
//	ClientCMD(ply, "lastinv", 0.01)
}

::RefreshInventory <- function(ply)
{
	ShowHint(ply, "inventory", "Cloth " + GetScopeVar(ply, "loot_cloth", 0) + ", Herbs " + GetScopeVar(ply, "loot_herbs", 0) + ", Metal " + GetScopeVar(ply, "loot_metal", 0) + ", Rocks " + GetScopeVar(ply, "loot_rocks", 0) + ", Tech " + GetScopeVar(ply, "loot_tech", 0))
}

::GiveItem <- function(ply, loot, amt = 1)
{
	AddScopeVar(ply, "loot_" + loot, amt)
	if (amt > 0)
		ShowHint(ply, "loot", "+" + amt + " " + loot)
	RefreshInventory(ply)
}

::HasItem <- function(ply, loot, amt = 1)
{
	return GetScopeVar(ply, "loot_" + loot) >= amt
}

::GetPlayerWeaponOfType <- function(ply, type)
{
	local weps = GetWeapons(ply)
	foreach (wep in weps)
	{
		local name = wep.GetClassname().slice(7)
		if ((name in WepNameToWepType) && WepNameToWepType[name] == type)
			return wep
	}
}

::GiveWeaponEffect <- function(cls, effect = false)
{
	local wep = null
	while (wep = Entities.FindByClassname(wep, cls))
	{
		if (!GetScopeVar(wep, "effect", false))
			break
	}
	local name = cls.slice(7)
	if (!(name in wars.weapons))
		return
	if (!effect)
		effect = PickEffect(wars.weapons[name].effects)
	SetScopeVar(wep, "effect", effect)
	EntFireHandle(wep, "color", wars.effects[effect].color)
}

::LoadoutUpgrades <- [
	[],
	[],
	["tec9", "mac10", "galilar"],
	["fiveseven", "mp9", "famas"],
]

OnPostSpawn <- function()
{
	// gamemode convars
	SendToConsoleServer("mp_roundtime 60")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_solid_teammates 0")
	SendToConsoleServer("mp_autokick 0")
	// loot init
	local ent = null
	while (ent = Entities.FindByName(ent, "loot"))
	{
		if (ent.ValidateScriptScope())
		{
			ent.GetScriptScope().InputUse <- function()
			{
				local mdl = self.GetModelName()
				if (!(mdl in wars.loot))
					return	

				local loot = wars.loot[mdl]
				if ("weapon" in loot && loot.weapon)
				{
					local cls = PickWeapon()
					GiveWeaponNoStrip(activator, cls)
					EntFireHandle(self, "RunScriptCode", "GiveWeaponEffect(\"" + cls + "\")", 0)
				}
				if ("ammo" in loot && loot.ammo)
				{
					RefillAmmo(activator)
					ShowHint(activator, "loot", "Refilled ammo")
				}
				if ("items" in loot)
				{
					GiveItem(activator, loot.items[0], (typeof loot.items[1] == "array") ? RandomInt(loot.items[1][0], loot.items[1][1]) : loot.items[1])
				}
				self.EmitSound(("sound" in loot) ? loot.sound : "DogTags.PickupDeny")
				self.PrecacheModel(loot.open)
				self.SetModel(loot.open)
				EntFireHandle(self, "RunScriptCode", "self.SetModel(\"" + mdl + "\")", ("delay" in loot) ? loot.delay : 100)
			}
		}
	}
	// resupply cabinet init
/*
	while (ent = Entities.FindByName(ent, "resupply"))
	{
		if (ent.ValidateScriptScope())
		{
			ent.GetScriptScope().InputUse <- function()
			{
				if (LivingPlayer(activator))
				{
					RestockPlayer(activator)
					ShowHint(activator, "loot", "Restocked")
				}
			}
		}
	}
*/
	// harvestable rocks
	while (ent = Entities.FindByName(ent, "rocks"))
	{
		if (ent.ValidateScriptScope())
		{
			ent.ConnectOutput("OnTakeDamage", "MineRocks")
			ent.GetScriptScope().MineRocks <- function()
			{
				if (LivingPlayer(activator))
				{
					GiveItem(activator, "rocks", RandomInt(6, 9))
					activator.EmitSound("Breakable.Concrete")
				}
			}
		}
	}
	// crafter init
	while (ent = Entities.FindByName(ent, "crafter"))
	{
		if (ent.ValidateScriptScope())
		{
			ent.GetScriptScope().InputUse <- function()
			{
				if (LivingPlayer(activator))
				{
					local wep = GetActiveWeapon(activator)
					if (wep == null)
						return

					local cls = wep.GetClassname()
					local name = cls.slice(7)
					if (name in wars.weapons)
					{
						// if they're holding a valid weapon,
						// replace what we're crafting with it

						// give back our old weapon (if we have one)
						if ("weapon" in this)
						{
							GiveWeaponNoStrip(activator, this.weapon)
							EntFireHandle(self, "RunScriptCode", "GiveWeaponEffect(\"" + this.weapon + "\", \"" + this.weapon_effect + "\")")
						}

						// replace what we're crafting
						this.weapon <- cls
						this.weapon_effect <- GetScopeVar(wep, "effect", "none")
						this.recipe <- wars.weapons[name].recipe

						// update hologram
						local gunmodel = Entities.FindByNameNearest("crafter_gun", self.GetOrigin(), 200)
						if (gunmodel != null)
							gunmodel.SetModel(wep.GetModelName())

						// weapon name and effect w/ color
						local display = Entities.FindByNameNearest("crafter_display", self.GetOrigin(), 200)
						if (display != null)
						{
							local efftab = wars.effects[GetScopeVar(wep, "effect", "none")]
							EntFireHandle(display, "AddOutput", "color " + efftab.color)
							EntFireHandle(display, "AddOutput", "message " + wars.weapons[name].name + " - " + efftab.name)
						}

						// update cost display with ingredients
						local costdisplay = Entities.FindByNameNearest("crafter_cost", self.GetOrigin(), 200)
						if (costdisplay != null)
						{
							local cost = "Costs "
							foreach (ing in this.recipe)
								cost += (ing[1] + " " + ing[0] + " ")
							EntFireHandle(costdisplay, "AddOutput", "message " + cost)
						}

						// strip the weapon from them
						wep.Destroy()
						ClientCMD(activator, "lastinv")
					}
					else
					{
						// if they're not holding a valid weapon,
						// craft what we currently have
						if ("recipe" in this)
						{
							// check if they have the ingredients
							foreach (ing in this.recipe)
							{
								if (!HasItem(activator, ing[0], ing[1]))
								{
									ShowHint(activator, "loot", "Not enough " + ing[0])
									return
								}
							}

							// take the ingredients
							foreach (ing in this.recipe)
							{
								GiveItem(activator, ing[0], -ing[1])
							}

							// give the weapon
							GiveWeaponNoStrip(activator, this.weapon)
							EntFireHandle(self, "RunScriptCode", "GiveWeaponEffect(\"" + this.weapon + "\", \"" + this.weapon_effect + "\")")
						}
					}
				}
			}
		}
	}
	// fix hud and restock
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player"))
	{
		SetScopeVar(ply, "needs_restock", true)
		foreach (item in ["cloth", "herbs", "metal", "rocks", "tech"])
		{
			SetScopeVar(ply, "loot_" + item, 0)
		}
		EntFireHandle(ply, "RunScriptCode", "RefreshInventory(self)", 0.1)
	}
	// precache combo effect data
	foreach (k, v in wars.effects)
	{
		if ("combo" in v)
		{
			local a = wars.effects[v.combo[0]]
			local b = wars.effects[v.combo[1]]
			wars.effects[k].color <- CombineColors(a.color, b.color)
			wars.effects[k].desc <- a.desc + "\n" + b.desc
			foreach (fname in ["weapon_fire", "player_hurt", "bullet_impact"])
			{
				// hook the OG functions (ghetto asf)
				if ((fname in a) && (fname in b))
					wars.effects[k][fname] <- [a[fname], b[fname]]
				else if (fname in a)
					wars.effects[k][fname] <- a[fname]
				else if (fname in b)
					wars.effects[k][fname] <- b[fname]
			}
		}
	}
	// reset team progress
	::TeamProgress <- [
		{},
		{},
		{
			name = "Terrorists",
			armor = 100,
			loadout = ["item_assaultsuit", "weapon_bayonet", "weapon_glock"],
			loadout_upgrades = 0
		},
		{
			name = "Counter-Terrorists",
			armor = 100,
			loadout = ["item_assaultsuit", "weapon_knife_m9_bayonet", "weapon_hkp2000"],
			loadout_upgrades = 0
		},
	]
	// restock after death
	HookToPlayerDeath(function(ply) {
		SetScopeVar(ply, "needs_restock", true)
	})
}

::AngSum <- function(ang)
	return floor(ang.x) + "-" + floor(ang.y) + "-" + floor(ang.z)

Think <- function()
{
	local deleted = []
	local ent = null
	while (ent = Entities.FindByClassname(ent, "bumpmine_projectile"))
	{
		if (ent.ValidateScriptScope())
		{
			local ss = ent.GetScriptScope()
			if (!("last_angles" in ss))
			{
				ss.last_angles <- AngSum(ent.GetAngles())
			}
			else if (ss.last_angles == AngSum(ent.GetAngles()))
			{
				local owner = ent.GetOwner()
				if (owner != null)
				{
					local pos = ent.GetOrigin()
					SandbagMaker.SpawnEntityAtLocation(pos, Vector(0, 0, 0))
					local sandbags = Entities.FindByNameNearest("sandbags", pos, 100)
					if (sandbags != null)
					{
						local vec = owner.GetOrigin() - pos
						vec.z = 0
						sandbags.SetForwardVector(vec)
						sandbags.EmitSound("Concrete.ImpactHard")
					}
					ent.StopSound("Survival.BumpIdle")
					ent.StopSound("Survival.BumpMineSetArmed")
					deleted.push(ent)
				}
			}
			else
			{
				ss.last_angles <- AngSum(ent.GetAngles())
			}
		}
	}
	while (ent = Entities.FindByClassname(ent, "tagrenade_projectile"))
	{
		if (ent.GetVelocity().Length() < 1)
		{
			local owner = ent.GetOwner()
			if (owner != null)
			{
				local pos = ent.GetOrigin()
				SpawnPointMakers[owner.GetTeam()].SpawnEntityAtLocation(pos, Vector(0, 0, 0))
				local team = owner.GetTeam()
				local spawn = Entities.FindByNameNearest("spawnpoint_" + ((team == T) ? "red" : "blue"), pos, 100)
				if (spawn != null)
				{
					local markerPos = RemapPoint([Vector(0, 0, 0), SpawnPointDisplays[team].GetOrigin()], [["x", "y"], ["x", "z"]], Vector(0.03125, 0, 0.03125 * ((team == CT) ? -1 : 1)), spawn.GetOrigin())
					SpawnPointMarkerMaker.SpawnEntityAtLocation(markerPos, Vector(0, 0, 0))
					spawn.EmitSound("Concrete.ImpactHard")
				}
				ent.StopSound("Sensor.Activate")
				deleted.push(ent)
			}
		}
	}
	// another fucking awful workaround
	// hide HUD text after it's been shown for a while,
	// because auto-decaying HUD text kills itself
	while (ent = Entities.FindByClassname(ent, "player"))
	{
		if (LivingPlayer(ent) && ent.ValidateScriptScope())
		{
			local ss = ent.GetScriptScope()
			foreach (hud in [["loot", 0.4], ["weapon", 1]])
			{
				local varname = "last_hud_" + hud[0]
				if (!(varname in ss))
					ss[varname] <- 0
				if (Time() - ss[varname] > hud[1])
					ShowHint(ent, hud[0], "")
			}
		}
	}
	foreach (ent in deleted)
		ent.Destroy()
}

AddHook("player_spawn", "Wars.SpawnArmor", function(data)
{
	local ply = data.userid_player
	if (ply == null)
		return

	GiveWeaponNoStrip(ply, "item_assaultsuit")
})

AddHook("item_equip", "Wars.ShowWeaponStats", function(data)
{
	local ply = data.userid_player
	if (ply == null)
		return

	RefreshInventory(ply)

	if (data.item in WepNameToWepType)
	{
		local wep = GetPlayerWeaponOfType(ply, WepNameToWepType[data.item])
		if (wep == null)
			return
		// IncrementHUDCounter(ply, "weapon") // what the fuck ?
		ShowWeaponStats(ply, wep)
	}
})

::CallArrayFunc <- function(arg, ply, data)
{
	if (typeof arg == "array")
	{
		arg[0](ply, data)
		arg[1](ply, data)
	}
	else
		arg(ply, data)
}

AddHook("player_hurt", "Wars.PlayerHurt", function(data)
{
	local ply = data.userid_player
	if (ply == null)
		return

	local attacker = data.attacker_player
	if (attacker == null)
		return

	local name = data.weapon
	if (name in WepNameToWepType)
	{
		local wep = GetPlayerWeaponOfType(attacker, WepNameToWepType[name])
		if (wep == null)
			return
		local effect = GetScopeVar(wep, "effect", "none")
		local efftab = wars.effects[effect]
		if ("player_hurt" in efftab)
			CallArrayFunc(efftab.player_hurt, ply, data)
	}
})

AddHook("weapon_fire", "Wars.WeaponFire", function(data)
{
	local ply = data.userid_player
	if (ply == null)
		return

	local name = data.weapon.slice(7)
	if (name in WepNameToWepType)
	{
		local wep = GetPlayerWeaponOfType(ply, WepNameToWepType[name])
		if (wep == null)
			return
		local effect = GetScopeVar(wep, "effect", "none")
		local efftab = wars.effects[effect]
		if ("weapon_fire" in efftab)
			CallArrayFunc(efftab.weapon_fire, ply, data)
	}
})

AddHook("bullet_impact", "Wars.BulletImpact", function(data)
{
	local ply = data.userid_player
	if (ply == null)
		return

	local wep = GetActiveWeapon(ply)
	if (wep == null)
		return
	local name = wep.GetClassname().slice(7)
	if (name in WepNameToWepType)
	{
		local effect = GetScopeVar(wep, "effect", "none")
		local efftab = wars.effects[effect]
		if ("bullet_impact" in efftab)
		{
			data.vector <- Vector(data.x, data.y, data.z)
			CallArrayFunc(efftab.bullet_impact, ply, data)
		}
	}
})

AddHook("player_say", "Wars.ChatCommands", function(data)
{
	local ply = data.userid_player
	if (!LivingPlayer(ply))
		return

	local txt = data.text
	local args = split(txt, " ")

	switch (args[0])
	{
		case "cheatwep":
			if (!(1 in args))
				return
			local wep = "weapon_" + args[1]
			GiveWeaponNoStrip(ply, wep)
			if (args.len() < 3)
				args[2] <- "none"
			EntFire("script", "runscriptcode", "GiveWeaponEffect(\"" + wep + "\", \"" + args[2] + "\")", 0.1)
			break

		case "cheatitem":
			if (!(1 in args))
				return
			if (args.len() < 3)
				args[2] <- 9999
			GiveItem(ply, args[1], args[2].tointeger())
			break

		case "stuck":
			ply.SetOrigin(ply.GetOrigin() + Vector(0, 0, 24))
			break

		case "hud":
			ClientCMD(ply, "hud_reloadscheme")
			break
	}
})
