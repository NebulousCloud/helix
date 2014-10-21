nut.class = nut.class or {}
nut.class.list = {}

-- Register classes from a directory.
function nut.class.loadFromDir(directory)
	-- Search the directory for .lua files.
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		-- Get the name without the "sh_" prefix and ".lua" suffix.
		local niceName = v:sub(4, -5)
		-- Determine a numeric identifier for this class.
		local index = #nut.class.list + 1

		-- Set up a global table so the file has access to the class table.
		CLASS = {index = index, uniqueID = niceName}
			-- Define some default variables.
			CLASS.name = "Unknown"
			CLASS.desc = "No description available."

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
		return false
	end

	-- If the player's faction matches the class's faction.
	if (client:Team() != info.faction) then
		return false
	end

	-- See if the class allows the player to join it.
	return info.onCanBe(client)
end