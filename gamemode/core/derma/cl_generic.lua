
-- generic panels that are applicable anywhere

-- used for prominent text entries
DEFINE_BASECLASS("DTextEntry")
local PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")

function PANEL:Init()
	self:SetPaintBackground(false)
	self:SetTextColor(color_white)

	self.backgroundColor = Color(255, 255, 255, 25)
end

function PANEL:SetFont(font)
	surface.SetFont(font)
	local _, height = surface.GetTextSize("W@")

	self:SetTall(height)
	BaseClass.SetFont(self, font)
end

function PANEL:Paint(width, height)
	derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, self.backgroundColor)
	BaseClass.Paint(self, width, height)
end

vgui.Register("ixTextEntry", PANEL, "DTextEntry")

-- similar to a frame, but is mainly used for grouping panels together in a list
PANEL = {}

AccessorFunc(PANEL, "text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "color", "Color")

function PANEL:Init()
	self.text = ""
	self.paddingTop = 32

	local skin = self:GetSkin()

	if (skin and skin.fontCategoryBlur) then
		surface.SetFont(skin.fontCategoryBlur)
		self.paddingTop = select(2, surface.GetTextSize("W@")) + 6
	end

	self:DockPadding(1, self.paddingTop, 1, 1)
end

function PANEL:SizeToContents()
	local height = self.paddingTop + 1

	for _, v in ipairs(self:GetChildren()) do
		if (IsValid(v) and v:IsVisible()) then
			local _, top, _, bottom = v:GetDockMargin()

			height = height + v:GetTall() + top + bottom
		end
	end

	self:SetTall(height)
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintCategoryPanel", self, self.text, self.color)
end

vgui.Register("ixCategoryPanel", PANEL, "EditablePanel")

-- segmented progress bar
PANEL = {}

AccessorFunc(PANEL, "font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "barColor", "BarColor")
AccessorFunc(PANEL, "textColor", "TextColor")
AccessorFunc(PANEL, "progress", "Progress", FORCE_NUMBER)
AccessorFunc(PANEL, "padding", "Padding", FORCE_NUMBER)
AccessorFunc(PANEL, "animationTime", "AnimationTime", FORCE_NUMBER)
AccessorFunc(PANEL, "easingType", "EasingType", FORCE_STRING)

function PANEL:Init()
	self.segments = {}
	self.padding = ScrH() * 0.01
	self.fraction = 0
	self.animationTime = 0.5
	self.easingType = "outQuint"
	self.progress = 0
end

function PANEL:AddSegment(text)
	local id = #self.segments + 1

	if (text:sub(1, 1) == "@") then
		text = L(text:sub(2))
	end

	self.segments[id] = text
	return id
end

function PANEL:AddSegments(...)
	local segments = {...}

	for i = 1, #segments do
		self:AddSegment(segments[i])
	end
end

function PANEL:GetSegments()
	return self.segments
end

function PANEL:SetProgress(segment)
	self.progress = math.Clamp(segment, 0, #self.segments)

	self:CreateAnimation(self.animationTime, {
		target = {fraction = self.progress / #self.segments},
		easing = self.easingType
	})
end

function PANEL:IncrementProgress(amount)
	self:SetProgress(self.progress + (amount or 1))
end

function PANEL:DecrementProgress(amount)
	self:SetProgress(self.progress - (amount or 1))
end

function PANEL:GetFraction()
	return self.fraction
end

function PANEL:SizeToContents()
	self:SetTall(draw.GetFontHeight(self.font or self:GetSkin().fontSegmentedProgress) + self.padding)
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintSegmentedProgressBackground", self, width, height)

	if (#self.segments > 0) then
		derma.SkinFunc("PaintSegmentedProgress", self, width, height)
	end
end

vgui.Register("ixSegmentedProgress", PANEL, "Panel")

-- list of labelled information
PANEL = {}

AccessorFunc(PANEL, "labelColor", "LabelColor")
AccessorFunc(PANEL, "textColor", "TextColor")
AccessorFunc(PANEL, "list", "List")
AccessorFunc(PANEL, "minWidth", "MinimumWidth", FORCE_NUMBER)

function PANEL:Init()
	self.label = self:Add("DLabel")
	self.label:SetFont("ixMediumFont")
	self.label:SetExpensiveShadow(1)
	self.label:SetTextColor(color_white)
	self.label:SetText("Label")
	self.label:SetContentAlignment(5)
	self.label:Dock(LEFT)
	self.label:DockMargin(0, 0, 4, 0)
	self.label:SizeToContents()
	self.label.Paint = function(this, width, height)
		derma.SkinFunc("PaintListRow", this, width, height)
	end

	self.text = self:Add("DLabel")
	self.text:SetFont("ixMediumLightFont")
	self.text:SetTextColor(color_white)
	self.text:SetText("Text")
	self.text:SetTextInset(8, 0)
	self.text:Dock(FILL)
	self.text:DockMargin(4, 0, 0, 0)
	self.text:SizeToContents()
	self.text.Paint = function(this, width, height)
		derma.SkinFunc("PaintListRow", this, width, height)
	end

	self:DockMargin(0, 0, 0, 8)

	self.list = {}
	self.minWidth = 100
end

function PANEL:SetRightPanel(panel)
	self.text:Remove()

	self.text = self:Add(panel)
	self.text:Dock(FILL)
	self.text:DockMargin(8, 4, 4, 4)
	self.text:SizeToContents()
end

function PANEL:SetList(list, bNoAdd)
	if (!bNoAdd) then
		list[#list + 1] = self
	end

	self.list = list
end

function PANEL:UpdateLabelWidths()
	local maxWidth = self.label:GetWide()

	for i = 1, #self.list do
		maxWidth = math.max(self.list[i]:GetLabelWidth(), maxWidth)
	end

	maxWidth = math.max(self.minWidth, maxWidth)

	for i = 1, #self.list do
		self.list[i]:SetLabelWidth(maxWidth)
	end
end

function PANEL:SetLabelColor(color)
	self.label:SetTextColor(color)
end

function PANEL:SetTextColor(color)
	self.text:SetTextColor(color)
end

function PANEL:SetLabelText(text)
	self.label:SetText(text)
	self.label:SizeToContents()

	self:UpdateLabelWidths()
end

function PANEL:SetText(text)
	self.text:SetText(text)
	self.text:SizeToContents()
end

function PANEL:SetLabelWidth(width)
	self.label:SetWide(width)
end

function PANEL:GetLabelWidth(bWithoutMargin)
	if (!bWithoutMargin) then
		return self.label:GetWide()
	end

	local left, _, right, _ = self.label:GetDockMargin()
	return self.label:GetWide() + left + right
end

function PANEL:SizeToContents()
	self:SetTall(math.max(self.label:GetTall(), self.text:GetTall()) + 8)
end

vgui.Register("ixListRow", PANEL, "Panel")

-- alternative checkbox
DEFINE_BASECLASS("EditablePanel")
PANEL = {}

AccessorFunc(PANEL, "enabledText", "EnabledText", FORCE_STRING)
AccessorFunc(PANEL, "disabledText", "DisabledText", FORCE_STRING)
AccessorFunc(PANEL, "font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "bChecked", "Checked", FORCE_BOOL)
AccessorFunc(PANEL, "animationTime", "AnimationTime", FORCE_NUMBER)
AccessorFunc(PANEL, "labelPadding", "LabelPadding", FORCE_NUMBER)

PANEL.GetValue = PANEL.GetChecked

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetCursor("hand")

	self.enabledText = L("yes"):utf8upper()
	self.disabledText = L("no"):utf8upper()
	self.font = "ixMenuButtonFont"
	self.animationTime = 0.5
	self.bChecked = false
	self.labelPadding = 8
	self.animationOffset = 0

	self:SizeToContents()
end

function PANEL:SizeToContents()
	BaseClass.SizeToContents(self)

	surface.SetFont(self.font)
	self:SetWide(math.max(surface.GetTextSize(self.enabledText), surface.GetTextSize(self.disabledText)) + self.labelPadding)
end

-- can be overidden to change audio params
function PANEL:GetAudioFeedback()
	return "weapons/ar2/ar2_empty.wav", 75, self.bChecked and 150 or 125, 0.25
end

function PANEL:EmitFeedback()
	LocalPlayer():EmitSound(self:GetAudioFeedback())
end

function PANEL:SetChecked(bChecked, bInstant)
	self.bChecked = tobool(bChecked)

	self:CreateAnimation(bInstant and 0 or self.animationTime, {
		index = 1,
		target = {
			animationOffset = bChecked and 1 or 0
		},
		easing = "outElastic"
	})

	if (!bInstant) then
		self:EmitFeedback()
	end
end

function PANEL:OnMousePressed(code)
	if (code == MOUSE_LEFT) then
		self:SetChecked(!self.bChecked)
		self:DoClick()
	end
end

function PANEL:DoClick()
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(derma.GetColor("DarkerBackground", self))
	surface.DrawRect(0, 0, width, height)

	local offset = self.animationOffset
	surface.SetFont(self.font)

	local text = self.disabledText
	local textWidth, textHeight = surface.GetTextSize(text)
	local y = offset * -textHeight

	surface.SetTextColor(250, 60, 60, 255)
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, y + height * 0.5 - textHeight * 0.5)
	surface.DrawText(text)

	text = self.enabledText
	y = y + textHeight
	textWidth, textHeight = surface.GetTextSize(text)

	surface.SetTextColor(30, 250, 30, 255)
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, y + height * 0.5 - textHeight * 0.5)
	surface.DrawText(text)
end

vgui.Register("ixCheckBox", PANEL, "EditablePanel")

-- alternative num slider
PANEL = {}

AccessorFunc(PANEL, "labelPadding", "LabelPadding", FORCE_NUMBER)

function PANEL:Init()
	self.labelPadding = 8

	surface.SetFont("ixMenuButtonFont")
	local totalWidth = surface.GetTextSize("999") -- start off with 3 digit width

	self.label = self:Add("DLabel")
	self.label:Dock(RIGHT)
	self.label:SetWide(totalWidth + self.labelPadding)
	self.label:SetContentAlignment(5)
	self.label:SetFont("ixMenuButtonFont")
	self.label.Paint = function(panel, width, height)
		surface.SetDrawColor(derma.GetColor("DarkerBackground", self))
		surface.DrawRect(0, 0, width, height)
	end
	self.label.SizeToContents = function(panel)
		surface.SetFont(panel:GetFont())
		local textWidth = surface.GetTextSize(panel:GetText())

		if (textWidth > totalWidth) then
			panel:SetWide(textWidth + self.labelPadding)
		elseif (panel:GetWide() > totalWidth + self.labelPadding) then
			panel:SetWide(totalWidth + self.labelPadding)
		end
	end

	self.slider = self:Add("ixSlider")
	self.slider:Dock(FILL)
	self.slider:DockMargin(0, 0, 4, 0)
	self.slider.OnValueChanged = function(panel)
		self:OnValueChanged()
	end
	self.slider.OnValueUpdated = function(panel)
		self.label:SetText(string.format("%0." .. tostring(panel:GetDecimals()) .. "f", tostring(panel:GetValue())))
		self.label:SizeToContents()

		self:OnValueUpdated()
	end
end

function PANEL:GetLabel()
	return self.label
end

function PANEL:GetSlider()
	return self.slider
end

function PANEL:SetValue(value, bNoNotify)
	value = tonumber(value) or self.slider:GetMin()

	self.slider:SetValue(value, bNoNotify)
	self.label:SetText(string.format("%0." .. tostring(self:GetDecimals()) .. "f", tostring(self.slider:GetValue())))
	self.label:SizeToContents()
end

function PANEL:GetValue()
	return self.slider:GetValue()
end

function PANEL:GetFraction()
	return self.slider:GetFraction()
end

function PANEL:GetVisualFraction()
	return self.slider:GetVisualFraction()
end

function PANEL:SetMin(value)
	self.slider:SetMin(value)
end

function PANEL:SetMax(value)
	self.slider:SetMax(value)
end

function PANEL:GetMin()
	return self.slider:GetMin()
end

function PANEL:GetMax()
	return self.slider:GetMax()
end

function PANEL:SetDecimals(value)
	self.slider:SetDecimals(value)
end

function PANEL:GetDecimals()
	return self.slider:GetDecimals()
end

-- called when changed by user
function PANEL:OnValueChanged()
end

-- called when changed while dragging bar
function PANEL:OnValueUpdated()
end

vgui.Register("ixNumSlider", PANEL, "Panel")

-- alternative slider
PANEL = {}

AccessorFunc(PANEL, "bDragging", "Dragging", FORCE_BOOL)
AccessorFunc(PANEL, "min", "Min", FORCE_NUMBER)
AccessorFunc(PANEL, "max", "Max", FORCE_NUMBER)
AccessorFunc(PANEL, "decimals", "Decimals", FORCE_NUMBER)

function PANEL:Init()
	self.min = 0
	self.max = 10
	self.value = 0
	self.visualValue = 0
	self.decimals = 0

	self:SetCursor("hand")
end

function PANEL:SetValue(value, bNoNotify)
	self.value = math.Clamp(math.Round(tonumber(value) or self.min, self.decimals), self.min, self.max)
	self:ValueUpdated(bNoNotify)

	if (!bNoNotify) then
		self:OnValueChanged()
	end
end

function PANEL:GetValue()
	return self.value
end

function PANEL:GetFraction()
	return math.Remap(self.value, self.min, self.max, 0, 1)
end

function PANEL:GetVisualFraction()
	return math.Remap(self.visualValue, self.min, self.max, 0, 1)
end

function PANEL:OnMousePressed(key)
	if (key == MOUSE_LEFT) then
		self.bDragging = true
		self:MouseCapture(true)

		self:OnCursorMoved(self:CursorPos())
	end
end

function PANEL:OnMouseReleased(key)
	if (self.bDragging) then
		self:OnValueChanged()
	end

	self.bDragging = false
	self:MouseCapture(false)
end

function PANEL:OnCursorMoved(x, y)
	if (!self.bDragging) then
		return
	end

	x = math.Clamp(x, 0, self:GetWide())
	local oldValue = self.value

	self.value = math.Clamp(math.Round(
		math.Remap(x / self:GetWide(), 0, 1, self.min, self.max), self.decimals
	), self.min, self.max)

	self:CreateAnimation(0.5, {
		index = 1,
		target = {visualValue = self.value},
		easing = "outQuint"
	})

	if (self.value != oldValue) then
		self:ValueUpdated()
	end
end

function PANEL:OnValueChanged()
end

function PANEL:ValueUpdated(bNoNotify)
	self:CreateAnimation(bNoNotify and 0 or 0.5, {
		index = 1,
		target = {visualValue = self.value},
		easing = "outQuint"
	})

	if (!bNoNotify) then
		self:OnValueUpdated()
	end
end

function PANEL:OnValueUpdated()
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintHelixSlider", self, width, height)
end

vgui.Register("ixSlider", PANEL, "EditablePanel")

--- Alternative to DLabel that adds extra functionality.
-- This panel is meant for drawing single-line text. It can add extra kerning (spaces between letters), and it can forcefully
-- scale the text down to fit the current width, without cutting off any letters. Text scaling is most useful when docking this
-- this panel without knowing what the width could be. For example, text scaling is used for the character name in the character
-- status menu.
-- 	local label = vgui.Create("ixLabel")
-- 	label:SetText("hello world")
-- 	label:SetFont("ixMenuButtonHugeFont")
-- 	label:SetContentAlignment(5)
-- 	label:SetTextColor(Color(255, 255, 255, 255))
-- 	label:SetBackgroundColor(Color(200, 30, 30, 255))
-- 	label:SetPadding(8)
-- 	label:SetScaleWidth(true)
-- 	label:SizeToContents()
-- @panel ixLabel
PANEL = {}

--- Sets the text for this label to display.
-- @realm client
-- @string text Text to display
-- @function SetText

--- Returns the current text for this panel.
-- @realm client
-- @treturn string Current text
-- @function GetText
AccessorFunc(PANEL, "text", "Text", FORCE_STRING)

--- Sets the color of the text to use when drawing.
-- @realm client
-- @color color New color to use
-- @function SetTextColor

--- Returns the current text color for this panel.
-- @realm client
-- @treturn color Current text color
-- @function GetTextColor
AccessorFunc(PANEL, "color", "TextColor")

--- Sets the color of the background to draw behind the text.
-- @realm client
-- @color color New color to use
-- @function SetBackgroundColor

--- Returns the current background color for this panel.
-- @realm client
-- @treturn color Current background color
-- @function GetBackgroundColor
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")

--- Sets the spacing between each character of the text in pixels. Set to `0` to disable. Kerning is disabled by default.
-- @realm client
-- @number kerning How far apart to draw each letter
-- @function SetKerning

--- Returns the current kerning for this panel.
-- @realm client
-- @treturn number Current kerning
-- @function GetKerning
AccessorFunc(PANEL, "kerning", "Kerning", FORCE_NUMBER)

--- Sets the font used to draw the text.
-- @realm client
-- @string font Name of the font to use
-- @function SetFont

--- Returns the current font for this panel.
-- @realm client
-- @treturn string Name of current font
-- @function GetFont
AccessorFunc(PANEL, "font", "Font", FORCE_STRING)

--- Changes how the text is aligned when drawing. Valid content alignment values include numbers `1` through `9`. Each number's
-- corresponding alignment is based on its position on a numpad. For example, `1` is bottom-left, `5` is centered, `9` is
-- top-right, etc.
-- @realm client
-- @number alignment Alignment to use
-- @function SetContentAlignment

--- Returns the current content alignment for this panel.
-- @realm client
-- @treturn number Current content alignment
-- @function GetContentAlignment
AccessorFunc(PANEL, "contentAlignment", "ContentAlignment", FORCE_NUMBER)

--- Whether or not to scale the width of the text down to fit the width of this panel, if needed.
-- @realm client
-- @bool bScale Whether or not to scale
-- @function SetScaleWidth

--- Returns whether or not this panel will scale its text down to fit its width.
-- @realm client
-- @treturn bool Whether or not this panel will scale its text
-- @function GetScaleWidth
AccessorFunc(PANEL, "bScaleWidth", "ScaleWidth", FORCE_BOOL)

--- How much spacing to use around the text when its drawn. This uses uniform padding on the top, left, right, and bottom of
-- this panel.
-- @realm client
-- @number padding Padding to use
-- @function SetPadding

--- Returns how much padding this panel has around its text.
-- @realm client
-- @treturn number Current padding
-- @function GetPadding
AccessorFunc(PANEL, "padding", "Padding", FORCE_NUMBER)

function PANEL:Init()
	self.text = ""
	self.color = color_white
	self.backgroundColor = Color(255, 255, 255, 0)
	self.kerning = 0
	self.font = "DermaDefault"
	self.scaledFont = "DermaDefault"
	self.contentAlignment = 5
	self.bScaleWidth = false
	self.padding = 0

	self.shadowDistance = 0
	self.bCurrentlyScaling = false
end

function PANEL:SetText(text)
	self.text = tostring(text)
end

function PANEL:SetFont(font)
	self.font = font
	self.scaledFont = font
end

--- Sets the drop shadow to draw behind the text.
-- @realm client
-- @number distance How far away to draw the shadow in pixels. Set to `0` to disable
-- @color[opt] color Color of the shadow. Defaults to a dimmed version of the text color
function PANEL:SetDropShadow(distance, color)
	self.shadowDistance = distance or 1
	self.shadowColor = color or ix.util.DimColor(self.color, 0.5)
end

PANEL.SetExpensiveShadow = PANEL.SetDropShadow -- aliasing for easier conversion from DLabels

--- Returns the X and Y location of the text taking into account the text alignment and padding.
-- @realm client
-- @internal
-- @number width Width of the panel
-- @number height Height of the panel
-- @number textWidth Width of the text
-- @number textHeight Height of the text
-- @treturn number X location to draw the text
-- @treturn number Y location to draw the text
function PANEL:CalculateAlignment(width, height, textWidth, textHeight)
	local alignment = self.contentAlignment
	local x, y

	if (self.bCurrentlyScaling) then
		-- if the text is currently being scaled down, then it's always centered
		x = width * 0.5 - textWidth * 0.5
	else
		-- x alignment
		if (alignment == 7 or alignment == 4 or alignment == 1) then
			-- left
			x = self.padding
		elseif (alignment == 8 or alignment == 5 or alignment == 2) then
			-- center
			x = width * 0.5 - textWidth * 0.5
		elseif (alignment == 9 or alignment == 6 or alignment == 3) then
			x = width - textWidth - self.padding
		end
	end

	-- y alignment
	if (alignment <= 3) then
		-- bottom
		y = height - textHeight - self.padding
	elseif (alignment <= 6) then
		-- center
		y = height * 0.5 - textHeight * 0.5
	else
		-- top
		y = self.padding
	end

	return x, y
end

--- Draws the current text with the current kerning.
-- @realm client
-- @internal
-- @number width Width of the panel
-- @number height Height of the panel
function PANEL:DrawKernedText(width, height)
	local contentWidth, contentHeight = self:GetContentSize()
	local x, y = self:CalculateAlignment(width, height, contentWidth, contentHeight)

	for i = 1, self.text:utf8len() do
		local character = self.text:utf8sub(i, i)
		local textWidth, _ = surface.GetTextSize(character)
		local kerning = i == 1 and 0 or self.kerning
		local shadowDistance = self.shadowDistance

		-- shadow
		if (self.shadowDistance > 0) then
			surface.SetTextColor(self.shadowColor)
			surface.SetTextPos(x + kerning + shadowDistance, y + shadowDistance)
			surface.DrawText(character)
		end

		-- character
		surface.SetTextColor(self.color)
		surface.SetTextPos(x + kerning, y)
		surface.DrawText(character)

		x = x + textWidth + kerning
	end
end

--- Draws the current text.
-- @realm client
-- @internal
-- @number width Width of the panel
-- @number height Height of the panel
function PANEL:DrawText(width, height)
	local textWidth, textHeight = surface.GetTextSize(self.text)
	local x, y = self:CalculateAlignment(width, height, textWidth, textHeight)

	-- shadow
	if (self.shadowDistance > 0) then
		surface.SetTextColor(self.shadowColor)
		surface.SetTextPos(x + self.shadowDistance, y + self.shadowDistance)
		surface.DrawText(self.text)
	end

	-- text
	surface.SetTextColor(self.color)
	surface.SetTextPos(x, y)
	surface.DrawText(self.text)
end

function PANEL:Paint(width, height)
	surface.SetFont(self.font)
	surface.SetDrawColor(self.backgroundColor)
	surface.DrawRect(0, 0, width, height)

	if (self.bScaleWidth) then
		local contentWidth, contentHeight = self:GetContentSize()

		if (contentWidth > (width - self.padding * 2)) then
			local x, y = self:LocalToScreen(self:GetPos())
			local scale = width / (contentWidth + self.padding * 2)
			local translation = Vector(x + width * 0.5, y - contentHeight * 0.5 + self.padding, 0)
			local matrix = Matrix()

			matrix:Translate(translation)
			matrix:Scale(Vector(scale, scale, 0))
			matrix:Translate(-translation)

			cam.PushModelMatrix(matrix, true)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
			DisableClipping(true)

			self.bCurrentlyScaling = true
		end
	end

	if (self.kerning > 0) then
		self:DrawKernedText(width, height)
	else
		self:DrawText(width, height)
	end

	if (self.bCurrentlyScaling) then
		DisableClipping(false)
		render.PopFilterMin()
		cam.PopModelMatrix()

		self.bCurrentlyScaling = false
	end
end

--- Returns the size of the text, taking into account the current kerning.
-- @realm client
-- @bool[opt=false] bCalculate Whether or not to recalculate the content size instead of using the cached copy
-- @treturn number Width of the text
-- @treturn number Height of the text
function PANEL:GetContentSize(bCalculate)
	if (bCalculate or !self.contentSize) then
		surface.SetFont(self.font)

		if (self.kerning > 0) then
			local width = 0

			for i = 1, self.text:utf8len() do
				local textWidth, _ = surface.GetTextSize(self.text:utf8sub(i, i))
				width = width + textWidth + self.kerning
			end

			self.contentSize = {width, draw.GetFontHeight(self.font)}
		else
			self.contentSize = {surface.GetTextSize(self.text)}
		end
	end

	return self.contentSize[1], self.contentSize[2]
end

--- Sets the size of the panel to fit the content size with the current padding. The content size is recalculated when this
-- method is called.
-- @realm client
function PANEL:SizeToContents()
	local contentWidth, contentHeight = self:GetContentSize(true)

	self:SetSize(contentWidth + self.padding * 2, contentHeight + self.padding * 2)
end

vgui.Register("ixLabel", PANEL, "Panel")

-- text entry with icon
DEFINE_BASECLASS("ixTextEntry")
PANEL = {}

AccessorFunc(PANEL, "icon", "Icon", FORCE_STRING)
AccessorFunc(PANEL, "iconColor", "IconColor")

function PANEL:Init()
	self:SetIcon("V")
	self:SetFont("ixSmallTitleFont")

	self.iconColor = Color(200, 200, 200, 160)
end

function PANEL:SetIcon(newIcon)
	surface.SetFont("ixSmallTitleIcons")

	self.iconWidth, self.iconHeight = surface.GetTextSize(newIcon)
	self.icon = newIcon

	self:DockMargin(self.iconWidth + 4, 0, 0, 8)
end

function PANEL:Paint(width, height)
	BaseClass.Paint(self, width, height)

	-- there's no inset for text entries so we'll have to get creative
	DisableClipping(true)
		surface.SetDrawColor(self:GetBackgroundColor())
		surface.DrawRect(-self.iconWidth - 4, 0, self.iconWidth + 4, height)

		surface.SetFont("ixSmallTitleIcons")
		surface.SetTextColor(self.iconColor)
		surface.SetTextPos(-self.iconWidth - 2, 0)
		surface.DrawText(self:GetIcon())
	DisableClipping(false)
end

vgui.Register("ixIconTextEntry", PANEL, "ixTextEntry")
