if (CLIENT) then
	local CHAT_FADETIME = 15
	local CHAT_FADEDELAY = 15
	local OUTLINE_COLOR = Color(0, 0, 0, 150)

	nut.chat.panel = nut.chat.panel or {}
	nut.chat.open = nut.chat.open or false

	local PANEL = {}
		function PANEL:Init()
			self:SetDrawBackground(false)

			timer.Simple(CHAT_FADEDELAY, function()
				if (IsValid(self)) then
					self.fadeStart = CurTime()
					self.fadeFinish = self.fadeStart + CHAT_FADETIME
				end
			end)
		end

		function PANEL:SetMaxWidth(width)
			self.maxWidth = width
		end

		function PANEL:SetFont(font)
			self.font = font
		end

		function PANEL:Parse(...)
			local data = ""
			local lastColor = Color(255, 255, 255)

			if (self.font) then
				data = "<font="..self.font..">"
			end

			for k, v in ipairs({...}) do
				if (type(v) == "table" and v.r and v.g and v.b) then
					if (v != lastColor) then
						data = data.."</color>"
					end

					lastColor = v
					data = data.."<color="..v.r..","..v.g..","..v.b..">"
				elseif (type(v) == "Player") then
					local color = team.GetColor(v:Team())

					data = data.."<color="..color.r..","..color.g..","..color.b..">"..v:Name().."</color>"
				else
					v = tostring(v)
					v = string.gsub(v, "&", "&amp;")
					v = string.gsub(v, "<", "&lt;")
					v = string.gsub(v, ">", "&gt;")

					data = data..v
				end
			end

			if (self.font) then
				data = data.."</font>"
			end

			self.markup = markup.Parse(data, self.maxWidth)

			function self.markup:Draw(xOffset, yOffset, hAlign, vAlign, alphaoverride)
				for i,blk in pairs(self.blocks) do
					local y = yOffset + (blk.height - blk.thisY) + blk.offset.y
					local x = xOffset

					if (halign == TEXT_ALIGN_CENTER) then		x = x - (self.totalWidth / 2) 
					elseif (halign == TEXT_ALIGN_RIGHT) then	x = x - (self.totalWidth)
					end

					x = x + blk.offset.x

					if (valign == TEXT_ALIGN_CENTER) then		y = y - (self.totalHeight / 2)
					elseif (valign == TEXT_ALIGN_BOTTOM) then	y = y - (self.totalHeight)
					end

					local alpha = blk.colour.a
					if (alphaoverride) then alpha = alphaoverride end

					draw.SimpleTextOutlined(blk.text, blk.font, x, y, blk.colour, hAlign, vAlign, 1, OUTLINE_COLOR)
				end
			end

			self:SetSize(self.markup:GetWidth(), self.markup:GetHeight())
		end

		function PANEL:SetAlignment(xAlign, yAlign)
			self.xAlign = xAlign
			self.yAlign = yAlign
		end

		function PANEL:Paint(w, h)
			if (self.markup) then
				local alpha = 255

				if (self.fadeStart and self.fadeFinish) then
					alpha = math.Clamp(255 - math.TimeFraction(self.fadeStart, self.fadeFinish, CurTime()) * 255, 0, 255)
				end

				if (nut.chat.open) then
					alpha = 255
				end

				self:SetAlpha(alpha)

				if (alpha > 0) then
					self.markup:Draw(1, 0, self.xAlign or 0, self.yAlign or 0)
				end
			end
		end
	vgui.Register("nut_MarkupPanel", PANEL, "DPanel")

	nut.chat = nut.chat or {}
	nut.chat.messages = nut.chat.messages or {}
	nut.chat.panel = nut.chat.panel or {}

	local CHAT_X, CHAT_Y = 64, ScrH() * 0.4
	local CHAT_W, CHAT_H = ScrW() * 0.4, ScrH() * 0.375

	chat.NutAddText = chat.NutAddText or chat.AddText

	function chat.PushFont(font)
		chat.font = font
	end

	function chat.PopFont()
		chat.font = nil
	end

	function chat.AddText(...)
		local data = {}
		local lastColor = Color(255, 255, 255)

		for k, v in pairs({...}) do
			data[k] = v
		end

		nut.chat.AddText(unpack(data))

		surface.PlaySound("common/talk.wav")

		return chat.NutAddText(unpack(data))
	end

	function nut.chat.AddText(...)
		local message = nut.chat.panel.content:Add("nut_MarkupPanel")
		message:Dock(TOP)
		message:DockPadding(4, 4, 4, 4)
		message:SetFont(chat.font or "nut_ChatFont")
		message:SetMaxWidth(CHAT_W - 16)
		message:Parse(...)
		message.lifetime = CurTime() + 150
		message.Think = function()
			if message.lifetime < CurTime() then
				message:Remove()
			end
		end

		local scrollBar = nut.chat.panel.content.VBar
		scrollBar.CanvasSize = scrollBar.CanvasSize + message:GetTall()
		scrollBar:AnimateTo(scrollBar.CanvasSize, 0.25, 0, 0.25)
	end

	function nut.chat.CreatePanels()
		if (!IsValid(nut.chat.panel.frame)) then
			local frame = vgui.Create("DPanel")
			frame:SetPos(CHAT_X, CHAT_Y)
			frame:SetSize(CHAT_W, CHAT_H)
			frame:SetDrawBackground(false)
			frame.Paint = function(panel, w, h)
				if (nut.chat.open) then
					surface.SetDrawColor(50, 50, 50, 10)
					surface.DrawRect(0, 0, w, h)
				end
			end

			local content = frame:Add("DScrollPanel")
			content:Dock(FILL)
			content:DockMargin(8, 8, 8, 38)
			content.Paint = function(panel, w, h)
				if (nut.chat.open) then
					surface.SetDrawColor(70, 70, 70, 50)
					surface.DrawRect(0, 0, w, h)
				end
			end
			content.VBar:SetWide(0)

			nut.chat.panel.frame = frame
			nut.chat.panel.content = content
		end
	end

	function nut.chat.Toggle(state)
		nut.chat.CreatePanels()
		nut.chat.open = state

		net.Start("nut_Typing")
			net.WriteBit(state)
		net.SendToServer()

		if (state) then
			local entry = vgui.Create("DTextEntry")
			entry:SetPos(CHAT_X + 8, CHAT_Y + CHAT_H - 30)
			entry:SetWide(CHAT_W - 16)
			entry:MakePopup()
			entry:RequestFocus()
			entry:SetAllowNonAsciiCharacters(true)
			entry.OnEnter = function(panel)
				nut.chat.Toggle(false)

				local text = panel:GetText()

				if (string.find(text, "[^%s]")) then
					net.Start("nut_PlayerSay")
						net.WriteString(text)
					net.SendToServer()

					hook.Run("FinishChat")
				end

				panel:SetText("")
				panel:Remove()
			end
			entry.OnTextChanged = function(panel)
				hook.Run("ChatTextChanged", panel:GetText())
			end

			hook.Run("ChatOpened")

			nut.chat.panel.entry = entry
		end
	end

	function PLUGIN:SchemaInitialized()
		nut.chat.CreatePanels()
	end

	function PLUGIN:StartChat()
		return true
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		if (string.find(string.lower(bind), "messagemode") and pressed) then
			nut.chat.Toggle(true)

			return true
		end
	end

	function PLUGIN:OnPlayerChat(client, text, teamOnly, dead)
		return true
	end

	function PLUGIN:HUDShouldDraw(element)
		if (element == "CHudChat") then
			return false
		end
	end

	function PLUGIN:ChatClassPreText(class, client, text)
		if (class.font) then
			chat.PushFont(class.font)
		end
	end

	function PLUGIN:ChatClassPostText(class, client, text)
		if (class.font) then
			chat.PopFont()
		end
	end
else
	util.AddNetworkString("nut_PlayerSay")

	net.Receive("nut_PlayerSay", function(length, client)
		if ((client.nextTalk or 0) < CurTime()) then
			client.nextTalk = CurTime() + 0.5

			-- Hacky method of allowing large text.
			hook.Run("PlayerSay", client, net.ReadString(), true)
		end
	end)
end