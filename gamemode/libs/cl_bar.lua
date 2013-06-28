--[[
	Purpose: A library to draw bars on the HUD and add bars to the list. This is used since
	it will make it easier for bars to be organized in drawing, otherwise it would be random
	each frame and would look like it is flickering. It can also be used for plugins to display
	other stuff, such as the stamina plugin.
--]]

nut.bar = nut.bar or {}
nut.bar.buffer = nut.bar.buffer or {}

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