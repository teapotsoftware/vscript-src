
//Boi <- EntityGroup[0]
//LookTrigger <- EntityGroup[1]

::LookedAtFace <- function(ply)
{
	printl(ply.GetClassname() + " - " + ply.entindex())
	ScriptPrintMessageChatAll("uh oh")
}
