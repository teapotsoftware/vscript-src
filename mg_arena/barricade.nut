
InputUse <- function()
{
	if (!("LastPlace" in this))
		this.LastPlace <- Time() - 2

	if (activator.GetTeam() == T && Time() - this.LastPlace >= 1)
	{
		CenterPrint(activator, Entities.FindByNameNearest((self.GetName() == "barricade_button") ? "barricade" : "barricade_big", self.GetOrigin(), 2) == null ? Lang.BARRICADE_START : Lang.BARRICADE_BREAK)
		return true
	}
	return false
}
