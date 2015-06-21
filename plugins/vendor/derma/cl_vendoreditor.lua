local PANEL = {}
	function PANEL:Init()
		local entity = nut.gui.vendor.entity

		self:SetSize(320, 480)
		self:MoveLeftOf(nut.gui.vendor, 8)
		self:MakePopup()
		self:CenterVertical()
		self:SetTitle(L"vendorEditor")

		self.name = self:Add("DTextEntry")
		self.name:Dock(TOP)
		self.name:SetText(entity:getNetVar("name", "John Doe"))
		self.name.OnEnter = function(this)
			if (entity:getNetVar("name") != this:GetText()) then
				self:updateVendor("name", this:GetText())
			end
		end

		self.desc = self:Add("DTextEntry")
		self.desc:Dock(TOP)
		self.desc:DockMargin(0, 4, 0, 0)
		self.desc:SetText(entity:getNetVar("desc", ""))
		self.desc.OnEnter = function(this)
			if (entity:getNetVar("desc") != this:GetText()) then
				self:updateVendor("desc", this:GetText())
			end
		end

		self.model = self:Add("DTextEntry")
		self.model:Dock(TOP)
		self.model:DockMargin(0, 4, 0, 0)
		self.model:SetText(entity:GetModel())
		self.model.OnEnter = function(this)
			if (entity:GetModel():lower() != this:GetText():lower()) then
				self:updateVendor("model", this:GetText():lower())
			end
		end

		local useMoney = tonumber(entity.money) != nil

		self.money = self:Add("DTextEntry")
		self.money:Dock(TOP)
		self.money:DockMargin(0, 4, 0, 0)
		self.money:SetText(!useMoney and "∞" or entity.money)
		self.money:SetDisabled(!useMoney)
		self.money:SetEnabled(useMoney)
		self.money:SetNumeric(true)
		self.money.OnEnter = function(this)
			local value = tonumber(this:GetText()) or entity.money

			if (value == entity.money) then
				return
			end

			self:updateVendor("money", value)
		end

		self.bubble = self:Add("DCheckBoxLabel")
		self.bubble:SetText(L"vendorNoBubble")
		self.bubble:Dock(TOP)
		self.bubble:DockMargin(0, 4, 0, 0)
		self.bubble:SetValue(entity:getNetVar("noBubble") and 1 or 0)
		self.bubble.OnChange = function(this, value)
			if (this.noSend) then
				this.noSend = nil
			else
				self:updateVendor("bubble", value)
			end
		end

		self.useMoney = self:Add("DCheckBoxLabel")
		self.useMoney:SetText(L"vendorUseMoney")
		self.useMoney:Dock(TOP)
		self.useMoney:DockMargin(0, 4, 0, 0)
		self.useMoney:SetChecked(useMoney)
		self.useMoney.OnChange = function(this, value)
			self:updateVendor("useMoney")
		end

		self.sellScale = self:Add("DNumSlider")
		self.sellScale:Dock(TOP)
		self.sellScale:DockMargin(0, 4, 0, 0)
		self.sellScale:SetText(L"vendorSellScale")
		self.sellScale.Label:SetTextColor(color_white)
		self.sellScale.TextArea:SetTextColor(color_white)
		self.sellScale:SetDecimals(1)
		self.sellScale.noSend = true
		self.sellScale:SetValue(entity.scale)
		self.sellScale.OnValueChanged = function(this, value)
			if (this.noSend) then
				this.noSend = nil
			else
				timer.Create("nutVendorScale", 1, 1, function()
					if (IsValid(self) and IsValid(self.sellScale)) then
						value = self.sellScale:GetValue()

						if (value != entity.scale) then
							self:updateVendor("scale", value)
						end
					end
				end)
			end
		end

		self.faction = self:Add("DButton")
		self.faction:SetText(L"vendorFaction")
		self.faction:Dock(TOP)
		self.faction:SetTextColor(color_white)
		self.faction:DockMargin(0, 4, 0, 0)
		self.faction.DoClick = function(this)
			if (IsValid(nut.gui.editorFaction)) then
				nut.gui.editorFaction:Remove()
			end

			nut.gui.editorFaction = vgui.Create("nutVendorFactionEditor")
			nut.gui.editorFaction.updateVendor = self.updateVendor
			nut.gui.editorFaction.entity = entity
			nut.gui.editorFaction:setup()
		end

		local menu

		self.items = self:Add("DListView")
		self.items:Dock(FILL)
		self.items:DockMargin(0, 4, 0, 0)
		self.items:AddColumn(L"name").Header:SetTextColor(color_black)	
		self.items:AddColumn(L"mode").Header:SetTextColor(color_black)
		self.items:AddColumn(L"price").Header:SetTextColor(color_black)
		self.items:AddColumn(L"stock").Header:SetTextColor(color_black)
		self.items:SetMultiSelect(false)
		self.items.OnRowRightClick = function(this, index, line)
			if (IsValid(menu)) then
				menu:Remove()
			end

			local uniqueID = line.item

			menu = DermaMenu()
				-- Modes of the item.
				local mode, panel = menu:AddSubMenu(L"mode")
				panel:SetImage("icon16/key.png")

				-- Disable buying/selling of the item.
				mode:AddOption(L"none", function()
					self:updateVendor("mode", {uniqueID, nil})
				end):SetImage("icon16/cog_error.png")

				-- Allow the vendor to sell and buy this item.
				mode:AddOption(L"vendorBoth", function()
					self:updateVendor("mode", {uniqueID, VENDOR_SELLANDBUY})
				end):SetImage("icon16/cog.png")

				-- Only allow the vendor to buy this item from players.
				mode:AddOption(L"vendorBuy", function()
					self:updateVendor("mode", {uniqueID, VENDOR_BUYONLY})
				end):SetImage("icon16/cog_delete.png")

				-- Only allow the vendor to sell this item to players.
				mode:AddOption(L"vendorSell", function()
					self:updateVendor("mode", {uniqueID, VENDOR_SELLONLY})
				end):SetImage("icon16/cog_add.png")

				local itemTable = nut.item.list[uniqueID]

				-- Set the price of the item.
				menu:AddOption(L"price", function()
					Derma_StringRequest(L(itemTable.name), L"vendorPriceReq", entity:getPrice(uniqueID), function(text)
						text = tonumber(text)

						if (text == itemTable.price) then
							text = nil
						end

						self:updateVendor("price", {uniqueID, text})
					end)
				end):SetImage("icon16/coins.png")

				-- Set the stock of the item or disable it.
				local stock, panel = menu:AddSubMenu(L"stock")
				panel:SetImage("icon16/table.png")

				-- Disable the use of stocks for this item.
				stock:AddOption(L"disable", function()
					self:updateVendor("stockDisable", uniqueID)
				end):SetImage("icon16/table_delete.png")

				-- Edit the maximum stock for this item.
				stock:AddOption(L"edit", function()
					local _, max = entity:getStock(uniqueID)

					Derma_StringRequest(L(itemTable.name), L"vendorStockReq", max or 1, function(text)
						self:updateVendor("stockMax", {uniqueID, text})
					end)
				end):SetImage("icon16/table_edit.png")

				-- Edit the current stock of this item.
				stock:AddOption(L"vendorEditCurStock", function()
					Derma_StringRequest(L(itemTable.name), L"vendorStockCurReq", entity:getStock(uniqueID) or 0, function(text)
						self:updateVendor("stock", {uniqueID, text})
					end)					
				end):SetImage("icon16/table_edit.png")
			menu:Open()
		end

		self.lines = {}

		for k, v in SortedPairs(nut.item.list) do
			local mode = entity.items[k] and entity.items[k][VENDOR_MODE]
			local current, max = entity:getStock(k)
			local panel = self.items:AddLine(L(v.name), mode and L(VENDOR_TEXT[mode]) or L"none", entity:getPrice(k), max and current.."/"..max or "-")

			panel.item = k
			self.lines[k] = panel
		end
	end

	function PANEL:OnRemove()
		if (IsValid(nut.gui.vendor)) then
			nut.gui.vendor:Remove()
		end

		if (IsValid(nut.gui.editorFaction)) then
			nut.gui.editorFaction:Remove()
		end
	end

	function PANEL:updateVendor(key, value)
		netstream.Start("vendorEdit", key, value)
	end
vgui.Register("nutVendorEditor", PANEL, "DFrame")