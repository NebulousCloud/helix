nut.bar = nut.bar or {}
nut.bar.list = {}
nut.bar.delta = nut.bar.delta or {}
nut.bar.actionText = ""
nut.bar.actionStart = 0
nut.bar.actionEnd = 0
nut.bar.totalHeight = 0

NUT_CVAR_SHOWBARS = CreateClientConVar("nut_alwaysshowbars", "0", true)

function nut.bar.Get(identifier)
	for i = 1, #nut.bar.list do
		local bar = nut.bar.list[i]
		
		if (bar and bar.identifier == identifier) then
			return bar
		end
	end
end

function nut.bar.Add(getValue, color, priority, identifier)
	if (identifier) then
		local oldBar = nut.bar.Get(identifier)
		
		if (oldBar) then
			table.remove(nut.bar.list, oldBar.priority)
		end
	end

	priority = priority or table.Count(nut.bar.list) + 1

	local info = nut.bar.list[priority]

	nut.bar.list[priority] = {
		getValue = getValue,
		color = color or info.color or Color(math.random(150, 255), math.random(150, 255), math.random(150, 255)),
		priority = priority,
		lifeTime = 0,
		identifier = identifier
	}

	return priority
end

local gradientU = nut.util.GetMaterial("vgui/gradient-u")
local gradientD = nut.util.GetMaterial("vgui/gradient-d")
local surface = surface
local draw = draw

local TEXT_COLOR = Color(240, 240, 240)
local SHADOW_COLOR = Color(20, 20, 20)

function nut.bar.Draw(x, y, w, h, value, color, text)
	local origX, origY = x, y
	
	nut.util.DrawBlurAt(x, y, w, h)

	surface.SetDrawColor(255, 255, 255, 15)
	surface.DrawRect(x, y, w, h)
	surface.DrawOutlinedRect(x, y, w, h)

	x, y, w, h = origX + 2, origY + 2, (w - 4) * math.min(value, 1), h - 4

	surface.SetDrawColor(color.r, color.g, color.b, 250)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(255, 255, 255, 8)
	surface.SetMaterial(gradientU)
	surface.DrawTexturedRect(x, y, w, h)

	if (isstring(text)) then
		x, y = origX + (w * 0.5), origY + (h * 0.5)

		draw.SimpleText(text, "nutSmallFont", x + 2, y + 2, SHADOW_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(text, "nutSmallFont", x, y, TEXT_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function nut.bar.DrawAction()
	local start, finish = nut.bar.actionStart, nut.bar.actionEnd
	local curTime = CurTime()
	local scrW, scrH = ScrW(), ScrH()

	if (finish > curTime) then
		local fraction = 1 - math.TimeFraction(start, finish, curTime)
		local alpha = fraction * 255

		if (alpha > 0) then
			local w, h = scrW * 0.35, 28
			local x, y = (scrW * 0.5) - (w * 0.5), (scrH * 0.725) - (h * 0.5)

			nut.util.DrawBlurAt(x, y, w, h)

			surface.SetDrawColor(35, 35, 35, 100)
			surface.DrawRect(x, y, w, h)

			surface.SetDrawColor(0, 0, 0, 120)
			surface.DrawOutlinedRect(x, y, w, h)

			surface.SetDrawColor(nut.config.Get("color"))
			surface.DrawRect(x + 4, y + 4, (w * fraction) - 8, h - 8)

			surface.SetDrawColor(200, 200, 200, 20)
			surface.SetMaterial(gradientD)
			surface.DrawTexturedRect(x + 4, y + 4, (w * fraction) - 8, h - 8)

			draw.SimpleText(nut.bar.actionText, "nutMediumFont", x + 2, y - 22, SHADOW_COLOR)
			draw.SimpleText(nut.bar.actionText, "nutMediumFont", x, y - 24, TEXT_COLOR)
		end
	end
end

local Approach = math.Approach

BAR_HEIGHT = 10

function nut.bar.DrawAll()
	nut.bar.totalHeight = 4

	if (hook.Run("ShouldHideBars")) then
		return
	end

	local w, h = surface.ScreenWidth() * 0.35, BAR_HEIGHT
	local x = 4
	local deltas = nut.bar.delta
	local frameTime = FrameTime()
	local curTime = CurTime()
	local updateValue = frameTime * 0.6

	for i = 1, #nut.bar.list do
		local bar = nut.bar.list[i]

		if (bar) then
			local realValue = bar.getValue()
			local value = Approach(deltas[i] or 0, realValue, updateValue)

			deltas[i] = value

			if (deltas[i] != realValue) then
				bar.lifeTime = curTime + 5
			end

			if (bar.lifeTime >= curTime or bar.visible or NUT_CVAR_SHOWBARS:GetBool() or hook.Run("ShouldBarDraw", bar)) then
				nut.bar.Draw(x, nut.bar.totalHeight, w, h, value, bar.color, bar.text)
				nut.bar.totalHeight = nut.bar.totalHeight + h + 2
			end
		end
	end

	nut.bar.DrawAction()
end

do
	nut.bar.Add(function()
		return LocalPlayer():Health() / LocalPlayer():GetMaxHealth()
	end, Color(200, 50, 40), nil, "health")

	nut.bar.Add(function()
		return math.min(LocalPlayer():Armor() / 100, 1)
	end, Color(30, 70, 180), nil, "armor")
end

netstream.Hook("actBar", function(start, finish, text)
	if (!text) then
		nut.bar.actionStart = 0
		nut.bar.actionEnd = 0
	else
		if (text:sub(1, 1) == "@") then
			text = L2(text:sub(2)) or text
		end

		nut.bar.actionStart = start
		nut.bar.actionEnd = finish
		nut.bar.actionText = text:upper()
	end
end)
