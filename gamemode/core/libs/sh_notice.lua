
if (SERVER) then
	-- Sends a notification to a specified recipient.
	function ix.util.Notify(message, recipient)
		netstream.Start(recipient, "notify", message)
	end

	-- Sends a translated notification.
	function ix.util.NotifyLocalized(message, recipient, ...)
		netstream.Start(recipient, "notifyL", message, ...)
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
	end
else
	-- List of notice panels.
	ix.notices = ix.notices or {}
	
	-- Move all notices to their proper positions.
	local function OrganizeNotices()
		for k, v in ipairs(ix.notices) do
			v:MoveTo(ScrW() - (v:GetWide() + 4), (k - 1) * (v:GetTall() + 4) + 4, 0.15, (k / #ix.notices) * 0.25, nil)
		end
	end
	
	-- Create a notification panel.
	function ix.util.Notify(message)
		if (ix.option.Get("chatNotices", false)) then
			ix.chat.Send(LocalPlayer(), "notice", message)
			return
		end

		local notice = vgui.Create("ixNotice")
		local i = table.insert(ix.notices, notice)

		-- Set up information for the notice.
		notice:SetText(message)
		notice:SetPos(ScrW(), (i - 1) * (notice:GetTall() + 4) + 4)
		notice:SizeToContentsX()
		notice:SetWide(notice:GetWide() + 16)
		notice.start = CurTime() + 0.25
		notice.endTime = CurTime() + 7.75

		-- Add the notice we made to the list.
		OrganizeNotices()

		-- Show the notification in the console.
		MsgC(Color(0, 255, 255), message.."\n")

		-- Once the notice appears, make a sound and message.
		timer.Simple(0.15, function()
			surface.PlaySound("buttons/button14.wav")
		end)

		-- After the notice has displayed for 7.5 seconds, remove it.
		timer.Simple(7.75, function()
			if (IsValid(notice)) then
				-- Search for the notice to remove.
				for k, v in ipairs(ix.notices) do
					if (v == notice) then
						-- Move the notice off the screen.
						notice:MoveTo(ScrW(), notice.y, 0.15, 0.1, nil, function()
							notice:Remove()
						end)

						-- Remove the notice from the list and move other notices.
						table.remove(ix.notices, k)
						OrganizeNotices()

						break
					end
				end
			end
		end)
	end

	-- Creates a translated notification.
	function ix.util.NotifyLocalized(message, ...)
		ix.util.Notify(L(message, ...))
	end

	-- Receives a notification from the server.
	netstream.Hook("notify", ix.util.Notify)

	-- Receives a notification from the server.
	netstream.Hook("notifyL", ix.util.NotifyLocalized)
end
