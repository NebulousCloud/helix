nut.plugin = nut.plugin or {}
nut.plugin.list = nut.plugin.list or {}
nut.plugin.unloaded = nut.plugin.unloaded or {}

HOOKS_CACHE = {}

function nut.plugin.load(uniqueID, path, isSingleFile, variable)
	if (hook.Run("PluginShouldLoad", uniqueID) == false) then return end

	variable = variable or "PLUGIN"

	-- Plugins within plugins situation?
	local oldPlugin = PLUGIN
	local PLUGIN = {folder = path, plugin = oldPlugin, uniqueID = uniqueID, name = "Unknown", desc = "Description not available", author = "Anonymous"}

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
	PLUGIN.loading = true

	if (!isSingleFile) then
		nut.lang.loadFromDir(path.."/languages")
		nut.util.includeDir(path.."/libs", true)
		nut.attribs.loadFromDir(path.."/attributes")
		nut.faction.loadFromDir(path.."/factions")
		nut.class.loadFromDir(path.."/classes")
		nut.item.loadFromDir(path.."/items")
		nut.plugin.loadFromDir(path.."/plugins")
		nut.util.includeDir(path.."/derma", true)
		nut.plugin.loadEntities(path.."/entities")

		hook.Run("DoPluginIncludes", path, PLUGIN)
	end
	
	nut.util.include(isSingleFile and path or path.."/sh_"..variable:lower()..".lua", "shared")
	PLUGIN.loading = false

	local uniqueID2 = uniqueID

	if (uniqueID2 == "schema") then
		uniqueID2 = PLUGIN.name
	end

	function PLUGIN:setData(value, global, ignoreMap)
		nut.data.set(uniqueID2, value, global, ignoreMap)
	end

	function PLUGIN:getData(default, global, ignoreMap, refresh)
		return nut.data.get(uniqueID2, default, global, ignoreMap, refresh) or {}
	end

	hook.Run("PluginLoaded", uniqueID, PLUGIN)

	if (uniqueID != "schema") then
		PLUGIN.name = PLUGIN.name or "Unknown"
		PLUGIN.desc = PLUGIN.desc or "No description available."

		for k, v in pairs(PLUGIN) do
			if (type(v) == "function") then
				HOOKS_CACHE[k] = HOOKS_CACHE[k] or {}
				HOOKS_CACHE[k][PLUGIN] = v
			end
		end

		nut.plugin.list[uniqueID] = PLUGIN
		_G[variable] = nil
	end

	if (PLUGIN.OnLoaded) then
		PLUGIN:OnLoaded()
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

			_G[variable] = table.Copy(default)
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
			local niceName = string.StripExtension(v)

			_G[variable] = table.Copy(default)
				_G[variable].ClassName = niceName
				nut.util.include(path.."/"..folder.."/"..v, clientOnly and "client" or "shared")

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
		nut.plugin.load(string.StripExtension(v), directory.."/"..v, true)
	end
end

function nut.plugin.setUnloaded(uniqueID, state, noSave)
	local plugin = nut.plugins.list[uniqueID]

	if (state) then
		if (plugin.onLoaded) then
			plugin:onLoaded()
		end

		if (nut.plugin.unloaded[uniqueID]) then
			nut.plugin.list[uniqueID] = nut.plugin.unloaded[uniqueID]
			nut.plugin.unloaded[uniqueID] = nil
		else
			return false
		end
	elseif (plugin) then
		if (plugin.onUnload) then
			plugin:onUnload()
		end

		nut.plugin.unloaded[uniqueID] = nut.plugin.list[uniqueID]
		nut.plugin.list[uniqueID] = nil
	else
		return false
	end

	if (SERVER and !noSave) then
		local status

		if (state) then
			status = true
		end

		local unloaded = nut.data.get("unloaded", {}, true, true)
			unloaded[uniqueID] = status
		nut.data.set("unloaded", unloaded, true, true)
	end

	hook.Run("PluginUnloaded", uniqueID)

	return true
end

if (SERVER) then
	nut.plugin.repos = nut.plugin.repos or {}
	nut.plugin.files = nut.plugin.files or {}
	
	local function ThrowFault(fault)
		MsgN(fault)
	end

	function nut.plugin.loadRepo(url, name, callback, faultCallback)
		name = name or url

		local curPlugin = ""
		local curPluginName = ""
		local cache = {data = {url = url}, files = {}}

		MsgN("Loading plugins from '"..url.."'")

		http.Fetch(url, function(body)
			if (body:find("<h1>")) then
				local fault = body:match("<h1>([_%w%s]+)</h1>") or "Unknown Error"

				if (faultCallback) then
					faultCallback(fault)
				end

				return MsgN("\t* ERROR: "..fault)
			end

			local exploded = string.Explode("\n", body)

			print("   * Repository identifier set to '"..name.."'")

			for k, line in ipairs(exploded) do
				if (line:sub(1, 1) == "@") then
					local key, value = line:match("@repo%-([_%w]+):[%s*](.+)")

					if (key and value) then
						if (key == "name") then
							print("   * "..value)
						end

						cache.data[key] = value
					end
				else
					local name = line:match("!%b[]")

					if (name) then
						curPlugin = name:sub(3, -2)
						name = name:sub(8, -2)
						curPluginName = name
						cache.files[name] = {}

						MsgN("\t* Found '"..name.."'")
					elseif (curPlugin and line:sub(1, #curPlugin) == curPlugin and cache.files[curPluginName]) then
						table.insert(cache.files[curPluginName], line:sub(#curPlugin + 2))
					end
				end
			end

			file.CreateDir("nutscript/plugins")
			file.CreateDir("nutscript/plugins/"..cache.data.id)

			if (callback) then
				callback(cache)
			end

			nut.plugin.repos[name] = cache
		end, function(fault)
			if (faultCallback) then
				faultCallback(fault)
			end

			MsgN("\t* ERROR: "..fault)
		end)
	end

	function nut.plugin.download(repo, plugin, callback)
		local plugins = nut.plugin.repos[repo]

		if (plugins) then
			if (plugins.files[plugin]) then
				local files = plugins.files[plugin]
				local baseDir = "nutscript/plugins/"..plugins.data.id.."/"..plugin.."/"

				-- Re-create the old file.Write behavior.
				local function WriteFile(name, contents)
					name = string.StripExtension(name)..".txt"

					if (name:find("/")) then
						local exploded = string.Explode("/", name)
						local tree = ""

						for k, v in ipairs(exploded) do
							if (k == #exploded) then
								file.Write(baseDir..tree..v, contents)
							else
								tree = tree..v.."/"
								file.CreateDir(baseDir..tree)
							end
						end
					else
						file.Write(baseDir..name, contents)
					end
				end

				MsgN("* Downloading plugin '"..plugin.."' from '"..repo.."'")
				nut.plugin.files[repo.."/"..plugin] = {}

				local function DownloadFile(i)
					MsgN("\t* Downloading... "..(math.Round(i / #files, 2) * 100).."%")

					local url = plugins.data.url.."/repo/"..plugin.."/"..files[i]

					http.Fetch(url, function(body)
						WriteFile(files[i], body)
						nut.plugin.files[repo.."/"..plugin][files[i]] = body

						if (i < #files) then
							DownloadFile(i + 1)
						else
							if (callback) then
								callback(true)
							end

							MsgN("* '"..plugin.."' has completed downloading")
						end
					end, function(fault)
						callback(false, fault)
					end)
				end

				DownloadFile(1)
			else
				return false, "cloud_no_plugin"
			end
		else
			return false, "cloud_no_repo"
		end
	end

	function nut.plugin.loadFromLocal(repo, plugin)

	end

	concommand.Add("nut_cloudloadrepo", function(client, _, arguments)
		local url = arguments[1]
		local name = arguments[2] or "default"

		if (!IsValid(client)) then
			nut.plugin.loadRepo(url, name)
		end
	end)

	concommand.Add("nut_cloudget", function(client, _, arguments)
		if (!IsValid(client)) then
			local status, result = nut.plugin.download(arguments[2] or "default", arguments[1])

			if (status == false) then
				MsgN("* ERROR: "..result)
			end
		end
	end)
end

do
	hook.NutCall = hook.NutCall or hook.Call

	function hook.Call(name, gm, ...)
		local cache = HOOKS_CACHE[name]

		if (cache) then
			for k, v in pairs(cache) do
				local result = {v(k, ...)}

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
