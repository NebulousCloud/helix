local PANEL = {}

function PANEL:Init()
	-- being relative.
	local size = 120
	self:SetSize(size, size * 1.4)
end

function PANEL:setItem(itemTable)
	self.itemName = L(itemTable.name):lower()

	self.price = self:Add("DLabel")
	self.price:Dock(BOTTOM)
	self.price:SetText(itemTable.price and nut.currency.get(itemTable.price) or L"free":upper())
	self.price:SetContentAlignment(5)
	self.price:SetTextColor(color_white)
	self.price:SetFont("nutSmallFont")
	self.price:SetExpensiveShadow(1, Color(0, 0, 0, 200))

	self.name = self:Add("DLabel")
	self.name:Dock(TOP)
	self.name:SetText(L(itemTable.name))
	self.name:SetContentAlignment(5)
	self.name:SetTextColor(color_white)
	self.name:SetFont("nutSmallFont")
	self.name:SetExpensiveShadow(1, Color(0, 0, 0, 200))
	self.name.Paint = function(this, w, h)
		surface.SetDrawColor(0, 0, 0, 75)
		surface.DrawRect(0, 0, w, h)
	end

	self.icon = self:Add("SpawnIcon")
	self.icon:SetZPos(1)
	self.icon:SetSize(self:GetWide(), self:GetWide())
	self.icon:Dock(FILL)
	self.icon:DockMargin(5, 5, 5, 10)
	self.icon:InvalidateLayout(true)
	self.icon:SetModel(itemTable.model, itemTable.skin or 0)
	self.icon:SetToolTip(L(itemTable:getDesc()))
	self.icon.DoClick = function(this)
		if (!IsValid(nut.gui.checkout) and (this.nextClick or 0) < CurTime()) then
			local parent = nut.gui.business
			parent:buyItem(itemTable.uniqueID)

			surface.PlaySound("buttons/button14.wav")
			this.nextClick = CurTime() + 0.5
		end
	end
	self.icon.PaintOver = function(this, w, h)
		if (itemTable and itemTable.paintOver) then
			local w, h = this:GetSize()

			itemTable.paintOver(this, itemTable, w, h)
		end
	end

	if ((itemTable.iconCam and !renderdIcons[itemTable.uniqueID]) or itemTable.forceRender) then
		local iconCam = itemTable.iconCam
		iconCam = {
			cam_pos = iconCam.pos,
			cam_fov = iconCam.fov,
			cam_ang = iconCam.ang,
		}
		renderdIcons[itemTable.uniqueID] = true
		
		self.icon:RebuildSpawnIconEx(
			iconCam
		)
	end
end

vgui.Register("nutBusinessItem", PANEL, "DPanel")

PANEL = {}

function PANEL:Init()
	nut.gui.business = self

	self:SetSize(self:GetParent():GetSize())

	self.categories = self:Add("DScrollPanel")
	self.categories:Dock(LEFT)
	self.categories:SetWide(260)
	self.categories.Paint = function(this, w, h)
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h)
	end
	self.categories:DockPadding(5, 5, 5, 5)
	self.categories:DockMargin(0, 46, 0, 0)
	self.categoryPanels = {}

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)

	self.search = self:Add("DTextEntry")
	self.search:Dock(TOP)
	self.search:SetTall(36)
	self.search:SetFont("nutMediumFont")
	self.search:DockMargin(10 + self:GetWide() * 0.35, 0, 5, 5)
	self.search.OnTextChanged = function(this)
		local text = self.search:GetText():lower()

		self:loadItems(self.selected.category, text:find("%S") and text or nil)
		self.scroll:InvalidateLayout()
	end
	self.search.PaintOver = function(this, cw, ch)
		if (self.search:GetValue() == "" and !self.search:HasFocus()) then
			nut.util.drawText("V", 10, ch/2 - 1, color_black, 3, 1, "nutIconsSmall")
		end
	end

	self.itemList = self.scroll:Add("DIconLayout")
	self.itemList:Dock(FILL)
	self.itemList:DockMargin(10, 5, 5, 5)
	self.itemList:SetSpaceX(10)
	self.itemList:SetSpaceY(10)
	self.itemList:SetMinimumSize(128, 400)

	self.checkout = self:Add("DButton")
	self.checkout:Dock(BOTTOM)
	self.checkout:SetTextColor(color_white)
	self.checkout:SetTall(36)
	self.checkout:SetFont("nutMediumFont")
	self.checkout:DockMargin(10, 10, 0, 0)
	self.checkout:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	self.checkout:SetText(L("checkout", 0))
	self.checkout.DoClick = function()
		if (!IsValid(nut.gui.checkout) and self:getCartCount() > 0) then
			self:Add("nutBusinessCheckout"):setCart(self.cart)
		end
	end

	self.cart = {}

	local dark = Color(0, 0, 0, 50)
	local first = true

	for k, v in pairs(nut.item.list) do
		if (hook.Run("CanPlayerUseBusiness", LocalPlayer(), k) == false) then
			continue
		end

		if (!self.categoryPanels[L(v.category)]) then
			self.categoryPanels[L(v.category)] = v.category
		end
	end

	for category, realName in SortedPairs(self.categoryPanels) do
		local button = self.categories:Add("DButton")
		button:SetTall(36)
		button:SetText(category)
		button:Dock(TOP)
		button:SetTextColor(color_white)
		button:DockMargin(5, 5, 5, 0)
		button:SetFont("nutMediumFont")
		button:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		button.Paint = function(this, w, h)
			surface.SetDrawColor(self.selected == this and nut.config.get("color") or dark)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(0, 0, 0, 50)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		button.DoClick = function(this)
			if (self.selected != this) then
				self.selected = this
				self:loadItems(realName)
			end
		end
		button.category = realName

		if (first) then
			self.selected = button
			first = false
		end

		self.categoryPanels[realName] = button
	end

	if (self.selected) then
		self:loadItems(self.selected.category)
	end
end

function PANEL:getCartCount()
	local count = 0

	for k, v in pairs(self.cart) do
		count = count + v
	end

	return count
end

function PANEL:buyItem(uniqueID)
	self.cart[uniqueID] = (self.cart[uniqueID] or 0) + 1
	self.checkout:SetText(L("checkout", self:getCartCount()))
end

function PANEL:loadItems(category, search)
	category = category	or "misc"
	local items = nut.item.list

	self.itemList:Clear()
	self.itemList:InvalidateLayout(true)

	for uniqueID, itemTable in SortedPairsByMemberValue(items, "name") do
		if (hook.Run("CanPlayerUseBusiness", LocalPlayer(), uniqueID) == false) then
			continue
		end

		if (itemTable.category == category) then
			if (search and search != "" and !L(itemTable.name):lower():find(search, 1, true)) then
				continue
			end

			self.itemList:Add("nutBusinessItem"):setItem(itemTable)
		end
	end
end

function PANEL:setPage()
end

function PANEL:getPageItems()
end

vgui.Register("nutBusiness", PANEL, "EditablePanel")

PANEL = {}
	function PANEL:Init()
		if (IsValid(nut.gui.checkout)) then
			nut.gui.checkout:Remove()
		end

		nut.gui.checkout = self

		self:SetTitle("Checkout")
		self:SetSize(280, 400)
		self:MakePopup()
		self:Center()
		self:SetBackgroundBlur(true)

		self.items = self:Add("DScrollPanel")
		self.items:Dock(FILL)
		self.items.Paint = function(this, w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		self.items:DockMargin(0, 0, 0, 4)

		self.buy = self:Add("DButton")
		self.buy:Dock(BOTTOM)
		self.buy:SetText(L"purchase")
		self.buy:SetTextColor(color_white)
		self.buy.DoClick = function(this)
			if ((this.nextClick or 0) < CurTime()) then
				this.nextClick = CurTime() + 0.5
			else
				return
			end

			if (self.preventBuy) then
				self.finalGlow:SetText(self.final:GetText())
				self.finalGlow:SetAlpha(255)
				self.finalGlow:AlphaTo(0, 0.5)

				return surface.PlaySound("buttons/button11.wav")
			end

			netstream.Start("bizBuy", self.itemData)
			self.itemData = {}

			self.items:Remove()
			self.data:Remove()
			self.buy:Remove()
			self:ShowCloseButton(false)

			nut.gui.business.cart = {}
			nut.gui.business.checkout:SetText(L("checkout", 0))

			self.text = self:Add("DLabel")
			self.text:Dock(FILL)
			self.text:SetContentAlignment(5)
			self.text:SetTextColor(color_white)
			self.text:SetText(L"purchasing")
			self.text:SetFont("nutMediumFont")

			netstream.Hook("bizResp", function()
				if (IsValid(self)) then
					self.text:SetText(L"buyGood")
					self.done = true
					self:ShowCloseButton(true)

					surface.PlaySound("buttons/button3.wav")
				end
			end)

			timer.Simple(5, function()
				if (IsValid(self) and !self.done) then
					self.text:SetText(L"buyFailed")
					self:ShowCloseButton(true)

					surface.PlaySound("buttons/button11.wav")
				end
			end)
		end

		self.data = self:Add("DPanel")
		self.data:Dock(BOTTOM)
		self.data:SetTall(64)
		self.data:DockMargin(0, 0, 0, 4)

		self.current = self.data:Add("DLabel")
		self.current:SetFont("nutSmallFont")
		self.current:SetContentAlignment(6)
		self.current:SetTextColor(color_white)
		self.current:Dock(TOP)
		self.current:SetTextInset(4, 0)

		self.total = self.data:Add("DLabel")
		self.total:SetFont("nutSmallFont")
		self.total:SetContentAlignment(6)
		self.total:SetTextColor(color_white)
		self.total:Dock(TOP)
		self.total:SetTextInset(4, 0)

		local line = self.data:Add("DPanel")
		line:SetTall(1)
		line:DockMargin(128, 0, 4, 0)
		line:Dock(TOP)
		line.Paint = function(this, w, h)
			surface.SetDrawColor(255, 255, 255, 150)
			surface.DrawLine(0, 0, w, 0)
		end

		self.final = self.data:Add("DLabel")
		self.final:SetFont("nutSmallFont")
		self.final:SetContentAlignment(6)
		self.final:SetTextColor(color_white)
		self.final:Dock(TOP)
		self.final:SetTextInset(4, 0)

		self.finalGlow = self.final:Add("DLabel")
		self.finalGlow:Dock(FILL)
		self.finalGlow:SetFont("nutSmallFont")
		self.finalGlow:SetTextColor(color_white)
		self.finalGlow:SetContentAlignment(6)
		self.finalGlow:SetAlpha(0)
		self.finalGlow:SetTextInset(4, 0)


		self:SetFocusTopLevel(true)
		self.itemData = {}
		self:onQuantityChanged()
	end

	function PANEL:onQuantityChanged()
		local price = 0
		local money = LocalPlayer():getChar():getMoney()
		local valid = 0

		for k, v in pairs(self.itemData) do
			local itemTable = nut.item.list[k]

			if (itemTable and v > 0) then
				valid = valid + 1
				price = price + (v * (itemTable.price or 0))
			end
		end

		self.current:SetText("Your Money: "..nut.currency.get(money))
		self.total:SetText("- "..nut.currency.get(price))
		self.final:SetText("Money Left: "..nut.currency.get(money - price))
		self.final:SetTextColor((money - price) >= 0 and Color(46, 204, 113) or Color(217, 30, 24))

		self.preventBuy = (money - price) < 0 or valid == 0
	end

	function PANEL:setCart(items)
		self.itemData = items

		for k, v in SortedPairs(items) do
			local itemTable = nut.item.list[k]

			if (itemTable) then
				local slot = self.items:Add("DPanel")
				slot:SetTall(36)
				slot:Dock(TOP)
				slot:DockMargin(5, 5, 5, 0)

				slot.icon = slot:Add("SpawnIcon")
				slot.icon:SetPos(2, 2)
				slot.icon:SetSize(32, 32)
				slot.icon:SetModel(itemTable.model)
				slot.icon:SetToolTip(L(itemTable:getDesc()))

				slot.name = slot:Add("DLabel")
				slot.name:SetPos(40, 2)
				slot.name:SetSize(180, 32)
				slot.name:SetFont("nutChatFont")
				slot.name:SetText(L(itemTable.name).." ("..(itemTable.price and nut.currency.get(itemTable.price) or L"free":upper())..")")
				slot.name:SetTextColor(color_white)

				slot.quantity = slot:Add("DTextEntry")
				slot.quantity:SetSize(32, 32)
				slot.quantity:Dock(RIGHT)
				slot.quantity:DockMargin(4, 4, 4, 4)
				slot.quantity:SetContentAlignment(5)
				slot.quantity:SetNumeric(true)
				slot.quantity:SetText(v)
				slot.quantity:SetFont("nutChatFont")
				slot.quantity.OnTextChanged = function(this)
					local value = tonumber(this:GetValue())

					if (value) then
						items[k] = math.Clamp(math.Round(value), 0, 10)
						self:onQuantityChanged()
					else
						this:SetValue(1)
					end
				end
			else
				items[k] = nil
			end
		end

		self:onQuantityChanged()
	end

	function PANEL:Think()
		if (!self:HasFocus()) then
			self:MakePopup()
		end	
	end
vgui.Register("nutBusinessCheckout", PANEL, "DFrame")

hook.Add("CreateMenuButtons", "nutBusiness", function(tabs)
	tabs["business"] = function(panel)
		if (hook.Run("BuildBusinessMenu", panel) != false) then
			panel:Add("nutBusiness")
		end
	end
end)