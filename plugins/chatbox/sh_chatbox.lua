if (CLIENT) then
	local CHAT_FADETIME = 15
	local CHAT_FADEDELAY = 15
	local OUTLINE_COLOR = Color(0, 0, 0, 150)
	local NUT_CVAR_CHATMESSAGES = CreateClientConVar("nut_chatmessages", "100", true)

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
				elseif (type(v) == "IMaterial" or type(v) == "table" and type(v[1]) == "IMaterial") then
					local w, h = 16, 16
					local material = v

					if (type(v) == "table" and v[2] and v[3]) then
						material = v[1]
						w = v[2]
						h = v[3]
					end

					data = data.."<img="..material:GetName()..".png,"..w.."x"..h.."> "
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

			self.markup = nut.markup.Parse(data, self.maxWidth)

			function self.markup:DrawText(text, font, x, y, color, hAlign, vAlign, alpha)
				draw.SimpleTextOutlined(text, font, x, y, color, hAlign, vAlign, 1, OUTLINE_COLOR)
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
	nut.chat.history = nut.chat.history or {}

	NUT_CVAR_CHATX = CreateClientConVar("nut_chatx", "32", true)
	NUT_CVAR_CHATY = CreateClientConVar("nut_chaty", "0.5", true)

	local CHAT_X, CHAT_Y = NUT_CVAR_CHATX:GetInt(), ScrH() * NUT_CVAR_CHATY:GetFloat()
	local CHAT_W, CHAT_H = ScrW() * 0.4, ScrH() * 0.375

	cvars.AddChangeCallback("nut_chatx", function(conVar, oldValue, value)
		CHAT_X = NUT_CVAR_CHATX:GetInt()
		nut.chat.panel.frame:SetPos(CHAT_X, CHAT_Y)
	end)

	cvars.AddChangeCallback("nut_chaty", function(conVar, oldValue, value)
		CHAT_Y = ScrH() * NUT_CVAR_CHATY:GetFloat()
		nut.chat.panel.frame:SetPos(CHAT_X, CHAT_Y)
	end)

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

		for k, v in ipairs(data) do
			if (type(v) == "Player") then
				local client = v
				local index = k
				
				table.remove(data, k)
				table.insert(data, index, team.GetColor(client:Team()))
				table.insert(data, index + 1, client:Name())
			end
		end

		return chat.NutAddText(unpack(data))
	end

	function nut.chat.AddText(...)
		local message = nut.chat.panel.content:Add("nut_MarkupPanel")
		message:Dock(TOP)
		message:DockPadding(4, 4, 4, 4)
		message:SetFont(chat.font or "nut_ChatFont")
		message:SetMaxWidth(CHAT_W - 16)
		message:Parse(...)

		local scrollBar = nut.chat.panel.content.VBar
		scrollBar.CanvasSize = scrollBar.CanvasSize + message:GetTall()
		scrollBar:AnimateTo(scrollBar.CanvasSize, 0.25, 0, 0.25)

		table.insert(nut.chat.messages, message)

		if (#nut.chat.messages > NUT_CVAR_CHATMESSAGES:GetInt()) then
			local panel = nut.chat.messages[1]
			panel:Remove()

			table.remove(nut.chat.messages, 1)
		end
	end

	function nut.chat.CreatePanels()
		if (!IsValid(nut.chat.panel.frame)) then
			local frame = vgui.Create("DPanel")
			frame:SetPos(CHAT_X, CHAT_Y)
			frame:SetSize(CHAT_W, CHAT_H)
			frame:SetDrawBackground(false)

			local content = frame:Add("DScrollPanel")
			content:Dock(FILL)
			content:DockMargin(8, 8, 8, 38)
			content.VBar:SetWide(0)

			nut.chat.panel.frame = frame
			nut.chat.panel.content = content
		end
	end

	function nut.chat.Toggle(state)
		nut.chat.CreatePanels()
		nut.chat.open = state

		netstream.Start("nut_Typing", state)

		if (state) then
			local entry = vgui.Create("DTextEntry")
			entry:SetPos(CHAT_X + 8, CHAT_Y + CHAT_H - 30)
			entry:SetWide(CHAT_W - 16)
			entry:MakePopup()
			entry:RequestFocus()
			entry:SetTall(24)
			entry.History = nut.chat.history
			entry:SetHistoryEnabled(true)
			entry:SetAllowNonAsciiCharacters(true)
			entry.OnEnter = function(panel)
				nut.chat.Toggle(false)

				local text = panel:GetText()

				if (string.find(text, "%S")) then
					netstream.Start("nut_PlayerSay", string.sub(text, 1, nut.config.maxChatLength))
					table.insert(nut.chat.history, text)

					hook.Run("FinishChat")
				end

				panel:SetText("")
				panel:Remove()
			end
			entry.OnKeyCodePressed = function(panel, key)
				if (key == KEY_ESCAPE) then
					nut.chat.Toggle(false)
					panel:SetText("")
					panel:Remove()
				end
			end
			entry.Think = function(panel)
				if (gui.IsGameUIVisible()) then
					nut.chat.Toggle(false)
					panel:SetText("")
					panel:Remove()
				end
			end
			entry.Paint = function(panel, w, h)
				surface.SetDrawColor(70, 70, 70, 245)
				surface.DrawRect(0, 0, w, h)

				surface.SetDrawColor(25, 25, 25, 235)
				surface.DrawOutlinedRect(0, 0, w, h)

				-- For some reason, it refuses to use the main color so we
				-- have to recreate it.
				local highlight = nut.config.mainColor
				local color = Color(highlight.r, highlight.g, highlight.b)

				panel:DrawTextEntryText(color_white, color, color_white)
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

	local icon = Material("icon16/server.png")

	function PLUGIN:OnPlayerChat(client, text, teamOnly, dead)
		if (!IsValid(client)) then
			chat.AddText(icon, Color(150, 150, 150), "Console", color_white, ": "..text)
		end

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
	netstream.Hook("nut_PlayerSay", function(client, data)
		if ((client.nextTalk or 0) < CurTime()) then
			client.nextTalk = CurTime() + 0.5

			-- Hacky method of allowing large text.
			hook.Run("PlayerSay", client, data, true)
		end
	end)
end