
--[[--
Client-side configuration management.

The `option` library provides a cleaner way to manage any arbitrary data on the client without the hassle of managing CVars. It
is analagous to the `ix.config` library, but it only deals with data that needs to be stored on the client.

To get started, you'll need to define an option in a shared realm so the framework can be aware of its existence. This can be
done in the `shared.lua` file of your schema, or `sh_plugin.lua` file of your plugin:
	ix.option.Add("headbob", true)

If you need to get the value of an option on the server, you'll need to specify `true` for the `bNetworked` argument in
`ix.option.Add`. This makes it so that the client will send that option's value to the server whenever it changes, which then
means that the server can now retrieve the value that the client has the option set to. For example, if you need to get what
language a client is using, you can simply do the following:
	ix.option.Get(player.GetByID(1), "language", "english")

This will return the language of the player, or `"english"` if one isn't found. Note that `"language"` is a networked option
that is already defined in the framework, so it will always be available.
]]
-- @module ix.option

ix.option = ix.option or {}
ix.option.stored = ix.option.stored or {}

--- Creates a client-side configuration option with the given information.
-- @shared
-- @string key Unique ID for this option
-- @param default Default value that this option will have
-- @bool[opt=false] bNetworked Whether or not the server should know about this option for each client
function ix.option.Add(key, default, bNetworked)
	ix.option.stored[key] = {
		default = default,
		bNetworked = bNetworked and true or false
	}
end

--- Loads all saved options from disk. This is an internal function and shouldn't be used!
-- @shared
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

if (CLIENT) then
	ix.option.client = ix.option.client or {}

	--- Sets an option value for the local player.
	-- This function will error when an invalid key is passed.
	-- @client
	-- @string key Unique ID of the option
	-- @param value New value to assign to the option
	-- @bool[opt=false] bNoSave Whether or not to avoid saving
	function ix.option.Set(key, value, bNoSave)
		local option = assert(ix.option.stored[key], "expected valid option key")

		ix.option.client[key] = value

		if (option.bNetworked) then
			netstream.Start("ixOptionSet", key, value)
		end

		if (!bNoSave) then
			ix.option.Save()
		end
	end

	--- Retrieves an option value for the local player. If it is not set, it'll return the default that you've specified.
	-- @client
	-- @string key Unique ID of the option
	-- @param default Default value to return if the option is not set
	-- @return Value associated with the key, or the default that was given if it doesn't exists
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

	--- Saves all options to disk. This is an internal function and shouldn't be used!
	-- @client
	function ix.option.Save()
		ix.data.Set("options", ix.option.client, true, true)
	end

	--- Syncs all networked options to the server.
	-- @client
	function ix.option.Sync()
		local options = {}

		for k, v in pairs(ix.option.stored) do
			if (v.bNetworked) then
				options[k] = ix.option.client[k]
			end
		end

		netstream.Start("ixOptionSync", options)
	end
else
	ix.option.clients = ix.option.clients or {}

	--- Retrieves an option value from the specified player. If it is not set, it'll return the default that you've specified.
	-- This function will error when an invalid player is passed.
	-- @server
	-- @player client Player to retrieve option value from
	-- @string key Unique ID of the option
	-- @param default Default value to return if the option is not set
	-- @return Value associated with the key, or the default that was given if it doesn't exists
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
	netstream.Hook("ixOptionSet", function(client, key, value)
		local steamID = client:SteamID64()
		local option = ix.option.stored[key]

		if (option) then
			ix.option.clients[steamID] = ix.option.clients[steamID] or {}
			ix.option.clients[steamID][key] = value
		else
			ErrorNoHalt(string.format(
				"'%s' attempted to set option with invalid key '%s'", tostring(client) .. client:SteamID(), key
			))
		end
	end)

	-- sent on first load to sync all networked option values
	netstream.Hook("ixOptionSync", function(client, data)
		local steamID = client:SteamID64()
		ix.option.clients[steamID] = ix.option.clients[steamID] or {}

		for k, v in pairs(data) do
			local option = ix.option.stored[k]

			if (option) then
				ix.option.clients[steamID][k] = v
			else
				return ErrorNoHalt(string.format(
					"'%s' attempted to sync option with invalid key '%s'", tostring(client) .. client:SteamID(), k
				))
			end
		end
	end)
end
