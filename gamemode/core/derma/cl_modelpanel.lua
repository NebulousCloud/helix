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
	local MODEL_ANGLE = Angle(0, 45, 0)

	function PANEL:Init()
		self:SetCursor("none")
		self.OldSetModel = self.SetModel
		self.SetModel = function(self, model)
			self:OldSetModel(model)

			local entity = self.Entity
			local sequence = entity:LookupSequence("idle")

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle_subtle")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("batonidle2")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle_unarmed")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle01")
			end

			if (sequence > 0) then
				entity:ResetSequence(sequence)
			end
		end
	end

	function PANEL:LayoutEntity()
		local scrW, scrH = ScrW(), ScrH()
		local xRatio = gui.MouseX() / scrW
		local yRatio = gui.MouseY() / scrH
		local x, y = self:LocalToScreen(self:GetWide() / 2)
		local xRatio2 = x / scrW
		local entity = self.Entity

		entity:SetPoseParameter("head_pitch", yRatio*80 - 30)
		entity:SetPoseParameter("head_yaw", (xRatio - xRatio2)*70)
		entity:SetAngles(MODEL_ANGLE)
		entity:SetIK(false)

		self:RunAnimation()		
	end

	function PANEL:OnMousePressed()
	end
vgui.Register("nutModelPanel", PANEL, "DModelPanel")