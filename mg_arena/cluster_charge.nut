
/*
** Author: Nick B (https://steamcommunity.com/id/sirfrancisbillard/)
** Description:
**     Fuze's cluster charge from rainbow 6 siege.
**     Launches three grenades through the implanted surface then disappears.
*/

::CLUSTER_DEPLOY_SOUND <- "Doors.Metal.Pound1"
::CLUSTER_SHOOT_SOUND <- "coop.grenade_launch"

this.placingPlayer <- null
this.thinkCount <- 0

Precache <- function() {
	self.PrecacheSoundScript(CLUSTER_DEPLOY_SOUND)
	self.PrecacheSoundScript(CLUSTER_SHOOT_SOUND)
}

OnPostSpawn <- function() {
	this.placingPlayer <- ::ClusterChargePlacer
	self.EmitSound(CLUSTER_DEPLOY_SOUND)
}

Think <- function() {
	if (this.thinkCount == 17) {
		SendNade()
		EntFireHandle(self, "FireUser1")
	} else if (this.thinkCount == 23) {
		SendNade()
		EntFireHandle(self, "FireUser2")
	} else if (this.thinkCount == 29) {
		SendNade()
		EntFireHandle(self, "FireUser3")
	} else if (this.thinkCount == 35) {
		EntFireHandle(self, "FireUser4")
	}

	this.thinkCount++
}

SendNade <- function() {
	ClusterNadeMaker.SpawnEntityAtLocation(self.GetOrigin() - self.GetUpVector() * 20, self.GetAngles())
	self.EmitSound(CLUSTER_SHOOT_SOUND)
	EntFire("clusternade", "FireUser1")
}
