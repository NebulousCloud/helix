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

	local FRAMETIME_LIMIT = 1 / 60
	local function fTime() return math.Clamp(FrameTime(), FRAMETIME_LIMIT, 1) end
	local math_round = math.Round
	local curGap = 0
	local curAlpha = 0
	local maxDistance = 1000

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

		if (SUPPRESS_CROSSHAIR or g_ContextMenu:IsVisible()) then
			return
		end

		local aimVector = client:EyeAngles()
		local punchAngle = client:GetPunchAngle()

		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + (aimVector + punchAngle):Forward()*65535
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity
		local distance = trace.StartPos:Distance(trace.HitPos)
		local scaleFraction = 1 - math.Clamp(distance / maxDistance, 0, .5)
		local screen = trace.HitPos:ToScreen()
		local w, h = ScrW(), ScrH()
		local crossGap = 25 * (scaleFraction - (client:isWepRaised() and 0 or .1))
		local crossSize = 4

		if (IsValid(entity) and entity:GetClass() == "nut_item" and 
			entity:GetPos():Distance(data.start) <= 128) then
			crossGap = 0
			crossSize = 5
		end

		curGap = Lerp(fTime() * 2, curGap, crossGap)
		curAlpha = Lerp(fTime() * 2, curAlpha, (!client:isWepRaised() and 255 or 150))
		local color = {color_black, Color(255, curAlpha, curAlpha, curAlpha)}

		drawdot( {math_round(screen.x), math_round(screen.y)}, crossSize, color )
		drawdot( {math_round(screen.x + curGap), math_round(screen.y)}, crossSize, color )
		drawdot( {math_round(screen.x - curGap), math_round(screen.y)}, crossSize, color ) 
		drawdot( {math_round(screen.x), math_round(screen.y + curGap * .8)}, crossSize, color ) 
		drawdot( {math_round(screen.x), math_round(screen.y - curGap * .8)}, crossSize, color ) 
	end
end