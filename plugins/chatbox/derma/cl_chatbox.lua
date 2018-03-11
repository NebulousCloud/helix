
local COLOR_TEXT = Color(255, 255, 255, 200)
local COLOR_FADED = Color(200, 200, 200, 100)
local COLOR_ACTIVE = color_white

-- chatbox filter button
DEFINE_BASECLASS("DButton")
local PANEL = {}

AccessorFunc(PANEL, "Active", "bActive", FORCE_BOOL)
AccessorFunc(PANEL, "Name", "name", FORCE_STRING)
AccessorFunc(PANEL, "Padding", "padding", FORCE_NUMBER)

function PANEL:Init()
	self:SetFont("ixChatFont")
	self:DockMargin(0, 0, 3, 0)
	self:Dock(LEFT)
	self:SetTextColor(color_white)
	self:SetExpensiveShadow(1, Color(0, 0, 0, 200))
end

function PANEL:SetName(name)
	name = tostring(name)
	self.name = name

	self:SetText(name:upper())
	self:SizeToContents()
end

function PANEL:Paint(width, height)
	if (self.bActive) then
		surface.SetDrawColor(40, 40, 40)
	else
		surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), 120))
	end

	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawOutlinedRect(0, 0, width, height)
end

function PANEL:DoClick()
	self.bActive = !self.bActive

	local filters = ix.option.Get("chatFilter", ""):lower()

	if (filters == "none") then
		filters = ""
	end

	if (self.bActive) then
		filters = filters .. self.name .. ","
	else
		filters = filters:gsub(self.name .. "[,]", "")

		if (!filters:find("%S")) then
			filters = "none"
		end
	end

	ix.gui.chat:OnFilterUpdated(self.name, self.bActive)
	ix.option.Set("chatFilter", filters)
end

vgui.Register("ixChatBoxFilterButton", PANEL, "DButton")

-- chatbox filter panel
PANEL = {}

function PANEL:Init()
	self:Dock(TOP)
	self:SetTall(24)
	self:DockMargin(4, 4, 4, 4)
	self:SetVisible(false)

	-- add buttons
	local buttons = {}

	for _, v in SortedPairsByMemberValue(ix.chat.classes, "filter") do
		if (!buttons[v.filter]) then
			self:AddFilter(v.filter)
			buttons[v.filter] = true
		end
	end
end

function PANEL:AddFilter(filter)
	local tab = self:Add("ixChatBoxFilterButton")
	tab:SetName(L(filter))

	if (ix.option.Get("chatFilter", ""):lower():find(filter)) then
		tab:SetActive(true)
	end
end

vgui.Register("ixChatBoxFilter", PANEL, "EditablePanel")

-- chatbox history panel
PANEL = {}

function PANEL:Init()
	local parent = self:GetParent()
	local parentWidth, parentHeight = parent:GetSize()

	self:SetPos(4, 30)
	self:SetSize(parentWidth - 8, parentHeight - 70)
	self:GetVBar():SetWide(0)

	self.history = {}
end

function PANEL:AddText(data)
	local text = "<font=ixChatFont>"

	if (ix.option.Get("chatTimestamps", false)) then
		text = text .. "<color=150,150,150>("

		if (ix.option.Get("24hourTime", false)) then
			text = text .. os.date("%H:%M")
		else
			text = text .. os.date("%I:%M %p")
		end

		text = text .. ") "
	end

	if (CHAT_CLASS) then
		text = text .. "<font=" .. (CHAT_CLASS.font or "ixChatFont") .. ">"
	end

	for _, v in ipairs(data) do
		if (type(v) == "IMaterial") then
			local texture = v:GetName()

			if (texture) then
				text = text .. "<img=" .. texture .. "," .. v:Width() .. "x" .. v:Height() .. "> "
			end
		elseif (type(v) == "table" and v.r and v.g and v.b) then
			text = text .. "<color=" .. v.r .. "," .. v.g .. "," .. v.b .. ">"
		elseif (type(v) == "Player") then
			local color = team.GetColor(v:Team())

			text = text .. "<color=" .. color.r .. "," .. color.g .. "," .. color.b .. ">" .. v:Name():gsub("<", "&lt;"):gsub(">", "&gt;")
		else
			text = text .. tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;")
			text = text:gsub("%b**", function(value)
				local inner = value:sub(2, -2)

				if (inner:find("%S")) then
					return "<font=ixChatFontItalics>" .. value:sub(2, -2) .. "</font>"
				end
			end)
		end
	end

	text = text .. "</font>"

	local panel = self:Add("ixMarkupPanel")
	panel:SetWide(self:GetWide() - 8)
	panel:SetMarkup(text, self.PaintChatText)
	panel.start = CurTime() + 15
	panel.finish = panel.start + 20
	panel.Think = function(this)
		if (self:GetParent().bActive) then
			this:SetAlpha(255)
		else
			this:SetAlpha((1 - math.TimeFraction(this.start, this.finish, CurTime())) * 255)
		end
	end

	self.history[#self.history + 1] = panel
	return panel
end

function PANEL:PaintChatText(font, x, y, color, alignX, alignY, alpha)
	alpha = alpha or 255

	surface.SetTextPos(x + 1, y + 1)
	surface.SetTextColor(0, 0, 0, alpha)
	surface.SetFont(font)
	surface.DrawText(self)

	surface.SetTextPos(x, y)
	surface.SetTextColor(color.r, color.g, color.b, alpha)
	surface.SetFont(font)
	surface.DrawText(self)
end

function PANEL:PaintOver(width, height)
	local parent = self:GetParent()
	local entry = parent.entry

	if (parent.bActive and IsValid(entry)) then
		local text = entry:GetText()

		if (text:sub(1, 1) == "/") then
			local arguments = parent.arguments or {}
			local command = string.PatternSafe(arguments[1] or ""):lower()

			ix.util.DrawBlur(self)

			surface.SetDrawColor(0, 0, 0, 200)
			surface.DrawRect(0, 0, width, height)

			local currentY = 0

			for k, v in ipairs(parent.potentialCommands) do
				local color = ix.config.Get("color")
				local bSelectedCommand = (parent.autocompleteIndex == 0 and command == v.uniqueID) or
					(parent.autocompleteIndex > 0 and k == parent.autocompleteIndex)

				if (bSelectedCommand) then
					local description = v:GetDescription()

					if (description != "") then
						local _, h = ix.util.DrawText(description, 4, currentY, COLOR_ACTIVE)

						currentY = currentY + h + 1
					end

					color = Color(color.r + 35, color.g + 35, color.b + 35, 255)
				end

				local x, h = ix.util.DrawText("/" .. v.name .. "  ", 4, currentY, color)

				if (bSelectedCommand and v.syntax) then
					local i2 = 0

					for argument in v.syntax:gmatch("([%[<][%w_]+[%s][%w_]+[%]>])") do
						i2 = i2 + 1
						color = COLOR_FADED

						if (i2 == (#arguments - 1)) then
							color = COLOR_ACTIVE
						end

						local w, _ = ix.util.DrawText(argument .. "  ", x, currentY, color)

						x = x + w
					end
				end

				currentY = currentY + h + 1
			end
		end
	end
end

vgui.Register("ixChatBoxHistory", PANEL, "DScrollPanel")

-- chatbox text entry panel
DEFINE_BASECLASS("DTextEntry")
PANEL = {}

function PANEL:Init()
	self.History = ix.chat.history
	self:SetHistoryEnabled(true)
	self:DockMargin(3, 3, 3, 3)
	self:SetFont("ixChatFont")
	self:SetAllowNonAsciiCharacters(true)

	hook.Run("StartChat")
end

function PANEL:OnEnter()
	local parent = self:GetParent()
	local text = self:GetText()

	if (text:find("%S")) then
		if (!(ix.chat.lastLine or ""):find(text, 1, true)) then
			ix.chat.history[#ix.chat.history + 1] = text
			ix.chat.lastLine = text
		end

		netstream.Start("msg", text)
	end

	self:Remove()
	parent:SetActive(false)
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(0, 0, 0, 100)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawOutlinedRect(0, 0, width, height)

	self:DrawTextEntryText(COLOR_TEXT, ix.config.Get("color"), COLOR_TEXT)
end

function PANEL:AllowInput(newText)
	local text = self:GetText()
	local maxLength = ix.config.Get("chatMax")

	if (string.len(text .. newText) > maxLength) then
		surface.PlaySound("common/talk.wav")
		return true
	end
end

function PANEL:Think()
	local text = self:GetText()
	local maxLength = ix.config.Get("chatMax")

	if (string.len(text) > maxLength) then
		local newText = string.sub(text, 0, maxLength)

		self:SetText(newText)
		self:SetCaretPos(string.len(newText))
	end
end

function PANEL:OnTextChanged()
	local parent = self:GetParent()
	local text = self:GetText()

	hook.Run("ChatTextChanged", text)

	if (text:sub(1, 1) == "/" and !self.bAutocompleted) then
		local command = tostring(text:match("(/(%w+))") or "/")

		parent.potentialCommands = ix.command.FindAll(command, true, true, true)
		parent.arguments = ix.command.ExtractArgs(text:sub(2))

		-- if the first suggested command is equal to the currently typed one,
		-- offset the index so you don't have to hit tab twice to go past the first command
		if (#parent.potentialCommands > 0 and parent.potentialCommands[1].uniqueID == command:sub(2):lower()) then
			parent.autocompleteIndex = 1
		else
			parent.autocompleteIndex = 0
		end
	end

	self.bAutocompleted = nil
end

function PANEL:OnKeyCodeTyped(code)
	local parent = self:GetParent()

	if (code == KEY_TAB) then
		if (#parent.potentialCommands > 0) then
			parent.autocompleteIndex = (parent.autocompleteIndex + 1) > #parent.potentialCommands and 1 or
				(parent.autocompleteIndex + 1)

			local command = parent.potentialCommands[parent.autocompleteIndex]

			if (command) then
				local text = string.format("/%s ", command.uniqueID)

				self:SetText(text)
				self:SetCaretPos(text:len())

				self.bAutocompleted = true
			end
		end

		self:RequestFocus()
		return true
	else
		BaseClass.OnKeyCodeTyped(self, code)
	end
end

function PANEL:OnRemove()
	hook.Run("FinishChat")
end

vgui.Register("ixChatBoxEntry", PANEL, "DTextEntry")

-- main chatbox panel
PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)

function PANEL:Init()
	local border = 32
	local scrW, scrH = ScrW(), ScrH()
	local w, h = scrW * 0.4, scrH * 0.375

	ix.gui.chat = self

	self:SetSize(w, h)
	self:SetPos(border, scrH - h - border)

	self.tabs = self:Add("ixChatBoxFilter")
	self.scroll = self:Add("ixChatBoxHistory")

	self.autocompleteIndex = 0
	self.potentialCommands = {}
	self.arguments = {}

	self.bActive = false
	self.lastY = 0
	self.filtered = {}

	-- luacheck: globals chat
	chat.GetChatBoxPos = function()
		return self:LocalToScreen(0, 0)
	end

	chat.GetChatBoxSize = function()
		return self:GetSize()
	end
end

function PANEL:Paint(w, h)
	if (self.bActive) then
		ix.util.DrawBlur(self, 10)

		surface.SetDrawColor(250, 250, 250, 2)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 240)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
end

function PANEL:SetActive(state)
	self.bActive = tobool(state)

	if (state) then
		ix.chat.history = ix.chat.history or {}

		self.entry = self:Add("ixChatBoxEntry")
		self.entry:SetPos(self.x + 4, self.y + self:GetTall() - 32)
		self.entry:SetWide(self:GetWide() - 8)
		self.entry:SetTall(28)

		self.entry:MakePopup()
		self.tabs:SetVisible(true)
	else
		self.entry:Remove()
		self.tabs:SetVisible(false)
	end
end

function PANEL:AddText(...)
	local panel = self.scroll:AddText({...})
	local class = CHAT_CLASS and CHAT_CLASS.filter and CHAT_CLASS.filter:lower() or "ic"

	if (ix.option.Get("chatFilter", ""):lower():find(class)) then
		self.filtered[panel] = class
		panel:SetVisible(false)
	else
		panel:SetPos(0, self.lastY)

		self.lastY = self.lastY + panel:GetTall()
		self.scroll:ScrollToChild(panel)
	end

	panel.filter = class

	return panel:IsVisible()
end

function PANEL:OnFilterUpdated(filter, bActive)
	if (bActive) then
		for _, v in ipairs(self.scroll.history) do
			if (v.filter == filter) then
				v:SetVisible(false)
				self.filtered[v] = filter
			end
		end
	else
		for k, v in pairs(self.filtered) do
			if (v == filter) then
				k:SetVisible(true)
				self.filtered[k] = nil
			end
		end
	end

	self.lastY = 0

	local lastChild

	for _, v in ipairs(self.scroll.history) do
		if (v:IsVisible()) then
			v:SetPos(0, self.lastY)
			self.lastY = self.lastY + v:GetTall() + 2
			lastChild = v
		end
	end

	if (IsValid(lastChild)) then
		self.scroll:ScrollToChild(lastChild)
	end
end

function PANEL:Think()
	if (gui.IsGameUIVisible() and self.bActive) then
		self:SetActive(false)
	end
end

vgui.Register("ixChatBox", PANEL, "DPanel")

if (IsValid(ix.gui.chat)) then
	RunConsoleCommand("fixchatplz")
end
