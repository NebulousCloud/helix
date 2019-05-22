
--[[--
Provides an API for integrating a character menu.

If you find the built-in character menu doesn't suit your needs, then you can quite easily create your own custom character
menu to replace it.

The most basic implementation requires that you have a panel that is based off of the `ixCharacterMenuBase` panel. This panel
contains all the necessary methods for creating a functional character menu. You'll need to disable the built-in character menu
in order for your own menu to be created. Fortunately this is easily done by unloading the `charactermenu` plugin with:
	ix.plugin.SetUnloaded("charactermenu", true, true)
The `charactermenu` plugin is the framework's base character menu implementation - you can refer to this plugin for specific
implementation details.

The only next step is to register your panel as the active character menu whenever it's created. This is done by hooking into
`CreateCharacterMenu` on the client and returning an instance of your panel. For example, if you're implementing your character
menu in a plugin:
	function PLUGIN:CreateCharacterMenu()
		return vgui.Create("ixMyCharacterMenu")
	end
]]
-- @module ix.charmenu

ix.charmenu = ix.charmenu or {}

--- Creates a character menu and sets it as active.
-- @realm client
-- @internal
function ix.charmenu.Create()
	if (IsValid(ix.gui.characterMenu)) then
		ix.gui.characterMenu:Remove()
	end

	local panel = hook.Run("CreateCharacterMenu")

	if (!IsValid(panel)) then
		error("no panels were returned when creating character menu!")
	end

	-- if the panel isn't based off of ixCharacterMenuBase then it'll probably be missing the necessary methods
	if (panel.Base != "ixCharacterMenuBase") then
		ErrorNoHalt("returned character menu panel is not based off of ixCharacterMenuBase!\n")
	end

	ix.gui.characterMenu = panel
end

--- Returns the character menu if it exists. Checking if the user is currently in the character menu should be done with
-- `ix.charmenu.IsOpen`, rather than checking the validity of the panel.
-- @realm client
-- @treturn[1] panel Character panel
-- @treturn[2] nil If the character panel does not exist
function ix.charmenu.Get()
	return IsValid(ix.gui.characterMenu) and ix.gui.characterMenu or nil
end

--- Returns the opened state of the character menu.
-- @realm client
-- @treturn bool Whether or not the character menu is open and **not** closing
function ix.charmenu.IsOpen()
	return IsValid(ix.gui.characterMenu) and !ix.gui.characterMenu.bClosing
end

--- Returns the closing state of the character menu. This usually means that the character menu currently exists, but is going
-- to close shortly (i.e performing a closing animation).
-- @realm client
-- @treturn bool Whether or not the character menu is closing
function ix.charmenu.IsClosing()
	return IsValid(ix.gui.characterMenu) and ix.gui.characterMenu.bClosing
end
