
SendToConsoleServer("mp_respawn_on_death_t 1")
SendToConsoleServer("mp_respawn_on_death_ct 1")
SendToConsoleServer("mp_taser_recharge_time 10")
SendToConsoleServer("mp_roundtime 9999999")
SendToConsoleServer("mp_anyone_can_pickup_c4 1")
SendToConsoleServer("mp_autokick 0")
SendToConsoleServer("mp_respawn_immunitytime 0.1")

::KeycardMaker <- EntityGroup[0]

::SCHEDULE_FREETIME <- 0
::SCHEDULE_LUNCHTIME <- 1
::SCHEDULE_YARDTIME <- 2
::SCHEDULE_CELLTIME <- 3

::SCHEDULE_CURRENT <- SCHEDULE_FREETIME

::UpdateSchedule <- function(time)
{
	SCHEDULE_CURRENT <- time

	ply <- null
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{		
		if (time == SCHEDULE_LUNCHTIME && ply.GetHealth() < 80 && !HasEscaped(ply))
		{
			CenterPrint(ply, "You are hurt. Head to the cafeteria to heal yourself.")
		}
	}
}

::P <- function(S)
{
	ScriptPrintMessageChatAll(S)
}

::DebugPrint <- function(S)
{
	if (GetDeveloperLevel() > 0)
	{
		P(S)
	}
}

::PRISON_SUPPLIER_DISABLED <- "Guards have disabled criminal supply lines. Criminals must re-open the supply lines before they can buy weapons."
::PRISON_SUPPLIER_ENABLED <- "Criminals have re-opened the supply lines and can once again buy weapons."
::PRISON_DOORS_DISABLED <- "Criminal hackers have disabled the prison doors temporarily."
::PRISON_DOORS_ENABLED <- "Prison doors have been re-enabled with auxiliary power."
::PRISON_LUNCH_TIME <- "Lunch has been served in the prison cafeteria. Attendance is mandatory."
::PRISON_LUNCH_OVER <- "Lunch is no longer being served."
::PRISON_YARD_OPEN <- "The yard is now open."
::PRISON_YARD_CLOSING <- "The yard will be closing shortly, all prisoners head back inside."
::PRISON_YARD_CLOSED <- "The yard is now closed. All prisoners remaining in the yard are now Kill-On-Sight."
::PRISON_YARD_OVERRIDE <- "The yard door has been manually overridden."
::PRISON_C4_PLANTED <- "Criminals have planted C4 on the main prison door. Stand back!"
::PRISON_WARHEAD_ARMED <- "!!!!!! WARHEAD ARMED !!!!!!"

::GetPlayerFromUserID <- function(id)
{
	found <- null
	while ((found = Entities.FindByClassname(found, "player")) != null)
	{
		if (found.ValidateScriptScope())
		{
			local scope = found.GetScriptScope()
			if ("userid" in scope && scope.userid == id)
			{
				return found
			}
		}		
	}
	return null
}

::ToggleIntercom <- function(on)
{
	if (on)
	{
		P("=== INTERCOM ENABLED ===")
		SendToConsoleServer("sv_talk_enemy_living 1")
		SendToConsoleServer("sv_talk_enemy_dead 1")
	}
	else
	{
		P("=== INTERCOM DISABLED ===")
		SendToConsoleServer("sv_talk_enemy_living 0")
		SendToConsoleServer("sv_talk_enemy_dead 0")
	}
}

::env_hudhint <- Entities.CreateByClassname("env_hudhint")

::CenterPrint <- function(ply, text)
{
	env_hudhint.__KeyValueFromString("message", text)
	EntFireByHandle(env_hudhint, "ShowHudHint", "", 0.0, ply, null)
}

::CenterPrintRed <- function(ply, text)
{
	CenterPrint(ply, "<font color=red>" + text + "</font>")
}

::player_speedmod <- Entities.CreateByClassname("player_speedmod")

::ModifySpeed <- function(ply, speed, delay = 0)
{
	DoEntFire("!self", "ModifySpeed", speed.tostring(), delay, ply, player_speedmod);
}

::SnortCocaine <- function(ply)
{
	CenterPrint(ply, "You snorted cocaine.")
	ModifySpeed(ply, 1.5)
	ModifySpeed(ply, 1, 40)
}

//KeycardPickup <- function()
//{
//	P("try pickup keycard")
//	if (activator.GetName() == "keycard_holder")
//	{
//		P("already has keycard")
//	}
//	else
//	{
//		P("picked up")
//		activator.SetName("keycard_holder")
//		P(self.GetModelName())
//		self.Destroy()
//	}
//}

::GetUserID <- function(ply)
{
	if (ply.ValidateScriptScope())
	{
		local scope = ply.GetScriptScope()
		return scope.userid
	}
	return -1
}

::HasKeycard <- function(ply)
{
	return ply.GetName() == "keycard_holder"
}

::GiveKeycard <- function(ply)
{
	if (!HasKeycard(ply))
	{
		ply.__KeyValueFromString("targetname", "keycard_holder")
		CenterPrint(ply, "You picked up a keycard.")
		return true
	}
	else
	{
		return false
	}
	
}

::queued_player <- null

::GetWeapons <- function(ply)
{
	local weapon = null
	local weaponlist = {}
	local i = 0
	while((weapon = Entities.FindByClassname(weapon, "weapon_*")) != null)
	{
		if (weapon.GetOwner() == ply)
		{
			weaponlist[i] <- weapon
			i++
		}
	}
	return weaponlist
}

::ReadScopeBool <- function(handle, index)
{
	if (handle.ValidateScriptScope())
	{
		local scope = handle.GetScriptScope()
		return (index in scope && scope[index])
	}
}

::WriteScope <- function(handle, index, value)
{
	if (handle.ValidateScriptScope())
	{
		local scope = handle.GetScriptScope()
		scope[index] <- value
	}
}

function Think()
{
	local weapon = null
	while ((weapon = Entities.FindByClassname(weapon, "weapon_*")) != null)
	{
		local ply = weapon.GetOwner()
		if (ply != null && ply.GetTeam() == 2 && weapon.GetClassname() != "weapon_c4" && ply.ValidateScriptScope() && !IsArmed(ply))
		{
			local scope = ply.GetScriptScope()
			if (!("criminal_immunity" in scope) || scope.criminal_immunity < Time())
			{
				if (!IsCriminal(ply))
				{
					CenterPrint(ply, "You are wanted for holding contraband!")
				}
				printl(ply.GetClassname() + " owns a " + weapon.GetClassname())
				scope.is_armed <- true
			}
		}
	}
	local test = Entities.FindByClassname(null, "player")
	//printl(ReadScopeBool(test, "is_armed") + " - " + ReadScopeBool(test, "has_escaped"))
}

::EscapePrison <- function(ply)
{
	local s = ply.GetScriptScope()
	if (ply.ValidateScriptScope())
	{
		if (!IsCriminal(ply))
		{
			CenterPrint(ply, "You are wanted for escaping prison!")
		}
		local scope = ply.GetScriptScope()
		scope.has_escaped <- true
	}
}

::IsArmed <- function(ply)
{
	return ply.GetTeam() == 2 && ReadScopeBool(ply, "is_armed")
}

::HasEscaped <- function(ply)
{
	return ply.GetTeam() == 2 && ReadScopeBool(ply, "has_escaped")
}

::IsCriminal <- function(ply)
{
	return HasEscaped(ply) || IsArmed(ply)
}

::OnPlayerDeath <- function(attacker, victim)
{
	victim.__KeyValueFromString("targetname", "") // clear keycard
	if (victim.GetTeam() == 3)
	{
		if (rand() % 3 == 0 && !HasKeycard(attacker))
		{
			KeycardMaker.SpawnEntityAtLocation(victim.GetOrigin() - Vector(0, 0, 64), Vector(0, 0, 0))
			//GiveKeycard(attacker) // nope
			//P("droping keycard")
			//local keycard = Entities.CreateByClassname("prop_Physics_override")
			//keycard.__KeyValueFromInt("spawnflags", 256)
			//keycard.SetModel("models/props_downtown/keycard_reader.mdl")
			//keycard.SetAngles(-90, 0, 0)
			//keycard.SetOrigin(victim.GetOrigin() - Vector(0, 0, 64))
			//EntFireByHandle(keycard, "wake", "", 0, null, null)
			//P(keycard.GetOrigin().ToKVString())
			//if (keycard.ValidateScriptScope())
			//{
			//	local scope = keycard.GetScriptScope()
			//	scope.InputUse <- function()
			//	{
			//		P("try pickup keycard")
			//		if (activator.GetName() == "keycard_holder")
			//		{
			//			P("already has keycard")
			//		}
			//		else
			//		{
			//			P("picked up")
			//			activator.SetName("keycard_holder")
			//			P(self.GetModelName())
			//			self.Destroy()
			//		}
			//	}
			//}
		}
	}
	else if (victim.GetTeam() == 2 && attacker.GetTeam() == 3 && !IsCriminal(victim))
	{
		if (attacker.ValidateScriptScope())
		{
			local scope = attacker.GetScriptScope()
			if ("killed_innocents" in scope)
			{
				scope.killed_innocents++
			}
			else
			{
				scope.killed_innocents <- 1
			}
			CenterPrint(attacker, "DO NOT KILL INNOCENTS - WARNING " + scope.killed_innocents + " OF 3")
			if (scope.killed_innocents >= 3)
			{
				scope.killed_innocents = 0
				attacker.SetTeam(2)
				//attacker.SetHealth(0)
			}
		}
		else
		{
			CenterPrint(attacker, "DO NOT KILL INNOCENTS - WARNING")
		}
	}

	if (victim.ValidateScriptScope())
	{
		printl("t")
		local scope = victim.GetScriptScope()
		if (IsCriminal(victim))
		{
			CenterPrint(victim, "You are no longer wanted.")
			scope.is_armed <- false
			scope.has_escaped <- false
			scope.criminal_immunity <- Time() + 2
		}
	}
}

::event_attacker <- null
::event_victim <- null

::player_kill <- Entities.CreateByClassname("trigger_brush")
EntFireByHandle(player_kill, "addoutput", "targetname game_playerkill", 0.0, null, null)
::player_kill.ValidateScriptScope()

local scope = ::player_kill.GetScriptScope()

scope.OnUse <- function()
{
	::event_attacker = activator

	//if (event_victim != null && event_attacker != null)
	//{
	//	::OnPlayerDeath(event_attacker, event_victim)
	//	event_attacker = null
	//	event_victim = null
	//}
}

::player_kill.ConnectOutput("OnUse", "OnUse")

::player_die <- Entities.CreateByClassname("trigger_brush")
EntFireByHandle(player_die, "addoutput", "targetname game_playerdie", 0.0, null, null)
::player_die.ValidateScriptScope()

local scope = ::player_die.GetScriptScope()

scope.OnUse <- function()
{
	::event_victim = activator
	::queued_player = activator
	if (event_victim != null && event_attacker != null)
	{
		::OnPlayerDeath(event_attacker, event_victim)
		event_attacker = null
		event_victim = null
	}
}

::player_die.ConnectOutput("OnUse", "OnUse")



::PrintTable <- function(table,tablename="",spaces=0){
local spaces_string=""
for (local i=0;i<spaces;i++){
	spaces_string+=" "
}
printl(spaces_string+(tablename!=""&&tablename+"  <-  "||"")+(typeof(table)=="table"&&"{"||"["))
local nokey=false
if (typeof(table)=="array"){
nokey=true
}
spaces_string+="  "
foreach(key,value in table){
if (typeof(value)=="table"||typeof(value)=="array"){
VUtil.Debug.PrintTable(value,(nokey&&""||key),spaces+4)
} else if (typeof(value)=="string"){
local double_quote=@""""
printl(spaces_string+(nokey&&""||key.tostring()+"  <-  ")+double_quote+value.tostring()+double_quote+",")
} else {
printl(spaces_string+(nokey&&""||key.tostring()+"  <-  ")+value.tostring()+",")
}
}
local spaces_string=""
for (local i=0;i<spaces;i++){
	spaces_string+=" "
}
printl(spaces_string+(typeof(table)=="table"&&"}"||"]")+(spaces!=0&&","||""))
}
