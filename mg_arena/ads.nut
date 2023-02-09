
/*
** Author: Nick B (https://steamcommunity.com/id/sirfrancisbillard/)
** Description:
**     Jager's ADS from rainbow 6 siege.
**     Shoots and destroys nearby enemy grenades.
*/

::ADS_BEEP_SOUND <- "Sensor.WarmupBeep"
::ADS_SHOOT_SOUND <- "Weapon_CZ75A.Single"

this.DefenderGadget <- true
this.LastDisable <- -999
this.thinkCount <- 0

Precache <- function() {
	self.PrecacheSoundScript(ADS_BEEP_SOUND)
	self.PrecacheSoundScript(ADS_SHOOT_SOUND)
}

Think <- function() {
	if (Time() - this.LastDisable <= 10) {
		return
	}

	this.thinkCount++
	if (this.thinkCount >= 15) {
		self.EmitSound(ADS_BEEP_SOUND)
		this.thinkCount = 0
	}

	local nade = null
	while (nade = Entities.FindByNameWithin(nade, "ads_target", self.GetOrigin(), 90)) {
		if (nade.GetTeam() == CT) {
			DispatchParticleEffect("slime_splash_0" + RandomInt(1, 3), nade.GetOrigin(), Vector(0, 0, 0))
			self.EmitSound(ADS_SHOOT_SOUND)
			self.SetForwardVector(nade.GetOrigin() - self.GetOrigin())
			QueueForDeletion(nade)
		}
	}
	FlushDeletionQueue()

	// speeeen
	local ang = self.GetAngles()
	ang.y -= 3
	self.SetAngles(ang.x, ang.y, ang.z)
}
