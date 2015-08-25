nut.config = nut.config or {}
nut.config.stored = nut.config.stored or {}

function nut.config.add(key, value, desc, callback, data, noNetworking, schemaOnly)
	local oldConfig = nut.config.stored[key]

	nut.config.stored[key] = {data = data, value = oldConfig and oldConfig.value or value, default = value, desc = desc, noNetworking = noNetworking, global = !schemaOnly, callback = callback}
end

function nut.config.setDefault(key, value)
	local config = nut.config.stored[key]

	if (config) then
		config.default = value
	end
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
	hook.Run("InitializedConfig")
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

	netstream.Hook("cfgSet", function(client, key, value)
		if (client:IsSuperAdmin() and type(nut.config.stored[key].default) == type(value)) then
			nut.config.set(key, value)

			if (type(value) == "table") then
				local value2 = "["
				local count = table.Count(value)
				local i = 1

				for k, v in SortedPairs(value) do
					value2 = value2..v..(i == count and "]" or ", ")
					i = i + 1
				end

				value = value2
			end

			nut.util.notifyLocalized("cfgSet", nil, client:Name(), key, tostring(value), v)
		end
	end)
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

			local properties = nut.gui.properties

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
	hook.Add("CreateMenuButtons", "nutConfig", function(tabs)
		if (LocalPlayer():IsSuperAdmin()) then
			tabs["config"] = function(panel)
				local scroll = panel:Add("DScrollPanel")
				scroll:Dock(FILL)
				
				local properties = scroll:Add("DProperties")
				properties:SetSize(panel:GetSize())

				nut.gui.properties = properties

				-- We're about to store the categories in this buffer.
				local buffer = {}

				for k, v in pairs(nut.config.stored) do
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
						local value = nut.config.stored[k].default

						if (!form) then
							local formType = type(value)

							if (formType == "number") then
								form = "Int"
								value = tonumber(nut.config.get(k)) or value
							elseif (formType == "boolean") then
								form = "Boolean"
								value = util.tobool(nut.config.get(k))
							else
								form = "Generic"
							end
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
						row:SetToolTip(v.desc)
						row.DataChanged = function(this, value)
							timer.Create("nutCfgSend"..k, delay, 1, function()
								if (IsValid(row)) then
									if (form == "VectorColor") then
										local vector = Vector(value)

										value = Color(math.floor(vector.x * 255), math.floor(vector.y * 255), math.floor(vector.z * 255))
									elseif (form == "Int" or form == "Float") then
										value = tonumber(value)

										if (form == "Int") then
											value = math.Round(value)
										end
									elseif (form == "Boolean") then
										value = util.tobool(value)
									end

									netstream.Start("cfgSet", k, value)
								end
							end)
						end
					end
				end
			end
		end
	end)
end