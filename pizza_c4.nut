
local pizza_box = "models/props_junk/garbage_pizzabox01a.mdl"
Entities.First().PrecacheModel(pizza_box)

local bomb = null
while (bomb = Entities.FindByClassname(bomb, "weapon_c4"))
	bomb.SetModel(pizza_box)