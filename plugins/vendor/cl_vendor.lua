local PANEL = {}
	function PANEL:Init()
		local width = ScrW() * nut.config.menuWidth

		self:SetSize(width, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle("Vendor")
		self:Center()

		self.property = self:Add("DPropertySheet")
		self.property:Dock(FILL)

		self.property:AddSheet("Vendor", vgui.Create("nut_VendorMenu"), "icon16/application_view_tile.png")
		self.property:AddSheet("Admin", vgui.Create("nut_VendorAdminMenu"), "icon16/star.png")
	end
vgui.Register("nut_Vendor", PANEL, "DFrame")

local PANEL = {}
	function PANEL:Init()
		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.categories = {}
		self.nextBuy = 0

		for class, itemTable in SortedPairs(nut.item.GetAll()) do
			if (!itemTable.noBusiness and (!itemTable.ShouldShowOnBusiness or (itemTable.ShouldShowOnBusiness and itemTable:ShouldShowOnBusiness(LocalPlayer()) != false))) then
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
						local icon = list:Add("SpawnIcon")
						icon:SetModel(itemTable.model or "models/error.mdl")

						local cost = "Price: Free"

						if (itemTable.price and itemTable.price > 0) then
							cost = "Price: "..nut.currency.GetName(itemTable.price or 0)
						end

						icon:SetToolTip("Description: "..itemTable:GetDesc().."\n"..cost)
						icon.DoClick = function(panel)
							if (icon.disabled) then
								return
							end
							
							net.Start("nut_BuyItem")
								net.WriteString(class)
							net.SendToServer()

							icon.disabled = true
							icon:SetAlpha(70)

							timer.Simple(nut.config.buyDelay, function()
								if (IsValid(icon)) then
									icon.disabled = false
									icon:SetAlpha(255)
								end
							end)
						end
					category3:InvalidateLayout(true)

					self.categories[category2] = {category = category3, panel = panel}
				end
			end
		end
	end
vgui.Register("nut_VendorMenu", PANEL, "DPanel")

local PANEL = {}
	function PANEL:Init()
		self:SetDrawBackground(false)

		self.list = self:Add("DListView")
		self.list:Dock(FILL)
		self.list:AddColumn("Name")
		self.list:AddColumn("Unique ID")
		self.list:AddColumn("Selling")
		self.list:SetMultiSelect(false)
		self.list.OnClickLine = function(panel, line, selected)
			line:SetValue(3, "X")
		end

		for k, v in SortedPairs(nut.item.GetAll()) do
			self.list:AddLine(v.name, v.uniqueID, "")
		end

		self.save = self:Add("DButton")
		self.save:Dock(BOTTOM)
		self.save:DockMargin(0, 5, 0, 0)
		self.save:SetText("Save")
	end
vgui.Register("nut_VendorAdminMenu", PANEL, "DPanel")