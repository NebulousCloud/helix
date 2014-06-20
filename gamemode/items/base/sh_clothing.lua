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
			local model = itemTable.model

			if ((string.find(model, "female") or nut.anim.GetClass(model) == "citizen_female") and itemTable.femaleModel) then
				model = itemTable.femaleModel
			end

			if (!model) then
				client.character:SetData("oldModel", nil, nil, true)
				error("Clothing item without valid model! ("..(itemTable.uniqueID or "null")..")")
			end

			if (client.character:GetData("oldModel")) then
				nut.util.Notify("You are already wearing another set of clothing.", client)

				return false
			end

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

					You can also use regular expressions.
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

			if (model == lowerPlyModel) then
				model = itemTable.model
			end

			client.character:SetData("oldModel", lowerPlyModel, nil, true)
			client.character.model = model
			client:SetModel(model)

			hook.Run("PlayerSetHandsModel", client, client:GetHands())

			if (itemTable.OnWear) then
				itemTable:OnWear(client, data)
			end

			local newData = table.Copy(data)
			newData.Equipped = true

			client:UpdateInv(itemTable.uniqueID, 1, newData, true)
			hook.Run("OnClothEquipped", client, itemTable, true)
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

				hook.Run("PlayerSetHandsModel", client, client:GetHands())
			client.character:SetData("oldModel", nil, nil, true)

			local newData = table.Copy(data)
			newData.Equipped = false

			client:UpdateInv(itemTable.uniqueID, 1, newData, true)
			hook.Run("OnClothEquipped", client, itemTable, false)

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

function BASE:OnRegister(itemTable)
	if (itemTable.outfitModel) then
		error("ITEM.outfitModel is now deprecated. Change it to ITEM.model")
	end
end