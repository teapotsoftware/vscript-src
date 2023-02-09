
IncludeScript("butil")

SendToConsoleServer("mp_respawn_on_death_t 1")
SendToConsoleServer("mp_respawn_on_death_ct 1")
SendToConsoleServer("mp_taser_recharge_time 10")
SendToConsoleServer("mp_roundtime 9999999")
SendToConsoleServer("mp_anyone_can_pickup_c4 1")
SendToConsoleServer("mp_autokick 0")
SendToConsoleServer("mp_respawn_immunitytime 0.1")

::SCHEDULE_FREETIME <- 0
::SCHEDULE_LUNCHTIME <- 1
::SCHEDULE_YARDTIME <- 2
::SCHEDULE_CELLTIME <- 3

::SCHEDULE_CURRENT <- SCHEDULE_FREETIME

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

::P <- ChatPrintAll

::UpdateSchedule <- function(time) {
	SCHEDULE_CURRENT <- time

	ply <- null
	while ((ply = Entities.FindByClassname(ply, "player")) != null) {		
		if (time == SCHEDULE_LUNCHTIME && ply.GetHealth() < 80 && !HasEscaped(ply)) {
			CenterPrint(ply, "You are hurt. Head to the cafeteria to heal yourself.")
		}
	}
}

::ToggleIntercom <- function(on) {
	if (on) {
		P("=== INTERCOM ENABLED ===")
		SendToConsoleServer("sv_talk_enemy_living 1")
		SendToConsoleServer("sv_talk_enemy_dead 1")
	} else {
		P("=== INTERCOM DISABLED ===")
		SendToConsoleServer("sv_talk_enemy_living 0")
		SendToConsoleServer("sv_talk_enemy_dead 0")
	}
}

::HasKeycard <- function(ply) {
	return ply.GetName() == "keycard_holder"
}

::GiveKeycard <- function(ply) {
	if (!HasKeycard(ply)) {
		ply.__KeyValueFromString("targetname", "keycard_holder")
		CenterPrint(ply, "You picked up a keycard.")
		return true
	}
	return false
}

::SnortCocaine <- function(ply) {
	EntFire("coke_sound", "PlaySound")
	EntFire("hideout_cokespawner", "ForceSpawn", "", 60)
	ModifySpeed(ply, 1.5)
	ModifySpeed(ply, 1, 40)
}
