
IncludeScript("butil")

::ReadyBots <- []

::BotSpawn <- function(bot) {
	printl(bot + " ready")
	ReadyBots.push(bot)
}

::PlaceSpawn <- function() {
	printl()
}

::NewEnemyType <- function(model = "models/player/custom_player/legacy/tm_phoenix.mdl", health = 100, loadout = ["weapon_glock"], speed = 1.0) {
	local enemy = {}
	enemy.model <- model
	enemy.health <- health
	enemy.loadout <- loadout
	enemy.speed <- speed
	return enemy
}

::ENEMY_GRUNT1 <- NewEnemyType()
::ENEMY_PRISONGUARD_TASER <- NewEnemyType("models/player/custom_player/legacy/ctm_swat.mdl", 100, ["item_assaultsuit", "weapon_knife", "weapon_taser"])
::ENEMY_PRISONER1 <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_varianta.mdl")
::ENEMY_PRISONER2 <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_variantb.mdl")
::ENEMY_PRISONER3 <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_variantc.mdl")
::ENEMY_PRISONER_ARMED1 <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_varianta.mdl", 100, ["weapon_glock"])
::ENEMY_PRISONER_ARMED2 <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_variantb.mdl", 100, ["weapon_nova"])
::ENEMY_PRISONER_ARMED3 <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_variantc.mdl", 100, ["weapon_m4a1"])
::ENEMY_PRISONER_PSYCHWARD1 <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_variantc.mdl", 300, ["weapon_knife"], 1.2)
::ENEMY_PRISONER_OUTSIDE <- NewEnemyType("models/player/custom_player/legacy/tm_jumpsuit_variantc.mdl", 100, ["weapon_knife"], 1.1)

::SpawnEnemy <- function(enemy, pos) {
	local bot = ReadyBots.pop()
	SetModelSafe(bot, enemy.model)
	GiveLoadout(bot, enemy.loadout)
	SetHealthAndMaxHealth(bot, enemy.health)
	ModifySpeed(bot, enemy.speed)
	bot.SetOrigin(pos)
}

::WAVE_PRISON_1 <- [
	[ENEMY_PRISONER2, Vector(-9241, -3664, 1)],
	[ENEMY_PRISONER3, Vector(-9325, -4114, 1)],
	[ENEMY_PSYCHWARD1, Vector(-9735, -3832, 1)],
	[ENEMY_PSYCHWARD1, Vector(-9472, -4090, 1)],
	[ENEMY_PSYCHWARD1, Vector(-9445, -3564, 1)]
]

::SpawnWave <- function(wave) {
	if (msn != CurrentMission)
		return

	foreach (nme in Missions[msn].waves[num]) {
		SpawnEnemy(nme[0], nme[1])
	}
}

::GetGamerFraction <- function() {
	local frac = 0.0
	local cnt = 0
	local ply = null
	while (ply = Entities.FindByClassname(ply, "player")) {
		frac += ply.GetHealth() / ply.GetMaxHealth()
		cnt++
	}
	return frac / cnt
}

// MUSIC TRACKS

::CurrentTrack <- null

::SetTrack <- function(name, duration) {
	if (CurrentTrack != null && CurrentTrack != name) {
		EntFire("track_" + CurrentTrack, "StopSound")
	}
	::CurrentTrack <- name
	EntFire("track_" + CurrentTrack, "PlaySound")
	EntFire("script", "RunScriptCode", "RefreshTrack(\"" + name + "\", " + duration + ")")
}

::RefreshTrack <- function(name, duration) {
	if (CurrentTrack == name) {
		SetTrack(name)
	}
}
