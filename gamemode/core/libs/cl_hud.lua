
ix.hud = {}

local owner, w, h, ceil, ft, clmp
ceil = math.ceil
clmp = math.Clamp
local aprg, aprg2 = 0, 0

function ix.hud.DrawDeath()
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

	if (IsValid(ix.char.gui) and ix.gui.char:IsVisible() or !owner:GetChar()) then
		return
	end

	surface.SetDrawColor(0, 0, 0, ceil((aprg^.5) * 255))
	surface.DrawRect(-1, -1, w+2, h+2)

	ix.util.DrawText(
		string.upper(L"youreDead"), w/2, h/2, ColorAlpha(color_white, aprg2 * 255), 1, 1, "ixDynFontMedium", aprg2 * 255
	)
end

function ix.hud.DrawItemPickup()
	local pickupTime = ix.config.Get("itemPickupTime", 0.5)

	if (pickupTime == 0) then
		return
	end

	local client = LocalPlayer()
	local entity = client.ixInteractionTarget
	local startTime = client.ixInteractionStartTime

	if (IsValid(entity) and startTime) then
		local sysTime = SysTime()
		local endTime = startTime + pickupTime

		if (sysTime >= endTime or client:GetEyeTrace().Entity != entity) then
			client.ixInteractionTarget = nil
			client.ixInteractionStartTime = nil

			return
		end

		local fraction = math.min((endTime - sysTime) / pickupTime, 1)
		local x, y = ScrW() / 2, ScrH() / 2
		local radius, thickness = 32, 6
		local startAngle = 90
		local endAngle = startAngle + (1 - fraction) * 360
		local color = ColorAlpha(color_white, fraction * 255)

		ix.util.DrawArc(x, y, radius, thickness, startAngle, endAngle, 2, color)
	end
end

hook.Add("GetCrosshairAlpha", "ixCrosshair", function(alpha)
	return alpha * (1 - aprg)
end)

function ix.hud.DrawAll(postHook)
	if (postHook) then
		ix.hud.DrawDeath()
	end

	ix.hud.DrawItemPickup()
end
