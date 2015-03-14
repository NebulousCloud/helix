VENDOR_BUY = 1
VENDOR_SELL = 2
VENDOR_BOTH = 3

local PANEL = {}
	function PANEL:Init()
		if (IsValid(nut.gui.vendor)) then
			nut.gui.vendor:Remove()
		end

		nut.gui.vendor = self

		self:SetSize(ScrW() * 0.5, 680)
		self:MakePopup()
		self:Center()

		self.selling = self:Add("nutVendorItemList")
		self.selling:Dock(LEFT)
		self.selling:SetWide(self:GetWide() * 0.5 - 7)
		self.selling:SetDrawBackground(true)
		self.selling:DockMargin(0, 0, 5, 0)
		self.selling.action:SetText(L"buy")

		self.buying = self:Add("nutVendorItemList")
		self.buying:Dock(RIGHT)
		self.buying:SetWide(self:GetWide() * 0.5 - 7)
		self.buying:SetDrawBackground(true)
		self.buying.title:SetText(LocalPlayer():Name())
		self.buying.title.Think = function(this)
			if ((this.nutNextTick or 0) < CurTime()) then
				local newText = LocalPlayer():Name().. " ("..nut.currency.symbol..LocalPlayer():getChar():getMoney()..")"

				if (this:GetText() != newText) then
					this:SetText(newText)
				end

				this.nutNextTick = CurTime() + 0.2
			end
		end
		self.buying.action:SetText(L"sell")

		self.tally = {}

		for k, v in pairs(LocalPlayer():getChar():getInv():getItems()) do
			if (v.base == "base_bags") then
				continue
			end

			self.tally[v.uniqueID] = (self.tally[v.uniqueID] or 0) + 1
		end

		self.selling.action.DoClick = function()
			if (self.entity) then
				local selectedItem = nut.gui.vendor.activeItem

				if (IsValid(selectedItem) and !selectedItem.isSelling) then
					netstream.Start("ventorItemTrade", self.entity, selectedItem.uniqueID)
				end
			end
		end

		self.buying.action.DoClick = function()
			if (self.entity) then
				local selectedItem = nut.gui.vendor.activeItem

				if (IsValid(selectedItem) and selectedItem.isSelling) then
					netstream.Start("ventorItemTrade", self.entity, selectedItem.uniqueID, true)
				end
			end
		end
	end

	function PANEL:setVendor(entity, items, money, stocks)
		entity = entity or self.entity
		items = items or self.items or {}
		money = money or self.money or 0
		stocks = stocks or self.stocks or {}

		self.selling.items:Clear()
		self.buying.items:Clear()

		if (IsValid(entity)) then
			entity.money = money

			self.entity = entity
			self.items = items
			self.money = money
			self.stocks = stocks

			self.selling.title:SetText(entity:getNetVar("name"))
			self.selling.title.Think = function(this)
				if ((this.nutNextTick or 0) < CurTime()) then
					local money = entity.money
					local newText = entity:getNetVar("name")..(money and " ("..nut.currency.symbol..money..")" or "")

					if (this:GetText() != newText) then
						this:SetText(newText)
					end

					this.nutNextTick = CurTime() + 0.2
				end
			end

			self:SetTitle(entity:getNetVar("name"))

			local count = 0

			for k, v in SortedPairs(self.tally) do
				local mode = items[k] and items[k][2]

				if (!mode or mode == VENDOR_SELL) then
					continue
				end
				
				self.buying:addItem(k, v).isSelling = true
				count = count + 1
			end

			if (count == 0) then
				local fault = self.buying.items:Add("DLabel")
				fault:SetText(L"vendorNoSellItems")
				fault:SetContentAlignment(5)
				fault:Dock(FILL)
				fault:SetFont("nutChatFont")
			end

			count = 0

			for k, v in SortedPairs(items) do
				if (items[k] and items[k][2] and items[k][2] == VENDOR_SELL or items[k][2] == VENDOR_BOTH) then
					local amount = stocks and stocks[k] and stocks[k][1] or nil

					if (amount and amount < 1) then
						continue
					end

					self.selling:addItem(k, amount)
					count = count + 1
				end
			end

			if (count == 0) then
				local fault = self.selling.items:Add("DLabel")
				fault:SetText(L"vendorNoBuyItems")
				fault:SetContentAlignment(5)
				fault:Dock(FILL)
				fault:SetFont("nutChatFont")
			end
		end
	end

	function PANEL:updateStock(uniqueID, count)
		local itemTable = nut.item.list[uniqueID]

		if (!itemTable) then
			return
		end

		local panel = self.selling.itemPanels[uniqueID]

		self.stocks[uniqueID] = self.stocks[uniqueID] or {}
		self.stocks[uniqueID][1] = count

		if (IsValid(panel)) then
			panel.name:SetText(itemTable.name.. " ("..count..")")
			panel:Remove()

			if (count < 1) then
				self:setVendor()
			end
		end
	end

	function PANEL:OnRemove()
		LocalPlayer():ChatPrint(self.entity:getNetVar("name", "John Doe")..": "..L"vendorBye")
		netstream.Start("vendorExit")
	end
vgui.Register("nutVendor", PANEL, "DFrame")

PANEL = {}
	function PANEL:Init()
		self.title = self:Add("DLabel")
		self.title:SetTextColor(color_white)
		self.title:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.title:Dock(TOP)
		self.title:SetFont("nutBigFont")
		self.title:SizeToContentsY()
		self.title:SetContentAlignment(7)
		self.title:SetTextInset(10, 5)
		self.title.Paint = function(this, w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
		end
		self.title:SetTall(self.title:GetTall() + 10)

		self.items = self:Add("DScrollPanel")
		self.items:Dock(FILL)
		self.items:SetDrawBackground(true)
		self.items:DockMargin(5, 5, 5, 5)

		self.action = self:Add("DButton")
		self.action:Dock(BOTTOM)
		self.action:SetTall(32)
		self.action:SetFont("nutMediumFont")
		self.action:SetExpensiveShadow(1, Color(0, 0, 0, 150))

		self.itemPanels = {}
	end

	function PANEL:addItem(uniqueID, count, isBuying)
		local itemTable = nut.item.list[uniqueID]

		if (!itemTable) then
			return
		end

		local oldPanel = self.itemPanels[uniqueID]

		if (IsValid(oldPanel)) then
			count = count or (oldPanel.count + 1)

			oldPanel.count = count
			oldPanel.name:SetText(itemTable.name..(count and " ("..count..")" or ""))

			return oldPanel
		elseif (isBuying) then
			count = count or 1
		end

		local color_dark = Color(0, 0, 0, 80)

		local panel = self.items:Add("DPanel")
		panel:SetTall(36)
		panel:Dock(TOP)
		panel:DockMargin(5, 5, 5, 0)
		panel.Paint = function(this, w, h)
			surface.SetDrawColor(nut.gui.vendor.activeItem == this and nut.config.get("color") or color_dark)
			surface.DrawRect(0, 0, w, h)
		end
		panel.uniqueID = itemTable.uniqueID
		panel.count = count

		panel.icon = panel:Add("SpawnIcon")
		panel.icon:SetPos(2, 2)
		panel.icon:SetSize(32, 32)
		panel.icon:SetModel(itemTable.model, itemTable.skin)

		panel.name = panel:Add("DLabel")
		panel.name:DockMargin(40, 2, 2, 2)
		panel.name:Dock(FILL)
		panel.name:SetFont("nutChatFont")
		panel.name:SetTextColor(color_white)
		panel.name:SetText(itemTable.name..(count and " ("..count..")" or ""))
		panel.name:SetExpensiveShadow(1, Color(0, 0, 0, 150))

		panel.overlay = panel:Add("DButton")
		panel.overlay:SetPos(0, 0)
		panel.overlay:SetSize(ScrW() * 0.25, 36)
		panel.overlay:SetText("")
		panel.overlay.Paint = function() end
		panel.overlay.DoClick = function(this)
			nut.gui.vendor.activeItem = panel
		end

		local items = nut.gui.vendor.items
		local price = items[uniqueID] and items[uniqueID][1] or itemTable.price or 0
		local price2 = math.Round(price * 0.5)

		panel.overlay:SetToolTip(L("itemPriceInfo", nut.currency.get(price), nut.currency.get(price2)))
		self.itemPanels[uniqueID] = panel

		return panel
	end
vgui.Register("nutVendorItemList", PANEL, "DPanel")

PANEL = {}
	function PANEL:Init()
		if (IsValid(nut.gui.vendorAdmin)) then
			nut.gui.vendorAdmin:Remove()
		end

		nut.gui.vendorAdmin = self

		self:SetTitle(L"vendorSettings")
		self:SetSize(ScrW() * 0.25, ScrH() * 0.5)
		self:MakePopup()
		self:CenterVertical()

		self.name = self:Add("DTextEntry")
		self.name:Dock(TOP)

		self.desc = self:Add("DTextEntry")
		self.desc:Dock(TOP)
		self.desc:DockMargin(0, 3, 0, 3)

		self.model = self:Add("DTextEntry")
		self.model:Dock(TOP)
		self.model:DockMargin(0, 0, 0, 3)

		self.moneyBox = self:Add("DPanel")
		self.moneyBox:Dock(TOP)
		self.moneyBox:DockMargin(0, 0, 0, 3)

		self.money = self.moneyBox:Add("DNumberWang")
		self.money:Dock(RIGHT)
		self.money:SetWide(self:GetWide() * 0.6 - 4)
		self.money:DockMargin(3, 3, 3, 3)

		self.useMoney = self.moneyBox:Add("DCheckBoxLabel")
		self.useMoney:Dock(LEFT)
		self.useMoney:SetText(L"vendorUseMoney")
		self.useMoney:SetWide(self:GetWide() * 0.4 - 4)
		self.useMoney:DockMargin(4, 4, 4, 4)

		self.noBubble = self:Add("DCheckBoxLabel")
		self.noBubble:Dock(TOP)
		self.noBubble:DockMargin(3, 0, 3, 3)
		self.noBubble:SetText(L"vendorNoBubble")

		self.items = self:Add("DListView")
		self.items:Dock(FILL)
		self.items:AddColumn(L"name").Header:SetTextColor(color_black)
		self.items:AddColumn(L"mode").Header:SetTextColor(color_black)
		self.items:AddColumn(L"price").Header:SetTextColor(color_black)
		self.items:AddColumn(L"stock").Header:SetTextColor(color_black)
		self.items:SetMultiSelect(false)

		if (IsValid(nut.gui.vendor)) then
			nut.gui.vendor:SetPos(nut.gui.vendor.x + self:GetWide()*0.5, nut.gui.vendor.y)
			self:MoveLeftOf(nut.gui.vendor, 5)
		end

		self.factions = self:Add("DButton")
		self.factions:Dock(BOTTOM)
		self.factions:DockMargin(0, 5, 0, 0)
		self.factions:SetText(L"vendorFaction")
	end

	local MODE_TEXT = {}
	MODE_TEXT[0] = "none"
	MODE_TEXT[VENDOR_BUY] = "vendorBuy"
	MODE_TEXT[VENDOR_SELL] = "vendorSell"
	MODE_TEXT[VENDOR_BOTH] = "vendorBoth"

	function PANEL:setData(entity, items, money, stock, adminData)
		local lastName, lastDesc

		if (money) then
			self.money:SetMinMax(0, 1000000000)
			self.money:SetValue(money)
			self.useMoney:SetChecked(1)
		end

		self.money.OnValueChanged = function(this, value)
			if (this.noSend) then
				this.noSend = nil

				return
			end

			value = math.max(value, 0)

			if (money != value) then
				netstream.Start("vendorEdit", entity, "money", value)
				money = value
			end
		end

		self.useMoney.OnChange = function(this, state)
			if (state) then
				netstream.Start("vendorEdit", entity, "money", math.max(tonumber(self.money:GetValue()) or 0, 0))
			else
				netstream.Start("vendorEdit", entity, "money")
			end
		end

		self.model:SetText(entity:GetModel())
		self.model.OnEnter = function(this)
			netstream.Start("vendorMdl", this:GetValue())
		end

		self.noBubble:SetValue(entity:getNetVar("noBubble") and 1 or 0)
		self.noBubble.OnChange = function(this, state)
			netstream.Start("vendorBbl", state)
		end

		self.name:SetText(entity:getNetVar("name"))
		self.name.Think = function(this)
			local curName = entity:getNetVar("name")

			if (lastName != curName) then
				self.name:SetText(curName)
				lastName = curName
			end
		end
		self.name.OnEnter = function(this)
			netstream.Start("vendorEdit", entity, "name", this:GetText())
		end

		self.desc:SetText(entity:getNetVar("desc", ""))
		self.desc.Think = function(this)
			local curDesc = entity:getNetVar("desc")

			if (lastDesc != curDesc) then
				self.desc:SetText(curDesc)
				lastDesc = curDesc
			end
		end
		self.desc.OnEnter = function(this)
			netstream.Start("vendorEdit", entity, "desc", this:GetText())
		end

		for k, v in SortedPairsByMemberValue(nut.item.list, "name") do
			local name = v.name
			local mode = items[k] and items[k][2] or 0
			local price = items[k] and items[k][1] or v.price or 0
			local curStock = stock and stock[k] and stock[k][1]
			local maxStock = curStock and stock[k][2]

			self.items:AddLine(v.name, L(MODE_TEXT[mode]), price, maxStock and (curStock.."/"..maxStock) or "∞").item = {
				name = name,
				mode = mode,
				price = price,
				curStock = curStock,
				maxStock = maxStock,
				uniqueID = k
			}
		end

		self.items.OnClickLine = function(this, line, selected)
			if (IsValid(self.menu)) then
				self.menu:Remove()
			end

			local itemData = {}
			local loaded = false

			local menu = self:Add("DFrame")
			menu:SetTitle(line.item.name)
			menu:SetSize(240, 180)
			menu:MakePopup()
			menu:SetPos(gui.MousePos())
			menu.uniqueID = line.item.uniqueID

			local settings = menu:Add("DProperties")
			settings:Dock(FILL)
			
			local price = settings:CreateRow(L"properties", L"price")
			price:Setup("Int", {min = 0, max = 1000})
			price:SetValue(line.item.price)
			price.DataChanged = function(this, value)
				if (!loaded) then
					return
				end

				itemData.price = value
			end

			local maxStock = settings:CreateRow(L"properties", L"maxStock")
			maxStock:Setup("Int", {min = 0, max = 50})
			maxStock:SetValue(line.item.maxStock)
			maxStock.DataChanged = function(this, value)
				if (!loaded) then
					return
				end
				
				itemData.maxStock = value
			end

			local stock = settings:CreateRow(L"properties", L"stock")
			stock:Setup("Int", {min = 0, max = 50})
			stock:SetValue(line.item.curStock)
			stock.DataChanged = function(this, value)
				if (!loaded) then
					return
				end
				
				itemData.stock = math.Round(value)
			end

			local mode = settings:CreateRow(L"properties", L"mode")
			mode:Setup("Combo", {L"mode"})
			mode:AddChoice(L(MODE_TEXT[0]), 0)
			mode:AddChoice(L(MODE_TEXT[VENDOR_BUY]), VENDOR_BUY)
			mode:AddChoice(L(MODE_TEXT[VENDOR_SELL]), VENDOR_SELL)
			mode:AddChoice(L(MODE_TEXT[VENDOR_BOTH]), VENDOR_BOTH)
			mode.DataChanged = function(this, value)
				if (!loaded) then
					return
				end
				
				itemData.mode = value
			end

			local save = menu:Add("DButton")
			save:Dock(BOTTOM)
			save:DockMargin(0, 3, 0, 0)
			save:SetText(L"save")
			save.DoClick = function(this)
				if (!loaded) then
					return
				end
				
				netstream.Start("vendorItemMod", entity, line.item.uniqueID, itemData)
				menu:Remove()
			end

			timer.Simple(0, function()
				loaded = true
			end)

			self.menu = menu
		end

		self.factions.DoClick = function(this)
			local menu = vgui.Create("DFrame")
			menu:SetTitle(L"vendorFaction")
			menu:SetSize(360, 180)
			menu:MakePopup()
			menu:Center()

			local list = menu:Add("DScrollPanel")
			list:Dock(FILL)

			self.factionBoxes = {}
			self.classBoxes = {}

			for k, v in ipairs(nut.faction.indices) do
				local faction = list:Add("DCheckBoxLabel")
				faction:SetText(L(v.name))
				faction:SetBright(true)
				faction:Dock(TOP)
				faction:DockMargin(0, 0, 0, 4)
				faction.OnChange = function(this, state)
					netstream.Start("vendorFEdit", entity, k, state)
				end

				for k2, v2 in ipairs(nut.class.list) do
					if (v2.faction == k) then
						local class = list:Add("DCheckBoxLabel")
						class:SetText(L(v2.name))
						class:Dock(TOP)
						class:DockMargin(24, 0, 0, 2)
						class.OnChange = function(this, state)
							netstream.Start("vendorCEdit", entity, k, state)
						end

						if (adminData and adminData.class and adminData.class[k]) then
							class:SetChecked(true)
						end

						self.classBoxes[k2] = class
					end
				end
				
				if (adminData.faction and adminData.faction[k]) then
					faction:SetChecked(true)
				end

				self.factionBoxes[k] = faction
			end
		end
	end

	function PANEL:update(uniqueID, data)
		local vendor = nut.gui.vendor

		if (self.menu and self.menu.uniqueID == uniqueID) then
			self.menu:Remove()
		end

		for k, v in ipairs(self.items:GetLines()) do
			if (v.item.uniqueID == uniqueID) then
				if (data.mode) then
					v:SetColumnText(2, L(MODE_TEXT[data.mode]))
					v.item.mode = data.mode > 0 and data.mode or nil

					if (IsValid(vendor)) then
						vendor.items[uniqueID] = vendor.items[uniqueID] or {}
						vendor.items[uniqueID][2] = v.item.mode
					end
				end

				if (data.maxStock or data.stock) then
					if (data.maxStock) then
						if (data.maxStock < 1) then
							data.maxStock = nil
						end

						v.item.maxStock = data.maxStock
					end

					if (data.stock) then
						v.item.curStock = data.stock
					end

					if (IsValid(vendor)) then
						vendor.stocks[uniqueID] = vendor.stocks[uniqueID] or {}

						if (v.item.curStock) then
							vendor.stocks[uniqueID][1] = v.item.curStock
						end

						if (v.item.maxStock) then
							vendor.stocks[uniqueID][2] = v.item.maxStock
						end
					end

					v:SetColumnText(4, v.item.maxStock and (v.item.curStock.."/"..v.item.maxStock) or "∞")
				end

				if (data.price) then
					v.item.price = data.price
					v:SetColumnText(3, data.price)
				end

				return
			end
		end
	end
vgui.Register("nutVendorAdmin", PANEL, "DFrame")