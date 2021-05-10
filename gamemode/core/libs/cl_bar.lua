
ix.bar = ix.bar or {}
ix.bar.list = {}
ix.bar.delta = ix.bar.delta or {}
ix.bar.actionText = ""
ix.bar.actionStart = 0
ix.bar.actionEnd = 0
ix.bar.totalHeight = 0

-- luacheck: globals BAR_HEIGHT
BAR_HEIGHT = 10

function ix.bar.Get(identifier)
	for _, v in ipairs(ix.bar.list) do
		if (v.identifier == identifier) then
			return v
		end
	end
end

function ix.bar.Remove(identifier)
	local bar = ix.bar.Get(identifier)

	if (bar) then
		table.remove(ix.bar.list, bar.index)

		if (IsValid(ix.gui.bars)) then
			ix.gui.bars:RemoveBar(bar.panel)
		end
	end
end

function ix.bar.Add(getValue, color, priority, identifier)
	if (identifier) then
		ix.bar.Remove(identifier)
	end

	local index = #ix.bar.list + 1

	color = color or Color(math.random(150, 255), math.random(150, 255), math.random(150, 255))
	priority = priority or index

	ix.bar.list[index] = {
		index = index,
		color = color,
		priority = priority,
		GetValue = getValue,
		identifier = identifier,
		panel = IsValid(ix.gui.bars) and ix.gui.bars:AddBar(index, color, priority)
	}

	return priority
end

local gradientD = ix.util.GetMaterial("vgui/gradient-d")

local TEXT_COLOR = Color(240, 240, 240)
local SHADOW_COLOR = Color(20, 20, 20)

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
	ix.bar.actionText = text:utf8upper()
end)

net.Receive("ixActionBarReset", function()
	ix.bar.actionStart = 0
	ix.bar.actionEnd = 0
	ix.bar.actionText = ""
end)
