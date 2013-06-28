nut.scroll = nut.scroll or {}
nut.scroll.buffer = nut.scroll.buffer or {}

if (CLIENT) then
	local CHAR_DELAY = 0.1
	local CURRENT_INDEX = 1

	function nut.scroll.Add(text)
		CURRENT_INDEX = CURRENT_INDEX + 1
		local index = CURRENT_INDEX

		nut.scroll.buffer[index] = {text = "", alpha = 255}

		local i = 1
		local alpha = 1

		timer.Create("nut_Scroll"..index, CHAR_DELAY, string.len(text), function()
			nut.scroll.buffer[index].text = string.sub(text, 1, i)
			i = i + 1

			if (i == string.len(text)) then
				timer.Simple(5, function()
					local alpha = 255
					local uniqueID = "nut_ScrollFadeOut"..index

					timer.Create(uniqueID, 0, 0, function()
						if (!nut.scroll.buffer[index]) then
							timer.Remove(uniqueID)

							return
						end

						nut.scroll.buffer[index].alpha = alpha
						alpha = alpha - 1

						if (alpha <= 0) then
							nut.scroll.buffer[index] = nil

							timer.Remove(uniqueID)
						end
					end)
				end)
			end
		end)
	end

	local SCROLL_X = ScrW() * 0.9
	local SCROLL_Y = ScrH() * 0.7

	function nut.scroll.Paint()
		local i = 0

		for _, v in pairs(nut.scroll.buffer) do
			nut.util.DrawText(SCROLL_X, SCROLL_Y - (i * 24), v.text, Color(255, 255, 255, v.alpha), nil, 2, 1)
			i = i + 1
		end
	end

	net.Receive("nut_ScrollData", function(length)
		nut.scroll.Add(net.ReadString())
	end)
else
	util.AddNetworkString("nut_ScrollData")

	function nut.scroll.Send(text, receiver)
		net.Start("nut_ScrollData")
			net.WriteString(text)
		if (receiver) then
			net.Send(receiver)
		else
			net.Broadcast()
		end
	end
end