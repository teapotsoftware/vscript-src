
local LocalPlayer = Entities.FindByClassname(null, "player")

local vm = null
while (vm = Entities.FindByClassname(vm, "predicted_viewmodel"))
{
	if (vm.GetMoveParent() == LocalPlayer)
		printl("LocalPlayer VM angles: " + vm.GetAngles())
}
