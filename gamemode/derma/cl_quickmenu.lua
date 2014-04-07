local PANEL = {}
local width = 64*5+10
local margin = 75

function PANEL:Init()
	--self:ParentToHUD()
	self:SetSize(width, 10)
	self:SetDrawBackground(false)

	hook.Run("CreateQuickMenu", self)
end

function PANEL:PerformLayout()
	--self:SetPos(margin, ScrH() - margin - self:GetTall())
	local tall = ScrH() - margin - self:GetTall()
	self:SetPos(margin, tall)
	local x, y = self:ChildrenSize()
	self:SetTall(y)
end

local gradient = surface.GetTextureID("vgui/gradient-r")

vgui.Register("nut_QuickMenu", PANEL, "DPanel")	

function GM:CreateQuickMenu(panel)
	/*
	PLACE HOLDER. DONT TRY TO USE THIS CODE
	local label = panel:Add("DLabel")
	label:Dock(TOP)
	label:SetText(" Item Quickslot")
	label:SetFont("nut_TargetFont")
	label:SetTextColor(Color(233, 233, 233))
	label:SizeToContents()
	label:SetExpensiveShadow(2, Color(0, 0, 0))
	local category = panel:Add("DPanel")
	category:Dock(TOP)
	category:DockPadding(5, 5, 5, 5)
	category:DockMargin(0, 5, 0, 5)
	category:SetTall(64+10)
	panel.quickitem = category:Add("DIconLayout")
	panel.quickitem:Dock(FILL)

	for class, items in pairs(LocalPlayer():GetInventory()) do
		local itemTable = nut.item.Get(class)

		if (itemTable and table.Count(items) > 0) then
			for k, v in SortedPairs(items) do
				local icon = panel.quickitem:Add("SpawnIcon")
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

				icon:SetToolTip(nut.lang.Get("item_info", itemTable.name, itemTable:GetDesc(v.data)))
				icon.DoClick = function(icon)
					nut.item.OpenMenu(itemTable, v, k, icon, label)
				end
			end
		end
	end
	*/
end

hook.Add("OnContextMenuOpen", "nut_QuickMenu", function()
	nut.gui.quickmenu = vgui.Create("nut_QuickMenu")
	nut.gui.quickmenu:MakePopup()
	gui.EnableScreenClicker(true)
end)

hook.Add("OnContextMenuClose", "nut_QuickMenu", function()
	if (nut.gui.quickmenu) then
		nut.gui.quickmenu:Remove()
	end
	gui.EnableScreenClicker(false)
end)