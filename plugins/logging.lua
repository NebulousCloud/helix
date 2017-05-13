PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
	local L = Format

	function PLUGIN:CharacterLoaded(id)
		local character = nut.char.loaded[id]
		local client = character:getPlayer()

		--nut.log.add(client:steamName().." ("..client:SteamID()..") loaded character #"..id.." ("..character:getName()..")")
		nut.log.add(client, "charLoad", id, character:getName())
	end

	function PLUGIN:OnCharDelete(client, id)
		nut.log.add(client, "charDelete", id)
	end
	
	function PLUGIN:OnTakeShipmentItem(client, itemClass, amount)
		local itemTable = nut.item.list[itemClass]
		nut.log.add(client, "shipment", itemTable.name)
	end

	function PLUGIN:OnCreateShipment(client, shipmentEntity)
		nut.log.add(client, "shipmentO")
	end

	function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
	end

	local logInteractions = {
		["drop"] = true,
		["take"] = true,
		["equip"] = true,
		["unequip"] = true,
	}

	function PLUGIN:OnPlayerInteractItem(client, action, item)
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

			nut.log.add(client, "itemUse", action, item)
	end
end