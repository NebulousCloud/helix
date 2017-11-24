ix.data = ix.data or {}
ix.data.stored = ix.data.stored or {}

-- Create a folder to store data in.
file.CreateDir("helix")

-- Set and save data in the helix folder.
function ix.data.Set(key, value, global, ignoreMap)
	-- Get the base path to write to.
	local path = "helix/"..(global and "" or Schema.folder.."/")..(ignoreMap and "" or game.GetMap().."/")

	-- Create the schema folder if the data is not global.
	if (!global) then
		file.CreateDir("helix/"..Schema.folder.."/")
	end

	-- If we're not ignoring the map, create a folder for the map.
	file.CreateDir(path)
	-- Write the data using pON encoding.
	file.Write(path..key..".txt", pon.encode({value}))

	-- Cache the data value here.
	ix.data.stored[key] = value

	return path
end

-- Gets a piece of information for Helix.
function ix.data.Get(key, default, global, ignoreMap, refresh)
	-- If it exists in the cache, return the cached value so it is faster.
	if (!refresh) then
		local stored = ix.data.stored[key]

		if (stored != nil) then
			return stored
		end
	end

	-- Get the path to read from.
	local path = "helix/"..(global and "" or Schema.folder.."/")..(ignoreMap and "" or game.GetMap().."/")
	-- Read the data from a local file.
	local contents = file.Read(path..key..".txt", "DATA")

	if (contents and contents != "") then
		-- Decode the contents and return the data.
		local status, decoded = pcall(pon.decode, contents)

		if (status and decoded) then
			local value = decoded[1]

			if (value != nil) then
				return value
			else
				return default
			end
		else
			return default
		end
	else
		-- If we provided a default, return that since we couldn't retrieve the data.
		return default
	end
end

-- Deletes existing data in helix framework.
function ix.data.Delete(key, global, ignoreMap)
	-- Get the path to read from.
	local path = "helix/"..(global and "" or Schema.folder.."/")..(ignoreMap and "" or game.GetMap().."/")
	-- Read the data from a local file.
	local contents = file.Read(path..key..".txt", "DATA")

	if (contents and contents != "") then
		file.Delete(path..key..".txt")
		ix.data.stored[key] = nil
		return true
	else
		-- If we provided a default, return that since we couldn't retrieve the data.
		return false
	end
end

timer.Create("ixSaveData", 600, 0, function()
	hook.Run("SaveData")
	hook.Run("PersistenceSave")
end)
