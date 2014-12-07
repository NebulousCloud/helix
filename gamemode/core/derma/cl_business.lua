--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

local PANEL = {}

function PANEL:Init()
	-- being relative.
	local size = 120
	self:SetSize(size, size * 1.4)
end

function PANEL:setItem(itemTable)
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
	self.icon:SetModel(itemTable.model)
	self.icon:SetToolTip(itemTable:getDesc())
	self.icon.DoClick = function(this)
		if ((this.nextClick or 0) < CurTime()) then
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

	self.categoryPanels = {}

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)

	self.itemList = self.scroll:Add("DIconLayout")
	self.itemList:Dock(FILL)
	self.itemList:DockMargin(10, 0, 5, 5)
	self.itemList:SetSpaceX(10)
	self.itemList:SetSpaceY(10)

	self.checkout = self:Add("DButton")
	self.checkout:Dock(BOTTOM)
	self.checkout:SetTextColor(color_white)
	self.checkout:SetTall(36)
	self.checkout:SetFont("nutMediumFont")
	self.checkout:DockMargin(10, 10, 0, 0)
	self.checkout:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	self.checkout:SetText(L("checkout", 0))

	self.cart = {}

	local dark = Color(0, 0, 0, 50)
	local first = true

	for k, v in pairs(nut.item.list) do
		if (!self.categoryPanels[L(v.category)]) then
			self.categoryPanels[L(v.category)] = v.category
		end
	end

	for category, realName in SortedPairs(self.categoryPanels) do
		local button = self.categories:Add("DButton")
		button:SetTall(36)
		button:SetText(category)
		button:Dock(TOP)
		button:DockMargin(5, 5, 5, 0)
		button:SetFont("nutMediumFont")
		button:SetTextColor(color_white)
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

	self:loadItems(self.selected.category)
end

function PANEL:buyItem(uniqueID)
	self.cart[uniqueID] = (self.cart[uniqueID] or 0) + 1

	local count = 0

	for k, v in pairs(self.cart) do
		count = count + v
	end

	self.checkout:SetText(L("checkout", count))
end

function PANEL:loadItems(category)
	category = category	or "misc"
	local items = nut.item.list

	self.itemList:Clear()

	for uniqueID, itemTable in SortedPairsByMemberValue(items, "name") do
		if (itemTable.category == category) then
			self.itemList:Add("nutBusinessItem"):setItem(itemTable)
		end
	end	
end

function PANEL:setPage()
end

function PANEL:getPageItems()
end

vgui.Register("nutBusiness", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "nutBusiness", function(tabs)
	tabs["business"] = function(panel)
		panel:Add("nutBusiness")
	end
end)