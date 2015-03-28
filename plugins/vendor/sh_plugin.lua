VENDOR_BUY = 1
VENDOR_SELL = 2
VENDOR_BOTH = 3

PLUGIN.name = "Vendors"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds NPC vendors that can sell things."

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
					msg = v.messages,
					stocks = v.stocks
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
			entity.msg = v.messages
			entity.stocks = v.stocks
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
		client.nutVendor = nil
	end)

	netstream.Hook("vendorEdit", function(client, entity, key, value)
		if (client:IsAdmin() and IsValid(entity)) then
			if (key == "name" or key == "desc") then
				entity:setNetVar(key, value)
			elseif (key == "money") then
				entity:setMoney(value)
			end

			PLUGIN:saveVendors()
		end
	end)

	netstream.Hook("ventorItemTrade", function(client, entity, request, sellToVendor)
		local itemTable = nut.item.list[request]

		if (!itemTable) then
			return
		end

		if (entity and IsValid(entity)) then
			if (entity:canAccess(client)) then
				if (sellToVendor) then
					local items = entity.items[request]
					local price = math.Round((items[1] or itemTable.price or 0) * 0.5)

					if (!entity:hasMoney(price) or !entity:canSellItem(client, request)) then
						client:notifyLocalized("unableTrade")

						return
					end

					local char = client:getChar()
					local charItem = char:getInv():hasItem(request)

					if (charItem) then
						if (!entity:hasMoney(price)) then
							client:notifyLocalized("vendorNoMoney")

							return
						end

						if (entity.stocks and entity.stocks[request] and entity.stocks[request][1] and entity.stocks[request][2] and entity.stocks[request][2] > 0) then
							local stock = entity.stocks[request][1]
							entity.stocks[request][1] = math.max(stock + 1, 0)


							local recipient = {}

							for k, v in ipairs(player.GetAll()) do
								if (v.nutVendor == entity) then
									recipient[#recipient + 1] = v
								end
							end

							if (#recipient > 0) then
								netstream.Start(recipient, "vendorStock", request, entity.stocks[request][1])
							end
						end

						hook.Run("OnCharTradeVendor", client, entity, charItem.gridX, charItem.gridY, charItem.invID, price or 0, true)

						char:giveMoney(price)
						charItem:remove()
						entity:takeMoney(price)

						netstream.Start(client, "vendorTraded", request)
					end
				else
					if (!entity:canBuyItem(client, request)) then
						client:notifyLocalized("unableTrade")

						return
					end

					local char = client:getChar()
					local items = entity.items[request]
					local price = items[1] or itemTable.price or 0

					if (!char:hasMoney(price)) then
						client:notifyLocalized("unableTrade")

						return
					end

					local x, y, bagInv = char:getInv():add(request)

					if (x != false) then						
						if (price > 0) then
							char:takeMoney(price)
							entity:giveMoney(price)
						end

						if (entity.stocks and entity.stocks[request] and entity.stocks[request][1] and entity.stocks[request][2] and entity.stocks[request][2] > 0) then
							local stock = entity.stocks[request][1]
							entity.stocks[request][1] = math.max(stock - 1, 0)


							local recipient = {}

							for k, v in ipairs(player.GetAll()) do
								if (v.nutVendor == entity) then
									recipient[#recipient + 1] = v
								end
							end

							if (#recipient > 0) then
								netstream.Start(recipient, "vendorStock", request, entity.stocks[request][1])
							end
						end

						hook.Run("OnCharTradeVendor", client, entity, x, y, bagInv, price or 0)
						netstream.Start(client, "vendorTraded", request, true)
					else
						client:notifyLocalized(y)
					end
				end
			end
		end
	end)

	netstream.Hook("vendorItemMod", function(client, entity, uniqueID, data)
		if (client:IsAdmin() and IsValid(entity)) then
			if (data.price) then
				data.price = math.max(math.floor(data.price), 0)

				entity.items[uniqueID] = entity.items[uniqueID] or {}
				entity.items[uniqueID][1] = data.price
			end

			if (data.mode) then
				data.mode = math.Clamp(math.floor(data.mode), 0, VENDOR_BOTH)

				entity.items[uniqueID] = entity.items[uniqueID] or {}
				entity.items[uniqueID][2] = data.mode > 0 and data.mode or nil
			end

			if (data.maxStock) then
				data.maxStock = math.Round(data.maxStock)

				if (data.maxStock < 1) then
					entity.stocks = {}
				else
					entity.stocks[uniqueID] = entity.stocks[uniqueID] or {}

					if (!entity.stocks[uniqueID][1] or entity.stocks[uniqueID][1] > data.maxStock) then
						data.stock = data.maxStock
					end

					entity.stocks[uniqueID][2] = data.maxStock
				end
			end

			if (data.stock and entity.stocks[uniqueID] and entity.stocks[uniqueID][2] and entity.stocks[uniqueID][2] > 0) then
				data.stock = math.Clamp(math.Round(data.stock), 0, entity.stocks[uniqueID][2])

				entity.stocks[uniqueID] = entity.stocks[uniqueID] or {}
				entity.stocks[uniqueID][1] = data.stock
			end

			client:EmitSound("buttons/button24.wav", 30)

			local recipient = {}

			for k, v in ipairs(player.GetAll()) do
				if (v.nutVendor == entity) then
					recipient[#recipient + 1] = v
				end
			end

			if (#recipient > 0) then
				netstream.Start(recipient, "vendorUpt", uniqueID, data)
			end

			PLUGIN:saveVendors()
		end
	end)

	netstream.Hook("vendorMdl", function(client, model)
		if (client:IsAdmin() and IsValid(client.nutVendor)) then
			client.nutVendor:SetModel(model)
			client.nutVendor:setAnim()

			PLUGIN:saveVendors()
		end
	end)

	netstream.Hook("vendorBbl", function(client, state)
		if (client:IsAdmin() and IsValid(client.nutVendor)) then
			client.nutVendor:setNetVar("noBubble", state)
			PLUGIN:saveVendors()
		end
	end)

	netstream.Hook("vendorFEdit", function(client, entity, index, state)
		if (client:IsAdmin() and IsValid(entity)) then
			state = util.tobool(state)

			local faction = nut.faction.indices[index]

			if (!faction) then
				return
			end

			if (!state) then
				state = nil
			end

			entity.factions[index] = state

			local recipient = {}

			for k, v in ipairs(player.GetAll()) do
				if (v.nutVendor == entity and v:IsAdmin()) then
					recipient[#recipient + 1] = v
				end
			end

			if (#recipient > 0) then
				netstream.Start(recipient, "vendorFEdit", index, state)
			end
		end
	end)

	netstream.Hook("vendorCEdit", function(client, entity, index, state)
		if (client:IsAdmin() and IsValid(entity)) then
			state = util.tobool(state)

			local class = nut.class.list[index]

			if (!class) then
				return
			end

			if (!state) then
				state = nil
			end

			entity.classes[index] = state

			local recipient = {}

			for k, v in ipairs(player.GetAll()) do
				if (v.nutVendor == entity and v:IsAdmin()) then
					recipient[#recipient + 1] = v
				end
			end

			if (#recipient > 0) then
				netstream.Start(recipient, "vendorCEdit", index, state)
			end
		end
	end)
else
	netstream.Hook("vendorMoney", function(value)
		if (IsValid(nut.gui.vendor) and IsValid(nut.gui.vendor.entity)) then
			nut.gui.vendor.entity.money = value
		end

		if (IsValid(nut.gui.vendorAdmin)) then
			nut.gui.vendorAdmin.money.noSend = true
			nut.gui.vendorAdmin.money:SetValue(value)
		end
	end)

	netstream.Hook("vendorUse", function(entity, items, money, stock, adminData)
		local shop = vgui.Create("nutVendor")
		shop:setVendor(entity, items, money, stock)

		if (LocalPlayer():IsAdmin()) then
			local admin = vgui.Create("nutVendorAdmin")
			admin:setData(entity, items, money, stock, adminData or {})
			if (admin.btnClose) then
				admin.btnClose.DoClick = function( button ) admin:Close() shop:Close() end
			end
			if (shop.btnClose) then
				shop.btnClose.DoClick = function( button ) shop:Close() admin:Close() end
			end
		end
	end)

	netstream.Hook("vendorUpt", function(uniqueID, data)
		if (IsValid(nut.gui.vendorAdmin)) then
			nut.gui.vendorAdmin:update(uniqueID, data)
		end

		if (IsValid(nut.gui.vendor)) then
			nut.gui.vendor:setVendor()
		end
	end)

	netstream.Hook("vendorStock", function(uniqueID, count)
		if (IsValid(nut.gui.vendor)) then
			nut.gui.vendor:updateStock(uniqueID, count)
		end

		if (IsValid(nut.gui.vendorAdmin)) then
			nut.gui.vendorAdmin:update(uniqueID, {stock = count})
		end
	end)

	netstream.Hook("vendorTraded", function(uniqueID, isBuying)
		if (IsValid(nut.gui.vendor)) then

			if (isBuying) then
				nut.gui.vendor.buying:addItem(uniqueID, nil, true).isSelling = true
			else
				local panel = nut.gui.vendor.buying.itemPanels[uniqueID]

				if (IsValid(panel)) then
					local count = panel.count - 1
						panel.name:SetText(nut.item.list[uniqueID].name..(count and " ("..count..")" or ""))
					panel.count = count

					if (count < 1) then
						local parent = panel:GetParent()
							panel:Remove()
						parent:InvalidateLayout()
					end
				end
			end
		end
	end)

	netstream.Hook("vendorFEdit", function(index, state)
		if (IsValid(nut.gui.vendorAdmin)) then
			local factions = nut.gui.vendorAdmin.factionBoxes

			if (IsValid(factions[index])) then
				factions[index]:SetChecked(state)
			end
		end
	end)

	netstream.Hook("vendorCEdit", function(index, state)
		if (IsValid(nut.gui.vendorAdmin)) then
			local classes = nut.gui.vendorAdmin.classBoxes

			if (IsValid(classes[index])) then
				classes[index]:SetChecked(state)
			end
		end
	end)
end

nut.util.include("sh_commands.lua")