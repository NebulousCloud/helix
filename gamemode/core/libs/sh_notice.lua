
--- Notification helper functions
-- @module ix.notice

if (SERVER) then
	util.AddNetworkString("ixNotify")
	util.AddNetworkString("ixNotifyLocalized")

	--- Sends a notification to a specified recipient.
	-- @realm server
	-- @string message Message to notify
	-- @player[opt=nil] recipient Player to be notified
	function ix.util.Notify(message, recipient)
		net.Start("ixNotify")
		net.WriteString(message)

		if (recipient == nil) then
			net.Broadcast()
		else
			net.Send(recipient)
		end
	end

	--- Sends a translated notification to a specified recipient.
	-- @realm server
	-- @string message Message to notify
	-- @player[opt=nil] recipient Player to be notified
	-- @param ... Arguments to pass to the translated message
	function ix.util.NotifyLocalized(message, recipient, ...)
		net.Start("ixNotifyLocalized")
		net.WriteString(message)
		net.WriteTable({...})

		if (recipient == nil) then
			net.Broadcast()
		else
			net.Send(recipient)
		end
	end

	do
		--- Notification util functions for players
		-- @classmod Player

		local playerMeta = FindMetaTable("Player")

		--- Displays a prominent notification in the top-right of this player's screen.
		-- @realm shared
		-- @string message Text to display in the notification
		function playerMeta:Notify(message)
			ix.util.Notify(message, self)
		end

		--- Displays a notification for this player with the given language phrase.
		-- @realm shared
		-- @string message ID of the phrase to display to the player
		-- @param ... Arguments to pass to the phrase
		-- @usage client:NotifyLocalized("mapRestarting", 10)
		-- -- displays "The map will restart in 10 seconds!" if the player's language is set to English
		-- @see ix.lang
		function playerMeta:NotifyLocalized(message, ...)
			ix.util.NotifyLocalized(message, self, ...)
		end

		--- Displays a notification for this player in the chatbox.
		-- @realm shared
		-- @string message Text to display in the notification
		function playerMeta:ChatNotify(message)
			local messageLength = message:utf8len()

			ix.chat.Send(nil, "notice", message, false, {self}, {
				bError = message:utf8sub(messageLength, messageLength) == "!"
			})
		end

		--- Displays a notification for this player in the chatbox with the given language phrase.
		-- @realm shared
		-- @string message ID of the phrase to display to the player
		-- @param ... Arguments to pass to the phrase
		-- @see NotifyLocalized
		function playerMeta:ChatNotifyLocalized(message, ...)
			message = L(message, self, ...)

			local messageLength = message:utf8len()

			ix.chat.Send(nil, "notice", message, false, {self}, {
				bError = message:utf8sub(messageLength, messageLength) == "!"
			})
		end
	end
else
	-- Create a notification panel.
	function ix.util.Notify(message)
		if (ix.option.Get("chatNotices", false)) then
			local messageLength = message:utf8len()

			ix.chat.Send(LocalPlayer(), "notice", message, false, {
				bError = message:utf8sub(messageLength, messageLength) == "!"
			})

			return
		end

		if (IsValid(ix.gui.notices)) then
			ix.gui.notices:AddNotice(message)
		end

		MsgC(Color(0, 255, 255), message .. "\n")
	end

	-- Creates a translated notification.
	function ix.util.NotifyLocalized(message, ...)
		ix.util.Notify(L(message, ...))
	end

	-- shortcut notify functions
	do
		local playerMeta = FindMetaTable("Player")

		function playerMeta:Notify(message)
			if (self == LocalPlayer()) then
				ix.util.Notify(message)
			end
		end

		function playerMeta:NotifyLocalized(message, ...)
			if (self == LocalPlayer()) then
				ix.util.NotifyLocalized(message, ...)
			end
		end

		function playerMeta:ChatNotify(message)
			if (self == LocalPlayer()) then
				local messageLength = message:utf8len()

				ix.chat.Send(LocalPlayer(), "notice", message, false, {
					bError = message:utf8sub(messageLength, messageLength) == "!"
				})
			end
		end

		function playerMeta:ChatNotifyLocalized(message, ...)
			if (self == LocalPlayer()) then
				message = L(message, ...)

				local messageLength = message:utf8len()

				ix.chat.Send(LocalPlayer(), "notice", message, false, {
					bError = message:utf8sub(messageLength, messageLength) == "!"
				})
			end
		end
	end

	-- Receives a notification from the server.
	net.Receive("ixNotify", function()
		ix.util.Notify(net.ReadString())
	end)

	-- Receives a notification from the server.
	net.Receive("ixNotifyLocalized", function()
		ix.util.NotifyLocalized(net.ReadString(), unpack(net.ReadTable()))
	end)
end
