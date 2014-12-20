--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

PLUGIN.name = "Logging"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
    function PLUGIN:CharacterLoaded()
        nut.log.add("%s loaded char %s.")
    end

    function PLUGIN:OnCharDelete(client, id)
        nut.log.add("%s deleted char %s.", FLAG_WARNING)
    end

    function PLUGIN:OnPlayerObserve(client, isObserving)
        nut.log.add("%s " .. (isObserving and "started observing" or "quit observing"))
    end

    local logInteractions = {
        ["drop"] = true,
        ["take"] = true,
        ["equip"] = true,
        ["unequip"] = true,
    } 
    function PLUGIN:OnPlayerInteractItem(client, action, item)
        if (logInteractions[action:lower()]) then
            if (type(item) == "Entity") then
                if (IsValid(item)) then
                    local entity = item
                    local itemID = item.nutItemID
                    item = nut.item.instances[itemID]
                else
                    return
                end
            elseif (type(item) == "number") then
                item = nut.item.instances[item]
            end

            if (!item) then
                return
            end
            nut.log.add(Format("%s did %s on %s.", client:Name(), action, item.name))
        end
    end
end