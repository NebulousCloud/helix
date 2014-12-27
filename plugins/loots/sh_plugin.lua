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

PLUGIN.name = "Loot"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Get loots mate."

nut.config.add("loot", 0, "Dead player will drop all items.", nil, {
	data = {min = 0, max = 1},
	category = "loot"
})


function PLUGIN:PlayerDeath(client)
	local char = client:getChar()

	if (char) then
		local inventory = char:getInv()
		
		local storage = ents.Create("nut_storage")
		storage:SetPos(client:GetPos() + Vector(0, 0, 10))
		storage:SetAngles(AngleRand())
		storage:Spawn()
		storage:SetModel("models/props_c17/SuitCase_Passenger_Physics.mdl")
		storage:SetSolid(SOLID_VPHYSICS)
		storage:PhysicsInit(SOLID_VPHYSICS)
		storage.generated = true

		local w, h = nut.config.get("invW"), nut.config.get("invH")
		local inventory = nut.item.createInv(w, h, "_"..storage:EntIndex())
		inventory.generated = true
		inventory:setOwner(0)
		function inventory:onCanTransfer(client, oldX, oldY, x, y, newInvID)
			return hook.Run("StorageCanTransfer", inventory, client, oldX, oldY, x, y, newInvID)
		end

		storage:setInventory(inventory)
		timer.Simple(300, function()
			if (storage and storage:IsValid()) then
				storage:Remove()
			end
		end)
		

		for k, v in pairs(inventory:getItems(true)) do
			if (v.noDrop) then
				continue
			end

			print(v.name)
		end
	end
end