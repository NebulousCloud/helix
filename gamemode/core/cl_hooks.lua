-- Auto-reload will remove the variable if it doesn't get reset.
nut.loaded = nut.loaded or false
nut.loadingText = nut.loadingText or {}

local surface = surface
local draw = draw
local pairs = pairs
local nut = nut

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

local DrawRect = surface.DrawRect
local SetDrawColor = surface.SetDrawColor
local SetDrawMaterial = surface.SetMaterial
local logo = Material("nutscript/logo.png")
local glow = Material("nutscript/logo_glow.png")

nut.loadAlpha = nut.loadAlpha or 0
nut.loadScreenAlpha = nut.loadScreenAlpha or 255

function GM:PostRenderVGUI()
	if (!gui.IsGameUIVisible() and nut.loadScreenAlpha > 0) then
		local scrW, scrH = surface.ScreenWidth(), surface.ScreenHeight()
		local goal = 0

		if (nut.loaded) then
			goal = 255
		end

		nut.loadAlpha = math.Approach(nut.loadAlpha, goal, FrameTime() * 60)

		if (nut.loadAlpha == 255 and goal == 255) then
			if (nut.loadScreenAlpha == 255) then
				LocalPlayer():EmitSound("friends/friend_online.wav", 160, 51)
			end

			nut.loadScreenAlpha = math.Approach(nut.loadScreenAlpha, 0, FrameTime() * 60)
		end

		local alpha = nut.loadScreenAlpha

		if (alpha > 0) then
			SetDrawColor(10, 10, 14, alpha)
			DrawRect(0, 0, scrW, scrH)

			local x, y, w, h = scrW*0.5 - 128, scrH*0.4 - 128, 256, 256

			surface.SetDrawColor(255, 255, 255, alpha)
			surface.SetMaterial(logo)
			surface.DrawTexturedRect(x, y, w, h)

			surface.SetDrawColor(255, 255, 255, (nut.loadAlpha/255 * 150 + math.sin(RealTime() * 2)*25) * (alpha / 255))
			surface.SetMaterial(glow)
			surface.DrawTexturedRect(x, y, w, h)

			for i = #nut.loadingText, 1, -1 do
				local alpha2 = (1-i / #nut.loadingText) * alpha

				draw.SimpleText(nut.loadingText[i], "nut_TargetFont", scrW * 0.5, scrH * 0.6 + (i * 36), Color(255, 255, 255, alpha2), 1, 1)
			end

			hook.Run("DrawLoadingScreen")

			do return end
		end
	end
end

local DrawOutlinedRect = surface.DrawOutlinedRect

function GM:HUDPaint()
	local client = LocalPlayer()
	local scrW, scrH = surface.ScreenWidth(), surface.ScreenHeight()

	if (nut.config.drawVignette) then
		local alpha = 240
		local data = {}
			data.start = client:GetPos()
			data.endpos = data.start + Vector(0, 0, 1000)
		local trace = util.TraceLine(data)

		if (!trace.Hit or trace.HitSky) then
			alpha = 125
		end

		vignetteAlpha = math.Approach(vignetteAlpha, alpha, FrameTime() * 75)

		SetDrawColor(255, 255, 255, vignetteAlpha)
		SetDrawMaterial(vignette)
		surface.DrawTexturedRect(0, 0, scrW, scrH)
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

	local entity = client:GetEyeTraceNoCursor().Entity
	hook.Run("HUDPaintTargetID", entity)

	self.BaseClass:PaintWorldTips()

	if (hook.Run("ShouldDrawCrosshair") != false and nut.config.crosshair) then
		local x, y = scrW * 0.5 - 2, scrH * 0.5 - 2
		local size = nut.config.crossSize or 1
		local size2 = size + 2
		local spacing = nut.config.crossSpacing or 5
		local alpha = nut.config.crossAlpha or 150

		SetDrawColor(25, 25, 25, alpha)
		DrawOutlinedRect(x-1 - spacing, y-1 - spacing, size2, size2)
		DrawOutlinedRect(x-1 + spacing, y-1 - spacing, size2, size2)
		DrawOutlinedRect(x-1 - spacing, y-1 + spacing, size2, size2)
		DrawOutlinedRect(x-1 + spacing, y-1 + spacing, size2, size2)

		SetDrawColor(230, 230, 230, alpha)
		DrawRect(x - spacing, y - spacing, size, size)
		DrawRect(x + spacing, y - spacing, size, size)
		DrawRect(x - spacing, y + spacing, size, size)
		DrawRect(x + spacing, y + spacing, size, size)
	end

	if (client:GetNetVar("tied")) then
		nut.util.DrawText(scrW * 0.5, scrH * 0.25, "You have been tied.")
	end

	local x = 8
	local y = scrH - BAR_HEIGHT - 8

	y = nut.bar.Paint(x, y, BAR_WIDTH, BAR_HEIGHT)

	nut.bar.PaintMain()
end

function GM:HUDDrawTargetID()
	return false
end

function GM:ShouldDrawTargetEntity(entity)
	return false
end

function GM:PostProcessPermitted(element)
	return false
end

-- Purpose: Called once the side menu of the F1 menu has been created.
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
local sin, cos = math.sin, math.cos

function GM:CalcView(client, origin, angles, fov)
	local view = self.BaseClass:CalcView(client, origin, angles, fov)
		local drunk = client:GetNetVar("drunk", 0)
		local realTime = RealTime()

		if (drunk > 0) then
			deltaAngle = LerpAngle(math.max(0.8 - drunk, 0.025), deltaAngle or angles, angles)
			view.angles = deltaAngle + Angle(cos(realTime * 0.9) * drunk*4, sin(realTime * 0.9) * drunk*7.5, cos(realTime * 0.9) * drunk*5)
			view.fov = fov + sin(realTime * 0.5) * (drunk * 5)
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

	nut.util.DrawText(x, y, hook.Run("GetPlayerName", client), color)
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
		local add = math.sin(RealTime() * 3)*25 + 50

		nut.util.DrawText(x, y, "Press <Use> to untie.", Color(math.min(255 + add, 255), math.min(165 + add, 255), math.min(30 + add, 255)), "nut_TargetFontSmall")
	end
end

local OFFSET_NORMAL = Vector(0, 0, 8)
local OFFSET_PLAYER = Vector(0, 0, 48)
local math_Approach = math.Approach
local ents = ents

local GetVectorDistance = FindMetaTable("Vector").Distance
local VectorLocalToWorld = FindMetaTable("Entity").LocalToWorld
local VectorToScreen = FindMetaTable("Vector").ToScreen
local drawnEntities = {}
local colorCache = {}

function GM:HUDPaintTargetID(entity)
	local client = LocalPlayer()
	local frameTime = FrameTime()
	local targetIsValid = IsValid(entity)

	if (targetIsValid and (!drawnEntities[entity] and entity != client and entity:IsPlayer() or hook.Run("ShouldDrawTargetEntity", entity) == true or entity.DrawTargetID)) then
		drawnEntities[entity] = true
	end

	for v in pairs(drawnEntities) do
		if (IsValid(v) and v != client and (v:IsPlayer() or hook.Run("ShouldDrawTargetEntity", v) == true or v.DrawTargetID)) then
			local target = 0
			local inRange = false

			if (targetIsValid and GetVectorDistance(entity:GetPos(), client:GetPos()) <= 360) then
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

			local origin = VectorLocalToWorld(v, v:OBBCenter()) + offset
			local position = VectorToScreen(origin, origin)
			local alpha = v.approachAlpha
			local mainColor = nut.config.mainColor
			colorCache[alpha] = colorCache[alpha] or Color(mainColor.r, mainColor.g, mainColor.b, alpha)
			local color = colorCache[alpha]
			local x, y = position.x, position.y

			if (alpha > 0) then
				if (v.character) then
					self:HUDPaintTargetPlayer(v, x, y, alpha)
				elseif (v.DrawTargetID) then
					v:DrawTargetID(x, y, alpha)
				else
					local result = hook.Run("DrawTargetID", v, x, y, alpha)

					if (!result) then
						local client = entity:GetNetVar("player")

						if (IsValid(client) and client:IsPlayer() and client.character and entity != client) then
							self:HUDPaintTargetPlayer(client, x, y, alpha)

							return true
						end
					end
				end
			end
		else
			drawnEntities[v] = nil
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

	client.raisedFrac = math.Approach(client.raisedFrac or 0, value, FrameTime() * 150)

	viewModel:SetAngles(eyeAngles)

	if (weapon.GetViewModelPosition) then
		local position, angles = weapon:GetViewModelPosition(eyePos, eyeAngles)

		oldEyePos = position or oldEyePos
		eyeAngles = angles or eyeAngles
	end
	
	if (weapon.CalcViewModelView) then
		local position, angles = weapon:CalcViewModelView(viewModel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)

		oldEyePos = position or oldEyePos
		eyeAngles = angles or eyeAngles
	end

	return oldEyePos, eyeAngles
end

local FADE_TIME = 7

netstream.Hook("nut_FadeIntro", function(data)
	nut.fadeStart = CurTime()
	nut.fadeFinish = CurTime() + FADE_TIME

	nut.fadeColorStart = CurTime() + FADE_TIME + 5
	nut.fadeColorFinish = CurTime() + FADE_TIME + 10

	hook.Run("DoSchemaIntro")
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

	hook.Run("ModifyColorCorrection", color)

	DrawColorModify(color)

	local drunk = LocalPlayer():GetNetVar("drunk", 0)

	if (drunk > 0) then
		DrawMotionBlur(0.075, drunk, 0.025)
	end

	local charMenu = nut.gui.charMenu

	if (IsValid(charMenu) and charMenu.RenderScreenspaceEffects) then
		charMenu:RenderScreenspaceEffects(color)
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
	if (bind == "gm_showhelp") then
		if (IsValid(nut.gui.charMenu)) then
			return
		end

		if (IsValid(nut.gui.menu)) then
			if nut.gui.menu:IsVisible() then
				return
			else
				nut.gui.menu:Remove()
			end
		end

		if (client.character) then
			nut.gui.menu = vgui.Create("nut_Menu")
		end
	end

	if (!client:GetNetVar("gettingUp") and client:IsRagdolled() and string.find(bind, "+jump") and pressed) then
		RunConsoleCommand("nut", "chargetup")
	end
end

-- Purpose: Whether or not a new nut_Notification element should be created.
function GM:NoticeShouldAppear(message) return true end

-- Purpose: Called right before a notification is actually removed.
function GM:NoticeRemoved(notice) end

-- Purpose: Called after a notification has been created from nut.util.Notify()
function GM:NoticeCreated(notice) end

-- Purpose: Called before business items are added so the menu can be modified.
function GM:BusinessPrePopulateItems(panel) end

-- Purpose: Whether or not an item will display in the business menu.
function GM:ShouldItemDisplay(itemTable) return true end

-- Purpose: Called after a new DCollapsibleCategory has been created.
function GM:BusinessCategoryCreated(category) end

-- Purpose: Called after a new item has been added to the business.
function GM:BusinessItemCreated(itemTable, panel) end

-- Purpose: Called once the business menu has been finalized.
function GM:BusinessPostPopulateItems(panel) end

-- Purpose: Whether or not the business tab button should be created.
function GM:PlayerCanSeeBusiness() return true end

-- Purpose: Called when the quick menu panel is created.
function GM:CreateQuickMenu() end

-- Purpose: Called to determine if a bar should be painted on the HUD. Return false to hide.
function GM:HUDShouldPaintBar(bar) return true end

-- Purpose: Called to get the user icon infront of an OOC message.
function GM:GetUserIcon(speaker) end

-- Purpose: Called before a chat message is added. Return true to block the message.
function GM:ChatClassPreText(class, speaker, text, mode) end

-- Purpose: Called after a chat message has bee added.
function GM:ChatClassPostText(class, speaker, text, mode) end

-- Purpose: Called by the recognition plugin to see if a player is recognized.
function GM:IsPlayerRecognized(client) return false end

-- Purpose: Called by the recognition plugin to get the fake name displayed 
-- if a player is recognized.
function GM:GetUnknownPlayerName(client)
	-- return "Unknown"
end

-- Purpose: Called by the storage plugin before the storage menu is created.
function GM:ContainerOpened(entity) end

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