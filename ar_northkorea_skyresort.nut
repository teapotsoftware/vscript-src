
IncludeScript("butil")

::CURSE_NONE <- 0
::CURSE_1HP <- 1
::CURSE_500HP <- 2
::CURSE_LOWGRAV <- 3
::CURSE_DEAGLE <- 4
::CURSE_FLASHBANGS <- 5
::CURSE_COKE <- 6
::CURSE_BURN <- 7
::CURSE_BIZON <- 8
::CURSE_NOIR <- 9
::CURSE_WEAKJUMPS <- 10
::CURSE_MAX <- 10

::CURSE_DURATION <- 30
::LAST_CURSE_TIME <- -CURSE_DURATION
::CURRENT_CURSE <- CURSE_NONE

::CurseList <- [
	{}, {
		message = "Instant kills",
		onStart = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				SetHealthAndMaxHealth(ply, 1)
			})
		},
		onEnd = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				SetHealthAndMaxHealth(ply, 100)
			})
		},
		onPlayerSpawn = function(ply) {
			SetHealthAndMaxHealth(ply, 1)
		}
	}, {
		message = "Chunky boys",
		onStart = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				SetHealthAndMaxHealth(ply, 500)
			})
		},
		onEnd = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				ply.SetMaxHealth(100)
				ply.SetHealth(Min(ply.GetHealth(), 100))
			})
		},
		onPlayerSpawn = function(ply) {
			SetHealthAndMaxHealth(ply, 500)
		}
	}, {
		message = "Moon gravity",
		onStart = function() {
			ForEachPlayerAndBot(function(ply) {
				EntFireHandle(ply, "AddOutput", "gravity 0.6")
			})
		},
		onEnd = function() {
			ForEachPlayerAndBot(function(ply) {
				EntFireHandle(ply, "AddOutput", "gravity 1.0")
			})
		},
		onPlayerSpawn = function(ply) {
			EntFireHandle(ply, "AddOutput", "gravity 0.6")
		}
	}, {
		message = "Deags out",
		onStart = function() {
			// delete all USPs
			local ent = null
			while (ent = Entities.FindByClassname(ent, "weapon_hkp2000")) {
				QueueForDeletion(ent)
			}
			FlushDeletionQueue()

			// give deagles
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				GiveWeaponNoStrip(ply, "weapon_deagle")
			})
		},
		onEnd = function() {
			// delete all deagles
			local ent = null
			while (ent = Entities.FindByClassname(ent, "weapon_deagle")) {
				QueueForDeletion(ent)
			}
			FlushDeletionQueue()

			// give USPs
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				GiveWeaponNoStrip(ply, "weapon_usp_silencer")
			})
		},
		onPlayerSpawn = function(ply) {
			GiveWeapon(ply, "weapon_deagle")
		}
	}, {
		message = "Utilitarian",
		onStart = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				GiveWeapons(ply, ["weapon_flashbang", "weapon_smokegrenade"])
			})
		},
		onEnd = function() {
			local ent = null
			while (ent = Entities.Next(ent)) {
				if (ent.GetClassname() == "weapon_flashbang" || ent.GetClassname() == "weapon_smokegrenade")
					QueueForDeletion(ent)
			}
			FlushDeletionQueue()
		},
		onPlayerSpawn = function(ply) {
			GiveWeapons(ply, ["weapon_flashbang", "weapon_smokegrenade"])
		}
	}, {
		message = "Adderall",
		latin = "ocius te ferant pedes tui quam acumen ingenii", // may your feet carry you faster than your wits can fathom
		onStart = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return
	
				ModifySpeed(ply, 1.5)
			})
		},
		onEnd = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				ModifySpeed(ply, 1.0)
			})
		},
		onPlayerSpawn = function(ply) {
			ModifySpeed(ply, 1.5)
		}
	}, {
		message = "Burn baby burn",
		onStart = function() {
			ForEachPlayerAndBot(function(ply) {
				if (!LivingPlayer(ply))
					return

				GiveWeapon(ply, "weapon_molotov")
			})
		},
		onEnd = function() {
			local ent = null
			while (ent = Entities.Next(ent)) {
				if (ent.GetClassname() == "weapon_molotov")
					QueueForDeletion(ent)
			}
			FlushDeletionQueue()
		},
		onPlayerSpawn = function(ply) {
			GiveWeapon(ply, "weapon_molotov")
		}
	}, {
		message = "Bizonly",
		onStart = function() {
			local ent = null
			while (ent = Entities.Next(ent)) {
				local name = ent.GetName()
				if (name.len() > 7 && name.slice(0, 7) == "pickup_" && name != "pickup_health" && name != "pickup_melon" && name != "pickup_item_assaultsuit" && ent.ValidateScriptScope()) {
					local ss = ent.GetScriptScope()
					if (!("previous_name" in ss)) {
						ss.previous_name <- name
						ss.previous_model <- ent.GetModelName()
					}
					ent.__KeyValueFromString("targetname", "pickup_weapon_bizon")
					SetModelSafe(ent, "models/weapons/w_smg_bizon_dropped.mdl")
				}
			}
		},
		onEnd = function() {
			local ent = null
			while (ent = Entities.Next(ent)) {
				local name = ent.GetName()
				if (name.len() > 7 && name.slice(0, 7) == "pickup_" && name != "pickup_health" && name != "pickup_melon" && name != "pickup_item_assaultsuit" && ent.ValidateScriptScope()) {
					local ss = ent.GetScriptScope()
					ent.__KeyValueFromString("targetname", ss.previous_name)
					SetModelSafe(ent, ss.previous_model)
				}
			}
		},
	}, {
		message = "Noir",
		onStart = function() {
			EntFire("cc_default", "Disable")
			EntFire("cc_noir", "Enable")
		},
		onEnd = function() {
			EntFire("cc_default", "Enable")
			EntFire("cc_noir", "Disable")
		},
	}, {
		message = "Boing",
		latin = "", //
		onStart = function() {
			SendToConsole("sv_jump_impulse 777")
		},
		onEnd = function() {
			SendToConsole("sv_jump_impulse 301.993377")
		},
	}
]

// add new hud with "yeonsog" counter (killstreak)
// bunch of little popups like "+50 HP" or "PICKED UP ISRAELI RIFLE"
// gun names are bad translations

::GunNames <- {
	[ITEM_ASSAULTSUIT] = "HELMET",
	[WEAPON_AK47] = "KF-7 SOVIET",
	[WEAPON_AUG] = "SCOPE RIFLE",
	[WEAPON_AWP] = "MAGNUM SNIPER",
	[WEAPON_DEAGLE] = "MAGNUM PISTOL",
	[WEAPON_FAMAS] = "CLARION",
	[WEAPON_GALIL] = "TEL-AVIV DEFENDER",
	[WEAPON_M249] = "BIG BROTHER",
	[WEAPON_M4A4] = "DIPLOMAT RIFLE",
	[WEAPON_M4A1S] = "ESPIONAGE RIFLE",
	[WEAPON_MAC10] = "BULLET BOX",
	[WEAPON_MP7] = "COMPANY SMG",
	[WEAPON_MP9] = "CORDLESS SMG",
	[WEAPON_NEGEV] = "VILLAGE SWEEPER",
	[WEAPON_NOVA] = "FATHER SHOTGUN",
	[WEAPON_P90] = "HIGH-TECH SMG",
	[WEAPON_SG553] = "KRIEG",
	[WEAPON_SSG08] = "SCOUT SNIPER",
	[WEAPON_UMP45] = "MILITARY SMG",
	[WEAPON_XM1014] = "BBQ SHOTGUN",
	["chunkster"] = "CHUNKY ARMOR",
}

::StartCurse <- function(newCurse = -1) {
	if (CURRENT_CURSE != CURSE_NONE && "onEnd" in CurseList[CURRENT_CURSE]) {
		CurseList[CURRENT_CURSE].onEnd()
	}
	::CURRENT_CURSE = newCurse == -1 ? (NextRandom(CURSE_MAX) + 1) : newCurse
	::LAST_CURSE_TIME <- Time()
	if ("onStart" in CurseList[CURRENT_CURSE]) {
		CurseList[CURRENT_CURSE].onStart()
	}
	Chat(RED + "Your curse: " + CurseList[CURRENT_CURSE].message)
}

::ChestWeps <- [
	// nades
	"weapon_flashbang",
	"weapon_molotov",
	"weapon_incgrenade"
	// secondaries
	"weapon_glock",
	"weapon_p250",
	"weapon_elite",
	"weapon_deagle",
	"weapon_fiveseven",
	// primaries
	"weapon_bizon",
	"weapon_sawedoff",
	"weapon_nova",
	"weapon_mac10",
	"weapon_mp9",
	"weapon_xm1014",
	"weapon_negev",
	"weapon_p90",
	"weapon_m249",
	"weapon_famas",
	"weapon_galilar",
	"weapon_aug",
	"weapon_sg556",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_scar20",
]

::OpenChest <- function(ply) {
	GiveWeapon(ply, CURRENT_CURSE == CURSE_BIZON ? WEAPON_BIZON : RandomFromArray(ChestWeps))
}

::CMDs <- [
	"mp_teammates_are_enemies 1",
	"mp_respawn_on_death_t 1",
	"mp_respawn_on_death_ct 1",
	"mp_respawnwavetime_t 4 1",
	"mp_respawnwavetime_ct 4 1",
	"mp_use_respawn_waves 1",
	"sv_infinite_ammo 2",
	"sv_hegrenade_damage_multiplier 2",
	"sv_falldamage_scale 0",
	"sv_airaccelerate 1337",
	"sv_autobunnyhopping 1",
	"mp_roundtime 60",
	"mp_maxrounds 99999",
	"mp_timelimit 99999",
	"mp_autokick 0",
	"mp_drop_grenade_enable 0",
	"mp_freezetime 0"
]

::PickupList <- []
// ::PickupPlanes <- {x = [], y = [], z = []}
::PICKUP_MAXS <- Vector(20, 20, 12)
::PICKUP_MINS <- Vector(-20, -20, -1)
::PICKUP_OFFSET <- Vector(0, 0, -32)

OnPostSpawn <- function() {
	foreach (cmd in CMDs) {
		SendToConsoleServer(cmd)
	}

	HookToPlayerKill(function(ply) {
		EntFire("hud_hitmarker", "display", "", 0, ply)
		if (ply.GetHealth() < ply.GetMaxHealth()) {
			local hp = CURRENT_CURSE == CURSE_500HP ? 200 : 50
			ply.SetHealth(Clamp(ply.GetHealth() + hp, 0, ply.GetMaxHealth()))
			EntFire("hud_pickup", "SetText", "+" + hp + "HP")
			EntFire("hud_pickup", "Display", "", 0, ply)
		}
	})

	HookToPlayerDeath(function(ply) {
		local wep = null
		while (wep = Entities.Next(wep))
			if ((wep.GetClassname() == "weapon_hkp2000" || wep.GetClassname() == "weapon_hegrenade") && wep.GetOwner() == null)
				wep.Destroy()

		// disconnected
		if (ply == null)
			return

		if (RandomInt(1, 100) == 69)
			ply.EmitSound("Chicken.Death")
		else if (RandomInt(1, 6) == 3)
			ply.EmitSound("Hostage.Pain")

		// progress the clock
		if (CURRENT_CURSE == CURSE_NONE) {
			local minute_hand = Entities.FindByName(null, "clock_hand_minute")
			if (minute_hand != null)
				minute_hand.SetAngles(minute_hand.GetAngles().x - 36, 0, 0)
			local hour_hand = Entities.FindByName(null, "clock_hand_hour")
			if (hour_hand != null) {
				local new_pitch = hour_hand.GetAngles().x - 12
				if (new_pitch <= -360) {
					hour_hand.SetAngles(0, 0, 0)
					Chat(RED + "The Kill Clock strikes midnight!")
					EntFire("killclock_snd", "PlaySound")
					StartCurse()
				} else
					hour_hand.SetAngles(new_pitch, 0, 0)
			}
		}
	})

	local ent = null
	while (ent = Entities.Next(ent)) {
		local cls = ent.GetClassname()
		local name = ent.GetName()
		if (ent.ValidateScriptScope() && name.len() > 13  && name.slice(0, 13) == "@knifepickup_") {
			ent.GetScriptScope().InputUse <- function() {
				SetKnife(activator, self.GetName().slice(13))
			}
		} else if (name.len() > 7 && name.slice(0, 7) == "pickup_") {
			PickupList.push(ent)
/*
			local pos = ent.GetOrigin()
			local mins = pos + PICKUP_MINS
			foreach (c in mins) {
				if (PickupPlanes[c].find(mins[c]) == null) {
					PickupPlanes[c].push(mins[c])
				}
			}
*/
		}
	}
}

::OverrideVM <- {
	["models/weapons/v_eq_decoy.mdl"] = "models/weapons/v_knife_bayonet.mdl",
	//["models/weapons/v_eq_fraggrenade.mdl"] = "models/weapons/v_hammer.mdl",
	["models/weapons/v_sonar_bomb.mdl"] = "models/weapons/v_spanner.mdl",
}

::WepTypes <- {
	weapon_galilar = 1,
	weapon_aug = 1,
	weapon_sg556 = 1,
	weapon_ak47 = 1,
	weapon_famas = 1,
	weapon_m4a1 = 1,
	weapon_m4a1_silencer = 1,
	weapon_mac10 = 1,
	weapon_mp9 = 1,
	weapon_ump45 = 1,
	weapon_bizon = 1,
	weapon_mp7 = 1,
	weapon_mp5sd = 1,
	weapon_p90 = 1,
	weapon_ssg08 = 1,
	weapon_awp = 1,
	weapon_scar20 = 1,
	weapon_g3sg1 = 1,
	weapon_negev = 1,
	weapon_m249 = 1,
	weapon_sawedoff = 1,
	weapon_mag7 = 1,
	weapon_nova = 1,
	weapon_xm1014 = 1,
	weapon_deagle = 2,
	weapon_p250 = 2,
	weapon_cz75a = 2,
	weapon_elite = 2,
	weapon_glock = 2,
	weapon_revolver = 2,
	weapon_usp_silencer = 2,
//	weapon_hkp2000 = 2, // commented out so deagle pickup strips usp
	weapon_tec9 = 2,
	weapon_fiveseven = 2,
	weapon_bumpmine = 5,
	weapon_breachcharge = 5,
}

::RotPckps <- function() {
	foreach (pickup in PickupList) {
		local ang = pickup.GetAngles()
		pickup.SetAngles(ang.x, ang.y - 1.5, ang.z)
	}
}

Think <- function() {
	// Think is only called every 0.1s, calling it
	// twice smooths out the speeeeeen animation
	RotPckps()
	EntFire("script", "RunScriptCode", "RotPckps()", 0.033)
	EntFire("script", "RunScriptCode", "RotPckps()", 0.067)

	//local pickups = []
	foreach (pickup in PickupList) {
		if (pickup.GetName() == "pickup_null") {
			if (pickup.ValidateScriptScope()) {
				local ss = pickup.GetScriptScope()
				if ("last_pickup" in ss && Time() - ss.last_pickup >= 60) {
					pickup.__KeyValueFromString("targetname", ss.previous_name)
					EntFireHandle(pickup, "EnableDraw")
				}
			}
			continue
		}
	}

	local deleted = []
	local ent = null
	while (ent = Entities.Next(ent)) {
		local cls = ent.GetClassname()
		local name = ent.GetName()

		if (cls == "decoy_projectile") {
			if (!ent.ValidateScriptScope())
				continue
			local owner = ent.GetOwner()
			if (owner == null)
				continue
			local ss = ent.GetScriptScope()
			if (!("thrown_knife" in ss)) {
				ss.thrown_knife <- true
				SetModelSafe(ent, "models/weapons/w_knife_bayonet_dropped.mdl")
				ent.EmitSound("Player.GhostKnifeSwish")
				GiveWeaponNoStrip(owner, "weapon_decoy")
			}
			if (ent.GetVelocity().Length() < 1)
				QueueForDeletion(ent)
			else {
				ent.EmitSound("Weapon_Knife.Slash")
				local ply = null
				while (ply = Entities.FindByClassnameWithin(ply, "*", ent.GetOrigin(), 20)) {
					if (LivingPlayer(ply)) {
						ply.EmitSound("Weapon_Knife.Hit")
						local new_hp = ply.GetHealth() - 25
						if (new_hp < 1) {
							ply.SetHealth(1)
							EntFireHandle(ply, "ignitelifetime", "0.1")
						}
						else
							ply.SetHealth(new_hp)
						QueueForDeletion(ent)
					}
				}
			}
		} else if (cls == "hegrenade_projectile") {
			if (!ent.ValidateScriptScope())
				continue
			local ss = ent.GetScriptScope()
			if ("spawn_time" in ss) {
				if ((Time() - ss.spawn_time > 1.5) && !("chicken_nade" in ss)) {
					ss.chicken_nade <- true
					ent.EmitSound("Chicken.Death")
					for (local i = 0; i < 4; i++)
						DispatchParticleEffect("chicken_gone", ent.GetOrigin(), ent.GetOrigin())
				}
			} else {
				ss.spawn_time <- Time()
				// SetModelSafe(ent, "models/chicken/chicken.mdl")
				local chickens = [
					"black", "black_white_head",
					"tan", "tan", "tan", "tan",
					"white", "white", "white_tan_head"
				]
				SetModelSafe(ent, "models/chicken/chicken_catalan_" + RandomFromArray(chickens) + ".mdl")
				local owner = ent.GetOwner()
				if (owner != null)
					owner.EmitSound("Chicken.Death")
			}
		}
	}
	FlushDeletionQueue()

	// separate loop for players because we need pickup list
	while (ent = Entities.Next(ent)) {
		if (ent.GetClassname() == "player" && ent.GetHealth() > 0) {
			local vel = ent.GetVelocity()
			if (vel.LengthSqr() > 250000) {
				if (!("speedometer" in getroottable()) || !speedometer.IsValid()) {
					::speedometer <- Entities.CreateByClassname("game_text")
					speedometer.__KeyValueFromInt("effect", 0)
					speedometer.__KeyValueFromInt("channel", 0)
					speedometer.__KeyValueFromInt("x", -1)
					speedometer.__KeyValueFromInt("fadein", 0)
					speedometer.__KeyValueFromInt("fadeout", 0)
					speedometer.__KeyValueFromFloat("holdtime", 0.5)
					speedometer.__KeyValueFromFloat("y", 0.9)
					speedometer.__KeyValueFromString("color", "255 255 255")
					speedometer.__KeyValueFromString("color2", "255 255 255")
				}
				
				local mph = (vel.Length() * 0.0568182 * (CURRENT_CURSE == CURSE_COKE ? 1.5 : 1.0)).tointeger()
				local arrows = floor(mph / 20)
				EntFireHandle(speedometer, "SetText", LoopString(">", arrows) + " " + mph + " mph " + LoopString("<", arrows))
				EntFireHandle(speedometer, "Display", "", 0, ent)
			}

			local plypos = ent.GetOrigin()
			foreach (pickup in PickupList) {
				local in_range = true
				local pos = pickup.GetOrigin() + PICKUP_OFFSET
				foreach (c in ["x", "y", "z"]) {
					local d = plypos[c] - pos[c]
					if (d > PICKUP_MAXS[c] || d < PICKUP_MINS[c]) {
						in_range = false
						break
					}
				}
				if (in_range) { //(DistToSqr(plypos, pickup.GetOrigin() - offset) < 900) {
					local name = pickup.GetName()
					if (name == "pickup_health" || name == "pickup_melon") {
						local current = ent.GetHealth()
						local max = ent.GetMaxHealth()
						if (ent.GetHealth() >= max)
							continue
						local new_health = current + ((name == "pickup_health") ? 100 : 50)
						if (new_health > max)
							new_health = max
						ent.SetHealth(new_health)
						pickup.EmitSound("HealthShot.Pickup")
					} else if (name == "pickup_ammo") {
						RefillAmmo(ent)
						pickup.EmitSound("Weapon_AK47.BoltPull")
					} else if (name == "pickup_chunkster") {
						if (ent.GetHealth() >= 200)
							continue
						GiveChunkster(ent)
					} else {
						local wep = name.slice(7)
						local has_type = false
						if (wep in WepTypes) {
							local e2 = null
							while (e2 = Entities.Next(e2)) {
								local cls2 = e2.GetClassname()
								if (cls2 in WepTypes && e2.GetOwner() == ent && WepTypes[cls2] == WepTypes[wep]) {
									has_type = true
									break
								}
							}
						} else {
							has_type = HasWeapon(ent, wep)
						}
						if (has_type)
							continue
						local kill_list = []
						local old_wep = null
						while (old_wep = Entities.FindByClassname(old_wep, wep))
							if (old_wep.GetOwner() == null)
								kill_list.push(old_wep)
						foreach (target in kill_list)
							target.Destroy()
						if (wep == "weapon_deagle") { // bruh
							GiveWeapon(ent, wep)
						} else {
							GiveWeaponNoStrip(ent, wep)
						}
						pickup.EmitSound("Player.PickupGrenade")
						if (!("pickuphud" in getroottable()) || !pickuphud.IsValid()) {
							::pickuphud <- Entities.CreateByClassname("game_text")
							pickuphud.__KeyValueFromInt("effect", 0)
							pickuphud.__KeyValueFromInt("channel", 0)
							pickuphud.__KeyValueFromInt("fadein", 0)
							pickuphud.__KeyValueFromInt("fadeout", 0)
							pickuphud.__KeyValueFromFloat("holdtime", 0.5)
							pickuphud.__KeyValueFromFloat("y", 0.8)
							pickuphud.__KeyValueFromFloat("x", -1)
							pickuphud.__KeyValueFromString("color", "255 255 255")
							pickuphud.__KeyValueFromString("color2", "255 255 255")
						}
						if (wep in GunNames) {
							EntFireHandle(pickuphud, "SetText", "Picked up " + GunNames[wep])
							EntFireHandle(pickuphud, "Display", "", 0, ent)
						}
					}
					if (pickup.ValidateScriptScope()) {
						local ss = pickup.GetScriptScope()
						ss.previous_name <- pickup.GetName()
						ss.previous_model <- pickup.GetModelName()
						ss.last_pickup <- Time()
					}
					EntFireHandle(pickup, "addoutput", "targetname pickup_null")
					EntFireHandle(pickup, "disabledraw")
					break
				}
			}
		}
	}

	if (CURRENT_CURSE != CURSE_NONE && Time() - LAST_CURSE_TIME >= 90) {
		Chat(RED + "Your curse has worn off.")
		if ("onEnd" in CurseList[CURRENT_CURSE]) {
			CurseList[CURRENT_CURSE].onEnd()
		}
		CURRENT_CURSE = CURSE_NONE
	}

	// jimmy dean tv
	EntFire("milkers", "AddOutput", "texframeindex " + ((Time() * 0.2).tointeger() % 4))
}

::PMList <- [
	"tm_balkan_variantg",
	"ctm_fbi_variantf",
	"tm_balkan_variantc",
	"tm_separatist",
	"tm_leet_varianth",
	"ctm_fbi_variantc",
	"tm_leet_varianti",
	"ctm_st6_variantm",
	"tm_phoenix_variantf",
	"ctm_sas_variantf",
	"tm_professional_var1",
	"ctm_st6_varianti"
]

::KnifeList <- [
	"bayonet",
	"knife_survival_bowie",
	"knife_m9_bayonet",
	"knife_karambit",
	"knife_css",
	"knife_butterfly",
	"knife_stiletto",
]

::GiveChunkster <- function(ply) {
	SetModelSafe(ply, PlayerModel("ctm_heavy"))
	ply.SetHealth(200)
}

::GiveKnife <- function(ply, name) {
	local weps = GetWeapons(ply)
	foreach (wep in weps) {
		local cls = wep.GetClassname()
		if (cls == "weapon_knife" || cls == "weapon_knifegg") {
			wep.Destroy()
		}
	}
	if (name == "bayonet") {
		GiveWeapon(ply, "weapon_" + name)
	} else {
		GiveWeapon(ply, "weapon_knife_" + name)
	}
	MeleeFixup()
}

::SetKnife <- function(ply, name) {
	if (ply.ValidateScriptScope()) {
		ply.GetScriptScope().knife <- name
	}
	GiveKnife(ply, name)
}

::PlayerSpawned <- function(ply) {
	ply.SetMaxHealth(100)
	ply.SetHealth(100)

	GiveWeapons(ply, ["item_kevlar", "weapon_usp_silencer", "weapon_hegrenade"])
	SetModelSafe(ply, PlayerModel("tm_phoenix"))
	ModifySpeed(ply, 1.0)
	EntFireHandle(ply, "addoutput", "gravity 1.0")

	local knife = "bayonet"
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if ("falltp_times" in ss)
			ss.falltp_times = 0
		if ("knife" in ss)
			knife = ss.knife
	}
	GiveKnife(ply, knife)

	// spawn effects
	DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), ply.GetOrigin())
	ply.EmitSound("Player.Respawn")

	if (CURRENT_CURSE != CURSE_NONE && "onPlayerSpawn" in CurseList[CURRENT_CURSE])
		CurseList[CURRENT_CURSE].onPlayerSpawn(ply)
}

::FallTeleport <- function(ent) {
	local cls = ent.GetClassname()
	if (cls != "player" && cls.slice(0, 7) != "weapon_" && cls.slice(0, 5) != "prop_")
		return
	local pos = ent.GetOrigin()
	local m = 1.0
	// ent.SetOrigin(Vector(pos.x * m, pos.y * m, 2944))
	ent.SetOrigin(Vector(pos.x * m, pos.y * m, pos.z + 1472))

	// jail for spamming fall
	if (cls == "player" && ent.ValidateScriptScope()) {
		local ss = ent.GetScriptScope()
		if ("falltp_times" in ss) {
			// printl("before: " + ss.falltp_times)
			ss.falltp_times = Max((ss.falltp_times + 1) - Max(floor((Time() - ss.last_falltp)), 0), 1)
			// printl("after: " + ss.falltp_times)
			ss.last_falltp <- Time()
			if (ss.falltp_times >= 12) { // 10 -> 50
				local jailEnt = Entities.FindByName(null, "jail_exit")
				ent.SetOrigin(jailEnt.GetOrigin())
				EntFire("prison_alarm", "PlaySound")
				CenterPrint(ent, "ARRESTED:\nTOO MANY FALL!")
				ss.falltp_times = 0
			}
		} else {
			ss.falltp_times <- 1
			ss.last_falltp <- Time()
		}
	}
}

::ShotKim <- function(ply) {
	local jailEnt = Entities.FindByName(null, "jail_exit")
	ply.SetOrigin(jailEnt.GetOrigin())
	EntFire("prison_alarm", "PlaySound")
	CenterPrint(ply, "ARRESTED:\nSHOOTING GLORIOUS LEADER")
}
