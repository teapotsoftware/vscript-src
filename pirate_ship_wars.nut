
IncludeScript("butil")

SendToConsoleServer("mp_autokick 0")
SendToConsoleServer("ammo_grenade_limit_default 3")
SendToConsoleServer("mp_respawn_on_death_t 1")
SendToConsoleServer("mp_respawn_on_death_ct 1")
SendToConsoleServer("mp_use_respawn_waves 1")
SendToConsoleServer("mp_shield_speed_holstered 250")
SendToConsoleServer("mp_shield_speed_deployed 200")
SendToConsoleServer("mp_roundtime 60")
SendToConsoleServer("mp_roundtime_defuse 60")
SendToConsoleServer("mp_roundtime_hostage 60")
SendToConsoleServer("mp_death_drop_gun 0")
SendToConsoleServer("sv_falldamage_scale 0")

::PLAYERMODEL_PREFIX <- "models/player/custom_player/legacy/"
::PLAYERMODEL_POSTFIX <- ".mdl"
::PLYMDL <- function(mdl) {return PLAYERMODEL_PREFIX + mdl + PLAYERMODEL_POSTFIX}

::TitleHint <- EntityGroup[0]
::VomitFade <- EntityGroup[1]
::KillMarker <- EntityGroup[2]

::Loadouts <- [
	{
		name = "Scout",
		models = ["tm_leet_variantg", "tm_professional_varg"],
		weps = ["knife_butterfly", "deagle", "ssg08", "bumpmine"],
		speed = 3
	},
	{
		name = "Bomber",
		models = ["tm_leet_variantb", "tm_professional_vari"],
		weps = ["knife_survival_bowie", "deagle", "xm1014", "breachcharge"],
		speed = 2
	},
	{
		name = "Captain",
		models = ["tm_jungle_raider_variantd", "tm_professional_varf3"],
		weps = ["knife_m9_bayonet", "deagle", "awp"],
		speed = 1
	}
]

::PickClass <- function(ply, index) {
	StripWeapons(ply)
	GiveWeapon(ply, "item_assaultsuit")
	foreach (wep in Loadouts[index].weps) {
		GiveWeapon(ply, "weapon_" + wep)
	}
	MeleeFixup()
	local speed = Loadouts[index].speed
	local health = 100 + ((4 - speed) * 25)
	ply.SetMaxHealth(health)
	ply.SetHealth(health)
	local finalSpeed = 1 + (speed - 2) * 0.2
	ModifySpeed(ply, finalSpeed)
	ply.__KeyValueFromFloat("gravity", 1 / finalSpeed)
	local mdl = PLYMDL(Loadouts[index].models[ply.GetTeam() - 2])
	ply.PrecacheModel(mdl)
	ply.SetModel(mdl)
}

::GiveCannonball <- function(ply) {
	GiveWeapon(ply, "weapon_hegrenade")
}

::PlayVO <- function(ply, i) {
	local player = Entities.FindByName(null, "voplayer_" + i)
	if (player != null) {
		player.SetOrigin(ply.EyePosition())
		EntFireHandle(player, "PlaySound")
	}
}

::Vomit <- function(ply) {
	if (ply.GetHealth() <= 0) {
		return
	}
	PlayVO(ply, RandomInt(0, 1))
	EntFireHandle(VomitFade, "Fade", "", 0, ply)
}

::Drink <- function(ply) {
	if (ply.GetHealth() <= 0) {
		return
	}
	ply.SetHealth(Clamp(ply.GetHealth() + 15, 0, ply.GetMaxHealth()))
	if (RandomInt(1, 999) % 6 == 0) {
		EntFireHandle(ply, "RunScriptCode", "Vomit(self)", RandomFloat(3, 7))
	}
}

::PlaceTitles <- [
	"Banana Isle",
	"Wreck of the Big Dinghy",
	"Dwayne",
	"Croissant Cove",
	"Bombsite Island",
	"Pokey Passage",
	"Wreck of the Poonwell"
]

::ShowTitle <- function(ply, index) {
	EntFireHandle(TitleHint, "addoutput", "message -= " + PlaceTitles[index] + " =-")
	EntFireHandle(TitleHint, "display", "", 0, ply)
}

::BulletImpact <- function(data) {
	local charge = Entities.FindByClassnameNearest("breachcharge_projectile", Vector(data.x, data.y, data.z), 3)
	if (charge != null) {
		charge.Destroy()
	}
}

::UpdateHullHealth <- function(part) {
	if (part == null || part.GetHealth() == 0) {
		return
	}
	local v = 255 * (part.GetHealth().tofloat() / part.GetMaxHealth())
	part.__KeyValueFromString("rendercolor", v + " " + v + " " + v)
}

OnPostSpawn <- function() {
	// barrel init
	local ent = null
	while (ent = Entities.FindByName(ent, "barrel")) {
		if (ent.ValidateScriptScope()) {
			ent.GetScriptScope().InputUse <- function() {
				GiveWeapon(activator, "weapon_healthshot")
				self.EmitSound("DogTags.PickupDeny")
			}
		}
	}
	HookToPlayerKill(function (ply) {
		EntFireHandle(KillMarker, "display", "", 0, ply)
	})
	HookToPlayerDeath(function(ply) {
		if (RandomInt(1, 100) > 60) {
			PlayVO(ply, RandomInt(2, 10))
		}
	})
}
