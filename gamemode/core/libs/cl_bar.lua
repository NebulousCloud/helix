ix.bar = ix.bar or {}
ix.bar.list = {}
ix.bar.delta = ix.bar.delta or {}
ix.bar.actionText = ""
ix.bar.actionStart = 0
ix.bar.actionEnd = 0
ix.bar.totalHeight = 0

IX_CVAR_SHOWBARS = CreateClientConVar("ix_alwaysshowbars", "0", true)

function ix.bar.Get(identifier)
	for i = 1, #ix.bar.list do
		local bar = ix.bar.list[i]
		
		if (bar and bar.identifier == identifier) then
			return bar
		end
	end
end

function ix.bar.Add(getValue, color, priority, identifier)
	if (identifier) then
		local oldBar = ix.bar.Get(identifier)
		
		if (oldBar) then
			table.remove(ix.bar.list, oldBar.priority)
		end
	end

	priority = priority or table.Count(ix.bar.list) + 1

	local info = ix.bar.list[priority]

	ix.bar.list[priority] = {
		getValue = getValue,
		color = color or info.color or Color(math.random(150, 255), math.random(150, 255), math.random(150, 255)),
		priority = priority,
		lifeTime = 0,
		identifier = identifier
	}

	return priority
end

local gradientU = ix.util.GetMaterial("vgui/gradient-u")
local gradientD = ix.util.GetMaterial("vgui/gradient-d")
local surface = surface
local draw = draw

local TEXT_COLOR = Color(240, 240, 240)
local SHADOW_COLOR = Color(20, 20, 20)

function ix.bar.Draw(x, y, w, h, value, color, text)
	local origX, origY = x, y
	
	ix.util.DrawBlurAt(x, y, w, h)

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

		draw.SimpleText(text, "ixSmallFont", x + 2, y + 2, SHADOW_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(text, "ixSmallFont", x, y, TEXT_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function ix.bar.DrawAction()
	local start, finish = ix.bar.actionStart, ix.bar.actionEnd
	local curTime = CurTime()
	local scrW, scrH = ScrW(), ScrH()

	if (finish > curTime) then
		local fraction = 1 - math.TimeFraction(start, finish, curTime)
		local alpha = fraction * 255

		if (alpha > 0) then
			local w, h = scrW * 0.35, 28
			local x, y = (scrW * 0.5) - (w * 0.5), (scrH * 0.725) - (h * 0.5)

			ix.util.DrawBlurAt(x, y, w, h)

			surface.SetDrawColor(35, 35, 35, 100)
			surface.DrawRect(x, y, w, h)

			surface.SetDrawColor(0, 0, 0, 120)
			surface.DrawOutlinedRect(x, y, w, h)

			surface.SetDrawColor(ix.config.Get("color"))
			surface.DrawRect(x + 4, y + 4, math.max(w * fraction, 8) - 8, h - 8)

			surface.SetDrawColor(200, 200, 200, 20)
			surface.SetMaterial(gradientD)
			surface.DrawTexturedRect(x + 4, y + 4, math.max(w * fraction, 8) - 8, h - 8)

			draw.SimpleText(ix.bar.actionText, "ixMediumFont", x + 2, y - 22, SHADOW_COLOR)
			draw.SimpleText(ix.bar.actionText, "ixMediumFont", x, y - 24, TEXT_COLOR)
		end
	end
end

local Approach = math.Approach

BAR_HEIGHT = 10

function ix.bar.DrawAll()
	ix.bar.totalHeight = 4

	if (hook.Run("ShouldHideBars")) then
		return
	end

	local w, h = surface.ScreenWidth() * 0.35, BAR_HEIGHT
	local x = 4
	local deltas = ix.bar.delta
	local frameTime = FrameTime()
	local curTime = CurTime()
	local updateValue = frameTime * 0.6

	for i = 1, #ix.bar.list do
		local bar = ix.bar.list[i]

		if (bar) then
			local realValue = bar.getValue()
			local value = Approach(deltas[i] or 0, realValue, updateValue)

			deltas[i] = value

			if (deltas[i] != realValue) then
				bar.lifeTime = curTime + 5
			end

			if (bar.lifeTime >= curTime or bar.visible or IX_CVAR_SHOWBARS:GetBool() or hook.Run("ShouldBarDraw", bar)) then
				ix.bar.Draw(x, ix.bar.totalHeight, w, h, value, bar.color, bar.text)
				ix.bar.totalHeight = ix.bar.totalHeight + h + 2
			end
		end
	end

	ix.bar.DrawAction()
end

do
	ix.bar.Add(function()
		return math.max(LocalPlayer():Health() / LocalPlayer():GetMaxHealth(), 0)
	end, Color(200, 50, 40), nil, "health")

	ix.bar.Add(function()
		return math.min(LocalPlayer():Armor() / 100, 1)
	end, Color(30, 70, 180), nil, "armor")
end

netstream.Hook("actBar", function(start, finish, text)
	if (!text) then
		ix.bar.actionStart = 0
		ix.bar.actionEnd = 0
	else
		if (text:sub(1, 1) == "@") then
			text = L2(text:sub(2)) or text
		end

		ix.bar.actionStart = start
		ix.bar.actionEnd = finish
		ix.bar.actionText = text:upper()
	end
end)
