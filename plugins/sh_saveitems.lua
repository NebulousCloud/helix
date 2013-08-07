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
					nut.item.Spawn(position, angles, itemTable, data)
				end
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_item")) do
			data[#data + 1] = {
				position = v:GetPos(),
				angles = v:GetAngles(),
				uniqueID = v:GetItemTable().uniqueID,
				data = v:GetData()
			}
		end

		nut.util.WriteTable("saveditems", data)
	end
end