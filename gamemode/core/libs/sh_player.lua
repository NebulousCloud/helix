local playerMeta = FindMetaTable("Player")

-- ixData information for the player.
do
	if (SERVER) then
		function playerMeta:GetData(key, default)
			if (key == true) then
				return self.ixData
			end

			local data = self.ixData and self.ixData[key]

			if (data == nil) then
				return default
			else
				return data
			end
		end
	else
		function playerMeta:GetData(key, default)
			local data = ix.localData and ix.localData[key]

			if (data == nil) then
				return default
			else
				return data
			end
		end

		netstream.Hook("ixDataSync", function(data, playTime)
			ix.localData = data
			ix.playTime = playTime
		end)

		netstream.Hook("ixData", function(key, value)
			ix.localData = ix.localData or {}
			ix.localData[key] = value
		end)
	end
end

-- Whitelist networking information here.
do
	function playerMeta:HasWhitelist(faction)
		local data = ix.faction.indices[faction]

		if (data) then
			if (data.isDefault) then
				return true
			end

			local ixData = self:GetData("whitelists", {})

			return ixData[Schema.folder] and ixData[Schema.folder][data.uniqueID] == true or false
		end

		return false
	end

	function playerMeta:GetItems()
		local char = self:GetChar()

		if (char) then
			local inv = char:GetInv()

			if (inv) then
				return inv:GetItems()
			end
		end
	end

	function playerMeta:GetClassData()
		local char = self:GetChar()

		if (char) then
			local class = char:GetClass()

			if (class) then
				local classData = ix.class.list[class]

				return classData
			end
		end
	end
end
