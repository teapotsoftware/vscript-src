
if ("gameevents_proxy" in getroottable() && gameevents_proxy != null)
	::gameevents_proxy.Destroy()

::gameevents_proxy<-Entities.CreateByClassname("info_game_event_proxy");
::gameevents_proxy.__KeyValueFromString("event_name","player_connect");
::gameevents_proxy.__KeyValueFromInt("range",0);

::GameEventsCapturedPlayer<-null

AddHook("player_connect", "fukcing_assigner_foodfight", function(params)
{
	printl("ASS")
	if (::GameEventsCapturedPlayer!=null)
	{
		local script_scope=::GameEventsCapturedPlayer.GetScriptScope();
		script_scope.userid<-params.userid;
		printl(GameEventsCapturedPlayer + " assgined!!!! (" + params.userid + ")")
		::GameEventsCapturedPlayer=null;
		return true
	}
})

AssignThink<-function()
{
	player<-null;
	while((player = Entities.FindByClassname(player,"*")) != null){
		if (player.GetClassname()=="player"){
			if (player.ValidateScriptScope()){
				local script_scope=player.GetScriptScope()
				if (((!("userid" in script_scope)) || script_scope.userid == 0)&&!("attemptogenerateuserid" in script_scope)){
					script_scope.attemptogenerateuserid<-true;
					::GameEventsCapturedPlayer=player;
					EntFireByHandle(::gameevents_proxy,"GenerateGameEvent","",0.0,player,null);
					printl(player + " assginer?")
				}
			}
		}
	}
}

AssignThink()

printl("FUCK!")
