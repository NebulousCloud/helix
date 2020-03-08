
--[[--
Client-side configuration management.

The `option` library provides a cleaner way to manage any arbitrary data on the client without the hassle of managing CVars. It
is analagous to the `ix.config` library, but it only deals with data that needs to be stored on the client.

To get started, you'll need to define an option in a client realm so the framework can be aware of its existence. This can be
done in the `cl_init.lua` file of your schema, or in an `if (CLIENT) then` statement in the `sh_plugin.lua` file of your plugin:
	ix.option.Add("headbob", ix.type.bool, true)

If you need to get the value of an option on the server, you'll need to specify `true` for the `bNetworked` argument in
`ix.option.Add`. *NOTE:* You also need to define your option in a *shared* realm, since the server now also needs to be aware
of its existence. This makes it so that the client will send that option's value to the server whenever it changes, which then
means that the server can now retrieve the value that the client has the option set to. For example, if you need to get what
language a client is using, you can simply do the following:
	ix.option.Get(player.GetByID(1), "language", "english")

This will return the language of the player, or `"english"` if one isn't found. Note that `"language"` is a networked option
that is already defined in the framework, so it will always be available. All options will show up in the options menu on the
client, unless `hidden` returns `true` when using `ix.option.Add`.

Note that the labels for each option in the menu will use a language phrase to show the name. For example, if your option is
named `headbob`, then you'll need to define a language phrase called `optHeadbob` that will be used as the option title.
]]
-- @module ix.option

ix.option = ix.option or {}
ix.option.stored = ix.option.stored or {}
ix.option.categories = ix.option.categories or {}

--- Creates a client-side configuration option with the given information.
-- @realm shared
-- @string key Unique ID for this option
-- @ixtype optionType Type of this option
-- @param default Default value that this option will have - this can be nil if needed
-- @tparam OptionStructure data Additional settings for this option
-- @usage ix.option.Add("animationScale", ix.type.number, 1, {
-- 	category = "appearance",
-- 	min = 0.3,
-- 	max = 2,
-- 	decimals = 1
-- })
function ix.option.Add(key, optionType, default, data)
	assert(isstring(key) and key:find("%S"), "expected a non-empty string for the key")

	data = data or {}

	local categories = ix.option.categories
	local category = data.category or "misc"
	local upperName = key:sub(1, 1):upper() .. key:sub(2)

	categories[category] = categories[category] or {}
	categories[category][key] = true

	--- You can specify additional optional arguments for `ix.option.Add` by passing in a table of specific fields as the fourth
	-- argument.
	-- @table OptionStructure
	-- @realm shared
	-- @field[type=string,opt="opt" .. key] phrase The phrase to use when displaying in the UI. The default value is your option
	-- key in UpperCamelCase, prefixed with `"opt"`. For example, if your key is `"exampleOption"`, the default phrase will be
	-- `"optExampleOption"`.
	-- @field[type=string,opt="optd" .. key] description The phrase to use in the tooltip when hovered in the UI. The default
	-- value is your option key in UpperCamelCase, prefixed with `"optd"`. For example, if your key is `"exampleOption"`, the
	-- default phrase will be `"optdExampleOption"`.
	-- @field[type=string,opt="misc"] category The category that this option should reside in. This is purely for
	-- aesthetic reasons when displaying the options in the options menu. When displayed in the UI, it will take the form of
	-- `L("category name")`. This means that you must create a language phrase for the category name - otherwise it will only
	-- show as the exact string you've specified. If no category is set, it will default to `"misc"`.
	-- @field[type=number,opt=0] min The minimum allowed amount when setting this option. This field is not
	-- applicable to any type other than `ix.type.number`.
	-- @field[type=number,opt=10] max The maximum allowed amount when setting this option. This field is not
	-- applicable to any type other than `ix.type.number`.
	-- @field[type=number,opt=0] decimals How many decimals to constrain to when using a number type. This field is not
	-- applicable to any type other than `ix.type.number`.
	-- @field[type=boolean,opt=false] bNetworked Whether or not the server should be aware of this option for each client.
	-- @field[type=function,opt] OnChanged The function to run when this option is changed - this includes whether it was set
	-- by the player, or through code using `ix.option.Set`.
	-- 	OnChanged = function(oldValue, value)
	-- 		print("new value is", value)
	-- 	end
	-- @field[type=function,opt] hidden The function to check whether the option should be hidden from the options menu.
	-- @field[type=function,opt] populate The function to run when the option needs to be added to the menu. This is a required
	-- field for any array options. It should return a table of entries where the key is the value to set in `ix.option.Set`,
	-- and the value is the display name for the entry. An example:
	--
	-- 	populate = function()
	-- 		return {
	-- 			["english"] = "English",
	-- 			["french"] = "French",
	-- 			["spanish"] = "Spanish"
	-- 		}
	-- 	end
	ix.option.stored[key] = {
		key = key,
		phrase = "opt" .. upperName,
		description = "optd" .. upperName,
		type = optionType,
		default = default,
		min = data.min or 0,
		max = data.max or 10,
		decimals = data.decimals or 0,
		category = data.category or "misc",
		bNetworked = data.bNetworked and true or false,
		hidden = data.hidden or nil,
		populate = data.populate or nil,
		OnChanged = data.OnChanged or nil
	}
end

--- Loads all saved options from disk.
-- @realm shared
-- @internal
function ix.option.Load()
	ix.util.Include("helix/gamemode/config/sh_options.lua")

	if (CLIENT) then
		local options = ix.data.Get("options", nil, true, true)

		if (options) then
			for k, v in pairs(options) do
				ix.option.client[k] = v
			end
		end

		ix.option.Sync()
	end
end

--- Returns all of the available options. Note that this does contain the actual values of the options, just their properties.
-- @realm shared
-- @treturn table Table of all options
-- @usage PrintTable(ix.option.GetAll())
-- > language:
-- >	bNetworked = true
-- >	default = english
-- >	type = 512
-- -- etc.
function ix.option.GetAll()
	return ix.option.stored
end


--- Returns all of the available options grouped by their categories. The returned table contains category tables, that contain
-- all the options in that category as an array (this is so you can sort them if you'd like).
-- @realm shared
-- @bool[opt=false] bRemoveHidden Remove entries that are marked as hidden
-- @treturn table Table of all options
-- @usage PrintTable(ix.option.GetAllByCategories())
-- > general:
-- >	1:
-- >		key = language
-- >		bNetworked = true
-- >		default = english
-- >		type = 512
-- -- etc.
function ix.option.GetAllByCategories(bRemoveHidden)
	local result = {}

	for k, v in pairs(ix.option.categories) do
		for k2, _ in pairs(v) do
			local option = ix.option.stored[k2]

			if (bRemoveHidden and isfunction(option.hidden) and option.hidden()) then
				continue
			end

			-- we create the category table here because it could contain all hidden options which makes the table empty
			result[k] = result[k] or {}
			result[k][#result[k] + 1] = option
		end
	end

	return result
end

if (CLIENT) then
	ix.option.client = ix.option.client or {}

	--- Sets an option value for the local player.
	-- This function will error when an invalid key is passed.
	-- @realm client
	-- @string key Unique ID of the option
	-- @param value New value to assign to the option
	-- @bool[opt=false] bNoSave Whether or not to avoid saving
	function ix.option.Set(key, value, bNoSave)
		local option = assert(ix.option.stored[key], "invalid option key \"" .. tostring(key) .. "\"")

		if (option.type == ix.type.number) then
			value = math.Clamp(math.Round(value, option.decimals), option.min, option.max)
		end

		local oldValue = ix.option.client[key]
		ix.option.client[key] = value

		if (option.bNetworked) then
			net.Start("ixOptionSet")
				net.WriteString(key)
				net.WriteType(value)
			net.SendToServer()
		end

		if (!bNoSave) then
			ix.option.Save()
		end

		if (isfunction(option.OnChanged)) then
			option.OnChanged(oldValue, value)
		end
	end

	--- Retrieves an option value for the local player. If it is not set, it'll return the default that you've specified.
	-- @realm client
	-- @string key Unique ID of the option
	-- @param default Default value to return if the option is not set
	-- @return[1] Value associated with the key
	-- @return[2] The given default if the option is not set
	function ix.option.Get(key, default)
		local option = ix.option.stored[key]

		if (option) then
			local localValue = ix.option.client[key]

			if (localValue != nil) then
				return localValue
			end

			return option.default
		end

		return default
	end

	--- Saves all options to disk.
	-- @realm client
	-- @internal
	function ix.option.Save()
		ix.data.Set("options", ix.option.client, true, true)
	end

	--- Syncs all networked options to the server.
	-- @realm client
	function ix.option.Sync()
		local options = {}

		for k, v in pairs(ix.option.stored) do
			if (v.bNetworked) then
				options[#options + 1] = {k, ix.option.client[k]}
			end
		end

		if (#options > 0) then
			net.Start("ixOptionSync")
			net.WriteUInt(#options, 8)

			for _, v in ipairs(options) do
				net.WriteString(v[1])
				net.WriteType(v[2])
			end

			net.SendToServer()
		end
	end
else
	util.AddNetworkString("ixOptionSet")
	util.AddNetworkString("ixOptionSync")

	ix.option.clients = ix.option.clients or {}

	--- Retrieves an option value from the specified player. If it is not set, it'll return the default that you've specified.
	-- This function will error when an invalid player is passed.
	-- @realm server
	-- @player client Player to retrieve option value from
	-- @string key Unique ID of the option
	-- @param default Default value to return if the option is not set
	-- @return[1] Value associated with the key
	-- @return[2] The given default if the option is not set
	function ix.option.Get(client, key, default)
		assert(IsValid(client) and client:IsPlayer(), "expected valid player for argument #1")

		local option = ix.option.stored[key]

		if (option) then
			local clientOptions = ix.option.clients[client:SteamID64()]

			if (clientOptions) then
				local clientOption = clientOptions[key]

				if (clientOption != nil) then
					return clientOption
				end
			end

			return option.default
		end

		return default
	end

	-- sent whenever a client's networked option has changed
	net.Receive("ixOptionSet", function(length, client)
		local key = net.ReadString()
		local value = net.ReadType()

		local steamID = client:SteamID64()
		local option = ix.option.stored[key]

		if (option) then
			ix.option.clients[steamID] = ix.option.clients[steamID] or {}
			ix.option.clients[steamID][key] = value
		else
			ErrorNoHalt(string.format(
				"'%s' attempted to set option with invalid key '%s'\n", tostring(client) .. client:SteamID(), key
			))
		end
	end)

	-- sent on first load to sync all networked option values
	net.Receive("ixOptionSync", function(length, client)
		local indices = net.ReadUInt(8)
		local data = {}

		for _ = 1, indices do
			data[net.ReadString()] = net.ReadType()
		end

		local steamID = client:SteamID64()
		ix.option.clients[steamID] = ix.option.clients[steamID] or {}

		for k, v in pairs(data) do
			local option = ix.option.stored[k]

			if (option) then
				ix.option.clients[steamID][k] = v
			else
				return ErrorNoHalt(string.format(
					"'%s' attempted to sync option with invalid key '%s'\n", tostring(client) .. client:SteamID(), k
				))
			end
		end
	end)
end
