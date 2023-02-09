
IncludeScript("butil")

::LOADOUTS <- [
	[WEAPON_KNIFE_M9_BAYONET, ITEM_KEVLAR, WEAPON_GLOCK],
	[WEAPON_BAYONET, ITEM_KEVLAR, WEAPON_P2K],
	[WEAPON_KNIFE_KARAMBIT, ITEM_KEVLAR, WEAPON_USPS],
	[WEAPON_KNIFE_M9_BAYONET, ITEM_KEVLAR, WEAPON_GALIL],
	[WEAPON_BAYONET, ITEM_KEVLAR, WEAPON_FAMAS],
	[WEAPON_BAYONET, ITEM_ASSAULTSUIT, WEAPON_M4A4],
	[WEAPON_KNIFE_KARAMBIT, ITEM_ASSAULTSUIT, WEAPON_M4A1],
	[WEAPON_KNIFE_M9_BAYONET, ITEM_ASSAULTSUIT, WEAPON_AK47],
	[WEAPON_KNIFE_BUTTERFLY, ITEM_ASSAULTSUIT, WEAPON_AK47],
	[WEAPON_KNIFE_KARAMBIT, ITEM_ASSAULTSUIT, WEAPON_DEAGLE],
	[WEAPON_KNIFE_BUTTERFLY, ITEM_ASSAULTSUIT, WEAPON_DEAGLE],
	[WEAPON_KNIFE_KARAMBIT, ITEM_ASSAULTSUIT, WEAPON_AWP],
	[WEAPON_KNIFE_BUTTERFLY, ITEM_ASSAULTSUIT, WEAPON_AWP],
]

function OnPostSpawn()
{
	SendToConsole("mp_death_drop_gun 0;mp_freezetime 0;mp_round_restart_delay 1;mp_maxrounds 9999")
	if (ScriptIsWarmupPeriod())
	{
		SendToConsole("mp_warmup_end")
		return
	}
	Chat(WHITE + "Welcome to " + GOLD + "AIM_MAP_" + RED + "CHINA" + GOLD + "!!!")
	ChatTeam(T, WHITE + "You are dirty " + BLUE + "american pig dog" + WHITE + ". Submit to Glorious Leader " + GOLD + "Xi Jinping" + WHITE + " or you will be " + DARK_RED + "DESTROYED!!!")
	ChatTeam(CT, WHITE + "Glorious Leader " + GOLD + "Xi Jinping" + WHITE + " has found " + BLUE + "american pig dog" + WHITE + " in this area. " + DARK_RED + "DESTROY THEM!!!")
	::CurrentLoadout <- RandomFromArray(LOADOUTS)
	ForEachPlayerAndBot(function(ply) {
		GiveLoadout(ply, CurrentLoadout)
		ply.SetModel(Ent("plymdl_" + ply.GetTeam()).GetModelName())
	})
	MeleeFixup()
}

function Think()
	ForEachPlayerAndBot(function(ply) {UserIDThink(ply)})

::CCP_CENSORED <- [
	"winnie",
	"winny",
	"pooh",
	"tiananmen",
	"tianemen",
	"tianamen",
	"tianmen",
	"protests",
	"massacre",
	"june 4",
	"1989",
	"great leap",
	"leap forward",
	"tibet",
	"hong kong",
	"taiwan",
	"revolution",
	"freedom",
	"independence",
	"dalai lama",
	"human rights",
	"uyghur",
	"uighur",
	"autonomous zone"
]

AddHook("player_say", "CCP", function(data) {
	local ply = data.userid_player
	if (ply == null || !LivingPlayer(ply))
		return

	local txt = data.text.tolower()
	foreach (word in CCP_CENSORED)
	{
		if (txt.find(word) != null)
		{
			Chat(DARK_RED + "A user in this game has mistakenly entered incorrect information in chat, and will be duly re-educated. Long live Xi Jinping!")
			ply.SetHealth(Min(25, ply.GetHealth()))
			Ignite(ply, 5)
			ply.SetOrigin(Ent("reeducation").GetOrigin())
			break
		}
	}
})
