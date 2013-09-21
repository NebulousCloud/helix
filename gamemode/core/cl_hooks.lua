-- Auto-reload will remove the variable if it doesn't get reset.
nut.loaded = nut.loaded or false

local surface = surface
local draw = draw
local pairs = pairs

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

local OUTLINE_COLOR = Color(0, 0, 0, 250)
local math_Clamp = math.Clamp

function GM:PaintBar(value, color, x, y, width, height)
	color.a = 205

	draw.RoundedBox(2, x, y, width, height, OUTLINE_COLOR)

	width = width * (math_Clamp(value, 0, 100) / 100) - 2

	surface.SetDrawColor(color)
	surface.DrawRect(x + 1, y + 1, width, height - 2)

	surface.SetDrawColor(255, 255, 255, 50)
	surface.DrawOutlinedRect(x + 1, y + 1, width, height - 2)

	return y - height - 2
end

local BAR_WIDTH, BAR_HEIGHT = ScrW() * 0.27, 10

function GM:HUDPaint()
	if (!nut.loaded) then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, ScrW(), ScrH())

		draw.SimpleText("Loading NutScript", "nut_HeaderFont", ScrW() * 0.5, ScrH() * 0.5, color_white, 1, 1)

		nut.schema.Call("DrawLoadingScreen")

		return
	end

	if (IsValid(nut.gui.charMenu)) then
		return
	end

	nut.scroll.Paint()

	if (nut.fadeStart and nut.fadeFinish) then
		local fraction = 255 - (math.TimeFraction(nut.fadeStart, nut.fadeFinish, CurTime()) * 255)
		local color = Color(255, 255, 255, fraction)
		local bigTitle = nut.config.bigIntroText or SCHEMA.name

		surface.SetFont("nut_TitleFont")
		local _, h = surface.GetTextSize(bigTitle)

		draw.SimpleText(bigTitle, "nut_TitleFont", ScrW() * 0.5, ScrH() * 0.35, color, 1, 1)
		draw.SimpleText(nut.config.smallIntroText or SCHEMA.desc, "nut_TargetFont", ScrW() * 0.5, (ScrH() * 0.35) + h, color, 1, 1)

		return
	end

	local trace = LocalPlayer():GetEyeTrace()

	nut.schema.Call("HUDPaintTargetID", trace.Entity)

	local x = 8
	local y = ScrH() - BAR_HEIGHT - 8

	y = nut.bar.Paint(x, y, BAR_WIDTH, BAR_HEIGHT)

	nut.bar.PaintMain()
end

function GM:ShouldDrawTargetEntity(entity)
	return false
end

function GM:CreateSideMenu(menu)
	if (nut.config.showTime) then
		menu.time = menu:Add("DLabel")
		menu.time:Dock(TOP)
		menu.time.Think = function(label)
			label:SetText(os.date("!%c", nut.util.GetTime()))
		end
		menu.time:SetContentAlignment(6)
		menu.time:SetTextColor(color_white)
		menu.time:SetExpensiveShadow(1, color_black)
		menu.time:SetFont("nut_TargetFont")
		menu.time:DockMargin(4, 4, 4, 4)
	end

	if (nut.config.showMoney) then
		menu.money = menu:Add("DLabel")
		menu.money:Dock(TOP)
		menu.money.Think = function(label)
			label:SetText(nut.currency.GetName(LocalPlayer():GetMoney(), true))
		end
		menu.money:SetContentAlignment(6)
		menu.money:SetTextColor(color_white)
		menu.money:SetExpensiveShadow(1, color_black)
		menu.money:SetFont("nut_TargetFont")
		menu.money:DockMargin(4, 4, 4, 4)
	end
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
						local data = v:GetData()

						nut.util.DrawText(position.x, position.y, itemTable.name, color)

						position.y = position.y + nut.config.targetTall
						color = Color(255, 255, 255, alpha)

						nut.util.DrawText(position.x, position.y, string.gsub(itemTable:GetDesc(data), "\n", ""), color, "nut_TargetFontSmall")

						if (itemTable.Paint) then
							itemTable.data = data
								itemTable:Paint(v, position.x, position.y + nut.config.targetTall, color)
							itemTable.data = nil
						end
					end
				elseif (v.character) then
					local color = team.GetColor(v:Team())
					color.a = alpha

					if (v:IsTyping()) then
						nut.util.DrawText(position.x, position.y - nut.config.targetTall, nut.config.showTypingText and v:GetNetVar("typing") or "Typing...", Color(255, 255, 255, alpha), "nut_TargetFontSmall")
					end

					nut.util.DrawText(position.x, position.y, v:Name(), color)
					position.y = position.y + nut.config.targetTall
					color = Color(255, 255, 255, alpha)

					local description = v.character:GetVar("description", nut.lang.Get("no_desc"))

					if (!v:GetNutVar("descLines") or description != (v:GetNutVar("descText") or "")) then
						v:SetNutVar("descText", description)

						local descLines, _, lineH = nut.util.WrapText("nut_TargetFontSmall", ScrW() * 0.4, v:GetNutVar("descText"))

						v:SetNutVar("descLines", descLines)
						v:SetNutVar("lineH", lineH)
					end

					nut.util.DrawWrappedText(position.x, position.y, v:GetNutVar("descLines"), v:GetNutVar("lineH"), "nut_TargetFontSmall", 1, 1, alpha)
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

local FADE_TIME = 7

netstream.Hook("nut_FadeIntro", function(data)
	nut.fadeStart = CurTime()
	nut.fadeFinish = CurTime() + FADE_TIME

	nut.fadeColorStart = CurTime() + FADE_TIME + 5
	nut.fadeColorFinish = CurTime() + FADE_TIME + 10

	nut.schema.Call("DoSchemaIntro")
end)

function GM:RenderScreenspaceEffects()
	local brightness = 0
	local color2 = 0
	local curTime = CurTime()

	if (nut.fadeStart and nut.fadeFinish) then
		brightness = 1 - math.TimeFraction(nut.fadeStart, nut.fadeFinish, curTime)

		if (curTime > nut.fadeFinish) then
			nut.fadeStart = nil
			nut.fadeFinish = nil
		end
	end

	if (nut.fadeColorStart and nut.fadeColorFinish) then
		color2 = (1 - math.TimeFraction(nut.fadeColorStart, nut.fadeColorFinish, curTime)) * 0.7

		if (curTime > nut.fadeColorFinish) then
			nut.fadeColorStart = nil
			nut.fadeColorFinish = nil
		end
	end

	local color = {}
	color["$pp_colour_addr"] = 0.02
	color["$pp_colour_addg"] = 0.01
	color["$pp_colour_addb"] = 0.07
	color["$pp_colour_brightness"] = -0.02 - (brightness * 1)
	color["$pp_colour_contrast"] = 1.3
	color["$pp_colour_colour"] = math.Clamp(0.7 - color2, 0, 1)
	color["$pp_colour_mulr"] = 0.1
	color["$pp_colour_mulg"] = 0
	color["$pp_colour_mulb"] = 0.1

	nut.schema.Call("ModifyColorCorrection", color)

	DrawColorModify(color)
end

function GM:ModifyColorCorrection(color)
	if (!nut.config.sadColors) then
		color["$pp_colour_brightness"] = color["$pp_colour_brightness"] + 0.02
		color["$pp_colour_contrast"] = 1
		color["$pp_colour_addr"] = 0
		color["$pp_colour_addg"] = 0
		color["$pp_colour_addb"] = 0
		color["$pp_colour_mulr"] = 0
		color["$pp_colour_mulg"] = 0
		color["$pp_colour_mulb"] = 0
	end
end

function GM:PlayerCanSeeBusiness()
	return true
end

netstream.Hook("nut_CurTime", function(data)
	net.curTime = data
end)