nut.class = nut.class or {}
nut.class.list = {}

local charMeta = nut.meta.character

-- Register classes from a directory.
function nut.class.loadFromDir(directory)
	-- Search the directory for .lua files.
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		-- Get the name without the "sh_" prefix and ".lua" suffix.
		local niceName = v:sub(4, -5)
		-- Determine a numeric identifier for this class.
		local index = #nut.class.list + 1

		local halt
		for k, v in ipairs(nut.class.list) do
			if (v.uniqueID == niceName) then
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
			CLASS.desc = "No description available."
			CLASS.limit = 0

			-- For future use with plugins.
			if (PLUGIN) then
				CLASS.plugin = PLUGIN.uniqueID
			end

			-- Include the file so data can be modified.
			nut.util.include(directory.."/"..v, "shared")

			-- Why have a class without a faction?
			if (!CLASS.faction or !team.Valid(CLASS.faction)) then
				ErrorNoHalt("Class '"..niceName.."' does not have a valid faction!\n")
				CLASS = nil

				continue
			end

			-- Allow classes to be joinable by default.
			if (!CLASS.onCanBe) then
				CLASS.onCanBe = function(client)
					return true
				end
			end

			-- Add the class to the list of classes.
			nut.class.list[index] = CLASS
		-- Remove the global variable to prevent conflict.
		CLASS = nil
	end
end

-- Determines if a player is allowed to join a specific class.
function nut.class.canBe(client, class)
	-- Get the class table by its numeric identifier.
	local info = nut.class.list[class]

	-- See if the class exists.
	if (!info) then
		return false, "no info"
	end

	-- If the player's faction matches the class's faction.
	if (client:Team() != info.faction) then
		return false, "not correct team"
	end

	if (client:getChar():getClass() == class) then
		return false, "same class request"
	end

	if (info.limit > 0) then
		if (#nut.class.getPlayers(info.index) >= info.limit) then
			return false, "class is full"
		end
	end

	hook.Run("CanPlayerJoinClass", client, class, info)

	-- See if the class allows the player to join it.
	return info:onCanBe(client)
end

function nut.class.get(identifier)
	return nut.class.list[identifier]
end

function nut.class.getPlayers(class)
	local players = {}
	for k, v in ipairs(player.GetAll()) do
		local char = v:getChar()

		if (char and char:getClass() == class) then
			table.insert(players, v)
		end
	end

	return players
end

function charMeta:joinClass(class)
	if (!class) then
		self:kickClass()

		return
	end

	local oldClass = self:getClass()
	local client = self:getPlayer()

	if (nut.class.canBe(client, class)) then
		self:setClass(class)
		hook.Run("OnPlayerJoinClass", client, class, oldClass)

		return true
	else
		return false
	end
end

function charMeta:kickClass()
	local client = self:getPlayer()
	if (!client) then return end
	
	local goClass

	for k, v in pairs(nut.class.list) do
		if (v.faction == client:Team() and v.isDefault) then
			goClass = k
			
			break
		end
	end

	self:joinClass(goClass)
	
	hook.Run("OnPlayerJoinClass", client, goClass)
end

function GM:OnPlayerJoinClass(client, class, oldClass)
	local info = nut.class.list[class]
	local info2 = nut.class.list[oldClass]

	if (info.onSet) then
		info:onSet(client)
	end

	if (info2 and info2.onLeave) then
		info2:onLeave(client)
	end

	netstream.Start(nil, "classUpdate", client)
end