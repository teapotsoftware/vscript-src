
PaintPreview <- EntityGroup[0]
PaintSpot <- EntityGroup[1]

::TOTAL_PAINTS <- 28
SelectedPaint <- 0

ChangePaint <- function(change = 0)
{
	SelectedPaint = (TOTAL_PAINTS + SelectedPaint + change) % TOTAL_PAINTS
	EntFireByHandle(PaintPreview, "AddOutput", "texframeindex " + SelectedPaint, 0.0, null, null)
}

ApplyPaint <- function()
{
	local car = Entities.FindByClassnameNearest("func_tracktrain", PaintSpot.GetOrigin(), 200)
	if (car != null)
		EntFireByHandle(car, "AddOutput", "texframeindex " + SelectedPaint, 0.0, null, null)
}
