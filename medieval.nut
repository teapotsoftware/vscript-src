
::T <- 2
::CT <- 3

::LastGivenWep <- {}

::GiveWeapon <- function(ply, weapon, ammo = 0)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, weapon == "weapon_snowball" ? 4 : ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	equip.Destroy()
	LastGivenWep[ply.entindex()] <- Time()
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireByHandle(strip, "Strip", "", 0.0, ply, null)
	strip.Destroy()
}

MedievalWeapons <- [
	"weapon_knife_push",
	"weapon_knife_karambit",
	"weapon_knife_css",
	"weapon_bayonet",
	"weapon_knife_stiletto",
	"weapon_knife_butterfly",
	"weapon_knife_m9_bayonet",
	"weapon_knife_outdoor",
	"weapon_knife_survival_bowie",
];

MedievalEquipment <- [
	"weapon_hegrenade",
	"weapon_molotov",
	"weapon_snowball",
];

OnPostSpawn <- function()
{
	SendToConsoleServer("mp_respawn_on_death_t 1")
	SendToConsoleServer("mp_respawn_on_death_ct 1")
	SendToConsoleServer("mp_autokick 0")
	SendToConsoleServer("mp_c4timer 120")
	SendToConsoleServer("sv_falldamage_scale 0")
/*
	ply <- null
	while ((ply = Entities.FindByClassname(ply, "*")) != null)
	{
		if (ply.GetClassname() == "player" || ply.GetClassname() == "bot")
		{
			StripWeapons(ply)
			GiveWeapon(ply, MedievalWeapons[RandomInt(1, MedievalWeapons.len()) - 1])
			GiveWeapon(ply, MedievalEquipment[RandomInt(1, MedievalEquipment.len()) - 1])
		}
	}

	/*
	foreach (wep in MedievalWeapons)
	{
		ScriptPrintMessageChatAll(wep)
		EntFire(wep, "addoutput", "classname weapon_knifegg")
	}
	*/

	ScriptPrintMessageChatTeam(T, "INVADERS")
	ScriptPrintMessageChatTeam(T, "Lay siege to the castle and slaughter the defenders.")
	ScriptPrintMessageChatTeam(T, "Catapult yourself into the castle swimming pool.")
	ScriptPrintMessageChatTeam(T, "Raise the flag to open the gate and gain forward spawns.")

	ScriptPrintMessageChatTeam(CT, "DEFENDERS")
	ScriptPrintMessageChatTeam(CT, "Hold off the invaders for as long as possible.")
	ScriptPrintMessageChatTeam(CT, "Beware of invaders catapulting themselves into the castle.")
	ScriptPrintMessageChatTeam(CT, "Stop the flag from being raised to stop the gate from being opened.")

	PlayerSpawned()
}

::OpenGate <- function()
{
	EntFire("bagpipes", "playsound")
	EntFire("castle_door", "open")
	ScriptPrintMessageChatAll("The castle gates have opened!")
}

HasWeapons <- function(ply)
{
	if ((ply.entindex() in LastGivenWep) && (Time() - LastGivenWep[ply.entindex()] < 0.1))
	{
		return true
	}
	wep <- null
	while ((wep = Entities.FindByClassname(wep, "weapon_*")) != null)
	{
		if (wep.GetClassname() != "weapon_c4")
		{
			if (wep.GetOwner() == ply)
			{
				return true
			}
			else if (wep.GetOwner() == null && wep.GetClassname() != "weapon_cz75a")
			{
				// do some cleanup while we're here
				wep.Destroy()
			}
		}
		
	}
	return false
}

::PlayerSpawned <- function()
{
	ply <- null
	while ((ply = Entities.FindByClassname(ply, "*")) != null)
	{
		if (ply.IsValid() && (ply.GetClassname() == "player" || ply.GetClassname() == "bot") && !HasWeapons(ply) && ply.GetHealth() > 0)
		{
			GiveWeapon(ply, MedievalWeapons[RandomInt(1, MedievalWeapons.len()) - 1])
			GiveWeapon(ply, "weapon_flashbang")
			EntFire("weapon_knife", "addoutput", "classname weapon_knifegg")
		}
	}
}

// really damn messy, hate this code lol

::FlagCaptured <- false
::CaptureProgress <- 0

Flag <- EntityGroup[0]
FlagBottom <- EntityGroup[1].GetOrigin()
FlagTop <- EntityGroup[2].GetOrigin()
FlagPos <- Flag.GetOrigin()
MaxCap <- 50

ThinkDelay <- 0

Think <- function()
{
	local curpos = Flag.GetOrigin()
	Flag.SetOrigin(Vector(FlagBottom.x, FlagBottom.y, curpos.z + ((FlagPos.z - curpos.z) * (FrameTime() * 8))))

	ThinkDelay = (ThinkDelay + 1) % 5
	if (ThinkDelay || FlagCaptured)
	{
		return
	}

	capmod <- -1
	ply <- null
	while ((ply = Entities.FindByClassnameWithin(ply, "player", FlagTop, 120)) != null)
	{
		if (ply.GetTeam() == T)
		{
			capmod <- 1
			break
		}
	}

	CaptureProgress += capmod

	if (CaptureProgress < 0)
	{
		CaptureProgress = 0
	}

	if (CaptureProgress >= MaxCap && !FlagCaptured)
	{
		FlagCaptured = true
		EntFire("back_spawns", "SetDisabled")
		EntFire("forward_spawns", "SetEnabled")
		ScriptPrintMessageChatAll("FLAG RAISED")
		OpenGate()
		ScriptPrintMessageChatAll("Attackers now have forward spawns!")
	}

	FlagPos <- FlagBottom + Vector(0, 0, (CaptureProgress.tofloat() / MaxCap) * 144)
}

BombPlanted <- function()
{
	if (!FlagCaptured)
	{
		OpenGate()
	}
	ScriptPrintMessageChatTeam(T, "Protect the bomb at all costs!")
	ScriptPrintMessageChatTeam(CT, "Protect your castle, defuse that bomb!")
}

::GiveGrenade <- function(ply)
{
	GiveWeapon(ply, "weapon_hegrenade")
}

::GiveCZ <- function(ply)
{
	GiveWeapon(ply, "weapon_cz75a")
}
