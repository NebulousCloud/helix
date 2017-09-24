PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.description = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
	nut.log.AddType("chat", function(client, ...)
		local arg = {...}
		return (Format("[%s] %s: %s", arg[1], client:Name(), arg[2]))
	end)
	nut.log.AddType("command", function(client, ...)
		local arg = {...}
		return (Format("%s used command '%s'", client:Name(), arg[1]))
	end)
	nut.log.AddType("charLoad", function(client, ...)
		local arg = {...}
		return (Format("%s loaded the character #%s(%s)", client:Name(), arg[1], arg[2]))
	end)
	nut.log.AddType("charDelete", function(client, ...)
		local arg = {...}
		return (Format("%s(%s) deleted character (%s)", client:SteamName(), client:SteamID(), arg[1]))
	end)
	nut.log.AddType("itemUse", function(client, ...)
		local arg = {...}
		local item = arg[2]
		return (Format("%s tried '%s' to item '%s'(#%s)", client:Name(), arg[1], item.name, item.id))
	end)
	nut.log.AddType("shipment", function(client, ...)
		local arg = {...}
		return (Format("%s took '%s' from the shipment", client:Name(), arg[1]))
	end)
	nut.log.AddType("shipmentO", function(client, ...)
		local arg = {...}
		return (Format("%s ordered a shipment", client:Name()))
	end)
	nut.log.AddType("buy", function(client, ...)
		local arg = {...}
		return (Format("%s purchased '%s' from the NPC", client:Name(), arg[1]))
	end)
	nut.log.AddType("buydoor", function(client, ...)
		local arg = {...}
		return (Format("%s purchased the door", client:Name()))
	end)

	local L = Format

	function PLUGIN:CharacterLoaded(id)
		local character = nut.char.loaded[id]
		local client = character:GetPlayer()

		--nut.log.Add(client:SteamName().." ("..client:SteamID()..") loaded character #"..id.." ("..character:GetName()..")")
		nut.log.Add(client, "charLoad", id, character:GetName())
	end

	function PLUGIN:OnCharDelete(client, id)
		nut.log.Add(client, "charDelete", id)
	end
	
	function PLUGIN:OnTakeShipmentItem(client, itemClass, amount)
		local itemTable = nut.item.list[itemClass]
		nut.log.Add(client, "shipment", itemTable.name)
	end

	function PLUGIN:OnCreateShipment(client, shipmentEntity)
		nut.log.Add(client, "shipmentO")
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

		nut.log.Add(client, "itemUse", action, item)
	end
end