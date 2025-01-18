
ix.plugin = ix.plugin or {}
ix.plugin.list = ix.plugin.list or {}
ix.plugin.unloaded = ix.plugin.unloaded or {}

ix.util.Include("helix/gamemode/core/meta/sh_tool.lua")

-- luacheck: globals HOOKS_CACHE
HOOKS_CACHE = {}

function ix.plugin.Load(uniqueID, path, isSingleFile, variable)
	if (hook.Run("PluginShouldLoad", uniqueID) == false) then return end

	variable = variable or "PLUGIN"

	-- Plugins within plugins situation?
	local oldPlugin = PLUGIN
	local PLUGIN = {
		folder = path,
		plugin = oldPlugin,
		uniqueID = uniqueID,
		name = "Unknown",
		description = "Description not available",
		author = "Anonymous"
	}

	if (uniqueID == "schema") then
		if (Schema) then
			PLUGIN = Schema
		end

		variable = "Schema"
		PLUGIN.folder = engine.ActiveGamemode()
	elseif (ix.plugin.list[uniqueID]) then
		PLUGIN = ix.plugin.list[uniqueID]
	end

	_G[variable] = PLUGIN
	PLUGIN.loading = true

	if (!isSingleFile) then
		ix.lang.LoadFromDir(path.."/languages")
		ix.util.IncludeDir(path.."/libs", true)
		ix.attributes.LoadFromDir(path.."/attributes")
		ix.faction.LoadFromDir(path.."/factions")
		ix.class.LoadFromDir(path.."/classes")
		ix.item.LoadFromDir(path.."/items")
		ix.plugin.LoadFromDir(path.."/plugins")
		ix.util.IncludeDir(path.."/derma", true)
		ix.plugin.LoadEntities(path.."/entities")

		hook.Run("DoPluginIncludes", path, PLUGIN)
	end

	ix.util.Include(isSingleFile and path or path.."/sh_"..variable:lower()..".lua", "shared")
	PLUGIN.loading = false

	local uniqueID2 = uniqueID

	if (uniqueID2 == "schema") then
		uniqueID2 = PLUGIN.name
	end

	function PLUGIN:SetData(value, global, ignoreMap)
		ix.data.Set(uniqueID2, value, global, ignoreMap)
	end

	function PLUGIN:GetData(default, global, ignoreMap, refresh)
		return ix.data.Get(uniqueID2, default, global, ignoreMap, refresh) or {}
	end

	hook.Run("PluginLoaded", uniqueID, PLUGIN)

	if (uniqueID != "schema") then
		PLUGIN.name = PLUGIN.name or "Unknown"
		PLUGIN.description = PLUGIN.description or "No description available."

		for k, v in pairs(PLUGIN) do
			if (isfunction(v)) then
				HOOKS_CACHE[k] = HOOKS_CACHE[k] or {}
				HOOKS_CACHE[k][PLUGIN] = v
			end
		end

		ix.plugin.list[uniqueID] = PLUGIN
		_G[variable] = oldPlugin
	end

	if (PLUGIN.OnLoaded) then
		PLUGIN:OnLoaded()
	end
end

function ix.plugin.GetHook(pluginName, hookName)
	local h = HOOKS_CACHE[hookName]

	if (h) then
		local p = ix.plugin.list[pluginName]

		if (p) then
			return h[p]
		end
	end

	return
end

function ix.plugin.LoadEntities(path)
	local bLoadedTools
	local files, folders

	local function IncludeFiles(path2, bClientOnly)
		if (SERVER and !bClientOnly) then
			if (file.Exists(path2.."init.lua", "LUA")) then
				ix.util.Include(path2.."init.lua", "server")
			elseif (file.Exists(path2.."shared.lua", "LUA")) then
				ix.util.Include(path2.."shared.lua")
			end

			if (file.Exists(path2.."cl_init.lua", "LUA")) then
				ix.util.Include(path2.."cl_init.lua", "client")
			end
		elseif (file.Exists(path2.."cl_init.lua", "LUA")) then
			ix.util.Include(path2.."cl_init.lua", "client")
		elseif (file.Exists(path2.."shared.lua", "LUA")) then
			ix.util.Include(path2.."shared.lua")
		end
	end

	local function HandleEntityInclusion(folder, variable, register, default, clientOnly, create, complete)
		files, folders = file.Find(path.."/"..folder.."/*", "LUA")
		default = default or {}

		for _, v in ipairs(folders) do
			local path2 = path.."/"..folder.."/"..v.."/"
			v = ix.util.StripRealmPrefix(v)

			_G[variable] = table.Copy(default)

			if (!isfunction(create)) then
				_G[variable].ClassName = v
			else
				create(v)
			end

			IncludeFiles(path2, clientOnly)

			if (clientOnly) then
				if (CLIENT) then
					register(_G[variable], v)
				end
			else
				register(_G[variable], v)
			end

			if (isfunction(complete)) then
				complete(_G[variable])
			end

			_G[variable] = nil
		end

		for _, v in ipairs(files) do
			local niceName = ix.util.StripRealmPrefix(string.StripExtension(v))

			_G[variable] = table.Copy(default)

			if (!isfunction(create)) then
				_G[variable].ClassName = niceName
			else
				create(niceName)
			end

			ix.util.Include(path.."/"..folder.."/"..v, clientOnly and "client" or "shared")

			if (clientOnly) then
				if (CLIENT) then
					register(_G[variable], niceName)
				end
			else
				register(_G[variable], niceName)
			end

			if (isfunction(complete)) then
				complete(_G[variable])
			end

			_G[variable] = nil
		end
	end

	local function RegisterTool(tool, className)
		local gmodTool = weapons.GetStored("gmod_tool")

		if (className:sub(1, 3) == "sh_") then
			className = className:sub(4)
		end

		if (gmodTool) then
			gmodTool.Tool[className] = tool
		else
			-- this should never happen
			ErrorNoHalt(string.format("attempted to register tool '%s' with invalid gmod_tool weapon", className))
		end

		bLoadedTools = true
	end

	-- Include entities.
	HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
		Type = "anim",
		Base = "base_gmodentity",
		Spawnable = true
	}, false, nil, function(ent)
		if (SERVER and ent.Holdable == true) then
			ix.allowedHoldableClasses[ent.ClassName] = true
		end
	end)

	-- Include weapons.
	HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
		Primary = {},
		Secondary = {},
		Base = "weapon_base"
	})

	HandleEntityInclusion("tools", "TOOL", RegisterTool, {}, false, function(className)
		if (className:sub(1, 3) == "sh_") then
			className = className:sub(4)
		end

		TOOL = ix.meta.tool:Create()
		TOOL.Mode = className
		TOOL:CreateConVars()
	end)

	-- Include effects.
	HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)

	-- only reload spawn menu if any new tools were registered
	if (CLIENT and bLoadedTools) then
		RunConsoleCommand("spawnmenu_reload")
	end
end

function ix.plugin.Initialize()
	if SERVER then
		ix.plugin.unloaded = ix.data.Get("unloaded", {}, true, true)
	end

	ix.plugin.LoadFromDir("helix/plugins")

	ix.plugin.Load("schema", engine.ActiveGamemode().."/schema")
	hook.Run("InitializedSchema")

	ix.plugin.LoadFromDir(engine.ActiveGamemode().."/plugins")
	hook.Run("InitializedPlugins")
end

function ix.plugin.Get(identifier)
	return ix.plugin.list[identifier]
end

function ix.plugin.LoadFromDir(directory)
	local files, folders = file.Find(directory.."/*", "LUA")

	for _, v in ipairs(folders) do
		ix.plugin.Load(v, directory.."/"..v)
	end

	for _, v in ipairs(files) do
		ix.plugin.Load(string.StripExtension(v), directory.."/"..v, true)
	end
end

function ix.plugin.SetUnloaded(uniqueID, state, bNoSave)
	local plugin = ix.plugin.list[uniqueID]

	if (state) then
		if (plugin and plugin.OnUnload) then
			plugin:OnUnload()
		end

		ix.plugin.unloaded[uniqueID] = true
	elseif (ix.plugin.unloaded[uniqueID]) then
		ix.plugin.unloaded[uniqueID] = false
	else
		return false
	end

	if (SERVER and !bNoSave) then
		local status

		if (state) then
			status = true
		end

		local unloaded = ix.data.Get("unloaded", {}, true, true)
			unloaded[uniqueID] = status
		ix.data.Set("unloaded", unloaded, true, true)
	end

	if (state) then
		hook.Run("PluginUnloaded", uniqueID)
	end

	return true
end

if (SERVER) then
	--- Runs the `LoadData` and `PostLoadData` hooks for the gamemode, schema, and plugins. Any plugins that error during the
	-- hook will have their `SaveData` and `PostLoadData` hooks removed to prevent them from saving junk data.
	-- @internal
	-- @realm server
	function ix.plugin.RunLoadData()
		local errors = hook.SafeRun("LoadData")

		-- remove the SaveData and PostLoadData hooks for any plugins that error during LoadData since they would probably be
		-- saving bad data. this doesn't prevent plugins from saving data via other means, but there's only so much we can do
		for _, v in pairs(errors or {}) do
			if (v.plugin) then
				local plugin = ix.plugin.Get(v.plugin)

				if (plugin) then
					local saveDataHooks = HOOKS_CACHE["SaveData"] or {}
					saveDataHooks[plugin] = nil

					local postLoadDataHooks = HOOKS_CACHE["PostLoadData"] or {}
					postLoadDataHooks[plugin] = nil
				end
			end
		end

		hook.Run("PostLoadData")
	end
end

do
	-- luacheck: globals hook
	hook.ixCall = hook.ixCall or hook.Call

	function hook.Call(name, gm, ...)
		local cache = HOOKS_CACHE[name]

		if (cache) then
			for k, v in pairs(cache) do
				local a, b, c, d, e, f = v(k, ...)

				if (a != nil) then
					return a, b, c, d, e, f
				end
			end
		end

		if (Schema and Schema[name]) then
			local a, b, c, d, e, f = Schema[name](Schema, ...)

			if (a != nil) then
				return a, b, c, d, e, f
			end
		end

		return hook.ixCall(name, gm, ...)
	end

	--- Runs the given hook in a protected call so that the calling function will continue executing even if any errors occur
	-- while running the hook. This function is much more expensive to call than `hook.Run`, so you should avoid using it unless
	-- you absolutely need to avoid errors from stopping the execution of your function.
	-- @internal
	-- @realm shared
	-- @string name Name of the hook to run
	-- @param ... Arguments to pass to the hook functions
	-- @treturn[1] table Table of error data if an error occurred while running
	-- @treturn[1] ... Any arguments returned by the hook functions
	-- @usage local errors, bCanSpray = hook.SafeRun("PlayerSpray", Entity(1))
	-- if (!errors) then
	-- 	-- do stuff with bCanSpray
	-- else
	-- 	PrintTable(errors)
	-- end
	function hook.SafeRun(name, ...)
		local errors = {}
		local gm = gmod and gmod.GetGamemode() or nil
		local cache = HOOKS_CACHE[name]

		if (cache) then
			for k, v in pairs(cache) do
				local bSuccess, a, b, c, d, e, f = pcall(v, k, ...)

				if (bSuccess) then
					if (a != nil) then
						return errors, a, b, c, d, e, f
					end
				else
					ErrorNoHalt(string.format("[Helix] hook.SafeRun error for plugin hook \"%s:%s\":\n\t%s\n%s\n",
						tostring(k and k.uniqueID or nil), tostring(name), tostring(a), debug.traceback()))

					errors[#errors + 1] = {
						name = name,
						plugin = k and k.uniqueID or nil,
						errorMessage = tostring(a)
					}
				end
			end
		end

		if (Schema and Schema[name]) then
			local bSuccess, a, b, c, d, e, f = pcall(Schema[name], Schema, ...)

			if (bSuccess) then
				if (a != nil) then
					return errors, a, b, c, d, e, f
				end
			else
				ErrorNoHalt(string.format("[Helix] hook.SafeRun error for schema hook \"%s\":\n\t%s\n%s\n",
					tostring(name), tostring(a), debug.traceback()))

				errors[#errors + 1] = {
					name = name,
					schema = Schema.name,
					errorMessage = tostring(a)
				}
			end
		end

		local bSuccess, a, b, c, d, e, f = pcall(hook.ixCall, name, gm, ...)

		if (bSuccess) then
			return errors, a, b, c, d, e, f
		else
			ErrorNoHalt(string.format("[Helix] hook.SafeRun error for gamemode hook \"%s\":\n\t%s\n%s\n",
				tostring(name), tostring(a), debug.traceback()))

			errors[#errors + 1] = {
				name = name,
				gamemode = "gamemode",
				errorMessage = tostring(a)
			}

			return errors
		end
	end
end
