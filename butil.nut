
if ("BUtil" in getroottable())
	return

::BUtil <- true

// CONSTANTS

::T <- 2
::CT <- 3
::INT_MAX <- 2147483647

// MISC

::EntFireHandle <- function(t, i, v = "", d = 0.0, a = null, c = null) EntFireByHandle(t, i, v, d, a, c)
::LocalPlayer <- function() return Entities.FindByClassname(null, "player")
::LocPly <- LocalPlayer
::NearestPlayer <- function(pos, range = 200) return Entities.FindByClassnameNearest("player", pos, range)
::Alive <- function(ent) return ent.GetHealth() > 0
::Entity <- function(name) return Entities.FindByName(null, name)
::Ent <- Entity
::tp <- function(e) LocPly().SetOrigin(Ent(e).GetOrigin())

::EntFireAny <- function(ent, i, v = "", d = 0.0, a = null, c = null) {
	if (typeof ent == "string")
		EntFire(ent, i, v, d, a, c)
	else
		EntFireHandle(ent, i, v, d, a, c)
}

::EntFireChain <- function(ent, i, v = "", d = 0.0, a = null, c = null) {
	EntFireAny(ent, i, v, d, a, c)
	return ent
}

::IsClearLOS <- function(a, b, ignore = null)
	return TraceLine(a, b, ignore) == 1

::GetPlayersAndBots <- function(start = null) {
	start = Entities.Next(start)
	if (start == null || start.GetClassname() == "player")
		return start

	return GetPlayersAndBots(start)
}

::GetPlayerList <- function() {
	local plys = []
	local ply = null
	while (ply = GetPlayersAndBots(ply)) {
		plys.push(ply)
	}
	return plys
}

::FilterArray <- function(arr, filter) {
	local newArr = []
	foreach (item in arr) {
		if (filter(item))
			newArr.push(item)
	}
	return newArr
}

::ForEachPlayerAndBot <- function(func) {
	local ply = null
	while (ply = GetPlayersAndBots(ply))
		func(ply)
}

::ForEachLivingPlayer <- function(func) {
	local ply = null
	while (ply = GetPlayersAndBots(ply)) {
		if (LivingPlayer(ply))
			func(ply)
	}
}

::GetLivingPlayers <- function(team = -1) {
	local alive = []
	local ply = null
	while (ply = GetPlayersAndBots(ply)) {
		if (LivingPlayer(ply) && (team == -1 || ply.GetTeam() == team))
			alive.push(ply)
	}
	return alive
}

::GetTerrorists <- function() return FilterArray(GetPlayerList(), function(ply) return ply.GetTeam() == T)
::GetTs <- GetTerrorists

::GetCounterTerrorists <- function() return FilterArray(GetPlayerList(), function(ply) return ply.GetTeam() == CT)
::GetCTs <- GetCounterTerrorists

::PointTowards <- function(ent, target) {
	if (typeof target != "Vector")
		target = target.GetOrigin()

	ent.SetForwardVector(target - ent.GetOrigin())
}

::TeleportToEntity <- function(ent, target, useAngles = true) {
	if (typeof target == "string")
		target = Entities.FindByName(null, target)
	ent.SetOrigin(target.GetOrigin())
	if (useAngles) {
		local a = target.GetAngles()
		ent.SetAngles(a.x, a.y, a.z)
	}
}

::SetKeyValue <- function(ent, key, val) {
	switch (typeof val) {
		case "integer":
			ent.__KeyValueFromInt(key, val)
			break

		case "float":
			ent.__KeyValueFromFloat(key, val)
			break

		case "string":
			ent.__KeyValueFromString(key, val)
			break

		case "Vector":
			ent.__KeyValueFromVector(key, val)
			break
	}
}

::CreateEntity <- function(cls, kv = {}) {
	local ent = Entities.CreateByClassname(cls)
	foreach (k, v in kv)
		SetKeyValue(ent, k, v)

	return ent
}

::SetHealthAndMaxHealth <- function(ent, health) {
	ent.SetMaxHealth(health)
	ent.SetHealth(health)
}

::GamemodeNameTable <- [
	["Casual", "Competitive", "Wingman"],
	["Arms Race", "Demolition", "Deathmatch"],
	[],
	["Custom"],
	["Guardian", "Co-op Strike"],
	[],
	["Danger Zone"]
]

::GetGamemodeName <- function() {
	local t = ScriptGetGameType()
	local m = ScriptGetGameMode()
	if (t in GamemodeNameTable) {
		if (m in GamemodeNameTable[t])
			return GamemodeNameTable[t][m]
		else if (GamemodeNameTable[t].len() > 0)
			return GamemodeNameTable[t][0]
	}
	return "Unknown"
}

::LoopString <- function(str, n) {
	if (n == 0) {
		return ""
	} else if (n == 1) {
		return str
	}
	local str2 = ""
	for (local i = 0; i < n; i++) {
		str2 += str
	}
	return str2
}
::LoopStr <- LoopString

// MODEL STUFF

::ModelPath <- function(str) return "models/" + str + ".mdl"
::PlayerModel <- function(str) return "models/player/custom_player/legacy/" + str + ".mdl"

// SCOPE VARIABLES

::GetScopeVar <- function(ent, name, def = 0) {
	if (ent.ValidateScriptScope()) {
		local ss = ent.GetScriptScope()
		if (name in ss)
			return ss[name]
	}
	return def
}

::SetScopeVar <- function(ent, name, val) {
	if (ent.ValidateScriptScope())
		return ent.GetScriptScope()[name] <- val

	return false
}

::AddScopeVar <- function(ent, name, val)
	SetScopeVar(ent, name, GetScopeVar(ent, name) + val)

// TIMERS

::TIMERS <- {}

::CreateTimer <- function(name, func, refire = 0.1) {
	local timer
	if (typeof refire == "array")
		timer = CreateEntity("logic_timer", {UseRandomTime = 1, LowerRandomBound = refire[0], UpperRandomBound = refire[1]})
	else
		timer = CreateEntity("logic_timer", {RefireTime = refire})

	if (timer.ValidateScriptScope()) {
		timer.GetScriptScope().OnTimer <- func
		timer.ConnectOutput("OnTimer", "OnTimer")
	}
	EntFireHandle(timer, "enable")
	::TIMERS[name] <- timer
	return timer
}

::TimerExists <- function(name) return name in TIMERS
::ValidTimer <- TimerExists
::GetTimer <- function(name) return TIMERS[name]
::DestroyTimer <- function(name) TIMERS[name].Destroy()
::PauseTimer <- function(name) EntFireHandle(TIMERS[name], "Disable")
::ResumeTimer <- function(name) EntFireHandle(TIMERS[name], "Enable")
::UnpauseTimer <- ResumeTimer

// MATH

::Sqr <- function(x) return x * x
::LogBase <- function(b, r) return log(r) / log(b)
::DistToSqr <- function(a, b) return Sqr(a.x - b.x) + Sqr(a.y - b.y) + Sqr(a.z - b.z)
::Distance <- function(a, b) return sqrt(DistToSqr(a, b))
::DistToSqr2D <- function(a, b) return Sqr(a.x - b.x) + Sqr(a.y - b.y)
::Distance2D <- function(a, b) return sqrt(DistToSqr2D(a, b))

::Min <- function(a, b = null) {
	if (typeof a == "array") {
		local m = a[0]
		foreach (n in a)
			m = Min(m, n)
		return m
	}
	return (a < b) ? a : b
}

::Max <- function(a, b = null) {
	if (typeof a == "array") {
		local m = a[0]
		foreach (n in a)
			m = Max(m, n)
		return m
	}
	return (a > b) ? a : b
}

::Round <- function(n) {
	local c = ceil(n)
	if (c - n <= 0.5)
		return c
	return floor(n)
}

::Approach <- function(start, dest, amt) {
	if (start > dest) return Clamp(start - amt, dest, start)
	else if (start < dest) return Clamp(start + amt, start, dest)
	return start
}

::Clamp <- function(val, min, max) {
	if (val > max) return max
	if (val < min) return min
	return val
}

::NormalizeVector <- function(v) {
	local max = fabs(v.x)
	if (fabs(v.y) > max) max = fabs(v.y)
	if (fabs(v.z) > max) max = fabs(v.z)
	if (max == 0) return v
	return Vector(v.x / max, v.y / max, v.z / max)
}

// RemapPoint
// gives the corresponding location of a vector on
// one finite plane, given its relative position on
// another finite plane.
// params:
// center - array containing vector positions of the
// centers of the starting and ending planes respectively
// orientation - array containing two other arrays of
// coordinate names, to rotate or flip the plane
// scale - used to scale up/down the final product
// (can also be a vector to change output shape)
// point - position of our point to remap
// example:
// RemapPoint([Vector(0, 0, 0), Vector(128, 0, 512)], [["x", "y"], ["x", "z"]], 1.0 / 64, Vector(...))
::RemapPoint <- function(center, orientation, scale, point) {
	if (typeof scale == "integer" || typeof scale == "float")
		scale = Vector(scale, scale, scale)
	local offset = (point - center[0])
	local output = center[1]
	output[orientation[1][0]] += (offset[orientation[0][0]] * scale[orientation[1][0]])
	output[orientation[1][1]] += (offset[orientation[0][1]] * scale[orientation[1][1]])
	return output
}

// my own LCG because I don't trust RandomInt anymore
::RSEED <- rand() // randception

::SetRandomSeed <- function(s) {
	::RSEED = s
}

// gives random int in [0, mx)
::NextRandom <- function(mx = INT_MAX) {
    ::RSEED = (1664525 * RSEED + 1013904223) % INT_MAX
    return RSEED % mx
}

// ARRAYS

::ShuffleArray <- function(arr) {
	local newArr = []
	foreach (item in arr)
		newArr.insert(NextRandom(newArr.len()), item)
	return newArr
}
::RandomizeArray <- ShuffleArray

::RandomFromArray <- function(arr)
	return arr[NextRandom(arr.len())]

// INTERPOLATION

::Lerp <- function(delta, min, max)
	return min + (delta * (max - min))

::LerpVector <- function(delta, min, max) {
	local vec = Vector(min.x, min.y, min.z)
	foreach (c in ["x", "y", "z"])
		vec[c] += (delta * (max[c] - min[c]))

	return vec
}

::EaseOutSine <- function(x)
	return math.sin((x * PI) / 2)

::EaseInOutElastic <- function(x) {
	if (x <= 0) return 0
	if (x >= 1) return 1

	local c5 = (2 * PI) / 4.5

	if (x < 0.5)
		return -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2

	return (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1
}

// CHAT COLORS

::CLEAR <- "\x0"
::WHITE <- "\x1"
::DARK_RED <- "\x2"
::VIOLET <- "\x3"
::LIME <- "\x4"
::MINT <- "\x5"
::GREEN <- "\x6"
::RED <- "\x7"
::GRAY <- "\x8"
::GREY <- GRAY
::YELLOW <- "\x9"
::GOLD <- "\x10"
::LIGHT_BLUE <- "\xB"
::BLUE <- "\xC"
::MAGENTA <- "\xE"

::GEORGE_CARLIN <- function()
	Chat(RED + "shit" + VIOLET + "piss" + LIME + "fuck" + GOLD + "cunt" + DARK_RED + "cock" + MAGENTA + "sucker" + YELLOW + "mother" + GREEN + "fucker" + BLUE + "tits")

// PRINTING

::DebugPrint <- function(txt) {
	if (GetDeveloperLevel() > 0)
		Chat(VIOLET + "[DEV] " + txt)
}

::PrintTable <- function(tab, printfunc = printl, indent = "") {
	if (typeof tab == "table") {
		printfunc(indent + "{")
		foreach (k, v in tab) {
			if (typeof v == "table" || typeof v == "array")
				PrintTable(v, printfunc, indent + "  ")
			else
				printfunc(indent + k + " = " + v)
		}
		printfunc(indent + "}")
	} else if (typeof tab == "array") {
		printfunc(indent + "[")
		foreach (v in tab) {
			if (typeof v == "table" || typeof v == "array")
				PrintTable(v, printfunc, indent + "  ")
			else
				printfunc(indent + v)
		}
		printfunc(indent + "]")
	} else {
		printfunc(tab)
	}
}

::CenterPrintAll <- ScriptPrintMessageCenterAll
::CenterPrintParams <- ScriptPrintMessageCenterAllWithParams
::CenterPrintTeam <- ScriptPrintMessageCenterTeam
::ChatPrintAll <- ScriptPrintMessageChatAll
::ChatPrintTeam <- ScriptPrintMessageChatTeam

::Chat <- function(t)
	ChatPrintAll(" " + t)

::ChatTeam <- function(i, t)
	ChatPrintTeam(i, " " + t)

::CenterPrint <- function(ply, msg, time = 5) {
	local temp_hint = Entities.CreateByClassname("env_hudhint")
	temp_hint.__KeyValueFromString("message", msg)
	EntFireHandle(temp_hint, "ShowHUDHint", "", 0, ply)
	EntFireHandle(temp_hint, "Kill", "", time)
}

// WEAPONS

::GetWeapons <- function(ply) {
	local weps = []
	local wep = null
	while (wep = Entities.FindByClassname(wep, "weapon_*")) {
		if (wep.GetOwner() == ply)
			weps.push(wep)
	}
	return weps
}

::GetWeapon <- function(ply, cls) {
	foreach (wep in GetWeapons(ply)) {
		if (wep.GetClassname() == cls)
			return wep
	}
	return null
}

::HasWeapon <- function(ply, cls)
	return GetWeapon(ply, cls) != null

::HasWeapons <- function(ply, arr = -1) {
	if (arr == -1) {
		while (wep = Entities.FindByClassname(wep, "weapon_*")) {
			if (wep.GetOwner() == ply)
				return true
		}
		return false
	} else {
		foreach (wep in arr) {
			if (!HasWeapon(wep))
				return false
		}
		return true
	}
}

::TranslateViewmodelToWeaponClass <- {
	["models/weapons/v_eq_decoy.mdl"] = "weapon_decoy",
	["models/weapons/v_eq_flashbang.mdl"] = "weapon_flashbang",
	["models/weapons/v_eq_fraggrenade.mdl"] = "weapon_hegrenade",
	["models/weapons/v_eq_incendiarygrenade.mdl"] = "weapon_incgrenade",
	["models/weapons/v_eq_molotov.mdl"] = "weapon_molotov",
	["models/weapons/v_eq_smokegrenade.mdl"] = "weapon_smokegrenade",
	["models/weapons/v_eq_taser.mdl"] = "weapon_taser",
	["models/weapons/v_ied.mdl"] = "weapon_c4",
	["models/weapons/v_healthshot.mdl"] = "weapon_healthshot",
	["models/weapons/v_sonar_bomb.mdl"] = "weapon_tagrenade",
	["models/weapons/v_knife.mdl"] = "weapon_knife",
	["models/weapons/v_knife_default_ct.mdl"] = "weapon_knife",
	["models/weapons/v_knife_default_t.mdl"] = "weapon_knife",
	["models/weapons/v_knife_gg.mdl"] = "weapon_knife",
	["models/weapons/v_knife_gg.mdl"] = "weapon_knife",
	["models/weapons/v_knife_bayonet.mdl"] = "weapon_knife",
	["models/weapons/v_knife_butterfly.mdl"] = "weapon_knife",
	["models/weapons/v_knife_falchion.mdl"] = "weapon_knife",
	["models/weapons/v_knife_bayonet.mdl"] = "weapon_knife",
	["models/weapons/v_knife_flip.mdl"] = "weapon_knife",
	["models/weapons/v_knife_gut.mdl"] = "weapon_knife",
	["models/weapons/v_knife_karam.mdl"] = "weapon_knife",
	["models/weapons/v_knife_m9_bay.mdl"] = "weapon_knife",
	["models/weapons/v_knife_push.mdl"] = "weapon_knife",
	["models/weapons/v_knife_survival_bowie.mdl"] = "weapon_knife",
	["models/weapons/v_knife_tactical.mdl"] = "weapon_knife",
	["models/weapons/v_knife_bayonet.mdl"] = "weapon_knife",
	["models/weapons/v_mach_m249para.mdl"] = "weapon_m249",
	["models/weapons/v_mach_negev.mdl"] = "weapon_negev",
	["models/weapons/v_pist_deagle.mdl"] = "weapon_deagle",
	["models/weapons/v_pist_elite.mdl"] = "weapon_elite",
	["models/weapons/v_pist_fiveseven.mdl"] = "weapon_fiveseven",
	["models/weapons/v_pist_glock18.mdl"] = "weapon_glock",
	["models/weapons/v_pist_hkp2000.mdl"] = "weapon_hkp2000",
	["models/weapons/v_pist_p250.mdl"] = "weapon_p250",
	["models/weapons/v_pist_tec9.mdl"] = "weapon_tec9",
	["models/weapons/v_pist_revolver.mdl"] = "weapon_revolver",
	["models/weapons/v_pist_223.mdl"] = "weapon_usp_silencer",
	["models/weapons/v_pist_cz_75.mdl"] = "weapon_cz75a",
	["models/weapons/v_rif_ak47.mdl"] = "weapon_ak47",
	["models/weapons/v_rif_aug.mdl"] = "weapon_aug",
	["models/weapons/v_rif_famas.mdl"] = "weapon_famas",
	["models/weapons/v_rif_galilar.mdl"] = "weapon_galilar",
	["models/weapons/v_rif_m4a1.mdl"] = "weapon_m4a1",
	["models/weapons/v_rif_m4a1_s.mdl"] = "weapon_m4a1_silencer",
	["models/weapons/v_rif_sg556.mdl"] = "weapon_sg556",
	["models/weapons/v_shot_mag7.mdl"] = "weapon_mag7",
	["models/weapons/v_shot_nova.mdl"] = "weapon_nova",
	["models/weapons/v_shot_sawedoff.mdl"] = "weapon_sawedoff",
	["models/weapons/v_shot_xm1014.mdl"] = "weapon_xm1014",
	["models/weapons/v_smg_bizon.mdl"] = "weapon_bizon",
	["models/weapons/v_smg_mac10.mdl"] = "weapon_mac10",
	["models/weapons/v_smg_mp5sd.mdl"] = "weapon_mp5sd",
	["models/weapons/v_smg_mp7.mdl"] = "weapon_mp7",
	["models/weapons/v_smg_mp9.mdl"] = "weapon_mp9",
	["models/weapons/v_smg_p90.mdl"] = "weapon_p90",
	["models/weapons/v_smg_ump45.mdl"] = "weapon_ump45",
	["models/weapons/v_snip_awp.mdl"] = "weapon_awp",
	["models/weapons/v_snip_g3sg1.mdl"] = "weapon_g3sg1",
	["models/weapons/v_snip_scar20.mdl"] = "weapon_scar20",
	["models/weapons/v_snip_ssg08.mdl"] = "weapon_ssg08"
}

::GetViewmodel <- function(ply) {
	local vm = null
	while (vm = Entities.FindByClassname(vm, "predicted_viewmodel")) {
		if (vm.GetMoveParent() == ply)
			break
	}
	return vm
}

::GetActiveWeaponClass <- function(ply) {
	local vm = GetViewmodel(ply)
	if (vm != null) {
		local vmn = vm.GetModelName()
		if (vmn in TranslateViewmodelToWeaponClass)
			return TranslateViewmodelToWeaponClass[vmn]
	}
	return "unknown"
}

::IsSameWeapon <- function(a, b) {
	if (a == b)
		return true
	if (a == "weapon_hkp2000" && b == "weapon_usp_silencer")
		return true
	if (a == "weapon_knifegg" && b == "weapon_knife")
		return true
	if (a == "weapon_deagle" && b == "weapon_revolver")
		return true
	return false
}

::GetActiveWeapon <- function(ply) {
	local cls = GetActiveWeaponClass(ply)
	foreach (k, v in GetWeapons(ply)) {
		if (IsSameWeapon(v.GetClassname(), cls))
			return v
	}
	return null
}

::GiveWeapon <- function(ply, weapon, ammo = 99999) {
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1, ply)
}

::GiveWeaponNoStrip <- function(ply, weapon, ammo = 99999) {
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 1)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1, ply)
}

::GiveWeapons <- function(ply, array) {
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	foreach (wep in array)
		equip.__KeyValueFromInt(wep, 999)
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1, ply)
}

::GiveLoadout <- function(ply, array) {
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 3)
	foreach (wep in array)
		equip.__KeyValueFromInt(wep, 999)
	EntFireHandle(equip, "Use", "", 0.0, ply)
	EntFireHandle(equip, "Kill", "", 0.1, ply)
}

/*
::GPEF_USEONLY <- 1
::GPEF_STRIPALL <- 2
::GPEF_STRIPSAME <- 4

::GiveWeapon <- function(ply, weapon, flags = 5) {
	if (!("__playerequip" in getroottable()) || !__playerequip.IsValid())
		::__playerequip <- Entities.CreateByClassname("game_player_equip")
	__playerequip.__KeyValueFromInt("spawnflags", flags)
	EntFireHandle(__playerequip, "TriggerForActivatedPlayer", weapon, 0.0, ply)
}

::GiveWeapons <- function(ply, array, flags = 5) {
	if (!("__playerequip" in getroottable()) || !__playerequip.IsValid())
		::__playerequip <- Entities.CreateByClassname("game_player_equip")
	__playerequip.__KeyValueFromInt("spawnflags", flags)
	foreach (weapon in array)
		EntFireHandle(__playerequip, "TriggerForActivatedPlayer", weapon, 0.0, ply)
}
*/

::RefillAmmo <- function(ply) {
	local ammo = Entities.CreateByClassname("point_give_ammo")
	EntFireByHandle(ammo, "GiveAmmo", "", 0, ply, null)
	EntFireByHandle(ammo, "Kill", "", 0.1, null, null)
}

::StripWeapons <- function(ply) {
	if (!("__weaponstrip" in getroottable()) || !__weaponstrip.IsValid())
		::__weaponstrip <- Entities.CreateByClassname("player_weaponstrip")
	EntFireHandle(__weaponstrip, "Strip", "", 0.0, ply)
}

::MeleeFixup <- function() {
	foreach (wep in ["knife", "fists", "melee"])
		EntFire("weapon_" + wep, "addoutput", "classname weapon_knifegg")
}

// DAMAGE

::SetDamageScale <- function(scale, team = -1) {
	if (team == -1 || team == T) {
		SendToConsoleServer("mp_damage_scale_t_head " + scale.tostring())
		SendToConsoleServer("mp_damage_scale_t_body " + scale.tostring())
	}
	if (team == -1 || team == CT) {
		SendToConsoleServer("mp_damage_scale_ct_head " + scale.tostring())
		SendToConsoleServer("mp_damage_scale_ct_body " + scale.tostring())
	}
}

::SetHeadshotsOnly <- function(on)
	SendToConsoleServer("mp_damage_headshots_only " + (on ? 1 : 0).tostring())

// MISC ENTITY

::IsValid <- function(ent)
	return ent != null

::Ignite <- function(ent, duration = 5)
	EntFireHandle(ent, "IgniteLifetime", duration.tostring())

::Heal <- function(ent, amt = 99999)
	ent.SetHealth(Clamp(ent.GetHealth() + amt, 0, ent.GetMaxHealth()))

::SetModelSafe <- function(ent, mdl) {
	ent.PrecacheModel(mdl)
	ent.SetModel(mdl)
}

// MONEY

::SPEND_PLY <- null
::SPEND_SUCCEEDED <- function() {}
::SPEND_FAILED <- function() {}

::__CreateMoneyManager <- function() {
	if (!("__moneyman" in getroottable()) || !__moneyman.IsValid()) {
		::__moneyman <- Entities.CreateByClassname("game_money")
		if (__moneyman.ValidateScriptScope()) {
			__moneyman.ConnectOutput("OnMoneySpent", "SpendSucc")
			__moneyman.ConnectOutput("OnMoneySpentFail", "SpendFail")
			__moneyman.GetScriptScope().SpendSucc <- function()
				::SPEND_SUCCEEDED(::SPEND_PLY)
			__moneyman.GetScriptScope().SpendFail <- function()
				::SPEND_FAILED(::SPEND_PLY)
		}
	}
}

::GiveMoney <- function(ply, amt, txt = "") {
	__CreateMoneyManager()
	__moneyman.__KeyValueFromString("AwardText", txt)
	__moneyman.__KeyValueFromInt("Money", amt)
	if (typeof ply == "integer") {
		if (ply == T)
			EntFireHandle(__moneyman, "AddTeamMoneyTerrorist")
		else if (ply == CT)
			EntFireHandle(__moneyman, "AddTeamMoneyCT")
	} else
		EntFireHandle(__moneyman, "AddMoneyPlayer", "", 0, ply)
}

::SpendMoney <- function(ply, amt, txt = "", succ = function(p) {}, fail = function(p) {}) {
	__CreateMoneyManager()
	::SPEND_SUCCEEDED <- succ
	::SPEND_FAILED <- fail
	__moneyman.__KeyValueFromString("AwardText", txt)
	__moneyman.__KeyValueFromInt("Money", amt)
	EntFireHandle(__moneyman, "SpendMoneyFromPlayer", "", 0, ply)
}

// MISC PLAYER

::SMFLAG_NONE <- 0
::SMFLAG_WEAPONS <- 1
::SMFLAG_HUD <- 2
::SMFLAG_JUMP <- 4
::SMFLAG_DUCK <- 8
::SMFLAG_USE <- 16
::SMFLAG_SPRINT <- 32
::SMFLAG_ATTACK <- 64
::SMFLAG_ZOOM <- 128

::LivingPlayer <- function(ent)
	return (ent != null && ent.GetClassname() == "player" && ent.GetHealth() > 0)

::ModifySpeed <- function(ply, speed, flags = 0) {
	if (!("__speedmod" in getroottable()) || !__speedmod.IsValid())
		::__speedmod <- Entities.CreateByClassname("player_speedmod")

	__speedmod.__KeyValueFromInt("spawnflags", flags)
	EntFireHandle(__speedmod, "ModifySpeed", speed.tostring(), 0.0, ply)
}

::ModifySpeedTemporarily <- function(ply, speed, time, flags = 0) {
	if (!("__speedmod" in getroottable()) || !__speedmod.IsValid())
		::__speedmod <- Entities.CreateByClassname("player_speedmod")

	__speedmod.__KeyValueFromInt("spawnflags", flags)
	EntFireHandle(__speedmod, "ModifySpeed", speed.tostring(), 0.0, ply)
	EntFireHandle(__speedmod, "addoutput", "spawnflags " + flags, time, ply)
	EntFireHandle(__speedmod, "ModifySpeed", "1", time, ply)
}

::ClientCMD <- function(ply, cmd, delay = 0.0) {
	if (!("__clientcmd" in getroottable()) || !__clientcmd.IsValid())
		::__clientcmd <- Entities.CreateByClassname("point_clientcommand")

	EntFireHandle(__clientcmd, "Command", cmd, delay, ply)
}

::BroadcastCMD <- function(cmd) {
	if (!("__broadcastcmd" in getroottable()) || !__broadcastcmd.IsValid())
		::__broadcastcmd <- Entities.CreateByClassname("point_broadcastclientcommand")

	EntFireHandle(__broadcastcmd, "Command", cmd)
}

::GetPlayerFromIndex <- function(index) {
	local ply = null
	while (ply = GetPlayersAndBots(ply)) {
		if (ply.entindex() == index)
			break
	}
	return ply
}

// DRAWING

::DrawLine <- DebugDrawLine
::DrawBox <- DebugDrawBox

::DrawAxes <- function(pos, size = 8, ignorez = false, duration = 5) {
	DrawLine(pos - Vector(size, 0, 0), pos + Vector(size, 0, 0), 255, 0, 0, ignorez, duration)
	DrawLine(pos - Vector(0, size, 0), pos + Vector(0, size, 0), 0, 255, 0, ignorez, duration)
	DrawLine(pos - Vector(0, 0, size), pos + Vector(0, 0, size), 0, 0, 255, ignorez, duration)
}

::DrawBoundingBox <- function(ent, r = 255, g = 0, b = 0, alpha = 120, duration = 5)
	DrawBox(ent.GetCenter(), ent.GetBoundingMins(), ent.GetBoundingMaxs(), r, g, b, alpha, duration)

::DebugTraceLine <- function(v1, v2, e, r = 255, g = 0, b = 0) {
	local t = TraceLine(v1, v2, e)
	DebugDrawLine(v1, v1 + ((v2 - v1) * t), r, g, b, true, 0.1)
	return t
}

// PLAYER EVENTS

::HookToPlayerDeath <- function(func) {
	death <- Entities.CreateByClassname("trigger_brush")
	death.__KeyValueFromString("targetname", "game_playerdie")
	if (death.ValidateScriptScope()) {
		death.ConnectOutput("OnUse", "EventFired")
		if (typeof func == "string") {
			death.GetScriptScope().EventFired <- function()
				getroottable()[func](activator)
		} else {
			death.GetScriptScope().func <- func
			death.GetScriptScope().EventFired <- function()
				func(activator)
		}
	}
}

::HookToPlayerKill <- function(func) {
	kill <- Entities.CreateByClassname("trigger_brush")
	kill.__KeyValueFromString("targetname", "game_playerkill")
	if (kill.ValidateScriptScope()) {
		kill.ConnectOutput("OnUse", "EventFired")
		if (typeof func == "string") {
			kill.GetScriptScope().EventFired <- function()
				getroottable()[func](activator)
		} else {
			kill.GetScriptScope().func <- func
			kill.GetScriptScope().EventFired <- function()
				func(activator)
		}
	}
}

// PERSISTENT VARIABLES

if (!("PERSISTENT" in getroottable())) {
	::PersistentVars <- {}
	::PersistentVars.Holder <- Entities.FindByClassname(null, "worldspawn")
	if (PersistentVars.Holder.GetOwner() == null) {
		::PersistentVars.State <- Entities.CreateByClassname("info_target")
		::PersistentVars.Holder.SetOwner(PersistentVars.State)
	} else
		::PersistentVars.State <- PersistentVars.Holder.GetOwner()

	if (PersistentVars.State.ValidateScriptScope())
		::PERSISTENT <- PersistentVars.State.GetScriptScope()
}

// OTHER EVENTS

::ConnectData <- {}

::HOOKS <- {
/*
	// FIXME: the following only work on players who connect while the map is loaded and butil is running
	["player_connect"] = {
		["__base"] = function(data) {
			::ConnectData[data.userid] <- data
		}
	},
	["player_spawn"] = {
		["__base"] = function(data) {
			if (data.userid in ConnectData) {
				local d = ConnectData[data.userid]
				local ply = GetPlayerFromIndex(d.index + 1)
				if (ply.ValidateScriptScope() && !("steamid" in ply.GetScriptScope())) {
					local ss = ply.GetScriptScope()
					ss.name <- d.name
					ss.userid <- d.userid
					ss.steamid <- d.networkid
					if (GetDeveloperLevel() > 0)
						Chat(BLUE + ss.name + LIGHT_BLUE + " connected. (" + BLUE + ss.steamid + LIGHT_BLUE + ")")
				}
			}
		}
	},
*/
	["player_use"] = {
		["__base"] = function(data) {
			if (data.entity == 0) {
				if (::UserIDCapturedPlayer != null && UserIDCapturedPlayer.ValidateScriptScope()) {
					::UserIDCapturedPlayer.GetScriptScope().userid <- data.userid
					printl("userid " + data.userid + " assigned to " + UserIDCapturedPlayer)
				}

				::UserIDCapturedPlayer = null // idfk :(
			}
		}
	}
}

::AddHook <- function(event, name, func) {
	if (!(event in HOOKS))
		::HOOKS[event] <- {}

	if (typeof func == "string")
		::HOOKS[event][name] <- getroottable()[func]
	else
		::HOOKS[event][name] <- func
}

// typically going to be called from a logic_eventlistener
// make sure to set the listener's targetname to the event name
::EventFired <- function(ent, data) {
	local event = (typeof ent == "string") ? ent : ent.GetName()

	if (event in HOOKS) {
		foreach (index in ["userid", "attacker"]) {
			if (index in data)
				data[index + "_player"] <- GetPlayerFromUserID(data[index])
		}

		foreach (k, v in HOOKS[event])
			v(data)
	}
}

::GetUserID <- function(ply) {
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if ("userid" in ss)
			return ss.userid
	}
	return 0
}

::GetPlayerName <- function(ply) {
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if ("name" in ss)
			return ss.name
	}
	return "Player"
}

::GetSteamID <- function(ply) {
	if (ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if ("steamid" in ss)
			return ss.steamid
	}
	return "Missing SteamID"
}

::GetPlayerFromUserID <- function(id) {
	// singleplayer support (maybe?)
	if (!id) {
		return null
		// printl("using LocalPlayer fallback for null userid")
		// return LocalPlayer()
	}

	local ply = null
	while (ply = GetPlayersAndBots(ply)) {
		if (GetUserID(ply) == id)
			break
	}
	return ply
}

// HAMMER COMPATIBILITY

::WEAPON_KNIFE <- "weapon_knife"
::WEAPON_TAGRENADE <- "weapon_tagrenade"
::WEAPON_HEALTHSHOT <- "weapon_healthshot"
::WEAPON_TEC9 <- "weapon_tec9"
::WEAPON_M249 <- "weapon_m249"
::WEAPON_FLASHBANG <- "weapon_flashbang"
::WEAPON_INCGRENADE <- "weapon_incgrenade"
::WEAPON_INCENDIARY <- WEAPON_INCGRENADE
::WEAPON_SSG08 <- "weapon_ssg08"
::WEAPON_SCOUT <- WEAPON_SSG08
::WEAPON_NEGEV <- "weapon_negev"
::WEAPON_SCAR20 <- "weapon_scar20"
::WEAPON_SCAR <- WEAPON_SCAR20
::WEAPON_MP7 <- "weapon_mp7"
::WEAPON_P90 <- "weapon_p90"
::WEAPON_G3SG1 <- "weapon_g3sg1"
::WEAPON_AUTOSNIPER <- WEAPON_G3SG1
::WEAPON_AWP <- "weapon_awp"
::WEAPON_ELITE <- "weapon_elite"
::WEAPON_ELITES <- WEAPON_ELITE
::WEAPON_DUALIES <- WEAPON_ELITE
::WEAPON_UMP45 <- "weapon_ump45"
::WEAPON_UMP <- WEAPON_UMP45
::WEAPON_BIZON <- "weapon_bizon"
::WEAPON_AK47 <- "weapon_ak47"
::WEAPON_MP9 <- "weapon_mp9"
::WEAPON_MP5SD <- "weapon_mp5sd"
::WEPAON_MP5 <- WEAPON_MP5SD
::WEAPON_XM1014 <- "weapon_xm1014"
::WEAPON_AUTOSHOTGUN <- WEAPON_XM1014
::WEAPON_AUTOSHOTTY <- WEAPON_XM1014
::WEAPON_SAWEDOFF <- "weapon_sawedoff"
::WEAPON_MOLOTOV <- "weapon_molotov"
::WEAPON_AUG <- "weapon_aug"
::WEAPON_MAG7 <- "weapon_mag7"
::WEAPON_FIVESEVEN <- "weapon_fiveseven"
::WEAPON_57 <- WEAPON_FIVESEVEN
::WEAPON_M4A1_SILENCER <- "weapon_m4a1_silencer"
::WEAPON_M4A1S <- WEAPON_M4A1_SILENCER
::WEAPON_M4A1 <- WEAPON_M4A1_SILENCER
::WEAPON_SG556 <- "weapon_sg556"
::WEAPON_SG553 <- WEAPON_SG556
::WEAPON_KRIEG <- WEAPON_SG556
::WEAPON_FAMAS <- "weapon_famas"
::WEAPON_GALILAR <- "weapon_galilar"
::WEAPON_GALIL <- WEAPON_GALILAR
::WEAPON_GLOCK <- "weapon_glock"
::WEAPON_GLOCK18 <- WEAPON_GLOCK
::WEAPON_NOVA <- "weapon_nova"
::WEAPON_MAC10 <- "weapon_mac10"
::WEAPON_MAC <- WEAPON_MAC10
::WEAPON_CZ75A <- "weapon_cz75a"
::WEAPON_CZ75 <- WEAPON_CZ75A
::WEAPON_CZ <- WEAPON_CZ75A
::WEAPON_USP_SILENCER <- "weapon_usp_silencer"
::WEAPON_USPS <- WEAPON_USP_SILENCER
::WEAPON_USP <- WEAPON_USP_SILENCER
::WEAPON_HKP2000 <- "weapon_hkp2000"
::WEAPON_P2000 <- WEAPON_HKP2000
::WEAPON_P2K <- WEAPON_HKP2000
::WEAPON_SMOKEGRENADE <- "weapon_smokegrenade"
::WEAPON_SMOKE <- WEAPON_SMOKEGRENADE
::WEAPON_P250 <- "weapon_p250"
::WEAPON_TASER <- "weapon_taser"
::WEAPON_ZEUSX27 <- WEAPON_TASER
::WEAPON_ZEUS <- WEAPON_TASER
::WEAPON_M4A4 <- "weapon_m4a1"
::WEAPON_DECOY <- "weapon_decoy"
::WEAPON_DECOYGRENADE <- "weapon_decoy"
::WEAPON_DEAGLE <- "weapon_deagle"
::WEAPON_HEGRENADE <- "weapon_hegrenade"
::WEAPON_GRENADE <- WEAPON_HEGRENADE
::WEAPON_FRAG <- WEAPON_HEGRENADE
::WEAPON_FRAGGRENADE <- WEAPON_HEGRENADE
::WEAPON_REVOLVER <- "weapon_revolver"
::WEAPON_R8 <- WEAPON_REVOLVER
::WEAPON_C4 <- "weapon_c4"
::WEAPON_BOMB <- WEAPON_C4
::WEAPON_AXE <- "weapon_axe"
::WEAPON_HAMMER <- "weapon_hammer"
::WEAPON_SPANNER <- "weapon_spanner"
::WEAPON_WRENCH <- WEAPON_SPANNER
::WEAPON_SHIELD <- "weapon_shield"
::WEAPON_SNOWBALL <- "weapon_snowball"
::WEAPON_FISTS <- "weapon_fists"
::WEAPON_FIST <- WEAPON_FISTS
::WEAPON_BUMPMINE <- "weapon_bumpmine"
::WEAPON_BUMP <- WEAPON_BUMPMINE
::WEAPON_BREACHCHARGE <- "weapon_breachcharge"
::WEAPON_BREACH <- WEAPON_BREACHCHARGE
::ITEM_DEFUSER <- "item_defuser"
::ITEM_KIT <- ITEM_DEFUSER
::ITEM_DEFUSEKIT <- ITEM_DEFUSER
::ITEM_CUTTERS <- "item_cutters"
::ITEM_NIGHTVISION <- "item_nvgs"
::ITEM_NVGS <- ITEM_NIGHTVISION
::ITEM_NVG <- ITEM_NIGHTVISION
::ITEM_KEVLAR <- "item_kevlar"
::ITEM_ARMOR <- ITEM_KEVLAR
::ITEM_ASSAULTSUIT <- "item_assaultsuit"
::ITEM_KEVLARHELMET <- ITEM_ASSAULTSUIT
::ITEM_ARMORHELMET <- ITEM_ASSAULTSUIT
::ITEM_HELMET <- ITEM_ASSAULTSUIT
::ITEM_HEAVYARMOR <- "item_heavyassaultsuit"
::WEAPON_KNIFE_T <- "weapon_knife_t"
::WEAPON_BAYONET <- "weapon_bayonet"
::WEAPON_KNIFE_BAYONET <- WEAPON_BAYONET
::WEAPON_KNIFE_M9_BAYONET <- "weapon_knife_m9_bayonet"
::WEAPON_KNIFE_KARAMBIT <- "weapon_knife_karambit"
::WEAPON_KNIFE_BUTTERFLY <- "weapon_knife_butterfly"
::WEAPON_KNIFE_STILETTO <- "weapon_knife_stiletto"

// OLD-FASHIONED USERID ASSIGNMENT

::UserIDCapturedPlayer <- null

::UserIDThink <- function(ply) {
	if (UserIDCapturedPlayer == null && ply.ValidateScriptScope()) {
		local ss = ply.GetScriptScope()
		if (!("userid" in ss)) {
			if (!("gameevents_proxy" in getroottable()) || !(::gameevents_proxy.IsValid())) {
				::gameevents_proxy <- Entities.CreateByClassname("info_game_event_proxy")
				::gameevents_proxy.__KeyValueFromString("event_name", "player_use")
				::gameevents_proxy.__KeyValueFromInt("range", 0)
			}

			//ss.attempttogenerateuserid <- true
			::UserIDCapturedPlayer = ply
			EntFireHandle(::gameevents_proxy, "GenerateGameEvent", "", 0.0, ply)

			return
		}
	}
}

// deleting entities while looping through them causes the loop to repeat

::DELETION_QUEUE <- []

::QueueForDeletion <- function(ent)
	DELETION_QUEUE.push(ent)

::FlushDeletionQueue <- function() {
	foreach (ent in DELETION_QUEUE)
		ent.Destroy()

	::DELETION_QUEUE = []
}

// AI NODES AND PATHFINDING

// A* finds a path from start to goal.
// h is the heuristic function. h(n) estimates the cost to reach goal from node n.
::AStar <- function(start, goal) {
	// The set of discovered nodes that may need to be (re-)expanded.
	// Initially, only the start node is known.
	// This is usually implemented as a min-heap or priority queue rather than a hash-set.
	openSet <- [start]

	// For node n, cameFrom[n] is the node immediately preceding it on the cheapest path from start
	// to n currently known.
	cameFrom <- {}

	// For node n, gScore[n] is the cost of the cheapest path from start to n currently known.
	gScore <- {} // Default value Infinity
	gScore[start] <- 0

	// For node n, fScore[n] := gScore[n] + h(n). fScore[n] represents our current best guess as to
	// how short a path from start to finish can be if it goes through n.
	fScore <- {} // Default value Infinity
	fScore[start] <- DistanceBetweenNodes(start, goal)

	while (openSet.len() > 0) {
		// This operation can occur in O(1) time if openSet is a min-heap or a priority queue
		// current is the node in openSet having the lowest fScore[] value
		local currentIndex = 0
		local current = openSet[currentIndex]
		foreach (i, node in openSet) {
			if (!(node in fScore))
				fScore[node] <- INT_MAX

			if (fScore[node] < fScore[current]) {
				currentIndex = i
				current = node
			}
		}

		// Reconstruct the final path and return it
		if (current == goal) {
			local total_path = [current]
			while (current in cameFrom) {
				current = cameFrom[current]
				total_path.insert(0, current)
			}
			return total_path
		}

		// Remove from array
		openSet.remove(currentIndex)

		foreach (neighbor in NodeGraph[current].connections) {
			foreach (node in [current, neighbor])
				if (!(node in gScore))
					gScore[node] <- INT_MAX

			// d(current,neighbor) is the weight of the edge from current to neighbor
			// tentative_gScore is the distance from start to the neighbor through current
			local tentative_gScore = gScore[current] + DistanceBetweenNodes(current, neighbor)
			if (tentative_gScore < gScore[neighbor]) {
				// This path to neighbor is better than any previous one. Record it!
				cameFrom[neighbor] <- current
				gScore[neighbor] <- tentative_gScore
				fScore[neighbor] <- gScore[neighbor] + DistanceBetweenNodes(neighbor, goal)
				if (!(neighbor in openSet))
					openSet.push(neighbor)
			}
		}
	}

	// Open set is empty but goal was never reached
	return [-1]
}

::NodeGraph <- {}

::IsValidPath <- function(a, b, ent = null) {
	// Sight check
	if (!IsClearLOS(a, b, ent))
		return false

	// Floating check
	local maxHeightOffFloor = Vector(0, 0, 20)
	for (local i = 0.2; i < 0.9; i += 0.2) {
		local c = a + ((b - a) * i)
		if (IsClearLOS(c, c - maxHeightOffFloor, ent))
			return false
	}

	return true
}

::BuildNodeGraph <- function() {
	::NodeGraph <- {}
	local ent = null
	while (ent = Entities.FindByName(ent, "ai_node")) {
		local tab = {}
		tab.index <- ent.entindex()
		tab.pos <- ent.GetOrigin()
		tab.connections <- []
		::NodeGraph[tab.index] <- tab
	}
	foreach (i, node in ::NodeGraph) {
		foreach (j, subnode in ::NodeGraph) {
			if (i == j)
				continue

			if (IsValidPath(node.pos, subnode.pos) && !(subnode.index in node.connections))
				node.connections.push(subnode.index)
		}
	}

	// Build NodeGraph
	foreach (i, node in NodeGraph) {
		node.path <- {}
		foreach (j, subnode in NodeGraph)
			node.path[j] <- AStar(i, j)
	}
}

::GetNearestNode <- function(pos, checkLOS = true) {
	local nearest = -1
	local dist = 0
	foreach (i, node in NodeGraph) {
		if ((nearest == -1 || DistToSqr(pos, node.pos) < dist) && (IsClearLOS(pos, node.pos) || !checkLOS)) {
			nearest = i
			dist = DistToSqr(pos, node.pos)
		}
	}
	return nearest
}

::IsValidNode <- function(i)
	return (i in NodeGraph) && (typeof NodeGraph[i] == "table")

::VisualizeNode <- function(i) {
	if (!IsValidNode(i))
		return
	node <- NodeGraph[i]
	foreach (connection in node.connections)
		DebugDrawLine(node.pos, NodeGraph[connection].pos, 255, 0, 255, false, 8)
}

::VisualizeNodes <- function() {
	foreach (i, node in NodeGraph)
		VisualizeNode(i)
}

::DistanceBetweenNodes <- function(a, b)
	return Distance(NodeGraph[a].pos, NodeGraph[b].pos)

// EYE ANGLE MEASUREMENTS

::CreateEyeMeasure <- function(ply) {
	local ref = UniqueString()
	local ent = CreateEntity("logic_measure_movement", {
		measuretype = 1,
		measurereference = "",
		measureretarget = "",
		targetreference = ref,
		target = ref,
		targetscale = 1.0,
		targetname = ref,
	})

	EntFireHandle(ent, "SetMeasureReference", ref)
	EntFireHandle(ent, "SetMeasureTarget", (typeof ply == "string") ? ply : ply.GetName())
	EntFireHandle(ent, "Enable")

	return ent
}

::SetEyeMeasure <- function(ent, ply)
	EntFireHandle(ent, "SetMeasureTarget", (typeof ply == "string") ? ply : ply.GetName())

// STUPID TF STUFF

::PLAYER_CLASSES <- [null]
::PLAYER_CONDITIONS <- [null]

::RegisterCond <- function(data) {
	::PLAYER_CONDITIONS.push(data)
	return PLAYER_CONDITIONS.len() - 1
}

::AddCond <- function(ply, cond, dur = 999999999) {
	if (!ply.ValidateScriptScope())
		return

	local scope = ply.GetScriptScope()
	if (!("conds" in scope))
		scope.conds <- {}

	if (cond in scope.conds)
		scope.conds[cond] = Max(scope.conds, Time()) + dur
	else
		scope.conds[cond] <- Time() + dur
}

::RemoveCond <- function(ply, cond) {
	// TODO
}
