PLUGIN.name = "Storage"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds storage items that can store items."

nut.util.Include("cl_storage.lua")

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_container")) do
			if (v.itemID) then
				local inventory = v:GetNetVar("inv")

				data[#data + 1] = {
					position = v:GetPos(),
					angles = v:GetAngles(),
					inv = inventory,
					uniqueID = v.itemID
				}
			end
		end

		nut.util.WriteTable("storage", data)
	end

	function PLUGIN:LoadData()
		local storage = nut.util.ReadTable("storage")

		if (storage) then
			for k, v in pairs(storage) do
				local inventory = v.inv
				local position = v.position
				local angles = v.angles
				local itemTable = nut.item.Get(v.uniqueID)

				if (itemTable) then
					local entity = ents.Create("nut_container")
					entity:SetPos(position)
					entity:SetAngles(angles)
					entity:Spawn()
					entity:Activate()
					entity:SetNetVar("inv", inventory)
					entity:SetNetVar("name", itemTable.name)
					entity.itemID = v.uniqueID

					if (itemTable.maxWeight) then
						entity:SetNetVar("max", itemTable.maxWeight)
					end

					entity:SetModel(itemTable.model)
					entity:PhysicsInit(SOLID_VPHYSICS)
				end
			end
		end
	end
end