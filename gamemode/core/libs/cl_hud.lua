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

nut.hud = {}

local owner, w, h, ceil, ft, clmp
ceil = math.ceil
clmp = math.Clamp
local aprg, aprg2 = 0, 0
function nut.hud.drawDeath()
	owner = LocalPlayer()
	ft = FrameTime()
	w, h = ScrW(), ScrH()

	if (owner:getChar()) then
		if (owner:Alive()) then
			if (aprg != 0) then
				aprg2 = clmp(aprg2 - ft*1.3, 0, 1)
				if (aprg2 == 0) then
					aprg = clmp(aprg - ft*.7, 0, 1)
				end
			end
		else
			if (aprg2 != 1) then
				aprg = clmp(aprg + ft*.5, 0, 1)
				if (aprg == 1) then
					aprg2 = clmp(aprg2 + ft*.4, 0, 1)
				end
			end
		end
	end

	if (IsValid(nut.char.gui) and nut.gui.char:IsVisible() or !owner:getChar()) then
		return
	end

	surface.SetDrawColor(0, 0, 0, ceil((aprg^.5) * 255))
	surface.DrawRect(-1, -1, w+2, h+2)
	local tx, ty = nut.util.drawText(L"youreDead", w/2, h/2, ColorAlpha(color_white, aprg2 * 255), 1, 1, "nutDynFontMedium", aprg2 * 255)
end

hook.Add("GetCrosshairAlpha", "nutCrosshair", function(alpha)
	return alpha * (1 - aprg)
end)

function nut.hud.drawAll(postHook)
	if (postHook) then
		nut.hud.drawDeath()
	end
end