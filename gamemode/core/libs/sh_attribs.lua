if (!nut.char) then include("sh_character.lua") end

nut.attribs = nut.attribs or {}
nut.attribs.list = nut.attribs.list or {}

function nut.attribs.LoadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		ATTRIBUTE = nut.attribs.list[niceName] or {}
			if (PLUGIN) then
				ATTRIBUTE.plugin = PLUGIN.uniqueID
			end

			nut.util.Include(directory.."/"..v)

			ATTRIBUTE.name = ATTRIBUTE.name or "Unknown"
			ATTRIBUTE.desc = ATTRIBUTE.desc or "No description availalble."

			nut.attribs.list[niceName] = ATTRIBUTE
		ATTRIBUTE = nil
	end
end

function nut.attribs.Setup(client)
	local character = client:GetChar()

	if (character) then
		for k, v in pairs(nut.attribs.list) do
			if (v.OnSetup) then
				v:OnSetup(client, character:GetAttrib(k, 0))
			end
		end
	end
end

-- Add updating of attributes to the character metatable.
do
	local charMeta = nut.meta.character
	
	if (SERVER) then
		function charMeta:UpdateAttrib(key, value)
			local attribute = nut.attribs.list[key]

			if (attribute) then
				local attrib = self:GetAttribs()
				local client = self:GetPlayer()

				attrib[key] = math.min((attrib[key] or 0) + value, attribute.maxValue or nut.config.Get("maxAttribs", 30))

				if (IsValid(client)) then
					netstream.Start(client, "attrib", self:GetID(), key, attrib[key])

					if (attribute.Setup) then
						attribute.Setup(attrib[key])
					end
				end
			end

			hook.Run("OnCharAttribUpdated", client, self, key, value)
		end

		function charMeta:SetAttrib(key, value)
			local attribute = nut.attribs.list[key]

			if (attribute) then
				local attrib = self:GetAttribs()
				local client = self:GetPlayer()

				attrib[key] = value

				if (IsValid(client)) then
					netstream.Start(client, "attrib", self:GetID(), key, attrib[key])

					if (attribute.Setup) then
						attribute.Setup(attrib[key])
					end
				end
			end
			
			hook.Run("OnCharAttribUpdated", client, self, key, value)
		end

		function charMeta:AddBoost(boostID, attribID, boostAmount)
			local boosts = self:GetVar("boosts", {})

			boosts[attribID] = boosts[attribID] or {}
			boosts[attribID][boostID] = boostAmount

			hook.Run("OnCharAttribBoosted", self:GetPlayer(), self, attribID, boostID, boostAmount)

			return self:SetVar("boosts", boosts, nil, self:GetPlayer())
		end
		
		function charMeta:RemoveBoost(boostID, attribID)
			local boosts = self:GetVar("boosts", {})

			boosts[attribID] = boosts[attribID] or {}
			boosts[attribID][boostID] = nil

			hook.Run("OnCharAttribBoosted", self:GetPlayer(), self, attribID, boostID, true)

			return self:SetVar("boosts", boosts, nil, self:GetPlayer())
		end
	else
		netstream.Hook("attrib", function(id, key, value)
			local character = nut.char.loaded[id]

			if (character) then
				character:GetAttribs()[key] = value
			end
		end)
	end

	function charMeta:GetBoost(attribID)
		local boosts = self:GetBoosts()

		return boosts[attribID]
	end

	function charMeta:GetBoosts()
		return self:GetVar("boosts", {})
	end

	function charMeta:GetAttrib(key, default)
		local att = self:GetAttribs()[key] or default
		local boosts = self:GetBoosts()[key]

		if (boosts) then
			for k, v in pairs(boosts) do
				att = att + v
			end
		end 
	
		return att
	end
end