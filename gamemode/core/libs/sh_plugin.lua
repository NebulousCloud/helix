nut.plugin = nut.plugin or {}
nut.plugin.list = nut.plugin.list or {}

function nut.plugin.load(uniqueID, path, isSingleFile, variable)
	if (hook.Run("PluginShouldLoad", uniqueID) == false) then return end

	variable = variable or "PLUGIN"

	-- Plugins within plugins situation?
	local oldPlugin = PLUGIN
	local PLUGIN = {folder = path, plugin = oldPlugin, uniqueID = uniqueID}

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
		nut.plugin.loadEntities(path.."/entities")

		hook.Run("DoPluginIncludes", path, PLUGIN)
	end

	hook.Run("PluginLoaded", uniqueID, PLUGIN)

	if (uniqueID != "schema") then
		nut.plugin.list[uniqueID] = PLUGIN
		_G[variable] = nil
	end
end

function nut.plugin.loadEntities(path)
	local files, folders

	local function IncludeFiles(path2, clientOnly)
		if (SERVER and file.Exists(path2.."init.lua", "LUA") or CLIENT) then
			nut.util.include(path2.."init.lua", clientOnly and "client" or "server")

			if (file.Exists(path2.."cl_init.lua", "LUA")) then
				nut.util.include(path2.."cl_init.lua", "client")
			end

			return true
		elseif (file.Exists(path2.."shared.lua", "LUA")) then
			nut.util.include(path2.."shared.lua")

			return true
		end

		return false
	end

	local function HandleEntityInclusion(folder, variable, register, default, clientOnly)
		files, folders = file.Find(path.."/"..folder.."/*", "LUA")
		default = default or {}

		for k, v in ipairs(folders) do
			local path2 = path.."/"..folder.."/"..v.."/"

			_G[variable] = default
				_G[variable].ClassName = v

				if (IncludeFiles(path2, clientOnly) and !client) then
					if (clientOnly) then
						if (CLIENT) then
							register(_G[variable], v)
						end
					else
						register(_G[variable], v)
					end
				end
			_G[variable] = nil
		end

		for k, v in ipairs(files) do
			local niceName = v:sub(4, -5)

			_G[variable] = default
				_G[variable].ClassName = niceName
				nut.util.include(path2..v, clientOnly and "client" or "shared")

				if (clientOnly) then
					if (CLIENT) then
						register(_G[variable], niceName)
					end
				else
					register(_G[variable], niceName)
				end
			_G[variable] = nil
		end
	end

	-- Include entities.
	HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
		Type = "anim",
		Base = "base_gmodentity",
		Spawnable = true
	})

	-- Include weapons.
	HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
		Primary = {},
		Secondary = {},
		Base = "weapon_base"
	})

	-- Include effects.
	HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)
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

function nut.plugin.unload(uniqueID)
	local plugin = nut.plugins.list[uniqueID]
		if (plugin.onUnload) then
			plugin:onUnload()
		end
	nut.plugins.list[uniqueID] = nil

	hook.Run("PluginUnloaded", uniqueID)
end

if (SERVER) then
	nut.plugin.repos = nut.plugin.repos or {}

	local function ThrowFault(fault)
		MsgN(fault)
	end

	function nut.plugin.loadRepo(url)
		http.Fetch(url, function(body)
			print(body)
		end)
	end

	function nut.plugin.download(repo, plugin)

	end
end

do
	hook.NutCall = hook.NutCall or hook.Call

	function hook.Call(name, gm, ...)
		for k, v in pairs(nut.plugin.list) do
			if (v[name]) then
				local result = {v[name](v, ...)}

				if (#result > 0) then
					return unpack(result)
				end
			end
		end

		if (SCHEMA and SCHEMA[name]) then
			local result = {SCHEMA[name](SCHEMA, ...)}

			if (#result > 0) then
				return unpack(result)
			end
		end

		return hook.NutCall(name, gm, ...)
	end
end