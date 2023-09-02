
--- Helper library for creating/setting config options.
-- @module ix.config

ix.config = ix.config or {}
ix.config.stored = ix.config.stored or {}

if (SERVER) then
	util.AddNetworkString("ixConfigList")
	util.AddNetworkString("ixConfigSet")
	util.AddNetworkString("ixConfigRequestUnloadedList")
	util.AddNetworkString("ixConfigUnloadedList")
	util.AddNetworkString("ixConfigPluginToggle")

	ix.config.server = ix.yaml.Read("gamemodes/helix/helix.yml") or {}
end

CAMI.RegisterPrivilege({
	Name = "Helix - Manage Config",
	MinAccess = "superadmin"
})

--- Creates a config option with the given information.
-- @realm shared
-- @string key Unique ID of the config
-- @param value Default value that this config will have
-- @string description Description of the config
-- @func[opt=nil] callback Function to call when config is changed
-- @tab[opt=nil] data Additional settings for this config option
-- @bool[opt=false] bNoNetworking Whether or not to prevent networking the config
-- @bool[opt=false] bSchemaOnly Whether or not the config is for the schema only
function ix.config.Add(key, value, description, callback, data, bNoNetworking, bSchemaOnly)
	data = istable(data) and data or {}

	local oldConfig = ix.config.stored[key]
	local type = data.type or ix.util.GetTypeFromValue(value)

	if (!type) then
		ErrorNoHalt("attempted to add config with invalid type\n")
		return
	end

	local default = value
	data.type = nil

	-- using explicit nil comparisons so we don't get caught by a config's value being `false`
	if (oldConfig != nil) then
		if (oldConfig.value != nil) then
			value = oldConfig.value
		end

		if (oldConfig.default != nil) then
			default = oldConfig.default
		end
	end

	ix.config.stored[key] = {
		type = type,
		data = data,
		value = value,
		default = default,
		description = description,
		bNoNetworking = bNoNetworking,
		global = !bSchemaOnly,
		callback = callback,
		hidden = data.hidden or nil
	}
end

--- Sets the default value for a config option.
-- @realm shared
-- @string key Unique ID of the config
-- @param value Default value for the config option
function ix.config.SetDefault(key, value)
	local config = ix.config.stored[key]

	if (config) then
		config.default = value
	else
		-- set up dummy config if we're setting default of config that doesn't exist yet (i.e schema setting framework default)
		ix.config.stored[key] = {
			value = value,
			default = value
		}
	end
end

function ix.config.ForceSet(key, value, noSave)
	local config = ix.config.stored[key]

	if (config) then
		config.value = value
	end

	if (noSave) then
		ix.config.Save()
	end
end

--- Sets the value of a config option.
-- @realm shared
-- @string key Unique ID of the config
-- @param value New value to assign to the config
function ix.config.Set(key, value)
	local config = ix.config.stored[key]

	if (config) then
		local oldValue = value
		config.value = value

		if (SERVER) then
			if (!config.bNoNetworking) then
				net.Start("ixConfigSet")
					net.WriteString(key)
					net.WriteType(value)
				net.Broadcast()
			end

			if (config.callback) then
				config.callback(oldValue, value)
			end

			ix.config.Save()
		end
	end
end

--- Retrieves a value of a config option. If it is not set, it'll return the default that you've specified.
-- @realm shared
-- @string key Unique ID of the config
-- @param default Default value to return if the config is not set
-- @return Value associated with the key, or the default that was given if it doesn't exist
function ix.config.Get(key, default)
	local config = ix.config.stored[key]

	-- ensure we aren't accessing a dummy value
	if (config and config.type) then
		if (config.value != nil) then
			return config.value
		elseif (config.default != nil) then
			return config.default
		end
	end

	return default
end

--- Loads all saved config options from disk.
-- @realm shared
-- @internal
function ix.config.Load()
	if (SERVER) then
		local globals = ix.data.Get("config", nil, true, true)
		local data = ix.data.Get("config", nil, false, true)

		if (globals) then
			for k, v in pairs(globals) do
				ix.config.stored[k] = ix.config.stored[k] or {}
				ix.config.stored[k].value = v
			end
		end

		if (data) then
			for k, v in pairs(data) do
				ix.config.stored[k] = ix.config.stored[k] or {}
				ix.config.stored[k].value = v
			end
		end
	end

	ix.util.Include("helix/gamemode/config/sh_config.lua")

	if (SERVER or !IX_RELOADED) then
		hook.Run("InitializedConfig")
	end
end

if (SERVER) then
	function ix.config.GetChangedValues()
		local data = {}

		for k, v in pairs(ix.config.stored) do
			if (v.default != v.value) then
				data[k] = v.value
			end
		end

		return data
	end

	function ix.config.Send(client)
		net.Start("ixConfigList")
			net.WriteTable(ix.config.GetChangedValues())
		net.Send(client)
	end

	--- Saves all config options to disk.
	-- @realm server
	-- @internal
	function ix.config.Save()
		local globals = {}
		local data = {}

		for k, v in pairs(ix.config.GetChangedValues()) do
			if (ix.config.stored[k].global) then
				globals[k] = v
			else
				data[k] = v
			end
		end

		-- Global and schema data set respectively.
		ix.data.Set("config", globals, true, true)
		ix.data.Set("config", data, false, true)
	end

	net.Receive("ixConfigSet", function(length, client)
		local key = net.ReadString()
		local value = net.ReadType()

		if (CAMI.PlayerHasAccess(client, "Helix - Manage Config", nil) and
			type(ix.config.stored[key].default) == type(value)) then
			ix.config.Set(key, value)

			if (ix.util.IsColor(value)) then
				value = string.format("[%d, %d, %d]", value.r, value.g, value.b)
			elseif (istable(value)) then
				local value2 = "["
				local count = table.Count(value)
				local i = 1

				for _, v in SortedPairs(value) do
					value2 = value2 .. v .. (i == count and "]" or ", ")
					i = i + 1
				end

				value = value2
			elseif (isstring(value)) then
				value = string.format("\"%s\"", tostring(value))
			elseif (isbool(value)) then
				value = string.format("[%s]", tostring(value))
			end

			ix.util.NotifyLocalized("cfgSet", nil, client:Name(), key, tostring(value))
			ix.log.Add(client, "cfgSet", key, value)
		end
	end)

	net.Receive("ixConfigRequestUnloadedList", function(length, client)
		if (!CAMI.PlayerHasAccess(client, "Helix - Manage Config", nil)) then
			return
		end

		net.Start("ixConfigUnloadedList")
			net.WriteTable(ix.plugin.unloaded)
		net.Send(client)
	end)

	net.Receive("ixConfigPluginToggle", function(length, client)
		if (!CAMI.PlayerHasAccess(client, "Helix - Manage Config", nil)) then
			return
		end

		local uniqueID = net.ReadString()
		local bUnloaded = !!ix.plugin.unloaded[uniqueID]
		local bShouldEnable = net.ReadBool()

		if ((bShouldEnable and bUnloaded) or (!bShouldEnable and !bUnloaded)) then
			ix.plugin.SetUnloaded(uniqueID, !bShouldEnable) -- flip bool since we're setting unloaded, not enabled

			ix.util.NotifyLocalized(bShouldEnable and "pluginLoaded" or "pluginUnloaded", nil, client:GetName(), uniqueID)
			ix.log.Add(client, bShouldEnable and "pluginLoaded" or "pluginUnloaded", uniqueID)

			net.Start("ixConfigPluginToggle")
				net.WriteString(uniqueID)
				net.WriteBool(bShouldEnable)
			net.Broadcast()
		end
	end)
else
	net.Receive("ixConfigList", function()
		local data = net.ReadTable()

		for k, v in pairs(data) do
			if (ix.config.stored[k]) then
				ix.config.stored[k].value = v
			end
		end

		hook.Run("InitializedConfig", data)
	end)

	net.Receive("ixConfigSet", function()
		local key = net.ReadString()
		local value = net.ReadType()
		local config = ix.config.stored[key]

		if (config) then
			if (config.callback) then
				config.callback(config.value, value)
			end

			config.value = value

			local properties = ix.gui.properties

			if (IsValid(properties)) then
				local row = properties:GetCategory(L(config.data and config.data.category or "misc")):GetRow(key)

				if (IsValid(row)) then
					if (istable(value) and value.r and value.g and value.b) then
						value = Vector(value.r / 255, value.g / 255, value.b / 255)
					end

					row:SetValue(value)
				end
			end
		end
	end)

	net.Receive("ixConfigUnloadedList", function()
		ix.plugin.unloaded = net.ReadTable()
		ix.gui.bReceivedUnloadedPlugins = true

		if (IsValid(ix.gui.pluginManager)) then
			ix.gui.pluginManager:UpdateUnloaded()
		end
	end)

	net.Receive("ixConfigPluginToggle", function()
		local uniqueID = net.ReadString()
		local bEnabled = net.ReadBool()

		if (bEnabled) then
			ix.plugin.unloaded[uniqueID] = false
		else
			ix.plugin.unloaded[uniqueID] = true
		end

		if (IsValid(ix.gui.pluginManager)) then
			ix.gui.pluginManager:UpdatePlugin(uniqueID, bEnabled)
		end
	end)

	hook.Add("CreateMenuButtons", "ixConfig", function(tabs)
		if (!CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Manage Config", nil)) then
			return
		end

		tabs["config"] = {
			Create = function(info, container)
				container.panel = container:Add("ixConfigManager")
			end,

			OnSelected = function(info, container)
				container.panel.searchEntry:RequestFocus()
			end,

			Sections = {
				plugins = {
					Create = function(info, container)
						ix.gui.pluginManager = container:Add("ixPluginManager")
					end,

					OnSelected = function(info, container)
						ix.gui.pluginManager.searchEntry:RequestFocus()
					end
				}
			}
		}
	end)
end
