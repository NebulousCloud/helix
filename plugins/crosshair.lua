
local PLUGIN = PLUGIN

PLUGIN.name = "Crosshair"
PLUGIN.author = "Black Tea"
PLUGIN.description = "A Crosshair."

if (CLIENT) then
	local function drawdot( pos, size, col )
		local color = col[2]
		surface.SetDrawColor(color.r, color.g, color.b, color.a)
		surface.DrawRect(pos[1] - size/2, pos[2] - size/2, size, size)

		color = col[1]
		surface.SetDrawColor(color.r, color.g, color.b, color.a)
		surface.DrawOutlinedRect(pos[1] - size/2, pos[2] - size/2 , size, size)
	end

	local aimVector, punchAngle, ft, screen, scaleFraction, distance
	local math_round = math.Round
	local curGap = 0
	local curAlpha = 0
	local maxDistance = 1000 ^ 2
	local crossSize = 4
	local crossGap = 0
	local colors = {color_black}
	local filter = {}

	function PLUGIN:DrawCrosshair(x, y, trace)
		local entity = trace.Entity
		distance = trace.StartPos:DistToSqr(trace.HitPos)
		scaleFraction = 1 - math.Clamp(distance / maxDistance, 0, .5)
		crossSize = 4
		crossGap = 25 * (scaleFraction - (LocalPlayer():IsWepRaised() and 0 or .1))

		if (IsValid(entity) and entity:GetClass() == "ix_item" and
			entity:GetPos():DistToSqr(trace.StartPos) <= 16384) then
			crossGap = 0
			crossSize = 5
		end

		curGap = Lerp(ft * 2, curGap, crossGap)
		curAlpha = Lerp(ft * 2, curAlpha, (!LocalPlayer():IsWepRaised() and 255 or 150))
		curAlpha = hook.Run("GetCrosshairAlpha", curAlpha) or curAlpha
		colors[2] = Color(255, curAlpha, curAlpha, curAlpha)

		drawdot( {math_round(screen.x), math_round(screen.y)}, crossSize, colors)
		drawdot( {math_round(screen.x + curGap), math_round(screen.y)}, crossSize, colors)
		drawdot( {math_round(screen.x - curGap), math_round(screen.y)}, crossSize, colors)
		drawdot( {math_round(screen.x), math_round(screen.y + curGap * .8)}, crossSize, colors)
		drawdot( {math_round(screen.x), math_round(screen.y - curGap * .8)}, crossSize, colors)
	end

	-- luacheck: globals g_ContextMenu
	function PLUGIN:PostDrawHUD()
		local client = LocalPlayer()
		if (!client:GetCharacter() or !client:Alive()) then
			return
		end

		local entity = Entity(client:GetLocalVar("ragdoll", 0))

		if (entity:IsValid()) then
			return
		end

		local wep = client:GetActiveWeapon()
		local bShouldDraw = hook.Run("ShouldDrawCrosshair", client, wep)

		if (bShouldDraw == false or !IsValid(wep) or wep.DrawCrosshair == false) then
			return
		end

		if (bShouldDraw == false or g_ContextMenu:IsVisible() or
			(IsValid(ix.gui.characterMenu) and !ix.gui.characterMenu:IsClosing())) then
			return
		end

		aimVector = client:EyeAngles()
		punchAngle = client:GetPunchAngle()
		ft = FrameTime()
		filter = {client}

		local vehicle = client:GetVehicle()
		if (vehicle and IsValid(vehicle)) then
			aimVector = aimVector + vehicle:GetAngles()
			table.insert(filter, vehicle)
		end

		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + (aimVector + punchAngle):Forward() * 65535
			data.filter = filter
		local trace = util.TraceLine(data)

		local drawTarget = self
		local drawFunction = self.DrawCrosshair

		-- we'll manually call this since CHudCrosshair is never drawn; checks are already performed
		if (wep.DoDrawCrosshair) then
			drawTarget = wep
			drawFunction = wep.DoDrawCrosshair
		end

		screen = trace.HitPos:ToScreen()
		drawFunction(drawTarget, screen.x, screen.y, trace)
	end
end
