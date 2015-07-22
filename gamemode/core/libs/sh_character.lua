nut.char = nut.char or {}
nut.char.loaded = nut.char.loaded or {}
nut.char.vars = nut.char.vars or {}
nut.char.cache = nut.char.cache or {}

nut.util.include("nutscript/gamemode/core/meta/sh_character.lua")

if (SERVER) then
	function nut.char.create(data, callback)
		local timeStamp = math.floor(os.time())

		data.money = data.money or nut.config.get("defMoney", 0)

		nut.db.insertTable({
			_name = data.name or "John Doe",
			_desc = data.desc or "No description available.",
			_model = data.model or "models/error.mdl",
			_schema = SCHEMA and SCHEMA.folder or "nutscript",
			_createTime = timeStamp,
			_lastJoinTime = timeStamp,
			_steamID = data.steamID,
			_faction = data.faction or "Unknown",
			_money = data.money,
			_data = data.data
		}, function(data2, charID)
			nut.db.query("INSERT INTO nut_inventories (_charID) VALUES ("..charID..")", function(_, invID)
				local client

				for k, v in ipairs(player.GetAll()) do
					if (v:SteamID64() == data.steamID) then
						client = v
						break
					end
				end

				local w, h = nut.config.get("invW"), nut.config.get("invH")
				local character = nut.char.new(data, charID, client, data.steamID)
				local inventory = nut.item.createInv(w, h, invID)

				character.vars.inv = {inventory}
				inventory:setOwner(charID)

				nut.char.loaded[charID] = character
				table.insert(nut.char.cache[data.steamID], charID)

				if (callback) then
					callback(charID)
				end
			end)
		end)
	end

	function nut.char.restore(client, callback, noCache, id)
		local steamID64 = client:SteamID64()
		local cache = nut.char.cache[steamID64]

		if (cache and !noCache) then
			for k, v in ipairs(cache) do
				local character = nut.char.loaded[v]

				if (character and !IsValid(character.client)) then
					character.player = client
				end
			end

			if (callback) then
				callback(cache)
			end

			return
		end

		local fields = "_id, _name, _desc, _model, _attribs, _data, _money, _faction"
		local condition = "_schema = '"..nut.db.escape(SCHEMA.folder).."' AND _steamID = "..steamID64

		if (id) then
			condition = condition.." AND _id = "..id
		end

		nut.db.query("SELECT "..fields.." FROM nut_characters WHERE "..condition, function(data)
			local characters = {}

			for k, v in ipairs(data or {}) do
				local id = tonumber(v._id)

				if (id) then
					local data = {}

					for k2, v2 in pairs(nut.char.vars) do
						if (v2.field and v[v2.field]) then
							local value = tostring(v[v2.field])

							if (type(v2.default) == "number") then
								value = tonumber(value) or v2.default
							elseif (type(v2.default) == "boolean") then
								value = tobool(vlaue)
							elseif (type(v2.default) == "table") then
								value = util.JSONToTable(value)
							end

							data[k2] = value
						end
					end

					characters[#characters + 1] = id

					local character = nut.char.new(data, id, client)
						hook.Run("CharacterRestored", character)
						character.vars.inv = {}

						nut.db.query("SELECT _invID, _invType FROM nut_inventories WHERE _charID = "..id, function(data)
							if (data and #data > 0) then
								for k, v in ipairs(data) do
									local w, h = nut.config.get("invW"), nut.config.get("invH")

									if (v._invType) then
										local invType = nut.item.inventoryTypes[v._invType]

										if (invType) then
											w, h = invType.w, invType.h
										end
									end

									nut.item.restoreInv(tonumber(v._invID), w, h, function(inventory)
										inventory:setOwner(id)
										character.vars.inv[k] = inventory
									end, true)
								end
							else
								nut.db.insertTable({
									_charID = id
								}, function(_, invID)
									local w, h = nut.config.get("invW"), nut.config.get("invH")
									local inventory = nut.item.createInv(w, h, invID)
									inventory:setOwner(id)

									character.vars.inv[1] = inventory
								end, "inventories")
							end
						end)
					nut.char.loaded[id] = character
				else
					ErrorNoHalt("[NutScript] Attempt to load character '"..(data._name or "nil").."' with invalid ID!")
				end
			end

			if (callback) then
				callback(characters)
			end

			nut.char.cache[steamID64] = characters
		end)
	end
end

function nut.char.new(data, id, client, steamID)
	if (data.name) then
		data.name = data.name:gsub("#", "#​")
	end

	if (data.desc) then
		data.desc = data.desc:gsub("#", "#​")
	end
	
	local character = setmetatable({vars = {}}, nut.meta.character)
		for k, v in pairs(data) do
			if (v != nil) then
				character.vars[k] = v
			end
		end

		character.id = id or 0
		character.player = client

		if (IsValid(client) or steamID) then
			character.steamID = IsValid(client) and client:SteamID64() or steamID
		end
	return character
end

nut.char.varHooks = nut.char.varHooks or {}
function nut.char.hookVar(varName, hookName, func)
	nut.char.varHooks[varName] = nut.char.varHooks[varName] or {}

	nut.char.varHooks[varName][hookName] = func
end

-- Registration of default variables go here.
do
	nut.char.registerVar("name", {
		field = "_name",
		default = "John Doe",
		index = 1,
		onValidate = function(value, data, client)
			if (!value or !value:find("%S")) then
				return false, "invalid", "name"
			end

			return hook.Run("GetDefaultCharName", client, data.faction) or value:sub(1, 70)
		end,
		onPostSetup = function(panel, faction, payload)
			local name, disabled = hook.Run("GetDefaultCharName", LocalPlayer(), faction)

			if (name) then
				panel:SetText(name)
				payload.name = name
			end

			if (disabled) then
				panel:SetDisabled(true)
				panel:SetEditable(false)
			end
		end
	})

	nut.char.registerVar("desc", {
		field = "_desc",
		default = "No description available.",
		index = 2,
		onValidate = function(value, data)
			local minLength = nut.config.get("minDescLen", 16)

			if (!value or #value:gsub("%s", "") < minLength) then
				return false, "descMinLen", minLength
			end
		end
	})

	local gradient = nut.util.getMaterial("vgui/gradient-d")

	nut.char.registerVar("model", {
		field = "_model",
		default = "models/error.mdl",
		onSet = function(character, value)
			local client = character:getPlayer()

			if (IsValid(client) and client:getChar() == character) then
				client:SetModel(value)
			end

			character.vars.model = value
		end,
		onGet = function(character, default)
			return character.vars.model or default
		end,
		index = 3,
		onDisplay = function(panel, y)
			local scroll = panel:Add("DScrollPanel")
			scroll:SetSize(panel:GetWide(), 260)
			scroll:SetPos(0, y)

			local layout = scroll:Add("DIconLayout")
			layout:Dock(FILL)
			layout:SetSpaceX(1)
			layout:SetSpaceY(1)

			local faction = nut.faction.indices[panel.faction]

			if (faction) then
				for k, v in SortedPairs(faction.models) do
					local icon = layout:Add("SpawnIcon")
					icon:SetSize(64, 128)
					icon:InvalidateLayout(true)
					icon.DoClick = function(this)
						panel.payload.model = k
					end
					icon.PaintOver = function(this, w, h)
						if (panel.payload.model == k) then
							local color = nut.config.get("color", color_white)

							surface.SetDrawColor(color.r, color.g, color.b, 200)

							for i = 1, 3 do
								local i2 = i * 2

								surface.DrawOutlinedRect(i, i, w - i2, h - i2)
							end

							surface.SetDrawColor(color.r, color.g, color.b, 75)
							surface.SetMaterial(gradient)
							surface.DrawTexturedRect(0, 0, w, h)
						end
					end

					if (type(v) == "string") then
						icon:SetModel(v)
					else
						icon:SetModel(v[1], v[2] or 0, v[3])
					end
				end
			end

			return scroll
		end,
		onValidate = function(value, data)
			local faction = nut.faction.indices[data.faction]

			if (faction) then
				if (!data.model or !faction.models[data.model]) then
					return false, "needModel"
				end
			else
				return false, "needModel"
			end
		end,
		onAdjust = function(client, data, value, newData)
			local faction = nut.faction.indices[data.faction]

			if (faction) then
				local model = faction.models[value]

				if (type(model) == "string") then
					newData.model = model
				elseif (type(model) == "table") then
					newData.model = model[1]
					newData.data = newData.data or {}
					newData.data.skin = model[2] or 0
					newData.data.bodyGroups = model[3]
				end
			end
		end
	})

	nut.char.registerVar("class", {
		isLocal = true,
		noDisplay = true,
		onSet = function(character, class)
			character:setVar("class", class)
		end,
		onGet = function(character, default)
			return character:getVar("class", default)
		end
	})

	nut.char.registerVar("faction", {
		field = "_faction",
		default = "Citizen",
		onSet = function(character, value)
			local client = character:getPlayer()

			if (IsValid(client)) then
				client:SetTeam(value)
			end
		end,
		onGet = function(character, default)
			local faction = nut.faction.teams[character.vars.faction]

			return faction and faction.index or 0
		end,
		noDisplay = true,
		onValidate = function(value, data, client)
			if (value) then
				if (client:hasWhitelist(value)) then
					return true
				end
			end

			return false
		end,
		onAdjust = function(client, data, value, newData)
			newData.faction = nut.faction.indices[value].uniqueID
		end
	})

	nut.char.registerVar("attribs", {
		field = "_attribs",
		default = {},
		isLocal = true,
		index = 4,
		onDisplay = function(panel, y)
			local container = panel:Add("DPanel")
			container:SetPos(0, y)
			container:SetWide(panel:GetWide() - 16)

			local y2 = 0
			local total = 0
			local maximum = hook.Run("GetMaxAttribPoints", LocalPlayer(), panel.payload) or nut.config.get("maxAttribs")

			panel.payload.attribs = {}

			for k, v in SortedPairsByMemberValue(nut.attribs.list, "name") do
				panel.payload.attribs[k] = 0

				local bar = container:Add("nutAttribBar")
				bar:setMax(maximum)
				bar:Dock(TOP)
				bar:DockMargin(2, 2, 2, 2)
				bar:setText(L(v.name))
				bar.onChanged = function(this, difference)
					if ((total + difference) > maximum) then
						return false
					end

					total = total + difference
					panel.payload.attribs[k] = panel.payload.attribs[k] + difference
				end

				y2 = y2 + bar:GetTall() + 4
			end

			container:SetTall(y2)
			return container
		end,
		onValidate = function(value, data, client)
			if (value != nil) then
				if (type(value) == "table") then
					local count = 0

					for k, v in pairs(value) do
						count = count + v
					end

					if (count > (hook.Run("GetMaxAttribPoints", client, info) or nut.config.get("maxAttribs"))) then
						return false, "unknownError"
					end
				else
					return false, "unknownError"
				end
			end
		end,
		shouldDisplay = function(panel) return table.Count(nut.attribs.list) > 0 end
	})

	nut.char.registerVar("money", {
		field = "_money",
		default = 0,
		isLocal = true,
		noDisplay = true
	})

	nut.char.registerVar("data", {
		default = {},
		isLocal = true,
		noDisplay = true,
		field = "_data",
		onSet = function(character, key, value, noReplication, receiver)
			local data = character:getData()
			local client = character:getPlayer()

			data[key] = value

			if (!noReplication and IsValid(client)) then
				netstream.Start(receiver or client, "charData", character:getID(), key, value)
			end

			character.vars.data = data
		end,
		onGet = function(character, key, default)
			local data = character.vars.data or {}

			if (key) then
				if (!data) then
					return default
				end

				local value = data[key]

				return value == nil and default or value
			else
				return default or data
			end
		end
	})

	nut.char.registerVar("var", {
		default = {},
		noDisplay = true,
		onSet = function(character, key, value, noReplication, receiver)
			local data = character:getVar()
			local client = character:getPlayer()

			data[key] = value

			if (!noReplication and IsValid(client)) then
				local id

				if (client:getChar() and client:getChar():getID() == character:getID()) then
					id = client:getChar():getID()
				else
					id = character:getID()
				end

				netstream.Start(receiver or client, "charVar", key, value, id)
			end

			character.vars.vars = data
		end,
		onGet = function(character, key, default)
			character.vars.vars = character.vars.vars or {}
			local data = character.vars.vars or {}

			if (key) then
				if (!data) then
					return default
				end

				local value = data[key]

				return value == nil and default or value
			else
				return default or data
			end
		end
	})
end

-- Networking information here.
do
	if (SERVER) then
		netstream.Hook("charChoose", function(client, id)
			if (client:getChar() and client:getChar():getID() == id) then
				netstream.Start(client, "charLoaded")
				
				return client:notifyLocalized("usingChar")
			end

			local character = nut.char.loaded[id]

			if (character and character:getPlayer() == client) then
				local status, result = hook.Run("CanPlayerUseChar", client, character)

				if (status == false) then
					if (result) then
						if (result:sub(1, 1) == "@") then
							client:notifyLocalized(result:sub(2))
						else
							client:notify(result)
						end
					end

					netstream.Start(client, "charMenu")

					return
				end

				local currentChar = client:getChar()

				if (currentChar) then
					currentChar:save()
				end

				character:setup()
				client:Spawn()

				hook.Run("PlayerLoadedChar", client, character, currentChar)
			else
				ErrorNoHalt("[NutScript] Attempt to load invalid character '"..id.."'\n")
			end
		end)

		netstream.Hook("charCreate", function(client, data)
			local newData = {}

			for k, v in pairs(data) do
				local info = nut.char.vars[k]

				if (!info or (!info.onValidate and info.noDisplay)) then
					data[k] = nil
				end
			end

			for k, v in SortedPairsByMemberValue(nut.char.vars, "index") do
				local value = data[k]

				if (v.onValidate) then
					local result = {v.onValidate(value, data, client)}

					if (result[1] == false) then
						return netstream.Start(client, "charAuthed", unpack(result, 2))
					else
						if (result[1] != nil) then
							data[k] = result[1]
						end

						if (v.onAdjust) then
							v.onAdjust(client, data, value, newData)
						end
					end
				end
			end

			data.steamID = client:SteamID64()
				hook.Run("AdjustCreationData", client, data, newData)
			data = table.Merge(data, newData)

			nut.char.create(data, function(id)
				if (IsValid(client)) then
					nut.char.loaded[id]:sync(client)

					netstream.Start(client, "charAuthed", client.nutCharList)
					MsgN("Created character '"..id.."' for "..client:steamName()..".")
					hook.Run("OnCharCreated", client, nut.char.loaded[id])
				end
			end)
			
		end)

		netstream.Hook("charDel", function(client, id)
			local character = nut.char.loaded[id]
			local steamID = client:SteamID64()
			local isCurrentChar = client:getChar() and client:getChar():getID() == id

			if (character and character.steamID == steamID) then
				for k, v in ipairs(client.nutCharList or {}) do
					if (v == id) then
						table.remove(client.nutCharList, k)
					end
				end

				hook.Run("PreCharDelete", client, character)
				nut.char.loaded[id] = nil
				netstream.Start(nil, "charDel", id)
				nut.db.query("DELETE FROM nut_characters WHERE _id = "..id.." AND _steamID = "..client:SteamID64())
				nut.db.query("SELECT _invID FROM nut_inventories WHERE _charID = "..id, function(data)
					if (data) then
						for k, v in ipairs(data) do
							nut.db.query("DELETE FROM nut_items WHERE _invID = "..v._invID)
							nut.item.inventories[tonumber(v._invID)] = nil
						end
					end

					nut.db.query("DELETE FROM nut_inventories WHERE _charID = "..id)
				end)

				-- other plugins might need to deal with deleted characters.
				hook.Run("OnCharDelete", client, id, isCurrentChar)
				
				if (isCurrentChar) then
					client:setNetVar("char", nil)
					client:Spawn()
				end
			end
		end)
	else
		netstream.Hook("charInfo", function(data, id, client)
			nut.char.loaded[id] = nut.char.new(data, id, client == nil and LocalPlayer() or client)
		end)

		netstream.Hook("charSet", function(key, value, id)
			id = id or (LocalPlayer():getChar() and LocalPlayer():getChar().id)
			
			local character = nut.char.loaded[id]

			if (character) then
				character.vars[key] = value
			end
		end)

		netstream.Hook("charVar", function(key, value, id)
			id = id or (LocalPlayer():getChar() and LocalPlayer():getChar().id)

			local character = nut.char.loaded[id]

			if (character) then
				local oldVar = character:getVar()[key]
				character:getVar()[key] = value

				hook.Run("OnCharVarChanged", character, key, oldVar, value)
			end
		end)

		netstream.Hook("charMenu", function(data, openNext)
			if (data) then
				nut.characters = data
			end

			OPENNEXT = openNext
			vgui.Create("nutCharMenu")
		end)

		netstream.Hook("charData", function(id, key, value)
			local character = nut.char.loaded[id]

			if (character) then
				character.vars.data = character.vars.data or {}
				character:getData()[key] = value
			end
		end)

		netstream.Hook("charDel", function(id)
			local isCurrentChar = LocalPlayer():getChar() and LocalPlayer():getChar():getID() == id

			nut.char.loaded[id] = nil

			for k, v in ipairs(nut.characters) do
				if (v == id) then
					table.remove(nut.characters, k)

					if (IsValid(nut.gui.char) and nut.gui.char.setupCharList) then
						nut.gui.char:setupCharList()
					end
				end
			end

			if (isCurrentChar and !IsValid(nut.gui.char)) then
				vgui.Create("nutCharMenu")
			end
		end)

		netstream.Hook("charKick", function(id, isCurrentChar)
			if (nut.gui.menu and nut.gui.menu:IsVisible()) then
				nut.gui.menu:Remove()
			end

			if (isCurrentChar and !IsValid(nut.gui.char)) then
				vgui.Create("nutCharMenu")
			end
		end)
	end
end

-- Additions to the player metatable here.
do
	local playerMeta = FindMetaTable("Player")
	playerMeta.steamName = playerMeta.steamName or playerMeta.Name
	playerMeta.SteamName = playerMeta.steamName

	function playerMeta:getChar()
		return nut.char.loaded[self.getNetVar(self, "char")]
	end

	function playerMeta:Name()
		local character = self.getChar(self)
		
		return character and character.getName(character) or self.steamName(self)
	end

	playerMeta.Nick = playerMeta.Name
	playerMeta.GetName = playerMeta.Name
end
