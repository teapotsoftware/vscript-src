
::PlayerDeathUserID <- function()
{
	local data = this.event_data
	if (queued_player != null && queued_player.ValidateScriptScope())
	{
		local scope = queued_player.GetScriptScope()
		if (!("userid" in scope))
		{
			scope.userid <- data.userid
			//P("UserID " + data.userid + " assigned to " + queued_player.entindex())
		}
		::queued_player = null
	}
}
