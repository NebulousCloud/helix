--[[
	Purpose: Provides a library for creating factions and having
	players able to be whitelisted to certain factions.
--]]

if (!netstream) then
	include("sh_netstream.lua")
end

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

	if (!classTable.OnSet) then
		function classTable:OnSet(client)
			local model = self.model

			if (!model and self.faction) then
				local faction = nut.faction.GetByID(self.faction)
				local gender = client.character:GetVar("gender", "male")

				model = table.Random(faction[gender.."Models"])
			end

			if (model) then
				client:SetModel(model)
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
			nut.util.Include(directpry.."/classes/"..v)
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

		if (class and client:CharClass() != class and class:PlayerCanJoin(client) and nut.schema.Call("PlayerCanJoinClass", client, class) != false) then
			nut.schema.Call("PlayerPreJoinClass", client, class)
				client:SetCharClass(index)
			nut.schema.Call("PlayerPostJoinClass", client, class)

			nut.util.Notify("You have joined the "..class.name.." class.", client)
		else
			nut.util.Notify("You can not join this class.", client)
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
					
					self.character:SetData("class", index)
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