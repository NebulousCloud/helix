local PANEL = {}
	function PANEL:Init()
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle("Vendor")
		self:Center()

		self.property = self:Add("DPropertySheet")
		self.property:Dock(FILL)

		self.menu = vgui.Create("nut_VendorMenu")

		self.menuTab = self.property:AddSheet("Vendor", self.menu, "icon16/application_view_tile.png")

		if (LocalPlayer():IsAdmin()) then
			self.admin = vgui.Create("nut_VendorAdminMenu")
			self.property:AddSheet("Admin", self.admin, "icon16/star.png")
		end
	end

	function PANEL:SetEntity(entity)
		if (IsValid(self.admin)) then
			self.admin:SetEntity(entity)
		end
		
		self.menu:SetEntity(entity)
	end
vgui.Register("nut_Vendor", PANEL, "DFrame")

local PANEL = {}
	function PANEL:Init()
		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.categories = {}
		self.nextBuy = 0
	end

	function PANEL:SetEntity(entity)
		self.entity = entity

		local data = entity:GetNetVar("data", {})

		for class, itemTable in SortedPairs(nut.item.GetAll()) do
			local factionData = entity:GetNetVar("factiondata", {})

			if (!factionData[LocalPlayer():Team()]) then
				continue
			end

			local classData = entity:GetNetVar("classdata", {})

			if (table.Count(classData) > 0 and LocalPlayer():CharClass() and !classData[LocalPlayer():CharClass()]) then
				continue
			end

			if (data[class] and data[class].selling) then
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

	function PANEL:Reload()
		if (IsValid(self.entity)) then
			self:Clear(true)
			self:Init()
			self:SetEntity(self.entity)
		end
	end
vgui.Register("nut_VendorMenu", PANEL, "DPanel")

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
		self.list:AddColumn("Price")
		self.list:SetMultiSelect(false)
		self.list.OnClickLine = function(panel, line, selected)
			if (input.IsMouseDown(MOUSE_LEFT)) then
				line.selling = !line.selling
				line:SetValue(3, line.selling and "✔" or "")
			end
		end
		self.list.OnRowRightClick = function(parent, index, line)
			Derma_StringRequest(line.itemTable.name, "What would you like the price to be?", "0", function(text)
				local amount = tonumber(text) or 0

				if (IsValid(line)) then
					line.price = math.max(math.floor(amount), 0)
					line:SetValue(4, line.price)
				end
			end)
		end

		for k, v in SortedPairsByMemberValue(nut.item.GetAll(), "name") do
			local line = self.list:AddLine(v.name, v.uniqueID, "")
			line.itemTable = v
			line.price = 0
			line:SetValue(4, line.price)

			if (data[v.uniqueID]) then
				if (data[v.uniqueID].price) then
					line.price = data[v.uniqueID].price
					line:SetValue(4, line.price)
				end

				if (data[v.uniqueID].selling) then
					line:SetValue(3, "✔")
					line.selling = true
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

					if (selling != true) then
						selling = nil
					else
						price = v.price

						if (price <= 0) then
							price = nil
						end
					end

					local value = {price = price, selling = selling}

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

				netstream.Start("nut_VendorData", {entity, data, factionData, classData, self.name:GetText(), self.desc:GetText(), self.model:GetText() or entity:GetModel()})

				timer.Simple(LocalPlayer():Ping() / 100, function()
					local parent = nut.gui.vendor

					if (IsValid(parent.menu)) then
						parent.menu:Reload()
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