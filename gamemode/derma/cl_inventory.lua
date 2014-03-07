local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("inventory"))

		local p = self:Add( "nut_NoticePanel" )
		p:Dock( TOP )
		p:DockMargin( 0, 0, 0, 5 )
		p:SetType( 4 )
		p:SetText( nut.lang.Get("inv_tip") )
	
		self.weight = self:Add("DPanel")
		self.weight:Dock(TOP)
		self.weight:SetTall(18)
		self.weight:DockMargin(0, 0, 0, 4)
		self.weight.Paint = function(panel, w, h)
			local width = self.weightValue or 0
			local color = nut.config.mainColor

			surface.SetDrawColor(color.r, color.g, color.b, 200)
			surface.DrawRect(0, 0, w * width, h)

			surface.SetDrawColor(255, 255, 255, 20)
			surface.DrawRect(0, 0, w * width, h * 0.4)

			surface.SetDrawColor(255, 255, 255, 30)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local weight, maxWeight = LocalPlayer():GetInvWeight()
		self.weightValue = weight / maxWeight

		self.weightText = self.weight:Add("DLabel")
		self.weightText:Dock(FILL)
		self.weightText:SetExpensiveShadow(1, color_black)
		self.weightText:SetTextColor(color_white)
		self.weightText:SetContentAlignment(5)
		self.weightText:SetText(math.ceil(self.weightValue * 100).."%")

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.categories = {}

		for class, items in pairs(LocalPlayer():GetInventory()) do
			local itemTable = nut.item.Get(class)

			if (itemTable and table.Count(items) > 0) then
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

				for k, v in SortedPairs(items) do
					local icon = list:Add("SpawnIcon")
					icon:SetModel(itemTable.model or "models/error.mdl", itemTable.skin)

					if (itemTable.bodygroup) then
						for k, v in pairs(itemTable.bodygroup) do
							icon:SetBodyGroup( k, v )
						end
					end

					icon.PaintOver = function(icon, w, h)
						surface.SetDrawColor(0, 0, 0, 45)
						surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

						if (itemTable.PaintIcon) then
							itemTable.data = v.data
								itemTable:PaintIcon(w, h)
							itemTable.data = nil
						end
					end
					
					local label = icon:Add("DLabel")
					label:SetPos(8, 3)
					label:SetWide(64)
					label:SetText(v.quantity)
					label:SetFont("DermaDefaultBold")
					label:SetDark(true)
					label:SetExpensiveShadow(1, Color(240, 240, 240))

					icon:SetToolTip(nut.lang.Get("item_info", itemTable.name, itemTable:GetDesc(v.data)))
					icon.DoClick = function(icon)
						nut.item.OpenMenu(itemTable, v, k, icon, label)
					end
				end
			elseif (table.Count(items) == 0) then
				LocalPlayer():GetInventory()[class] = nil
			end
		end
	end

	nut.char.HookVar("inv", "refreshInv", function(character)
		if (IsValid(nut.gui.inv)) then
			nut.gui.inv:Reload()
		end
	end)

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end

	function PANEL:Reload()
		local parent = self:GetParent()

		self:Remove()

		nut.gui.inv = vgui.Create("nut_Inventory", parent)
		nut.gui.menu:SetCurrentMenu(nut.gui.inv, true)
	end
vgui.Register("nut_Inventory", PANEL, "DFrame")