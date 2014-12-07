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

		/*
		self.public = self:Add("DCheckBoxLabel")
		self.public:SetText("Is Public?")
		self.public:SetValue(0)
		self.public:Dock(BOTTOM)
		self.public:DockMargin(5, 5, 5, 5)
		function self.public:OnChange()
			local ispublic = self:GetChecked()

			netstream.Start("pubShp", self.entity, ispublic)
		end
		*/

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.itemPanel = {}
	end

	function PANEL:setItems(entity, items)
		self.entity = entity
		self.items = items

		for k, v in SortedPairs(items) do
			local itemTable = nut.item.list[k]

			self.itemPanel[k] = self.list:Add("DPanel")
			local item = self.itemPanel[k]
			item:SetTall(36)
			item:Dock(TOP)
			item:DockMargin(5, 5, 5, 0)
			item.amount = v

			item.icon = item:Add("SpawnIcon")
			item.icon:SetPos(2, 2)
			item.icon:SetSize(32, 32)
			item.icon:SetModel(itemTable.model)
			item.icon:SetToolTip(itemTable:getDesc())

			item.name = item:Add("DLabel")
			item.name:SetPos(40, 2)
			item.name:SetSize(250, 32)
			item.name:SetFont("nutChatFont")
			item.name:SetTextColor(color_white)
			function item:Update(amount)
				item.name:SetText(L(itemTable.name) .. " (" .. amount .. ")")
			end
			item:Update(item.amount)

			item.clicker = item:Add("DButton")
			item.clicker:Dock(FILL)
			item.clicker.Paint = function() end
			item.clicker:SetText("")
			item.clicker.DoClick = function()
				netstream.Start("takeShp", entity, k, 1)
			end
		end
	end

	function PANEL:Think()
		if (self.items and !IsValid(self.entity)) then
			self:Remove()
		end
	end
vgui.Register("nutShipment", PANEL, "DFrame")