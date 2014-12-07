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
		self:SetSize(320, 480)
		self:SetTitle(L"shipment")
		self:Center()
		self:MakePopup()

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
	end

	function PANEL:setItems(entity, items)
		self.entity = entity
		self.items = items

		for k, v in SortedPairs(items) do
			local item = self.list:Add("DPanel")
			item:SetTall(36)
			item:Dock(TOP)
			item:DockMargin(4, 4, 4, 0)
		end
	end

	function PANEL:Think()
		if (self.items and !IsValid(self.entity)) then
			self:Remove()
		end
	end
vgui.Register("nutShipment", PANEL, "DFrame")