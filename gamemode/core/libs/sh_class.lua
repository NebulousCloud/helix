
--[[--
Helper library for loading/getting class information.

Classes are temporary assignments for characters - analogous to a "job" in a faction. For example, you may have a police faction
in your schema, and have "police recruit" and "police chief" as different classes in your faction. Anyone can join a class in
their faction by default, but you can restrict this as you need with `CLASS.CanSwitchTo`.
]]
-- @module ix.class

if (SERVER) then
	util.AddNetworkString("ixClassUpdate")
end

ix.class = ix.class or {}
ix.class.list = {}

local charMeta = ix.meta.character

--- Loads classes from a directory.
-- @realm shared
-- @internal
-- @string directory The path to the class files.
function ix.class.LoadFromDir(directory)
	for _, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		-- Get the name without the "sh_" prefix and ".lua" suffix.
		local niceName = v:sub(4, -5)
		-- Determine a numeric identifier for this class.
		local index = #ix.class.list + 1
		local halt

		for _, v2 in ipairs(ix.class.list) do
			if (v2.uniqueID == niceName) then
				halt = true
			end
		end

		if (halt == true) then
			continue
		end

		-- Set up a global table so the file has access to the class table.
		CLASS = {index = index, uniqueID = niceName}
			CLASS.name = "Unknown"
			CLASS.description = "No description available."
			CLASS.limit = 0

			-- For future use with plugins.
			if (PLUGIN) then
				CLASS.plugin = PLUGIN.uniqueID
			end

			ix.util.Include(directory.."/"..v, "shared")

			-- Why have a class without a faction?
			if (!CLASS.faction or !team.Valid(CLASS.faction)) then
				ErrorNoHalt("Class '"..niceName.."' does not have a valid faction!\n")
				CLASS = nil

				continue
			end

			-- Allow classes to be joinable by default.
			if (!CLASS.CanSwitchTo) then
				CLASS.CanSwitchTo = function(client)
					return true
				end
			end

			ix.class.list[index] = CLASS
		CLASS = nil
	end
end

--- Determines if a player is allowed to join a specific class.
-- @realm shared
-- @player client Player to check
-- @number class Index of the class
-- @treturn bool Whether or not the player can switch to the class
function ix.class.CanSwitchTo(client, class)
	-- Get the class table by its numeric identifier.
	local info = ix.class.list[class]

	-- See if the class exists.
	if (!info) then
		return false, "no info"
	end

	-- If the player's faction matches the class's faction.
	if (client:Team() != info.faction) then
		return false, "not correct team"
	end

	if (client:GetCharacter():GetClass() == class) then
		return false, "same class request"
	end

	if (info.limit > 0) then
		if (#ix.class.GetPlayers(info.index) >= info.limit) then
			return false, "class is full"
		end
	end

	if (hook.Run("CanPlayerJoinClass", client, class, info) == false) then
		return false
	end

	-- See if the class allows the player to join it.
	return info:CanSwitchTo(client)
end

--- Retrieves a class table.
-- @realm shared
-- @number identifier Index of the class
-- @treturn table Class table
function ix.class.Get(identifier)
	return ix.class.list[identifier]
end

--- Retrieves the players in a class
-- @realm shared
-- @number class Index of the class
-- @treturn table Table of players in the class
function ix.class.GetPlayers(class)
	local players = {}

	for _, v in ipairs(player.GetAll()) do
		local char = v:GetCharacter()

		if (char and char:GetClass() == class) then
			table.insert(players, v)
		end
	end

	return players
end

function charMeta:JoinClass(class)
	if (!class) then
		self:KickClass()

		return
	end

	local oldClass = self:GetClass()
	local client = self:GetPlayer()

	if (ix.class.CanSwitchTo(client, class)) then
		self:SetClass(class)
		hook.Run("PlayerJoinedClass", client, class, oldClass)

		return true
	else
		return false
	end
end

function charMeta:KickClass()
	local client = self:GetPlayer()
	if (!client) then return end

	local goClass

	for k, v in pairs(ix.class.list) do
		if (v.faction == client:Team() and v.isDefault) then
			goClass = k

			break
		end
	end

	self:JoinClass(goClass)

	hook.Run("PlayerJoinedClass", client, goClass)
end

function GM:PlayerJoinedClass(client, class, oldClass)
	local info = ix.class.list[class]
	local info2 = ix.class.list[oldClass]

	if (info.OnSet) then
		info:OnSet(client)
	end

	if (info2 and info2.OnLeave) then
		info2:OnLeave(client)
	end

	net.Start("ixClassUpdate")
		net.WriteEntity(client)
	net.Broadcast()
end
