
--[[--
Character creation and management.

**NOTE:** For the most part you shouldn't use this library unless you know what you're doing. You can very easily corrupt
character data using these functions!
]]
-- @module ix.char

ix.char = ix.char or {}

--- Characters that are currently loaded into memory. This is **not** a table of characters that players are currently using.
-- Characters are automatically loaded when a player joins the server. Entries are not cleared once the player disconnects, as
-- some data is needed after the player has disconnected. Clients will also keep their own version of this table, so don't
-- expect it to be the same as the server's.
--
-- The keys in this table are the IDs of characters, and the values are the `Character` objects that the ID corresponds to.
-- @realm shared
-- @table ix.char.loaded
-- @usage print(ix.char.loaded[1])
-- > character[1]
ix.char.loaded = ix.char.loaded or {}

--- Variables that are stored on characters. This table is populated automatically by `ix.char.RegisterVar`.
-- @realm shared
-- @table ix.char.vars
-- @usage print(ix.char.vars["name"])
-- > table: 0xdeadbeef
ix.char.vars = ix.char.vars or {}

--- Functions similar to `ix.char.loaded`, but is serverside only. This contains a table of all loaded characters grouped by
-- the SteamID64 of the player that owns them.
-- @realm server
-- @table ix.char.cache
ix.char.cache = ix.char.cache or {}

ix.util.Include("helix/gamemode/core/meta/sh_character.lua")

if (SERVER) then
	--- Creates a character object with its assigned properties and saves it to the database.
	-- @realm server
	-- @tab data Properties to assign to this character. If fields are missing from the table, then it will use the default
	-- value for that property
	-- @func callback Function to call after the character saves
	function ix.char.Create(data, callback)
		local timeStamp = math.floor(os.time())

		data.money = data.money or ix.config.Get("defaultMoney", 0)
		data.schema = Schema and Schema.folder or "helix"
		data.createTime = timeStamp
		data.lastJoinTime = timeStamp

		local query = mysql:Insert("ix_characters")
			query:Insert("name", data.name or "")
			query:Insert("description", data.description or "")
			query:Insert("model", data.model or "models/error.mdl")
			query:Insert("schema", Schema and Schema.folder or "helix")
			query:Insert("create_time", data.createTime)
			query:Insert("last_join_time", data.lastJoinTime)
			query:Insert("steamid", data.steamID)
			query:Insert("faction", data.faction or "Unknown")
			query:Insert("money", data.money)
			query:Insert("data", util.TableToJSON(data.data or {}))
			query:Callback(function(result, status, lastID)
				local invQuery = mysql:Insert("ix_inventories")
					invQuery:Insert("character_id", lastID)
					invQuery:Callback(function(invResult, invStats, invLastID)
						local client = player.GetBySteamID64(data.steamID)

						ix.char.RestoreVars(data, data)

						local w, h = ix.config.Get("inventoryWidth"), ix.config.Get("inventoryHeight")
						local character = ix.char.New(data, lastID, client, data.steamID)
						local inventory = ix.inventory.Create(w, h, invLastID)

						character.vars.inv = {inventory}
						inventory:SetOwner(lastID)

						ix.char.loaded[lastID] = character
						table.insert(ix.char.cache[data.steamID], lastID)

						if (callback) then
							callback(lastID)
						end
					end)
				invQuery:Execute()
			end)
		query:Execute()
	end

	--- Loads all of a player's characters into memory.
	-- @realm server
	-- @player client Player to load the characters for
	-- @func[opt=nil] callback Function to call when the characters have been loaded
	-- @bool[opt=false] bNoCache Whether or not to skip the cache; players that leave and join again later will already have
	-- their characters loaded which will skip the database query and load quicker
	-- @number[opt=nil] id The ID of a specific character to load instead of all of the player's characters
	function ix.char.Restore(client, callback, bNoCache, id)
		local steamID64 = client:SteamID64()
		local cache = ix.char.cache[steamID64]

		if (cache and !bNoCache) then
			for _, v in ipairs(cache) do
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

		local query = mysql:Select("ix_characters")
			query:Select("id")

			ix.char.RestoreVars(query)

			query:Where("schema", Schema.folder)
			query:Where("steamid", steamID64)

			if (id) then
				query:Where("id", id)
			end

			query:Callback(function(result)
				local characters = {}

				for _, v in ipairs(result or {}) do
					local charID = tonumber(v.id)

					if (charID) then
						local data = {
							steamID = steamID64
						}

						ix.char.RestoreVars(data, v)

						characters[#characters + 1] = charID
						local character = ix.char.New(data, charID, client)

						hook.Run("CharacterRestored", character)
						character.vars.inv = {
							[1] = -1,
						}

						local invQuery = mysql:Select("ix_inventories")
							invQuery:Select("inventory_id")
							invQuery:Select("inventory_type")
							invQuery:Where("character_id", charID)
							invQuery:Callback(function(info)
								if (istable(info) and #info > 0) then
									local inventories = {}

									for _, v2 in pairs(info) do
										if (v2.inventory_type and isstring(v2.inventory_type) and v2.inventory_type == "NULL") then
											v2.inventory_type = nil
										end

										if (hook.Run("ShouldRestoreInventory", charID, v2.inventory_id, v2.inventory_type) != false) then
											local w, h = ix.config.Get("inventoryWidth"), ix.config.Get("inventoryHeight")
											local invType

											if (v2.inventory_type) then
												invType = ix.item.inventoryTypes[v2.inventory_type]

												if (invType) then
													w, h = invType.w, invType.h
												end
											end

											inventories[tonumber(v2.inventory_id)] = {w, h, v2.inventory_type}
										end
									end

									ix.inventory.Restore(inventories, nil, nil, function(inventory)
										local inventoryType = inventories[inventory:GetID()][3]

										if (inventoryType) then
											inventory.vars.isBag = inventoryType
											table.insert(character.vars.inv, inventory)
										else
											character.vars.inv[1] = inventory
										end

										inventory:SetOwner(charID)
									end, true)
								else
									local insertQuery = mysql:Insert("ix_inventories")
										insertQuery:Insert("character_id", charID)
										insertQuery:Callback(function(_, status, lastID)
											local w, h = ix.config.Get("inventoryWidth"), ix.config.Get("inventoryHeight")
											local inventory = ix.inventory.Create(w, h, lastID)
											inventory:SetOwner(charID)

											character.vars.inv = {
												inventory
											}
										end)
									insertQuery:Execute()
								end
							end)
						invQuery:Execute()

						ix.char.loaded[charID] = character
					else
						ErrorNoHalt("[Helix] Attempt to load character with invalid ID '" .. tostring(id) .. "'!")
					end
				end

				if (callback) then
					callback(characters)
				end

				ix.char.cache[steamID64] = characters
			end)
		query:Execute()
	end

	--- Adds character properties to a table. This is done automatically by `ix.char.Restore`, so that should be used instead if
	-- you are loading characters.
	-- @realm server
	-- @internal
	-- @tab data Table of fields to apply to the table. If this is an SQL query object, it will instead populate the query with
	-- `SELECT` statements for each applicable character var in `ix.char.vars`.
	-- @tab characterInfo Table to apply the properties to. This can be left as `nil` if an SQL query object is passed in `data`
	function ix.char.RestoreVars(data, characterInfo)
		if (data.queryType) then
			-- populate query
			for _, v in pairs(ix.char.vars) do
				if (v.field and v.fieldType and !v.bSaveLoadInitialOnly) then
					data:Select(v.field)

					-- if FilterValues is used, any rows that contain a value in the column that isn't in the valid values table
					-- will be ignored entirely (i.e the character will not load if it has an invalid value)
					if (v.FilterValues) then
						data:WhereIn(v.field, v:FilterValues())
					end
				end
			end
		else
			-- populate character data
			for k, v in pairs(ix.char.vars) do
				if (v.field and characterInfo[v.field] and !v.bSaveLoadInitialOnly) then
					local value = characterInfo[v.field]

					if (isnumber(v.default)) then
						value = tonumber(value) or v.default
					elseif (isstring(v.default)) then
						value = tostring(value) == "NULL" and v.default or tostring(value or v.default)
					elseif (isbool(v.default)) then
						if (tostring(value) != "NULL") then
							value = tobool(value)
						else
							value = v.default
						end
					elseif (istable(v.default)) then
						value = istable(value) and value or util.JSONToTable(value)
					end

					data[k] = value
				end
			end
		end
	end
end

--- Creates a new empty `Character` object. If you are looking to create a usable character, see `ix.char.Create`.
-- @realm shared
-- @internal
-- @tab data Character vars to assign
-- @number id Unique ID of the character
-- @player client Player that will own the character
-- @string[opt=client:SteamID64()] steamID SteamID64 of the player that will own the character
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

		if (SERVER and IsValid(client) or steamID) then
			character.steamID = IsValid(client) and client:SteamID64() or steamID
		end
	return character
end

ix.char.varHooks = ix.char.varHooks or {}
function ix.char.HookVar(varName, hookName, func)
	ix.char.varHooks[varName] = ix.char.varHooks[varName] or {}

	ix.char.varHooks[varName][hookName] = func
end

do
	--- Default character vars
	-- @classmod Character

	--- Sets this character's name. This is automatically networked.
	-- @realm server
	-- @string name New name for the character
	-- @function SetName

	--- Returns this character's name
	-- @realm shared
	-- @treturn string This character's current name
	-- @function GetName
	ix.char.RegisterVar("name", {
		field = "name",
		fieldType = ix.type.string,
		default = "John Doe",
		index = 1,
		OnValidate = function(self, value, payload, client)
			if (!value) then
				return false, "invalid", "name"
			end

			value = tostring(value):gsub("\r\n", ""):gsub("\n", "")
			value = string.Trim(value)

			local minLength = ix.config.Get("minNameLength", 4)
			local maxLength = ix.config.Get("maxNameLength", 32)

			if (value:utf8len() < minLength) then
				return false, "nameMinLen", minLength
			elseif (!value:find("%S")) then
				return false, "invalid", "name"
			elseif (value:gsub("%s", ""):utf8len() > maxLength) then
				return false, "nameMaxLen", maxLength
			end

			return hook.Run("GetDefaultCharacterName", client, payload.faction) or value:utf8sub(1, 70)
		end,
		OnPostSetup = function(self, panel, payload)
			local faction = ix.faction.indices[payload.faction]
			local name, disabled = hook.Run("GetDefaultCharacterName", LocalPlayer(), payload.faction)

			if (name) then
				panel:SetText(name)
				payload:Set("name", name)
			end

			if (disabled) then
				panel:SetDisabled(true)
				panel:SetEditable(false)
			end

			panel:SetBackgroundColor(faction.color or Color(255, 255, 255, 25))
		end
	})

	--- Sets this character's physical description. This is automatically networked.
	-- @realm server
	-- @string description New description for this character
	-- @function SetDescription

	--- Returns this character's physical description.
	-- @realm shared
	-- @treturn string This character's current description
	-- @function GetDescription
	ix.char.RegisterVar("description", {
		field = "description",
		fieldType = ix.type.text,
		default = "",
		index = 2,
		OnValidate = function(self, value, payload)
			value = string.Trim((tostring(value):gsub("\r\n", ""):gsub("\n", "")))
			local minLength = ix.config.Get("minDescriptionLength", 16)

			if (value:utf8len() < minLength) then
				return false, "descMinLen", minLength
			elseif (!value:find("%s+") or !value:find("%S")) then
				return false, "invalid", "description"
			end

			return value
		end,
		OnPostSetup = function(self, panel, payload)
			panel:SetMultiline(true)
			panel:SetFont("ixMenuButtonFont")
			panel:SetTall(panel:GetTall() * 2 + 6) -- add another line
			panel.AllowInput = function(_, character)
				if (character == "\n" or character == "\r") then
					return true
				end
			end
		end,
		alias = "Desc"
	})

	--- Sets this character's model. This sets the player's current model to the given one, and saves it to the character.
	-- It is automatically networked.
	-- @realm server
	-- @string model New model for the character
	-- @function SetModel

	--- Returns this character's model.
	-- @realm shared
	-- @treturn string This character's current model
	-- @function GetModel
	ix.char.RegisterVar("model", {
		field = "model",
		fieldType = ix.type.string,
		default = "models/error.mdl",
		index = 3,
		OnSet = function(character, value)
			local client = character:GetPlayer()

			if (IsValid(client) and client:GetCharacter() == character) then
				client:SetModel(value)
			end

			character.vars.model = value
		end,
		OnGet = function(character, default)
			return character.vars.model or default
		end,
		OnDisplay = function(self, container, payload)
			local scroll = container:Add("DScrollPanel")
			scroll:Dock(FILL) -- TODO: don't fill so we can allow other panels
			scroll.Paint = function(panel, width, height)
				derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, Color(255, 255, 255, 25))
			end

			local layout = scroll:Add("DIconLayout")
			layout:Dock(FILL)
			layout:SetSpaceX(1)
			layout:SetSpaceY(1)

			local faction = ix.faction.indices[payload.faction]

			if (faction) then
				local models = faction:GetModels(LocalPlayer())

				for k, v in SortedPairs(models) do
					local icon = layout:Add("SpawnIcon")
					icon:SetSize(64, 128)
					icon:InvalidateLayout(true)
					icon.DoClick = function(this)
						payload:Set("model", k)
					end
					icon.PaintOver = function(this, w, h)
						if (payload.model == k) then
							local color = ix.config.Get("color", color_white)

							surface.SetDrawColor(color.r, color.g, color.b, 200)

							for i = 1, 3 do
								local i2 = i * 2
								surface.DrawOutlinedRect(i, i, w - i2, h - i2)
							end
						end
					end

					if (isstring(v)) then
						icon:SetModel(v)
					else
						icon:SetModel(v[1], v[2] or 0, v[3])
					end
				end
			end

			return scroll
		end,
		OnValidate = function(self, value, payload, client)
			local faction = ix.faction.indices[payload.faction]

			if (faction) then
				local models = faction:GetModels(client)

				if (!payload.model or !models[payload.model]) then
					return false, "needModel"
				end
			else
				return false, "needModel"
			end
		end,
		OnAdjust = function(self, client, data, value, newData)
			local faction = ix.faction.indices[data.faction]

			if (faction) then
				local model = faction:GetModels(client)[value]

				if (isstring(model)) then
					newData.model = model
				elseif (istable(model)) then
					newData.model = model[1]

					-- save skin/bodygroups to character data
					local bodygroups = {}

					for i = 1, #model[3] do
						bodygroups[i - 1] = tonumber(model[3][i]) or 0
					end

					newData.data = newData.data or {}
					newData.data.skin = model[2] or 0
					newData.data.groups = bodygroups
				end
			end
		end,
		ShouldDisplay = function(self, container, payload)
			local faction = ix.faction.indices[payload.faction]
			return #faction:GetModels(LocalPlayer()) > 1
		end
	})

	-- SetClass shouldn't be used here, character:JoinClass should be used instead

	--- Returns this character's current class.
	-- @realm shared
	-- @treturn number Index of the class this character is in
	-- @function GetClass
	ix.char.RegisterVar("class", {
		bNoDisplay = true,
	})

	--- Sets this character's faction. Note that this doesn't do the initial setup for the player after the faction has been
	-- changed, so you'll have to update some character vars manually.
	-- @realm server
	-- @number faction Index of the faction to transfer this character to
	-- @function SetFaction

	--- Returns this character's faction.
	-- @realm shared
	-- @treturn number Index of the faction this character is currently in
	-- @function GetFaction
	ix.char.RegisterVar("faction", {
		field = "faction",
		fieldType = ix.type.string,
		default = "Citizen",
		bNoDisplay = true,
		FilterValues = function(self)
			-- make sequential table of faction unique IDs
			local values = {}

			for k, v in ipairs(ix.faction.indices) do
				values[k] = v.uniqueID
			end

			return values
		end,
		OnSet = function(self, value)
			local client = self:GetPlayer()

			if (IsValid(client)) then
				self.vars.faction = ix.faction.indices[value] and ix.faction.indices[value].uniqueID

				client:SetTeam(value)

				-- @todo refactor networking of character vars so this doesn't need to be repeated on every OnSet override
				net.Start("ixCharacterVarChanged")
					net.WriteUInt(self:GetID(), 32)
					net.WriteString("faction")
					net.WriteType(self.vars.faction)
				net.Broadcast()
			end
		end,
		OnGet = function(self, default)
			local faction = ix.faction.teams[self.vars.faction]

			return faction and faction.index or 0
		end,
		OnValidate = function(self, index, data, client)
			if (index and client:HasWhitelist(index)) then
				return true
			end

			return false
		end,
		OnAdjust = function(self, client, data, value, newData)
			newData.faction = ix.faction.indices[value].uniqueID
		end
	})

	-- attribute manipulation should be done with methods from the ix.attributes library
	ix.char.RegisterVar("attributes", {
		field = "attributes",
		fieldType = ix.type.text,
		default = {},
		index = 4,
		category = "attributes",
		isLocal = true,
		OnDisplay = function(self, container, payload)
			local maximum = hook.Run("GetDefaultAttributePoints", LocalPlayer(), payload) or 10

			if (maximum < 1) then
				return
			end

			local attributes = container:Add("DPanel")
			attributes:Dock(TOP)

			local y
			local total = 0

			payload.attributes = {}

			-- total spendable attribute points
			local totalBar = attributes:Add("ixAttributeBar")
			totalBar:SetMax(maximum)
			totalBar:SetValue(maximum)
			totalBar:Dock(TOP)
			totalBar:DockMargin(2, 2, 2, 2)
			totalBar:SetText(L("attribPointsLeft"))
			totalBar:SetReadOnly(true)
			totalBar:SetColor(Color(20, 120, 20, 255))

			y = totalBar:GetTall() + 4

			for k, v in SortedPairsByMemberValue(ix.attributes.list, "name") do
				payload.attributes[k] = 0

				local bar = attributes:Add("ixAttributeBar")
				bar:SetMax(maximum)
				bar:Dock(TOP)
				bar:DockMargin(2, 2, 2, 2)
				bar:SetText(L(v.name))
				bar.OnChanged = function(this, difference)
					if ((total + difference) > maximum) then
						return false
					end

					total = total + difference
					payload.attributes[k] = payload.attributes[k] + difference

					totalBar:SetValue(totalBar.value - difference)
				end

				if (v.noStartBonus) then
					bar:SetReadOnly()
				end

				y = y + bar:GetTall() + 4
			end

			attributes:SetTall(y)
			return attributes
		end,
		OnValidate = function(self, value, data, client)
			if (value != nil) then
				if (istable(value)) then
					local count = 0

					for _, v in pairs(value) do
						count = count + v
					end

					if (count > (hook.Run("GetDefaultAttributePoints", client, count) or 10)) then
						return false, "unknownError"
					end
				else
					return false, "unknownError"
				end
			end
		end,
		ShouldDisplay = function(self, container, payload)
			return !table.IsEmpty(ix.attributes.list)
		end
	})

	--- Sets this character's current money. Money is only networked to the player that owns this character.
	-- @realm server
	-- @number money New amount of money this character should have
	-- @function SetMoney

	--- Returns this character's money. This is only valid on the server and the owning client.
	-- @realm shared
	-- @treturn number Current money of this character
	-- @function GetMoney
	ix.char.RegisterVar("money", {
		field = "money",
		fieldType = ix.type.number,
		default = 0,
		isLocal = true,
		bNoDisplay = true
	})

	--- Sets a data field on this character. This is useful for storing small bits of data that you need persisted on this
	-- character. This is networked only to the owning client. If you are going to be accessing this data field frequently with
	-- a getter/setter, consider using `ix.char.RegisterVar` instead.
	-- @realm server
	-- @string key Name of the field that holds the data
	-- @param value Any value to store in the field, as long as it's supported by GMod's JSON parser
	-- @function SetData

	--- Returns a data field set on this character. If it doesn't exist, it will return the given default or `nil`. This is only
	-- valid on the server and the owning client.
	-- @realm shared
	-- @string key Name of the field that's holding the data
	-- @param default Value to return if the given key doesn't exist, or is `nil`
	-- @return[1] Data stored in the field
	-- @treturn[2] nil If the data doesn't exist, or is `nil`
	-- @function GetData
	ix.char.RegisterVar("data", {
		default = {},
		isLocal = true,
		bNoDisplay = true,
		field = "data",
		fieldType = ix.type.text,
		OnSet = function(character, key, value, noReplication, receiver)
			local data = character:GetData()
			local client = character:GetPlayer()

			data[key] = value

			if (!noReplication and IsValid(client)) then
				net.Start("ixCharacterData")
					net.WriteUInt(character:GetID(), 32)
					net.WriteString(key)
					net.WriteType(value)
				net.Send(receiver or client)
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
		bNoDisplay = true,
		OnSet = function(character, key, value, noReplication, receiver)
			local data = character:GetVar()
			local client = character:GetPlayer()

			data[key] = value

			if (!noReplication and IsValid(client)) then
				local id

				if (client:GetCharacter() and client:GetCharacter():GetID() == character:GetID()) then
					id = client:GetCharacter():GetID()
				else
					id = character:GetID()
				end

				net.Start("ixCharacterVar")
					net.WriteUInt(id, 32)
					net.WriteString(key)
					net.WriteType(value)
				net.Send(receiver or client)
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

	--- Returns the Unix timestamp of when this character was created (i.e the value of `os.time()` at the time of creation).
	-- @realm server
	-- @treturn number Unix timestamp of when this character was created
	-- @function GetCreateTime
	ix.char.RegisterVar("createTime", {
		field = "create_time",
		fieldType = ix.type.number,
		bNoDisplay = true,
		bNoNetworking = true,
		bNotModifiable = true
	})

	--- Returns the Unix timestamp of when this character was last used by its owning player.
	-- @realm server
	-- @treturn number Unix timestamp of when this character was last used
	-- @function GetLastJoinTime
	ix.char.RegisterVar("lastJoinTime", {
		field = "last_join_time",
		fieldType = ix.type.number,
		bNoDisplay = true,
		bNoNetworking = true,
		bNotModifiable = true,
		bSaveLoadInitialOnly = true
	})

	--- Returns the schema that this character belongs to. This is useful if you are running multiple schemas off of the same
	-- database, and need to differentiate between them.
	-- @realm server
	-- @treturn string Schema this character belongs to
	-- @function GetSchema
	ix.char.RegisterVar("schema", {
		field = "schema",
		fieldType = ix.type.string,
		bNoDisplay = true,
		bNoNetworking = true,
		bNotModifiable = true,
		bSaveLoadInitialOnly = true
	})

	--- Returns the 64-bit Steam ID of the player that owns this character.
	-- @realm server
	-- @treturn string Owning player's Steam ID
	-- @function GetSteamID
	ix.char.RegisterVar("steamID", {
		field = "steamid",
		fieldType = ix.type.steamid,
		bNoDisplay = true,
		bNoNetworking = true,
		bNotModifiable = true,
		bSaveLoadInitialOnly = true
	})
end

-- Networking information here.
do
	if (SERVER) then
		util.AddNetworkString("ixCharacterMenu")
		util.AddNetworkString("ixCharacterChoose")
		util.AddNetworkString("ixCharacterCreate")
		util.AddNetworkString("ixCharacterDelete")
		util.AddNetworkString("ixCharacterLoaded")
		util.AddNetworkString("ixCharacterLoadFailure")

		util.AddNetworkString("ixCharacterAuthed")
		util.AddNetworkString("ixCharacterAuthFailed")

		util.AddNetworkString("ixCharacterInfo")
		util.AddNetworkString("ixCharacterData")
		util.AddNetworkString("ixCharacterKick")
		util.AddNetworkString("ixCharacterSet")
		util.AddNetworkString("ixCharacterVar")
		util.AddNetworkString("ixCharacterVarChanged")

		net.Receive("ixCharacterChoose", function(length, client)
			local id = net.ReadUInt(32)

			if (client:GetCharacter() and client:GetCharacter():GetID() == id) then
				net.Start("ixCharacterLoadFailure")
					net.WriteString("@usingChar")
				net.Send(client)
				return
			end

			local character = ix.char.loaded[id]

			if (character and character:GetPlayer() == client) then
				local status, result = hook.Run("CanPlayerUseCharacter", client, character)

				if (status == false) then
					net.Start("ixCharacterLoadFailure")
						net.WriteString(result or "")
					net.Send(client)
					return
				end

				local currentChar = client:GetCharacter()

				if (currentChar) then
					currentChar:Save()

					for _, v in ipairs(currentChar:GetInventory(true)) do
						if (istable(v)) then
							v:RemoveReceiver(client)
						end
					end
				end

				hook.Run("PrePlayerLoadedCharacter", client, character, currentChar)
				character:Setup()
				client:Spawn()

				hook.Run("PlayerLoadedCharacter", client, character, currentChar)
			else
				net.Start("ixCharacterLoadFailure")
					net.WriteString("@unknownError")
				net.Send(client)

				ErrorNoHalt("[Helix] Attempt to load invalid character '" .. id .. "'\n")
			end
		end)

		net.Receive("ixCharacterCreate", function(length, client)
			if ((client.ixNextCharacterCreate or 0) > RealTime()) then
				return
			end

			local maxChars = hook.Run("GetMaxPlayerCharacter", client) or ix.config.Get("maxCharacters", 5)
			local charList = client.ixCharList
			local charCount = table.Count(charList)

			if (charCount >= maxChars) then
				net.Start("ixCharacterAuthFailed")
					net.WriteString("maxCharacters")
					net.WriteTable({})
				net.Send(client)

				return
			end

			client.ixNextCharacterCreate = RealTime() + 1

			local indicies = net.ReadUInt(8)
			local payload = {}

			for _ = 1, indicies do
				payload[net.ReadString()] = net.ReadType()
			end

			local newPayload = {}
			local results = {hook.Run("CanPlayerCreateCharacter", client, payload)}

			if (table.remove(results, 1) == false) then
				net.Start("ixCharacterAuthFailed")
					net.WriteString(table.remove(results, 1) or "unknownError")
					net.WriteTable(results)
				net.Send(client)

				return
			end

			for k, _ in pairs(payload) do
				local info = ix.char.vars[k]

				if (!info or (!info.OnValidate and info.bNoDisplay)) then
					payload[k] = nil
				end
			end

			for k, v in SortedPairsByMemberValue(ix.char.vars, "index") do
				local value = payload[k]

				if (v.OnValidate) then
					local result = {v:OnValidate(value, payload, client)}

					if (result[1] == false) then
						local fault = result[2]

						table.remove(result, 2)
						table.remove(result, 1)

						net.Start("ixCharacterAuthFailed")
							net.WriteString(fault)
							net.WriteTable(result)
						net.Send(client)

						return
					else
						if (result[1] != nil) then
							payload[k] = result[1]
						end

						if (v.OnAdjust) then
							v:OnAdjust(client, payload, value, newPayload)
						end
					end
				end
			end

			payload.steamID = client:SteamID64()
				hook.Run("AdjustCreationPayload", client, payload, newPayload)
			payload = table.Merge(payload, newPayload)

			ix.char.Create(payload, function(id)
				if (IsValid(client)) then
					ix.char.loaded[id]:Sync(client)

					net.Start("ixCharacterAuthed")
					net.WriteUInt(id, 32)
					net.WriteUInt(#client.ixCharList, 6)

					for _, v in ipairs(client.ixCharList) do
						net.WriteUInt(v, 32)
					end

					net.Send(client)

					MsgN("Created character '" .. id .. "' for " .. client:SteamName() .. ".")
					hook.Run("OnCharacterCreated", client, ix.char.loaded[id])
				end
			end)
		end)

		net.Receive("ixCharacterDelete", function(length, client)
			local id = net.ReadUInt(32)
			local character = ix.char.loaded[id]
			local steamID = client:SteamID64()
			local isCurrentChar = client:GetCharacter() and client:GetCharacter():GetID() == id

			if (character and character.steamID == steamID) then
				for k, v in ipairs(client.ixCharList or {}) do
					if (v == id) then
						table.remove(client.ixCharList, k)
					end
				end

				hook.Run("PreCharacterDeleted", client, character)
				ix.char.loaded[id] = nil

				net.Start("ixCharacterDelete")
					net.WriteUInt(id, 32)
				net.Broadcast()

				-- remove character from database
				local query = mysql:Delete("ix_characters")
					query:Where("id", id)
					query:Where("steamid", client:SteamID64())
				query:Execute()

				-- DBTODO: setup relations instead
				-- remove inventory from database
				query = mysql:Select("ix_inventories")
					query:Select("inventory_id")
					query:Where("character_id", id)
					query:Callback(function(result)
						if (istable(result)) then
							-- remove associated items from database
							for _, v in ipairs(result) do
								local itemQuery = mysql:Delete("ix_items")
									itemQuery:Where("inventory_id", v.inventory_id)
								itemQuery:Execute()

								ix.item.inventories[tonumber(v.inventory_id)] = nil
							end
						end

						local invQuery = mysql:Delete("ix_inventories")
							invQuery:Where("character_id", id)
						invQuery:Execute()
					end)
				query:Execute()

				-- other plugins might need to deal with deleted characters.
				hook.Run("CharacterDeleted", client, id, isCurrentChar)

				if (isCurrentChar) then
					client:SetNetVar("char", nil)
					client:KillSilent()
					client:StripAmmo()
				end
			end
		end)
	else
		net.Receive("ixCharacterInfo", function()
			local data = net.ReadTable()
			local id = net.ReadUInt(32)
			local client = net.ReadUInt(8)

			ix.char.loaded[id] = ix.char.New(data, id, client)
		end)

		net.Receive("ixCharacterVarChanged", function()
			local id = net.ReadUInt(32)
			local character = ix.char.loaded[id]

			if (character) then
				local key = net.ReadString()
				local value = net.ReadType()

				character.vars[key] = value
			end
		end)

		-- Used for setting random access vars on the "var" character var (really stupid).
		-- Clean this up someday.
		net.Receive("ixCharacterVar", function()
			local id = net.ReadUInt(32)
			local character = ix.char.loaded[id]

			if (character) then
				local key = net.ReadString()
				local value = net.ReadType()
				local oldVar = character:GetVar()[key]
				character:GetVar()[key] = value

				hook.Run("CharacterVarChanged", character, key, oldVar, value)
			end
		end)

		net.Receive("ixCharacterMenu", function()
			local indices = net.ReadUInt(6)
			local charList = {}

			for _ = 1, indices do
				charList[#charList + 1] = net.ReadUInt(32)
			end

			if (charList) then
				ix.characters = charList
			end

			vgui.Create("ixCharMenu")
		end)

		net.Receive("ixCharacterLoadFailure", function()
			local message = net.ReadString()

			if (isstring(message) and message:sub(1, 1) == "@") then
				message = L(message:sub(2))
			end

			message = message != "" and message or L("unknownError")

			if (IsValid(ix.gui.characterMenu)) then
				ix.gui.characterMenu:OnCharacterLoadFailed(message)
			else
				ix.util.Notify(message)
			end
		end)

		net.Receive("ixCharacterData", function()
			local id = net.ReadUInt(32)
			local key = net.ReadString()
			local value = net.ReadType()
			local character = ix.char.loaded[id]

			if (character) then
				character.vars.data = character.vars.data or {}
				character:GetData()[key] = value
			end
		end)

		net.Receive("ixCharacterDelete", function()
			local id = net.ReadUInt(32)
			local isCurrentChar = LocalPlayer():GetCharacter() and LocalPlayer():GetCharacter():GetID() == id
			local character = ix.char.loaded[id]

			ix.char.loaded[id] = nil

			for k, v in ipairs(ix.characters) do
				if (v == id) then
					table.remove(ix.characters, k)

					if (IsValid(ix.gui.characterMenu)) then
						ix.gui.characterMenu:OnCharacterDeleted(character)
					end
				end
			end

			if (isCurrentChar and !IsValid(ix.gui.characterMenu)) then
				vgui.Create("ixCharMenu")
			end
		end)

		net.Receive("ixCharacterKick", function()
			local isCurrentChar = net.ReadBool()

			if (ix.gui.menu and ix.gui.menu:IsVisible()) then
				ix.gui.menu:Remove()
			end

			if (!IsValid(ix.gui.characterMenu)) then
				vgui.Create("ixCharMenu")
			elseif (ix.gui.characterMenu:IsClosing()) then
				ix.gui.characterMenu:Remove()
				vgui.Create("ixCharMenu")
			end

			if (isCurrentChar) then
				ix.gui.characterMenu.mainPanel:UpdateReturnButton(false)
			end
		end)

		net.Receive("ixCharacterLoaded", function()
			hook.Run("CharacterLoaded", ix.char.loaded[net.ReadUInt(32)])
		end)
	end
end

do
	--- Character util functions for player
	-- @classmod Player

	local playerMeta = FindMetaTable("Player")
	playerMeta.SteamName = playerMeta.SteamName or playerMeta.Name

	--- Returns this player's currently possessed `Character` object if it exists.
	-- @realm shared
	-- @treturn[1] Character Currently loaded character
	-- @treturn[2] nil If this player has no character loaded
	function playerMeta:GetCharacter()
		return ix.char.loaded[self:GetNetVar("char")]
	end

	playerMeta.GetChar = playerMeta.GetCharacter

	--- Returns this player's current name.
	-- @realm shared
	-- @treturn[1] string Name of this player's currently loaded character
	-- @treturn[2] string Steam name of this player if the player has no character loaded
	function playerMeta:GetName()
		local character = self:GetCharacter()

		return character and character:GetName() or self:SteamName()
	end

	playerMeta.Nick = playerMeta.GetName
	playerMeta.Name = playerMeta.GetName
end
