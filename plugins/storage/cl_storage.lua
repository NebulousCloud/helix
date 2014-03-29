local PANEL = {}
	function PANEL:Init()
		local width = ScrW() * nut.config.menuWidth

		self:SetSize(width, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("inventory"))
		self:Center()

		self.list = self:Add("DScrollPanel")
		self.list:Dock(LEFT)
		self.list:SetWide(width / 2 - 7)
		self.list:SetDrawBackground(true)

		self.storageTitle = self.list:Add("DLabel")
		self.storageTitle:SetText("Storage")
		self.storageTitle:DockMargin(3, 3, 3, 3)
		self.storageTitle:Dock(TOP)
		self.storageTitle:SetTextColor(Color(60, 60, 60))
		self.storageTitle:SetFont("nut_ScoreTeamFont")
		self.storageTitle:SizeToContents()

		self.weight = self.list:Add("DPanel")
		self.weight:Dock(TOP)
		self.weight:SetTall(18)
		self.weight:DockMargin(3, 3, 3, 4)
		self.weight.Paint = function(panel, w, h)
			local target = 0

			if (IsValid(self.entity)) then
				target = self.entity:GetNetVar("weight", 0) / 100
			end

			panel.width = math.Approach(panel.width or 0, target, FrameTime() * 0.75)

			local color = nut.config.mainColor

			surface.SetDrawColor(color.r, color.g, color.b, 200)
			surface.DrawRect(0, 0, w * panel.width, h)

			surface.SetDrawColor(255, 255, 255, 20)
			surface.DrawRect(0, 0, w * panel.width, h * 0.4)

			surface.SetDrawColor(25, 25, 25, 170)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		self.inv = self:Add("DScrollPanel")
		self.inv:Dock(RIGHT)
		self.inv:SetWide(width / 2 - 7)
		self.inv:SetDrawBackground(true)

		self.invTitle = self.inv:Add("DLabel")
		self.invTitle:SetText(nut.lang.Get("inventory"))
		self.invTitle:DockMargin(3, 3, 3, 3)
		self.invTitle:Dock(TOP)
		self.invTitle:SetTextColor(Color(60, 60, 60))
		self.invTitle:SetFont("nut_ScoreTeamFont")
		self.invTitle:SizeToContents()

		self.weight2 = self.inv:Add("DPanel")
		self.weight2:Dock(TOP)
		self.weight2:SetTall(18)
		self.weight2:DockMargin(3, 3, 3, 4)
		self.weight2.Paint = function(panel, w, h)
			panel.width = math.Approach(panel.width or 0, self.weightValue2, FrameTime() * 0.75)
			local color = nut.config.mainColor

			surface.SetDrawColor(color.r, color.g, color.b, 200)
			surface.DrawRect(0, 0, w * panel.width, h)

			surface.SetDrawColor(255, 255, 255, 20)
			surface.DrawRect(0, 0, w * panel.width, h * 0.4)

			surface.SetDrawColor(25, 25, 25, 170)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local transfer

		self.money2 = self.inv:Add("DTextEntry")
		self.money2:DockMargin(3, 3, 3, 3)
		self.money2:Dock(TOP)
		self.money2:SetNumeric(true)
		self.money2:SetText(LocalPlayer():GetMoney())
		self.money2.OnEnter = function(panel)
			transfer:DoClick()
		end

		transfer = self.money2:Add("DButton")
		transfer:Dock(RIGHT)
		transfer:SetText("Transfer")
		transfer.DoClick = function(panel)
			local value = tonumber(self.money2:GetText()) or 0

			if (value and value <= LocalPlayer():GetMoney() and value > 0) then
				netstream.Start("nut_TransferMoney", {self.entity, math.abs(value)})
			else
				self.money2:SetText(LocalPlayer():GetMoney())
			end
		end

		self.categories = {}
		self.invCategories = {}
	end

	function PANEL:GetEntity()
		return self.entity
	end

	function PANEL:OnClose()
		netstream.Start("nut_ContainerClosed")
	end

	function PANEL:SetEntity(entity)
		self.entity = entity
		self:SetupInv()

		self:SetTitle(entity:GetNetVar("name", "Storage"))

		self.weightText = self.weight:Add("DLabel")
		self.weightText:Dock(FILL)
		self.weightText:SetDark(true)
		self.weightText:SetContentAlignment(5)
		self.weightText:SetText(entity:GetNetVar("weight", 0).."%")

		local transfer

		self.money = self.list:Add("DTextEntry")
		self.money:DockMargin(3, 3, 3, 3)
		self.money:Dock(TOP)
		self.money:SetNumeric(true)
		self.money:SetText(entity:GetNetVar("money", 0))
		self.money.OnEnter = function(panel)
			transfer:DoClick()
		end

		transfer = self.money:Add("DButton")
		transfer:Dock(RIGHT)
		transfer:SetText("Transfer")
		transfer.DoClick = function(panel)
			local value = tonumber(self.money:GetText()) or 0

			if (value and value <= entity:GetNetVar("money", 0) and value > 0) then
				netstream.Start("nut_TransferMoney", {entity, -math.abs(value)})
			else
				self.money:SetText(entity:GetNetVar("money", 0))
			end
		end

		for class, items in pairs(entity:GetNetVar("inv")) do
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
					category3:InvalidateLayout(true)

					self.categories[category2] = {list = list, category = category3, panel = panel}
				end

				local list = self.categories[category2].list

				for k, v in SortedPairs(items) do
					local icon = list:Add("SpawnIcon")
					icon:SetModel(itemTable.model or "models/error.mdl", itemTable.skin)
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
						netstream.Start("nut_StorageUpdate", {entity, class, -1, v.data or {}, self.entity.lock})
					end
				end
			end
		end
	end

	function PANEL:SetupInv()
		local weight, maxWeight = LocalPlayer():GetInvWeight()
		self.weightValue2 = weight / maxWeight

		self.weightText2 = self.weight2:Add("DLabel")
		self.weightText2:Dock(FILL)
		self.weightText2:SetDark(true)
		self.weightText2:SetContentAlignment(5)
		self.weightText2:SetText(math.ceil(self.weightValue2 * 100).."%")

		for class, items in pairs(LocalPlayer():GetInventory()) do
			local itemTable = nut.item.Get(class)

			if (itemTable) then
				local category = itemTable.category
				local category2 = string.lower(category)

				if (!self.invCategories[category2]) then
					local category3 = self.inv:Add("DCollapsibleCategory")
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

					self.invCategories[category2] = {list = list, category = category3, panel = panel}
				end

				local list = self.invCategories[category2].list

				for k, v in SortedPairs(items) do
					local icon = list:Add("SpawnIcon")
					icon:SetModel(itemTable.model or "models/error.mdl", itemTable.skin)
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
						if (itemTable.CanTransfer and itemTable:CanTransfer(LocalPlayer(), v.data) == false) then
							return false
						end
						netstream.Start("nut_StorageUpdate", {self.entity, class, 1, v.data or {}, self.entity.lock})
					end
				end
			end
		end
	end

	function PANEL:Reload()
		local parent = self:GetParent()
		local entity = self:GetEntity()
		local x, y = self:GetPos()
		local oldWidth = self.weight.width
		local oldWidth2 = self.weight2.width

		self:Remove()

		nut.gui.storage = vgui.Create("nut_Storage", parent)
		nut.gui.storage:SetPos(x, y)
		nut.gui.storage.weight.width = oldWidth
		nut.gui.storage.weight2.width = oldWidth2

		if (IsValid(entity)) then
			nut.gui.storage:SetEntity(entity)
		end
	end
vgui.Register("nut_Storage", PANEL, "DFrame")

function PLUGIN:ShouldDrawTargetEntity(entity)
	if (entity:GetClass() == "nut_container") then
		return true
	end
end

function PLUGIN:DrawTargetID(entity, x, y, alpha)
	if (entity:GetClass() == "nut_container") then
		local mainColor = nut.config.mainColor
		local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)

		nut.util.DrawText(x, y, entity:GetNetVar("name", "Storage"), color)
			y = y + nut.config.targetTall
		nut.util.DrawText(x, y, "Has "..entity:GetNetVar("weight", 0).."% of storage used.", Color(255, 255, 255, alpha), "nut_TargetFontSmall")

		if (entity:GetNetVar("locked", false)) then
			nut.util.DrawText(x, y + 16, nut.lang.Get( "lock_locked" ), Color(255, 30, 30, alpha), "nut_TargetFontSmall")
		end
	end
end