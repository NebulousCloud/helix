--[[
	Purpose: A library to draw bars on the HUD and add bars to the list. This is used since
	it will make it easier for bars to be organized in drawing, otherwise it would be random
	each frame and would look like it is flickering. It can also be used for plugins to display
	other stuff, such as the stamina plugin.
--]]

nut.bar = nut.bar or {}

if (CLIENT) then
	nut.bar.buffer = nut.bar.buffer or {}
	nut.bar.mainStart = nut.bar.mainStart or 0
	nut.bar.mainFinish = nut.bar.mainFinish or 0
	nut.bar.mainText = nut.bar.mainText or ""
	nut.bar.mainAlpha = nut.bar.mainAlpha or 0

	--[[
		Purpose: Adds a bar to the list of bars to be drawn and defines an ID for it.
	--]]
	function nut.bar.Add(uniqueID, data)
		data.id = table.Count(nut.bar.buffer) + 1

		nut.bar.buffer[uniqueID] = data
	end

	--[[
		Purpose: Loops through the list of bars, sorted by their IDs, and draws them
		using nut:PaintBar(). It returns the y of the next bar that is to be drawn.
	--]]
	function nut.bar.Paint(x, y, width, height)
		for k, v in SortedPairsByMemberValue(nut.bar.buffer, "id", true) do
			if (v.getValue) then
				local realValue = v.getValue()

				v.deltaValue = math.Approach(v.deltaValue or 0, realValue, FrameTime() * 80)

				local color = v.color

				if (v.deltaValue != realValue) then
					color = Color(200, 200, 200, 100)
				end

				y = nut:PaintBar(v.deltaValue, color, x, y, width, height)
			end
		end

		return y
	end

	function nut.bar.SetMainBar(text, time)
		nut.bar.mainStart = CurTime()
		nut.bar.mainFinish = nut.bar.mainStart + time
		nut.bar.mainText = text
	end

	function nut.bar.KillMainBar()
		nut.bar.mainStart = 0
		nut.bar.mainFinish = 0
		nut.bar.mainText = ""
	end

	function nut.bar.PaintMain()
		local finish = nut.bar.mainFinish
		local approach = 0

		if (finish > CurTime()) then
			approach = 255
		end

		nut.bar.mainAlpha = math.Approach(nut.bar.mainAlpha, approach, FrameTime() * 360)

		local alpha = nut.bar.mainAlpha

		if (alpha > 0) then
			local fraction = 1 - math.TimeFraction(nut.bar.mainStart, finish, CurTime())
			local scrW, scrH = ScrW(), ScrH()
			local width, height = scrW * 0.4, scrH * 0.05
			local x, y = scrW*0.5 - width*0.5, scrH*0.5 - height*0.5
			local border = 4
			local color = nut.config.mainColor
			color.a = alpha

			surface.SetDrawColor(10, 10, 10, alpha * 0.25)
			surface.DrawOutlinedRect(x, y, width, height)

			surface.SetDrawColor(25, 25, 25, alpha * 0.78)
			surface.DrawRect(x, y, width, height)

			surface.SetDrawColor(color)
			surface.DrawRect(x + border, y + border, math.Clamp(width*fraction - border*2, 0, width), height - border*2)

			nut.util.DrawText(scrW * 0.5, scrH * 0.5, nut.bar.mainText, Color(255, 255, 255, alpha))
		end
	end

	net.Receive("nut_MainBar", function(length)
		local text = net.ReadString()
		local time = net.ReadUInt(16)

		if (time == 0) then
			nut.bar.KillMainBar()
		else
			nut.bar.SetMainBar(text, time)
		end
	end)
else
	util.AddNetworkString("nut_MainBar")

	local playerMeta = FindMetaTable("Player")

	function playerMeta:SetMainBar(text, time)
		text = text or ""
		time = time or 0

		net.Start("nut_MainBar")
			net.WriteString(text)
			net.WriteUInt(time, 16)
		net.Send(self)
	end
end