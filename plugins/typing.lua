
local PLUGIN = PLUGIN

PLUGIN.name = "Typing Indicator"
PLUGIN.description = "Shows an indicator when someone is typing."
PLUGIN.author = "`impulse"
PLUGIN.animationTime = 0.5

if (CLIENT) then
	local standingOffset = Vector(0, 0, 72)
	local crouchingOffset = Vector(0, 0, 38)
	local boneOffset = Vector(0, 0, 10)
	local textColor = Color(250, 250, 250)
	local shadowColor = Color(66, 66, 66)
	local currentClass

	-- we can't rely on matching non-alphanumeric characters (i.e %W) due to patterns matching single bytes and not UTF-8 chars
	local symbolPattern = "[~`!@#$%%%^&*()_%+%-={}%[%]|;:'\",%./<>?]"

	function PLUGIN:LoadFonts(font, genericFont)
		surface.CreateFont("ixTypingIndicator", {
			font = genericFont,
			size = 128,
			extended = true,
			weight = 1000
		})
	end

	function PLUGIN:ChatTextChanged(text)
		if (!IsValid(LocalPlayer())) then
			return
		end

		local character = LocalPlayer():GetCharacter()

		if (!character) then
			return
		end

		if (text == "") then
			currentClass = nil

			net.Start("ixTypeClass")
				net.WriteString("")
			net.SendToServer()

			return
		end

		local newClass = hook.Run("GetTypingIndicator", character, text)

		if (newClass != currentClass) then
			currentClass = newClass

			net.Start("ixTypeClass")
				net.WriteString(currentClass or "")
			net.SendToServer()
		end
	end

	function PLUGIN:FinishChat()
		currentClass = nil

		net.Start("ixTypeClass")
			net.WriteString("")
		net.SendToServer()
	end

	function PLUGIN:GetTypingIndicator(character, text)
		local prefix = text:utf8sub(1, 1)

		if (!prefix:find(symbolPattern) and text:utf8len() > 1) then
			return "ic"
		else
			local chatType = ix.chat.Parse(nil, text)

			if (chatType and chatType != "ic") then
				return !ix.chat.classes[chatType].bNoIndicator and chatType or nil
			end

			-- some commands will have their own typing indicator, so we'll make sure we're actually typing out a command first
			local start, _, commandName = text:find("/(%S+)%s")

			if (start == 1) then
				for uniqueID, command in pairs(ix.command.list) do
					if (command.bNoIndicator) then
						continue
					end

					if (commandName == uniqueID) then
						return command.indicator and "@" .. command.indicator or "ooc"
					end
				end
			end
		end
	end

	function PLUGIN:GetTypingIndicatorPosition(client)
		local head

		for i = 1, client:GetBoneCount() do
			local name = client:GetBoneName(i)

			if (string.find(name:lower(), "head")) then
				head = i
				break
			end
		end

		local position = head and client:GetBonePosition(head) or (client:Crouching() and crouchingOffset or standingOffset)
		return position + boneOffset
	end

	function PLUGIN:PostDrawTranslucentRenderables()
		local client = LocalPlayer()
		local position = client:GetPos()

		for _, v in player.Iterator() do
			if (v == client) then
				continue
			end

			local distance = v:GetPos():DistToSqr(position)
			local moveType = v:GetMoveType()

			if (!IsValid(v) or !v:Alive() or
				(moveType != MOVETYPE_WALK and moveType != MOVETYPE_NONE) or
				!v.ixChatClassText or
				distance >= v.ixChatClassRange) then
				continue
			end

			local text = v.ixChatClassText
			local range = v.ixChatClassRange

			local bAnimation = !ix.option.Get("disableAnimations", false)
			local fraction

			if (bAnimation) then
				local bComplete = v.ixChatClassTween:update(FrameTime())

				if (bComplete and !v.ixChatStarted) then
					v.ixChatClassText = nil
					v.ixChatClassRange = nil

					continue
				end

				fraction = v.ixChatClassAnimation
			else
				fraction = 1
			end

			local angle = EyeAngles()
			angle:RotateAroundAxis(angle:Forward(), 90)
			angle:RotateAroundAxis(angle:Right(), 90)

			cam.Start3D2D(self:GetTypingIndicatorPosition(v), Angle(0, angle.y, 90), 0.05)
				surface.SetFont("ixTypingIndicator")

				local _, textHeight = surface.GetTextSize(text)
				local alpha = bAnimation and ((1 - math.min(distance, range) / range) * 255 * fraction) or 255

				draw.SimpleTextOutlined(text, "ixTypingIndicator", 0,
					-textHeight * 0.5 * fraction,
					ColorAlpha(textColor, alpha),
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_CENTER, 4,
					ColorAlpha(shadowColor, alpha)
				)
			cam.End3D2D()
		end
	end

	net.Receive("ixTypeClass", function()
		local client = net.ReadEntity()

		if (!IsValid(client) or client == LocalPlayer()) then
			return
		end

		local newClass = net.ReadString()
		local chatClass = ix.chat.classes[newClass]
		local text
		local range

		if (chatClass) then
			text = L(chatClass.indicator or "chatTyping")
			range = chatClass.range or math.pow(ix.config.Get("chatRange", 280), 2)
		elseif (newClass and newClass:sub(1, 1) == "@") then
			text = L(newClass:sub(2))
			range = math.pow(ix.config.Get("chatRange", 280), 2)
		end

		if (ix.option.Get("disableAnimations", false)) then
			client.ixChatClassText = text
			client.ixChatClassRange = range
		else
			client.ixChatClassAnimation = tonumber(client.ixChatClassAnimation) or 0

			if (text and !client.ixChatStarted) then
				client.ixChatClassTween = ix.tween.new(PLUGIN.animationTime, client, {ixChatClassAnimation = 1}, "outCubic")

				client.ixChatClassText = text
				client.ixChatClassRange = range
				client.ixChatStarted = true
			elseif (!text and client.ixChatStarted) then
				client.ixChatClassTween = ix.tween.new(PLUGIN.animationTime, client, {ixChatClassAnimation = 0}, "inCubic")
				client.ixChatStarted = nil
			end
		end
	end)
else
	util.AddNetworkString("ixTypeClass")

	function PLUGIN:PlayerSpawn(client)
		net.Start("ixTypeClass")
			net.WriteEntity(client)
			net.WriteString("")
		net.Broadcast()
	end

	net.Receive("ixTypeClass", function(length, client)
		if ((client.ixNextTypeClass or 0) > RealTime()) then
			return
		end

		local newClass = net.ReadString()

		-- send message to players in pvs only since they're the only ones who can see the indicator
		-- we'll broadcast if the type class is empty because they might move out of pvs before the ending net message is sent
		net.Start("ixTypeClass")
		net.WriteEntity(client)
		net.WriteString(newClass)

		if (newClass == "") then
			net.Broadcast()
		else
			net.SendPVS(client:GetPos())
		end

		client.ixNextTypeClass = RealTime() + 0.2
	end)
end
