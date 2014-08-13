nut.data = nut.data or {}
nut.data.stored = nut.data.stored or {}

file.CreateDir("nutscript")

function nut.data.set(key, value, global, ignoreMap)
	local path = "nutscript/"..(global and "" or SCHEMA.folder.."/")..(ignoreMap and "" or game.GetMap().."/")

	file.CreateDir("nutscript/"..(global and "" or SCHEMA.folder.."/"))
	file.CreateDir(path)
	file.Write(path..key..".txt", pon.encode({value}))
	
	nut.data.stored[key] = value
end

function nut.data.get(key, default, global, ignoreMap, refresh)
	if (!refresh) then
		local stored = nut.data.stored[key]

		if (stored != nil) then
			return stored
		end
	end

	local path = "nutscript/"..(global and "" or SCHEMA.folder.."/")..(ignoreMap and "" or game.GetMap().."/")
	local contents = file.Read(path..key..".txt", "DATA")

	if (contents and contents != "") then
		local decoded = pon.decode(contents)
		local value = decoded[1]

		if (value != nil) then
			return value
		else
			return default
		end
	else
		return default
	end
end