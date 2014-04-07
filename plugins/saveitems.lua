PLUGIN.name = "Save Items"
PLUGIN.desc = "Saves droped items in the world."
PLUGIN.author = "Chessnut"

if (SERVER) then
	function PLUGIN:LoadData()
		local restored = nut.util.ReadTable("saveditems")

		if (restored) then
			for k, v in pairs(restored) do
				local position = v.position
				local angles = v.angles
				local itemTable = nut.item.Get(v.uniqueID)
				local data = v.data

				if itemTable then
					local entity = nut.item.Spawn(position, angles, itemTable, data)

					hook.Run("ItemRestored", itemTable, entity)
				end
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_item")) do
			if (hook.Run("ItemShouldSave", v) != false) then
				data[#data + 1] = {
					position = v:GetPos(),
					angles = v:GetAngles(),
					uniqueID = v:GetItemTable().uniqueID,
					data = v:GetData()
				}

				hook.Run("ItemSaved", v)
			end
		end

		nut.util.WriteTable("saveditems", data)
	end
end