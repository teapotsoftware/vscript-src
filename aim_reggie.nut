/****************************************************/
/*                    AIM_REGGIE                    */
/*             Map and script by Reggie.            */
/*    https://steamcommunity.com/id/ReggieMouse     */
/****************************************************/

/***********************************/
/*         One-Time Setup          */
/*  Runs once on the first round,  */
/*  but never again. Used to set   */
/*  up some global variables.      */
/***********************************/

if ( ! ( "_setup" in getroottable( ) ) )
{
	// alternate ent fire function with default arguments
	::EntFire2 <- function( a, b, c = "", d = 0.0, e = null, f = null ) EntFireByHandle( a, b, c, d, e, f )

	// weapon class shortcuts
	::kev <- "item_kevlar"
	::helm <- "item_assaultsuit"
	::karam <- "weapon_knife_karambit"
	::bfly <- "weapon_knife_butterfly"
	::bayo <- "weapon_bayonet"
	::m9 <- "weapon_knife_m9_bayonet"
	::usp <- "weapon_usp_silencer"
	::glk <- "weapon_glock"

	// game_player_equip spawnflags
	::GPE_FL_USEONLY <- 1
	::GPE_FL_STRIPALL <- 2
	::GPE_FL_STRIPSAME <- 4

	// default loadouts
	// format: [ < name >, < weight >, < weapons >, [ no awp pickups? = false ] ]
	::Loadouts <- [
		[ "AK-47", 4, [ helm, "weapon_ak47", glk, m9 ] ],
		[ "M4A4", 2, [ helm, "weapon_m4a1", usp, bayo ] ],
		[ "M4A1-S", 2, [ helm, "weapon_m4a1_silencer", usp, bayo ] ],
		[ "AWP", 2, [ helm, "weapon_awp", "weapon_p250", karam ] ],
		[ "Deagle", 1, [ helm, "weapon_deagle", karam ], true ],
		[ "USP-S", 1, [ usp, bayo ], true ],
		[ "Glock", 1, [ glk, m9 ], true ]
	]

	// le epic funny
	::FunnyLoadouts <- [
		[ "Bizon", 1, [ helm, "weapon_bizon", bfly ] ],
		[ "CZ75", 1, [ helm, "weapon_cz75a", karam ] ],
		[ "Scout", 1, [ helm, "weapon_ssg08", bfly ] ],
		[ "R8", 1, [ helm, "weapon_revolver", bayo ] ],
		[ "Negev", 1, [ helm, "weapon_negev", m9 ] ],
		[ "XM1014", 1, [ helm, "weapon_xm1014", bfly ] ],
		[ "Scar-20", 1, [ helm, "weapon_scar20", m9 ] ]
	]

	//    C L A S S - B A S E D   G A M E P L A Y
	::ClassLoadouts <- [
		[ "AK-47 + Frag", "255 100 100", [ helm, "weapon_ak47", "weapon_glock", m9, "weapon_hegrenade" ] ],
		[ "Negev + Molotov", "100 100 255", [ helm, "weapon_negev", "weapon_cz75a", bayo, "weapon_molotov" ] ],
		[ "AWP + Flash", "100 255 100", [ helm, "weapon_awp", "weapon_deagle", karam, "weapon_flashbang" ] ],
		[ "M4A1-S + Smoke", "255 100 255", [ helm, "weapon_m4a1_silencer", "weapon_usp_silencer", bfly, "weapon_smokegrenade" ] ]
	]

	// funny is off by default
	::USE_FUNNY_LOADOUTS <- false

	// nades to give randomly
	::NadeList <- [
		[ "weapon_flashbang", "Flash" ],
		[ "weapon_hegrenade", "Frag" ],
		[ "weapon_smokegrenade", "Smoke" ],
		[ "weapon_molotov", "Molotov" ]
	]

	// game modes
	::MODE_NONE <- 0
	::MODE_STANDARD <- 1
	::MODE_DEATHMATCH <- 2
	::CurrentMode <- MODE_NONE

	// mark setup as done
	::_setup <- "map by reggie :P"
}

/************************************/
/*         GiveClassLoadout         */
/*      ( player, int => void )     */
/*  Gives the specified player the  */
/*  Class Loadout of index "id"     */
/************************************/

::GiveClassLoadout <- function( ply, id )
{
	EntFire2( ClassEquips[ id ], "Use", "", 0, ply )
	local data = ClassLoadouts[ id ]

	// set hint text
	EntFire2( GunHint, "SetText", data[ 0 ] )

	// set hint color
	local clr = data[ 1 ]
	EntFire2( GunHint, "SetTextColor", clr )
	EntFire2( GunHint, "SetTextColor2", clr )

	// show me what u got *kerplop*
	EntFire2( GunHint, "Display" )

	// fix special knives
	EntFire( "weapon_knife", "AddOutput", "classname weapon_knifegg" )
	EntFire( "weapon_knife", "AddOutput", "classname weapon_knifegg", 0.2 )
}

/*************************************************/
/*                  OnPostSpawn                  */
/*                ( void => void )               */
/*  Runs every time the round starts.            */
/*                                               */
/*  In standard mode ( Casual / Competitive ):   */
/*  Gives all players randomly chosen weapons,   */
/*	plus a random grenade 50% of the time.       */
/*                                               */
/*  In deathmatch mode ( Custom ):               */
/*  Sets up game_player_equips for loadouts and  */
/*  enables spawn doors.                         */
/*************************************************/

OnPostSpawn <- function( )
{
	SendToConsole( "mp_solid_teammates 2" )
	SendToConsole( "mp_use_respawn_waves 1" )
	SendToConsole( "mp_respawnwavetime_ct 7.0" )
	SendToConsole( "mp_respawnwavetime_t 7.0" )

	// save game mode and type ids
	::game_mode <- ScriptGetGameMode( )
	::game_type <- ScriptGetGameType( )
	::is_warmup <- ScriptIsWarmupPeriod( )

	// game_text setup
	if ( ! ( "GunHint" in getroottable( ) && GunHint.IsValid( ) ) )
	{
		::GunHint <- Entities.CreateByClassname( "game_text" )
		GunHint.__KeyValueFromFloat( "fadein", 0.4 )
		GunHint.__KeyValueFromFloat( "fadeout", 0.4 )
		GunHint.__KeyValueFromFloat( "y", 0.7 )
		GunHint.__KeyValueFromInt( "x", -1 )
		GunHint.__KeyValueFromInt( "channel", 1 )
		GunHint.__KeyValueFromInt( "holdtime", 2 )
		GunHint.__KeyValueFromInt( "effect", 0 )
	}

	// "classic" mode, give random loadouts on round start
	if ( game_type == 0 && !is_warmup )
	{
		SendToConsole( "mp_death_drop_gun 1" )
		SendToConsole( "mp_drop_grenade_enable 1" )
		SendToConsole( "mp_respawn_on_death_ct 0" )
		SendToConsole( "mp_respawn_on_death_t 0" )

		local gpes = Loadouts
		local lastDefaultLoadout = gpes.len( ) - 1

		// add funny loadouts if we're using them
		if ( USE_FUNNY_LOADOUTS ) gpes.extend( FunnyLoadouts )

		// thicc weighted array
		local n = [ ]
		for ( local i = 0; i < gpes.len( ); i++ )
		{
			for ( local j = 0; j < gpes[ i ][ 1 ]; j++ )
			{
				n.push( i )
			}
		}

		// select loadout
		local loadouti = n[ RandomInt( 0, 99999 ) % n.len( ) ]
		local loadout = gpes[ loadouti ]
		local equip = Entities.CreateByClassname( "game_player_equip" )
		equip.__KeyValueFromInt( "spawnflags", GPE_FL_STRIPALL )
		foreach ( wep in loadout[ 2 ] ) equip.__KeyValueFromInt( wep, 99999 )

		// random grenadey half the time
		local nade = -1
		if ( RandomInt( 0, 99999 ) % 2 == 0 )
		{
			nade = RandomInt( 0, 99999 ) % NadeList.len( )
			equip.__KeyValueFromInt( NadeList[ nade ][ 0 ], 1 )
		}

		// give selected loadout + nade
		EntFire2( equip, "TriggerForAllPlayers" )

		// some loaoduts don't have awp pickups
		if ( loadout.len( ) > 3 && loadout[ 3 ] ) EntFire( "bonus_avp", "Kill" )

		// fix special knives
		EntFire( "weapon_knife", "AddOutput", "classname weapon_knifegg" )
		EntFire( "weapon_knife", "AddOutput", "classname weapon_knifegg", 0.2 )

		// make sure the hints are sent to all players
		GunHint.__KeyValueFromInt( "spawnflags", 1 )

		// set hint text
		EntFire2( GunHint, "SetText", loadout[ 0 ] + ( nade == -1 ? "" : " + " + NadeList[ nade ][ 1 ] ) )

		// set hint color
		local clr = loadouti > lastDefaultLoadout ? "0 255 150" : "255 255 255"
		EntFire2( GunHint, "SetTextColor", clr )
		EntFire2( GunHint, "SetTextColor2", clr )

		// show me what u got *kerplop*
		EntFire2( GunHint, "Display" )

		// restart if mode just changed
		if ( CurrentMode != MODE_STANDARD && CurrentMode != MODE_NONE )
		{
			SendToConsole( "mp_restartgame 1" )
		}
		::CurrentMode = MODE_STANDARD
	}

	// "custom" mode, enable   c l a s s - b a s e d   g a m e p l a y
	if ( game_type == 3 || is_warmup )
	{
		SendToConsole( "mp_death_drop_gun 0" )
		SendToConsole( "mp_drop_grenade_enable 0" )
		SendToConsole( "mp_respawn_on_death_ct 1" )
		SendToConsole( "mp_respawn_on_death_t 1" )

		// enable spawn rooms
		EntFire( "spawns_default", "SetDisabled" )
		EntFire( "spawns_custom", "SetEnabled" )
		EntFire( "spawnroom_deco", "Enable" )
		EntFire( "spawnroom_deco", "LightOn" )
		EntFire( "spawnroom_blockers", "Disable" )

		// no avp for u
		EntFire( "bonus_avp", "Kill" )

		// create game_player_equip for each class
		::ClassEquips <- [ ]

		foreach ( loadout in ClassLoadouts )
		{
			local equip = Entities.CreateByClassname( "game_player_equip" )
			equip.__KeyValueFromInt( "spawnflags", GPE_FL_USEONLY + GPE_FL_STRIPALL )
			foreach ( wep in loadout[ 2 ] ) equip.__KeyValueFromInt( wep, 99999 )
			ClassEquips.push( equip )
		}

		// make sure the hints are sent to only receiving player
		GunHint.__KeyValueFromInt( "spawnflags", 0 )

		// restart if mode just changed
		if ( CurrentMode != MODE_DEATHMATCH && CurrentMode != MODE_NONE )
		{
			SendToConsole( "mp_restartgame 1" )
		}
		::CurrentMode = MODE_DEATHMATCH
	}
	else
	{
		// hide spawn rooms if we're not using them
		EntFire( "spawns_default", "SetEnabled" )
		EntFire( "spawns_custom", "SetDisabled" )
		EntFire( "spawnroom_deco", "Disable" )
		EntFire( "spawnroom_deco", "LightOff" )
		EntFire( "spawnroom_blockers", "Enable" )
		EntFire( "spawndoor_pnk", "Kill" )
		EntFire( "spawndoor_cyn", "Kill" )
	}
}

// shhh don't look down here
// see --> wytidiymirmgzxe

::SECRET_COUNT <- 0

::WallButton <- function( b )
{
	if ( b )
	{
		::SECRET_COUNT++

		if ( SECRET_COUNT == 6 )
		{
			EntFire( "box_doors", "Open" )
			EntFire( "box_kill", "Disable" )
		}
	}
	else
	{
		::SECRET_COUNT--
	}
}
