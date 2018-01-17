if (SERVER) then
	netstream.Hook("bizBuy", function(client, items)
		local char = client:GetChar()

		if (!char) then
			return
		end

		if (table.Count(items) < 1) then
			return
		end

		local cost = 0

		for k, v in pairs(items) do
			local itemTable = ix.item.list[k]

			if (itemTable and hook.Run("CanPlayerUseBusiness", client, k) != false) then
				local amount = math.Clamp(tonumber(v) or 0, 0, 10)

				if (amount == 0) then
					items[k] = nil
				else
					cost = cost + (amount * (itemTable.price or 0))
				end
			else
				items[k] = nil
			end
		end

		if (table.Count(items) < 1) then
			return
		end

		if (char:HasMoney(cost)) then
			char:TakeMoney(cost)

			local entity = ents.Create("ix_shipment")
			entity:Spawn()
			entity:SetPos(client:GetItemDropPos(entity))
			entity:SetItems(items)
			entity:SetNetVar("owner", char:GetID())

			local shipments = char:GetVar("charEnts") or {}
			table.insert(shipments, entity)
			char:SetVar("charEnts", shipments, true)

			netstream.Start(client, "bizResp")
			hook.Run("OnCreateShipment", client, entity)
		end
	end)

	netstream.Hook("shpUse", function(client, uniqueID, drop)
		local entity = client.ixShipment
		local itemTable = ix.item.list[uniqueID]

		if (itemTable and IsValid(entity)) then
			if (entity:GetPos():Distance(client:GetPos()) > 128) then
				client.ixShipment = nil

				return
			end

			local amount = entity.items[uniqueID]

			if (amount and amount > 0) then
				if (entity.items[uniqueID] <= 0) then
					entity.items[uniqueID] = nil
				end

				if (drop) then
					ix.item.Spawn(uniqueID, entity:GetPos() + Vector(0, 0, 16))
				else
					local status, fault = client:GetChar():GetInv():Add(uniqueID)

					if (!status) then
						return client:NotifyLocalized("noFit")
					end
				end

				hook.Run("OnTakeShipmentItem", client, uniqueID, amount)

				entity.items[uniqueID] = entity.items[uniqueID] - 1

				if (entity:GetItemCount() < 1) then
					entity:GibBreakServer(Vector(0, 0, 0.5))
					entity:Remove()
				end
			end
		end
	end)
else
	netstream.Hook("openShp", function(entity, items)
		ix.gui.shipment = vgui.Create("ixShipment")
		ix.gui.shipment:SetItems(entity, items)
	end)

	netstream.Hook("updtShp", function(entity, items)
		if (ix.gui.shipment and ix.gui.shipment:IsVisible()) then
		end
	end)

	netstream.Hook("takeShp", function(name, amount)
		if (ix.gui.shipment and ix.gui.shipment:IsVisible()) then
			local item = ix.gui.shipment.itemPanel[name]

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
