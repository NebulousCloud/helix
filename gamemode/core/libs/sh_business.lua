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
			hook.Run("OnCreateShipment", client, entity)
		end
	end)

	netstream.Hook("takeShp", function(client, entity, name, amount)
		if (entity and entity:IsValid()) then
			local item = entity.items[name]
			if (amount > 0 and
				item >= amount and
				(item - amount) >= 0) then

				local inv = client:getChar():getInv()
				if (inv and inv:add(name, amount)) then
					netstream.Start(client, "takeShp", name, amount)
					entity.items[name] = item - amount

					if (entity.items[name] <= 0) then
						entity.items[name] = nil
					end

					entity:EmitSound(Format("physics/cardboard/cardboard_box_impact_hard%s.wav", math.random(1, 5)))

					if (table.Count(entity.items) <= 0) then
						entity:Break()
					end
				else
					client:notify("Unable to move item.")
				end
			end
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

					--netstream.Hook("updtShp", uniqueID)
				end

				entity.items[uniqueID] = entity.items[uniqueID] - 1

				if (entity:getItemCount() < 1) then
					entity:GibBreakServer(Vector(0, 0, 0.5))
					entity:Remove()
				end
			end
		end
	end)
else
	netstream.Hook("openShp", function(entity, items)
		nut.gui.shipment = vgui.Create("nutShipment")
		nut.gui.shipment:setItems(entity, items)
	end)

	netstream.Hook("updtShp", function(entity, items)
		if (nut.gui.shipment and nut.gui.shipment:IsVisible()) then
		end
	end)

	netstream.Hook("takeShp", function(name, amount)
		if (nut.gui.shipment and nut.gui.shipment:IsVisible()) then
			local item = nut.gui.shipment.itemPanel[name]

			if (item) then
				item.amount = item.amount - 1
				item:Update(item.amount)

				if (item.amount <= 0) then
					item:Remove()
				end
			end
		end
	end)
end