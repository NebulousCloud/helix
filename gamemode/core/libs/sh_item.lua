--[[--
Item/inventory manipulation and helper functions.
]]
-- @module ix.item

ix.item = ix.item or {}
ix.item.list = ix.item.list or {}
ix.item.base = ix.item.base or {}
ix.item.instances = ix.item.instances or {}
ix.item.inventories = ix.item.inventories or {
	[0] = {}
}
ix.item.inventoryTypes = ix.item.inventoryTypes or {}

ix.util.Include("helix/gamemode/core/meta/sh_item.lua")

-- Declare some supports for logic inventory
local zeroInv = ix.item.inventories[0]

function zeroInv:GetID()
	return 0
end

function zeroInv:OnCheckAccess(client)
	return true
end

-- WARNING: You have to manually sync the data to client if you're trying to use item in the logical inventory in the vgui.
function zeroInv:Add(uniqueID, quantity, data, x, y)
	quantity = quantity or 1

	if (quantity > 0) then
		if (!isnumber(uniqueID)) then
			if (quantity > 1) then
				for _ = 1, quantity do
					self:Add(uniqueID, 1, data)
				end

				return
			end

			local itemTable = ix.item.list[uniqueID]

			if (!itemTable) then
				return false, "invalidItem"
			end

			ix.item.Instance(0, uniqueID, data, x, y, function(item)
				self[item:GetID()] = item
			end)

			return nil, nil, 0
		end
	else
		return false, "notValid"
	end
end

function ix.item.Instance(index, uniqueID, itemData, x, y, callback, characterID, playerID)
	if (!uniqueID or ix.item.list[uniqueID]) then
		local query = mysql:Insert("ix_items")
			query:Insert("inventory_id", index)
			query:Insert("unique_id", uniqueID)
			query:Insert("data", util.TableToJSON(itemData))
			query:Insert("x", x)
			query:Insert("y", y)

			if (characterID) then
				query:Insert("character_id", characterID)
			end

			if (playerID) then
				query:Insert("player_id", playerID)
			end

			query:Callback(function(result, status, lastID)
				local item = ix.item.New(uniqueID, lastID)

				if (item) then
					item.data = istable(itemData) and table.Copy(itemData) or {}
					item.invID = index
					item.characterID = characterID
					item.playerID = playerID

					if (callback) then
						callback(item)
					end

					if (item.OnInstanced) then
						item:OnInstanced(index, x, y, item)
					end
				end
			end)
		query:Execute()
	else
		ErrorNoHalt("[Helix] Attempt to give an invalid item! (" .. (uniqueID or "nil") .. ")\n")
	end
end

function ix.item.RegisterInv(invType, w, h, isBag)
	ix.item.inventoryTypes[invType] = {w = w, h = h}

	if (isBag) then
		ix.item.inventoryTypes[invType].isBag = invType
	end

	return ix.item.inventoryTypes[invType]
end

function ix.item.NewInv(owner, invType, callback)
	local invData = ix.item.inventoryTypes[invType] or {w = 1, h = 1}

	local query = mysql:Insert("ix_inventories")
		query:Insert("inventory_type", invType)
		query:Insert("character_id", owner)
		query:Callback(function(result, status, lastID)
			local inventory = ix.item.CreateInv(invData.w, invData.h, lastID)

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

function ix.item.Get(identifier)
	return ix.item.base[identifier] or ix.item.list[identifier]
end

function ix.item.GetInv(invID)
	return ix.item.inventories[invID]
end

function ix.item.Load(path, baseID, isBaseItem)
	local uniqueID = path:match("sh_([_%w]+)%.lua")

	if (uniqueID) then
		uniqueID = (isBaseItem and "base_" or "")..uniqueID
		ix.item.Register(uniqueID, baseID, isBaseItem, path)
	else
		if (!path:find(".txt")) then
			ErrorNoHalt("[Helix] Item at '"..path.."' follows invalid naming convention!\n")
		end
	end
end

function ix.item.Register(uniqueID, baseID, isBaseItem, path, luaGenerated)
	local meta = ix.meta.item

	if (uniqueID) then
		ITEM = (isBaseItem and ix.item.base or ix.item.list)[uniqueID] or setmetatable({}, meta)
			ITEM.uniqueID = uniqueID
			ITEM.base = baseID or ITEM.base
			ITEM.isBase = isBaseItem
			ITEM.hooks = ITEM.hooks or {}
			ITEM.postHooks = ITEM.postHooks or {}
			ITEM.functions = ITEM.functions or {}
			ITEM.functions.drop = ITEM.functions.drop or {
				tip = "dropTip",
				icon = "icon16/world.png",
				OnRun = function(item)
					local bSuccess, error = item:Transfer(nil, nil, nil, item.player)

					if (!bSuccess and isstring(error)) then
						item.player:NotifyLocalized(error)
					else
						item.player:EmitSound("npc/zombie/foot_slide" .. math.random(1, 3) .. ".wav", 75, math.random(90, 120), 1)
					end

					return false
				end,
				OnCanRun = function(item)
					return !IsValid(item.entity) and !item.noDrop
				end
			}
			ITEM.functions.take = ITEM.functions.take or {
				tip = "takeTip",
				icon = "icon16/box.png",
				OnRun = function(item)
					local client = item.player
					local bSuccess, error = item:Transfer(client:GetCharacter():GetInventory():GetID(), nil, nil, client)

					if (!bSuccess) then
						client:NotifyLocalized(error or "unknownError")
						return false
					else
						client:EmitSound("npc/zombie/foot_slide" .. math.random(1, 3) .. ".wav", 75, math.random(90, 120), 1)

						if (item.data) then -- I don't like it but, meh...
							for k, v in pairs(item.data) do
								item:SetData(k, v)
							end
						end
					end

					return true
				end,
				OnCanRun = function(item)
					return IsValid(item.entity)
				end
			}

			local oldBase = ITEM.base

			if (ITEM.base) then
				local baseTable = ix.item.base[ITEM.base]

				if (baseTable) then
					for k, v in pairs(baseTable) do
						if (ITEM[k] == nil) then
							ITEM[k] = v
						end

						ITEM.baseTable = baseTable
					end

					local mergeTable = table.Copy(baseTable)
					ITEM = table.Merge(mergeTable, ITEM)
				else
					ErrorNoHalt("[Helix] Item '"..ITEM.uniqueID.."' has a non-existent base! ("..ITEM.base..")\n")
				end
			end

			if (PLUGIN) then
				ITEM.plugin = PLUGIN.uniqueID
			end

			if (!luaGenerated and path) then
				ix.util.Include(path)
			end

			if (ITEM.base and oldBase != ITEM.base) then
				local baseTable = ix.item.base[ITEM.base]

				if (baseTable) then
					for k, v in pairs(baseTable) do
						if (ITEM[k] == nil) then
							ITEM[k] = v
						end

						ITEM.baseTable = baseTable
					end

					local mergeTable = table.Copy(baseTable)
					ITEM = table.Merge(mergeTable, ITEM)
				else
					ErrorNoHalt("[Helix] Item '"..ITEM.uniqueID.."' has a non-existent base! ("..ITEM.base..")\n")
				end
			end

			ITEM.description = ITEM.description or "noDesc"
			ITEM.width = ITEM.width or 1
			ITEM.height = ITEM.height or 1
			ITEM.category = ITEM.category or "misc"

			if (ITEM.OnRegistered) then
				ITEM:OnRegistered()
			end

			(isBaseItem and ix.item.base or ix.item.list)[ITEM.uniqueID] = ITEM

			if (IX_RELOADED) then
				-- we don't know which item was actually edited, so we'll refresh all of them
				for _, v in pairs(ix.item.instances) do
					if (v.uniqueID == uniqueID) then
						table.Merge(v, ITEM)
					end
				end
			end
		if (luaGenerated) then
			return ITEM
		else
			ITEM = nil
		end
	else
		ErrorNoHalt("[Helix] You tried to register an item without uniqueID!\n")
	end
end

function ix.item.LoadFromDir(directory)
	local files, folders

	files = file.Find(directory.."/base/*.lua", "LUA")

	for _, v in ipairs(files) do
		ix.item.Load(directory.."/base/"..v, nil, true)
	end

	files, folders = file.Find(directory.."/*", "LUA")

	for _, v in ipairs(folders) do
		if (v == "base") then
			continue
		end

		for _, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
			ix.item.Load(directory.."/"..v .. "/".. v2, "base_"..v)
		end
	end

	for _, v in ipairs(files) do
		ix.item.Load(directory.."/"..v)
	end
end

function ix.item.New(uniqueID, id)
	if (ix.item.instances[id] and ix.item.instances[id].uniqueID == uniqueID) then
		return ix.item.instances[id]
	end

	local stockItem = ix.item.list[uniqueID]

	if (stockItem) then
		local item = setmetatable({}, {__index = stockItem})
		item.id = id
		item.data = {}

		ix.item.instances[id] = item

		return item
	else
		ErrorNoHalt("[Helix] Attempt to index unknown item '"..uniqueID.."'\n")
	end
end

do
	ix.util.Include("helix/gamemode/core/meta/sh_inventory.lua")

	function ix.item.CreateInv(w, h, id)
		local inventory = setmetatable({w = w, h = h, id = id, slots = {}, vars = {}, receivers = {}}, ix.meta.inventory)
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
	-- @usage ix.item.RestoreInv({
	-- 	[10] = {5, 5},
	-- 	[11] = {7, 4}
	-- })
	-- -- inventories 10 and 11 with sizes (5, 5) and (7, 4) will be loaded
	function ix.item.RestoreInv(invID, width, height, callback)
		local inventories = {}

		if (!istable(invID)) then
			if (!isnumber(invID) or invID < 0) then
				error("Attempt to restore inventory with an invalid ID!")
			end

			inventories[invID] = {width, height}
			ix.item.CreateInv(width, height, invID)
		else
			for k, v in pairs(invID) do
				inventories[k] = {v[1], v[2]}
				ix.item.CreateInv(v[1], v[2], k)
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
				local badItemsUniqueID = {}

				if (istable(result) and #result > 0) then
					local invSlots = {}
					local badItems = {}

					for _, item in ipairs(result) do
						local itemInvID = tonumber(item.inventory_id)
						local invInfo = inventories[itemInvID]

						if (!itemInvID or !invInfo) then
							badItemsUniqueID[#badItemsUniqueID + 1] = item.unique_id
							badItems[#badItems + 1] = tonumber(item.item_id)

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
								else
									badItemsUniqueID[#badItemsUniqueID + 1] = item.unique_id
									badItems[#badItems + 1] = itemID
								end
							else
								badItemsUniqueID[#badItemsUniqueID + 1] = item.unique_id
								badItems[#badItems + 1] = itemID
							end
						end
					end

					for k, v in pairs(invSlots) do
						ix.item.inventories[k].slots = v
					end

					if (!table.IsEmpty(badItems)) then
						local deleteQuery = mysql:Delete("ix_items")
							deleteQuery:WhereIn("item_id", badItems)
						deleteQuery:Execute()
					end
				end

				if (callback) then
					for k, _ in pairs(inventories) do
						callback(ix.item.inventories[k], badItemsUniqueID)
					end
				end
			end)
		query:Execute()
	end

	if (CLIENT) then
		net.Receive("ixInventorySync", function()
			local slots = net.ReadTable()
			local id = net.ReadUInt(32)
			local w, h = net.ReadUInt(6), net.ReadUInt(6)
			local owner = net.ReadType()
			local vars = net.ReadTable()

			local character = owner and ix.char.loaded[owner] or LocalPlayer():GetCharacter()

			if (character) then
				local inventory = ix.item.CreateInv(w, h, id)
				inventory:SetOwner(character:GetID())
				inventory.slots = {}
				inventory.vars = vars

				local x, y

				for _, v in ipairs(slots) do
					x, y = v[1], v[2]

					inventory.slots[x] = inventory.slots[x] or {}

					local item = ix.item.New(v[3], v[4])

					item.data = {}
					if (v[5]) then
						item.data = v[5]
					end

					item.invID = item.invID or id
					inventory.slots[x][y] = item
				end

				character.vars.inv = character.vars.inv or {}

				for k, v in ipairs(character:GetInventory(true)) do
					if (v:GetID() == id) then
						character:GetInventory(true)[k] = inventory

						return
					end
				end

				table.insert(character.vars.inv, inventory)
			end
		end)

		net.Receive("ixInventoryData", function()
			local id = net.ReadUInt(32)
			local item = ix.item.instances[id]

			if (item) then
				local key = net.ReadString()
				local value = net.ReadType()

				item.data = item.data or {}
				item.data[key] = value

				local invID = item.invID == LocalPlayer():GetCharacter():GetInventory():GetID() and 1 or item.invID
				local panel = ix.gui["inv" .. invID]

				if (panel and panel.panels) then
					local icon = panel.panels[id]

					if (icon) then
						icon:SetHelixTooltip(function(tooltip)
							ix.hud.PopulateItemTooltip(tooltip, item)
						end)
					end
				end
			end
		end)

		net.Receive("ixInventorySet", function()
			local invID = net.ReadUInt(32)
			local x, y = net.ReadUInt(6), net.ReadUInt(6)
			local uniqueID = net.ReadString()
			local id = net.ReadUInt(32)
			local owner = net.ReadUInt(32)
			local data = net.ReadTable()

			local character = owner != 0 and ix.char.loaded[owner] or LocalPlayer():GetCharacter()

			if (character) then
				local inventory = ix.item.inventories[invID]

				if (inventory) then
					local item = (uniqueID != "" and id != 0) and ix.item.New(uniqueID, id) or nil
					item.invID = invID
					item.data = {}

					if (data) then
						item.data = data
					end

					inventory.slots[x] = inventory.slots[x] or {}
					inventory.slots[x][y] = item

					invID = invID == LocalPlayer():GetCharacter():GetInventory():GetID() and 1 or invID

					local panel = ix.gui["inv" .. invID]

					if (IsValid(panel)) then
						local icon = panel:AddIcon(
							item:GetModel() or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height, item:GetSkin()
						)

						if (IsValid(icon)) then
							icon:SetHelixTooltip(function(tooltip)
								ix.hud.PopulateItemTooltip(tooltip, item)
							end)

							icon.itemID = item.id
							panel.panels[item.id] = icon
						end
					end
				end
			end
		end)

		net.Receive("ixInventoryMove", function()
			local invID = net.ReadUInt(32)
			local inventory = ix.item.inventories[invID]

			if (!inventory) then
				return
			end

			local itemID = net.ReadUInt(32)
			local oldX = net.ReadUInt(6)
			local oldY = net.ReadUInt(6)
			local x = net.ReadUInt(6)
			local y = net.ReadUInt(6)

			invID = invID == LocalPlayer():GetCharacter():GetInventory():GetID() and 1 or invID

			local item = ix.item.instances[itemID]
			local panel = ix.gui["inv" .. invID]

			-- update inventory UI if it's open
			if (IsValid(panel)) then
				local icon = panel.panels[itemID]

				if (IsValid(icon)) then
					icon:Move(x, y, panel, true)
				end
			end

			-- update inventory slots
			if (item) then
				inventory.slots[oldX][oldY] = nil

				inventory.slots[x] = inventory.slots[x] or {}
				inventory.slots[x][y] = item
			end
		end)

		net.Receive("ixInventoryRemove", function()
			local id = net.ReadUInt(32)
			local invID = net.ReadUInt(32)

			local inventory = ix.item.inventories[invID]

			if (!inventory) then
				return
			end

			inventory:Remove(id)

			invID = invID == LocalPlayer():GetCharacter():GetInventory():GetID() and 1 or invID
			local panel = ix.gui["inv" .. invID]

			if (IsValid(panel)) then
				local icon = panel.panels[id]

				if (IsValid(icon)) then
					for _, v in ipairs(icon.slots or {}) do
						if (v.item == icon) then
							v.item = nil
						end
					end

					icon:Remove()
				end
			end

			local item = ix.item.instances[id]

			if (!item) then
				return
			end

			-- we need to close any bag windows that are open because of this item
			if (item.isBag) then
				local itemInv = item:GetInventory()

				if (itemInv) then
					local frame = ix.gui["inv" .. itemInv:GetID()]

					if (IsValid(frame)) then
						frame:Remove()
					end
				end
			end
		end)
	else
		util.AddNetworkString("ixInventorySync")
		util.AddNetworkString("ixInventorySet")
		util.AddNetworkString("ixInventoryMove")
		util.AddNetworkString("ixInventoryRemove")
		util.AddNetworkString("ixInventoryData")
		util.AddNetworkString("ixInventoryAction")

		function ix.item.LoadItemByID(itemIndex, recipientFilter)
			local query = mysql:Select("ix_items")
				query:Select("item_id")
				query:Select("unique_id")
				query:Select("data")
				query:Select("character_id")
				query:Select("player_id")
				query:WhereIn("item_id", itemIndex)
				query:Callback(function(result)
					if (istable(result)) then
						for _, v in ipairs(result) do
							local itemID = tonumber(v.item_id)
							local data = util.JSONToTable(v.data or "[]")
							local uniqueID = v.unique_id
							local itemTable = ix.item.list[uniqueID]
							local characterID = tonumber(v.character_id)
							local playerID = tostring(v.player_id)

							if (itemTable and itemID) then
								local item = ix.item.New(uniqueID, itemID)

								item.data = data or {}
								item.invID = 0
								item.characterID = characterID
								item.playerID = (playerID == "" or playerID == "NULL") and nil or playerID
							end
						end
					end
				end)
			query:Execute()
		end

		function ix.item.PerformInventoryAction(client, action, item, invID, data)
			local character = client:GetCharacter()

			if (!character) then
				return
			end

			local inventory = ix.item.inventories[invID or 0]

			if (hook.Run("CanPlayerInteractItem", client, action, item, data) == false) then
				return
			end

			if (!inventory:OnCheckAccess(client)) then
				return
			end

			if (isentity(item)) then
				if (IsValid(item)) then
					local entity = item
					local itemID = item.ixItemID
					item = ix.item.instances[itemID]

					if (!item) then
						return
					end

					item.entity = entity
					item.player = client
				else
					return
				end
			elseif (isnumber(item)) then
				item = ix.item.instances[item]

				if (!item) then
					return
				end

				item.player = client
			end

			if (item.entity) then
				if (item.entity:GetPos():Distance(client:GetPos()) > 96) then
					return
				end
			elseif (!inventory:GetItemByID(item.id)) then
				return
			end

			if (!item.bAllowMultiCharacterInteraction and IsValid(client) and client:GetCharacter()) then
				local itemPlayerID = item:GetPlayerID()
				local itemCharacterID = item:GetCharacterID()
				local playerID = client:SteamID64()
				local characterID = client:GetCharacter():GetID()

				if (itemPlayerID and itemCharacterID and itemPlayerID == playerID and itemCharacterID != characterID) then
					client:NotifyLocalized("itemOwned")

					item.player = nil
					item.entity = nil
					return
				end
			end

			local callback = item.functions[action]

			if (callback) then
				if (callback.OnCanRun and callback.OnCanRun(item, data) == false) then
					item.entity = nil
					item.player = nil

					return
				end

				hook.Run("PlayerInteractItem", client, action, item)

				local entity = item.entity
				local result

				if (item.hooks[action]) then
					result = item.hooks[action](item, data)
				end

				if (result == nil) then
					result = callback.OnRun(item, data)
				end

				if (item.postHooks[action]) then
					-- Posthooks shouldn't override the result from OnRun
					item.postHooks[action](item, result, data)
				end

				if (result != false) then
					if (IsValid(entity)) then
						entity.ixIsSafe = true
						entity:Remove()
					else
						item:Remove()
					end
				end

				item.entity = nil
				item.player = nil

				return result != false
			end
		end

		local function NetworkInventoryMove(receiver, invID, itemID, oldX, oldY, x, y)
			net.Start("ixInventoryMove")
				net.WriteUInt(invID, 32)
				net.WriteUInt(itemID, 32)
				net.WriteUInt(oldX, 6)
				net.WriteUInt(oldY, 6)
				net.WriteUInt(x, 6)
				net.WriteUInt(y, 6)
			net.Send(receiver)
		end

		net.Receive("ixInventoryMove", function(length, client)
			local oldX, oldY, x, y = net.ReadUInt(6), net.ReadUInt(6), net.ReadUInt(6), net.ReadUInt(6)
			local invID, newInvID = net.ReadUInt(32), net.ReadUInt(32)

			local character = client:GetCharacter()

			if (character) then
				local inventory = ix.item.inventories[invID]

				if (!inventory or inventory == nil) then
					inventory:Sync(client)
				end

				if ((!inventory.owner or (inventory.owner and inventory.owner == character:GetID())) or
					inventory:OnCheckAccess(client)) then
					local item = inventory:GetItemAt(oldX, oldY)

					if (item) then
						if (newInvID and invID != newInvID) then
							local inventory2 = ix.item.inventories[newInvID]

							if (inventory2) then
								local bStatus, error = item:Transfer(newInvID, x, y, client)

								if (!bStatus) then
									NetworkInventoryMove(
										client, item.invID, item:GetID(), item.gridX, item.gridY, item.gridX, item.gridY
									)

									client:NotifyLocalized(error or "unknownError")
								end
							end

							return
						end

						if (inventory:CanItemFit(x, y, item.width, item.height, item)) then
							item.gridX = x
							item.gridY = y

							for x2 = 0, item.width - 1 do
								for y2 = 0, item.height - 1 do
									local previousX = inventory.slots[oldX + x2]

									if (previousX) then
										previousX[oldY + y2] = nil
									end
								end
							end

							for x2 = 0, item.width - 1 do
								for y2 = 0, item.height - 1 do
									inventory.slots[x + x2] = inventory.slots[x + x2] or {}
									inventory.slots[x + x2][y + y2] = item
								end
							end

							local receivers = inventory:GetReceivers()

							if (istable(receivers)) then
								local filtered = {}

								for _, v in ipairs(receivers) do
									if (v != client) then
										filtered[#filtered + 1] = v
									end
								end

								if (#filtered > 0) then
									NetworkInventoryMove(
										filtered, invID, item:GetID(), oldX, oldY, x, y
									)
								end
							end

							if (!inventory.noSave) then
								local query = mysql:Update("ix_items")
									query:Update("x", x)
									query:Update("y", y)
									query:Where("item_id", item.id)
								query:Execute()
							end
						else
							NetworkInventoryMove(
								client, item.invID, item:GetID(), item.gridX, item.gridY, item.gridX, item.gridY
							)
						end
					end
				else
					local item = inventory:GetItemAt(oldX, oldY)

					if (item) then
						NetworkInventoryMove(
							client, item.invID, item.invID, item:GetID(), item.gridX, item.gridY, item.gridX, item.gridY
						)
					end
				end
			end
		end)

		net.Receive("ixInventoryAction", function(length, client)
			ix.item.PerformInventoryAction(client, net.ReadString(), net.ReadUInt(32), net.ReadUInt(32), net.ReadTable())
		end)
	end

	-- Instances and spawns a given item type.
	function ix.item.Spawn(uniqueID, position, callback, angles, data)
		ix.item.Instance(0, uniqueID, data or {}, 1, 1, function(item)
			local entity = item:Spawn(position, angles)

			if (callback) then
				callback(item, entity)
			end
		end)
	end
end

ix.char.RegisterVar("Inventory", {
	bNoNetworking = true,
	bNoDisplay = true,
	OnGet = function(character, index)
		if (index and !isnumber(index)) then
			return character.vars.inv or {}
		end

		return character.vars.inv and character.vars.inv[index or 1]
	end,
	alias = "Inv"
})
