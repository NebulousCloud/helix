PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
	local L = Format

	function PLUGIN:CharacterLoaded(id)
		local character = nut.char.loaded[id]
		local client = character:getPlayer()

		nut.log.add(client:steamName().." ("..client:SteamID()..") loaded character #"..id.." ("..character:getName()..")")
	end

	function PLUGIN:OnCharDelete(client, id)
		nut.log.add(client, "deleted character #"..id, FLAG_WARNING)
	end

	function PLUGIN:PlayerDeath(victim, inflictor, attacker)
		if (victim:IsPlayer() and attacker) then
			if (attacker:IsWorld() or victim == attacker) then
				nut.log.add(victim, "has died")
			else
				local victimName = victim:Name().." ("..victim:SteamID()..")"

				if (attacker:IsPlayer()) then
					nut.log.add(attacker, L("killed %s with %s", victimName, inflictor:GetClass()))
				else
					nut.log.add(L("%s killed %s with %s.", tostring(attacker), victimName, inflictor:GetClass()))
				end
			end
		end
	end

	function PLUGIN:OnTakeShipmentItem(client, itemClass, amount)
		local itemTable = nut.item.list[itemClass]
		nut.log.add(client, L("took %s from the shipment.", itemTable.name))
	end

	function PLUGIN:OnCreateShipment(client, shipmentEntity)
		nut.log.add(client, L("ordered a shipment."))
	end

	function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
		local inventory = nut.item.inventories[invID]
		local itemTable = inventory:getItemAt(x, y)
		nut.log.add(client, L("%s %s.", isSell and "sold" or "purchased", itemTable.name))
	end

	local logInteractions = {
		["drop"] = true,
		["take"] = true,
		["equip"] = true,
		["unequip"] = true,
	}

	function PLUGIN:OnPlayerInteractItem(client, action, item)
		if (logInteractions[action:lower()]) then
			if (type(item) == "Entity") then
				if (IsValid(item)) then
					local entity = item
					local itemID = item.nutItemID
					item = nut.item.instances[itemID]
				else
					return
				end
			elseif (type(item) == "number") then
				item = nut.item.instances[item]
			end

			if (!item) then
				return
			end

			nut.log.add(client, L("used \"%s\" on %s.", action, item.name))
		end
	end
end