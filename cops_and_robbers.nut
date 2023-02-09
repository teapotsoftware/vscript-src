
IncludeScript("butil")

OnPostSpawn <- function()
{
	
}

Think <- function()
{
	
}

::PickupKeycard <- function(card)
{
	local ply = NearestPlayer(card.GetOrigin())
	if (ply != null && ply.ValidateScriptScope())
	{
	}
}

