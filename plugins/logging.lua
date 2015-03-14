PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
    local L = Format
    function PLUGIN:CharacterLoaded(id)
        local character = nut.char.loaded[id]
        nut.log.add(L("%s loaded char %s.", character:getPlayer():steamName(), id))
    end

    function PLUGIN:OnCharDelete(client, id)
        nut.log.add(L("%s deleted char %s.", client, id), FLAG_WARNING)
    end

    function PLUGIN:OnPlayerObserve(client, isObserving)
        nut.log.add(L("%s " .. (isObserving and "is now observing" or "quit observing"), client:Name()))
    end

    function PLUGIN:PlayerDeath(victim, inflictor, attacker)
        if (victim:IsPlayer() and attacker) then
            if (attacker:IsWorld() or victim == attacker) then
                nut.log.add(L("%s is dead.", victim:Name()))
            else
                nut.log.add(L("%s killed %s with %s.", victim:Name(), inflictor:GetClass(), (attacker:IsPlayer() and attacker:Name() or attacker:GetClass())))
            end
        end
    end

    function PLUGIN:OnTakeShipmentItem(client, itemClass, amount)
        local itemTable = nut.item.list[itemClass]
        nut.log.add(L("%s took %s from the shipment.", client:Name(), itemTable.name))
    end

    function PLUGIN:OnCreateShipment(client, shipmentEntity)
        nut.log.add(L("%s ordered shipment.", client:Name()))
    end

    function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
        local inventory = nut.item.inventories[invID]
        local itemTable = inventory:getItemAt(x, y)
        nut.log.add(L("%s %s %s.", client:Name(), isSell and "sold" or "purchased", itemTable.name))
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
            nut.log.add(L("%s, %s -> %s.", client:Name(), action, item.name))
        end
    end
end