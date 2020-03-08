
-- luacheck: ignore 111

--[[--
Class setup hooks.

As with `Faction`s, `Class`es get their own hooks for when players leave/join a class, etc. These hooks are only
valid in class tables that are created in `schema/classes/sh_classname.lua`, and cannot be used like regular gamemode hooks.
]]
-- @hooks Class

--- Whether or not a player can switch to this class.
-- @realm shared
-- @player client Client that wants to switch to this class
-- @treturn bool True if the player is allowed to switch to this class
-- @usage function CLASS:CanSwitchTo(client)
-- 	return client:IsAdmin() -- only admins allowed in this class!
-- end
function CanSwitchTo(client)
end

--- Called when a character has left this class and has joined a different one. You can get the class the character has
-- has joined by calling `character:GetClass()`.
-- @realm server
-- @player client Player who left this class
function OnLeave(client)
end

--- Called when a character has joined this class.
-- @realm server
-- @player client Player who has joined this class
-- @usage function CLASS:OnSet(client)
-- 	client:SetModel("models/police.mdl")
-- end
function OnSet(client)
end

--- Called when a character in this class has spawned in the world.
-- @realm server
-- @player client Player that has just spawned
function OnSpawn(client)
end
