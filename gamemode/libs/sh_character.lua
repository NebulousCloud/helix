--[[
	Purpose: Provides a class for characters using metatables and
	has a library that will create characters for players. In addition,
	this includes networking for character data.
--]]

-- Weird way of including dependencies.
if (SERVER and !nut.db) then
	include("sv_database.lua")
end

if (!nut.schema) then
	include("sh_schema.lua")
end

if (!von) then
	include("sh_von.lua")
end

if (!netstream) then
	include("sh_netstream.lua")
end

do
	-- Overwrite the player:Name() function to return the character name if it exists,
	-- otherwise return the original Steam name.
	local playerMeta = FindMetaTable("Player")
	playerMeta.NutName = playerMeta.NutName or playerMeta.Name

	-- Alias to the old function before it gets overwritten.
	playerMeta.RealName = playerMeta.RealName or playerMeta.Name
	playerMeta.SteamName = playerMeta.RealName

	function playerMeta:Name()
		if (self.character) then
			return self.character:GetVar("charname", "John Doe")
		end

		return self:NutName()
	end

	playerMeta.Nick = playerMeta.Name
	playerMeta.GetName = playerMeta.Name
end

nut.char = nut.char or {}
nut.char.buffer = nut.char.buffer or {}
nut.char.hooks = nut.char.hooks or {}
nut.char.dataTypes = nut.char.dataTypes or {}

-- We begin our metatable here.
local META = {}
META.__index = META

-- Public variable and private variable enums.
CHAR_PUBLIC = 1
CHAR_PRIVATE = 2

--[[
	Purpose: Predefines a variable and places it in the correct table for type
	of variables that will be used for networking. It also sets a default value
	with the second argument.
--]]
function META:NewVar(name, value, state, noSave)
	local dataType = type(value)

	if (dataType == "table") then
		self.dataTypes[name] = von.deserialize
	elseif (dataType == "number") then
		self.dataTypes[name] = tonumber
	elseif (dataType == "boolean") then
		self.dataTypes[name] = tobool
	end

	if (state == CHAR_PRIVATE) then
		self.privateVars[name] = value
	else
		self.publicVars[name] = value
	end

	if (noSave) then
		self.noSaveVars[name] = true
	end
end

if (SERVER) then
	local playerMeta = FindMetaTable("Player")

	function playerMeta:UpdateCharInfo()
		if (self.character) then
			netstream.Start(client, "nut_CharInfo", {
				self.character:GetVar("charname", "John Doe"),
				self.character:GetVar("description", "No description available."),
				self:GetModel(),
				self:Team(),
				self.character.index,
				self:GetSkin()
			})
		end
	end
end

--[[
	Purpose: Sets the actual variable that is defined by :NewVar and networks it
	to the receiver which is either a player, table, or nil. Using nil as the receiver
	will broadcast it to the server so every player receives the data.
--]]
function META:SetVar(name, value, receiver, convert)
	if (convert and self.dataTypes[name]) then
		value = self.dataTypes[name](value)
	end

	if (self.privateVars[name]) then
		receiver = self.player
		self.privateVars[name] = value
	else
		self.publicVars[name] = value
	end

	if (SERVER) then
		self:Send(name, receiver)

		if (name == "charname" or name == "description" or name == "model" or name == "chardata") then
			self.player:UpdateCharInfo()
		end
	end

	if (nut.char.hooks[name]) then
		for k, v in pairs(nut.char.hooks[name]) do
			v(self)
		end
	end
end

--[[
	Purpose: Returns the public variables and private variables into one tableto be used for
	saving characters.
--]]
function META:GetVars()
	local variables = {};

	for k, v in pairs(self.publicVars) do
		if (!self.noSaveVars[k]) then
			variables[k] = v
		end
	end

	for k, v in pairs(self.privateVars) do
		if (!self.noSaveVars[k]) then
			variables[k] = v
		end
	end

	return variables
end

--[[
	Purpose: Returns a variable that has been defined by :NewVar or returns the default
	value if the second argument is specified.
--]]
function META:GetVar(name, default)
	if (self.privateVars and self.privateVars[name]) then
		return self.privateVars[name]
	elseif (self.publicVars and self.publicVars[name]) then
		return self.publicVars[name]
	else
		return default
	end
end

--[[
	Purpose: A quick utility method to set a member of the data field and send it to the receiver.
--]]
function META:SetData(key, value, receiver, noSend)
	self:GetVar("chardata")[key] = value

	if (!noSend) then
		self:Send("chardata", receiver)
	end
end

--[[
	Purpose: Gets a value from the character data.
--]]
function META:GetData(key, default)
	if (self:GetVar("chardata")[key]) then
		return self:GetVar("chardata")[key]
	end

	return default
end

--[[
	Purpose: Returns the table of character data.
--]]
function META:GetDataTable()
	return self:GetVar("chardata")
end

local function replacePlaceHolders(value)
	for k, v in pairs(value) do
		if (type(v) == "table") then
			v = replacePlaceHolders(v)
		elseif (type(v) == "string" and v == "__nil") then
			value[k] = nil
		end
	end

	return value
end

--[[
	Purpose: Using the variables defined by :NewVar, it will send the data to the receiver
	if it is a public var, or only send it to the character's owner when it is private.
	If a field is not known, it will give an error. If variable is nil, then it sends all
	neccessary information based off it's state of either private or public.
--]]
function META:Send(variable, receiver, noDelta)
	local privateValue = self.privateVars[variable]
	local publicValue = self.publicVars[variable]
	local deltaValue = self.deltas[variable]

	if (!variable) then
		for k, v in pairs(self.publicVars) do
			self:Send(k, receiver, noDelta)
		end

		if (!receiver or receiver == self.player) then
			for k, v in pairs(self.privateVars) do
				self:Send(k, self.player, noDelta)
			end
		end
	elseif (privateValue) then
		if (!noDelta and type(privateValue) == "table") then
			local oldValue = privateValue
			privateValue = nut.util.GetTableDelta(privateValue, self.deltas[variable] or {})

			self.deltas[variable] = table.Copy(oldValue)
		end

		netstream.Start(self.player, "nut_LocalCharData", {variable, privateValue, noDelta})
	elseif (publicValue) then
		if (!noDelta and type(publicValue) == "table") then
			local oldValue = publicValue
			publicValue = nut.util.GetTableDelta(publicValue, self.deltas[variable] or {})

			self.deltas[variable] = table.Copy(oldValue)
		end

		netstream.Start(receiver, "nut_CharData", {self.player:EntIndex(), variable, publicValue, noDelta})
	else
		error("Attempted to send unknown character data!")
	end
end

--[[
	Purpose: A nice name for printing characters rather than just stating
	it is a table.
--]]
function META.__tostring(character)
	return "Character ["..(IsValid(character.player) and character.player:SteamName() or "NULL").."]["..character:GetVar("charname", "John Doe").."]"
end

setmetatable(META, {
	__tostring = function(character)
		return "Character ["..(IsValid(character.player) and character.player:SteamName() or "NULL").."]["..character:GetVar("charname", "John Doe").."]"
	end
})
debug.getregistry().Character = META

--[[
	Purpose: Returns a new character that has the owner set to the first argument,
	and will broadcast the information if ran on the server and send is true.
--]]
function nut.char.New(client, send)
	if (send == nil) then
		send = true
	end

	local character = setmetatable({
		player = client,
		privateVars = {},
		publicVars = {},
		dataTypes = {},
		noSaveVars = {},
		deltas = {}
	}, META)

	nut.schema.Call("CreateCharVars", character)

	if (SERVER and send) then
		character:Send(nil, nil, true)
	end

	table.insert(nut.char.buffer, character)

	return character
end

--[[
	Purpose: Returns a table of characters where the owner of the character is valid.
	It will also remove any characters with invalid players.
--]]
function nut.char.GetAll()
	local output = {}

	for k, v in pairs(nut.char.buffer) do
		if (IsValid(v.player)) then
			output[#output + 1] = v
		else
			table.remove(nut.char.buffer, k)
		end
	end

	return output
end

--[[
	Purpose: Similar to regular hooks, calls the function provided when the
	variable for the character has been changed.
--]]
function nut.char.HookVar(variable, uniqueID, callback)
	nut.char.hooks[variable] = nut.char.hooks[variable] or {}
	nut.char.hooks[variable][uniqueID] = callback
end

if (SERVER) then
	-- Quick function to return a string for MySQL conditions.
	local function sameSchema()
		return " AND rpschema = '"..SCHEMA.uniqueID.."'"
	end

	--[[
		Purpose: A function to insert a new character into the database with predefined
		information like the name for the second argument. In addition, the ID for the character
		is already calculated when calling this and the steamid and schema are defined.
	--]]
	function nut.char.Create(client, data, callback)
		local steamID = client:SteamID64()
		local condition = "steamid = "..steamID..sameSchema()

		nut.db.FetchTable(condition, "id", function(_, data3)
			data.steamid = client:SteamID64()
			data.rpschema = SCHEMA.uniqueID

			local highest = 0

			if (data3) then
				for k, v in pairs(data3) do
					local actualID = tonumber(v.id)

					if (actualID and actualID > highest) then
						highest = actualID
					end
				end

				data.id = highest + 1
			else
				data.id = 1
			end

			nut.db.InsertTable(data)

			if (callback) then
				callback(data.id)
			end
		end)
	end

	--[[
		Purpose: Loads a character from the database and creates a new character object.
		If the character does not exist, an error will be created.
	--]]
	function nut.char.LoadID(client, index, callback)
		local steamID = client:SteamID64()
		local condition = "steamid = "..steamID.." AND id = "..index..sameSchema()
		local tables = "money, chardata, charname, inv, description, faction, id, model"
		local sameChar = false

		if (client.character and client.character.index == index) then
			sameChar = true
		end

		client.nut_CachedChars = client.nut_CachedChars or {}

		if (client.nut_CachedChars[index]) then
			client.character = client.nut_CachedChars[index]
				for name, _ in pairs(client.character:GetVars()) do
					if (nut.char.hooks[name]) then
						for k, v in pairs(nut.char.hooks[name]) do
							v(client.character)
						end
					end
				end
			client.character:Send(nil, nil, true)

			print("Restoring cached character '"..client.character:GetVar("charname").."' for "..client:RealName()..".")

			if (callback) then
				callback(sameChar)
			end

			return
		end

		nut.db.FetchTable(condition, tables, function(data)
			if (IsValid(client)) then
				if (data) then
					if (!sameChar) then
						if (string.find(data.model, ";")) then
							local exploded = string.Explode(";", data.model)

							data.model = exploded[1]
							data.skin = tonumber(exploded[2])
						end

						local character = nut.char.New(client)
						character.index = index
						character.model = data.model
						character.skin = data.skin

						for k, v in pairs(data) do
							character:SetVar(k, v, nil, true)
						end
						
						client.character = character
						client.nut_CachedChars[index] = client.character

						print("Loaded character '"..client.character:GetVar("charname").."' for "..client:RealName()..".")
					end

					if (callback) then
						callback(sameChar)
					end
				else
					error("Attempt to load an invalid character ("..client:Name().." #"..index..")")
				end
			end
		end)
	end

	--[[
		Purpose: Sends character information for a player that is to be used in the character
		listing.
	--]]
	function nut.char.SendInfo(client, index)
		local steamID = client:SteamID64()
		local condition = "steamid = "..steamID.." AND id = "..index..sameSchema()
		local tables = "charname, faction, id, description, model"
		
		nut.db.FetchTable(condition, tables, function(data)
			if (IsValid(client)) then
				if (data and table.Count(data) > 0) then
					client.characters = client.characters or {};
					table.insert(client.characters, tonumber(data.id))
					
					if (string.find(data.model, ";")) then
						local exploded = string.Explode(";", data.model)

						data.model = exploded[1]
						data.skin = tonumber(exploded[2])
					end

					netstream.Start(client, "nut_CharInfo", {data.charname, data.description, data.model, data.faction, data.id, data.skin})
				else
					error("Attempt to load an invalid character ("..client:Name().." #"..index..")")
				end
			end
		end)
	end

	--[[
		Purpose: Loads all the characters from the database and sends them to the player. If
		a callback is provided, it will be ran with no arguments.
	--]]
	function nut.char.Load(client, callback)
		nut.db.FetchTable("steamid = "..client:SteamID64()..sameSchema(), "id", function(_, data)
			if (IsValid(client)) then
				for k, v in SortedPairs(data) do
					nut.char.SendInfo(client, v.id)
				end

				if (callback) then
					callback()
				end
			end
		end)
	end

	--[[
		Purpose: Saves the active character of a player to the database.
	--]]
	function nut.char.Save(client)
		if (!IsValid(client)) then
			return
		end
		
		local steamID = client:SteamID64()
		local character = client.character

		if (!character) then
			return
		end

		local skin = client:GetSkin()

		if (skin > 0) then
			client.character:SetData("skin", skin)
		end

		nut.schema.Call("CharacterSave", client)

		local customClass = client:GetNetVar("customClass")

		if (customClass and customClass != "") then
			client.character:SetData("customClass", customClass)
		else
			client.character:SetData("customClass", nil)
		end

		local index = character.index
		local data = character:GetVars()
		data.model = client:GetModel()

		if (data.skin) then
			data.model = data.model..";"..data.skin
		end

		nut.db.UpdateTable("steamid = "..steamID.." AND id = "..index..sameSchema(), data)
		client:SaveData()

		print("Saved '"..client.character:GetVar("charname").."' for "..client:RealName()..".")
	end

	-- Validate the character creation request and sends a message to close the creation
	-- menu when the character has been inserted into the database.
	netstream.Hook("nut_CharCreate", function(client, data)
		if (!IsValid(client)) then
			return
		end

		if (client.characters and table.Count(client.characters) >= nut.config.maxChars) then
			return
		end

		local name = string.sub(data.name, 1, nut.config.maxNameLength or 70)
		local gender = string.lower(data.gender)
		local desc = string.sub(data.desc, 1, nut.config.maxDescLength or 240)
		local model = data.model
		local faction = data.faction
		local attributes = data.attribs or {}

		local totalPoints = 0

		for k, v in pairs(attributes) do
			totalPoints = totalPoints + v
		end

		if (!name or (gender != "male" and gender != "female") or
			!desc or !model or !faction or !nut.faction.GetByID(faction)
			or !nut.faction.CanBe(client, faction) or !attributes
			or totalPoints > nut.config.startingPoints) then
			client:ChatPrint("Invalid character creation response!")

			return
		end

		local data = {}

		for k, v in pairs(attributes) do
			local attribute = nut.attribs.buffer[k]

			if (attribute) then
				data["attrib_"..attribute.uniqueID] = v
			end
		end

		data.flags = nut.config.defaultFlags
		
		local charData = {}
		charData.charname = name
		charData.description = desc
		charData.gender = gender
		charData.money = 0
		charData.inv = {}
		charData.chardata = data
		charData.faction = faction
		charData.model = model

		local inventory = {}
		inventory.buffer = {}

		function inventory:Add(class, quantity, data2)
			self.buffer = nut.util.StackInv(self.buffer, class, quantity, data2)
		end

		nut.schema.Call("GetDefaultInv", inventory, client, charData)

		charData.inv = inventory.buffer
		charData.money = nut.schema.Call("GetDefaultMoney", client, charData)

		nut.char.Create(client, charData, function(id)
			timer.Simple(math.max(client:Ping() / 100, 0.1), function()
				nut.char.SendInfo(client, id)

				timer.Simple(math.max(client:Ping() / 100, 0.1), function()
					netstream.Start(client, "nut_CharCreateAuthed")
				end)

				nut.schema.Call("PlayerCreatedChar", client, charData)
				
				print("Created new character '"..name.."' for "..client:RealName()..".")
			end)
		end)
	end)

	-- Spawns the player with their appropriate character and closes the main menu.
	netstream.Hook("nut_CharChoose", function(client, index)
		if (client.character and client.character.index != index) then
			nut.char.Save(client)
			nut.schema.Call("OnCharChanged", client)
		end

		nut.char.LoadID(client, index, function(sameChar)
			netstream.Start(client, "nut_CharMenu", false)

			if (!sameChar) then
				nut.schema.Call("PlayerLoadedChar", client)
					client:Spawn()
				nut.schema.Call("PostPlayerSpawn", client)
			end
		end)
	end)

	-- Deletes a character from the database if it exists.
	netstream.Hook("nut_CharDelete", function(client, index)
		if (client.characters and table.HasValue(client.characters, index)) then
			for k, v in pairs(client.characters) do
				if (v == index) then
					client.characters[k] = nil
				end
			end

			nut.db.Query("DELETE FROM "..nut.config.dbTable.." WHERE steamid = "..client:SteamID64().." AND id = "..index..sameSchema(), function(data)
				if (IsValid(client) and client.character and client.character.index == index) then
					if (client.nut_CachedChars) then
						client.nut_CachedChars[client.character.index] = nil
					end
					
					client.character = nil
					client:KillSilent()

					timer.Simple(0, function()
						netstream.Start(client, "nut_CharMenu", {true, true})
					end)
				end

				print("Deleted character #"..index.." for "..client:Name()..".")
			end)
		else
			ErrorNoHalt("Attempt to delete invalid character! ("..index..")")
		end
	end)
else
	-- CharData needs a valid player.
	netstream.Hook("nut_CharData", function(data)
		local index = data[1]
		local client = player.GetByID(index)
		local key = data[2]
		local value = data[3]
		local noDelta = data[4]

		if (!IsValid(client)) then
			local uniqueID = "nut_CharData"..index..key

			timer.Create(uniqueID, 5, 12, function()
				local client = player.GetByID(index)

				if (IsValid(client)) then
					if (!client.character) then
						client.character = nut.char.New(client)
					end

					local character = client.character

					if (!noDelta and type(value) == "table") then
						local currentValue

						if (character.privateVars[key]) then
							currentValue = character.privateVars[key]
						elseif (character.publicVars[key]) then
							currentValue = character.publicVars[key]
						end

						value = table.Merge(currentValue, value)
						value = replacePlaceHolders(value)
					end

					client.character:SetVar(key, value)
					timer.Remove(uniqueID)

					return
				end
			end)

			return
		end

		if (!client.character) then
			client.character = nut.char.New(client)
		end

		local character = client.character

		if (!noDelta and type(value) == "table") then
			local currentValue

			if (character.privateVars[key]) then
				currentValue = character.privateVars[key]
			elseif (character.publicVars[key]) then
				currentValue = character.publicVars[key]
			end

			value = table.Merge(currentValue, value)
			value = replacePlaceHolders(value)
		end

		client.character:SetVar(key, value)
	end)

	-- Local data is meant for the character's owner and uses Localplayer instead of an
	-- entity.
	netstream.Hook("nut_LocalCharData", function(data)
		local key = data[1]
		local value = data[2]
		local noDelta = data[3]

		if (!LocalPlayer().character) then
			LocalPlayer().character = nut.char.New(LocalPlayer())
		end

		local character = LocalPlayer().character
		
		if (!noDelta and type(value) == "table") then
			local currentValue = {}

			if (character.privateVars[key]) then
				currentValue = character.privateVars[key]
			elseif (character.publicVars[key]) then
				currentValue = character.publicVars[key]
			end

			value = table.Merge(currentValue, value)
			value = replacePlaceHolders(value)
		end

		character:SetVar(key, value)
	end)

	-- Receives the character information from the server to be displayed in the character listing.
	netstream.Hook("nut_CharInfo", function(data)
		local name = data[1]
		local description = data[2]
		local model = data[3]
		local faction = data[4]
		local id = data[5]
		local skin = data[6]

		LocalPlayer().characters = LocalPlayer().characters or {}

		for k, v in pairs(LocalPlayer().characters) do
			if (v.id == id) then
				LocalPlayer().characters[k] = {
					name = name,
					desc = description,
					model = model,
					faction = faction,
					id = id,
					skin = skin
				}

				return
			end
		end

		table.insert(LocalPlayer().characters, {
			name = name,
			desc = description,
			model = model,
			faction = faction,
			id = id,
			skin = skin
		})
	end)
end