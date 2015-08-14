PLUGIN.name = "Typing Indicator"
PLUGIN.desc = "Shows some text when someone types."
PLUGIN.author = "Chessnut"

if (CLIENT) then
	local TYPE_OFFSET = Vector(0, 0, 80)
	local TYPE_OFFSET_CROUCHED = Vector(0, 0, 48)
	local TYPE_COLOR = Color(250, 250, 250)

	function PLUGIN:StartChat()
		netstream.Start("typeStatus", 1)
	end

	function PLUGIN:FinishChat()
		netstream.Start("typeStatus")
	end

	local data = {}

	function PLUGIN:HUDPaint()
		local ourPos = LocalPlayer():GetPos()
		local localPlayer = LocalPlayer()

		data.start = localPlayer:EyePos()

		for k, v in ipairs(player.GetAll()) do
			if (v != localPlayer and v:getNetVar("typing") and v:GetMoveType() == MOVETYPE_WALK) then
				data.endpos = v:EyePos()

				if (util.TraceLine(data).Entity == v) then
					local position = v:GetPos()
					local alpha = (1 - (ourPos:DistToSqr(position) / 65536)) * 255

					if (alpha > 0) then
						local screen = (position + (v:Crouching() and TYPE_OFFSET_CROUCHED or TYPE_OFFSET)):ToScreen()

						nut.util.drawText("(Typing)", screen.x, screen.y - 18, ColorAlpha(TYPE_COLOR, alpha), 1, 1, "nutChatFontItalics", alpha)
					end
				end
			end
		end
	end
else
	netstream.Hook("typeStatus", function(client, state)
		if (state) then
			state = true
		else
			state = nil
		end

		client:setNetVar("typing", state)
	end)
end