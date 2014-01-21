local PLUGIN = PLUGIN
local recognizeCommand = {
	syntax = "[string none|aim|whisper|yell]",
	onRun = function(client, arguments)
		local mode = arguments[1]

		if (mode) then
			mode = mode:lower()
		end

		if (mode and mode:find("aim")) then
			local data = {}
				data.start = client:GetShootPos()
				data.endpos = data.start + client:GetAimVector()*128
				data.filter = client
			local trace = util.TraceLine(data)
			local entity = trace.Entity

			if (IsValid(entity)) then
				PLUGIN:SetRecognized(client, entity)

				nut.util.Notify("The person you are looking at now recognizes you.", client)
			else
				nut.util.Notify("You are not looking at a valid player.", client)
			end
		else
			local range = nut.config.chatRange
			local text = "talking"

			if (mode and mode:find("whisper")) then
				range = nut.config.whisperRange
				text = "whispering"
			elseif (mode and mode:find("yell")) then
				range = nut.config.yellRange
				text = "yelling"
			end

			for k, v in pairs(player.GetAll()) do
				if (v:GetPos():Distance(client:GetPos()) <= range) then
					PLUGIN:SetRecognized(client, v)
				end
			end

			nut.util.Notify("People in a "..text.." range now recognize you.", client)
		end
	end
}

nut.command.Register(recognizeCommand, "recognize")
nut.command.Register(recognizeCommand, "recognise")
