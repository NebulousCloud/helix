-- VGUI needs to be re-done ;_;
local PANEL = {}
	function PANEL:Init()
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle("Vendor")
		self:Center()

		self.property = self:Add("DPropertySheet")
		self.property:Dock(FILL)

	end

	function PANEL:SetEntity(entity)
		
		self.vendorentity = entity
		local vendorAction = entity:GetNetVar("vendoraction", { sell = true, buy = false })
		if vendorAction.sell then
			self.selling = vgui.Create("nut_VendorMenu")
			self.selling:SetEntity(entity, false)
			self.sellingTab = self.property:AddSheet("Selling", self.selling, "icon16/coins_delete.png")
		end
		if vendorAction.buy then
			self.buying = vgui.Create("nut_VendorMenu")
			self.buying:SetEntity(entity, true)
			self.buyingTab = self.property:AddSheet("Buying", self.buying, "icon16/coins_add.png")
		end
		
		if (LocalPlayer():IsAdmin()) then
			self.admin = vgui.Create("nut_VendorAdminMenu")
			self.property:AddSheet("Admin", self.admin, "icon16/star.png")
		end
		if (IsValid(self.admin)) then
			self.admin:SetEntity(entity)
		end

	end
vgui.Register("nut_Vendor", PANEL, "DFrame")

-- PLEASE
netstream.Hook("nut_CashUpdate", function( data )
	local v = nut.gui.vendor
	if v then
		if v.buying then
			v.buying.money.desc:SetText( nut.lang.Get( "vendor_cash", nut.currency.GetName( v.vendorentity:GetNetVar("money", 0) ) ) )
		end
		if v.selling then
			v.selling.money.desc:SetText( nut.lang.Get( "vendor_cash", nut.currency.GetName( v.vendorentity:GetNetVar("money", 0) ) ) )
		end
	end
end)

-- VENDOR CONTENT
local PANEL = {}
	function PANEL:Init()
		self.money = self:Add("DPanel")
		self.money:Dock(TOP)
		self.money:DockMargin(0, 7, 2, 7)
		self.money:SetDrawBackground(false)
		
		self.money.desc = self.money:Add("DLabel")
		self.money.desc:DockMargin(16, 2, 2, 2)
		self.money.desc:Dock(TOP)
		self.money.desc:SetTextColor(Color(60, 60, 60))
		self.money.desc:SetFont("nut_TargetFont")
		self.money.desc:SizeToContents()
		self.money:Dock(TOP)
		
		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.categories = {}
		self.nextBuy = 0
	end
	
	function PANEL:SetEntity(entity, boolBuying)
		self.entity = entity

		local data = entity:GetNetVar("data", {})
		self.money.desc:SetText( nut.lang.Get( "vendor_cash", nut.currency.GetName( entity:GetNetVar("money", 0) ) ) )

		for class, itemTable in SortedPairs(nut.item.GetAll()) do
			local factionData = entity:GetNetVar("factiondata", {})

			if (!factionData[LocalPlayer():Team()]) then
				continue
			end

			local classData = entity:GetNetVar("classdata", {})

			if (table.Count(classData) > 0 and LocalPlayer():CharClass() and !classData[LocalPlayer():CharClass()]) then
				continue
			end

			--- SELLING STUFFS
			if (data[class] and data[class].selling and !boolBuying ) then
				local category = itemTable.category
				local category2 = string.lower(category)

				if (!self.categories[category2]) then
					local category3 = self.list:Add("DCollapsibleCategory")
					category3:Dock(TOP)
					category3:SetLabel(category)
					category3:DockMargin(5, 5, 5, 5)
					category3:SetPadding(5)

					local list = vgui.Create("DIconLayout")
						list.Paint = function(list, w, h)
							surface.SetDrawColor(0, 0, 0, 25)
							surface.DrawRect(0, 0, w, h)
						end
					category3:SetContents(list)
					category3:InvalidateLayout(true)

					self.categories[category2] = {list = list, category = category3, panel = panel}
				end

				local list = self.categories[category2].list
				local icon = list:Add("SpawnIcon")

				icon:SetModel(itemTable.model or "models/error.mdl", itemTable.skin)

				local price = itemTable.price or 0
				local cost = "Price: "..nut.currency.GetName(price)

				if (data[class] and data[class].price and data[class].price > 0) then
					price = data[class].price
				end

				if (price and price > 0) then
					cost = "Price: "..nut.currency.GetName(price)
				end

				icon:SetToolTip("Description: "..itemTable:GetDesc().."\n"..cost)
				icon.DoClick = function(panel)
					if (icon.disabled) then
						return
					end
					
					netstream.Start("nut_VendorBuy", {entity, class})
					timer.Simple(LocalPlayer():Ping() / 500, function()
						if self and self.money and self.money.desc then
							self.money.desc:SetText( nut.lang.Get( "vendor_cash", nut.currency.GetName( entity:GetNetVar("money", 0) ) ) )
						end
					end)


					icon.disabled = true
					icon:SetAlpha(70)

					timer.Simple(nut.config.buyDelay, function()
						if (IsValid(icon)) then
							icon.disabled = false
							icon:SetAlpha(255)
						end
					end)
				end
			end

			-- BUYING
			if (data[class] and data[class].buying and boolBuying) then
				local category = itemTable.category
				local category2 = string.lower(category)

				if (!self.categories[category2]) then
					local category3 = self.list:Add("DCollapsibleCategory")
					category3:Dock(TOP)
					category3:SetLabel(category)
					category3:DockMargin(5, 5, 5, 5)
					category3:SetPadding(5)

					local list = vgui.Create("DIconLayout")
						list.Paint = function(list, w, h)
							surface.SetDrawColor(0, 0, 0, 25)
							surface.DrawRect(0, 0, w, h)
						end
					category3:SetContents(list)
					category3:InvalidateLayout(true)

					self.categories[category2] = {list = list, category = category3, panel = panel}
				end

				local list = self.categories[category2].list
				local icon = list:Add("SpawnIcon")

				icon:SetModel(itemTable.model or "models/error.mdl", itemTable.skin)

				local price = itemTable.price or 0
				local cost = "Price: "..nut.currency.GetName(price)

				if (data[class] and data[class].price and data[class].price > 0) then
					price = data[class].price
				end

				if (price and price > 0) then
					cost = "Price: "..nut.currency.GetName(price)
				end

				icon:SetToolTip("Description: "..itemTable:GetDesc().."\n"..cost)
				icon.DoClick = function(panel)
					if (icon.disabled) then
						return
					end
					
					netstream.Start("nut_VendorSell", {entity, class})
					timer.Simple(LocalPlayer():Ping() / 500, function()
						if self and self.money and self.money.desc then
							self.money.desc:SetText( nut.lang.Get( "vendor_cash", nut.currency.GetName( entity:GetNetVar("money", 0) ) ) )
						end
					end)
					icon.disabled = true
					icon:SetAlpha(70)

					timer.Simple(nut.config.buyDelay, function()
						if (IsValid(icon)) then
							icon.disabled = false
							icon:SetAlpha(255)
						end
					end)
				end
			end

		end
	end

	function PANEL:Reload( boolBuying )
		if (IsValid(self.entity)) then
			self:Clear(true)
			self:Init()
			self:SetEntity(self.entity, boolBuying)
		end
	end
vgui.Register("nut_VendorMenu", PANEL, "DPanel")

-- ADMIN
local PANEL = {}
	function PANEL:Init()
		self:SetDrawBackground(false)

		self.info = self:Add("DLabel")
		self.info:Dock(TOP)
		self.info:DockMargin(3, 3, 3, 5)
		self.info:SetText("Left click to toggle selling. Right click to change the price.")
		self.info:SetTextColor(color_white)
		self.info:SizeToContents()

		self.scroll = self:Add("DScrollPanel")
		self.scroll:Dock(FILL)
		self.scroll:DockMargin(0, 5, 0, 0)
		self.scroll:SetPaintBackground(true)
	end

	function PANEL:SetEntity(entity)
		if (!IsValid(entity)) then
			return
		end

		local data = entity:GetNetVar("data", {})

		self.list = self:Add("DListView")
		self.list:Dock(TOP)
		self.list:SetTall(256)
		self.list:AddColumn("Name")
		self.list:AddColumn("Unique ID")
		self.list:AddColumn("Selling")
		self.list:AddColumn("Buying")
		self.list:AddColumn("Price")
		self.list:SetMultiSelect(false)
		self.list.OnClickLine = function(panel, line, selected)
			if (input.IsMouseDown(MOUSE_LEFT)) then
				local menu = DermaMenu()
				menu:AddOption( "Toggle Buying", function()
					line.buying = !line.buying
					line:SetValue(4, line.buying and "✔" or "")
				end):SetImage("icon16/money_add.png")
				menu:AddOption( "Toggle Selling", function()
					line.selling = !line.selling
					line:SetValue(3, line.selling and "✔" or "")
				end):SetImage("icon16/money_delete.png")
				menu:Open()
			end
			
			/* -- old code: Chessnut
			if (input.IsMouseDown(MOUSE_LEFT)) then
				line.selling = !line.selling
				line:SetValue(3, line.selling and "✔" or "")
			end
			*/
			
		end
		self.list.OnRowRightClick = function(parent, index, line)
			Derma_StringRequest(line.itemTable.name, "What would you like the price to be?", "0", function(text)
				local amount = tonumber(text) or 0

				if (IsValid(line)) then
					line.price = math.max(math.floor(amount), 0)
					line:SetValue(5, line.price)
				end
			end)
		end

		for k, v in SortedPairsByMemberValue(nut.item.GetAll(), "name") do
			local line = self.list:AddLine(v.name, v.uniqueID, "")
			line.itemTable = v
			line.price = 0
			line:SetValue(5, line.price)

			if (data[v.uniqueID]) then
				if (data[v.uniqueID].price) then
					line.price = data[v.uniqueID].price
					line:SetValue(5, line.price)
				end

				if (data[v.uniqueID].selling) then
					line:SetValue(3, "✔")
					line.selling = true
				end
				
				if (data[v.uniqueID].buying) then
					line:SetValue(4, "✔")
					line.buying = true
				end
				
			end
		end

		self.factions = {}

		local faction = self.scroll:Add("DLabel")
		faction:SetText("Factions")
		faction:DockMargin(3, 3, 3, 3)
		faction:Dock(TOP)
		faction:SetTextColor(Color(60, 60, 60))
		faction:SetFont("nut_ScoreTeamFont")
		faction:SizeToContents()

		local factionData = entity:GetNetVar("factiondata", {})

		for k, v in SortedPairs(nut.faction.GetAll()) do
			local panel = self.scroll:Add("DCheckBoxLabel")
			panel:Dock(TOP)
			panel:SetText("Sell to "..v.name..".")
			panel:SetValue(0)
			panel:DockMargin(12, 3, 3, 3)
			panel:SetDark(true)

			if (factionData[k]) then
				panel:SetChecked(factionData[k])
			end

			self.factions[k] = panel
		end

		local classes = self.scroll:Add("DLabel")
		classes:SetText("Classes")
		classes:DockMargin(3, 3, 3, 3)
		classes:Dock(TOP)
		classes:SetTextColor(Color(60, 60, 60))
		classes:SetFont("nut_ScoreTeamFont")
		classes:SizeToContents()

		self.classes = {}

		local classData = entity:GetNetVar("classdata", {})

		for k, v in SortedPairs(nut.class.GetAll()) do
			local panel = self.scroll:Add("DCheckBoxLabel")
			panel:Dock(TOP)
			panel:SetText("Sell to "..v.name..".")
			panel:SetValue(0)
			panel:DockMargin(12, 3, 3, 3)
			panel:SetDark(true)

			if (classData[k]) then
				panel:SetChecked(classData[k])
			end

			self.classes[k] = panel
		end

		local name = self.scroll:Add("DLabel")
		name:SetText("Name")
		name:DockMargin(3, 3, 3, 3)
		name:Dock(TOP)
		name:SetTextColor(Color(60, 60, 60))
		name:SetFont("nut_ScoreTeamFont")
		name:SizeToContents()

		self.name = self.scroll:Add("DTextEntry")
		self.name:Dock(TOP)
		self.name:DockMargin(3, 3, 3, 3)
		self.name:SetText(entity:GetNetVar("name", "John Doe"))
		
		-- Set sell only, buy only
		local action = self.scroll:Add("DLabel")
		action:SetText("Sell/Buy")
		action:DockMargin(3, 3, 3, 3)
		action:Dock(TOP)
		action:SetTextColor(Color(60, 60, 60))
		action:SetFont("nut_ScoreTeamFont")
		action:SizeToContents()
		
		local vendorAction = entity:GetNetVar("vendoraction", { sell = true, buy = false })
		
		self.sell = self.scroll:Add("DCheckBoxLabel")
		self.sell:Dock(TOP)
		self.sell:SetText( "Do Sell Item to player" )
		self.sell:SetValue(0)
		self.sell:DockMargin(12, 3, 3, 3)
		self.sell:SetDark(true)
		if ( vendorAction.sell ) then
			self.sell:SetChecked( vendorAction.sell )
		end
		
		self.buy = self.scroll:Add("DCheckBoxLabel")
		self.buy:Dock(TOP)
		self.buy:SetText( "Do Buy Item from player" )
		self.buy:SetValue(0)
		self.buy:DockMargin(12, 3, 3, 3)
		self.buy:SetDark(true)
		if ( vendorAction.buy ) then
			self.buy:SetChecked( vendorAction.buy )
		end
		
		
		-- Set vendor's money
		local adj = self.scroll:Add("DLabel")
		adj:SetText("Buying Money Adjustment")
		adj:DockMargin(3, 3, 3, 3)
		adj:Dock(TOP)
		adj:SetTextColor(Color(60, 60, 60))
		adj:SetFont("nut_ScoreTeamFont")
		adj:SizeToContents()
		
		self.adj = self.scroll:Add("DTextEntry")
		self.adj:Dock(TOP)
		self.adj:DockMargin(3, 3, 3, 3)
		self.adj:SetText(entity:GetNetVar("buyadjustment", .5))
		
		-- Set vendor's money
		local money = self.scroll:Add("DLabel")
		money:SetText("Vendor's Money")
		money:DockMargin(3, 3, 3, 3)
		money:Dock(TOP)
		money:SetTextColor(Color(60, 60, 60))
		money:SetFont("nut_ScoreTeamFont")
		money:SizeToContents()
		
		self.money = self.scroll:Add("DTextEntry")
		self.money:Dock(TOP)
		self.money:DockMargin(3, 3, 3, 3)
		self.money:SetText(entity:GetNetVar("money", 100))
		
		-- Description
		local desc = self.scroll:Add("DLabel")
		desc:SetText("Description")
		desc:DockMargin(3, 3, 3, 3)
		desc:Dock(TOP)
		desc:SetTextColor(Color(60, 60, 60))
		desc:SetFont("nut_ScoreTeamFont")
		desc:SizeToContents()

		self.desc = self.scroll:Add("DTextEntry")
		self.desc:Dock(TOP)
		self.desc:DockMargin(3, 3, 3, 3)
		self.desc:SetText(entity:GetNetVar("desc", nut.lang.Get("no_desc")))

		-- Model
		local model = self.scroll:Add("DLabel")
		model:SetText("Model")
		model:DockMargin(3, 3, 3, 3)
		model:Dock(TOP)
		model:SetTextColor(Color(60, 60, 60))
		model:SetFont("nut_ScoreTeamFont")
		model:SizeToContents()

		self.model = self.scroll:Add("DTextEntry")
		self.model:Dock(TOP)
		self.model:DockMargin(3, 3, 3, 3)
		self.model:SetText(entity:GetModel())

		-- Save
		self.save = self:Add("DButton")
		self.save:Dock(BOTTOM)
		self.save:DockMargin(0, 5, 0, 0)
		self.save:SetText("Save")
		self.save.DoClick = function()
			if (IsValid(entity) and (self.nextSend or 0) < CurTime()) then
				self.nextSend = CurTime() + 1

				local data = {}

				for k, v in pairs(self.list:GetLines()) do
					local price
					local selling = v.selling
					local buying = v.buying

					if (selling != true) then
						selling = nil
					elseif (buying != true) then
						buying = nil
					else
						price = v.price

						if (price <= 0) then
							price = nil
						end
					end

					local value = { price = price, selling = selling, buying = buying }

					if (table.Count(value) > 0) then
						data[v.itemTable.uniqueID] = value
					end
				end

				local factionData = {}

				for k, v in pairs(self.factions) do
					if (v:GetChecked()) then
						factionData[k] = true
					end
				end

				local classData = {}

				for k, v in pairs(self.classes) do
					if (v:GetChecked()) then
						classData[k] = true
					end
				end
				
				local vendorAction = {}
				vendorAction.buy = self.buy:GetChecked()
				vendorAction.sell = self.sell:GetChecked()
				
				local cashadjustment = self.adj:GetValue()
				local money = self.money:GetValue()
				-- need to add money
				netstream.Start("nut_VendorData", {entity, data, vendorAction, cashadjustment, money, factionData, classData, self.name:GetText(), self.desc:GetText(), self.model:GetText() or entity:GetModel()})

				timer.Simple(LocalPlayer():Ping() / 50, function()
					local parent = nut.gui.vendor

					if (IsValid(parent.buying)) then
						parent.buying:Reload( true )
					end
					if (IsValid(parent.selling)) then
						parent.selling:Reload()
					end
				end)
			end
		end
	end
vgui.Register("nut_VendorAdminMenu", PANEL, "DPanel")

function PLUGIN:ShouldDrawTargetEntity(entity)
	if (string.lower(entity:GetClass()) == "nut_vendor") then
		return true
	end
end

function PLUGIN:DrawTargetID(entity, x, y, alpha)
	if (string.lower(entity:GetClass()) == "nut_vendor") then
		local mainColor = nut.config.mainColor
		local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)

		nut.util.DrawText(x, y, entity:GetNetVar("name", "John Doe"), color)
			y = y + nut.config.targetTall
		nut.util.DrawText(x, y, entity:GetNetVar("desc", nut.lang.Get("no_desc")), Color(255, 255, 255, alpha), "nut_TargetFontSmall")
	end
end