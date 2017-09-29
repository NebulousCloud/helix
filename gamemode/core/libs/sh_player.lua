local playerMeta = FindMetaTable("Player")

-- nutData information for the player.
do
	if (SERVER) then
		function playerMeta:GetData(key, default)
			if (key == true) then
				return self.nutData
			end

			local data = self.nutData and self.nutData[key]

			if (data == nil) then
				return default
			else
				return data
			end
		end
	else
		function playerMeta:GetData(key, default)
			local data = nut.localData and nut.localData[key]

			if (data == nil) then
				return default
			else
				return data
			end
		end

		netstream.Hook("nutDataSync", function(data, playTime)
			nut.localData = data
			nut.playTime = playTime
		end)

		netstream.Hook("nutData", function(key, value)
			nut.localData = nut.localData or {}
			nut.localData[key] = value
		end)
	end
end

-- Whitelist networking information here.
do
	function playerMeta:HasWhitelist(faction)
		local data = nut.faction.indices[faction]

		if (data) then
			if (data.isDefault) then
				return true
			end

			local nutData = self:GetData("whitelists", {})

			return nutData[Schema.folder] and nutData[Schema.folder][data.uniqueID] == true or false
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
				local classData = nut.class.list[class]

				return classData
			end
		end
	end
end