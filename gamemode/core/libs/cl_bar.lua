
ix.bar = ix.bar or {}
ix.bar.list = {}
ix.bar.delta = ix.bar.delta or {}
ix.bar.actionText = ""
ix.bar.actionStart = 0
ix.bar.actionEnd = 0
ix.bar.totalHeight = 0

function ix.bar.Get(identifier)
	for i = 1, #ix.bar.list do
		local bar = ix.bar.list[i]

		if (bar and bar.identifier == identifier) then
			return bar
		end
	end
end

function ix.bar.Remove(identifier)
	local bar = ix.bar.Get(identifier)

	if (bar) then
		table.remove(ix.bar.list, bar.priority)
	end
end

function ix.bar.Add(getValue, color, priority, identifier)
	if (identifier) then
		ix.bar.Remove(identifier)
	end

	priority = priority or table.Count(ix.bar.list) + 1

	local info = ix.bar.list[priority]

	ix.bar.list[priority] = {
		GetValue = getValue,
		color = color or info.color or Color(math.random(150, 255), math.random(150, 255), math.random(150, 255)),
		priority = priority,
		lifeTime = 0,
		identifier = identifier,
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
	local menu = IsValid(ix.gui.menu) and ix.gui.menu
	local fraction = menu and 1 - menu.currentAlpha / 255 or 1

	if (menu and fraction <= 0) then
		return
	end

	local origX, origY, origW = x, y, w

	surface.SetDrawColor(230, 230, 230, 15 * fraction)
	surface.DrawRect(x, y, w, h)
	surface.DrawOutlinedRect(x, y, w, h)

	x, y, w, h = origX + 2, origY + 2, (w - 4) * math.min(value, 1), h - 4

	surface.SetDrawColor(color.r, color.g, color.b, 250 * fraction)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(230, 230, 230, 8 * fraction)
	surface.SetMaterial(gradientU)
	surface.DrawTexturedRect(x, y, w, h)

	if (isstring(text)) then
		x, y = origW * 0.5, origY + (h * 0.5)

		surface.SetFont("ixSmallFont")
		local textWidth, textHeight = surface.GetTextSize(text)

		surface.SetTextColor(ColorAlpha(SHADOW_COLOR, 255 * fraction))
		surface.SetTextPos(math.max(6, x + 2 - textWidth * 0.5), y + 4 - textHeight * 0.5)
		surface.DrawText(text)

		surface.SetTextColor(ColorAlpha(TEXT_COLOR, 255 * fraction))
		surface.SetTextPos(math.max(4, x - textWidth * 0.5), y + 2 - textHeight * 0.5)
		surface.DrawText(text)
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

-- luacheck: globals BAR_HEIGHT
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
			local realValue, barText = bar.GetValue()
			if (realValue == false) then
				continue
			end
			deltas[i] = deltas[i] or 0
			local value = Approach(deltas[i], realValue, updateValue)
			-- fix for smooth bar changes (increase of 0.01 every 0.1sec for example)
			if (value == realValue and deltas[i] != realValue and realValue != 0 and realValue != 1) then
				value = deltas[i]
			end

			deltas[i] = value

			if (deltas[i] != realValue) then
				bar.lifeTime = curTime + 5
			end
			if (bar.lifeTime >= curTime or bar.visible or ix.option.Get("alwaysShowBars", false) or hook.Run("ShouldBarDraw", bar)) then
				ix.bar.Draw(x, ix.bar.totalHeight, w, h, value, bar.color, barText)
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

net.Receive("ixActionBar", function()
	local start, finish = net.ReadFloat(), net.ReadFloat()
	local text = net.ReadString()

	if (text:sub(1, 1) == "@") then
		text = L2(text:sub(2)) or text
	end

	ix.bar.actionStart = start
	ix.bar.actionEnd = finish
	ix.bar.actionText = text:upper()
end)

net.Receive("ixActionBarReset", function()
	ix.bar.actionStart = 0
	ix.bar.actionEnd = 0
	ix.bar.actionText = ""
end)
