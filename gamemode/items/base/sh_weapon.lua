BASE.name = "Base Weapon"
BASE.uniqueID = "base_wep"
BASE.category = "Weapons"
BASE.class = "weapon_crowbar"
BASE.type = "melee"
BASE.data = {
	Equipped = false
}
BASE.functions = {}
BASE.functions.Equip = {
	run = function(itemTable, client, data)
		if (SERVER) then
			if (client:HasWeapon(itemTable.class)) then
				nut.util.Notify("You already has this weapon equipped.", client)

				return false
			end

			if (nut.config.noMultipleWepSlots and IsValid(client:GetNutVar(itemTable.type))) then
				nut.util.Notify("You already have a weapon in the "..itemTable.type.." slot.", client)

				return false
			end

			local weapon = client:Give(itemTable.class)

			if (IsValid(weapon)) then
				client:SetNutVar(itemTable.type, weapon)
				client:SelectWeapon(itemTable.class)
			end

			local newData = table.Copy(data)
			newData.Equipped = true

			client:UpdateInv(itemTable.uniqueID, 1, newData, true)
			hook.Run("OnWeaponEquipped", client, itemTable, true)
		end
	end,
	shouldDisplay = function(itemTable, data, entity)
		return !data.Equipped or data.Equipped == nil
	end
}
BASE.functions.Unequip = {
	run = function(itemTable, client, data)
		if (SERVER) then
			if (client:HasWeapon(itemTable.class)) then
				client:SetNutVar(itemTable.type, nil)
				client:StripWeapon(itemTable.class)
			end

			local newData = table.Copy(data)
			newData.Equipped = false

			client:UpdateInv(itemTable.uniqueID, 1, newData, true)
			hook.Run("OnWeaponEquipped", client, itemTable, false)
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
	hook.Add("PlayerSpawn", "nut_WeaponBase", function(client)
		timer.Simple(0.1, function()
			if (!IsValid(client) or !client.character) then
				return
			end

			for class, items in pairs(client:GetInventory()) do
				local itemTable = nut.item.Get(class)

				if (itemTable and itemTable.class) then
					for k, v in pairs(items) do
						if (v.data.Equipped) then
							local weapon = client:Give(itemTable.class)
							
							client:SetNutVar(itemTable.type, weapon)
						end
					end
				end
			end
		end)
	end)
end
