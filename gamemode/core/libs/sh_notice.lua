
if (SERVER) then
	util.AddNetworkString("ixNotify")
	util.AddNetworkString("ixNotifyLocalized")

	-- Sends a notification to a specified recipient.
	function ix.util.Notify(message, recipient)
		net.Start("ixNotify")
		net.WriteString(message)

		if (recipient == nil) then
			net.Broadcast()
		else
			net.Send(recipient)
		end
	end

	-- Sends a translated notification.
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
		local playerMeta = FindMetaTable("Player")

		-- Utility function to notify a player.
		function playerMeta:Notify(message)
			ix.util.Notify(message, self)
		end

		-- Utility function to notify a localized message to a player.
		function playerMeta:NotifyLocalized(message, ...)
			ix.util.NotifyLocalized(message, self, ...)
		end

		function playerMeta:ChatNotify(message)
			ix.chat.Send(nil, "notice", message, false, {self})
		end

		function playerMeta:ChatNotifyLocalized(message, ...)
			ix.chat.Send(nil, "notice", L(message, self, ...), false, {self})
		end
	end
else
	-- Create a notification panel.
	function ix.util.Notify(message)
		if (ix.option.Get("chatNotices", false)) then
			ix.chat.Send(LocalPlayer(), "notice", message, false, {
				bError = message:sub(#message, #message) == "!"
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
				ix.chat.Send(LocalPlayer(), "notice", message)
			end
		end

		function playerMeta:ChatNotifyLocalized(message, ...)
			if (self == LocalPlayer()) then
				ix.chat.Send(LocalPlayer(), "notice", L(message, ...))
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
