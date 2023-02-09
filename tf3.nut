
// file name is not typo

IncludeScript("butil")

::ChunksterActive <- false

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_teammates_are_enemies 1")
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_respawnwavetime_t 4 1")
	SendToConsoleServer("mp_respawnwavetime_ct 4 1")
	SendToConsoleServer("mp_use_respawn_waves 1")
	SendToConsoleServer("sv_infinite_ammo 2")
	SendToConsoleServer("sv_hegrenade_damage_multiplier 2")
	SendToConsoleServer("sv_falldamage_scale 0")
	SendToConsoleServer("sv_airaccelerate 1337")
	SendToConsoleServer("sv_autobunnyhopping 1")
	SendToConsoleServer("weapon_accuracy_nospread 1")
	HookToPlayerKill(function(ply)
	{
		EntFire("hud_hitmarker", "display", "", 0, ply)
		if (ply.GetHealth() < ply.GetMaxHealth())
		{
			ply.SetHealth(Clamp(ply.GetHealth() + 50, 0, ply.GetMaxHealth()))
			CenterPrint(ply, "Nice kill! +50 health")
		}
	})
	HookToPlayerDeath(function(ply)
	{
		if (RandomInt(1, 100) == 69)
			ply.EmitSound("Chicken.Death")
		else if (RandomInt(1, 6) == 3)
			ply.EmitSound("Hostage.Pain")
		local wep = null
		while (wep = Entities.Next(wep))
			if ((wep.GetClassname() == "weapon_hkp2000" || wep.GetClassname() == "weapon_hegrenade") && wep.GetOwner() == null)
				wep.Destroy()
		if (false && ply.GetModelName() == "models/player/custom_player/legacy/ctm_heavy.mdl")
		{
			ChatPrintAll(" " + RED + "The Chunkster has died!")
			::ChunksterActive <- false
		}
		// progress the clock
		local minute_hand = Entities.FindByName(null, "clock_hand_minute")
		if (minute_hand != null)
			minute_hand.SetAngles(minute_hand.GetAngles().x - 15, 0, 0)
		local hour_hand = Entities.FindByName(null, "clock_hand_hour")
		if (hour_hand != null)
		{
			local new_pitch = hour_hand.GetAngles().x - 5
			if (new_pitch <= -360)
			{
				hour_hand.SetAngles(0, 0, 0)
				ChatPrintAll(" " + RED + "The Kill Clock strikes midnight!")
				BroadcastCMD("playvol ambient/canals/ambience_canals_bell_bg.wav 1")
			}
			else
				hour_hand.SetAngles(new_pitch, 0, 0)
		}
	})
}

::OverrideVM <- {
	["models/weapons/v_eq_decoy.mdl"] = "models/weapons/v_knife_bayonet.mdl",
	//["models/weapons/v_eq_fraggrenade.mdl"] = "models/weapons/v_hammer.mdl",
	["models/weapons/v_sonar_bomb.mdl"] = "models/weapons/v_spanner.mdl",
}

::RotateMe <- function(ent)
{
	local ang = ent.GetAngles()
	ent.SetAngles(ang.x, ang.y + 2, ang.z)
}

Think <- function()
{
	local deleted = []
	local ent = null
	while (ent = Entities.FindByClassname(ent, "predicted_viewmodel"))
	{
		local mdl = ent.GetModelName()
		if (mdl in OverrideVM)
		{
			SetModelSafe(ent, OverrideVM[mdl])
		}
	}
	// Think is only called every 0.1s, calling it
	// twice smooths out the speeeeeen animation
	EntFire("pickup_*", "runscriptcode", "RotateMe(self)", 0.05)
	while (ent = Entities.FindByName(ent, "pickup_*"))
	{
		RotateMe(ent)
		local name = ent.GetName()
		if (name == "pickup_null")
			continue
		local user = Entities.FindByClassnameNearest("player", ent.GetOrigin() - Vector(0, 0, 30), 30)
		if (user != null)
		{
			if (name == "pickup_health" || name == "pickup_melon")
			{
				local current = user.GetHealth()
				local max = user.GetMaxHealth()
				if (user.GetHealth() >= max)
					continue
				local new_health = current + ((name == "pickup_health") ? 100 : 50)
				if (new_health > max)
					new_health = max
				user.SetHealth(new_health)
				ent.EmitSound("HealthShot.Pickup")
			}
			else if (name == "pickup_ammo")
			{
				RefillAmmo(user)
				ent.EmitSound("Weapon_AK47.BoltPull")
			}
			else
			{
				local wep = name.slice(7)
				if (HasWeapon(user, wep))
					continue
				local kill_list = []
				local old_wep = null
				while (old_wep = Entities.FindByClassnameWithin(old_wep, wep, ent.GetOrigin(), 100))
					if (old_wep.GetOwner() == null)
						kill_list.push(old_wep)
				foreach (target in kill_list)
					target.Destroy()
				GiveWeaponNoStrip(user, wep)
				ent.EmitSound("Player.PickupGrenade")
				if (wep == "item_assaultsuit")
				{
					SetModelSafe(user, PLYMDL("ctm_heavy"))
					user.SetHealth(200)
				}
			}
			EntFireHandle(ent, "addoutput", "targetname pickup_null")
			EntFireHandle(ent, "disabledraw")
			EntFireHandle(ent, "addoutput", "targetname " + name, 30)
			EntFireHandle(ent, "enabledraw", "", 30)
		}
	}
	while (ent = Entities.FindByClassname(ent, "decoy_projectile"))
	{
		if (!ent.ValidateScriptScope())
			continue
		local owner = ent.GetOwner()
		if (owner == null)
			continue
		local ss = ent.GetScriptScope()
		if (!("thrown_knife" in ss))
		{
			ss.thrown_knife <- true
			SetModelSafe(ent, "models/weapons/w_knife_bayonet_dropped.mdl")
			ent.EmitSound("Player.GhostKnifeSwish")
			GiveWeaponNoStrip(owner, "weapon_decoy")
		}
		if (ent.GetVelocity().Length() < 1)
			deleted.push(ent)
		else
		{
			ent.EmitSound("Weapon_Knife.Slash")
			local ply = null
			while (ply = Entities.FindByClassnameWithin(ply, "*", ent.GetOrigin(), 20))
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
					deleted.push(ent)
				}
			}
		}
	}
	while (ent = Entities.FindByClassname(ent, "hegrenade_projectile"))
	{
		if (!ent.ValidateScriptScope())
			continue
		local ss = ent.GetScriptScope()
		if ("spawn_time" in ss)
		{
			if ((Time() - ss.spawn_time > 1.5) && !("chicken_nade" in ss))
			{
				ss.chicken_nade <- true
				ent.EmitSound("Chicken.Death")
				for (local i = 0; i < 4; i++)
					DispatchParticleEffect("chicken_gone", ent.GetOrigin(), ent.GetOrigin())
				//local hhg_snd = Entities.FindByName(null, "vampire_hhg")
				//if (hhg_snd != null)
				//{
				//	hhg_snd.SetOrigin(ent.GetOrigin())
				//	EntFireHandle(hhg_snd, "playsound")
				//}
			}
		}
		else
		{
			ss.spawn_time <- Time()
			SetModelSafe(ent, "models/chicken/chicken.mdl")
			local owner = ent.GetOwner()
			if (owner != null)
				owner.EmitSound("Chicken.Death")
		}
	}
	foreach (ent in deleted)
	{
		if (ent != null)
			ent.Destroy()
	}
}

::PLAYERMODEL_PREFIX <- "models/player/custom_player/legacy/"
::PLAYERMODEL_POSTFIX <- ".mdl"
::PLYMDL <- function(mdl) {return PLAYERMODEL_PREFIX + mdl + PLAYERMODEL_POSTFIX}

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
	"knife_karambit"
]

::PlayerSpawned <- function(ply)
{
	ply.SetMaxHealth(100)
	ply.SetHealth(100)
	GiveWeapons(ply, ["item_kevlar", "weapon_usp_silencer", "weapon_" + KnifeList[RandomInt(0, KnifeList.len() - 1)], "weapon_hegrenade"])
	MeleeFixup()
	DispatchParticleEffect("firework_crate_explosion_01", ply.GetOrigin(), ply.GetOrigin())
	ply.EmitSound("Player.Respawn")
	// DISABLE CHUNKSTER
	if (false && RandomInt(1, 20) == 1 && !ChunksterActive)
	{
		::ChunksterActive <- true
		ChatPrintAll(" " + RED + "The Chunkster has arrived with 2000hp!")
		SetModelSafe(ply, PLYMDL("ctm_heavy"))
		ply.SetMaxHealth(2000)
		ply.SetHealth(2000)
		ModifySpeed(ply, 0.6)
		EntFireHandle(ply, "addoutput", "gravity " + (1.0 / 0.6))
	}
	else
	{
		// local mdl = PLYMDL(PMList[RandomInt(0, PMList.len() - 1)])
		SetModelSafe(ply, PLYMDL("tm_phoenix"))
		ply.SetMaxHealth(100)
		ply.SetHealth(100)
		ModifySpeed(ply, 1.0)
		EntFireHandle(ply, "addoutput", "gravity 1.0")
	}
}

::FallTeleport <- function(ent)
{
	local cls = ent.GetClassname()
	if (cls != "player" && cls.slice(0, 7) != "weapon_")
		return
	local pos = ent.GetOrigin()
	local m = 1.0
	ent.SetOrigin(Vector(pos.x * m, pos.y * m, 1472 * 2))

	// jail for spamming fall
	if (cls == "player" && ent.ValidateScriptScope())
	{
		local ss = ent.GetScriptScope()
		if ("falltp_times" in ss)
		{
			printl("before: " + ss.falltp_times)
			ss.falltp_times = Max((ss.falltp_times + 1) - Max(floor((Time() - ss.last_falltp) / 5), 0), 1)
			printl("after: " + ss.falltp_times)
			ss.last_falltp = Time()
			if (ss.falltp_times >= 7)
			{
				local jailEnt = Entities.FindByName(null, "jail_exit")
				ent.SetOrigin(jailEnt.GetOrigin())
				CenterPrint(ent, "You have been arrested for:\nFALLING TOO FREQUENTLY")
			}
		}
		else
		{
			ss.falltp_times <- 1
			ss.last_falltp <- Time()
		}
	}
}
