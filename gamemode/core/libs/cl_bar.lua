nut.bar = nut.bar or {}
nut.bar.list = {}
nut.bar.delta = nut.bar.delta or {}

function nut.bar.add(getValue, color, priority)
	priority = priority or table.Count(nut.bar.list) + 1

	
	local info = nut.bar.list[priority]

	nut.bar.list[priority] = {
		getValue = getValue,
		color = color or info.color or Color(math.random(150, 255), math.random(150, 255), math.random(150, 255)),
		priority = priority,
		lifeTime = 0
	}

	return priority
end

local color_dark = Color(0, 0, 0, 225)
local gradient = nut.util.getMaterial("vgui/gradient-u")
local gradient2 = nut.util.getMaterial("vgui/gradient-d")

function nut.bar.draw(x, y, w, h, value, color)
	surface.SetDrawColor(25, 25, 25, 240)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(255, 255, 255, 5)
	surface.SetMaterial(gradient2)
	surface.DrawTexturedRect(x, y, w, h)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawOutlinedRect(x, y, w, h)

	x, y, w, h = x + 2, y + 2, (w - 4) * value, h - 4

	surface.SetDrawColor(color.r, color.g, color.b, 250)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(255, 255, 255, 8)
	surface.SetMaterial(gradient)
	surface.DrawTexturedRect(x, y, w, h)
end	

local Approach = math.Approach

function nut.bar.drawAll()
	local w, h = surface.ScreenWidth() * 0.35, 10
	local x, y = 4, 4
	local deltas = nut.bar.delta
	local frameTime = FrameTime()
	local curTime = CurTime()

	for k, v in ipairs(nut.bar.list) do
		local realValue = v.getValue()
		local value = Approach(deltas[k] or 0, realValue, frameTime * 0.6)

		deltas[k] = value

		if (deltas[k] != realValue) then
			v.lifeTime = curTime + 5
		end

		if (v.lifeTime >= curTime) then
			nut.bar.draw(x, y, w, h, value, v.color)
			y = y + (h + 2)
		end
	end
end

do
	nut.bar.add(function()
		return LocalPlayer():Health() / LocalPlayer():GetMaxHealth()
	end, Color(200, 50, 40))

	nut.bar.add(function()
		return math.min(LocalPlayer():Armor() / 100, 1)
	end, Color(30, 70, 180))
end