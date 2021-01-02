
--[[--
Inventory manipulation and helper functions.
]]
-- @module ix.inventory

ix.inventory = ix.inventory or {}

ix.util.Include("helix/gamemode/core/meta/sh_inventory.lua")

--- Retrieves an inventory table.
-- @realm shared
-- @number invID Index of the inventory
-- @treturn Inventory Inventory table
function ix.inventory.Get(invID)
	return ix.item.inventories[invID]
end

function ix.inventory.Create(width, height, id)
	local inventory = ix.meta.inventory:New(id, width, height)
		ix.item.inventories[id] = inventory
	return inventory
end

--- Loads an inventory and associated items from the database into memory. If you are passing a table into `invID`, it
-- requires a table where the key is the inventory ID, and the value is a table of the width and height values. See below
-- for an example.
-- @realm server
-- @param invID Inventory ID or table of inventory IDs
-- @number width Width of inventory (this is not used when passing a table to `invID`)
-- @number height Height of inventory (this is not used when passing a table to `invID`)
-- @func callback Function to call when inventory is restored
-- @usage ix.inventory.Restore({
-- 	[10] = {5, 5},
-- 	[11] = {7, 4}
-- })
-- -- inventories 10 and 11 with sizes (5, 5) and (7, 4) will be loaded
function ix.inventory.Restore(invID, width, height, callback)
	local inventories = {}

	if (!istable(invID)) then
		if (!isnumber(invID) or invID < 0) then
			error("Attempt to restore inventory with an invalid ID!")
		end

		inventories[invID] = {width, height}
		ix.inventory.Create(width, height, invID)
	else
		for k, v in pairs(invID) do
			inventories[k] = {v[1], v[2]}
			ix.inventory.Create(v[1], v[2], k)
		end
	end

	local query = mysql:Select("ix_items")
		query:Select("item_id")
		query:Select("inventory_id")
		query:Select("unique_id")
		query:Select("data")
		query:Select("character_id")
		query:Select("player_id")
		query:Select("x")
		query:Select("y")
		query:WhereIn("inventory_id", table.GetKeys(inventories))
		query:Callback(function(result)
			if (istable(result) and #result > 0) then
				local invSlots = {}

				for _, item in ipairs(result) do
					local itemInvID = tonumber(item.inventory_id)
					local invInfo = inventories[itemInvID]

					if (!itemInvID or !invInfo) then
						-- don't restore items with an invalid inventory id or type
						continue
					end

					local inventory = ix.item.inventories[itemInvID]
					local x, y = tonumber(item.x), tonumber(item.y)
					local itemID = tonumber(item.item_id)
					local data = util.JSONToTable(item.data or "[]")
					local characterID, playerID = tonumber(item.character_id), tostring(item.player_id)

					if (x and y and itemID) then
						if (x <= inventory.w and x > 0 and y <= inventory.h and y > 0) then
							local item2 = ix.item.New(item.unique_id, itemID)

							if (item2) then
								invSlots[itemInvID] = invSlots[itemInvID] or {}
								local slots = invSlots[itemInvID]

								item2.data = {}

								if (data) then
									item2.data = data
								end

								item2.gridX = x
								item2.gridY = y
								item2.invID = itemInvID
								item2.characterID = characterID
								item2.playerID = (playerID == "" or playerID == "NULL") and nil or playerID

								for x2 = 0, item2.width - 1 do
									for y2 = 0, item2.height - 1 do
										slots[x + x2] = slots[x + x2] or {}
										slots[x + x2][y + y2] = item2
									end
								end

								if (item2.OnRestored) then
									item2:OnRestored(item2, itemInvID)
								end
							end
						end
					end
				end

				for k, v in pairs(invSlots) do
					ix.item.inventories[k].slots = v
				end
			end

			if (callback) then
				for k, _ in pairs(inventories) do
					callback(ix.item.inventories[k])
				end
			end
		end)
	query:Execute()
end

function ix.inventory.New(owner, invType, callback)
	local invData = ix.item.inventoryTypes[invType] or {w = 1, h = 1}

	local query = mysql:Insert("ix_inventories")
		query:Insert("inventory_type", invType)
		query:Insert("character_id", owner)
		query:Callback(function(result, status, lastID)
			local inventory = ix.inventory.Create(invData.w, invData.h, lastID)

			if (invType) then
				inventory.vars.isBag = invType
			end

			if (isnumber(owner) and owner > 0) then
				local character = ix.char.loaded[owner]
				local client = character:GetPlayer()

				inventory:SetOwner(owner)

				if (IsValid(client)) then
					inventory:Sync(client)
				end
			end

			if (callback) then
				callback(inventory)
			end
		end)
	query:Execute()
end

function ix.inventory.Register(invType, w, h, isBag)
	ix.item.inventoryTypes[invType] = {w = w, h = h}

	if (isBag) then
		ix.item.inventoryTypes[invType].isBag = invType
	end

	return ix.item.inventoryTypes[invType]
end
