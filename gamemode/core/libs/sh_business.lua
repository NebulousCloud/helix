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

if (SERVER) then
	netstream.Hook("businessBuy", function(client, id)
		local char = client:getChar()
		local inv = char:getInv()

		if (!char or !inv) then
			return false
		end

		local price = hook.Run("CanPlayerUseBusiness", char, id)

		if (price == false) then
			return false
		end

		price = (price or 0)

		local x, y = inv:add(id, 1, data)
		local item = inv:getItemAt(x, y)
		if (!item or item == false) then
			return
		end

		char:takeMoney(price)
		client:notify(L("businessPurchase", client, item.name, price > 0 and nut.currency.get(price) or "FREE"))

		hook.Run("OnPlayerUseBusiness", char, item)
	end)

	netstream.Hook("bizBuy", function(client, items)
		if (!client:getChar()) then
			return
		end

		local cost = 0

		for k, v in pairs(items) do
			local itemTable = nut.item.list[k]

			if (itemTable) then
				local amount = math.Clamp(tonumber(v) or 0, 1, 10)
				
				cost = cost + (amount * (itemTable.price or 0))
			else
				return
			end
		end

		if (client:getChar():hasMoney(cost)) then
			client:getChar():takeMoney(cost)

			local entity = ents.Create("nut_shipment")
			entity:SetPos(client:getItemDropPos())
			entity:Spawn()
			entity:setItems(items)
			entity:setNetVar("owner", client:getChar():getID())

			netstream.Start(client, "bizResp")
		end
	end)

	netstream.Hook("shpUse", function(client, uniqueID, drop)
		local entity = client.nutShipment
		local itemTable = nut.item.list[uniqueID]

		if (itemTable and IsValid(entity)) then
			if (entity:GetPos():Distance(client:GetPos()) > 128) then
				client.nutShipment = nil

				return
			end

			local amount = entity.items[uniqueID]

			if (amount and amount > 0) then
				entity.items[uniqueID] = entity.items[uniqueID] - 1

				if (entity.items[uniqueID] <= 0) then
					entity.items[uniqueID] = nil
				end

				if (drop) then
					nut.item.spawn(uniqueID, entity:GetPos() + Vector(0, 0, 16))
				else
					local status, fault = client:getChar():getInv():add(uniqueID)

					if (!status) then
						return client:notifyLocalized("noFit")
					end
				end

				if (entity:getItemCount() < 1) then
					entity:GibBreakServer(Vector(0, 0, 0.5))
					entity:Remove()
				end
			end
		end
	end)
else
	netstream.Hook("openShp", function(entity, items)
		local menu = vgui.Create("nutShipment")
		menu:setItems(entity, items)
	end)
end