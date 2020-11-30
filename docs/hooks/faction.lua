
-- luacheck: ignore 111

--[[--
Faction setup hooks.

Factions get their own hooks that are called for various reasons, but the most common one is to set up a character
once it's created and assigned to a certain faction. For example, giving a police faction character a weapon on creation.
These hooks are used in faction tables that are created in `schema/factions/sh_factionname.lua` and cannot be used like
regular gamemode hooks.
]]
-- @hooks Faction

--- Called when the default name for a character needs to be retrieved (i.e upon initial creation).
-- @realm shared
-- @player client Client to get the default name for
-- @treturn string Default name for the newly created character
-- @usage function FACTION:GetDefaultName(client)
-- 	return "MPF-RCT." .. tostring(math.random(1, 99999))
-- end
function GetDefaultName(client)
end

--- Called when a character has been initally created and assigned to this faction.
-- @realm server
-- @player client Client that owns the character
-- @char character Character that has been created
-- @usage function FACTION:OnCharacterCreated(client, character)
-- 	local inventory = character:GetInventory()
-- 	inventory:Add("pistol")
-- end
function OnCharacterCreated(client, character)
end

--- Called when a character in this faction has spawned in the world.
-- @realm server
-- @player client Player that has just spawned
function OnSpawn(client)
end

--- Called when a player's character has been transferred to this faction.
-- @realm server
-- @char character Character that was transferred
-- @usage function FACTION:OnTransferred(character)
-- 	character:SetModel(self.models[1])
-- end
function OnTransferred(character)
end
