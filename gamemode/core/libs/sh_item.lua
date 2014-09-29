nut.item = nut.item or {}
nut.item.list = nut.item.list or {}
nut.item.base = nut.item.base or {}
nut.item.instances = nut.item.instances or {}

nut.util.include("nutscript/gamemode/core/meta/sh_item.lua")

function nut.item.instance(owner, uniqueID, data, x, y, callback)
	if (!uniqueID or nut.item.list[uniqueID]) then
		nut.db.insertTable({
			_charID = owner,
			_uniqueID = uniqueID,
			_data = data,
			_x = x,
			_y = y
		}, function(data, itemID)
			local item = nut.item.new(uniqueID, itemID)

			if (item) then
				if (callback) then
					callback(item)
				end
			end
		end, "items")
	else
		ErrorNoHalt("[NutScript] Attempt to give an invalid item! ("..(uniqueID or "nil")..")\n")
	end
end

function nut.item.load(path, baseID, isBaseItem)
	local uniqueID = path:match("sh_([_%w]+)%.lua")
	local meta = FindMetaTable("Item")

	if (uniqueID) then
		uniqueID = (isBaseItem and "base_" or "")..uniqueID

		ITEM = (isBaseItem and nut.item.base or nut.item.list)[uniqueID] or setmetatable({}, {__index = meta})
			ITEM.uniqueID = uniqueID
			ITEM.base = baseID
			ITEM.isBase = isBaseItem
			ITEM.data = ITEM.data or {}
			ITEM.hooks = ITEM.hooks or {}
			ITEM.functions = ITEM.functions or {}
			ITEM.functions.drop = {
				tip = "dropTip",
				icon = "icon16/world.png",
				onRun = function(item)
					item:spawn(item.player)
					item.player:getChar():getInv():remove(item.id, nil, true)
				end,
				onCanRun = function(item)
					return !IsValid(item.entity)
				end
			}
			ITEM.functions.take = {
				tip = "takeTip",
				icon = "icon16/box.png",
				onRun = function(item)
					local status, result = item.player:getChar():getInv():add(item.id)

					if (item.data) then -- I don't like it but, meh...
						for k, v in pairs(item.data) do
							item:setData(k, v)
						end
					end

					if (!status) then
						item.player:notify(result)

						return false
					end
				end,
				onCanRun = function(item)
					return IsValid(item.entity)
				end
			}

			if (PLUGIN) then
				ITEM.plugin = PLUGIN.uniqueID
			end

			nut.util.include(path)
				if (ITEM.base) then
					local baseTable = nut.item.base[ITEM.base]

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
						ErrorNoHalt("[NutScript] Item '"..ITEM.uniqueID.."' has a non-existent base! ("..ITEM.base..")")
					end
				end

				ITEM.width = ITEM.width or 1
				ITEM.height = ITEM.height or 1
			(isBaseItem and nut.item.base or nut.item.list)[ITEM.uniqueID] = ITEM
		ITEM = nil
	else
		ErrorNoHalt("[NutScript] Item at '"..path.."' follows invalid naming convention!\n")
	end
end

function nut.item.register(uniqueID, baseID, isBaseItem)
	local meta = FindMetaTable("Item")

	if (uniqueID) then
		uniqueID = (isBaseItem and "base_" or "")..uniqueID

		ITEM = (isBaseItem and nut.item.base or nut.item.list)[uniqueID] or setmetatable({}, {__index = meta})
			ITEM.uniqueID = uniqueID
			ITEM.base = baseID
			ITEM.isBase = isBaseItem
			ITEM.data = ITEM.data or {}
			ITEM.hooks = ITEM.hooks or {}
			ITEM.functions = ITEM.functions or {}
			ITEM.functions.drop = {
				tip = "dropTip",
				icon = "icon16/world.png",
				onRun = function(item)
					item:spawn(item.player)
					item.player:getChar():getInv():remove(item.id, nil, true)
				end,
				onCanRun = function(item)
					return !IsValid(item.entity)
				end
			}
			ITEM.functions.take = {
				tip = "takeTip",
				icon = "icon16/box.png",
				onRun = function(item)
					local status, result = item.player:getChar():getInv():add(item.id)

					if (item.data) then -- I don't like it but, meh...
						for k, v in pairs(item.data) do
							item:setData(k, v)
						end
					end

					if (!status) then
						item.player:notify(result)

						return false
					end
				end,
				onCanRun = function(item)
					return IsValid(item.entity)
				end
			}

			if (PLUGIN) then
				ITEM.plugin = PLUGIN.uniqueID
			end

			if (ITEM.base) then
				local baseTable = nut.item.base[ITEM.base]

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
					ErrorNoHalt("[NutScript] Item '"..ITEM.uniqueID.."' has a non-existent base! ("..ITEM.base..")")
				end
			end

			ITEM.width = ITEM.width or 1
			ITEM.height = ITEM.height or 1

			(isBaseItem and nut.item.base or nut.item.list)[ITEM.uniqueID] = ITEM
		return ITEM
	else
		ErrorNoHalt("[NutScript] You tried to register an item without uniqueID!\n")
	end
end


function nut.item.loadFromDir(directory)
	local files, folders

	files = file.Find(directory.."/base/*.lua", "LUA")

	for k, v in ipairs(files) do
		nut.item.load(directory.."/base/"..v, nil, true)
	end

	files, folders = file.Find(directory.."/*", "LUA")

	for k, v in ipairs(folders) do
		if (v == "base") then
			continue
		end
		
		for k2, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
			nut.item.load(directory.."/"..v .. "/".. v2, "base_"..v)
		end
	end

	for k, v in ipairs(files) do
		nut.item.load(directory.."/"..v)
	end
end

function nut.item.new(uniqueID, id)
	local stockItem = nut.item.list[uniqueID]

	if (stockItem) then
		local item = setmetatable({}, {__index = stockItem})
		item.id = id
		item.data = table.Copy(stockItem.data)
		nut.item.instances[id] = item

		return item
	else
		ErrorNoHalt("[NutScript] Attempt to index unknown item '"..uniqueID.."'\n")
	end
end

do
	nut.util.include("nutscript/gamemode/core/meta/sh_inventory.lua")

	function nut.item.createInv(w, h)
		return setmetatable({w = w, h = h}, {__index = FindMetaTable("Inventory")})
	end


	if (CLIENT) then
		netstream.Hook("inv", function(slots, w, h, owner)
			local character

			if (owner) then
				character = nut.char.loaded[owner]
			end

			if (character) then
				local inventory = nut.item.createInv(w, h)
				inventory:setOwner(owner)
				inventory.slots = {}

				local x, y
				
				for k, v in ipairs(slots) do
					x, y = v[1], v[2]

					inventory.slots[x] = inventory.slots[x] or {}

					local item = nut.item.new(v[3], v[4])
						item.data = table.Merge(item.data, v[5] or {})
					inventory.slots[x][y] = item
				end

				character.vars.inv = inventory
			end
		end)

		netstream.Hook("invSet", function(uniqueID, id, x, y, owner)
			local character = LocalPlayer():getChar()

			if (owner) then
				character = nut.char.loaded[owner]
			end

			if (character) then
				local inventory = character:getInv()

				if (inventory) then
					local item = uniqueID and id and nut.item.new(uniqueID, id) or nil
					inventory.slots[x] = inventory.slots[x] or {}
					inventory.slots[x][y] = item

					local panel = nut.gui.inv

					if (IsValid(panel)) then
						local icon = panel:addIcon(item.model or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height)

						if (IsValid(icon)) then
							icon:SetToolTip("Item #"..item.id.."\n"..L("itemInfo", item.name, item.desc))

							panel.panels[item.id] = icon
						end
					end
				end
			end
		end)

		netstream.Hook("invData", function(id, key, value)
			local item = nut.item.instances[id]

			if (item) then
				item.data[key] = value
			end
		end)

		netstream.Hook("invSet", function(uniqueID, id, x, y, owner)
			local character = LocalPlayer():getChar()

			if (owner) then
				character = nut.char.loaded[owner]
			end

			if (character) then
				local inventory = character:getInv()

				if (inventory) then
					local item = uniqueID and id and nut.item.new(uniqueID, id) or nil
					inventory.slots[x] = inventory.slots[x] or {}
					inventory.slots[x][y] = item

					local panel = nut.gui.inv

					if (IsValid(panel)) then
						local icon = panel:addIcon(item.model or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height)

						if (IsValid(icon)) then
							icon:SetToolTip("Item #"..item.id.."\n"..L("itemInfo", item.name, item.desc))

							panel.panels[item.id] = icon
						end
					end
				end
			end
		end)

		netstream.Hook("invRmv", function(id, owner)
			local character = LocalPlayer():getChar()

			if (owner) then
				character = nut.char.loaded[owner]
			end

			if (character) then
				local inventory = character:getInv()

				if (inventory) then
					inventory:remove(id)

					local panel = nut.gui.inv

					if (IsValid(panel)) then
						local icon = panel.panels[id]

						if (IsValid(icon)) then
							for k, v in ipairs(icon.slots or {}) do
								v.item = nil
							end

							icon:Remove()
						end
					end
				end
			end			
		end)
	else
		netstream.Hook("invMove", function(client, oldX, oldY, x, y)
			oldX, oldY, x, y = tonumber(oldX), tonumber(oldY), tonumber(x), tonumber(y)
			if (!oldX or !oldY or !x or !y) then return end

			local character = client:getChar()

			if (character) then
				local inventory = character:getInv()
				local item = inventory:getItemAt(oldX, oldY)

				if (item) then
					if (inventory:canItemFit(x, y, item.width, item.height, item)) then
						item.gridX = x
						item.gridY = y

						for x2 = 0, item.width - 1 do
							for y2 = 0, item.height - 1 do
								inventory.slots[oldX + x2] = inventory.slots[oldX + x2] or {}
								inventory.slots[oldX + x2][oldY + y2] = nil

								inventory.slots[x + x2] = inventory.slots[x + x2] or {}
								inventory.slots[x + x2][y + y2] = item
							end
						end

						nut.db.query("UPDATE nut_items SET _x = "..x..", _y = "..y.." WHERE _itemID = "..item.id)
					end
				end
			end
		end)

		netstream.Hook("invAct", function(client, action, item)
			local character = client:getChar()

			if (!character) then
				return
			end

			if (type(item) == "Entity") then
				if (IsValid(item)) then
					local entity = item
					local itemID = item.nutItemID
					item = nut.item.instances[itemID]

					if (!item) then
						return
					end

					item.entity = entity
					item.player = client
				else
					return
				end
			elseif (type(item) == "number") then
				item = nut.item.instances[item]

				if (!item) then
					return
				end

				item.player = client
			end

			if (item.entity) then
				if (item.entity:GetPos():Distance(client:GetPos()) > 96) then
					return
				end
			elseif (!character:getInv():getItemByID(item.id)) then
				return
			end

			local callback = item.functions[action]

			if (item.functions[action]) then
				if (callback.onCanRun and callback.onCanRun(item) == false) then
					item.entity = nil
					item.player = nil

					return
				end

				if (callback.onRun(item) != false) then
					if (item.entity) then
						item.entity:Remove()
					else
						character:getInv():remove(item.id, nil, true)
						nut.db.query("UPDATE nut_items SET _charID = 0 WHERE _itemID = "..item.id)
					end
				end

				if (item.hooks[action]) then
					item.hooks[action](item)
				end

				item.entity = nil
				item.player = nil
			end
		end)
	end
end

nut.char.registerVar("inv", {
	isLocal = true,
	noDisplay = true
})
