BASE.name = "Base Clothes"
BASE.uniqueID = "base_cloth"
BASE.category = "Clothing"
BASE.model = Model( "models/props_c17/BriefCase001a.mdl" )
BASE.outfitmodel = Model( "models/Kleiner.mdl" )
BASE.data = {
	Equipped = false
}
BASE.functions = {}
BASE.functions.Wear = {
	run = function(itemTable, client, data)
		if (SERVER) then
			if (client.character:GetData("oldModel")) then
				nut.util.Notify("You are already wearing another set of clothing.", client)

				return false
			end

			client.character:SetData("oldModel", client:GetModel())
			client.character:SetVar("model", itemTable.outfitmodel)
			client:SetModel(itemTable.model)

			local newData = table.Copy(data)
			newData.Equipped = true

			client:UpdateInv(itemTable.uniqueID, 1, newData)
		end
	end,
	shouldDisplay = function(itemTable, data, entity)
		return !data.Equipped or data.Equipped == nil
	end
}
BASE.functions.TakeOff = {
	text = "Take Off",
	run = function(itemTable, client, data)
		if (SERVER) then
			if (!client.character:GetData("oldModel")) then
				return false
			end

			local model = client.character:GetData("oldModel", client:GetModel())
				client.character:SetVar("model", model)
				client:SetModel(model)
			client.character:SetData("oldModel", nil)

			local newData = table.Copy(data)
			newData.Equipped = false

			client:UpdateInv(itemTable.uniqueID, 1, newData)

			return true
		end
	end,
	shouldDisplay = function(itemTable, data, entity)
		return data.Equipped == true
	end
}

local size = 16
local border = 4
local distance = size + border
local tick = Material("icon16/tick.png")

function BASE:PaintIcon(w, h)
	if (self.data.Equipped) then
		surface.SetDrawColor(0, 0, 0, 50)
		surface.DrawRect(w - distance - 1, w - distance - 1, size + 2, size + 2)

		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(tick)
		surface.DrawTexturedRect(w - distance, w - distance, size, size)
	end
end

function BASE:CanTransfer(client, data)
	if (data.Equipped) then
		nut.util.Notify("You must unequip the item before doing that.", client)
	end

	return !data.Equipped
end