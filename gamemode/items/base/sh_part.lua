BASE.name = "Base Parts"
BASE.uniqueID = "base_part"
BASE.category = "Appearance"
--BASE.type = "hat" -- Optional.
BASE.data = {
	Equipped = false
}
BASE.functions = {}
BASE.functions.Equip = {
	run = function(itemTable, client, data)
		if (SERVER) then
			if (client:HasPartModel(itemTable.uniqueID)) then
				nut.util.Notify("You already has this part equipped.", client)

				return false
			end
			if (itemTable.type and IsValid(client:GetNutVar(itemTable.type))) then
				nut.util.Notify("You already have a part in the "..itemTable.type.." slot.", client)

				return false
			end
			if itemTable.type then
				client:SetNutVar(itemTable.type, itemTable.unequID)
			end
			client:AddPartModel(itemTable.uniqueID, itemTable.partdata)
			local newData = table.Copy(data)
			newData.Equipped = true
			client:UpdateInv(itemTable.uniqueID, 1, newData, true)
			hook.Run("OnPartEquipped", client, itemTable, true)
		end
	end,
	shouldDisplay = function(itemTable, data, entity)
		return !data.Equipped or data.Equipped == nil
	end
}
BASE.functions.Unequip = {
	run = function(itemTable, client, data)
		if (SERVER) then
			if itemTable.type then
				client:SetNutVar(itemTable.type, nil)
			end
			client:RemovePartModel(itemTable.uniqueID, itemTable.partdata)
			local newData = table.Copy(data)
			newData.Equipped = false
			client:UpdateInv(itemTable.uniqueID, 1, newData, true)
			hook.Run("OnPartEquipped", client, itemTable, false)
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

if (SERVER) then
	hook.Add("PlayerSpawn", "nut_PartBase", function(client)
		timer.Simple(0.1, function()
			if (!IsValid(client) or !client.character) then
				return
			end
			client:ResetPartModels()
			for class, items in pairs(client:GetInventory()) do
				local itemTable = nut.item.Get(class)

				if (itemTable and itemTable.partdata) then
					for k, v in pairs(items) do
						if (v.data.Equipped) then
							client:AddPartModel(itemTable.uniqueID, itemTable.partdata)
						end
					end
				end
			end
		end)
	end)
end
