
IncludeScript("butil")

GameUI <- EntityGroup[0]
ItemModel <- EntityGroup[1]
ItemName <- EntityGroup[2]
ItemDesc <- EntityGroup[3]

CurrentItemIndex <- 0
ItemList <- [
	["models/weapons/w_pist_glock18_dropped.mdl", "Glock", "Super gangster pistol gun"],
	["models/weapons/w_pist_deagle_dropped.mdl", "Deagle", "Epic kinda long range gun"],
	["models/weapons/w_shot_sawedoff_dropped.mdl", "Sawed Off", "Super cool close range gun"],
	["models/weapons/w_snip_awp_dropped.mdl", "AWP", "Epic long range gun"]
]

GameUIScope <- null
if (GameUI.ValidateScriptScope())
{
	GameUIScope <- GameUI.GetScriptScope()
}

GameUIScope.MainScript <- this
GameUIScope.GoLeft <- function() {MainScript.UpdateDisplay(-1)}
GameUIScope.GoRight <- function() {MainScript.UpdateDisplay(1)}
GameUI.ConnectOutput("PressedMoveLeft", "GoLeft")
GameUI.ConnectOutput("PressedMoveRight", "GoRight")

UpdateDisplay <- function(cycle = 0)
{
	CurrentItemIndex = (ItemList.len() + CurrentItemIndex + cycle) % ItemList.len()
	SetModelSafe(ItemModel, ItemList[CurrentItemIndex][0])
	EntFireHandle(ItemName, "AddOutput", "message " + ItemList[CurrentItemIndex][1])
	EntFireHandle(ItemDesc, "AddOutput", "message " + ItemList[CurrentItemIndex][2])
}

OnPostSpawn <- function()
{
}

Think <- function()
{
	ItemModel.SetAngles(0, Time(), 0)
}
