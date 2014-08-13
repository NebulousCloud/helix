nut.config = nut.config or {}
nut.config.stored = nut.config.stored or {}

function nut.config.add(key, value, desc, callback, noNetworking, schemaOnly)
	local oldConfig = nut.config.stored[key]

	nut.config.stored[key] = {value = oldConfig and oldConfig.value or value, default = value, desc = desc, noNetworking = noNetworking, global = !schemaOnly, callback = callback}
end

function nut.config.set(key, value)
	local config = nut.config.stored[key]

	if (config) then
		local oldValue = value
		config.value = value

		if (SERVER) then
			if (!config.noNetworking) then
				netstream.Start(nil, "cfgSet", key, value)
			end

			if (config.callback) then
				config.callback(oldValue, value)
			end

			nut.config.save()
		end
	end
end

function nut.config.get(key, default)
	local config = nut.config.stored[key]

	if (config) then
		if (config.value != nil) then
			return config.value
		elseif (config.default != nil) then
			return config.default
		end
	end

	return default
end

function nut.config.load()
	if (SERVER) then
		local globals = nut.data.get("config", nil, true, true)
		local data = nut.data.get("config", nil, false, true)

		if (globals) then
			for k, v in pairs(globals) do
				nut.config.stored[k] = nut.config.stored[k] or {}
				nut.config.stored[k].value = v
			end
		end

		if (data) then
			for k, v in pairs(data) do
				nut.config.stored[k] = nut.config.stored[k] or {}
				nut.config.stored[k].value = v
			end
		end
	end

	nut.util.include("nutscript/gamemode/config/sh_config.lua")
end

if (SERVER) then
	function nut.config.getChangedValues()
		local data = {}

		for k, v in pairs(nut.config.stored) do
			if (v.default != v.value) then
				data[k] = v.value
			end
		end

		return data
	end

	function nut.config.send(client)
		netstream.Start(client, "cfgList", nut.config.getChangedValues())
	end

	function nut.config.save()
		local globals = {}
		local data = {}

		for k, v in pairs(nut.config.getChangedValues()) do
			if (nut.config.stored[k].global) then
				globals[k] = v
			else
				data[k] = v
			end
		end

		-- Global and schema data set respectively.
		nut.data.set("config", globals, true, true)
		nut.data.set("config", data, false, true)
	end
else
	netstream.Hook("cfgList", function(data)
		for k, v in pairs(data) do
			if (nut.config.stored[k]) then
				nut.config.stored[k].value = v
			end
		end

		hook.Run("InitializedConfig", data)
	end)

	netstream.Hook("cfgSet", function(key, value)
		local config = nut.config.stored[key]

		if (config) then
			if (config.callback) then
				config.callback(config.value, value)
			end

			config.value = value
		end
	end)
end