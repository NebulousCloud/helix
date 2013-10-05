BASE.name = "Base Clothes"
BASE.uniqueID = "base_cloth"
BASE.category = "Clothing"
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
			
			-- Backwards compatability.
			local model = itemTable.outfitModel or itemTable.model
			local replacement = itemTable.replacement
			local lowerPlyModel = string.lower(client:GetModel())

			if (replacement) then
				--[[
					Replacements can either be:
					ITEM.replacement = {"group02", "group03"}

					or:

					ITEM.replacement = {
						{"group01", "group03"},
						{"group02", "group03"}
					}
				--]]
				if (#replacement == 2 and type(replacement[1]) == "string" and type(replacement[2]) == "string") then
					model = string.gsub(lowerPlyModel, replacement[1], replacement[2])
				elseif (#replacement > 0) then
					for k, v in pairs(replacement) do
						if (v[1] and v[2]) then
							model = string.gsub(lowerPlyModel, string.lower(v[1]), string.lower(v[2]))
						end
					end
				end
			end

			client.character:SetData("oldModel", lowerPlyModel)
			client.character.model = model
			client:SetModel(model)

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
				client.character.model = model
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

function BASE:GetDropModel()
	return "models/props_c17/suitCase_passenger_physics.mdl"
end
