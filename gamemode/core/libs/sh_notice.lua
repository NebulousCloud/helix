if (SERVER) then
	-- Sends a notification to a specified recipient.
	function nut.util.notify(message, recipient)
		netstream.Start(recipient, "notify", message)
	end

	do
		local playerMeta = FindMetaTable("Player")

		-- Utility function to notify a player.
		function playerMeta:notify(message)
			nut.util.notify(message, self)
		end
	end
else
	-- List of notice panels.
	nut.notices = nut.notices or {}

	-- Create a notification panel.
	function nut.util.notify(message)
		local notice = vgui.Create("nutNotice")
		local i = table.insert(nut.notices, notice)
		local scrW = ScrW()

		-- Set up information for the notice.
		notice:SetText(message)
		notice:SetPos(ScrW(), (i - 1) * (notice:GetTall() + 4) + 4)
		notice:SizeToContentsX()
		notice:SetWide(notice:GetWide() + 16)
		notice.start = CurTime() + 0.5
		notice.endTime = CurTime() + 8

		-- Move all notices to their proper positions.
		local function OrganizeNotices()
			for k, v in ipairs(nut.notices) do
				v:MoveTo(scrW - (v:GetWide() + 4), (k - 1) * (v:GetTall() + 4) + 4, 0.25, (k / #nut.notices) * 0.25 + 0.5, nil)
			end
		end

		-- Add the notice we made to the list.
		OrganizeNotices()

		-- Once the notice appears, make a sound and message.
		timer.Simple(0.5, function()
			surface.PlaySound("buttons/button14.wav")
			MsgC(Color(0, 255, 255), message.."\n")
		end)

		-- After the notice has displayed for 7.5 seconds, remove it.
		timer.Simple(8, function()
			if (IsValid(notice)) then
				-- Search for the notice to remove.
				for k, v in ipairs(nut.notices) do
					if (v == notice) then
						-- Move the notice off the screen.
						notice:MoveTo(ScrW(), notice.y, 0.25, 0.5, nil, function()
							notice:Remove()
						end)

						-- Remove the notice from the list and move other notices.
						table.remove(nut.notices, k)
						OrganizeNotices()

						break
					end
				end
			end
		end)
	end

	-- Receives a notification from the server.
	netstream.Hook("notify", function(message)
		nut.util.notify(message)
	end)
end