-- Auto-reload will remove the variable if it doesn't get reset.
nut.loaded = nut.loaded or false
nut.loadingText = nut.loadingText or {}

local surface = surface
local draw = draw
local pairs = pairs

function GM:HUDShouldDraw(element)
	if (element == "CHudHealth" or element == "CHudBattery" or element == "CHudAmmo" or element == "CHudSecondaryAmmo") then
		return false
	end
	
	if (element == "CHudCrosshair") then
		return false
	end

	return true
end

local OUTLINE_COLOR = Color(0, 0, 0, 250)
local math_Clamp = math.Clamp

function GM:PaintBar(value, color, x, y, width, height)
	color.a = 205

	draw.RoundedBox(2, x, y, width, height, OUTLINE_COLOR)

	width = width * (math_Clamp(value, 0, 100) / 100) - 2

	if (width > 0) then
		surface.SetDrawColor(color)
		surface.DrawRect(x + 1, y + 1, width, height - 2)

		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawOutlinedRect(x + 1, y + 1, width, height - 2)
	end

	return y - height - 2
end

local NUT_CVAR_BWIDTH = CreateClientConVar("nut_barwscale", "0.27", true)
local NUT_CVAR_BHEIGHT = CreateClientConVar("nut_barh", "10", true)
local BAR_WIDTH, BAR_HEIGHT = ScrW() * NUT_CVAR_BWIDTH:GetFloat(), NUT_CVAR_BHEIGHT:GetInt()
local lastFPS = 0
local avgFPS = 0

cvars.AddChangeCallback("nut_barwscale", function(conVar, oldValue, value)
	if (NUT_CVAR_BWIDTH:GetFloat() == 0) then
		BAR_WIDTH = 0
	else
		BAR_WIDTH = math.max(ScrW() * NUT_CVAR_BWIDTH:GetFloat(), 8)
	end
end)

cvars.AddChangeCallback("nut_barh", function(conVar, oldValue, value)
	BAR_HEIGHT = math.max(NUT_CVAR_BHEIGHT:GetInt(), 3)
end)

local vignette = Material("nutscript/vignette.png")
local vignetteAlpha = 0

function GM:HUDPaint()
	local scrW, scrH = surface.ScreenWidth(), surface.ScreenHeight()

	if (nut.config.drawVignette) then
		local alpha = 235
		local data = {}
			data.start = LocalPlayer():GetPos()
			data.endpos = data.start + Vector(0, 0, 1000)
		local trace = util.TraceLine(data)

		if (!trace.Hit or trace.HitSky) then
			alpha = 150
		end

		vignetteAlpha = math.Approach(vignetteAlpha, alpha, FrameTime() * 75)

		surface.SetDrawColor(255, 255, 255, vignetteAlpha)
		surface.SetMaterial(vignette)
		surface.DrawTexturedRect(0, 0, scrW, scrH)
	end

	if (!nut.loaded) then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, scrW, scrH)

		draw.SimpleText("Loading NutScript", "nut_HeaderFont", scrW * 0.5, scrH * 0.5, color_white, 1, 1)

		for i = #nut.loadingText, 1, -1 do
			local alpha = (1-i / #nut.loadingText) * 255

			draw.SimpleText(nut.loadingText[i], "nut_TargetFont", scrW * 0.5, scrH * 0.6 + (i * 36), Color(255, 255, 255, alpha), 1, 1)
		end

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

		draw.SimpleText(bigTitle, "nut_TitleFont", scrW * 0.5, scrH * 0.35, color, 1, 1)
		draw.SimpleText(nut.config.smallIntroText or SCHEMA.desc, "nut_TargetFont", scrW * 0.5, (scrH * 0.35) + h, color, 1, 1)

		return
	end

	local trace = LocalPlayer():GetEyeTrace()

	nut.schema.Call("HUDPaintTargetID", trace.Entity)

	if (nut.schema.Call("ShouldDrawCrosshair") != false and nut.config.crosshair) then
		local x, y = scrW * 0.5 - 2, scrH * 0.5 - 2
		local size = nut.config.crossSize or 1
		local size2 = size + 2
		local spacing = nut.config.crossSpacing or 5
		local alpha = nut.config.crossAlpha or 150

		surface.SetDrawColor(25, 25, 25, alpha)
		surface.DrawOutlinedRect(x-1 - spacing, y-1 - spacing, size2, size2)
		surface.DrawOutlinedRect(x-1 + spacing, y-1 - spacing, size2, size2)
		surface.DrawOutlinedRect(x-1 - spacing, y-1 + spacing, size2, size2)
		surface.DrawOutlinedRect(x-1 + spacing, y-1 + spacing, size2, size2)

		surface.SetDrawColor(230, 230, 230, alpha)
		surface.DrawRect(x - spacing, y - spacing, size, size)
		surface.DrawRect(x + spacing, y - spacing, size, size)
		surface.DrawRect(x - spacing, y + spacing, size, size)
		surface.DrawRect(x + spacing, y + spacing, size, size)
	end

	if (LocalPlayer():GetNetVar("tied")) then
		nut.util.DrawText(scrW * 0.5, scrH * 0.25, "You have been tied.")
	end

	local x = 8
	local y = scrH - BAR_HEIGHT - 8

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

	if (nut.config.showMoney and nut.currency.IsSet()) then
		menu.money = menu:Add("DLabel")
		menu.money:Dock(TOP)
		menu.money.Think = function(label)
			label:SetText(nut.currency.GetName(LocalPlayer():GetMoney(), true) or "Unknown")
		end
		menu.money:SetContentAlignment(6)
		menu.money:SetTextColor(color_white)
		menu.money:SetExpensiveShadow(1, color_black)
		menu.money:SetFont("nut_TargetFont")
		menu.money:DockMargin(4, 4, 4, 4)
	end
end

local deltaAngle

function GM:CalcView(client, origin, angles, fov)
	local view = self.BaseClass:CalcView(client, origin, angles, fov)
		local drunk = client:GetNetVar("drunk", 0)

		if (drunk > 0) then
			deltaAngle = LerpAngle(math.max(0.8 - drunk, 0.025), deltaAngle or angles, angles)
			view.angles = deltaAngle + Angle(math.cos(RealTime() * 0.9) * drunk*4, math.sin(RealTime() * 0.9) * drunk*7.5, math.cos(RealTime() * 0.9) * drunk*5)
			view.fov = fov + math.sin(RealTime() * 0.5) * (drunk * 5)
		end

		local entity = client:GetRagdollEntity()

		if (IsValid(entity)) then
			local index = entity:LookupAttachment("eyes")

			if (index and index > 0) then
				local attachment = entity:GetAttachment(index)

				view.origin = attachment.Pos
				view.angles = attachment.Ang
			end
		end

	return view
end

function GM:HUDPaintTargetPlayer(client, x, y, alpha)
	local color = team.GetColor(client:Team())
	color.a = alpha

	if (client:IsTyping()) then
		local text = "Typing..."
		local typingText = client:GetNetVar("typing")

		if (nut.config.showTypingText and typingText and type(typingText) == "string") then
			text = "("..typingText..")"
		end

		nut.util.DrawText(x, y - nut.config.targetTall, text, Color(255, 255, 255, alpha), "nut_TargetFontSmall")
	end

	nut.util.DrawText(x, y, nut.schema.Call("GetPlayerName", client), color)
	y = y + nut.config.targetTall
	color = Color(255, 255, 255, alpha)

	local description = client.character:GetVar("description", nut.lang.Get("no_desc"))

	if (!client:GetNutVar("descLines") or description != (client:GetNutVar("descText") or "")) then
		client:SetNutVar("descText", description)

		local descLines, _, lineH = nut.util.WrapText("nut_TargetFontSmall", ScrW() * 0.4, client:GetNutVar("descText"))

		client:SetNutVar("descLines", descLines)
		client:SetNutVar("lineH", lineH)
	end

	y = nut.util.DrawWrappedText(x, y, client:GetNutVar("descLines"), client:GetNutVar("lineH"), "nut_TargetFontSmall", 1, 1, alpha)

	if (client:GetNetVar("tied")) then
		nut.util.DrawText(x, y, "Press <Use> to untie.", Color(255, 165, 30, math.sin(RealTime() * 3)*100 + 150), "nut_TargetFontSmall")
	end
end

local OFFSET_NORMAL = Vector(0, 0, 8)
local OFFSET_PLAYER = Vector(0, 0, 48)
local math_Approach = math.Approach
local ents = ents

function GM:HUDPaintTargetID(entity)
	local frameTime = FrameTime()

	for k, v in pairs(ents.GetAll()) do
		if (v != LocalPlayer() and v:IsPlayer() or nut.schema.Call("ShouldDrawTargetEntity", v) == true or v.DrawTargetID) then
			local target = 0
			local inRange = false

			if (IsValid(entity) and entity:GetPos():Distance(LocalPlayer():GetPos()) <= 360) then
				inRange = true
			end

			if (inRange and entity == v) then
				target = 255
			end
			
			v.approachAlpha = math_Approach(v.approachAlpha or 0, target, frameTime * 150)

			local offset = OFFSET_NORMAL

			if (v:IsPlayer()) then
				offset = OFFSET_PLAYER
			end

			local position = (v:LocalToWorld(v:OBBCenter()) + offset):ToScreen()
			local alpha = v.approachAlpha
			local mainColor = nut.config.mainColor
			local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)
			local x, y = position.x, position.y

			if (alpha > 0) then
				if (v.character) then
					self:HUDPaintTargetPlayer(v, x, y, alpha)
				elseif (v.DrawTargetID) then
					v:DrawTargetID(x, y, alpha)
				else
					local result = nut.schema.Call("DrawTargetID", v, x, y, alpha)

					if (!result) then
						local client = entity:GetNetVar("player")

						if (IsValid(client) and client:IsPlayer() and client.character) then
							self:HUDPaintTargetPlayer(client, x, y, alpha)

							return true
						end
					end
				end
			end
		end
	end
end

function GM:ShouldDrawTargetEntity(entity)
	if (entity:GetNetVar("player")) then
		return true
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
	local brightness = 0.01
	local color2 = 0.25
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
	color["$pp_colour_addr"] = 0
	color["$pp_colour_addg"] = 0
	color["$pp_colour_addb"] = 0
	color["$pp_colour_brightness"] = brightness * -1
	color["$pp_colour_contrast"] = 1.25
	color["$pp_colour_colour"] = math.Clamp(0.7 - color2, 0, 1)
	color["$pp_colour_mulr"] = 0
	color["$pp_colour_mulg"] = 0
	color["$pp_colour_mulb"] = 0

	nut.schema.Call("ModifyColorCorrection", color)

	DrawColorModify(color)

	local drunk = LocalPlayer():GetNetVar("drunk", 0)

	if (drunk > 0) then
		DrawMotionBlur(0.075, drunk, 0.025)
	end
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

function GM:PlayerBindPress(client, bind, pressed)
	if (!client:GetNetVar("gettingUp") and client:IsRagdolled() and string.find(bind, "+jump") and pressed) then
		RunConsoleCommand("nut", "chargetup")
	end
end

netstream.Hook("nut_CurTime", function(data)
	nut.curTime = data
end)

netstream.Hook("nut_LoadingData", function(data)
	if (data == "") then
		nut.loadingText = {}

		return
	end

	table.insert(nut.loadingText, 1, data)

	if (#nut.loadingText > 4) then
		table.remove(nut.loadingText, 5)
	end
end)