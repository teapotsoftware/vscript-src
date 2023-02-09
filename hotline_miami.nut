
OnPostSpawn <- function() {
	ScriptPrintMessageChatAll("boop")
}

Think <- function() {
	EntFire("weapon_*", "SetReserveAmmoAmount", "0")
}
