PLUGIN.name = "Crosshair"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "A Crosshair."

if (CLIENT) then
	local function drawdot( pos, size, col )
		local color = col[2]
		surface.SetDrawColor(color.r, color.g, color.b, color.a)
		surface.DrawRect(pos[1] - size/2, pos[2] - size/2, size, size)

		local color = col[1]
		surface.SetDrawColor(color.r, color.g, color.b, color.a)
		surface.DrawOutlinedRect(pos[1] - size/2, pos[2] - size/2 , size, size)
	end

	local w, h, aimVector, punchAngle, ft, screen, scaleFraction, distance, entity
	local math_round = math.Round
	local curGap = 0
	local curAlpha = 0
	local maxDistance = 1000 ^ 2
	local crossSize = 4
	local crossGap = 0
	local colors = {color_black}
	local filter = {}

	function PLUGIN:PostDrawHUD()
		local client = LocalPlayer()
		if (!client:getChar() or !client:Alive()) then
			return
		end

		local entity = Entity(client:getLocalVar("ragdoll", 0))
		if (entity:IsValid()) then
			return
		end

		local wep = client:GetActiveWeapon()
		if (wep and wep:IsValid() and wep.HUDPaint) then
			return
		end

		if (hook.Run("ShouldDrawCrosshair") == false or g_ContextMenu:IsVisible() or nut.gui.char:IsVisible()) then
			return
		end

		aimVector = client:EyeAngles()
		punchAngle = client:GetPunchAngle()
		w, h = ScrW(), ScrH()
		ft = FrameTime()
		filter = {client}

		local vehicle = client:GetVehicle()
		if (vehicle and IsValid(vehicle)) then
			aimVector = aimVector + vehicle:GetAngles()
			table.insert(filter, vehicle)
		end

		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + (aimVector + punchAngle):Forward()*65535
			data.filter = filter
		local trace = util.TraceLine(data)

		entity = trace.Entity
		distance = trace.StartPos:DistToSqr(trace.HitPos)
		scaleFraction = 1 - math.Clamp(distance / maxDistance, 0, .5)
		screen = trace.HitPos:ToScreen()
		crossSize = 4
		crossGap = 25 * (scaleFraction - (client:isWepRaised() and 0 or .1))

		if (IsValid(entity) and entity:GetClass() == "nut_item" and 
			entity:GetPos():DistToSqr(data.start) <= 16384) then
			crossGap = 0
			crossSize = 5
		end

		curGap = Lerp(ft * 2, curGap, crossGap)
		curAlpha = Lerp(ft * 2, curAlpha, (!client:isWepRaised() and 255 or 150))
		curAlpha = hook.Run("GetCrosshairAlpha", curAlpha) or curAlpha
		colors[2] = Color(255, curAlpha, curAlpha, curAlpha)

		drawdot( {math_round(screen.x), math_round(screen.y)}, crossSize, colors)
		drawdot( {math_round(screen.x + curGap), math_round(screen.y)}, crossSize, colors)
		drawdot( {math_round(screen.x - curGap), math_round(screen.y)}, crossSize, colors) 
		drawdot( {math_round(screen.x), math_round(screen.y + curGap * .8)}, crossSize, colors) 
		drawdot( {math_round(screen.x), math_round(screen.y - curGap * .8)}, crossSize, colors) 
	end
end