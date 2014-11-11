--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

PLUGIN.name = "Storage"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Provides the ability to store items."

PLUGIN.definitions = PLUGIN.definitions or {}
nut.util.include("sh_definitions.lua")

for k, v in pairs(PLUGIN.definitions) do
	if (v.name and v.width and v.height) then
		nut.item.registerInv("st"..v.name, v.width, v.height)
	else
		ErrorNoHalt("[NutScript] Storage for '"..k.."' is missing all inventory information!\n")
		PLUGIN.definitions[k] = nil
	end
end

if (SERVER) then
	function PLUGIN:PlayerSpawnedProp(client, model, entity)
		local data = self.definitions[model:lower()]

		if (data) then
			local storage = ents.Create("nut_storage")
			storage:SetPos(entity:GetPos())
			storage:SetAngles(entity:GetAngles())
			storage:Spawn()
			storage:SetModel(model)
			storage:SetSolid(SOLID_VPHYSICS)
			storage:PhysicsInit(SOLID_VPHYSICS)

			nut.item.newInv(0, "st"..data.name, function(inventory)
				storage:setInventory(inventory)

				function inventory:onCanTransfer(client, oldX, oldY, x, y, newInvID)
					return hook.Run("StorageCanTransfer", inventory, client, oldX, oldY, x, y, newInvID)
				end
			end)

			self:saveStorage()
			entity:Remove()
		end
	end

	function PLUGIN:saveStorage()
		local data = {}

		for k, v in ipairs(ents.FindByClass("nut_storage")) do
			if (v:getInv()) then
				data[#data + 1] = {v:GetPos(), v:GetAngles(), v:getNetVar("id"), v:GetModel()}
			end
		end

		self:setData(data)
	end

	function PLUGIN:StorageItemRemoved(entity, inventory)
		self:saveStorage()
	end

	function PLUGIN:StorageCanTransfer(inventory, client, oldX, oldY, x, y, newInvID)
		local inventory2 = nut.item.inventories[newInvID]

		print(inventory2)
	end

	function PLUGIN:LoadData()
		local data = self:getData()

		if (data) then
			for k, v in ipairs(data) do
				local data2 = self.definitions[v[4]:lower()]

				if (data2) then
					local storage = ents.Create("nut_storage")
					storage:SetPos(v[1])
					storage:SetAngles(v[2])
					storage:Spawn()
					storage:SetModel(v[4])
					storage:SetSolid(SOLID_VPHYSICS)
					storage:PhysicsInit(SOLID_VPHYSICS)
					
					nut.item.restoreInv(v[3], data2.width, data2.height, function(inventory)
						function inventory:onCanTransfer(client, oldX, oldY, x, y, newInvID)
							print(self)
							return hook.Run("StorageCanTransfer", inventory, client, oldX, oldY, x, y, newInvID)
						end

						storage:setNetVar("id", v[3])
					end)
				end
			end
		end
	end

	netstream.Hook("invExit", function(client)
		local entity = client.nutBagEntity

		if (IsValid(entity)) then
			entity.receivers[client] = nil
		end

		client.nutBagEntity = nil
	end)
else
	local PLUGIN = PLUGIN

	netstream.Hook("invOpen", function(entity, index)
		local inventory = nut.item.inventories[index]

		if (IsValid(entity) and inventory and inventory.slots) then
			local data = PLUGIN.definitions[entity:GetModel():lower()]

			if (data) then
				nut.gui.inv1 = vgui.Create("nutInventory")
				nut.gui.inv1:ShowCloseButton(true)

				local inventory2 = LocalPlayer():getChar():getInv()

				if (inventory2) then
					nut.gui.inv1:setInventory(inventory2)
				end

				local panel = vgui.Create("nutInventory")
				panel:ShowCloseButton(true)
				panel:SetTitle(data.name)
				panel:setInventory(inventory)
				panel:MoveLeftOf(nut.gui.inv1, 4)
				panel.OnClose = function(this)
					if (IsValid(nut.gui.inv1) and !IsValid(nut.gui.menu)) then
						nut.gui.inv1:Remove()
					end

					netstream.Start("invExit")
				end

				nut.gui["inv"..index] = panel
			end
		end
	end)
end