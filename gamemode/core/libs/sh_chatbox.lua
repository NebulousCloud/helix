
ix.chat = ix.chat or {}
ix.chat.classes = ix.char.classes or {}

if (!ix.command) then
	include("sh_command.lua")
end

-- Registers a new chat type with the information provided.
function ix.chat.Register(chatType, data)
	if (!data.OnCanHear) then
		-- Have a substitute if the canHear property is not found.
		function data:OnCanHear(speaker, listener)
			-- The speaker will be heard by everyone.
			return true
		end
	elseif (type(data.OnCanHear) == "number") then
		-- Use the value as a range and create a function to compare distances.
		local range = data.OnCanHear * data.OnCanHear

		function data:OnCanHear(speaker, listener)
			-- Length2DSqr is faster than Length2D, so just check the squares.
			return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= range
		end
	end

	-- Allow players to use this chat type by default.
	if (!data.OnCanSay) then
		function data:OnCanSay(speaker, text)
			if (!self.deadCanChat and !speaker:Alive()) then
				speaker:NotifyLocalized("noPerm")

				return false
			end

			return true
		end
	end

	-- Chat text color.
	data.color = data.color or Color(242, 230, 160)

	if (!data.OnChatAdd) then
		data.format = data.format or "%s: \"%s\""

		function data:OnChatAdd(speaker, text, anonymous, info)
			local color = self.color
			local name = anonymous and
				L"someone" or hook.Run("GetDisplayedName", speaker, chatType) or
				(IsValid(speaker) and speaker:Name() or "Console")

			if (self.OnGetColor) then
				color = self:OnGetColor(speaker, text)
			end

			local translated = L2(chatType.."Format", name, text)

			chat.AddText(color, translated or string.format(self.format, name, text))
		end
	end

	if (CLIENT and data.prefix) then
		if (type(data.prefix) == "table") then
			for _, v in ipairs(data.prefix) do
				if (v:sub(1, 1) == "/") then
					ix.command.Add(v:sub(2), {
						description = data.description,
						syntax = "<text message>",
						OnRun = function() end
					})
				end
			end
		else
			ix.command.Add(chatType, {
				description = data.description,
				syntax = "<text message>",
				OnRun = function() end
			})
		end
	end

	data.filter = data.filter or "ic"

	-- Add the chat type to the list of classes.
	ix.chat.classes[string.lower(chatType)] = data
end

-- Identifies which chat mode should be used.
function ix.chat.Parse(client, message, noSend)
	local anonymous = false
	local chatType = "ic"

	-- Loop through all chat classes and see if the message contains their prefix.
	for k, v in pairs(ix.chat.classes) do
		local isChosen = false
		local chosenPrefix = ""
		local noSpaceAfter = v.noSpaceAfter

		-- Check through all prefixes if the chat type has more than one.
		if (type(v.prefix) == "table") then
			for _, prefix in ipairs(v.prefix) do
				prefix = prefix:lower()

				-- Checking if the start of the message has the prefix.
				if (message:sub(1, #prefix + (noSpaceAfter and 0 or 1)):lower() == prefix..(noSpaceAfter and "" or " "):lower()) then
					isChosen = true
					chosenPrefix = prefix..(v.noSpaceAfter and "" or " ")

					break
				end
			end
		-- Otherwise the prefix itself is checked.
		elseif (type(v.prefix) == "string") then
			local prefix = v.prefix:lower()

			isChosen = message:sub(1, #prefix + (noSpaceAfter and 0 or 1)):lower() == prefix..(noSpaceAfter and "" or " "):lower()
			chosenPrefix = prefix..(v.noSpaceAfter and "" or " ")
		end

		-- If the checks say we have the proper chat type, then the chat type is the chosen one!
		-- If this is not chosen, the loop continues. If the loop doesn't find the correct chat
		-- type, then it falls back to IC chat as seen by the chatType variable above.
		if (isChosen) then
			-- Set the chat type to the chosen one.
			chatType = k
			-- Remove the prefix from the chat type so it does not show in the message.
			message = message:sub(#chosenPrefix + 1)

			if (ix.chat.classes[k].noSpaceAfter and message:sub(1, 1):match("%s")) then
				message = message:sub(2)
			end

			break
		end
	end

	if (!message:find("%S")) then
		return
	end

	-- Only send if needed.
	if (SERVER and !noSend) then
		-- Send the correct chat type out so other player see the message.
		ix.chat.Send(client, chatType, hook.Run("PlayerMessageSend", client, chatType, message, anonymous) or message, anonymous)
	end

	-- Return the chosen chat type and the message that was sent if needed for some reason.
	-- This would be useful if you want to send the message on your own.
	return chatType, message, anonymous
end

if (SERVER) then
	-- Send a chat message using the specified chat type.
	function ix.chat.Send(speaker, chatType, text, anonymous, receivers)
		local class = ix.chat.classes[chatType]

		if (class and class:OnCanSay(speaker, text) != false) then
			if (class.OnCanHear and !receivers) then
				receivers = {}

				for _, v in ipairs(player.GetAll()) do
					if (v:GetChar() and class:OnCanHear(speaker, v) != false) then
						receivers[#receivers + 1] = v
					end
				end

				if (#receivers == 0) then
					return
				end
			end

			-- Format the message if needed before we run the hook.
			local rawText = text
			local maxLength = ix.config.Get("chatMax")

			if (text:len() > maxLength) then
				text = text:sub(0, maxLength)
			end

			if (ix.config.Get("chatAutoFormat") and hook.Run("CanAutoFormatMessage", speaker, chatType, text)) then
				local last = text:sub(-1)

				if (last != "." and last != "?" and last != "!") then
					text = text .. "."
				end

				text = text:sub(1, 1):upper() .. text:sub(2)
			end

			netstream.Start(receivers, "cMsg", speaker, chatType,
				hook.Run("PlayerMessageSend", speaker, chatType, text, anonymous, receivers, rawText) or text,
				anonymous or false
			)
		end
	end
else
	function ix.chat.Send(speaker, chatType, text, anonymous, data)
		local class = ix.chat.classes[chatType]

		if (class) then
			-- luacheck: globals CHAT_CLASS
			CHAT_CLASS = class
				class:OnChatAdd(speaker, text, anonymous, data)
			CHAT_CLASS = nil
		end
	end

	-- Call OnChatAdd for the appropriate chatType.
	netstream.Hook("cMsg", function(client, chatType, text, anonymous)
		if (IsValid(client)) then
			local info = {
				chatType = chatType,
				text = text,
				anonymous = anonymous,
				data = {}
			}

			hook.Run("OnChatReceived", client, info)
			ix.chat.Send(client, info.chatType or chatType, info.text or text, info.anonymous or anonymous, info.data or {})
		else
			ix.chat.Send(nil, chatType, text, anonymous, {})
		end
	end)
end

-- Add the default chat types here.
do
	-- Load the chat types after the configs so we can access changed configs.
	hook.Add("InitializedConfig", "ixChatTypes", function()
		-- The default in-character chat.
		ix.chat.Register("ic", {
			format = "%s says \"%s\"",
			OnGetColor = function(self, speaker, text)
				-- If you are looking at the speaker, make it greener to easier identify who is talking.
				if (LocalPlayer():GetEyeTrace().Entity == speaker) then
					return ix.config.Get("chatListenColor")
				end

				-- Otherwise, use the normal chat color.
				return ix.config.Get("chatColor")
			end,
			OnCanHear = ix.config.Get("chatRange", 280)
		})

		-- Actions and such.
		ix.chat.Register("me", {
			format = "** %s %s",
			OnGetColor = ix.chat.classes.ic.OnGetColor,
			OnCanHear = ix.config.Get("chatRange", 280),
			prefix = {"/Me", "/Action"},
			description = "@cmdMe",
			filter = "actions",
			deadCanChat = true
		})

		-- Actions and such.
		ix.chat.Register("it", {
			OnChatAdd = function(self, speaker, text)
				chat.AddText(ix.config.Get("chatColor"), "** "..text)
			end,
			OnCanHear = ix.config.Get("chatRange", 280),
			prefix = {"/It"},
			description = "@cmdIt",
			filter = "actions",
			deadCanChat = true
		})

		-- Whisper chat.
		ix.chat.Register("w", {
			format = "%s whispers \"%s\"",
			OnGetColor = function(self, speaker, text)
				local color = ix.chat.classes.ic:OnGetColor(speaker, text)

				-- Make the whisper chat slightly darker than IC chat.
				return Color(color.r - 35, color.g - 35, color.b - 35)
			end,
			OnCanHear = ix.config.Get("chatRange", 280) * 0.25,
			prefix = {"/W", "/Whisper"},
			description = "@cmdW"
		})

		-- Yelling out loud.
		ix.chat.Register("y", {
			format = "%s yells \"%s\"",
			OnGetColor = function(self, speaker, text)
				local color = ix.chat.classes.ic:OnGetColor(speaker, text)

				-- Make the yell chat slightly brighter than IC chat.
				return Color(color.r + 35, color.g + 35, color.b + 35)
			end,
			OnCanHear = ix.config.Get("chatRange", 280) * 2,
			prefix = {"/Y", "/Yell"},
			description = "@cmdY"
		})

		-- Out of character.
		ix.chat.Register("ooc", {
			OnCanSay = function(self, speaker, text)
				if (!ix.config.Get("allowGlobalOOC")) then
					speaker:NotifyLocalized("Global OOC is disabled on this server.")
					return false
				else
					local delay = ix.config.Get("oocDelay", 10)

					-- Only need to check the time if they have spoken in OOC chat before.
					if (delay > 0 and speaker.ixLastOOC) then
						local lastOOC = CurTime() - speaker.ixLastOOC

						-- Use this method of checking time in case the oocDelay config changes.
						if (lastOOC <= delay) then
							speaker:NotifyLocalized("oocDelay", delay - math.ceil(lastOOC))

							return false
						end
					end

					-- Save the last time they spoke in OOC.
					speaker.ixLastOOC = CurTime()
				end
			end,
			OnChatAdd = function(self, speaker, text)
				local icon = "icon16/user.png"

				if (speaker:IsSuperAdmin()) then
					icon = "icon16/shield.png"
				elseif (speaker:IsAdmin()) then
					icon = "icon16/star.png"
				elseif (speaker:IsUserGroup("moderator") or speaker:IsUserGroup("operator")) then
					icon = "icon16/wrench.png"
				elseif (speaker:IsUserGroup("vip") or speaker:IsUserGroup("donator") or speaker:IsUserGroup("donor")) then
					icon = "icon16/heart.png"
				end

				icon = Material(hook.Run("GetPlayerIcon", speaker) or icon)

				chat.AddText(icon, Color(255, 50, 50), "[OOC] ", speaker, color_white, ": "..text)
			end,
			prefix = {"//", "/OOC"},
			description = "@cmdOOC",
			noSpaceAfter = true,
			filter = "ooc"
		})

		-- Local out of character.
		ix.chat.Register("looc", {
			OnCanSay = function(self, speaker, text)
				local delay = ix.config.Get("loocDelay", 0)

				-- Only need to check the time if they have spoken in OOC chat before.
				if (delay > 0 and speaker.ixLastLOOC) then
					local lastLOOC = CurTime() - speaker.ixLastLOOC

					-- Use this method of checking time in case the oocDelay config changes.
					if (lastLOOC <= delay) then
						speaker:NotifyLocalized("loocDelay", delay - math.ceil(lastLOOC))

						return false
					end
				end

				-- Save the last time they spoke in OOC.
				speaker.ixLastLOOC = CurTime()
			end,
			OnChatAdd = function(self, speaker, text)
				chat.AddText(Color(255, 50, 50), "[LOOC] ", ix.config.Get("chatColor"), speaker:Name()..": "..text)
			end,
			OnCanHear = ix.config.Get("chatRange", 280),
			prefix = {".//", "[[", "/LOOC"},
			description = "@cmdLOOC",
			noSpaceAfter = true,
			filter = "ooc"
		})

		-- Roll information in chat.
		ix.chat.Register("roll", {
			format = "%s has rolled %s.",
			color = Color(155, 111, 176),
			filter = "actions",
			OnCanHear = ix.config.Get("chatRange", 280),
			deadCanChat = true
		})

		-- run a hook after we add the basic chat classes so schemas/plugins can access their info as soon as possible if needed
		hook.Run("InitializedChatClasses")
	end)
end

-- Private messages between players.
ix.chat.Register("pm", {
	format = "[PM] %s: %s",
	color = Color(249, 211, 89),
	filter = "pm",
	deadCanChat = true
})

-- Global events.
ix.chat.Register("event", {
	OnCanSay = function(self, speaker, text)
		return speaker:IsAdmin()
	end,
	OnCanHear = 1000000,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 150, 0), text)
	end,
	prefix = {"/Event"},
	description = "@cmdEvent"
})

ix.chat.Register("connect", {
	OnCanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		local icon = ix.util.GetMaterial("icon16/user_add.png")

		chat.AddText(icon, Color(150, 150, 200), L("playerConnected", text))
	end,
	noSpaceAfter = true,
	filter = "ooc"
})

ix.chat.Register("disconnect", {
	OnCanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		local icon = ix.util.GetMaterial("icon16/user_delete.png")

		chat.AddText(icon, Color(200, 150, 200), L("playerDisconnected", text))
	end,
	noSpaceAfter = true,
	filter = "ooc"
})

ix.chat.Register("notice", {
	OnCanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		local icon = ix.util.GetMaterial("icon16/comment.png")
		chat.AddText(icon, Color(175, 200, 255), text)
	end,
	noSpaceAfter = true,
	filter = "ooc"
})

-- Why does ULX even have a /me command?
hook.Remove("PlayerSay", "ULXMeCheck")
