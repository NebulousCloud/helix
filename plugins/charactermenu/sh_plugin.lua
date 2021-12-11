
local PLUGIN = PLUGIN

PLUGIN.name = "Character Menu"
PLUGIN.description = "Provides an interface to create, load, and delete characters."
PLUGIN.author = "`impulse"

if (CLIENT) then
	function PLUGIN:CreateCharacterMenu()
		return vgui.Create("ixCharacterMenu")
	end
end
