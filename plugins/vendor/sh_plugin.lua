--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

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
					rates = v.rates,
					money = v.money,
					msg = v.messages,
					stocks = v.stocks
				}
			end
		self:setData(data)
	end

	function PLUGIN:LoadData()
		for k, v in ipairs(self:getData()) do
			local entity = ents.Create("nut_vendor")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:SetModel(v.model)
			entity:Spawn()
			entity:setNetVar("noBubble", v.bubble)
			entity:setNetVar("name", v.name)
			entity:setNetVar("desc", v.desc)

			entity.items = v.items or {}
			entity.factions = v.factions or {}
			entity.classes = v.classes or {}
			entity.rates = v.rates
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

	function PLUGIN:CanVendorSellItem(client, vendor, itemID)

	end

	function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
		if (invID) then
			local inv = nut.item.inventories[invID]
			local item = inv:getItemAt(x, y)

			if (isSell) then
				if (item) then
					client:notify(L("businessSell", client, item.name, price or L("free", client):upper()))
				end
			else
				if (item) then
					client:notify(L("businessPurchase", client, item.name, price or L("free", client):upper()))
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
			elseif (entity[key]) then
				entity[key] = value
			end

			timer.Create("nutSaveVendorEdits", 60, 1, function()
				PLUGIN:saveVendors()
			end)
		end
	end)

	netstream.Hook("ventorItemTrade", function(client, entity, request, sellToVendor)
		if (entity and IsValid(entity)) then
			if (entity:canAccess(client)) then
				if (sellToVendor) then
					if (!entity:canSellItem(client, request)) then
						client:notify(L("unableTrade", client))
						return
					end

					local char = client:getChar()
					local items = entity.items[request]
					local charItem = char:getInv():hasItem(request)

					if (charItem) then
						local price = math.Round((items[1] or 0) * 0.5)

						hook.Run("OnCharTradeVendor", client, entity, charItem.gridX, charItem.gridY, charItem.invID, price, true)
						char:giveMoney(price)
						charItem:remove()
					end
				else
					if (!entity:canBuyItem(client, request)) then
						client:notify(L("unableTrade", client))
						return
					end

					local char = client:getChar()
					local items = entity.items[request]
					local x, y, bagInv = char:getInv():add(request)

					if (x != false) then
						char:takeMoney(items[1] or 0)

						if (entity.stocks and entity.stocks[request] and entity.stocks[request][1]) then
							local stock = entity.stocks[request][1]
							entity.stocks[request][1] = math.max(stock - 1, 0)


							local recipient = {}

							for k, v in ipairs(player.GetAll()) do
								if (v.nutVendor == entity) then
									recipient[#recipient + 1] = v
								end
							end

							if (#recipient > 0) then
								-- MUST UPDATE STOCK AFTER PURCHASE
							end
						end

						hook.Run("OnCharTradeVendor", client, entity, x, y, bagInv, items[1])
					else
						client:notify(L(y, client))
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

			timer.Create("nutSaveVendorEdits", 60, 1, function()
				PLUGIN:saveVendors()
			end)
		end
	end)
else
	netstream.Hook("vendorUse", function(entity, items, rates, money, stock, adminData)
		local shop = vgui.Create("nutVendor")
		shop:setVendor(entity, items, rates, money, stock)

		if (LocalPlayer():IsAdmin() and adminData) then
			local admin = vgui.Create("nutVendorAdmin")
			admin:setData(entity, items, rates, money, stock, adminData)
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
end

nut.util.include("sh_commands.lua")