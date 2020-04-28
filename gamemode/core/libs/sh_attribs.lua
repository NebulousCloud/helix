
-- @module ix.attributes

if (!ix.char) then
	include("sh_character.lua")
end

ix.attributes = ix.attributes or {}
ix.attributes.list = ix.attributes.list or {}

function ix.attributes.LoadFromDir(directory)
	for _, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		ATTRIBUTE = ix.attributes.list[niceName] or {}
			if (PLUGIN) then
				ATTRIBUTE.plugin = PLUGIN.uniqueID
			end

			ix.util.Include(directory.."/"..v)

			ATTRIBUTE.name = ATTRIBUTE.name or "Unknown"
			ATTRIBUTE.description = ATTRIBUTE.description or "No description availalble."

			ix.attributes.list[niceName] = ATTRIBUTE
		ATTRIBUTE = nil
	end
end

function ix.attributes.Setup(client)
	local character = client:GetCharacter()

	if (character) then
		for k, v in pairs(ix.attributes.list) do
			if (v.OnSetup) then
				v:OnSetup(client, character:GetAttribute(k, 0))
			end
		end
	end
end

do
	--- Character attribute methods
	-- @classmod Character
	local charMeta = ix.meta.character

	if (SERVER) then
		util.AddNetworkString("ixAttributeUpdate")

		--- Increments one of this character's attributes by the given amount.
		-- @realm server
		-- @string key Name of the attribute to update
		-- @number value Amount to add to the attribute
		function charMeta:UpdateAttrib(key, value)
			local attribute = ix.attributes.list[key]
			local client = self:GetPlayer()

			if (attribute) then
				local attrib = self:GetAttributes()

				attrib[key] = math.min((attrib[key] or 0) + value, attribute.maxValue or ix.config.Get("maxAttributes", 100))

				if (IsValid(client)) then
					net.Start("ixAttributeUpdate")
						net.WriteUInt(self:GetID(), 32)
						net.WriteString(key)
						net.WriteFloat(attrib[key])
					net.Send(client)

					if (attribute.Setup) then
						attribute.Setup(attrib[key])
					end
				end

				self:SetAttributes(attrib)
			end

			hook.Run("CharacterAttributeUpdated", client, self, key, value)
		end

		--- Sets the value of an attribute for this character.
		-- @realm server
		-- @string key Name of the attribute to update
		-- @number value New value for the attribute
		function charMeta:SetAttrib(key, value)
			local attribute = ix.attributes.list[key]
			local client = self:GetPlayer()

			if (attribute) then
				local attrib = self:GetAttributes()

				attrib[key] = value

				if (IsValid(client)) then
					net.Start("ixAttributeUpdate")
						net.WriteUInt(self:GetID(), 32)
						net.WriteString(key)
						net.WriteFloat(attrib[key])
					net.Send(client)

					if (attribute.Setup) then
						attribute.Setup(attrib[key])
					end
				end

				self:SetAttributes(attrib)
			end

			hook.Run("CharacterAttributeUpdated", client, self, key, value)
		end

		--- Temporarily increments one of this character's attributes. Useful for things like consumable items.
		-- @realm server
		-- @string boostID Unique ID to use for the boost to remove it later
		-- @string attribID Name of the attribute to boost
		-- @number boostAmount Amount to increase the attribute by
		function charMeta:AddBoost(boostID, attribID, boostAmount)
			local boosts = self:GetVar("boosts", {})

			boosts[attribID] = boosts[attribID] or {}
			boosts[attribID][boostID] = boostAmount

			hook.Run("CharacterAttributeBoosted", self:GetPlayer(), self, attribID, boostID, boostAmount)

			return self:SetVar("boosts", boosts, nil, self:GetPlayer())
		end

		--- Removes a temporary boost from this character.
		-- @realm server
		-- @string boostID Unique ID of the boost to remove
		-- @string attribID Name of the attribute that was boosted
		function charMeta:RemoveBoost(boostID, attribID)
			local boosts = self:GetVar("boosts", {})

			boosts[attribID] = boosts[attribID] or {}
			boosts[attribID][boostID] = nil

			hook.Run("CharacterAttributeBoosted", self:GetPlayer(), self, attribID, boostID, true)

			return self:SetVar("boosts", boosts, nil, self:GetPlayer())
		end
	else
		net.Receive("ixAttributeUpdate", function()
			local id = net.ReadUInt(32)
			local character = ix.char.loaded[id]

			if (character) then
				local key = net.ReadString()
				local value = net.ReadFloat()

				character:GetAttributes()[key] = value
			end
		end)
	end

	--- Returns all boosts that this character has for the given attribute. This is only valid on the server and owning client.
	-- @realm shared
	-- @string attribID Name of the attribute to find boosts for
	-- @treturn[1] table Table of boosts that this character has for the attribute
	-- @treturn[2] nil If the character has no boosts for the given attribute
	function charMeta:GetBoost(attribID)
		local boosts = self:GetBoosts()

		return boosts[attribID]
	end

	--- Returns all boosts that this character has. This is only valid on the server and owning client.
	-- @realm shared
	-- @treturn table Table of boosts this character has
	function charMeta:GetBoosts()
		return self:GetVar("boosts", {})
	end

	--- Returns the current value of an attribute. This is only valid on the server and owning client.
	-- @realm shared
	-- @string key Name of the attribute to get
	-- @number default Value to return if the attribute doesn't exist
	-- @treturn number Value of the attribute
	function charMeta:GetAttribute(key, default)
		local att = self:GetAttributes()[key] or default
		local boosts = self:GetBoosts()[key]

		if (boosts) then
			for _, v in pairs(boosts) do
				att = att + v
			end
		end

		return att
	end
end
