-- Auto-reload will remove the variable if it doesn't get reset.
nut.loaded = nut.loaded or false

function GM:HUDShouldDraw(element)
	if (element == "CHudHealth" or element == "CHudBattery" or element == "CHudAmmo" or element == "CHudSecondaryAmmo") then
		return false
	end

	if (IsValid(nut.gui.charMenu)) then
		if (element == "CHudCrosshair") then
			return false
		end
	end

	return true
end

function GM:PaintBar(value, color, x, y, width, height)
	if (value < 100 and value > 0) then
		color.a = 205

		draw.RoundedBox(2, x, y, width, height, Color(0, 0, 0, 250))

		width = width * (math.Clamp(value, 0, 100) / 100) - 2

		surface.SetDrawColor(color)
		surface.DrawRect(x + 1, y + 1, width, height - 2)

		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawOutlinedRect(x + 1, y + 1, width, height - 2)

		return y - height - 2
	else
		return y
	end
end

local BAR_WIDTH, BAR_HEIGHT = ScrW() * 0.27, 10

function GM:HUDPaint()
	local trace = LocalPlayer():GetEyeTrace()

	nut.schema.Call("HUDPaintTargetID", trace.Entity)

	if (!IsValid(nut.gui.charMenu)) then
		local x = 8
		local y = ScrH() - BAR_HEIGHT - 8

		y = nut.bar.Paint(x, y, BAR_WIDTH, BAR_HEIGHT)
	end

	nut.scroll.Paint()
	
	if (!nut.loaded) then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, ScrW(), ScrH())

		draw.SimpleText("Loading NutScript", "nut_HeaderFont", ScrW() * 0.5, ScrH() * 0.5, color_white, 1, 1)
	end

	local info = {
		"NutScript Development Build",
		"Schema UniqueID: "..SCHEMA.uniqueID,
		"http://chessnut.info"
	}

	surface.SetFont("DermaDefault")

	local x, y = 8, 8

	for k, v in ipairs(info) do
		draw.SimpleText(v, "BudgetLabel", x, y, color_white, 0, 0)

		y = y + 16
	end
end

function GM:ShouldDrawTargetEntity(entity)
	return false
end

function GM:HUDPaintTargetID(entity)
	for k, v in pairs(ents.GetAll()) do
		if (v != LocalPlayer() and v:IsPlayer() or v:GetClass() == "nut_item" or nut.schema.Call("ShouldDrawTargetEntity", v) == true) then
			local target = 0
			local inRange = false

			if (IsValid(entity) and entity:GetPos():Distance(LocalPlayer():GetPos()) <= 360) then
				inRange = true
			end

			if (inRange and entity == v) then
				target = 255
			end

			v.approachAlpha = math.Approach(v.approachAlpha or 0, target, FrameTime() * 150)

			local offset = Vector(0, 0, 8)

			if (v:IsPlayer()) then
				offset = Vector(0, 0, 48)
			end

			local position = (v:LocalToWorld(v:OBBCenter()) + offset):ToScreen()
			local alpha = v.approachAlpha
			local mainColor = nut.config.mainColor
			local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)

			if (alpha > 0) then
				if (v:GetClass() == "nut_item") then
					local itemTable = v:GetItemTable()

					if (itemTable) then
						nut.util.DrawText(position.x, position.y, itemTable.name, color)

						position.y = position.y + nut.config.targetTall
						color = Color(255, 255, 255, alpha)

						nut.util.DrawText(position.x, position.y, itemTable:GetDesc(v:GetData()), color, "nut_TargetFontSmall")

						if (itemTable.Paint) then
							itemTable:Paint(v, position.x, position.y + nut.config.targetTall, color)
						end
					end
				elseif (v.character) then
					local color = team.GetColor(v:Team())
					color.a = alpha

					if (v:IsTyping()) then
						nut.util.DrawText(position.x, position.y - nut.config.targetTall, nut.config.showTypingText and v:GetNetVar("typing") or "Typing...", Color(255, 255, 255, alpha))
					end

					nut.util.DrawText(position.x, position.y, v:Name(), color)
					position.y = position.y + nut.config.targetTall
					color = Color(255, 255, 255, alpha)

					local description = v.character:GetVar("description", nut.lang.Get("no_desc"))

					if (!v.nut_DescLines or description != (v.nut_DescText or "")) then
						v.nut_DescText = description
						v.nut_DescLines, _, v.nut_DescLineH = nut.util.WrapText("nut_TargetFontSmall", ScrW() * 0.2, v.nut_DescText)
					end

					nut.util.DrawWrappedText(position.x, position.y, v.nut_DescLines, v.nut_DescLineH, "nut_TargetFontSmall", 1, 1, alpha)
				else
					nut.schema.Call("DrawTargetID", v, position.x, position.y, alpha)
				end
			end
		end
	end
end

nut.bar.Add("health", {
	getValue = function()
		return LocalPlayer():Health()
	end,
	color = Color(255, 40, 30)
})

nut.bar.Add("armor", {
	getValue = function()
		return LocalPlayer():Armor()
	end,
	color = Color(50, 90, 200)
})

function GM:CalcViewModelView(weapon, viewModel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)
	if (!IsValid(weapon)) then
		return
	end

	local client = LocalPlayer()

	local data = {}
		data.start = eyePos + client:GetAimVector() * 1
		data.endpos = eyePos + client:GetAimVector() * 30
	local trace = util.TraceLine(data)

	viewModel:SetPos(trace.HitPos - client:GetAimVector()*18 * 1.3)

	local value = 0

	if (!client:WepRaised()) then
		value = 100
	end

	local fraction = (client.raisedFrac or 0) / 100
	local rotation = weapon.LowerAngles or Angle(30, 5, -10)
	
	eyeAngles:RotateAroundAxis(eyeAngles:Up(), rotation.p * fraction)
	eyeAngles:RotateAroundAxis(eyeAngles:Forward(), rotation.y * fraction)
	eyeAngles:RotateAroundAxis(eyeAngles:Right(), rotation.r * fraction)

	client.raisedFrac = math.Approach(client.raisedFrac or 0, value, FrameTime() * 175)

	viewModel:SetAngles(eyeAngles)
end

function GM:RenderScreenspaceEffects()
	local color = {}
	color["$pp_colour_addr"] = 0.02
	color["$pp_colour_addg"] = 0.01
	color["$pp_colour_addb"] = 0.07
	color["$pp_colour_brightness"] = -0.05
	color["$pp_colour_contrast"] = 1.3
	color["$pp_colour_colour"] = 0.4
	color["$pp_colour_mulr"] = 0.1
	color["$pp_colour_mulg"] = 0
	color["$pp_colour_mulb"] = 0.1

	DrawColorModify(color)
end