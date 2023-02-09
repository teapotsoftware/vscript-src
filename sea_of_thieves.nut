
IncludeScript("butil")

SendToConsoleServer("mp_autokick 0")
SendToConsoleServer("ammo_grenade_limit_default 3")
SendToConsoleServer("mp_respawn_on_death_t 1")
SendToConsoleServer("mp_respawn_on_death_ct 1")

::PLAYERMODEL_PREFIX <- "models/player/custom_player/legacy/"
::PLAYERMODEL_POSTFIX <- ".mdl"
::PLYMDL <- function(mdl) {return PLAYERMODEL_PREFIX + mdl + PLAYERMODEL_POSTFIX}

::TitleHint <- EntityGroup[0]
::VomitFade <- EntityGroup[1]
::KillMarker <- EntityGroup[2]

::Loadouts <- [
	{
		name = "Scout",
		models = ["tm_leet_varianti", "tm_professional_varg"],
		weps = ["knife_butterfly", "cz75a", "ssg08", "bumpmine"],
		speed = 3
	},
	{
		name = "Assault",
		models = ["tm_leet_variantb", "tm_professional_varh"],
		weps = ["bayonet", "p250", "ump45", "bumpmine"],
		speed = 2
	},
	{
		name = "Bomber",
		models = ["tm_leet_varianth", "tm_professional_vari"],
		weps = ["knife_survival_bowie", "deagle", "sawedoff", "breachcharge"],
		speed = 2
	},
	{
		name = "Watch",
		models = ["tm_leet_variantf", "tm_professional_varj"],
		weps = ["knife_m9_bayonet", "tec9", "xm1014", "tagrenade", "tagrenade", "tagrenade"],
		speed = 1
	}
]

::GiveLoadout <- function(ply, index)
{
	StripWeapons(ply)
	GiveWeapon(ply, "item_assaultsuit")
	foreach (wep in Loadouts[index].weps)
	{
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

::GiveCannonball <- function(ply)
{
	GiveWeapon(ply, "weapon_hegrenade")
}

::PlayVO <- function(ply, name)
{
	local player = Entities.FindByName(null, "voplayer_" + (ply.entindex() % 11))
	if (player != null)
	{
		player.__KeyValueFromString("message", "sea_of_thieves/actor/" + name + ".wav")
		player.SetOrigin(ply.EyePosition())
		EntFireHandle(player, "PlaySound")
	}
}

::Vomit <- function(ply)
{
	if (ply.GetHealth() <= 0)
	{
		return
	}
	PlayVO(ply, "vomit_" + RandomInt(1, 2))
	EntFireHandle(VomitFade, "Fade", "", 0, ply)
}

::Drink <- function(ply)
{
	if (ply.GetHealth() <= 0)
	{
		return
	}
	ply.SetHealth(Clamp(ply.GetHealth() + 15, 0, ply.GetMaxHealth()))
	if (RandomInt(1, 9999999999) % 6 == 0)
	{
		EntFireHandle(ply, "RunScriptCode", "Vomit(self)", RandomFloat(3, 7))
	}
}

::PlaceTitles <- [
	"Banana Isle",
	"Wreck of the Big Dinghy",
	"Dwayne",
	"Croissant Cove",
	"Bombsite Island",
	"Pokey Passage"
]

::ShowTitle <- function(ply, index)
{
	EntFireHandle(TitleHint, "addoutput", "message -= " + PlaceTitles[index] + " =-")
	EntFireHandle(TitleHint, "display", "", 0, ply)
}

::BulletImpact <- function(data)
{
	local charge = Entities.FindByClassnameNearest("breachcharge_projectile", Vector(data.x, data.y, data.z), 3)
	if (charge != null)
	{
		charge.Destroy()
	}
}

::UpdateHullHealth <- function(part)
{
	if (part == null || part.GetHealth() == 0)
	{
		return
	}
	local v = 255 * (part.GetHealth().tofloat() / part.GetMaxHealth())
	part.__KeyValueFromString("rendercolor", v + " " + v + " " + v)
}

OnPostSpawn <- function()
{
	// barrel init
	local ent = null
	while (ent = Entities.FindByName(ent, "barrel"))
	{
		if (ent.ValidateScriptScope())
		{
			ent.GetScriptScope().InputUse <- function()
			{
				GiveWeapon(activator, "weapon_healthshot")
				self.EmitSound("DogTags.PickupDeny")
			}
		}
	}
	HookToPlayerKill(function (ply) {
		EntFireHandle(KillMarker, "display", "", 0, ply)
	})
	HookToPlayerDeath(function(ply) {
		if (RandomInt(1, 100) > 60)
		{
			PlayVO(ply, "femboy_death_" + RandomInt(1, 9))
		}
	})
}
