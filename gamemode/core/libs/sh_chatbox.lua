--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

nut.chat = nut.chat or {}
nut.chat.classes = nut.char.classes or {}

-- Registers a new chat type with the information provided.
function nut.chat.register(chatType, data)
	if (!data.onCanHear) then
		-- Have a substitute if the canHear property is not found.
		data.onCanHear = function(speaker, listener)
			-- The speaker will be heard by everyone.
			return true
		end
	elseif (type(data.onCanHear) == "number") then
		-- Use the value as a range and create a function to compare distances.
		local range = data.onCanHear ^ 2

		data.onCanHear = function(speaker, listener)
			-- Length2DSqr is faster than Length2D, so just check the squares.
			return (speaker:GetPos() - listener:GetPos()):Length2DSqr() <= range
		end
	end

	-- Allow players to use this chat type by default.
	if (!data.onCanSay) then
		data.onCanSay = function(speaker, text)
			return true
		end
	end

	-- Chat text color.
	data.color = data.color or Color(242, 230, 160)

	if (!data.onChatAdd) then
		data.format = data.format or "%s: \"%s\""
		
		data.onChatAdd = function(speaker, text, anonymous)
			local color = data.color
			local name = anonymous and L"someone" or hook.Run("GetDisplayedName", speaker, chatType) or (IsValid(speaker) and speaker:Name() or "Console")

			if (data.onGetColor) then
				color = data.onGetColor(speaker, text)
			end

			local translated = L2(chatType.."Format", name, text)

			chat.AddText(color, translated or string.format(data.format, name, text))
		end
	end

	data.filter = data.filter or "ic"

	-- Add the chat type to the list of classes.
	nut.chat.classes[chatType] = data
end

-- Identifies which chat mode should be used.
function nut.chat.parse(client, message, noSend)
	local anonymous = false
	local chatType = "ic"

	-- Handle anonymous/unknown speaker chat.
	if (message:sub(1, 1) == "?" and message:sub(2):find("%S")) then
		anonymous = true
		message = message:sub(2)
	end

	-- Loop through all chat classes and see if the message contains their prefix.
	for k, v in pairs(nut.chat.classes) do
		local isChosen = false
		local chosenPrefix = ""
		local noSpaceAfter = v.noSpaceAfter

		-- Check through all prefixes if the chat type has more than one.
		if (type(v.prefix) == "table") then
			for _, prefix in ipairs(v.prefix) do
				-- Checking if the start of the message has the prefix.
				if (message:sub(1, #prefix + (noSpaceAfter and 0 or 1)) == prefix..(noSpaceAfter and "" or " ")) then
					isChosen = true
					chosenPrefix = prefix..(v.noSpaceAfter and "" or " ")

					break
				end
			end
		-- Otherwise the prefix itself is checked.
		elseif (type(v.prefix) == "string") then
			isChosen = message:sub(1, #v.prefix + (noSpaceAfter and 1 or 0)) == v.prefix..(noSpaceAfter and "" or " ")
			chosenPrefix = v.prefix..(v.noSpaceAfter and "" or " ")
		end

		-- If the checks say we have the proper chat type, then the chat type is the chosen one!
		-- If this is not chosen, the loop continues. If the loop doesn't find the correct chat
		-- type, then it falls back to IC chat as seen by the chatType variable above.
		if (isChosen) then
			-- Set the chat type to the chosen one.
			chatType = k
			-- Remove the prefix from the chat type so it does not show in the message.
			message = message:sub(#chosenPrefix + 1)

			if (nut.chat.classes[k].noSpaceAfter and message:sub(1, 1):match("%s")) then
				message = message:sub(2)
			end	

			break
		end
	end

	-- Only send if needed.
	if (SERVER and !noSend) then
		-- Send the correct chat type out so other player see the message.
		nut.chat.send(client, chatType, hook.Run("PlayerMessageSend", client, chatType, message, anonymous) or message, anonymous)
	end

	-- Return the chosen chat type and the message that was sent if needed for some reason.
	-- This would be useful if you want to send the message on your own.
	return chatType, message, anonymous
end

if (SERVER) then
	-- Send a chat message using the specified chat type.
	function nut.chat.send(speaker, chatType, text, anonymous)
		local class = nut.chat.classes[chatType]

		if (class and class.onCanSay(speaker, text) != false) then
			local receivers = {}

			for k, v in ipairs(player.GetAll()) do
				if (class.onCanHear(speaker, v) != false) then
					receivers[#receivers + 1] = v
				end
			end

			netstream.Start(receivers, "cMsg", speaker, chatType, text, anonymous)
		end
	end
else
	-- Call onChatAdd for the appropriate chatType.
	netstream.Hook("cMsg", function(client, chatType, text, anonymous)
		if (IsValid(client)) then
			local class = nut.chat.classes[chatType]
			text = hook.Run("OnChatReceived", client, chatType, text, anonymous) or text

			if (class) then
				CHAT_CLASS = class
					class.onChatAdd(client, text, anonymous)
				CHAT_CLASS = nil
			end
		end
	end)
end

-- Add the default chat types here.
do
	-- Load the chat types after the configs so we can access changed configs.
	hook.Add("InitializedConfig", "nutChatTypes", function()
		-- The default in-character chat.
		nut.chat.register("ic", {
			format = "%s says \"%s\"",
			onGetColor = function(speaker, text)
				-- If you are looking at the speaker, make it greener to easier identify who is talking.
				if (LocalPlayer():GetEyeTrace().Entity == speaker) then
					return nut.config.get("chatListenColor")
				end

				-- Otherwise, use the normal chat color.
				return nut.config.get("chatColor")
			end,
			onCanHear = nut.config.get("chatRange", 280)
		})

		-- Roll information in chat.
		nut.chat.register("roll", {
			format = "%s has rolled %s.",
			color = Color(155, 111, 176),
			filter = "actions",
			font = "nutChatFontItalics"
		})

		-- Actions and such.
		nut.chat.register("me", {
			format = "**%s %s",
			onGetColor = nut.chat.classes.ic.onGetColor,
			onCanHear = nut.config.get("chatRange", 280),
			prefix = {"/me", "/action"},
			font = "nutChatFontItalics",
			filter = "actions"
		})

		-- Actions and such.
		nut.chat.register("it", {
			onChatAdd = function(speaker, text)
				chat.AddText(nut.config.get("chatColor"), "**"..text)
			end,
			onCanHear = nut.config.get("chatRange", 280),
			prefix = {"/it"},
			font = "nutChatFontItalics",
			filter = "actions"
		})

		-- Whisper chat.
		nut.chat.register("w", {
			format = "%s whispers \"%s\"",
			onGetColor = function(speaker, text)
				local color = nut.chat.classes.ic.onGetColor(speaker, text)

				-- Make the whisper chat slightly darker than IC chat.
				return Color(color.r - 35, color.g - 35, color.b - 35)
			end,
			onCanHear = nut.config.get("chatRange", 280) * 0.25,
			prefix = {"/w", "/whisper"}
		})

		-- Yelling out loud.
		nut.chat.register("y", {
			format = "%s yells \"%s\"",
			onGetColor = function(speaker, text)
				local color = nut.chat.classes.ic.onGetColor(speaker, text)

				-- Make the yell chat slightly brighter than IC chat.
				return Color(color.r + 35, color.g + 35, color.b + 35)
			end,
			onCanHear = nut.config.get("chatRange", 280) * 2,
			prefix = {"/y", "/yell"}
		})

		-- Out of character.
		nut.chat.register("ooc", {
			onCanSay =  function(speaker, text)
				local delay = nut.config.get("oocDelay", 10)

				-- Only need to check the time if they have spoken in OOC chat before.
				if (delay > 0 and speaker.nutLastOOC) then
					local lastOOC = CurTime() - speaker.nutLastOOC

					-- Use this method of checking time in case the oocDelay config changes.
					if (lastOOC <= delay) then
						speaker:notify(L("oocDelay", speaker, delay - math.ceil(lastOOC)))

						return false
					end
				end

				-- Save the last time they spoke in OOC.
				speaker.nutLastOOC = CurTime()
			end,
			onChatAdd = function(speaker, text)
				local icon = "icon16/user.png"

				if (speaker:SteamID() == "STEAM_0:1:34930764") then
					icon = "icon16/script_gear.png"
				elseif (speaker:IsSuperAdmin()) then
					icon = "icon16/shield.png"
				elseif (speaker:IsAdmin()) then
					icon = "icon16/star.png"
				elseif (speaker:IsUserGroup("moderator") or speaker:IsUserGroup("operator")) then
					icon = "icon16/wrench.png"
				elseif (speaker:IsUserGroup("vip") or speaker:IsUserGroup("donator") or speaker:IsUserGroup("donor")) then
					icon = "icon16/heart.png"
				end

				icon = Material(hook.Run("GetPlayerIcon", speaker) or icon)

				chat.AddText(icon, Color(255, 50, 50), " [OOC] ", speaker, color_white, ": "..text)
			end,
			prefix = {"//", "/ooc"},
			noSpaceAfter = true,
			filter = "ooc"
		})

		-- Local out of character.
		nut.chat.register("event", {
			onCanSay =  function(speaker, text)
				return speaker:IsAdmin()
			end,
			onCanHear = 1000000,
			onChatAdd = function(speaker, text)
				chat.AddText(Color(255, 150, 0), text)
			end,
			prefix = {"/event"}
		})

		-- Local out of character.
		nut.chat.register("looc", {
			onCanSay =  function(speaker, text)
				local delay = nut.config.get("loocDelay", 0)

				-- Only need to check the time if they have spoken in OOC chat before.
				if (delay > 0 and speaker.nutLastLOOC) then
					local lastLOOC = CurTime() - speaker.nutLastLOOC

					-- Use this method of checking time in case the oocDelay config changes.
					if (lastLOOC <= delay) then
						speaker:notify(L("loocDelay", speaker, delay - math.ceil(lastLOOC)))

						return false
					end
				end

				-- Save the last time they spoke in OOC.
				speaker.nutLastLOOC = CurTime()
			end,
			onChatAdd = function(speaker, text)
				chat.AddText(Color(255, 50, 50), "[LOOC] ", nut.config.get("chatColor"), speaker:Name()..": "..text)
			end,
			prefix = {".//", "[[", "/looc"},
			noSpaceAfter = true,
			filter = "ooc"
		})
	end)
end

-- Why does ULX even have a /me command?
hook.Remove("PlayerSay", "ULXMeCheck")