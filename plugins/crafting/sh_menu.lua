if SERVER then return end
local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("crafting"))

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.categories = {}
		self.nextBuy = 0

		nut.schema.Call("CraftingPrePopulateItems", self)

		for class, itemTable in SortedPairs( RECIPES:GetAll() ) do
			if
				-- acquired recipie book || learned the recipe ( planned )
				-- is it blueprint? ( planned )
				( true )
			then
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
						icon:SetModel( itemTable.model or "models/props_lab/box01a.mdl" )
						
						local text = nut.lang.Get("crft_text", itemTable.name, itemTable.desc)
						local cnt = 0
						local brk = "\n"
						for itc, qua in pairs( itemTable.items ) do
							cnt = cnt + 1
							if ( cnt == table.Count( itemTable.items ) ) then brk = "" end
							local tblItem = nut.item.Get( itc )
							if tblItem then
								text = text .. tblItem.name .. " x ".. qua .. brk
							end
						end
						icon:SetToolTip(text) -- should be fixed.
						
						icon.DoClick = function(panel)
							if (icon.disabled) then
								return
							end
							net.Start("nut_CraftItem")
								net.WriteString( class )
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
					nut.schema.Call("CraftingCategoryCreated", category3)
					self.categories[category2] = {list = list, category = category3, panel = panel}
					
				else
				
					local list = self.categories[category2].list
					local icon = list:Add("SpawnIcon")
					icon:SetModel( itemTable.model or "models/props_lab/box01a.mdl" )
						
					local text = nut.lang.Get("crft_text", itemTable.name, itemTable.desc)
					local cnt = 0
					local brk = "\n"
					for itc, qua in pairs( itemTable.items ) do
						cnt = cnt + 1
						if ( cnt == table.Count( itemTable.items ) ) then brk = "" end
						local tblItem = nut.item.Get( itc )
						if tblItem then
							text = text .. tblItem.name .. " x ".. qua .. brk
						end
					end
					icon:SetToolTip(text) -- should be fixed.
						
					icon.DoClick = function(panel)
						if (icon.disabled) then
							return
						end
						net.Start("nut_CraftItem")
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

					nut.schema.Call("CraftingItemCreated", itemTable, icon)			
				end
				
			end
		end

		nut.schema.Call("CraftingPostPopulateItems", self)
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end
vgui.Register("nut_Crafting", PANEL, "DFrame")

function PLUGIN:CreateMenuButtons(menu, addButton)
	if self.enabled then
		addButton("crafting", nut.lang.Get("crafting"), function()
			nut.gui.crafting = vgui.Create("nut_Crafting", menu)
			menu:SetCurrentMenu(nut.gui.crafting)
		end)
	end
end