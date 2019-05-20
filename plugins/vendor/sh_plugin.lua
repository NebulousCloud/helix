
--[[
	luacheck: globals
	VENDOR_BUY VENDOR_SELL VENDOR_BOTH VENDOR_WELCOME VENDOR_LEAVE VENDOR_NOTRADE VENDOR_PRICE VENDOR_STOCK VENDOR_MODE
	VENDOR_MAXSTOCK VENDOR_SELLANDBUY VENDOR_SELLONLY VENDOR_BUYONLY VENDOR_TEXT
]]

local PLUGIN = PLUGIN

PLUGIN.name = "Vendors"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds NPC vendors that can sell things."

CAMI.RegisterPrivilege({
	Name = "Helix - Manage Vendors",
	MinAccess = "admin"
})

VENDOR_BUY = 1
VENDOR_SELL = 2
VENDOR_BOTH = 3

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
	util.AddNetworkString("ixVendorOpen")
	util.AddNetworkString("ixVendorClose")
	util.AddNetworkString("ixVendorTrade")

	util.AddNetworkString("ixVendorEdit")
	util.AddNetworkString("ixVendorEditFinish")
	util.AddNetworkString("ixVendorEditor")
	util.AddNetworkString("ixVendorMoney")
	util.AddNetworkString("ixVendorStock")
	util.AddNetworkString("ixVendorAddItem")

	function PLUGIN:SaveData()
		local data = {}

		for _, entity in ipairs(ents.FindByClass("ix_vendor")) do
			local bodygroups = {}

			for _, v in ipairs(entity:GetBodyGroups() or {}) do
				bodygroups[v.id] = entity:GetBodygroup(v.id)
			end

			data[#data + 1] = {
				name = entity:GetDisplayName(),
				description = entity:GetDescription(),
				pos = entity:GetPos(),
				angles = entity:GetAngles(),
				model = entity:GetModel(),
				skin = entity:GetSkin(),
				bodygroups = bodygroups,
				bubble = entity:GetNoBubble(),
				items = entity.items,
				factions = entity.factions,
				classes = entity.classes,
				money = entity.money,
				scale = entity.scale
			}
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		for _, v in ipairs(self:GetData() or {}) do
			local entity = ents.Create("ix_vendor")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:Spawn()

			entity:SetModel(v.model)
			entity:SetSkin(v.skin or 0)
			entity:SetSolid(SOLID_BBOX)
			entity:PhysicsInit(SOLID_BBOX)

			local physObj = entity:GetPhysicsObject()

			if (IsValid(physObj)) then
				physObj:EnableMotion(false)
				physObj:Sleep()
			end

			entity:SetNoBubble(v.bubble)
			entity:SetDisplayName(v.name)
			entity:SetDescription(v.description)

			for id, bodygroup in pairs(v.bodygroups or {}) do
				entity:SetBodygroup(id, bodygroup)
			end

			entity.items = v.items or {}
			entity.factions = v.factions or {}
			entity.classes = v.classes or {}
			entity.money = v.money
			entity.scale = v.scale or 0.5
		end
	end

	function PLUGIN:CanVendorSellItem(client, vendor, itemID)
		local tradeData = vendor.items[itemID]
		local char = client:GetCharacter()

		if (!tradeData or !char) then
			return false
		end

		if (!char:HasMoney(tradeData[1] or 0)) then
			return false
		end

		return true
	end

	ix.log.AddType("vendorUse", function(client, ...)
		local arg = {...}
		return string.format("%s used the '%s' vendor.", client:Name(), arg[1])
	end)

	net.Receive("ixVendorClose", function(length, client)
		local entity = client.ixVendor

		if (IsValid(entity)) then
			for k, v in ipairs(entity.receivers) do
				if (v == client) then
					table.remove(entity.receivers, k)

					break
				end
			end

			client.ixVendor = nil
		end
	end)

	local function UpdateEditReceivers(receivers, key, value)
		net.Start("ixVendorEdit")
			net.WriteString(key)
			net.WriteType(value)
		net.Send(receivers)
	end

	net.Receive("ixVendorEdit", function(length, client)
		if (!CAMI.PlayerHasAccess(client, "Helix - Manage Vendors", nil)) then
			return
		end

		local entity = client.ixVendor

		if (!IsValid(entity)) then
			return
		end

		local key = net.ReadString()
		local data = net.ReadType()
		local feedback = true

		if (key == "name") then
			entity:SetDisplayName(data)
		elseif (key == "description") then
			entity:SetDescription(data)
		elseif (key == "bubble") then
			entity:SetNoBubble(data)
		elseif (key == "mode") then
			local uniqueID = data[1]

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_MODE] = data[2]

			UpdateEditReceivers(entity.receivers, key, data)
		elseif (key == "price") then
			local uniqueID = data[1]
			data[2] = tonumber(data[2])

			if (data[2]) then
				data[2] = math.Round(data[2])
			end

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_PRICE] = data[2]

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "stockDisable") then
			local uniqueID = data[1]

			entity.items[data] = entity.items[uniqueID] or {}
			entity.items[data][VENDOR_MAXSTOCK] = nil

			UpdateEditReceivers(entity.receivers, key, data)
		elseif (key == "stockMax") then
			local uniqueID = data[1]
			data[2] = math.max(math.Round(tonumber(data[2]) or 1), 1)

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_MAXSTOCK] = data[2]
			entity.items[uniqueID][VENDOR_STOCK] = math.Clamp(entity.items[uniqueID][VENDOR_STOCK] or data[2], 1, data[2])

			data[3] = entity.items[uniqueID][VENDOR_STOCK]

			UpdateEditReceivers(entity.receivers, key, data)

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

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "faction") then
			local faction = ix.faction.teams[data]

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

			for _, v in ipairs(ix.class.list) do
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
			entity:SetSolid(SOLID_BBOX)
			entity:PhysicsInit(SOLID_BBOX)
			entity:SetAnim()
		elseif (key == "useMoney") then
			if (entity.money) then
				entity:SetMoney()
			else
				entity:SetMoney(0)
			end
		elseif (key == "money") then
			data = math.Round(math.abs(tonumber(data) or 0))

			entity:SetMoney(data)
			feedback = false
		elseif (key == "scale") then
			data = tonumber(data) or 0.5

			entity.scale = data

			UpdateEditReceivers(entity.receivers, key, data)
		end

		PLUGIN:SaveData()

		if (feedback) then
			local receivers = {}

			for _, v in ipairs(entity.receivers) do
				if (CAMI.PlayerHasAccess(v, "Helix - Manage Vendors", nil)) then
					receivers[#receivers + 1] = v
				end
			end

			net.Start("ixVendorEditFinish")
				net.WriteString(key)
				net.WriteType(data)
			net.Send(receivers)
		end
	end)

	net.Receive("ixVendorTrade", function(length, client)
		if ((client.ixVendorTry or 0) < CurTime()) then
			client.ixVendorTry = CurTime() + 0.33
		else
			return
		end

		local entity = client.ixVendor

		if (!IsValid(entity) or client:GetPos():Distance(entity:GetPos()) > 192) then
			return
		end

		local uniqueID = net.ReadString()
		local isSellingToVendor = net.ReadBool()

		if (entity.items[uniqueID] and
			hook.Run("CanPlayerTradeWithVendor", client, entity, uniqueID, isSellingToVendor) != false) then
			local price = entity:GetPrice(uniqueID, isSellingToVendor)

			if (isSellingToVendor) then
				local found = false
				local name

				if (!entity:HasMoney(price)) then
					return client:NotifyLocalized("vendorNoMoney")
				end

				local invOkay = true

				for _, v in pairs(client:GetCharacter():GetInventory():GetItems()) do
					if (v.uniqueID == uniqueID and v:GetID() != 0 and ix.item.instances[v:GetID()] and v:GetData("equip", false) == false) then
						invOkay = v:Remove()
						found = true
						name = L(v.name, client)

						break
					end
				end

				if (!found) then
					return
				end

				if (!invOkay) then
					client:GetCharacter():GetInventory():Sync(client, true)
					return client:NotifyLocalized("tellAdmin", "trd!iid")
				end

				client:GetCharacter():GiveMoney(price)
				client:NotifyLocalized("businessSell", name, ix.currency.Get(price))
				entity:TakeMoney(price)
				entity:AddStock(uniqueID)

				PLUGIN:SaveData()
				hook.Run("CharacterVendorTraded", client, entity, uniqueID, isSellingToVendor)
			else
				local stock = entity:GetStock(uniqueID)

				if (stock and stock < 1) then
					return client:NotifyLocalized("vendorNoStock")
				end

				if (!client:GetCharacter():HasMoney(price)) then
					return client:NotifyLocalized("canNotAfford")
				end

				local name = L(ix.item.list[uniqueID].name, client)

				client:GetCharacter():TakeMoney(price)
				client:NotifyLocalized("businessPurchase", name, ix.currency.Get(price))

				entity:GiveMoney(price)

				if (!client:GetCharacter():GetInventory():Add(uniqueID)) then
					ix.item.Spawn(uniqueID, client)
				else
					net.Start("ixVendorAddItem")
						net.WriteString(uniqueID)
					net.Send(client)
				end

				entity:TakeStock(uniqueID)

				PLUGIN:SaveData()
				hook.Run("CharacterVendorTraded", client, entity, uniqueID, isSellingToVendor)
			end
		else
			client:NotifyLocalized("vendorNoTrade")
		end
	end)
else
	VENDOR_TEXT = {}
	VENDOR_TEXT[VENDOR_SELLANDBUY] = "vendorBoth"
	VENDOR_TEXT[VENDOR_BUYONLY] = "vendorBuy"
	VENDOR_TEXT[VENDOR_SELLONLY] = "vendorSell"

	net.Receive("ixVendorOpen", function()
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then
			return
		end

		entity.money = net.ReadUInt(16)
		entity.items = net.ReadTable()
		entity.scale = net.ReadFloat()

		ix.gui.vendor = vgui.Create("ixVendor")
		ix.gui.vendor:SetReadOnly(false)
		ix.gui.vendor:Setup(entity)
	end)

	net.Receive("ixVendorEditor", function()
		local entity = net.ReadEntity()

		if (!IsValid(entity) or !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Manage Vendors", nil)) then
			return
		end

		entity.money = net.ReadUInt(16)
		entity.items = net.ReadTable()
		entity.scale = net.ReadFloat()
		entity.messages = net.ReadTable()
		entity.factions = net.ReadTable()
		entity.classes = net.ReadTable()

		ix.gui.vendor = vgui.Create("ixVendor")
		ix.gui.vendor:SetReadOnly(true)
		ix.gui.vendor:Setup(entity)
		ix.gui.vendorEditor = vgui.Create("ixVendorEditor")
	end)

	net.Receive("ixVendorEdit", function()
		local panel = ix.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local key = net.ReadString()
		local data = net.ReadType()

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

	net.Receive("ixVendorEditFinish", function()
		local panel = ix.gui.vendor
		local editor = ix.gui.vendorEditor

		if (!IsValid(panel) or !IsValid(editor)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local key = net.ReadString()
		local data = net.ReadType()

		if (key == "name") then
			editor.name:SetText(entity:GetDisplayName())
		elseif (key == "description") then
			editor.description:SetText(entity:GetDescription())
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
			editor.lines[data]:SetValue(3, entity:GetPrice(data))
		elseif (key == "stockDisable") then
			editor.lines[data]:SetValue(4, "-")
		elseif (key == "stockMax" or key == "stock") then
			local current, max = entity:GetStock(data)

			editor.lines[data]:SetValue(4, current.."/"..max)
		elseif (key == "faction") then
			local uniqueID = data[1]
			local state = data[2]
			local editPanel = ix.gui.editorFaction

			entity.factions[uniqueID] = state

			if (IsValid(editPanel) and IsValid(editPanel.factions[uniqueID])) then
				editPanel.factions[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "class") then
			local uniqueID = data[1]
			local state = data[2]
			local editPanel = ix.gui.editorFaction

			entity.classes[uniqueID] = state

			if (IsValid(editPanel) and IsValid(editPanel.classes[uniqueID])) then
				editPanel.classes[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "model") then
			editor.model:SetText(entity:GetModel())
		elseif (key == "scale") then
			editor.sellScale.noSend = true
			editor.sellScale:SetValue(data)
		end

		surface.PlaySound("buttons/button14.wav")
	end)

	net.Receive("ixVendorMoney", function()
		local panel = ix.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local value = net.ReadUInt(16)
		value = value != -1 and value or nil

		entity.money = value

		local editor = ix.gui.vendorEditor

		if (IsValid(editor)) then
			local useMoney = tonumber(value) != nil

			editor.money:SetDisabled(!useMoney)
			editor.money:SetEnabled(useMoney)
			editor.money:SetText(useMoney and value or "∞")
		end
	end)

	net.Receive("ixVendorStock", function()
		local panel = ix.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local uniqueID = net.ReadString()
		local amount = net.ReadUInt(16)

		entity.items[uniqueID] = entity.items[uniqueID] or {}
		entity.items[uniqueID][VENDOR_STOCK] = amount

		local editor = ix.gui.vendorEditor

		if (IsValid(editor)) then
			local _, max = entity:GetStock(uniqueID)

			editor.lines[uniqueID]:SetValue(4, amount .. "/" .. max)
		end
	end)

	net.Receive("ixVendorAddItem", function()
		local uniqueID = net.ReadString()

		if (IsValid(ix.gui.vendor)) then
			ix.gui.vendor:addItem(uniqueID, "buying")
		end
	end)
end

properties.Add("vendor_edit", {
	MenuLabel = "Edit Vendor",
	Order = 999,
	MenuIcon = "icon16/user_edit.png",

	Filter = function(self, entity, client)
		if (!IsValid(entity)) then return false end
		if (entity:GetClass() != "ix_vendor") then return false end
		if (!gamemode.Call( "CanProperty", client, "vendor_edit", entity)) then return false end

		return CAMI.PlayerHasAccess(client, "Helix - Manage Vendors", nil)
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		entity.receivers[#entity.receivers + 1] = client

		local itemsTable = {}

		for k, v in pairs(entity.items) do
			if (!table.IsEmpty(v)) then
				itemsTable[k] = v
			end
		end

		client.ixVendor = entity

		net.Start("ixVendorEditor")
			net.WriteEntity(entity)
			net.WriteUInt(entity.money or 0, 16)
			net.WriteTable(itemsTable)
			net.WriteFloat(entity.scale or 0.5)
			net.WriteTable(entity.messages)
			net.WriteTable(entity.factions)
			net.WriteTable(entity.classes)
		net.Send(client)
	end
})
