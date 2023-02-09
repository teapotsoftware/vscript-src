
::point_clientcommand <- Entities.CreateByClassname("point_clientcommand")

::SendCommandToClient <- function(player, command)
{
	EntFireByHandle(point_clientcommand, "Command", command, 0, player, point_clientcommand)
}

::PlayEndMusic <- function()
{
	local data = this.event_data

	ply <- null
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		if (ply.GetTeam() == data.winner)
		{
			SendCommandToClient(ply, "play fof/music_victory.mp3")
		}
		else
		{
			SendCommandToClient(ply, "play fof/music_defeat.mp3")
		}
	}
}