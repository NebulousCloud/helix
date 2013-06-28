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

do
	-- Overwrite the player:Name() function to return the character name if it exists,
	-- otherwise return the original Steam name.
	local playerMeta = FindMetaTable("Player")
	playerMeta.NutName = playerMeta.NutName or playerMeta.Name

	-- Alias to the old function before it gets overwritten.
	playerMeta.RealName = playerMeta.RealName or playerMeta.Name

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

-- We begin our metatable here.
local META = {}
META.__index = META

-- Public variable and private variable enums.
CHAR_PUBLIC = 1
CHAR_PRIVATE = 2

--[[
	Purpose: A nice name for printing characters rather than just stating
	it is a table.
--]]
function META:__tostring()
	return "Character ["..(IsValid(self.player) and self.player:Name() or "NULL").."]["..self:GetVar("charname", "John Doe").."]"
end

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
	if (self.privateVars[name]) then
		return self.privateVars[name]
	elseif (self.publicVars[name]) then
		return self.publicVars[name]
	else
		return default
	end
end

--[[
	Purpose: A quick utility method to set a member of the data field and send it to the receiver.
--]]
function META:SetData(key, value, receiver)
	self:GetVar("chardata")[key] = value
	self:Send("chardata", receiver)
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

--[[
	Purpose: Using the variables defined by :NewVar, it will send the data to the receiver
	if it is a public var, or only send it to the character's owner when it is private.
	If a field is not known, it will give an error. If variable is nil, then it sends all
	neccessary information based off it's state of either private or public.
--]]
function META:Send(variable, receiver)
	if (!variable) then
		for k, v in pairs(self.publicVars) do
			self:Send(k, receiver)
		end

		if (receiver == self.player) then
			for k, v in pairs(self.privateVars) do
				self:Send(k, receiver)
			end
		end
	elseif (self.privateVars[variable]) then
		net.Start("nut_LocalCharData")
			net.WriteString(variable)
			net.WriteType(self.privateVars[variable])
		net.Send(self.player)
	elseif (self.publicVars[variable]) then
		net.Start("nut_CharData")
			net.WriteEntity(self.player)
			net.WriteString(variable)
			net.WriteType(self.publicVars[variable])
		if (receiver) then
			net.Send(receiver)
		else
			net.Broadcast()
		end
	else
		error("Attempted to send unknown character data!")
	end
end

setmetatable(META, {})

--[[
	Purpose: Returns a new character that has the owner set to the first argument,
	and will broadcast the information if ran on the server and send is true.
--]]
function nut.char.New(client, send)
	local character = setmetatable({
		player = client,
		privateVars = {},
		publicVars = {},
		dataTypes = {},
		noSaveVars = {}
	}, META)

	nut.schema.Call("CreateCharVars", character)

	if (SERVER and send) then
		character:Send()
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

	-- Precache the character net messages.
	util.AddNetworkString("nut_CharData")
	util.AddNetworkString("nut_LocalCharData")
	util.AddNetworkString("nut_CharCreate")
	util.AddNetworkString("nut_CharCreateAuthed")
	util.AddNetworkString("nut_CharInfo")
	util.AddNetworkString("nut_CharChoose")
	util.AddNetworkString("nut_CharDelete")
	util.AddNetworkString("nut_CharMenu")

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
			client.character:Send()

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
						local character = nut.char.New(client)
						character.index = index
						character.model = data.model

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
		local condition = "steamid = "..steamID.." AND id = "..index--..sameSchema()
		local tables = "charname, faction, id, description, model"
		
		nut.db.FetchTable(condition, tables, function(data)
			if (IsValid(client)) then
				if (data and table.Count(data) > 0) then
					client.characters = client.characters or {};
					table.insert(client.characters, tonumber(data.id))

					net.Start("nut_CharInfo")
						net.WriteString(data.charname)
						net.WriteString(data.description)
						net.WriteString(data.model)
						net.WriteUInt(data.faction, 8)
						net.WriteUInt(data.id, 8)
					net.Send(client)
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
		nut.db.FetchTable("steamid = "..client:SteamID64(), "id", function(_, data)
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
		local steamID = client:SteamID64()
		local character = client.character

		if (!character) then
			return
		end

		local index = character.index
		local data = character:GetVars()
		data.model = client:GetModel()

		nut.db.UpdateTable("steamid = "..steamID.." AND id = "..index..sameSchema(), data)
		client:SaveData()

		print("Saved '"..client.character:GetVar("charname").."' for "..client:RealName()..".")
	end

	-- Validate the character creation request and sends a message to close the creation
	-- menu when the character has been inserted into the database.
	net.Receive("nut_CharCreate", function(length, client)
		if (!IsValid(client)) then
			return
		end

		local name = string.sub(net.ReadString(), 1, 70)
		local gender = string.lower( net.ReadString() )
		local desc = string.sub(net.ReadString(), 1, 240)
		local model = net.ReadString()
		local faction = net.ReadUInt(8)
		local attributes = net.ReadTable() or {}

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

		nut.char.Create(client, {
			charname = name,
			description = desc,
			gender = gender,
			inv = nut.schema.Call("GetDefaultInventory", client),
			money = nut.schema.Call("GetDefaultMoney", client),
			chardata = data,
			faction = faction,
			model = model
		}, function(id)
			net.Start("nut_CharCreateAuthed")
			net.Send(client)

			timer.Simple(0.05, function()
				nut.char.SendInfo(client, id)

				print("Created new character '"..name.."' for "..client:Name()..".")
			end)
		end)		
	end)

	-- Spawns the player with their appropriate character and closes the main menu.
	net.Receive("nut_CharChoose", function(length, client)
		local index = net.ReadUInt(8)
		
		if (client.character and client.character.index != index) then
			nut.char.Save(client)
			nut.schema.Call("OnCharChanged", client)
		end

		nut.char.LoadID(client, index, function(sameChar)
			net.Start("nut_CharMenu")
			net.Send(client)

			if (!sameChar) then
				client:Spawn()

				nut.schema.Call("PlayerLoadedChar", client)
			end
		end)
	end)

	-- Deletes a character from the database if it exists.
	net.Receive("nut_CharDelete", function(length, client)
		local index = net.ReadUInt(8)

		if (client.characters and table.HasValue(client.characters, index)) then
			if (client.character and client.character.index == index) then
				return
			end

			nut.db.Query("DELETE FROM "..nut.config.dbTable.." WHERE steamid = "..client:SteamID64().." AND id = "..index..sameSchema(), function(data)
				print("Deleted character #"..index.." for "..client:Name()..".")
			end)
		else
			ErrorNoHalt("Attempt to delete invalid character! ("..index..")")
		end
	end)
else
	-- CharData needs a valid player.
	net.Receive("nut_CharData", function(length)
		local client = net.ReadEntity()
		local key = net.ReadString()
		local index = net.ReadUInt(8)
		local value = net.ReadType(index)

		if (!IsValid(client)) then
			return
		end
		
		if (!client.character) then
			client.character = nut.char.New(client)
		end

		client.character:SetVar(key, value)
	end)

	-- Local data is meant for the character's owner and uses Localplayer instead of an
	-- entity.
	net.Receive("nut_LocalCharData", function(length)
		local key = net.ReadString()
		local index = net.ReadUInt(8)
		local value = net.ReadType(index)

		if (!LocalPlayer().character) then
			LocalPlayer().character = nut.char.New(LocalPlayer())
		end

		LocalPlayer().character:SetVar(key, value)
	end)

	-- Receives the character information from the server to be displayed in the character listing.
	net.Receive("nut_CharInfo", function(length)
		local name = net.ReadString()
		local description = net.ReadString()
		local model = net.ReadString()
		local faction = net.ReadUInt(8)
		local id = net.ReadUInt(8)

		LocalPlayer().characters = LocalPlayer().characters or {}
		table.insert(LocalPlayer().characters, {
			name = name,
			desc = description,
			model = model,
			faction = faction,
			id = id
		})
	end)
end