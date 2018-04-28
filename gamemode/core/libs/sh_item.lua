
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

function ix.item.Instance(index, uniqueID, itemData, x, y, callback)
	if (!uniqueID or ix.item.list[uniqueID]) then
		local query = mysql:Insert("ix_items")
			query:Insert("inventory_id", index)
			query:Insert("unique_id", uniqueID)
			query:Insert("data", util.TableToJSON(itemData))
			query:Insert("x", x)
			query:Insert("y", y)
			query:Callback(function(result, status, lastID)
				local item = ix.item.New(uniqueID, lastID)

				if (item) then
					item.data = itemData or {}
					item.invID = index

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

			if (owner and owner > 0) then
				for _, v in ipairs(player.GetAll()) do
					if (v:GetChar() and v:GetChar():GetID() == owner) then
						inventory:SetOwner(owner)
						inventory:Sync(v)

						break
					end
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
			ITEM.base = baseID
			ITEM.isBase = isBaseItem
			ITEM.hooks = ITEM.hooks or {}
			ITEM.postHooks = ITEM.postHooks or {}
			ITEM.functions = ITEM.functions or {}
			ITEM.functions.drop = ITEM.functions.drop or {
				tip = "dropTip",
				icon = "icon16/world.png",
				OnRun = function(item)
					item:Transfer()
					item.player:EmitSound("npc/zombie/foot_slide" .. math.random(1, 3) .. ".wav", 75, math.random(90, 120), 1)

					return false
				end,
				OnCanRun = function(item)
					return (!IsValid(item.entity) and !item.noDrop)
				end
			}
			ITEM.functions.take = ITEM.functions.take or {
				tip = "takeTip",
				icon = "icon16/box.png",
				OnRun = function(item)
					local client = item.player
					local status, result = client:GetChar():GetInv():Add(item.id)

					if (!status) then
						client:NotifyLocalized(result)

						return false
					else
						client:EmitSound("npc/zombie/foot_slide" .. math.random(1, 3) .. ".wav", 75, math.random(90, 120), 1)

						if (item.data) then -- I don't like it but, meh...
							for k, v in pairs(item.data) do
								item:SetData(k, v)
							end
						end
					end
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
		local inventory = setmetatable({w = w, h = h, id = id, slots = {}, vars = {}}, ix.meta.inventory)
			ix.item.inventories[id] = inventory

		return inventory
	end

	function ix.item.RestoreInv(invID, w, h, callback)
		if (type(invID) != "number" or invID < 0) then
			error("Attempt to restore inventory with an invalid ID!")
		end

		local inventory = ix.item.CreateInv(w, h, invID)

		local query = mysql:Select("ix_items")
			query:Select("item_id")
			query:Select("unique_id")
			query:Select("data")
			query:Select("x")
			query:Select("y")
			query:Where("inventory_id", invID)
			query:Callback(function(result)
				local badItemsUniqueID = {}

				if (istable(result) and #result > 0) then
					local slots = {}
					local badItems = {}

					for _, item in ipairs(result) do
						local x, y = tonumber(item.x), tonumber(item.y)
						local itemID = tonumber(item.item_id)
						local data = util.JSONToTable(item.data or "[]")

						if (x and y and itemID) then
							if (x <= w and x > 0 and y <= h and y > 0) then
								local item2 = ix.item.New(item.unique_id, itemID)

								if (item2) then
									item2.data = {}
									if (data) then
										item2.data = data
									end

									item2.gridX = x
									item2.gridY = y
									item2.invID = invID

									for x2 = 0, item2.width - 1 do
										for y2 = 0, item2.height - 1 do
											slots[x + x2] = slots[x + x2] or {}
											slots[x + x2][y + y2] = item2
										end
									end

									if (item2.OnRestored) then
										item2:OnRestored(item2, invID)
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

					inventory.slots = slots

					if (table.Count(badItems) > 0) then
						local deleteQuery = mysql:Delete("ix_items")
							deleteQuery:WhereIn("item_id", badItems)
						deleteQuery:Execute()
					end
				end

				if (callback) then
					callback(inventory, badItemsUniqueID)
				end
			end)
		query:Execute()
	end

	if (CLIENT) then
		netstream.Hook("item", function(uniqueID, id, data, invID)
			local item = ix.item.New(uniqueID, id)
			item.data = {}

			if (data) then
				item.data = data
			end

			item.invID = invID or 0
		end)

		netstream.Hook("inv", function(slots, id, w, h, owner, vars)
			local character

			if (owner) then
				character = ix.char.loaded[owner]
			else
				character = LocalPlayer():GetChar()
			end

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

				for k, v in ipairs(character:GetInv(true)) do
					if (v:GetID() == id) then
						character:GetInv(true)[k] = inventory

						return
					end
				end

				table.insert(character.vars.inv, inventory)
			end
		end)

		netstream.Hook("invData", function(id, key, value)
			local item = ix.item.instances[id]

			if (item) then
				item.data = item.data or {}
				item.data[key] = value

				local panel = item.invID and ix.gui["inv"..item.invID] or ix.gui.inv1

				if (panel and panel.panels) then
					local icon = panel.panels[id]

					if (icon) then
						icon:SetToolTip(
							Format(ix.config.itemFormat,
							item.GetName and item:GetName() or L(item.name), item:GetDescription() or "")
						)
					end
				end
			end
		end)

		netstream.Hook("invSet", function(invID, x, y, uniqueID, id, owner, data, a)
			local character = LocalPlayer():GetChar()

			if (owner) then
				character = ix.char.loaded[owner]
			end

			if (character) then
				local inventory = ix.item.inventories[invID]

				if (inventory) then
					local item = uniqueID and id and ix.item.New(uniqueID, id) or nil
					item.invID = invID

					item.data = {}
					-- Let's just be sure about it kk?
					if (data) then
						item.data = data
					end

					inventory.slots[x] = inventory.slots[x] or {}
					inventory.slots[x][y] = item

					local panel = ix.gui["inv"..invID] or ix.gui.inv1

					if (IsValid(panel)) then
						local icon = panel:AddIcon(item.model or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height)

						if (IsValid(icon)) then
							icon:SetToolTip(
								Format(ix.config.itemFormat,
								item.GetName and item:GetName() or L(item.name), item:GetDescription() or "")
							)
							icon.itemID = item.id

							panel.panels[item.id] = icon
						end
					end
				end
			end
		end)

		netstream.Hook("invMv", function(invID, itemID, x, y)
			local inventory = ix.item.inventories[invID]
			local panel = ix.gui["inv"..invID]

			if (inventory and IsValid(panel)) then
				local icon = panel.panels[itemID]

				if (IsValid(icon)) then
					icon:move({x2 = x, y2 = y}, panel, true)
				end
			end
		end)

		netstream.Hook("invRm", function(id, invID, owner)
			local character = LocalPlayer():GetChar()

			if (owner) then
				character = ix.char.loaded[owner]
			end

			if (character) then
				local inventory = ix.item.inventories[invID]

				if (inventory) then
					inventory:Remove(id)

					local panel = ix.gui["inv"..invID] or ix.gui.inv1

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
				end
			end
		end)
	else
		function ix.item.LoadItemByID(itemIndex, recipientFilter)
			local query = mysql:Select("ix_items")
				query:Select("item_id")
				query:Select("unique_id")
				query:Select("data")
				query:WhereIn("item_id", itemIndex)
				query:Callback(function(result)
					if (istable(result)) then
						for _, v in ipairs(result) do
							local itemID = tonumber(v.item_id)
							local data = util.JSONToTable(v.data or "[]")
							local uniqueID = v.unique_id
							local itemTable = ix.item.list[uniqueID]

							if (itemTable and itemID) then
								local item = ix.item.New(uniqueID, itemID)

								item.data = data or {}
								item.invID = 0
							end
						end
					end
				end)
			query:Execute()
		end

		function ix.item.PerformInventoryAction(client, action, item, invID, data)
			local character = client:GetChar()

			if (!character) then
				return
			end

			local inventory = ix.item.inventories[invID]

			if (type(item) != "Entity") then
				if (!inventory or !inventory.owner or inventory.owner != character:GetID()) then
					return
				end
			end

			if (hook.Run("CanPlayerInteractItem", client, action, item, data) == false) then
				return
			end

			if (type(item) == "Entity") then
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
			elseif (type(item) == "number") then
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

			local callback = item.functions[action]
			if (callback) then
				if (callback.OnCanRun and callback.OnCanRun(item, data) == false) then
					item.entity = nil
					item.player = nil

					return
				end

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

				hook.Run("OnPlayerInteractItem", client, action, item, result, data)

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
			end
		end

		netstream.Hook("invMv", function(client, oldX, oldY, x, y, invID, newInvID)
			oldX, oldY, x, y, invID = tonumber(oldX), tonumber(oldY), tonumber(x), tonumber(y), tonumber(invID)
			if (!oldX or !oldY or !x or !y or !invID) then return end

			local character = client:GetChar()

			if (character) then
				local inventory = ix.item.inventories[invID]

				if (!inventory or inventory == nil) then
					inventory:Sync(client)
				end

				if ((!inventory.owner or
					(inventory.owner and inventory.owner == character:GetID())) or
					(inventory.OnCheckAccess and inventory:OnCheckAccess(client))) then
					local item = inventory:GetItemAt(oldX, oldY)

					if (item) then
						if (newInvID and invID != newInvID) then
							local inventory2 = ix.item.inventories[newInvID]

							if (inventory2) then
								item:Transfer(newInvID, x, y, client)
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

							local receiver = inventory:GetReceiver()

							if (receiver and type(receiver) == "table") then
								for _, v in ipairs(receiver) do
									if (v != client) then
										netstream.Start(v, "invMv", invID, item:GetID(), x, y)
									end
								end
							end

							if (!inventory.noSave) then
								local query = mysql:Update("ix_items")
									query:Update("x", x)
									query:Update("y", y)
									query:Where("item_id", item.id)
								query:Execute()
							end
						end
					end
				end
			end
		end)

		netstream.Hook("invAct", function(client, action, item, invID, data)
			ix.item.PerformInventoryAction(client, action, item, invID, data)
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
		if (index and type(index) != "number") then
			return character.vars.inv or {}
		end

		return character.vars.inv and character.vars.inv[index or 1]
	end,
	alias = "Inv"
})
