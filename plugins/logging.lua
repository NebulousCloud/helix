
PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.description = "You can modfiy the logging text/lists on this plugin."

if (SERVER) then
	local L = Format

	ix.log.AddType("chat", function(client, ...)
		local arg = {...}
		return L("[%s] %s: %s", arg[1], client:Name(), arg[2])
	end)

	ix.log.AddType("command", function(client, ...)
		local arg = {...}

		if (#arg[2] > 0) then
			return L("%s used command '%s %s'.", client:Name(), arg[1], arg[2])
		else
			return L("%s used command '%s'.", client:Name(), arg[1])
		end
	end)

	ix.log.AddType("cfgSet", function(client, ...)
		local arg = {...}
		return L("%s set %s to '%s'.", client:Name(), arg[1], arg[2])
	end, FLAG_DANGER)

	ix.log.AddType("connect", function(client, ...)
		return L("%s has connected.", client:SteamName())
	end, FLAG_NORMAL)

	ix.log.AddType("disconnect", function(client, ...)
		if (client:IsTimingOut()) then
			return L("%s has disconnected (timed out).", client:SteamName())
		else
			return L("%s has disconnected.", client:SteamName())
		end
	end, FLAG_NORMAL)

	ix.log.AddType("charCreate", function(client, ...)
		local arg = {...}
		return L("%s created the character '%s'", client:SteamName(), arg[1])
	end, FLAG_SERVER)

	ix.log.AddType("charLoad", function(client, ...)
		local arg = {...}
		return L("%s loaded the character '%s'", client:SteamName(), arg[1])
	end, FLAG_SERVER)

	ix.log.AddType("charDelete", function(client, ...)
		local arg = {...}
		return L("%s (%s) deleted character '%s'", client:SteamName(), client:SteamID(), arg[1])
	end, FLAG_SERVER)

	ix.log.AddType("itemAction", function(client, ...)
		local arg = {...}
		local item = arg[2]
		return L("%s ran '%s' on item '%s' (#%s)", client:Name(), arg[1], item.name, item.id)
	end, FLAG_NORMAL)

	ix.log.AddType("shipmentTake", function(client, ...)
		local arg = {...}
		return L("%s took '%s' from the shipment", client:Name(), arg[1])
	end, FLAG_WARNING)

	ix.log.AddType("shipmentOrder", function(client, ...)
		return L("%s ordered a shipment", client:Name())
	end, FLAG_SUCCESS)

	ix.log.AddType("buy", function(client, ...)
		local arg = {...}
		return L("%s purchased '%s' from the NPC", client:Name(), arg[1])
	end, FLAG_SUCCESS)

	ix.log.AddType("buydoor", function(client, ...)
		return L("%s purchased the door", client:Name())
	end, FLAG_SUCCESS)

	ix.log.AddType("playerHurt", function(client, ...)
		local arg = {...}
		return L("%s has taken %d damage from %s.", client:Name(), arg[1], arg[2])
	end, FLAG_WARNING)

	ix.log.AddType("playerDeath", function(client, ...)
		local arg = {...}
		return L("%s has killed %s.", arg[1], client:Name())
	end, FLAG_DANGER)

	ix.log.AddType("inventoryAdd", function(client, ...)
		local arg = {...}
		return L("%s has gained a '%s' #%d.", client:Name(), arg[1], arg[2])
	end, FLAG_WARNING)

	ix.log.AddType("inventoryRemove", function(client, ...)
		local arg = {...}
		return L("%s has lost a '%s' #%d.", client:Name(), arg[1], arg[2])
	end, FLAG_WARNING)

	ix.log.AddType("openContainer", function(client, ...)
		local arg = {...}
		return L("%s opened a '%s' #%d.", client:Name(), arg[1], arg[2])
	end, FLAG_NORMAL)

	ix.log.AddType("closeContainer", function(client, ...)
		local arg = {...}
		return L("%s closed a '%s' #%d.", client:Name(), arg[1], arg[2])
	end, FLAG_NORMAL)

	function PLUGIN:PlayerInitialSpawn(client)
		ix.log.Add(client, "connect")
	end

	function PLUGIN:PlayerDisconnected(client)
		ix.log.Add(client, "disconnect")
	end

	function PLUGIN:OnCharCreated(client, character)
		ix.log.Add(client, "charCreate", character:GetName())
	end

	function PLUGIN:CharacterLoaded(character)
		local client = character:GetPlayer()
		ix.log.Add(client, "charLoad", character:GetName())
	end

	function PLUGIN:PreCharDelete(client, character)
		ix.log.Add(client, "charDelete", character:GetName())
	end

	function PLUGIN:OnTakeShipmentItem(client, itemClass, amount)
		local itemTable = ix.item.list[itemClass]
		ix.log.Add(client, "shipmentTake", itemTable.name)
	end

	function PLUGIN:OnCreateShipment(client, shipmentEntity)
		ix.log.Add(client, "shipmentOrder")
	end

	function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
	end

	function PLUGIN:OnPlayerInteractItem(client, action, item)
		if (type(item) == "Entity") then
			if (IsValid(item)) then
				local itemID = item.ixItemID
				item = ix.item.instances[itemID]
			else
				return
			end
		elseif (type(item) == "number") then
			item = ix.item.instances[item]
		end

		if (!item) then
			return
		end

		ix.log.Add(client, "itemAction", action, item)
	end

	function PLUGIN:InventoryItemAdded(inventory, item)
		if (!inventory.owner) then
			return
		end

		local character = ix.char.loaded[inventory.owner]

		ix.log.Add(character:GetPlayer(), "inventoryAdd", item:GetName(), item:GetID())
	end

	function PLUGIN:InventoryItemRemoved(inventory, item)
		if (!inventory.owner) then
			return
		end

		local character = ix.char.loaded[inventory.owner]

		ix.log.Add(character:GetPlayer(), "inventoryRemove", item:GetName(), item:GetID())
	end
end
