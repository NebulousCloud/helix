nut.chat = nut.chat or {}
nut.chat.classes = nut.char.classes or {}

-- Registers a new chat type with the information provided.
function nut.chat.register(chatType, data)
	if (!data.canHear) then
		-- Have a substitute if the canHear property is not found.
		data.canHear = function(speaker, listener)
			-- The speaker will be heard by everyone.
			return true
		end
	elseif (type(data.canHear) == "number") then
		-- Use the value as a range and create a function to compare distances.
		local range = data.canHear ^ 2

		data.canHear = function(speaker, listener)
			-- Length2DSqr is faster than Length2D, so just check the squares.
			return (speaker:GetPos() - listener:GetPos()):Length2DSqr() <= range
		end
	end

	-- Allow players to use this chat type by default.
	if (!data.canSay) then
		data.canSay = function(speaker, text)
			return true
		end
	end

	-- Chat text color.
	data.color = data.color or Color(242, 230, 160)

	if (!data.onChatAdd) then
		data.format = data.format or "%s says \"%s\""
		
		data.onChatAdd = function(speaker, text)
			chat.AddText(data.color, string.format(data.format, speaker:Name(), text))
		end
	end

	-- Add the chat type to the list of classes.
	nut.chat.classes[chatType] = data
end

if (SERVER) then
	-- Send a chat message using the specified chat type.
	function nut.chat.send(speaker, chatType, text)
		local class = nut.chat.classes[chatType]

		if (class and class.canSay(speaker, text) != false) then
			local receivers = {}

			for k, v in ipairs(player.GetAll()) do
				if (class.canHear(client, v) != false) then
					receivers[#receivers + 1] = v
				end
			end

			netstream.Start(receivers, "cMsg", speaker, chatType, text)
		end
	end
else
	-- Call onChatAdd for the appropriate chatType.
	netstream.Hook("cMsg", function(client, chatType, text)
		if (IsValid(client)) then
			local class = nut.chat.classes[chatType]

			if (class) then
				class.onChatAdd(client, text)
			end
		end
	end)
end