
ix.config = ix.config or {}
ix.config.stored = ix.config.stored or {}

function ix.config.Add(key, value, description, callback, data, bNoNetworking, schemaOnly)
	local oldConfig = ix.config.stored[key]

	ix.config.stored[key] = {
		data = data,
		value = oldConfig and oldConfig.value or value,
		default = value,
		description = description,
		bNoNetworking = bNoNetworking,
		global = !schemaOnly,
		callback = callback
	}
end

function ix.config.SetDefault(key, value)
	local config = ix.config.stored[key]

	if (config) then
		config.default = value
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

function ix.config.Set(key, value)
	local config = ix.config.stored[key]

	if (config) then
		local oldValue = value
		config.value = value

		if (SERVER) then
			if (!config.bNoNetworking) then
				netstream.Start(nil, "cfgSet", key, value)
			end

			if (config.callback) then
				config.callback(oldValue, value)
			end

			ix.config.Save()
		end
	end
end

function ix.config.Get(key, default)
	local config = ix.config.stored[key]

	if (config) then
		if (config.value != nil) then
			return config.value
		elseif (config.default != nil) then
			return config.default
		end
	end

	return default
end

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
		netstream.Start(client, "cfgList", ix.config.GetChangedValues())
	end

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

	netstream.Hook("cfgSet", function(client, key, value)
		-- NEED TO ADD HOOK: CanPlayerModifyConfig
		if (client:IsSuperAdmin() and type(ix.config.stored[key].default) == type(value)) then
			ix.config.Set(key, value)

			if (type(value) == "table") then
				local value2 = "["
				local count = table.Count(value)
				local i = 1

				for _, v in SortedPairs(value) do
					value2 = value2..v..(i == count and "]" or ", ")
					i = i + 1
				end

				value = value2
			end

			ix.util.NotifyLocalized("cfgSet", nil, client:Name(), key, tostring(value))
			ix.log.Add(client, "cfgSet", key, value)
		end
	end)
else
	netstream.Hook("cfgList", function(data)
		for k, v in pairs(data) do
			if (ix.config.stored[k]) then
				ix.config.stored[k].value = v
			end
		end

		hook.Run("InitializedConfig", data)
	end)

	netstream.Hook("cfgSet", function(key, value)
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
					if (type(value) == "table" and value.r and value.g and value.b) then
						value = Vector(value.r / 255, value.g / 255, value.b / 255)
					end

					row:SetValue(value)
				end
			end
		end
	end)
end

if (CLIENT) then
	hook.Add("CreateMenuButtons", "ixConfig", function(tabs)
		if (LocalPlayer():IsSuperAdmin() and hook.Run("CanPlayerUseConfig", LocalPlayer()) != false) then
			tabs["config"] = function(panel)
				local scroll = panel:Add("DScrollPanel")
				scroll:Dock(FILL)

				local properties = scroll:Add("DProperties")
				properties:SetSize(panel:GetSize())

				ix.gui.properties = properties

				-- We're about to store the categories in this buffer.
				local buffer = {}

				for k, v in pairs(ix.config.stored) do
					-- Get the category name.
					local index = v.data and v.data.category or "misc"

					-- Insert the config into the category list.
					buffer[index] = buffer[index] or {}
					buffer[index][k] = v
				end

				-- Loop through the categories in alphabetical order.
				for category, configs in SortedPairs(buffer) do
					category = L(category)

					-- Ditto, except we're looping through configs.
					for k, v in SortedPairs(configs) do
						-- Determine which type of panel to create.
						local form = v.data and v.data.form
						local value = ix.config.stored[k].default

						if (!form) then
							local formType = type(value)

							if (formType == "number") then
								form = "Int"
								value = tonumber(ix.config.Get(k)) or value
							elseif (formType == "boolean") then
								form = "Boolean"
								value = util.tobool(ix.config.Get(k))
							else
								form = "Generic"
								value = ix.config.Get(k) or value
							end
						else
							value = ix.config.Get(k) or value
						end

						-- VectorColor currently only exists for DProperties.
						if (form == "Generic" and type(value) == "table" and value.r and value.g and value.b) then
							-- Convert the color to a vector.
							value = Vector(value.r / 255, value.g / 255, value.b / 255)
							form = "VectorColor"
						end

						local delay = 1

						if (form == "Boolean") then
							delay = 0
						end

						-- Add a new row for the config to the properties.
						local row = properties:CreateRow(category, k)
						row:Setup(form, v.data and v.data.data or {})
						row:SetValue(value)
						row:SetTooltip(v.description)
						row.DataChanged = function(this, newValue)
							timer.Create("ixCfgSend"..k, delay, 1, function()
								if (IsValid(row)) then
									if (form == "VectorColor") then
										local vector = Vector(newValue)

										newValue = Color(math.floor(vector.x * 255), math.floor(vector.y * 255), math.floor(vector.z * 255))
									elseif (form == "Int" or form == "Float") then
										newValue = tonumber(newValue)

										if (form == "Int") then
											newValue = math.Round(newValue)
										end
									elseif (form == "Boolean") then
										newValue = tobool(newValue)
									end

									netstream.Start("cfgSet", k, newValue)
								end
							end)
						end
					end
				end
			end
		end
	end)
end
