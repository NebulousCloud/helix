nut.plugin = nut.plugin or {}
nut.plugin.list = nut.plugin.list or {}

function nut.plugin.load(uniqueID, path, isSingleFile, variable)
	variable = variable or "PLUGIN"

	local PLUGIN = {folder = path}

	if (uniqueID == "schema") then
		if (SCHEMA) then
			PLUGIN = SCHEMA
		end

		variable = "SCHEMA"
		PLUGIN.folder = engine.ActiveGamemode()
	elseif (nut.plugin.list[uniqueID]) then
		PLUGIN = nut.plugin.list[uniqueID]
	end

	_G[variable] = PLUGIN
	nut.util.include(isSingleFile and path or path.."/sh_"..variable:lower()..".lua", "shared")

	if (!isSingleFile) then
		nut.lang.loadFromDir(path.."/languages")
		nut.util.includeDir(path.."/libs")
		nut.attribs.loadFromDir(path.."/attributes")
		nut.faction.loadFromDir(path.."/factions")
		nut.item.loadFromDir(path.."/items")
		nut.plugin.loadFromDir(path.."/plugins")
		nut.util.includeDir(path.."/derma")
	end

	if (uniqueID != "schema") then
		nut.plugin.list[uniqueID] = PLUGIN
		_G[variable] = nil
	end
end

function nut.plugin.initialize()
	nut.plugin.load("schema", engine.ActiveGamemode().."/schema")
	hook.Run("InitializedSchema")

	nut.plugin.loadFromDir(engine.ActiveGamemode().."/plugins")
	nut.plugin.loadFromDir("nutscript/plugins")
	hook.Run("InitializedPlugins")
end

function nut.plugin.loadFromDir(directory)
	local files, folders = file.Find(directory.."/*", "LUA")

	for k, v in ipairs(folders) do
		nut.plugin.load(v, directory.."/"..v)
	end

	for k, v in ipairs(files) do
		nut.plugin.load(v, directory.."/"..v, true)
	end
end