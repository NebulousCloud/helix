nut.data = nut.data or {}
nut.data.stored = nut.data.stored or {}

-- Create a folder to store data in.
file.CreateDir("nutscript")

-- Set and save data in the nutscript folder.
function nut.data.set(key, value, global, ignoreMap)
	-- Get the base path to write to.
	local path = "nutscript/"..(global and "" or SCHEMA.folder.."/")..(ignoreMap and "" or game.GetMap().."/")

	-- Create the schema folder if the data is not global.
	if (!global) then
		file.CreateDir("nutscript/"..SCHEMA.folder.."/")
	end

	-- If we're not ignoring the map, create a folder for the map.
	file.CreateDir(path)
	-- Write the data using pON encoding.
	file.Write(path..key..".txt", pon.encode({value}))
	
	-- Cache the data value here.
	nut.data.stored[key] = value

	return path
end

-- Gets a piece of information for NutScript.
function nut.data.get(key, default, global, ignoreMap, refresh)
	-- If it exists in the cache, return the cached value so it is faster.
	if (!refresh) then
		local stored = nut.data.stored[key]

		if (stored != nil) then
			return stored
		end
	end

	-- Get the path to read from.
	local path = "nutscript/"..(global and "" or SCHEMA.folder.."/")..(ignoreMap and "" or game.GetMap().."/")
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

-- Deletes existing data in nutscript framework.
function nut.data.delete(key, global, ignoreMap)
	-- Get the path to read from.
	local path = "nutscript/"..(global and "" or SCHEMA.folder.."/")..(ignoreMap and "" or game.GetMap().."/")
	-- Read the data from a local file.
	local contents = file.Read(path..key..".txt", "DATA")

	if (contents and contents != "") then
		file.Delete(path..key..".txt")
		nut.data.stored[key] = nil
		return true
	else
		-- If we provided a default, return that since we couldn't retrieve the data.
		return false
	end
end

timer.Create("nutSaveData", 600, 0, function()
	hook.Run("SaveData")
	hook.Run("PersistenceSave")
end)