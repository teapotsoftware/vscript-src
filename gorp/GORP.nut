DoIncludeScript("VUtil.nut", null)

printl("[GORP] Loading...")

::GORP <- {}

GORP.Entities <- []
GORP.EntityInstances <- []

SendToConsole("mp_respawn_on_death_ct 1")
SendToConsole("mp_respawn_on_death_t 1")

function GORP::BaseEntity() {
	return {name = "Base Entity", model = "models/error.mdl", think = function() {}, use = function() {}}
}

function GORP::RegisterEntity(name) {
	::ENT = GORP.BaseEntity()
	DoIncludeScript("gorp/entities/" + name + ".nut", this)
	GORP.Entities.push(ENT)
	::ENT = null
	printl("[GORP] Registered entity: " + name)
}

function GORP::DefaultEntities() {
	GORP.RegisterEntity("dropped_money")
	GORP.RegisterEntity("money_printer")
	GORP.RegisterEntity("drug_lab")
	GORP.RegisterEntity("drugs")
}

