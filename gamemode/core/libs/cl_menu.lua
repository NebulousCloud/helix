
--[[--
Entity menu manipulation.

The `menu` library allows you to open up a context menu of arbitrary options whose callbacks will be ran when they are selected
from the panel that shows up for the player.

## Menu options structure
You'll need to pass a table of options to `ix.menu.Open` to populate the menu. This table consists of strings as its keys and
functions as its values. These correspond to the text displayed in the menu and the callback to run, respectively.

Example usage:
	ix.menu.Open({
		Drink = function()
			print("Drink option selected!")
		end,
		Take = function()
			print("Take option selected!")
		end
	}, ents.GetByIndex(1))
This opens a menu with the options `"Drink"` and `"Take"` which will print a message when you click on either of the options.
]]
-- @module ix.menu

ix.menu = ix.menu or {}

--- Opens up a context menu for the given entity.
-- @client
-- @table options Options to display - see the **Menu options structure** section
-- @entity[opt] entity Entity to send commands to
-- @treturn boolean Whether or not the menu opened successfully. It will fail when there is already a menu open.
function ix.menu.Open(options, entity)
	if (IsValid(ix.menu.panel)) then
		return false
	end

	local panel = vgui.Create("ixEntityMenu")
	panel:SetEntity(entity)
	panel:SetOptions(options)

	return true
end

--- Checks whether or not an entity menu is currently open.
-- @client
-- @treturn boolean Whether or not an entity menu is open
function ix.menu.IsOpen()
	return IsValid(ix.menu.panel)
end
