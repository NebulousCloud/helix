nut.scroll = nut.scroll or {}
nut.scroll.buffer = nut.scroll.buffer or {}

local CHAR_DELAY = 0.1

if (CLIENT) then
	function nut.scroll.Add(text, callback)
		local index = table.insert(nut.scroll.buffer, {text = "", callback = callback})
		local i = 1
		local alpha = 1

		timer.Create("nut_Scroll"..index, CHAR_DELAY, string.len(text), function()
			if (!nut.scroll.buffer[index]) then
				return
			end
			
			nut.scroll.buffer[index].text = string.sub(text, 1, i)
			i = i + 1

			if (i == string.len(text)) then
				local buffer = nut.scroll.buffer

				timer.Simple(1, function()
					if (buffer[index]) then
						buffer[index].start = CurTime()
						buffer[index].finish = CurTime() + 3
					end
				end)
			end
		end)
	end

	local SCROLL_X = ScrW() * 0.9
	local SCROLL_Y = ScrH() * 0.7

	function nut.scroll.Paint()
		for k, v in pairs(nut.scroll.buffer) do
			local alpha = 255

			if (v.start and v.finish) then
				alpha = 255 - math.Clamp(math.TimeFraction(v.start, v.finish, CurTime()) * 255, 0, 255)
			end

			nut.util.DrawText(SCROLL_X, SCROLL_Y - (k * 24), v.text, Color(255, 255, 255, alpha), nil, 2, 1)

			if (alpha == 0) then
				if (v.callback) then
					v.callback()
				end

				table.remove(nut.scroll.buffer, k)
			end
		end
	end

	net.Receive("nut_ScrollData", function(length)
		nut.scroll.Add(net.ReadString())
	end)
else
	util.AddNetworkString("nut_ScrollData")

	function nut.scroll.Send(text, receiver, callback)
		net.Start("nut_ScrollData")
			net.WriteString(text)
		if (receiver) then
			net.Send(receiver)
		else
			net.Broadcast()
		end

		timer.Simple(CHAR_DELAY*string.len(text) + 4, function()
			if (callback) then
				callback()
			end
		end)
	end
end