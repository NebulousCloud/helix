ix.char = ix.char or {}
ix.char.loaded = ix.char.loaded or {}
ix.char.vars = ix.char.vars or {}
ix.char.cache = ix.char.cache or {}

ix.util.Include("helix/gamemode/core/meta/sh_character.lua")

if (SERVER) then
	function ix.char.Create(data, callback)
		local timeStamp = math.floor(os.time())

		data.money = data.money or ix.config.Get("defMoney", 0)

		ix.db.InsertTable({
			_name = data.name or "",
			_description = data.description or "",
			_model = data.model or "models/error.mdl",
			_schema = Schema and Schema.folder or "helix",
			_createTime = timeStamp,
			_lastJoinTime = timeStamp,
			_steamID = data.steamID,
			_faction = data.faction or "Unknown",
			_money = data.money,
			_data = data.data
		}, function(data2, charID)
			ix.db.query("INSERT INTO ix_inventories (_charID) VALUES ("..charID..")", function(_, invID)
				local client

				for k, v in ipairs(player.GetAll()) do
					if (v:SteamID64() == data.steamID) then
						client = v
						break
					end
				end

				local w, h = ix.config.Get("invW"), ix.config.Get("invH")
				local character = ix.char.New(data, charID, client, data.steamID)
				local inventory = ix.item.CreateInv(w, h, invID)

				character.vars.inv = {inventory}
				inventory:SetOwner(charID)

				ix.char.loaded[charID] = character
				table.insert(ix.char.cache[data.steamID], charID)

				if (callback) then
					callback(charID)
				end
			end)
		end)
	end

	function ix.char.Restore(client, callback, noCache, id)
		local steamID64 = client:SteamID64()
		local cache = ix.char.cache[steamID64]

		if (cache and !noCache) then
			for k, v in ipairs(cache) do
				local character = ix.char.loaded[v]

				if (character and !IsValid(character.client)) then
					character.player = client
				end
			end

			if (callback) then
				callback(cache)
			end

			return
		end

		local fields = "_id, _name, _description, _model, _attribs, _data, _money, _faction"
		local condition = "_schema = '"..ix.db.escape(Schema.folder).."' AND _steamID = "..steamID64

		if (id) then
			condition = condition.." AND _id = "..id
		end

		ix.db.query("SELECT "..fields.." FROM ix_characters WHERE "..condition, function(data)
			local characters = {}

			for k, v in ipairs(data or {}) do
				local id = tonumber(v._id)

				if (id) then
					local data = {}

					for k2, v2 in pairs(ix.char.vars) do
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

					local character = ix.char.New(data, id, client)
						hook.Run("CharacterRestored", character)
						character.vars.inv = {
							[1] = -1,
						}

						ix.db.query("SELECT _invID, _invType FROM ix_inventories WHERE _charID = "..id, function(data)
							if (data and #data > 0) then
								for k, v in pairs(data) do
									if (v._invType and isstring(v._invType) and v._invType == "NULL") then
										v._invType = nil
									end

									local w, h = ix.config.Get("invW"), ix.config.Get("invH")

									local invType 
									if (v._invType) then
										invType = ix.item.inventoryTypes[v._invType]

										if (invType) then
											w, h = invType.w, invType.h
										end
									end

									ix.item.RestoreInv(tonumber(v._invID), w, h, function(inventory)
										if (v._invType) then
											inventory.vars.isBag = v._invType
											table.insert(character.vars.inv, inventory)
										else
											character.vars.inv[1] = inventory
										end

										inventory:SetOwner(id)
									end, true)
								end
							else
								ix.db.InsertTable({
									_charID = id
								}, function(_, invID)
									local w, h = ix.config.Get("invW"), ix.config.Get("invH")
									local inventory = ix.item.CreateInv(w, h, invID)
									inventory:SetOwner(id)

									character.vars.inv = {
										inventory
									}
								end, "inventories")
							end
						end)
					ix.char.loaded[id] = character
				else
					ErrorNoHalt("[Helix] Attempt to load character '"..(data._name or "nil").."' with invalid ID!")
				end
			end

			if (callback) then
				callback(characters)
			end

			ix.char.cache[steamID64] = characters
		end)
	end

	function ix.char.LoadChar(callback, noCache, id)
		local fields = "_id, _name, _description, _model, _attribs, _data, _money, _faction"
		local condition = "_schema = '"..ix.db.escape(Schema.folder)

		if (id) then
			condition = condition.."' AND _id = "..id
		else
			ErrorNoHalt("Tried to load invalid character with ix.char.loadChar")

			return
		end

		ix.db.query("SELECT "..fields.." FROM ix_characters WHERE "..condition, function(data)
			for k, v in ipairs(data or {}) do
				local id = tonumber(v._id)

				if (id) then
					local data = {}

					for k2, v2 in pairs(ix.char.vars) do
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

					local character = ix.char.New(data, id)
						hook.Run("CharacterRestored", character)
						character.vars.inv = {
							[1] = -1,
						}

						ix.db.query("SELECT _invID, _invType FROM ix_inventories WHERE _charID = "..id, function(data)
							if (data and #data > 0) then
								for k, v in pairs(data) do
									if (v._invType and isstring(v._invType) and v._invType == "NULL") then
										v._invType = nil
									end

									local w, h = ix.config.Get("invW"), ix.config.Get("invH")

									local invType 
									if (v._invType) then
										invType = ix.item.inventoryTypes[v._invType]

										if (invType) then
											w, h = invType.w, invType.h
										end
									end

									ix.item.RestoreInv(tonumber(v._invID), w, h, function(inventory)
										if (v._invType) then
											inventory.vars.isBag = v._invType
											table.insert(character.vars.inv, inventory)
										else
											character.vars.inv[1] = inventory
										end

										inventory:SetOwner(id)
									end, true)
								end
							else
								ix.db.InsertTable({
									_charID = id
								}, function(_, invID)
									local w, h = ix.config.Get("invW"), ix.config.Get("invH")
									local inventory = ix.item.CreateInv(w, h, invID)
									inventory:SetOwner(id)

									character.vars.inv = {
										inventory
									}
								end, "inventories")
							end
						end)
					ix.char.loaded[id] = character
				else
					ErrorNoHalt("[Helix] Attempt to load character '"..(data._name or "nil").."' with invalid ID!")
				end
			end

			if (callback) then
				callback(character)
			end
		end)
	end
end

function ix.char.New(data, id, client, steamID)
	if (data.name) then
		data.name = data.name:gsub("#", "#​")
	end

	if (data.description) then
		data.description = data.description:gsub("#", "#​")
	end
	
	local character = setmetatable({vars = {}}, ix.meta.character)
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

ix.char.varHooks = ix.char.varHooks or {}
function ix.char.HookVar(varName, hookName, func)
	ix.char.varHooks[varName] = ix.char.varHooks[varName] or {}

	ix.char.varHooks[varName][hookName] = func
end

-- Registration of default variables go here.
do
	ix.char.RegisterVar("name", {
		field = "_name",
		default = "John Doe",
		index = 1,
		OnValidate = function(value, data, client)
			local minLength = ix.config.Get("minNameLen", 4)
			local maxLength = ix.config.Get("maxNameLen", 32)

			if (!value or #value:gsub("%s", "") < minLength) then
				return false, "nameMinLen", minLength
			elseif (!value:find("%S")) then
				return false, "invalid", "name"
			elseif (#value:gsub("%s", "") > maxLength) then
				return false, "nameMaxLen", maxLength
			end

			return hook.Run("GetDefaultCharName", client, data.faction) or value:sub(1, 70)
		end,
		OnPostSetup = function(panel, faction, payload)
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

	ix.char.RegisterVar("description", {
		field = "_description",
		default = "",
		index = 2,
		OnValidate = function(value, data)
			if (noDesc) then return true end

			local minLength = ix.config.Get("minDescLen", 16)

			if (!value or #value:gsub("%s", "") < minLength) then
				return false, "descMinLen", minLength
			elseif (!value:find("%s+") or !value:find("%S")) then
				return false, "invalid", "description"
			end
		end
	})

	local gradient = ix.util.GetMaterial("vgui/gradient-d")

	ix.char.RegisterVar("model", {
		field = "_model",
		default = "models/error.mdl",
		OnSet = function(character, value)
			local client = character:GetPlayer()

			if (IsValid(client) and client:GetChar() == character) then
				client:SetModel(value)
			end

			character.vars.model = value
		end,
		OnGet = function(character, default)
			return character.vars.model or default
		end,
		index = 3,
		OnDisplay = function(panel, y)
			local scroll = panel:Add("DScrollPanel")
			scroll:SetSize(panel:GetWide(), 260)
			scroll:SetPos(0, y)

			local layout = scroll:Add("DIconLayout")
			layout:Dock(FILL)
			layout:SetSpaceX(1)
			layout:SetSpaceY(1)

			local faction = ix.faction.indices[panel.faction]

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
							local color = ix.config.Get("color", color_white)

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
		OnValidate = function(value, data)
			local faction = ix.faction.indices[data.faction]

			if (faction) then
				if (!data.model or !faction.models[data.model]) then
					return false, "needModel"
				end
			else
				return false, "needModel"
			end
		end,
		OnAdjust = function(client, data, value, newData)
			local faction = ix.faction.indices[data.faction]

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

	ix.char.RegisterVar("class", {
		noDisplay = true,
	})

	ix.char.RegisterVar("faction", {
		field = "_faction",
		default = "Citizen",
		OnSet = function(character, value)
			local client = character:GetPlayer()

			if (IsValid(client)) then
				client:SetTeam(value)
			end
		end,
		OnGet = function(character, default)
			local faction = ix.faction.teams[character.vars.faction]

			return faction and faction.index or 0
		end,
		noDisplay = true,
		OnValidate = function(value, data, client)
			if (value) then
				if (client:HasWhitelist(value)) then
					return true
				end
			end

			return false
		end,
		OnAdjust = function(client, data, value, newData)
			newData.faction = ix.faction.indices[value].uniqueID
		end
	})

	ix.char.RegisterVar("attribs", {
		field = "_attribs",
		default = {},
		isLocal = true,
		index = 4,
		OnDisplay = function(panel, y)
			local container = panel:Add("DPanel")
			container:SetPos(0, y)
			container:SetWide(panel:GetWide() - 16)

			local y2 = 0
			local total = 0
			local maximum = hook.Run("GetStartAttribPoints", LocalPlayer(), panel.payload) or ix.config.Get("maxAttribs", 30)

			panel.payload.attribs = {}

			for k, v in SortedPairsByMemberValue(ix.attribs.list, "name") do
				panel.payload.attribs[k] = 0

				local bar = container:Add("ixAttribBar")
				bar:SetMax(maximum)
				bar:Dock(TOP)
				bar:DockMargin(2, 2, 2, 2)
				bar:SetText(L(v.name))
				bar.onChanged = function(this, difference)
					if ((total + difference) > maximum) then
						return false
					end

					total = total + difference
					panel.payload.attribs[k] = panel.payload.attribs[k] + difference
				end

				if (v.noStartBonus) then
					bar:SetReadOnly()
				end

				y2 = y2 + bar:GetTall() + 4
			end

			container:SetTall(y2)
			return container
		end,
		OnValidate = function(value, data, client)
			if (value != nil) then
				if (type(value) == "table") then
					local count = 0

					for k, v in pairs(value) do
						count = count + v
					end

					if (count > (hook.Run("GetStartAttribPoints", client, count) or ix.config.Get("maxAttribs", 30))) then
						return false, "unknownError"
					end
				else
					return false, "unknownError"
				end
			end
		end,
		shouldDisplay = function(panel) return table.Count(ix.attribs.list) > 0 end
	})

	ix.char.RegisterVar("money", {
		field = "_money",
		default = 0,
		isLocal = true,
		noDisplay = true
	})

	ix.char.RegisterVar("data", {
		default = {},
		isLocal = true,
		noDisplay = true,
		field = "_data",
		OnSet = function(character, key, value, noReplication, receiver)
			local data = character:GetData()
			local client = character:GetPlayer()

			data[key] = value

			if (!noReplication and IsValid(client)) then
				netstream.Start(receiver or client, "charData", character:GetID(), key, value)
			end

			character.vars.data = data
		end,
		OnGet = function(character, key, default)
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

	ix.char.RegisterVar("var", {
		default = {},
		noDisplay = true,
		OnSet = function(character, key, value, noReplication, receiver)
			local data = character:GetVar()
			local client = character:GetPlayer()

			data[key] = value

			if (!noReplication and IsValid(client)) then
				local id

				if (client:GetChar() and client:GetChar():GetID() == character:GetID()) then
					id = client:GetChar():GetID()
				else
					id = character:GetID()
				end

				netstream.Start(receiver or client, "charVar", key, value, id)
			end

			character.vars.vars = data
		end,
		OnGet = function(character, key, default)
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
			if (client:GetChar() and client:GetChar():GetID() == id) then
				netstream.Start(client, "charLoaded")
				
				return client:NotifyLocalized("usingChar")
			end

			local character = ix.char.loaded[id]

			if (character and character:GetPlayer() == client) then
				local status, result = hook.Run("CanPlayerUseChar", client, character)

				if (status == false) then
					if (result) then
						if (result:sub(1, 1) == "@") then
							client:NotifyLocalized(result:sub(2))
						else
							client:Notify(result)
						end
					end

					netstream.Start(client, "charMenu")

					return
				end

				local currentChar = client:GetChar()

				if (currentChar) then
					currentChar:Save()
				end

				hook.Run("PrePlayerLoadedChar", client, character, currentChar)
				character:Setup()
				client:Spawn()

				hook.Run("PlayerLoadedChar", client, character, currentChar)
			else
				ErrorNoHalt("[Helix] Attempt to load invalid character '"..id.."'\n")
			end
		end)

		netstream.Hook("charCreate", function(client, data)
			local newData = {}
			
			local maxChars = hook.Run("GetMaxPlayerCharacter", client) or ix.config.Get("maxChars", 5)
			local charList = client.ixCharList
			local charCount = table.Count(charList)

			if (charCount >= maxChars) then
				return netstream.Start(client, "charAuthed", "maxCharacters")
			end

			for k, v in pairs(data) do
				local info = ix.char.vars[k]

				if (!info or (!info.OnValidate and info.noDisplay)) then
					data[k] = nil
				end
			end

			for k, v in SortedPairsByMemberValue(ix.char.vars, "index") do
				local value = data[k]

				if (v.OnValidate) then
					local result = {v.OnValidate(value, data, client)}

					if (result[1] == false) then
						return netstream.Start(client, "charAuthed", unpack(result, 2))
					else
						if (result[1] != nil) then
							data[k] = result[1]
						end

						if (v.OnAdjust) then
							v.OnAdjust(client, data, value, newData)
						end
					end
				end
			end

			data.steamID = client:SteamID64()
				hook.Run("AdjustCreationData", client, data, newData)
			data = table.Merge(data, newData)

			ix.char.Create(data, function(id)
				if (IsValid(client)) then
					ix.char.loaded[id]:Sync(client)

					netstream.Start(client, "charAuthed", client.ixCharList)
					MsgN("Created character '"..id.."' for "..client:SteamName()..".")
					hook.Run("OnCharCreated", client, ix.char.loaded[id])
				end
			end)
			
		end)

		netstream.Hook("charDel", function(client, id)
			local character = ix.char.loaded[id]
			local steamID = client:SteamID64()
			local isCurrentChar = client:GetChar() and client:GetChar():GetID() == id

			if (character and character.steamID == steamID) then
				for k, v in ipairs(client.ixCharList or {}) do
					if (v == id) then
						table.remove(client.ixCharList, k)
					end
				end

				hook.Run("PreCharDelete", client, character)
				ix.char.loaded[id] = nil
				netstream.Start(nil, "charDel", id)
				ix.db.query("DELETE FROM ix_characters WHERE _id = "..id.." AND _steamID = "..client:SteamID64())
				ix.db.query("SELECT _invID FROM ix_inventories WHERE _charID = "..id, function(data)
					if (data) then
						for k, v in ipairs(data) do
							ix.db.query("DELETE FROM ix_items WHERE _invID = "..v._invID)
							ix.item.inventories[tonumber(v._invID)] = nil
						end
					end

					ix.db.query("DELETE FROM ix_inventories WHERE _charID = "..id)
				end)

				-- other plugins might need to deal with deleted characters.
				hook.Run("OnCharDelete", client, id, isCurrentChar)
				
				if (isCurrentChar) then
					client:SetNetVar("char", nil)
					client:Spawn()
				end
			end
		end)
	else
		netstream.Hook("charInfo", function(data, id, client)
			ix.char.loaded[id] = ix.char.New(data, id, client == nil and LocalPlayer() or client)
		end)

		netstream.Hook("charSet", function(key, value, id)
			id = id or (LocalPlayer():GetChar() and LocalPlayer():GetChar().id)
			
			local character = ix.char.loaded[id]

			if (character) then
				character.vars[key] = value
			end
		end)

		netstream.Hook("charVar", function(key, value, id)
			id = id or (LocalPlayer():GetChar() and LocalPlayer():GetChar().id)

			local character = ix.char.loaded[id]

			if (character) then
				local oldVar = character:GetVar()[key]
				character:GetVar()[key] = value

				hook.Run("OnCharVarChanged", character, key, oldVar, value)
			end
		end)

		netstream.Hook("charMenu", function(data, openNext)
			if (data) then
				ix.characters = data
			end

			OPENNEXT = openNext
			vgui.Create("ixCharMenu")
		end)

		netstream.Hook("charData", function(id, key, value)
			local character = ix.char.loaded[id]

			if (character) then
				character.vars.data = character.vars.data or {}
				character:GetData()[key] = value
			end
		end)

		netstream.Hook("charDel", function(id)
			local isCurrentChar = LocalPlayer():GetChar() and LocalPlayer():GetChar():GetID() == id

			ix.char.loaded[id] = nil

			for k, v in ipairs(ix.characters) do
				if (v == id) then
					table.remove(ix.characters, k)

					if (IsValid(ix.gui.char) and ix.gui.char.setupCharList) then
						ix.gui.char:SetupCharList()
					end
				end
			end

			if (isCurrentChar and !IsValid(ix.gui.char)) then
				vgui.Create("ixCharMenu")
			end
		end)

		netstream.Hook("charKick", function(id, isCurrentChar)
			if (ix.gui.menu and ix.gui.menu:IsVisible()) then
				ix.gui.menu:Remove()
			end

			if (isCurrentChar and !IsValid(ix.gui.char)) then
				vgui.Create("ixCharMenu")
			end
		end)
	end
end

-- Additions to the player metatable here.
do
	local playerMeta = FindMetaTable("Player")
	playerMeta.SteamName = playerMeta.SteamName or playerMeta.Name

	function playerMeta:GetCharacter()
		return ix.char.loaded[self.GetNetVar(self, "char")]
	end

	playerMeta.GetChar = playerMeta.GetCharacter

	function playerMeta:Name()
		local character = self:GetCharacter()
		
		return character and character:GetName() or self:SteamName()
	end

	playerMeta.Nick = playerMeta.Name
	playerMeta.GetName = playerMeta.Name
end
