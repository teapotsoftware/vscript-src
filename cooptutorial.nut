wave <- 0;

function RoundInit(){
	//Will do this everytime you start the map/round because we call it in the OnLevelReset
	wave = 0;
	//Reset the difficulty to normal at start of the round
	SendToConsoleServer( "mp_coopmission_bot_difficulty_offset 1" );
	ScriptCoopSetBotQuotaAndRefreshSpawns( 0 );
}

function ChangeGameModeToCoopIfNotCorrect()
{
	// This will change the game mode and game type if the player has not initialized this before starting the map.
    local game_mode = ScriptGetGameMode();
    local game_type = ScriptGetGameType();
    local map = GetMapName();

	if (game_mode != 1 || game_type != 4)
	{
		SendToConsole("game_mode 1; game_type 4; changelevel " + map);
	}
}

function SpawnFirstEnemies( amount )
{
	ScriptCoopMissionSpawnFirstEnemies( amount );	
	ScriptCoopResetRoundStartTime();
	wave++;
}

function SpawnNextWave( amount ){
	ScriptCoopMissionSpawnNextWave( amount );
	wave++;
}

function OnMissionCompleted()
{
	//what will happen once you've completed the mission (you could play a sound)
	
}

function OnRoundLostKilled()
{
	//what will happen if you loose the round because you died (you could tell the players that your grandma is better than them)
	
}

function OnRoundLostTime()
{
	//what will happen if you loose the round because the time runs out (you could tell the player that they are like turtles)
	
}

function OnRoundReset() 
{
	//called when the round resets
	// IMPORTANT: you need a game_coopmission_manager that has the output 'OnLevelReset' when this is called you NEED to call this function
	// in order for the level to work properly every round!
	RoundInit();
}

function OnSpawnsReset()
{
	//called right before the round resets (usually used for correcting stuff when on a new round other stuff is immediately called)
	//enabled/disabled the correct spawns for the start. * means every group going from Terrorist_00 to infinite enemygroup_example
	EntFire( "wave_*", "SetDisabled", "", 0 );
	EntFire( "wave_01", "SetEnabled", "", 0 );
	EntFire( "CT_*", "SetDisabled", "", 0 );
	EntFire( "CT_1", "SetEnabled", "", 0 );
}

function OnWaveCompleted()
{	
	//Check which wave the player is and do stuff
	if ( wave == 1 )
	{
		EntFire( "wave_*", "SetDisabled", "", 0 );
		EntFire( "wave_02", "SetEnabled", "", 0 );
		EntFire( "door_wave_01", "Unlock", "", 1 );
		EntFire( "door_wave_01", "SetGlowEnabled", "", 1 );
	}
	else if ( wave == 2 )
	{
		EntFire( "wave_*", "SetDisabled", "", 0 );
		EntFire( "wave_03", "SetEnabled", "", 0 );
		EntFire( "door_wave_02", "Unlock", "", 1 );
		EntFire( "door_wave_02", "SetGlowEnabled", "", 1 );
	}
	else if ( wave == 3 )
	{
		EntFire( "door_wave_03", "Unlock", "", 1 );
		EntFire( "door_wave_03", "SetGlowEnabled", "", 1 );
	}
}