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
		self:SetDrawBackground(false)
	end

	function PANEL:setMarkup(text, onDrawText)
		local object = nut.markup.parse(text, self:GetWide())
		object.onDrawText = onDrawText

		self:SetTall(object:getHeight())
		self.Paint = function(this, w, h)
			object:draw(0, 0)
		end
	end
vgui.Register("nutMarkupPanel", PANEL, "DPanel")