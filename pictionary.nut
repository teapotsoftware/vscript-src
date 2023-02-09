
::GiveWeapon <- function(ply, weapon, ammo = 1)
{
	local equip = Entities.CreateByClassname("game_player_equip")
	equip.__KeyValueFromInt("spawnflags", 5)
	equip.__KeyValueFromInt(weapon, ammo)
	EntFireByHandle(equip, "Use", "", 0.0, ply, null)
	equip.__KeyValueFromInt(weapon, 0)
	equip.Destroy()
}

::StripWeapons <- function(ply)
{
	local strip = Entities.CreateByClassname("player_weaponstrip")
	EntFireByHandle(strip, "Strip", "", 0.0, ply, null)
	strip.Destroy()
}

// bruh moment
::WordList <- ["dink", "monkey", "fellatio", "fruit", "gate", "hang", "concentrate", "juice", "blood", "sky", "split", "powder", "free", "disobey", "place", "private", "sponge", "trees", "solid", "death", "swim", "paper", "hurt", "wind", "milky", "inflate", "comfort", "bun", "driving", "dead", "free", "discover", "magic", "sample", "narrow", "lawyer", "noisy", "give", "actor", "shut", "balloon", "blossom", "letter", "screw", "vacation", "boil", "hose", "angle", "apple", "smell", "mass", "duck", "party", "downtown", "sweater", "girl", "earth", "legs", "marble", "birth", "key", "mind", "sofa", "cork", "sink", "pain", "north", "cars", "chain", "vest", "food", "brass", "pancake", "bell", "geese", "spider", "corn", "soda", "clock", "frog", "glove", "father", "balance", "daughter", "lamp", "bridge", "home", "lunch", "baby", "love", "bee", "record", "alley", "zebra", "country", "celery", "bomb", "scarf", "trucks", "chance", "arm", "stick", "tent", "anger", "bite", "shoe", "gun", "seed", "battle", "cave", "guitar", "chess", "school", "nail", "hammer", "cemetery", "light", "crib", "throat", "mom", "color", "ink", "bell", "wash", "camera", "flower", "alarm", "ticket", "ear", "friends", "haircut", "body", "doctor", "laugh", "middle", "moon", "police", "cobweb", "club", "spot", "music", "egg", "cherry", "poison", "division", "sticks", "beds", "creator", "cheese", "smell", "nest", "sheep", "airplane", "family", "party", "sheet", "flight", "badge", "debt", "faucet", "muscle", "feather", "hands", "lock", "orange", "calculator", "border", "trail", "bushes", "market", "steel", "breath", "hospital", "train", "scissors", "office", "idea", "face", "language", "tank", "pear", "kitten", "dinosaur", "volleyball", "crime", "zipper", "man", "tray", "jeans", "wall", "string", "cook", "collar", "boy", "sidewalk", "rose", "sail", "pencil", "nut", "crush", "birthday", "crayon", "toothpaste", "war", "liquid", "thread", "store", "stew", "bag", "polish", "note", "top", "floor", "roof"]
::Word <- "Bloxwich"
::BlankWord <- "________"

::BLACK <- 0
::WHITE <- 1
::RED <- 2
::ORANGE <- 3
::YELLOW <- 4
::GREEN <- 5
::AQUA <- 6
::BLUE <- 7
::PINK <- 8
::PURPLE <- 9

::ColorToR <- [0, 255, 255, 255, 255, 0, 0, 0, 255, 140]
::ColorToG <- [0, 255, 0, 140, 255, 255, 255, 0, 100, 40]
::ColorToB <- [0, 255, 0, 255, 255, 0, 255, 255, 180, 225]

::PaintColor <- BLACK
::Impacts <- []

::SetPaintColor <- function(clr) {PaintColor <- clr}

// build the table in triplets, start vector, end vector, color (as vector)
BulletImpact <- function()
{
	local data = this.event_data
	Impacts.push(Vector(data.x, data.y, data.z))
	if (Impacts.len() % 3 == 2)
	{
		Impacts.push(Vector(ColorToR[PaintColor], ColorToG[PaintColor], ColorToB[PaintColor]))
	}
	SendToConsole("r_cleardecals")
}

ChatMessage <- function()
{
	local data = this.event_data
	if (Word != "" && data.text.tolower() == Word)
	{
		ScriptPrintMessageChatAll("Correct! The word was " + Word.toupper() + "!")
		ScriptPrintMessageChatAll("Next round starting in 10 seconds...")
		Word = ""
	}
}

i <- 0

Think <- function()
{
	i++
	if (i > 5)
	{
		i <- 0
		local curPoint = []
		foreach (imp in Impacts)
		{
			curPoint.push(imp)
			if (curPoint.len() > 2)
			{
				DebugDrawLine(curPoint[0], curPoint[1], curPoint[2].x, curPoint[2].y, curPoint[2].z, true, 0.65)
				curPoint = []
			}
		}
	}
}

LetterHint <- function()
{
	local letterIndex = RandomInt(0, Word.len() - 1)
	BlankWord[letterIndex] = Word[letterIndex]
	EntFire("spectator_display", "addoutput", "message " + BlankWord)
}

::StartGame <- function()
{
	SendToConsoleServer("sv_infinite_ammo 1")

	local bleachers = Entities.FindByName(null, "spectator_teleport").GetOrigin()
	painter <- null
	ply <- null
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		StripWeapons(ply)
		if (painter == null && ply.ValidateScriptScope() && !(("been_chosen" in ply.GetScriptScope()) && ply.GetScriptScope().been_chosen))
		{
			ply.GetScriptScope().been_chosen <- true
			painter <- ply
		}
		else
		{
			ply.SetOrigin(bleachers)
		}
	}

	if (painter == null)
	{
		ply <- null
		while ((ply = Entities.FindByClassname(ply, "player")) != null)
		{
			if (ply.ValidateScriptScope())
			{
				ply.GetScriptScope().been_chosen = false
			}
		}
		StartGame()
	}

	Impacts <- []

	Word <- WordList[RandomInt(0, WordList.len() - 1)]
	EntFire("painter_display", "addoutput", "message " + Word.toupper())

	local blank = ""
	for (local i = 0; i < Word.len(); i++)
	{
		blank += "_"
	}
	BlankWord <- blank
	EntFire("spectator_display", "addoutput", "message " + BlankWord)

	painter.SetOrigin(Entities.FindByName(null, "painter_teleport").GetOrigin())
	GiveWeapon(painter, "weapon_m4a1_silencer", 9001)
}
