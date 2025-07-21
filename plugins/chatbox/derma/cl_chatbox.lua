
local PLUGIN = PLUGIN

local animationTime = 0.5
local chatBorder = 32
local sizingBorder = 20
local maxChatEntries = 100

-- called when a markup object should paint its text
local function PaintMarkupOverride(text, font, x, y, color, alignX, alignY, alpha)
	alpha = alpha or 255

	if (ix.option.Get("chatOutline", false)) then
		-- outlined background for even more visibility
		draw.SimpleTextOutlined(text, font, x, y, ColorAlpha(color, alpha), alignX, alignY, 1, Color(0, 0, 0, alpha))
	else
		-- background for easier reading
		surface.SetTextPos(x + 1, y + 1)
		surface.SetTextColor(0, 0, 0, alpha)
		surface.SetFont(font)
		surface.DrawText(text)

		surface.SetTextPos(x, y)
		surface.SetTextColor(color.r, color.g, color.b, alpha)
		surface.SetFont(font)
		surface.DrawText(text)
	end
end

-- chat message
local PANEL = {}

AccessorFunc(PANEL, "fadeDelay", "FadeDelay", FORCE_NUMBER)
AccessorFunc(PANEL, "fadeDuration", "FadeDuration", FORCE_NUMBER)

function PANEL:Init()
	self.text = ""
	self.alpha = 255
	self.fadeDelay = 15
	self.fadeDuration = 5
end

function PANEL:SetMarkup(text)
	self.text = text

	self.markup = ix.markup.Parse(self.text, self:GetWide())
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())

	timer.Simple(self.fadeDelay, function()
		if (!IsValid(self)) then
			return
		end

		self:CreateAnimation(self.fadeDuration, {
			index = 3,
			target = {alpha = 0}
		})
	end)
end

function PANEL:PerformLayout(width, height)
	if ((IsValid(ix.gui.chat) and ix.gui.chat.bSizing) or width == self.markup:GetWidth()) then
		return
	end

	self.markup = ix.markup.Parse(self.text, width)
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())
end

function PANEL:Paint(width, height)
	local newAlpha

	-- we'll want to hide the chat while some important menus are open
	if (IsValid(ix.gui.characterMenu)) then
		newAlpha = math.min(255 - ix.gui.characterMenu.currentAlpha, self.alpha)
	elseif (IsValid(ix.gui.menu)) then
		newAlpha = math.min(255 - ix.gui.menu.currentAlpha, self.alpha)
	elseif (ix.gui.chat:GetActive()) then
		newAlpha = math.max(ix.gui.chat.alpha, self.alpha)
	else
		newAlpha = self.alpha
	end

	if (newAlpha < 1) then
		return
	end

	self.markup:draw(0, 0, nil, nil, newAlpha)
end

vgui.Register("ixChatMessage", PANEL, "Panel")

-- chatbox tab button
PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)
AccessorFunc(PANEL, "bUnread", "Unread", FORCE_BOOL)

function PANEL:Init()
	self:SetFont("ixChatFont")
	self:SetContentAlignment(5)

	self.unreadAlpha = 0
end

function PANEL:SetUnread(bValue)
	self.bUnread = bValue

	self:CreateAnimation(animationTime, {
		index = 4,
		target = {unreadAlpha = bValue and 1 or 0},
		easing = "outQuint"
	})
end

function PANEL:SizeToContents()
	local width, height = self:GetContentSize()
	self:SetSize(width + 12, height + 6)
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintChatboxTabButton", self, width, height)
end

vgui.Register("ixChatboxTabButton", PANEL, "DButton")

-- chatbox tab panel
-- holds all tab buttons and corresponding history panels
PANEL = {}

function PANEL:Init()
	-- holds all tab buttons
	self.buttons = self:Add("Panel")
	self.buttons:Dock(TOP)
	self.buttons:DockPadding(1, 1, 0, 0)
	self.buttons.OnMousePressed = ix.util.Bind(ix.gui.chat, ix.gui.chat.OnMousePressed) -- we want mouse events to fall through
	self.buttons.OnMouseReleased = ix.util.Bind(ix.gui.chat, ix.gui.chat.OnMouseReleased)
	self.buttons.Paint = function(_, width, height)
		derma.SkinFunc("PaintChatboxTabs", self, width, height)
	end

	self.tabs = {}
end

function PANEL:GetTabs()
	return self.tabs
end

function PANEL:AddTab(id, filter)
	local button = self.buttons:Add("ixChatboxTabButton")
	button:Dock(LEFT)
	button:SetText(id) -- display name is also the ID
	button:SetActive(false)
	button:SetMouseInputEnabled(true)
	button:SizeToContents()

	button.DoClick = function(this)
		self:SetActiveTab(this:GetText())
	end

	local panel = self:Add("ixChatboxHistory")
	panel:SetButton(button)
	panel:SetID(id)
	panel:Dock(FILL)
	panel:SetVisible(false)
	panel:SetFilter(filter or {})

	button.DoRightClick = function(this)
		ix.gui.chat:OnTabRightClick(this, panel, panel:GetID())
	end

	self.tabs[id] = panel
	return panel
end

function PANEL:RemoveTab(id)
	local tab = self.tabs[id]

	if (!tab) then
		return
	end

	tab:GetButton():Remove()
	tab:Remove()

	self.tabs[id] = nil

	-- add default tab if we don't have any tabs left
	if (table.IsEmpty(self.tabs)) then
		self:AddTab(L("chat"), {})
		self:SetActiveTab(L("chat"))
	elseif (id == self:GetActiveTabID()) then
		-- set a different active tab if we've removed a tab that is currently active
		self:SetActiveTab(next(self.tabs))
	end
end

function PANEL:RenameTab(id, newID)
	local tab = self.tabs[id]

	if (!tab) then
		return
	end

	tab:GetButton():SetText(newID)
	tab:GetButton():SizeToContents()

	tab:SetID(newID)

	self.tabs[id] = nil
	self.tabs[newID] = tab

	if (id == self:GetActiveTabID()) then
		self:SetActiveTab(newID)
	end
end

function PANEL:SetActiveTab(id)
	local tab = self.tabs[id]

	if (!tab) then
		error("attempted to set non-existent active tab")
	end

	for _, v in ipairs(self.buttons:GetChildren()) do
		v:SetActive(v:GetText() == id)
	end

	for _, v in pairs(self.tabs) do
		v:SetVisible(v:GetID() == id)
	end

	tab:GetButton():SetUnread(false)

	self.activeTab = id
	self:OnTabChanged(tab)
end

function PANEL:GetActiveTabID()
	return self.activeTab
end

function PANEL:GetActiveTab()
	return self.tabs[self.activeTab]
end

-- called when the active tab is changed
-- `panel` is the corresponding history panel
function PANEL:OnTabChanged(panel)
end

vgui.Register("ixChatboxTabs", PANEL, "EditablePanel")

-- chatbox history panel
-- holds individual messages in a scrollable panel
PANEL = {}

AccessorFunc(PANEL, "filter", "Filter") -- blacklist of message classes
AccessorFunc(PANEL, "id", "ID", FORCE_STRING)
AccessorFunc(PANEL, "button", "Button") -- button panel that this panel corresponds to

function PANEL:Init()
	self:DockMargin(4, 2, 4, 4) -- smaller top margin to help blend tab button/history panel transition
	self:SetPaintedManually(true)

	local bar = self:GetVBar()
	bar:SetWide(0)

	self.entries = {}
	self.filter = {}
end

DEFINE_BASECLASS("Panel") -- DScrollPanel doesn't have SetVisible member
function PANEL:SetVisible(bState)
	self:GetCanvas():SetVisible(bState)
	BaseClass.SetVisible(self, bState)
end

DEFINE_BASECLASS("DScrollPanel")
function PANEL:PerformLayoutInternal()
	local bar = self:GetVBar()
	local bScroll = !ix.gui.chat:GetActive() or bar.Scroll == bar.CanvasSize -- only scroll when we're not at the bottom/inactive

	BaseClass.PerformLayoutInternal(self)

	if (bScroll) then
		self:ScrollToBottom()
	end
end

function PANEL:ScrollToBottom()
	local bar = self:GetVBar()
	bar:SetScroll(bar.CanvasSize)
end

-- adds a line of text as described by its elements
function PANEL:AddLine(elements, bShouldScroll)
	-- table.concat is faster than regular string concatenation where there are lots of strings to concatenate
	local buffer = {
		"<font=ixChatFont>"
	}

	if (ix.option.Get("chatTimestamps", false)) then
		buffer[#buffer + 1] = "<color=150,150,150>("

		if (ix.option.Get("24hourTime", false)) then
			buffer[#buffer + 1] = os.date("%H:%M")
		else
			buffer[#buffer + 1] = os.date("%I:%M %p")
		end

		buffer[#buffer + 1] = ") "
	end

	if (CHAT_CLASS) then
		buffer[#buffer + 1] = "<font="
		buffer[#buffer + 1] = CHAT_CLASS.font or "ixChatFont"
		buffer[#buffer + 1] = ">"
	end

	for _, v in ipairs(elements) do
		if (type(v) == "IMaterial") then
			local texture = v:GetName()

			if (texture) then
				buffer[#buffer + 1] = string.format("<img=%s,%dx%d> ", texture, v:Width(), v:Height())
			end
		elseif (istable(v) and v.r and v.g and v.b) then
			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>", v.r, v.g, v.b)
		elseif (type(v) == "Player") then
			local color = team.GetColor(v:Team())

			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>%s", color.r, color.g, color.b,
				v:GetName():gsub("<", "&lt;"):gsub(">", "&gt;"))
		else
			buffer[#buffer + 1] = tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("%b**", function(value)
				local inner = value:utf8sub(2, -2)

				if (inner:find("%S")) then
					return "<font=ixChatFontItalics>" .. value:utf8sub(2, -2) .. "</font>"
				end
			end)
		end
	end

	local panel = self:Add("ixChatMessage")
	panel:Dock(TOP)
	panel:InvalidateParent(true)
	panel:SetMarkup(table.concat(buffer))

	if (#self.entries >= maxChatEntries) then
		local oldPanel = table.remove(self.entries, 1)

		if (IsValid(oldPanel)) then
			oldPanel:Remove()
		end
	end

	self.entries[#self.entries + 1] = panel
	return panel
end

vgui.Register("ixChatboxHistory", PANEL, "DScrollPanel")

PANEL = {}
DEFINE_BASECLASS("DTextEntry")

function PANEL:Init()
	self:SetFont("ixChatFont")
	self:SetUpdateOnType(true)
	self:SetHistoryEnabled(true)

	self.History = ix.chat.history
	self.m_bLoseFocusOnClickAway = false
end

function PANEL:SetFont(font)
	BaseClass.SetFont(self, font)

	surface.SetFont(font)
	local _, height = surface.GetTextSize("W@")

	self:SetTall(height + 8)
end

function PANEL:AllowInput(newCharacter)
	local text = self:GetText()
	local maxLength = ix.config.Get("chatMax")

	-- we can't check for the proper length using utf-8 since AllowInput is called for single bytes instead of full characters
	if (string.len(text .. newCharacter) > maxLength) then
		surface.PlaySound("common/talk.wav")
		return true
	end
end

function PANEL:Think()
	local text = self:GetText()
	local maxLength = ix.config.Get("chatMax", 256)

	if (text:utf8len() > maxLength) then
		local newText = text:utf8sub(0, maxLength)

		self:SetText(newText)
		self:SetCaretPos(newText:utf8len())
	end
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintChatboxEntry", self, width, height)
end

vgui.Register("ixChatboxEntry", PANEL, "DTextEntry")

-- chatbox additional command info panel
PANEL = {}

AccessorFunc(PANEL, "text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "padding", "Padding", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "textColor", "TextColor")

function PANEL:Init()
	self.text = ""
	self.padding = 4
	self.currentWidth = 0
	self.currentMargin = 0
	self.backgroundColor = ix.config.Get("color")
	self.textColor = color_white

	self:SetWide(0)
	self:DockMargin(0, 0, 0, 0)
end

function PANEL:SetText(text)
	self:SetVisible(true)

	if (!isstring(text) or text == "") then
		self:CreateAnimation(animationTime, {
			index = 9,
			easing = "outQuint",
			target = {
				currentWidth = 0,
				currentMargin = 0
			},

			Think = function(animation, panel)
				panel:SetWide(panel.currentWidth)
				panel:DockMargin(0, 0, panel.currentMargin, 0)
			end,

			OnComplete = function(animation, panel)
				panel:SetVisible(false)
				self.text = ""
			end
		})
	else
		text = tostring(text)

		surface.SetFont("ixChatFont")
		local textWidth = surface.GetTextSize(text)

		self:CreateAnimation(animationTime, {
			index = 9,
			easing = "outQuint",
			target = {
				currentWidth = textWidth + self.padding * 2,
				currentMargin = 4
			},

			Think = function(animation, panel)
				panel:SetWide(panel.currentWidth)
				panel:DockMargin(0, 0, panel.currentMargin, 0)
			end,
		})

		self.text = text
	end
end

function PANEL:Paint(width, height)
	derma.SkinFunc("DrawChatboxPrefixBox", self, width, height)

	surface.SetFont("ixChatFont")
	local textWidth, textHeight = surface.GetTextSize(self.text)

	surface.SetTextColor(self.textColor)
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, height * 0.5 - textHeight * 0.5)
	surface.DrawText(self.text)
end

vgui.Register("ixChatboxPrefix", PANEL, "Panel")

-- chatbox command preview panel
PANEL = {}
DEFINE_BASECLASS("Panel")

AccessorFunc(PANEL, "targetHeight", "TargetHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "command", "Command", FORCE_STRING)

function PANEL:Init()
	self:SetTall(0)
	self:SetVisible(false, true)

	self.height = 0
	self.targetHeight = 16
	self.margin = 0

	self.command = ""
end

function PANEL:SetCommand(command)
	-- if we're setting it to an empty command, then we'll hold the reference to the old command table to render it for the
	-- fade out animation
	if (command == "") then
		self.command = ""
		ix.chat.currentCommand = ""

		return
	end

	local commandTable = ix.command.list[command]

	if (!commandTable) then
		return
	end

	self.command = command
	self.commandTable = commandTable
	self.arguments = {}

	ix.chat.currentCommand = command:lower()
end

function PANEL:UpdateArguments(text)
	if (self.command == "") then
		ix.chat.currentArguments = {}
		return
	end

	local commandName = text:match("(/(%w+)%s)") or self.command -- we could be using a chat class prefix and not a proper command
	local givenArguments = ix.command.ExtractArgs(text:utf8sub(commandName:utf8len()))
	local commandArguments = self.commandTable.arguments or {}
	local arguments = {}

	-- we want to concat any text types so they show up as one argument at the end of the list, this is so the argument
	-- highlighting is accurate since ExtractArgs will not account because it has no type context
	for k, v in ipairs(givenArguments) do
		if (k == #commandArguments) then
			arguments[#arguments + 1] = table.concat(givenArguments, " ", k)
			break
		end

		arguments[#arguments + 1] = v
	end

	self.arguments = arguments
	ix.chat.currentArguments = table.Copy(arguments)
end

-- returns the target SetVisible value
function PANEL:IsOpen()
	return self.bOpen
end

function PANEL:SetVisible(bValue, bForce)
	if (bForce) then
		BaseClass.SetVisible(self, bValue)
		return
	end

	BaseClass.SetVisible(self, true) -- make sure this panel is visible during animation
	self.bOpen = bValue

	self:CreateAnimation(animationTime * 0.5, {
		index = 5,
		target = {
			height = bValue and self.targetHeight or 0,
			margin = bValue and 4 or 0
		},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetTall(math.ceil(panel.height))
			panel:DockMargin(4, 0, 4, math.ceil(panel.margin))
		end,

		OnComplete = function(animation, panel)
			BaseClass.SetVisible(panel, bValue)
		end
	})
end

function PANEL:Paint(width, height)
	local command = self.commandTable

	if (!command) then
		return
	end

	local color = ix.config.Get("color")
	surface.SetFont("ixChatFont")

	-- command name
	local x = derma.SkinFunc("DrawChatboxPreviewBox", 0, 0, "/" .. command.name) + 6

	-- command arguments
	if (istable(command.arguments)) then
		for k, v in ipairs(command.arguments) do
			local bOptional = bit.band(v, ix.type.optional) > 0
			local type = bOptional and bit.bxor(v, ix.type.optional) or v

			x = x + derma.SkinFunc(
				"DrawChatboxPreviewBox", x, 0,
				-- draw text in format of <name: type> or [name: type] if it's optional
				string.format(bOptional and "[%s: %s]" or "<%s: %s>", command.argumentNames[k], ix.type[type]),
				-- fill in the color for arguments that are before the one the user is currently typing, otherwise draw a faded
				-- color instead (optional arguments will not have any background color unless it's been filled out by user)
				(k <= #self.arguments) and color or (bOptional and Color(0, 0, 0, 66) or ColorAlpha(color, 100))
			) + 6
		end
	end
end

vgui.Register("ixChatboxPreview", PANEL, "Panel")

-- chatbox autocomplete panel
-- holds and displays similar commands based on the textentry
PANEL = {}
DEFINE_BASECLASS("Panel")

AccessorFunc(PANEL, "maxEntries", "MaxEntries", FORCE_NUMBER)

function PANEL:Init()
	self:SetVisible(false, true)
	self:SetMouseInputEnabled(true)

	self.maxEntries = 20
	self.currentAlpha = 0

	self.commandIndex = 0 -- currently selected entry in command list
	self.commands = {}
	self.commandPanels = {}
end

function PANEL:GetCommands()
	return self.commands
end

function PANEL:IsOpen()
	return self.bOpen
end

function PANEL:SetVisible(bValue, bForce)
	if (bForce) then
		BaseClass.SetVisible(self, bValue)
		return
	end

	BaseClass.SetVisible(self, true) -- make sure this panel is visible during animation
	self.bOpen = bValue

	self:CreateAnimation(animationTime, {
		index = 6,
		target = {
			currentAlpha = bValue and 255 or 0
		},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(math.ceil(panel.currentAlpha))
		end,

		OnComplete = function(animation, panel)
			BaseClass.SetVisible(panel, bValue)

			if (!bValue) then
				self.commands = {}
			end
		end
	})
end

function PANEL:Update(text)
	local commands = ix.command.FindAll(text, true, true, true)

	self.commandIndex = 0 -- reset the command index because the command list could be different
	self.commands = {}

	for _, v in ipairs(self.commandPanels) do
		v:Remove()
	end

	self.commandPanels = {}

	-- manually loop over the found commands so we can ignore commands the user doesn't have access to
	local i = 1
	local bSelected -- just to make sure we don't reset it during the loop for whatever reason

	for _, v in ipairs(commands) do
		-- @todo chat classes aren't checked since they're done through the class's OnCanSay callback
		if (v.OnCheckAccess and !v:OnCheckAccess(LocalPlayer())) then
			continue
		end

		local panel = self:Add("ixChatboxAutocompleteEntry")
		panel:SetCommand(v)

		if (!bSelected and text:utf8lower():utf8sub(1, v.uniqueID:utf8len()) == v.uniqueID) then
			panel:SetHighlighted(true)

			self.commandIndex = i
			bSelected = true
		end

		self.commandPanels[i] = panel
		self.commands[i] = v

		if (i == self.maxEntries) then
			break
		end

		i = i + 1
	end
end

-- selects the next entry in the autocomplete if possible and returns the text that should replace the textentry
function PANEL:SelectNext()
	-- wrap back to beginning if we're past the end
	if (self.commandIndex == #self.commands) then
		self.commandIndex = 1
	else
		self.commandIndex = self.commandIndex + 1
	end

	for k, v in ipairs(self.commandPanels) do
		if (k == self.commandIndex) then
			v:SetHighlighted(true)
			self:ScrollToChild(v)
		else
			v:SetHighlighted(false)
		end
	end

	return "/" .. self.commands[self.commandIndex].uniqueID
end

function PANEL:Paint(width, height)
	ix.util.DrawBlur(self)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, width, height)
end

vgui.Register("ixChatboxAutocomplete", PANEL, "DScrollPanel")

-- autocomplete entry
PANEL = {}

AccessorFunc(PANEL, "bSelected", "Highlighted", FORCE_BOOL)

function PANEL:Init()
	self:Dock(TOP)

	self.name = self:Add("DLabel")
	self.name:Dock(TOP)
	self.name:DockMargin(4, 4, 0, 0)
	self.name:SetContentAlignment(4)
	self.name:SetFont("ixChatFont")
	self.name:SetTextColor(ix.config.Get("color"))
	self.name:SetExpensiveShadow(1, color_black)

	self.description = self:Add("DLabel")
	self.description:Dock(BOTTOM)
	self.description:DockMargin(4, 4, 0, 4)
	self.description:SetContentAlignment(4)
	self.description:SetFont("ixChatFont")
	self.description:SetTextColor(color_white)
	self.description:SetExpensiveShadow(1, color_black)

	self.highlightAlpha = 0
end

function PANEL:SetHighlighted(bValue)
	self:CreateAnimation(animationTime * 2, {
		index = 7,
		target = {highlightAlpha = bValue and 1 or 0},
		easing = "outQuint"
	})

	self.bHighlighted = true
end

function PANEL:SetCommand(command)
	local description = command:GetDescription()

	self.name:SetText("/" .. command.name)

	if (description and description != "") then
		self.description:SetText(command:GetDescription())
	else
		self.description:SetVisible(false)
	end

	self:SizeToContents()
	self.command = command
end

function PANEL:SizeToContents()
	local bDescriptionVisible = self.description:IsVisible()
	local _, height = self.name:GetContentSize()

	self.name:SetTall(height)

	if (bDescriptionVisible) then
		_, height = self.description:GetContentSize()
		self.description:SetTall(height)
	else
		self.description:SetTall(0)
	end

	self:SetTall(self.name:GetTall() + self.description:GetTall() + (bDescriptionVisible and 12 or 8))
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintChatboxAutocompleteEntry", self, width, height)
end

vgui.Register("ixChatboxAutocompleteEntry", PANEL, "Panel")

-- main chatbox panel
-- this contains the text entry, tab sheets, and callbacks for other panel events
PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)

function PANEL:Init()
	ix.gui.chat = self

	self:SetSize(self:GetDefaultSize())
	self:SetPos(self:GetDefaultPosition())

	local entryPanel = self:Add("Panel")
	entryPanel:SetZPos(1)
	entryPanel:Dock(BOTTOM)
	entryPanel:DockMargin(4, 0, 4, 4)

	self.entry = entryPanel:Add("ixChatboxEntry")
	self.entry:Dock(FILL)
	self.entry.OnValueChange = ix.util.Bind(self, self.OnTextChanged)
	self.entry.OnKeyCodeTyped = ix.util.Bind(self, self.OnKeyCodeTyped)
	self.entry.OnEnter = ix.util.Bind(self, self.OnMessageSent)

	self.prefix = entryPanel:Add("ixChatboxPrefix")
	self.prefix:Dock(LEFT)

	self.preview = self:Add("ixChatboxPreview")
	self.preview:SetZPos(2) -- ensure the preview is docked above the text entry
	self.preview:Dock(BOTTOM)
	self.preview:SetTargetHeight(self.entry:GetTall())

	self.tabs = self:Add("ixChatboxTabs")
	self.tabs:Dock(FILL)
	self.tabs.OnTabChanged = ix.util.Bind(self, self.OnTabChanged)

	self.autocomplete = self.tabs:Add("ixChatboxAutocomplete")
	self.autocomplete:Dock(FILL)
	self.autocomplete:DockMargin(4, 3, 4, 4) -- top margin is 3 to account for tab 1px border
	self.autocomplete:SetZPos(3)

	self.alpha = 0
	self:SetActive(false)

	-- luacheck: globals chat
	chat.GetChatBoxPos = function()
		return self:GetPos()
	end

	chat.GetChatBoxSize = function()
		return self:GetSize()
	end
end

function PANEL:GetDefaultSize()
	return ScrW() * 0.4, ScrH() * 0.375
end

function PANEL:GetDefaultPosition()
	return chatBorder, ScrH() - self:GetTall() - chatBorder
end

DEFINE_BASECLASS("Panel")
function PANEL:SetAlpha(amount, duration)
	self:CreateAnimation(duration or animationTime, {
		index = 1,
		target = {alpha = amount},
		easing = "outQuint",

		Think = function(animation, panel)
			BaseClass.SetAlpha(panel, panel.alpha)
		end
	})
end

function PANEL:SizingInBounds()
	local screenX, screenY = self:LocalToScreen(0, 0)
	local mouseX, mouseY = gui.MousePos()

	return mouseX > screenX + self:GetWide() - sizingBorder and mouseY > screenY + self:GetTall() - sizingBorder
end

function PANEL:DraggingInBounds()
	local _, screenY = self:LocalToScreen(0, 0)
	local mouseY = gui.MouseY()

	return mouseY > screenY and mouseY < screenY + self.tabs.buttons:GetTall()
end

function PANEL:SetActive(bActive)
	if (bActive) then
		self:SetAlpha(255)
		self:MakePopup()
		self.entry:RequestFocus()

		input.SetCursorPos(self:LocalToScreen(-1, -1))

		hook.Run("StartChat")
		self.prefix:SetText(hook.Run("GetChatPrefixInfo", ""))
	else
		-- make sure we aren't still sizing/dragging anything
		if (self.bSizing or self.DragOffset) then
			self:OnMouseReleased(MOUSE_LEFT)
		end

		self:SetAlpha(0)
		self:SetMouseInputEnabled(false)
		self:SetKeyboardInputEnabled(false)

		self.autocomplete:SetVisible(false)
		self.preview:SetVisible(false)
		self.entry:SetText("")
		self.preview:SetCommand("")
		self.prefix:SetText(hook.Run("GetChatPrefixInfo", ""))

		CloseDermaMenus()
		gui.EnableScreenClicker(false)

		hook.Run("FinishChat")
	end

	local tab = self.tabs:GetActiveTab()

	if (tab) then
		-- we'll scroll to bottom even if we're opening since the SetVisible for the textentry will shift things a bit
		tab:ScrollToBottom()
	end

	self.bActive = tobool(bActive)
end

function PANEL:SetupTabs(tabs)
	if (!tabs or table.IsEmpty(tabs)) then
		self.tabs:AddTab(L("chat"), {})
		self.tabs:SetActiveTab(L("chat"))

		return
	end

	for id, filter in pairs(tabs) do
		self.tabs:AddTab(id, filter)
	end

	self.tabs:SetActiveTab(next(tabs))
end

function PANEL:SetupPosition(info)
	local x, y, width, height

	if (!istable(info)) then
		x, y = self:GetDefaultPosition()
		width, height = self:GetDefaultSize()
	else
		-- screen size may have changed so we'll need to clamp the values
		width = math.Clamp(info[3], 32, ScrW() - chatBorder * 2)
		height = math.Clamp(info[4], 32, ScrH() - chatBorder * 2)
		x = math.Clamp(info[1], 0, ScrW() - width)
		y = math.Clamp(info[2], 0, ScrH() - height)
	end

	self:SetSize(width, height)
	self:SetPos(x, y)

	PLUGIN:SavePosition()
end

function PANEL:OnMousePressed(key)
	if (key == MOUSE_RIGHT) then
		local menu = DermaMenu()
			menu:AddOption(L("chatNewTab"), function()
				if (IsValid(ix.gui.chatTabCustomize)) then
					ix.gui.chatTabCustomize:Remove()
				end

				local panel = vgui.Create("ixChatboxTabCustomize")
				panel.OnTabCreated = ix.util.Bind(self, self.OnTabCreated)
			end)

			menu:AddOption(L("chatMarkRead"), function()
				for _, v in pairs(self.tabs:GetTabs()) do
					v:GetButton():SetUnread(false)
				end
			end)

			menu:AddSpacer()

			menu:AddOption(L("chatReset"), function()
				local x, y = self:GetDefaultPosition()
				local width, height = self:GetDefaultSize()

				self:SetSize(width, height)
				self:SetPos(x, y)

				ix.option.Set("chatPosition", "")
				hook.Run("ChatboxPositionChanged", x, y, width, height)
			end)

			menu:AddOption(L("chatResetTabs"), function()
				for id, _ in pairs(self.tabs:GetTabs()) do
					self.tabs:RemoveTab(id)
				end

				ix.option.Set("chatTabs", "")
			end)
		menu:Open()
		menu:MakePopup()

		return
	end

	if (key != MOUSE_LEFT) then
		return
	end

	-- capture the mouse if we're in bounds for sizing this panel
	if (self:SizingInBounds()) then
		self.bSizing = true
		self:MouseCapture(true)
	elseif (self:DraggingInBounds()) then
		local mouseX, mouseY = self:ScreenToLocal(gui.MousePos())

		-- mouse offset relative to the panel
		self.DragOffset = {mouseX, mouseY}
		self:MouseCapture(true)
	end
end

function PANEL:OnMouseReleased()
	self:MouseCapture(false)
	self:SetCursor("arrow")

	-- save new position/size if we were dragging/resizing
	if (self.bSizing or self.DragOffset) then
		PLUGIN:SavePosition()

		self.bSizing = nil
		self.DragOffset = nil

		-- resize chat messages to fit new width
		self:InvalidateChildren(true)

		local x, y = self:GetPos()
		local width, height = self:GetSize()

		hook.Run("ChatboxPositionChanged", x, y, width, height)
	end
end

function PANEL:Think()
	if (!self.bActive) then
		return
	end

	local mouseX = math.Clamp(gui.MouseX(), 0, ScrW())
	local mouseY = math.Clamp(gui.MouseY(), 0, ScrH())

	if (self.bSizing) then
		local x, y = self:GetPos()
		local width = math.Clamp(mouseX - x, chatBorder, ScrW() - chatBorder * 2)
		local height = math.Clamp(mouseY - y, chatBorder, ScrH() - chatBorder * 2)

		self:SetSize(width, height)
		self:SetCursor("sizenwse")
	elseif (self.DragOffset) then
		local x = math.Clamp(mouseX - self.DragOffset[1], 0, ScrW() - self:GetWide())
		local y = math.Clamp(mouseY - self.DragOffset[2], 0, ScrH() - self:GetTall())

		self:SetPos(x, y)
	elseif (self:SizingInBounds()) then
		self:SetCursor("sizenwse")
	elseif (self:DraggingInBounds()) then
		-- we have to set the cursor on the list panel since that's the actual hovered panel
		self.tabs.buttons:SetCursor("sizeall")
	else
		self:SetCursor("arrow")
	end
end

function PANEL:Paint(width, height)
	local tab = self.tabs:GetActiveTab()
	local alpha = self:GetAlpha()

	derma.SkinFunc("PaintChatboxBackground", self, width, height)

	if (tab) then
		-- manually paint active tab since messages handle their own alpha lifetime
		surface.SetAlphaMultiplier(1)
			tab:PaintManual()
		surface.SetAlphaMultiplier(alpha / 255)
	end

	if (alpha > 0) then
		hook.Run("PostChatboxDraw", width, height, self:GetAlpha())
	end
end

-- get the command of the current chat class in the textentry if possible
function PANEL:GetTextEntryChatClass(text)
	text = text or self.entry:GetText()

	local chatType = ix.chat.Parse(LocalPlayer(), text, true)

	if (chatType and chatType != "ic") then
		-- OOC is the only one with two slashes as its prefix, so we'll make a special case for it here
		if (chatType == "ooc") then
			return "ooc"
		end

		local class = ix.chat.classes[chatType]

		if (istable(class.prefix)) then
			for _, v in ipairs(class.prefix) do
				if (v:utf8sub(1, 1) == "/") then
					return v:utf8sub(2):utf8lower()
				end
			end
		elseif (class.prefix:utf8sub(1, 1) == "/") then
			return class.prefix:utf8sub(2):utf8lower()
		end
	end
end

-- chatbox panel hooks
-- called when the textentry value changes
function PANEL:OnTextChanged(text)
	hook.Run("ChatTextChanged", text)

	local preview = self.preview
	local autocomplete = self.autocomplete
	local chatClassCommand = self:GetTextEntryChatClass(text)

	self.prefix:SetText(hook.Run("GetChatPrefixInfo", text))

	if (chatClassCommand) then
		preview:SetCommand(chatClassCommand)
		preview:SetVisible(true)
		preview:UpdateArguments(text)

		autocomplete:SetVisible(false)
		return
	end

	local start, _, command = text:find("(/(%w+)%s)")
	command = ix.command.list[tostring(command):utf8sub(2, tostring(command):utf8len() - 1):utf8lower()]

	-- update preview if we've found a command
	if (start == 1 and command) then
		preview:SetCommand(command.uniqueID)
		preview:SetVisible(true)
		preview:UpdateArguments(text)

		-- we don't need the autocomplete because we have a command already typed out
		autocomplete:SetVisible(false)
		return
	-- if there's a slash then we're probably going to be (or are currently) typing out a command
	elseif (text:utf8sub(1, 1) == "/") then
		command = text:match("(/(%w+))") or "/"

		preview:SetVisible(false) -- we don't have a valid command yet
		autocomplete:Update(command:utf8sub(2))
		autocomplete:SetVisible(true)

		return
	end

	if (preview:GetCommand() != "") then
		preview:SetCommand("")
		preview:SetVisible(false)
	end

	if (autocomplete:IsVisible()) then
		autocomplete:SetVisible(false)
	end
end

DEFINE_BASECLASS("DTextEntry")
function PANEL:OnKeyCodeTyped(key)
	if (key == KEY_TAB) then
		if (self.autocomplete:IsOpen() and #self.autocomplete:GetCommands() > 0) then
			local newText = self.autocomplete:SelectNext()

			self.entry:SetText(newText)
			self.entry:SetCaretPos(newText:utf8len())
		end

		return true
	end

	return BaseClass.OnKeyCodeTyped(self.entry, key)
end

-- called when player types something and presses enter in the textentry
function PANEL:OnMessageSent()
	local text = self.entry:GetText()

	if (text:find("%S")) then
		local lastEntry = ix.chat.history[#ix.chat.history]

		-- only add line to textentry history if it isn't the same message
		if (lastEntry != text) then
			if (#ix.chat.history >= 20) then
				table.remove(ix.chat.history, 1)
			end

			ix.chat.history[#ix.chat.history + 1] = text
		end

		net.Start("ixChatMessage")
			net.WriteString(text)
		net.SendToServer()
	end

	self:SetActive(false) -- textentry is set to "" in SetActive
end

-- called when the player changes the currently active tab
function PANEL:OnTabChanged(panel)
	panel:InvalidateLayout(true)
	panel:ScrollToBottom()
end

-- called when the player creates a new tab
function PANEL:OnTabCreated(id, filter)
	self.tabs:AddTab(id, filter)
	PLUGIN:SaveTabs()
end

-- called when the player updates a tab's filter
function PANEL:OnTabUpdated(id, filter, newID)
	local tab = self.tabs:GetTabs()[id]

	if (!tab) then
		return
	end

	tab:SetFilter(filter)
	self.tabs:RenameTab(id, newID)

	PLUGIN:SaveTabs()
end

-- called when a tab's button was right-clicked
function PANEL:OnTabRightClick(button, tab, id)
	local menu = DermaMenu()
		menu:AddOption(L("chatCustomize"), function()
			if (IsValid(ix.gui.chatTabCustomize)) then
				ix.gui.chatTabCustomize:Remove()
			end

			local panel = vgui.Create("ixChatboxTabCustomize")
			panel:PopulateFromTab(id, tab:GetFilter())
			panel.OnTabUpdated = ix.util.Bind(self, self.OnTabUpdated)
		end)

		menu:AddSpacer()

		menu:AddOption(L("chatCloseTab"), function()
			self.tabs:RemoveTab(id)
			PLUGIN:SaveTabs()
		end)
	menu:Open()
	menu:MakePopup() -- HACK: mouse input doesn't work when created immediately after opening chatbox
end

-- called when a message needs to be added to applicable tabs
function PANEL:AddMessage(...)
	local class = CHAT_CLASS and CHAT_CLASS.uniqueID or "notice"
	local activeTab = self.tabs:GetActiveTab()

	-- track whether or not the message was filtered out in the active tab
	local bShown = false

	if (activeTab and !activeTab:GetFilter()[class]) then
		activeTab:AddLine({...}, true)
		bShown = true
	end

	for _, v in pairs(self.tabs:GetTabs()) do
		if (v:GetID() == activeTab:GetID()) then
			continue -- we already added it to the active tab
		end

		if (!v:GetFilter()[class]) then
			v:AddLine({...}, true)

			-- mark other tabs as unread if we didn't show the message in the active tab
			if (!bShown) then
				v:GetButton():SetUnread(true)
			end
		end
	end

	if (bShown) then
		chat.PlaySound()
	end
end

vgui.Register("ixChatbox", PANEL, "EditablePanel")
