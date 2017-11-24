-- Create the character metatable.
local CHAR = ix.meta.character or {}
CHAR.__index = CHAR
CHAR.id = CHAR.id or 0
CHAR.vars = CHAR.vars or {}

-- Called when the character is being printed as a string.
function CHAR:__tostring()
	return "character["..(self.id or 0).."]"
end

-- Checks if two character objects represent the same character.
function CHAR:__eq(other)
	return self:GetID() == other:GetID()
end

-- Returns the character index from the database.
function CHAR:GetID()
	return self.id
end

if (SERVER) then
	-- Saves the character to the database and calls the callback if provided.
	function CHAR:Save(callback)
		-- Do not save if the character is for a bot.
		if (self.isBot) then
			return
		end
		
		-- Prepare a list of information to be saved.
		local data = {}

		-- Save all the character variables.
		for k, v in pairs(ix.char.vars) do
			if (v.field and self.vars[k] != nil) then
				data[v.field] = self.vars[k]
			end
		end

		-- Let plugins/schema determine if the character should be saved.
		local shouldSave = hook.Run("CharacterPreSave", self)

		if (shouldSave != false) then
			-- Run a query to save the character to the database.
			ix.db.UpdateTable(data, function()
				if (callback) then
					callback()
				end

				hook.Run("CharacterPostSave", self)
			end, nil, "_id = "..self:GetID())
		end
	end

	-- Sends character information to the receiver.
	function CHAR:Sync(receiver)
		-- Broadcast the character information if receiver is not set.
		if (receiver == nil) then
			for k, v in ipairs(player.GetAll()) do
				self:Sync(v)
			end
		-- Send all character information if the receiver is the character's owner.
		elseif (receiver == self.player) then
			local data = {}

			for k, v in pairs(self.vars) do
				if (ix.char.vars[k] != nil and !ix.char.vars[k].noNetworking) then
					data[k] = v
				end
			end

			netstream.Start(self.player, "charInfo", data, self:GetID())
		-- Send public character information to the receiver.
		else
			local data = {}

			for k, v in pairs(ix.char.vars) do
				if (!v.noNetworking and !v.isLocal) then
					data[k] = self.vars[k]
				end
			end

			netstream.Start(receiver, "charInfo", data, self:GetID(), self.player)
		end
	end

	-- Sets up the "appearance" related inforomation for the character.
	function CHAR:Setup(noNetworking)
		local client = self:GetPlayer()

		if (IsValid(client)) then
			-- Set the faction, model, and character index for the player.
			client:SetModel(self:GetModel())
			client:SetTeam(self:GetFaction())
			client:SetNetVar("char", self:GetID())

			-- Apply saved body groups.
			for k, v in pairs(self:GetData("groups", {})) do
				client:SetBodygroup(k, v)
			end

			-- Apply a saved skin.
			client:SetSkin(self:GetData("skin", 0))
			
			-- Synchronize the character if we should.
			if (!noNetworking) then
				self:Sync()
				
				-- wtf
				for k, v in ipairs(self:GetInv(true)) do
					if (type(v) == "table") then 
						v:Sync(client)	
					end
				end
			end

			hook.Run("CharacterLoaded", ix.char.loaded[self:GetID()])

			-- Close the character menu.
			netstream.Start(client, "charLoaded")
			self.firstTimeLoaded = true
		end
	end

	-- Forces the player to choose a character.
	function CHAR:Kick()
		-- Kill the player so they are not standing anywhere.
		local client = self:GetPlayer()
		client:KillSilent()

		local steamID = client:SteamID64()
		local id = self:GetID()
		local isCurrentChar = self and self:GetID() == id
		
		-- Return the player to the character menu.
		if (self and self.steamID == steamID) then			
			netstream.Start(client, "charKick", id, isCurrentChar)

			if (isCurrentChar) then
				client:SetNetVar("char", nil)
				client:Spawn()
			end
		end
	end

	-- Prevents the use of this character permanently or for a certain amount of time.
	function CHAR:Ban(time)
		time = tonumber(time)

		if (time) then
			-- If time is provided, adjust it so it becomes the un-ban time.
			time = os.time() + math.max(math.ceil(time), 60)
		end

		-- Mark the character as banned and kick the character back to menu.
		self:SetData("banned", time or true)
		self:Kick()
	end
end

-- Returns which player owns this character.
function CHAR:GetPlayer()
	-- Return the player from cache.
	if (IsValid(self.player)) then
		return self.player
	-- Search for which player owns this character.
	elseif (self.steamID) then
		local steamID = self.steamID

		for k, v in ipairs(player.GetAll()) do
			if (v:SteamID64() == steamID) then
				self.player = v

				return v
			end
		end
	end
end

-- Sets up a new character variable.
function ix.char.RegisterVar(key, data)
	-- Store information for the variable.
	ix.char.vars[key] = data
	data.index = data.index or table.Count(ix.char.vars)

	-- Convert the name of the variable to be capitalized.
	local upperName = key:sub(1, 1):upper()..key:sub(2)

	-- Provide functions to change the variable if allowed.
	if (SERVER and !data.isNotModifiable) then
		-- Overwrite the set function if desired.
		if (data.OnSet) then
			CHAR["Set"..upperName] = data.OnSet
		-- Have the set function only set on the server if no networking.
		elseif (data.noNetworking) then
			CHAR["Set"..upperName] = function(self, value)
				self.vars[key] = value
			end
		-- If the variable is a local one, only send the variable to the local player.
		elseif (data.isLocal) then
			CHAR["Set"..upperName] = function(self, value)
				local curChar = self:GetPlayer() and self:GetPlayer():GetChar()
				local sendID = true

				if (curChar and curChar == self) then
					sendID = false
				end

				local oldVar = self.vars[key]
					self.vars[key] = value
				netstream.Start(self.player, "charSet", key, value, sendID and self:GetID() or nil)

				hook.Run("OnCharVarChanged", self, key, oldVar, value)
			end
		-- Otherwise network the variable to everyone.
		else
			CHAR["Set"..upperName] = function(self, value)
				local oldVar = self.vars[key]
					self.vars[key] = value
				netstream.Start(nil, "charSet", key, value, self:GetID())
				
				hook.Run("OnCharVarChanged", self, key, oldVar, value)
			end
		end
	end

	-- The get functions are shared.
	-- Overwrite the get function if desired.
	if (data.OnGet) then
		CHAR["Get"..upperName] = data.OnGet
	-- Otherwise return the character variable or default if it does not exist.
	else
		CHAR["Get"..upperName] = function(self, default)
			local value = self.vars[key]

			if (value != nil) then
				return value
			end

			if (default == nil) then
				return ix.char.vars[key] and ix.char.vars[key].default or nil
			end

			return default
		end
	end

	local alias = data.alias

	if (alias) then
		if (type(alias) == "table") then
			for k, v in ipairs(alias) do
				local aliasName = v:sub(1, 1):upper()..v:sub(2)

				CHAR["Get"..aliasName] = CHAR["Get"..upperName]
				CHAR["Set"..aliasName] = CHAR["Set"..upperName]
			end
		elseif (type(alias) == "string") then
			local aliasName = alias:sub(1, 1):upper()..alias:sub(2)

			CHAR["Get"..aliasName] = CHAR["Get"..upperName]
			CHAR["Set"..aliasName] = CHAR["Set"..upperName]
		end
	end

	-- Add the variable default to the character object.
	CHAR.vars[key] = data.default
end

-- Allows access to the character metatable using ix.meta.character
ix.meta.character = CHAR
