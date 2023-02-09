
if (ScriptGetGameMode() != 1 || ScriptGetGameType() != 4) {
	SendToConsole("game_mode 1; game_type 4; changelevel " + GetMapName());
	return;
}

wave <- 0;

function SpawnFirstEnemies(amount) {
	ScriptCoopMissionSpawnFirstEnemies(amount);	
	ScriptCoopResetRoundStartTime();
	wave++;
}

function SpawnNextWave(amount) {
	ScriptCoopMissionSpawnNextWave(amount);
	wave++;
}

function OnMissionCompleted() {
	// What will happen once you've completed the mission (you could play a sound)
}

function OnRoundLostKilled() {
	// What will happen if you loose the round because you died (you could tell the players that your grandma is better than them)
}

function OnRoundLostTime() {
	// What will happen if you loose the round because the time runs out (you could tell the player that they are like turtles)
}

function OnRoundReset()  {
	// IMPORTANT: you need a game_coopmission_manager that has the output 'OnLevelReset' when this is called you NEED to call this function
	// in order for the level to work properly every round!
	// Will do this everytime you start the map/round because we call it in the OnLevelReset
	wave = 0;

	// Reset the difficulty to normal at start of the round
	SendToConsoleServer("mp_coopmission_bot_difficulty_offset 1");
	ScriptCoopSetBotQuotaAndRefreshSpawns(0);
}

function OnSpawnsReset() {
	// Called right before the round resets (usually used for correcting stuff when on a new round other stuff is immediately called)
	// enabled/disabled the correct spawns for the start. * means every group going from Terrorist_00 to infinite enemygroup_example
	EntFire("wave_*", "SetDisabled");
	EntFire("wave_1", "SetEnabled");
	EntFire("spawns_*", "SetDisabled");
	EntFire("spawns_1", "SetEnabled");
}

function OnWaveCompleted() {	
	EntFire("wave_*", "SetDisabled")
	EntFire("wave_" + (wave + 1), "SetEnabled")
}
