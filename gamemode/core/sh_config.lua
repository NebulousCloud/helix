
ix.config = ix.config or {}
ix.config.stored = ix.config.stored or {}

if (SERVER) then
	util.AddNetworkString("ixConfigList")
	util.AddNetworkString("ixConfigSet")

	ix.config.server = ix.yaml.Read("gamemodes/helix/helix.yml") or {}
end

function ix.config.Add(key, value, description, callback, data, bNoNetworking, schemaOnly)
	local oldConfig = ix.config.stored[key]
	local type = data.type or ix.util.GetTypeFromValue(value)

	if (!type) then
		ErrorNoHalt("attempted to add config with invalid type\n")
		return
	end

	data.type = nil

	ix.config.stored[key] = {
		type = type,
		data = data,
		value = oldConfig and oldConfig.value or value,
		default = value,
		description = description,
		bNoNetworking = bNoNetworking,
		global = !schemaOnly,
		callback = callback,
		hidden = data.hidden or nil
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
		net.Start("ixConfigList")
			net.WriteTable(ix.config.GetChangedValues())
		net.Send(client)
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

	net.Receive("ixConfigSet", function(length, client)
		local key = net.ReadString()
		local value = net.ReadType()

		if (hook.Run("CanPlayerModifyConfig", client, key) != false
		and type(ix.config.stored[key].default) == type(value)) then
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
		if (!LocalPlayer():IsSuperAdmin() or hook.Run("CanPlayerUseConfig", LocalPlayer()) == false) then
			return
		end

		tabs["config"] = {
			Create = function(info, container)
				local settings = container:Add("ixSettings")
				settings:SetSearchEnabled(true)

				-- gather categories
				local categories = {}
				local categoryIndices = {}

				for k, v in pairs(ix.config.stored) do
					local index = v.data and v.data.category or "misc"

					categories[index] = categories[index] or {}
					categories[index][k] = v
				end

				-- sort by category phrase
				for k, _ in pairs(categories) do
					categoryIndices[#categoryIndices + 1] = k
				end

				table.sort(categoryIndices, function(a, b)
					return L(a) < L(b)
				end)

				-- add panels
				for _, category in ipairs(categoryIndices) do
					local categoryPhrase = L(category)
					settings:AddCategory(categoryPhrase)

					-- we can use sortedpairs since configs don't have phrases to account for
					for k, v in SortedPairs(categories[category]) do
						if (isfunction(v.hidden) and v.hidden()) then
							continue
						end

						local data = v.data.data
						local type = v.type
						local value = ix.util.SanitizeType(type, ix.config.Get(k))

						-- @todo check ix.gui.properties
						local row = settings:AddRow(type, categoryPhrase)
						row:SetText(ix.util.ExpandCamelCase(k))

						-- type-specific properties
						if (type == ix.type.number) then
							row:SetMin(data and data.min or 0)
							row:SetMax(data and data.max or 1)
							row:SetDecimals(data and data.decimals or 0)
						end

						row:SetValue(value, true)
						row:SetShowReset(value != v.default, k, v.default)

						row.OnValueChanged = function(panel)
							local newValue = ix.util.SanitizeType(type, panel:GetValue())

							panel:SetShowReset(newValue != v.default, k, v.default)

							net.Start("ixConfigSet")
								net.WriteString(k)
								net.WriteType(newValue)
							net.SendToServer()
						end

						row.OnResetClicked = function(panel)
							panel:SetValue(v.default, true)
							panel:SetShowReset(false)

							net.Start("ixConfigSet")
								net.WriteString(k)
								net.WriteType(v.default)
							net.SendToServer()
						end

						row:GetLabel():SetHelixTooltip(function(tooltip)
							local title = tooltip:AddRow("name")
							title:SetImportant()
							title:SetText(k)
							title:SizeToContents()
							title:SetMaxWidth(math.max(title:GetMaxWidth(), ScrW() * 0.5))

							local description = tooltip:AddRow("description")
							description:SetText(v.description)
							description:SizeToContents()
						end)
					end
				end

				settings:SizeToContents()
				container.panel = settings
			end,

			OnSelected = function(info, container)
				container.panel.searchEntry:RequestFocus()
			end
		}
	end)
end
