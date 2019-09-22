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

		net.Receive("ixDataSync", function()
			ix.localData = net.ReadTable()
			ix.playTime = net.ReadUInt(32)
		end)

		net.Receive("ixData", function()
			ix.localData = ix.localData or {}
			ix.localData[net.ReadString()] = net.ReadType()
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
		local char = self:GetCharacter()

		if (char) then
			local inv = char:GetInventory()

			if (inv) then
				return inv:GetItems()
			end
		end
	end

	function playerMeta:GetClassData()
		local char = self:GetCharacter()

		if (char) then
			local class = char:GetClass()

			if (class) then
				local classData = ix.class.list[class]

				return classData
			end
		end
	end
end

do
	if (SERVER) then
		util.AddNetworkString("PlayerModelChanged")
		util.AddNetworkString("PlayerSelectWeapon")

		local entityMeta = FindMetaTable("Entity")

		entityMeta.ixSetModel = entityMeta.ixSetModel or entityMeta.SetModel
		playerMeta.ixSelectWeapon = playerMeta.ixSelectWeapon or playerMeta.SelectWeapon

		function entityMeta:SetModel(model)
			local oldModel = self:GetModel()

			if (self:IsPlayer()) then
				hook.Run("PlayerModelChanged", self, model, oldModel)

				net.Start("PlayerModelChanged")
					net.WriteEntity(self)
					net.WriteString(model)
					net.WriteString(oldModel)
				net.Broadcast()
			end

			return self:ixSetModel(model)
		end

		function playerMeta:SelectWeapon(className)
			net.Start("PlayerSelectWeapon")
				net.WriteEntity(self)
				net.WriteString(className)
			net.Broadcast()

			return self:ixSelectWeapon(className)
		end
	else
		net.Receive("PlayerModelChanged", function(length)
			hook.Run("PlayerModelChanged", net.ReadEntity(), net.ReadString(), net.ReadString())
		end)

		net.Receive("PlayerSelectWeapon", function(length)
			local client = net.ReadEntity()
			local className = net.ReadString()

			if (!IsValid(client)) then
				hook.Run("PlayerWeaponChanged", client, NULL)
				return
			end

			for _, v in ipairs(client:GetWeapons()) do
				if (v:GetClass() == className) then
					hook.Run("PlayerWeaponChanged", client, v)
					break
				end
			end
		end)
	end
end
