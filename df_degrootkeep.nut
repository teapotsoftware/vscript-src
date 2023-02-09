
::TerriblePerson <- function()
{
	ScriptPrintMessageChatAll(" \x2You are a terrible person.")
}

::MinikitParticles <- function(pos)
{
	DispatchParticleEffect("firework_crate_explosion_01", pos, pos)
}

::RADIO_SONG <- 0

::CycleRadio <- function()
{
	::RADIO_SONG <- (RADIO_SONG + 1) % 10
	EntFire("radio_song_" + RADIO_SONG, "volume", "10")
}
