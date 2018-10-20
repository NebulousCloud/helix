
--- Helper library for reading/writing files to the data folder.
-- @module ix.data

ix.data = ix.data or {}
ix.data.stored = ix.data.stored or {}

-- Create a folder to store data in.
file.CreateDir("helix")

--- Populates a file in the `data/helix` folder with some serialized data.
-- @realm shared
-- @string key Name of the file to save
-- @param value Some sort of data to save
-- @bool[opt=false] bGlobal Whether or not to write directly to the `data/helix` folder, or the `data/helix/schema` folder,
-- where `schema` is the name of the current schema.
-- @bool[opt=false] bIgnoreMap Whether or not to ignore the map and save in the schema folder, rather than
-- `data/helix/schema/map`, where `map` is the name of the current map.
function ix.data.Set(key, value, bGlobal, bIgnoreMap)
	-- Get the base path to write to.
	local path = "helix/" .. (bGlobal and "" or Schema.folder .. "/") .. (bIgnoreMap and "" or game.GetMap() .. "/")

	-- Create the schema folder if the data is not global.
	if (!bGlobal) then
		file.CreateDir("helix/" .. Schema.folder .. "/")
	end

	-- If we're not ignoring the map, create a folder for the map.
	file.CreateDir(path)
	-- Write the data using pON encoding.
	file.Write(path .. key .. ".txt", pon.encode({value}))

	-- Cache the data value here.
	ix.data.stored[key] = value

	return path
end

--- Retrieves the contents of a saved file in the `data/helix` folder.
-- @realm shared
-- @string key Name of the file to load
-- @param default Value to return if the file could not be loaded successfully
-- @bool[opt=false] bGlobal Whether or not the data is in the `data/helix` folder, or the `data/helix/schema` folder,
-- where `schema` is the name of the current schema.
-- @bool[opt=false] bIgnoreMap Whether or not to ignore the map and load from the schema folder, rather than
-- `data/helix/schema/map`, where `map` is the name of the current map.
-- @bool[opt=false] bRefresh Whether or not to skip the cache and forcefully load from disk.
-- @return Value associated with the key, or the default that was given if it doesn't exists
function ix.data.Get(key, default, bGlobal, bIgnoreMap, bRefresh)
	-- If it exists in the cache, return the cached value so it is faster.
	if (!bRefresh) then
		local stored = ix.data.stored[key]

		if (stored != nil) then
			return stored
		end
	end

	-- Get the path to read from.
	local path = "helix/" .. (bGlobal and "" or Schema.folder .. "/") .. (bIgnoreMap and "" or game.GetMap() .. "/")
	-- Read the data from a local file.
	local contents = file.Read(path .. key .. ".txt", "DATA")

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

--- Deletes the contents of a saved file in the `data/helix` folder.
-- @realm shared
-- @string key Name of the file to delete
-- @bool[opt=false] bGlobal Whether or not the data is in the `data/helix` folder, or the `data/helix/schema` folder,
-- where `schema` is the name of the current schema.
-- @bool[opt=false] bIgnoreMap Whether or not to ignore the map and delete from the schema folder, rather than
-- `data/helix/schema/map`, where `map` is the name of the current map.
-- @treturn bool Whether or not the deletion has succeeded
function ix.data.Delete(key, bGlobal, bIgnoreMap)
	-- Get the path to read from.
	local path = "helix/" .. (bGlobal and "" or Schema.folder .. "/") .. (bIgnoreMap and "" or game.GetMap() .. "/")
	-- Read the data from a local file.
	local contents = file.Read(path .. key .. ".txt", "DATA")

	if (contents and contents != "") then
		file.Delete(path .. key .. ".txt")
		ix.data.stored[key] = nil
		return true
	else
		-- If we provided a default, return that since we couldn't retrieve the data.
		return false
	end
end

if (SERVER) then
	timer.Create("ixSaveData", 600, 0, function()
		hook.Run("SaveData")
	end)
end
