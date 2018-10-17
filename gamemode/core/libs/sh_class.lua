
if (SERVER) then
	util.AddNetworkString("ixClassUpdate")
end

ix.class = ix.class or {}
ix.class.list = {}

local charMeta = ix.meta.character

-- Register classes from a directory.
function ix.class.LoadFromDir(directory)
	-- Search the directory for .lua files.
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
			-- Define some default variables.
			CLASS.name = "Unknown"
			CLASS.description = "No description available."
			CLASS.limit = 0

			-- For future use with plugins.
			if (PLUGIN) then
				CLASS.plugin = PLUGIN.uniqueID
			end

			-- Include the file so data can be modified.
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

			-- Add the class to the list of classes.
			ix.class.list[index] = CLASS
		-- Remove the global variable to prevent conflict.
		CLASS = nil
	end
end

-- Determines if a player is allowed to join a specific class.
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

function ix.class.Get(identifier)
	return ix.class.list[identifier]
end

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
