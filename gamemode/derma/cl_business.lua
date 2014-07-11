local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("business"))

		local noticePanel = self:Add( "nut_NoticePanel" )
		noticePanel:Dock( TOP )
		noticePanel:DockMargin( 0, 0, 0, 5 )
		noticePanel:SetType( 4 )
		noticePanel:SetText( nut.lang.Get("business_tip") )
		
		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.categories = {}
		self.nextBuy = 0

		local result = hook.Run("BusinessPrePopulateItems", self)

		if (result != false) then
			local categories = {}

			for k, v in pairs(nut.item.GetAll()) do
				categories[v.category] = categories[v.category] or {}
				table.insert(categories[v.category], v)
			end

			for _, items in SortedPairs(categories) do
				for _, itemTable in SortedPairsByMemberValue(items, "name") do
					local class = itemTable.uniqueID
					local allowed = true

					if (itemTable.faction) then
						if (type(itemTable.faction) == "number" and itemTable.faction != LocalPlayer():Team()) then
							allowed = false
						elseif (type(itemTable.faction) == "table" and !table.HasValue(itemTable.faction, LocalPlayer():Team())) then
							allowed = false
						end
					end

					if (allowed and hook.Run("ShouldItemDisplay", itemTable) != false and !itemTable.noBusiness and (!itemTable.ShouldShowOnBusiness or (itemTable.ShouldShowOnBusiness and itemTable:ShouldShowOnBusiness(LocalPlayer()) != false))) then
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
								icon:SetModel(itemTable.model or "models/error.mdl", itemTable.skin)

								local cost = "Price: Free"

								if (itemTable.price and itemTable.price > 0) then
									if (!nut.currency.IsSet()) then
										error("Item has price but no currency is set!")
									end
								
									cost = "Price: "..nut.currency.GetName(itemTable.price or 0)
								end

								icon:SetToolTip("Name: " .. itemTable.name .. "\nDescription: "..itemTable:GetDesc().."\n"..cost)
								icon.DoClick = function(panel)
									if (icon.disabled) then
										return
									end

									netstream.Start("nut_BuyItem", class)

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

							hook.Run("BusinessCategoryCreated", category3)

							self.categories[category2] = {list = list, category = category3, panel = panel}
						else
							local list = self.categories[category2].list
							local icon = list:Add("SpawnIcon")
							icon:SetModel(itemTable.model or "models/error.mdl", itemTable.skin)

							local cost = "Price: Free"

							if (itemTable.price and itemTable.price > 0) then
								if (!nut.currency.IsSet()) then
									error("Item has price but no currency is set!")
								end

								cost = "Price: "..nut.currency.GetName(itemTable.price or 0)
							end

							icon:SetToolTip("Name: " .. itemTable.name .. "\nDescription: "..itemTable:GetDesc().."\n"..cost)
							icon.DoClick = function(panel)
								if (icon.disabled) then
									return
								end
									
								netstream.Start("nut_BuyItem", class)

								icon.disabled = true
								icon:SetAlpha(70)

								timer.Simple(nut.config.buyDelay, function()
									if (IsValid(icon)) then
										icon.disabled = false
										icon:SetAlpha(255)
									end
								end)
							end

							hook.Run("BusinessItemCreated", itemTable, icon)			
						end
					end
				end
			end
		end

		hook.Run("BusinessPostPopulateItems", self)
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end
vgui.Register("nut_Business", PANEL, "DFrame")