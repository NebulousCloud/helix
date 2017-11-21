nut.hud = {}

local owner, w, h, ceil, ft, clmp
ceil = math.ceil
clmp = math.Clamp
local aprg, aprg2 = 0, 0

function nut.hud.DrawDeath()
	owner = LocalPlayer()
	ft = FrameTime()
	w, h = ScrW(), ScrH()

	if (owner:GetChar()) then
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

	if (IsValid(nut.char.gui) and nut.gui.char:IsVisible() or !owner:GetChar()) then
		return
	end

	surface.SetDrawColor(0, 0, 0, ceil((aprg^.5) * 255))
	surface.DrawRect(-1, -1, w+2, h+2)
	local tx, ty = nut.util.DrawText(string.upper(L"youreDead"), w/2, h/2, ColorAlpha(color_white, aprg2 * 255), 1, 1, "nutDynFontMedium", aprg2 * 255)
end

function nut.hud.DrawItemPickup()
	local pickupTime = nut.config.Get("itemPickupTime", 0.5)

	if (pickupTime == 0) then
		return
	end

	local client = LocalPlayer()
	local entity = client.nutInteractionTarget
	local startTime = client.nutInteractionStartTime

	if (IsValid(entity) and startTime) then
		local sysTime = SysTime()
		local endTime = startTime + pickupTime

		if (sysTime >= endTime or client:GetEyeTrace().Entity != entity) then
			client.nutInteractionTarget = nil
			client.nutInteractionStartTime = nil

			return
		end

		local fraction = math.min((endTime - sysTime) / pickupTime, 1)
		local x, y = ScrW() / 2, ScrH() / 2
		local radius, thickness = 32, 6
		local startAngle = 90
		local endAngle = startAngle + (1 - fraction) * 360
		local color = ColorAlpha(color_white, fraction * 255)

		nut.util.DrawArc(x, y, radius, thickness, startAngle, endAngle, 2, color)
	end
end

hook.Add("GetCrosshairAlpha", "nutCrosshair", function(alpha)
	return alpha * (1 - aprg)
end)

function nut.hud.DrawAll(postHook)
	if (postHook) then
		nut.hud.DrawDeath()
	end

	nut.hud.DrawItemPickup()
end
