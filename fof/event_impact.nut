
::PlayRicSound <- function()
{
	local d = this.event_data
	local pos = Vector(d.x, d.y, d.z)
	local name = "fof_ric" + RandomInt(1, 4)
	local ent = Entities.FindByName(null, name)
	ent.SetOrigin(pos)
	EntFire(name, "PlaySound", "")
}