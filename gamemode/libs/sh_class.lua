--[[
	Purpose: Provides a library for creating factions and having
	players able to be whitelisted to certain factions.
--]]

nut.class = nut.class or {}
nut.class.buffer = {}

function nut.class.Register(index, classTable)
	if (!classTable.faction) then
		error("Attempt to register class without faction! ("..(classTable.uniqueID or "unknown")..")")
	end

	if (!classTable.PlayerCanJoin) then
		function classTable:PlayerCanJoin(client)
			return true
		end
	end

	function classTable:GetModel(client)
		if (CLIENT) then
			client = LocalPlayer()
		end

		local model = self.model

		if (!model and self.faction) then
			local faction = nut.faction.GetByID(self.faction)
			local gender = client.character:GetVar("gender", "male")

			model = table.Random(faction[gender.."Models"])
		end

		return self.PlayerGetModel and self:PlayerGetModel(client) or self.model or model
	end

	function classTable:GetSkin()
		return self.skin or 0
	end

	if (!classTable.OnSet) then
		function classTable:OnSet(client)
			local model = self:GetModel(client)

			if (model) then
				client:SetModel(model)

				hook.Run("PlayerSetHandsModel", client, client:GetHands())
			end

			client:SetSkin(self.skin or 0)
		end
	end

	nut.class.buffer[index] = classTable
end

function nut.class.GetByStringID(uniqueID)
	for k, v in pairs(nut.class.buffer) do
		if (v.uniqueID == uniqueID) then
			return v
		end
	end
end

function nut.class.Load(directory)
	for k, v in pairs(file.Find(directory.."/classes/*.lua", "LUA")) do
		local uniqueID = string.sub(v, 4, -5)
		local index = #nut.class.buffer + 1

		CLASS = nut.class.GetByStringID(uniqueID) or {uniqueID = uniqueID}
			CLASS.index = index
			
			nut.util.Include(directory.."/classes/"..v)
			nut.class.Register(index, CLASS)
		CLASS = nil
	end
end

function nut.class.GetAll()
	return nut.class.buffer
end

function nut.class.Get(index)
	return nut.class.buffer[index]
end

if (SERVER) then
	netstream.Hook("nut_ChooseClass", function(client, index)
		local class = nut.class.Get(index)

		if (class and client:CharClass() != class and class:PlayerCanJoin(client) and hook.Run("PlayerCanJoinClass", client, class) != false) then
			hook.Run("PlayerPreJoinClass", client, class)
				client:SetCharClass(index)
			hook.Run("PlayerPostJoinClass", client, class)

			nut.util.Notify(nut.lang.Get("class_joined", class.name), client)
		else
			nut.util.Notify(nut.lang.Get("class_failed"), client)
		end
	end)
end

do
	local playerMeta = FindMetaTable("Player")

	function playerMeta:CharClass()
		if (self.character) then
			return self.character:GetData("class")	
		end
	end

	if (SERVER) then
		function playerMeta:SetCharClass(index)
			if (self.character) then
				local class = nut.class.Get(index)

				if (class) then
					if (class.faction and self:Team() != class.faction) then
						return
					end

					local result = true

					if (class.OnSet) then
						result = class:OnSet(self) or true
					end

					if (result == false) then
						return
					end
					

					local model = class:GetModel(self)

					self.character.model = model or self.character.model
					self:SetModel(self.character.model)
					self.character:SetData("class", index)
					self:SetSkin(class:GetSkin(self))

					hook.Run("PlayerClassSet", self, index)
					hook.Run("PlayerSetHandsModel", self, self:GetHands())
				end
			end
		end
	end
end

function nut.class.GetByFaction(faction)
	local output = {}

	for k, v in pairs(nut.class.buffer) do
		if (v.faction == faction) then
			output[k] = v
		end
	end

	return output
end