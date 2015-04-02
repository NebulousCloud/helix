VENDOR_BUY = 1
VENDOR_SELL = 2
VENDOR_BOTH = 3

PLUGIN.name = "Vendors"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds NPC vendors that can sell things."

-- Keys for vendor messages.
VENDOR_WELCOME = 1
VENDOR_LEAVE = 2
VENDOR_NOTRADE = 3

-- Keys for item information.
VENDOR_PRICE = 1
VENDOR_STOCK = 2
VENDOR_MODE = 3
VENDOR_MAXSTOCK = 4

-- Sell and buy the item.
VENDOR_SELLANDBUY = 1
-- Only sell the item to the player.
VENDOR_SELLONLY = 2
-- Only buy the item from the player.
VENDOR_BUYONLY = 3

if (SERVER) then
	local PLUGIN = PLUGIN

	function PLUGIN:saveVendors()
		local data = {}
			for k, v in ipairs(ents.FindByClass("nut_vendor")) do
				data[#data + 1] = {
					name = v:getNetVar("name"),
					desc = v:getNetVar("desc"),
					pos = v:GetPos(),
					angles = v:GetAngles(),
					model = v:GetModel(),
					bubble = v:getNetVar("noBubble"),
					items = v.items,
					factions = v.factions,
					classes = v.classes,
					money = v.money
				}
			end
		self:setData(data)
	end

	function PLUGIN:LoadData()
		for k, v in ipairs(self:getData() or {}) do
			local entity = ents.Create("nut_vendor")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:Spawn()
			entity:SetModel(v.model)
			entity:setNetVar("noBubble", v.bubble)
			entity:setNetVar("name", v.name)
			entity:setNetVar("desc", v.desc)

			entity.items = v.items or {}
			entity.factions = v.factions or {}
			entity.classes = v.classes or {}
			entity.money = v.money
		end
	end

	function PLUGIN:CanVendorSellItem(client, vendor, itemID)
		local tradeData = vendor.items[itemID]
		local char = client:getChar()

		if (!tradeData or !char) then
			print("Not Valid Item or Client Char.")
			return false
		end

		if (!char:hasMoney(tradeData[1] or 0)) then
			print("Insufficient Fund.")
			return false
		end

		return true
	end

	function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
		if (invID) then
			local inv = nut.item.inventories[invID]
			local item = inv:getItemAt(x, y)

			if (price) then
				price = nut.currency.get(price)
			else
				price = L("free", client):upper()
			end

			if (isSell) then
				if (item) then
					client:notifyLocalized("businessSell", item.name, price)
				end
			else
				if (item) then
					client:notifyLocalized("businessPurchase", item.name, price)
				end
			end
		end
	end

	netstream.Hook("vendorExit", function(client)
		local entity = client.nutVendor

		if (IsValid(entity)) then
			for k, v in ipairs(entity.receivers) do
				if (v == client) then
					table.remove(entity.receivers, k)

					break
				end
			end

			client.nutVendor = nil
		end
	end)

	netstream.Hook("vendorEdit", function(client, key, data)
		if (client:IsAdmin()) then
			local entity = client.nutVendor

			if (!IsValid(entity)) then
				return
			end

			local feedback = true

			if (key == "name") then
				entity:setNetVar("name", data)
			elseif (key == "desc") then
				entity:setNetVar("desc", data)
			elseif (key == "bubble") then
				entity:setNetVar("noBubble", data)
			elseif (key == "mode") then
				local uniqueID = data[1]

				entity.items[uniqueID] = entity.items[uniqueID] or {}
				entity.items[uniqueID][VENDOR_MODE] = data[2]

				netstream.Start(entity.receivers, "vendorEdit", key, data)
			elseif (key == "price") then
				local uniqueID = data[1]
				data[2] = tonumber(data[2])

				if (data[2]) then
					data[2] = math.Round(data[2])
				end

				entity.items[uniqueID] = entity.items[uniqueID] or {}
				entity.items[uniqueID][VENDOR_PRICE] = data[2]

				netstream.Start(entity.receivers, "vendorEdit", key, data)
				data = uniqueID
			elseif (key == "stockDisable") then
				entity.items[data] = entity.items[uniqueID] or {}
				entity.items[data][VENDOR_MAXSTOCK] = nil

				netstream.Start(entity.receivers, "vendorEdit", key, data)
			elseif (key == "stockMax") then
				local uniqueID = data[1]
				data[2] = math.max(math.Round(tonumber(data[2]) or 1), 1)

				entity.items[uniqueID] = entity.items[uniqueID] or {}
				entity.items[uniqueID][VENDOR_MAXSTOCK] = data[2]
				entity.items[uniqueID][VENDOR_STOCK] = math.Clamp(entity.items[uniqueID][VENDOR_STOCK] or data[2], 1, data[2])

				data[3] = entity.items[uniqueID][VENDOR_STOCK]

				netstream.Start(entity.receivers, "vendorEdit", key, data)
				data = uniqueID
			elseif (key == "stock") then
				local uniqueID = data[1]

				entity.items[uniqueID] = entity.items[uniqueID] or {}

				if (!entity.items[uniqueID][VENDOR_MAXSTOCK]) then
					data[2] = math.max(math.Round(tonumber(data[2]) or 0), 0)
					entity.items[uniqueID][VENDOR_MAXSTOCK] = data[2]
				end

				data[2] = math.Clamp(math.Round(tonumber(data[2]) or 0), 0, entity.items[uniqueID][VENDOR_MAXSTOCK])
				entity.items[uniqueID][VENDOR_STOCK] = data[2]

				netstream.Start(entity.receivers, "vendorEdit", key, data)
				data = uniqueID
			end

			PLUGIN:saveVendors()

			if (feedback) then
				local receivers = {}

				for k, v in ipairs(entity.receivers) do
					if (v:IsAdmin()) then
						receivers[#receivers + 1] = v
					end
				end

				netstream.Start(receivers, "vendorEditFinish", key, data)
			end
		end
	end)
else
	VENDOR_TEXT = {}
	VENDOR_TEXT[VENDOR_SELLANDBUY] = "vendorBoth"
	VENDOR_TEXT[VENDOR_BUYONLY] = "vendorBuy"
	VENDOR_TEXT[VENDOR_SELLONLY] = "vendorSell"

	netstream.Hook("vendorOpen", function(index, items, messages, factions, classes)
		local entity = Entity(index)

		if (!IsValid(entity)) then
			return
		end

		entity.items = items
		entity.messages = messages
		entity.factions = factions
		entity.classes = classes

		nut.gui.vendor = vgui.Create("nutVendor")
		nut.gui.vendor:setup(entity)

		if (messages) then
			nut.gui.vendorEditor = vgui.Create("nutVendorEditor")
		end
	end)

	netstream.Hook("vendorEdit", function(key, data)
		local panel = nut.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		if (key == "mode") then
			entity.items[data[1]] = entity.items[data[1]] or {}
			entity.items[data[1]][VENDOR_MODE] = data[2]

			if (!data[2]) then
				panel:removeItem(data[1])
			elseif (data[2] == VENDOR_SELLANDBUY) then
				panel:addItem(data[1])
			else
				panel:addItem(data[1], data[2] == VENDOR_SELLONLY and "selling" or "buying")
				panel:removeItem(data[1], data[2] == VENDOR_SELLONLY and "buying" or "selling")
			end
		elseif (key == "price") then
			local uniqueID = data[1]

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_PRICE] = tonumber(data[2])
		elseif (key == "stockDisable") then
			if (entity.items[data]) then
				entity.items[data][VENDOR_MAXSTOCK] = nil
			end
		elseif (key == "stockMax") then
			local uniqueID = data[1]
			local value = data[2]
			local current = data[3]

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_MAXSTOCK] = value
			entity.items[uniqueID][VENDOR_STOCK] = current
		elseif (key == "stock") then
			local uniqueID = data[1]
			local value = data[2]

			entity.items[uniqueID] = entity.items[uniqueID] or {}

			if (!entity.items[uniqueID][VENDOR_MAXSTOCK]) then
				entity.items[uniqueID][VENDOR_MAXSTOCK] = value
			end

			entity.items[uniqueID][VENDOR_STOCK] = value
		end
	end)

	netstream.Hook("vendorEditFinish", function(key, data)
		local panel = nut.gui.vendor
		local editor = nut.gui.vendorEditor

		if (!IsValid(panel) or !IsValid(editor)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		if (key == "name") then
			editor.name:SetText(entity:getNetVar("name"))
		elseif (key == "desc") then
			editor.desc:SetText(entity:getNetVar("desc"))
		elseif (key == "bubble") then
			editor.bubble.noSend = true
			editor.bubble:SetValue(data and 1 or 0)
		elseif (key == "mode") then
			if (data[2] == nil) then
				editor.lines[data[1]]:SetValue(2, L"none")
			else
				editor.lines[data[1]]:SetValue(2, L(VENDOR_TEXT[data[2]]))
			end
		elseif (key == "price") then
			editor.lines[data]:SetValue(3, entity:getPrice(data))
		elseif (key == "stockDisable") then
			editor.lines[data]:SetValue(4, "-")
		elseif (key == "stockMax" or key == "stock") then
			local current, max = entity:getStock(data)

			editor.lines[data]:SetValue(4, current.."/"..max)
		end

		surface.PlaySound("buttons/button14.wav")
	end)
end