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
	self.what = self:Add("DPanel")
	self.what:Dock(BOTTOM)
	self.what:SetTall(self:GetWide() * .4)
	self.what.text = itemTable.name
	self.what.Paint = function(this, w, h)
		draw.SimpleText(self.what.price and nut.currency.get(self.what.price) or "FREE", "ChatFont", w/2, h/2, color_white, 1, 1)
	end

	self.icon = self:Add("SpawnIcon")
	self.icon:SetZPos(1)
	self.icon:SetSize(self:GetWide(), self:GetWide())
	self.icon:Dock(FILL)
	self.icon:DockMargin(5, 5, 5, 5)
	self.icon:InvalidateLayout(true)
	self.icon:SetModel(itemTable.model)
	self.icon.DoClick = function(this)
		netstream.Start("businessBuy", itemTable.uniqueID)
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
	self.itemList = self:Add("DIconLayout")
	self.itemList:Dock(FILL)
	self.itemList:DockMargin(5, 5, 5, 5)
	self.itemList:SetSpaceX(10)
	self.itemList:SetSpaceY(10)

	self:loadItems()
end

function PANEL:loadItems()
	local items = nut.item.list

	for uniqueID, itemTable in pairs(items) do
		local itemPanel = self.itemList:Add("nutBusinessItem")
		itemPanel:setItem(itemTable)
	end	
end

function PANEL:setPage()
end

function PANEL:getPageItems()
end

vgui.Register("nutBusiness", PANEL, "DScrollPanel")

hook.Add("CreateMenuButtons", "nutBusiness", function(tabs)
	tabs["business"] = function(panel)
		local bPanel = panel:Add("nutBusiness")
		bPanel:SetSize(panel:GetSize())
		bPanel.itemList:Dock(FILL)
	end
end)