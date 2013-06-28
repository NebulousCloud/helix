local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("inventory"))

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
		self.weightText:SetText(math.floor(self.weightValue * 100).."%")

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.categories = {}

		for class, items in pairs(LocalPlayer():GetInventory()) do
			local itemTable = nut.item.Get(class)

			if (itemTable) then
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

					for k, v in SortedPairs(items) do
						local icon = list:Add("SpawnIcon")
						icon:SetModel(itemTable.model or "models/error.mdl")

						local label = icon:Add("DLabel")
						label:SetPos(8, 3)
						label:SetWide(64)
						label:SetText(v.quantity)
						label:SetFont("DermaDefaultBold")
						label:SetDark(true)
						label:SetExpensiveShadow(1, Color(240, 240, 240))

						local tip = nut.lang.Get("item_info", itemTable.name, itemTable:GetDesc(v.data))

						if (v.data) then
							for k, v in pairs(v.data) do
								tip = tip.."\n  "..k..": "..v
							end
						else
							tip = tip..nut.lang.Get("none")
						end

						icon:SetToolTip(tip)
						icon.DoClick = function(icon)
							nut.item.OpenMenu(itemTable, v, k, icon, label)
						end
					end

					category3:InvalidateLayout(true)

					self.categories[category2] = {category = category3, panel = panel}
				end
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
	end
vgui.Register("nut_Inventory", PANEL, "DFrame")