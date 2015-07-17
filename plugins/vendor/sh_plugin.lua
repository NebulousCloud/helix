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
					money = v.money,
					scale = v.scale
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
			entity.scale = v.scale or 0.5
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
			elseif (key == "faction") then
				local faction = nut.faction.teams[data]

				if (faction) then
					entity.factions[data] = !entity.factions[data]

					if (!entity.factions[data]) then
						entity.factions[data] = nil
					end
				end

				local uniqueID = data
				data = {uniqueID, entity.factions[uniqueID]}
			elseif (key == "class") then
				local class

				for k, v in ipairs(nut.class.list) do
					if (v.uniqueID == data) then
						class = v

						break
					end
				end

				if (class) then
					entity.classes[data] = !entity.classes[data]

					if (!entity.classes[data]) then
						entity.classes[data] = nil
					end
				end

				local uniqueID = data
				data = {uniqueID, entity.classes[uniqueID]}
			elseif (key == "model") then
				entity:SetModel(data)
				entity:setAnim()
			elseif (key == "useMoney") then
				if (entity.money) then
					entity:setMoney()
				else
					entity:setMoney(0)
				end
			elseif (key == "money") then
				data = math.Round(math.abs(tonumber(data) or 0))

				entity:setMoney(data)
				feedback = false
			elseif (key == "scale") then
				data = tonumber(data) or 0.5

				entity.scale = data
				netstream.Start(entity.receivers, "vendorEdit", key, data)
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

	netstream.Hook("vendorTrade", function(client, uniqueID, isSellingToVendor)
		if ((client.nutVendorTry or 0) < CurTime()) then
			client.nutVendorTry = CurTime() + 0.33
		else
			return
		end

		local found
		local entity = client.nutVendor

		if (!IsValid(entity) or client:GetPos():Distance(entity:GetPos()) > 192) then
			return
		end

		if (entity.items[uniqueID] and hook.Run("CanPlayerTradeWithVendor", client, entity, uniqueID, isSellingToVendor) != false) then
			local price = entity:getPrice(uniqueID, isSellingToVendor)

			if (isSellingToVendor) then
				local found = false
				local name

				for k, v in pairs(client:getChar():getInv():getItems()) do
					if (v.uniqueID == uniqueID) then
						v:remove()
						found = true
						name = L(v.name, client)

						break
					end
				end

				if (!found) then
					return
				end

				if (!entity:hasMoney(price)) then
					return client:notifyLocalized("vendorNoMoney")
				end

				client:getChar():giveMoney(price)
				client:notifyLocalized("businessSell", name, nut.currency.get(price))

				entity:takeMoney(price)
				entity:addStock(uniqueID)

				PLUGIN:saveVendors()
			else
				local stock = entity:getStock(uniqueID)

				if (stock and stock < 1) then
					return client:notifyLocalized("vendorNoStock")
				end

				if (!client:getChar():hasMoney(price)) then
					return client:notifyLocalized("canNotAfford")
				end

				local name = L(nut.item.list[uniqueID].name, client)

				client:getChar():takeMoney(price)
				client:notifyLocalized("businessPurchase", name, price)
				
				entity:giveMoney(price)

				if (!client:getChar():getInv():add(uniqueID)) then
					nut.item.spawn(uniqueID, client:getItemDropPos())
				else
					netstream.Start(client, "vendorAdd", uniqueID)
				end

				entity:takeStock(uniqueID)

				PLUGIN:saveVendors()
			end
		else
			client:notifyLocalized("vendorNoTrade")
		end
	end)
else
	VENDOR_TEXT = {}
	VENDOR_TEXT[VENDOR_SELLANDBUY] = "vendorBoth"
	VENDOR_TEXT[VENDOR_BUYONLY] = "vendorBuy"
	VENDOR_TEXT[VENDOR_SELLONLY] = "vendorSell"

	netstream.Hook("vendorOpen", function(index, items, money, scale, messages, factions, classes)
		local entity = Entity(index)

		if (!IsValid(entity)) then
			return
		end

		entity.money = money
		entity.items = items
		entity.messages = messages
		entity.factions = factions
		entity.classes = classes
		entity.scale = scale

		nut.gui.vendor = vgui.Create("nutVendor")
		nut.gui.vendor:setup(entity)

		if (LocalPlayer():IsAdmin() and messages) then
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
		elseif (key == "scale") then
			entity.scale = data
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
		elseif (key == "faction") then
			local uniqueID = data[1]
			local state = data[2]
			local panel = nut.gui.editorFaction

			entity.factions[uniqueID] = state

			if (IsValid(panel) and IsValid(panel.factions[uniqueID])) then
				panel.factions[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "class") then
			local uniqueID = data[1]
			local state = data[2]
			local panel = nut.gui.editorFaction

			entity.classes[uniqueID] = state

			if (IsValid(panel) and IsValid(panel.classes[uniqueID])) then
				panel.classes[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "model") then
			editor.model:SetText(entity:GetModel())
		elseif (key == "scale") then
			editor.sellScale.noSend = true
			editor.sellScale:SetValue(data)
		end

		surface.PlaySound("buttons/button14.wav")
	end)

	netstream.Hook("vendorMoney", function(value)
		local panel = nut.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		entity.money = value

		local editor = nut.gui.vendorEditor

		if (IsValid(editor)) then
			local useMoney = tonumber(value) != nil

			editor.money:SetDisabled(!useMoney)
			editor.money:SetEnabled(useMoney)
			editor.money:SetText(useMoney and value or "∞")
		end
	end)

	netstream.Hook("vendorStock", function(uniqueID, amount)
		local panel = nut.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		entity.items[uniqueID] = entity.items[uniqueID] or {}
		entity.items[uniqueID][VENDOR_STOCK] = amount

		local editor = nut.gui.vendorEditor

		if (IsValid(editor)) then
			local _, max = entity:getStock(uniqueID)

			editor.lines[uniqueID]:SetValue(4, amount.."/"..max)
		end
	end)

	netstream.Hook("vendorAdd", function(uniqueID)
		if (IsValid(nut.gui.vendor)) then
			nut.gui.vendor:addItem(uniqueID, "buying")
		end
	end)
end