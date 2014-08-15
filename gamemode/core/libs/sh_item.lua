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

			nut.util.include(path)
				if (ITEM.base) then
					local baseTable = nut.item.list[ITEM.base]

					if (baseTable) then
						for k, v in pairs(baseTable) do
							if (ITEM[k] == nil) then
								ITEM[k] = v
							end

							ITEM.baseTable = baseTable
						end
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

function nut.item.loadFromDir(directory)
	local files, folders

	files = file.Find(directory.."/base/*.lua", "LUA")

	for k, v in ipairs(files) do
		nut.item.load(directory.."/base/"..v, nil, true)
	end

	files, folders = file.Find(directory.."/*", "LUA")

	for k, v in ipairs(folders) do
		for k2, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
			nut.item.load(directory.."/"..v, "base_"..v)
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
			local character = LocalPlayer():getChar()

			if (owner) then
				character = nut.char.loaded[owner]
			end

			if (character) then
				local inventory = nut.item.createInv(w, h)
				inventory:setOwner(owner)
				
				local x, y
				
				for k, v in ipairs(slots) do
					x, y = v[1], v[2]

					inventory.slots[x] = inventory.slots[x] or {}
					inventory.slots[x][y] = nut.item.new(v[3], v[4])
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
						panel:addIcon(item.model or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height)
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
	end
end

nut.char.registerVar("inv", {
	isLocal = true,
	noDisplay = true
})