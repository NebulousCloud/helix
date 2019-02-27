
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
PANEL = {}

AccessorFunc(PANEL, "bChecked", "Checked", FORCE_BOOL)
AccessorFunc(PANEL, "animationTime", "AnimationTime", FORCE_NUMBER)
AccessorFunc(PANEL, "labelPadding", "LabelPadding", FORCE_NUMBER)

PANEL.GetValue = PANEL.GetChecked

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetCursor("hand")

	self.labelPadding = 8

	self.animationOffset = 0
	self.animationTime = 0.5
	self.bChecked = false

	surface.SetFont("ixMenuButtonFont")
	self:SetWide(math.max(surface.GetTextSize(L("yes")), surface.GetTextSize(L("no"))) + self.labelPadding)
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
	surface.SetFont("ixMenuButtonFont")

	local text = L("no"):upper()
	local textWidth, textHeight = surface.GetTextSize(text)
	local y = offset * -textHeight

	surface.SetTextColor(Color(250, 60, 60, 255))
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, y + height * 0.5 - textHeight * 0.5)
	surface.DrawText(text)

	text = L("yes"):upper()
	y = y + textHeight
	textWidth, textHeight = surface.GetTextSize(text)

	surface.SetTextColor(Color(30, 250, 30, 255))
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
		self.label:SetText(tostring(panel:GetValue()))
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
	self.label:SetText(tostring(self.slider:GetValue()))
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

-- label with custom kerning
PANEL = {}

AccessorFunc(PANEL, "text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "color", "TextColor")
AccessorFunc(PANEL, "kerning", "Kerning", FORCE_NUMBER) -- in px
AccessorFunc(PANEL, "font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "bCentered", "Centered", FORCE_BOOL)
AccessorFunc(PANEL, "bDrawShadow", "ExpensiveShadow")

function PANEL:Init()
	self.text = ""
	self.color = color_white
	self.kerning = 2
	self.font = "DermaDefault"
	self.bCentered = false

	self.shadowDistance = 0
	self.color = color_black
end

function PANEL:SetText(text)
	self.text = tostring(text)
	self:GetContentSize(true)
end

function PANEL:SetExpensiveShadow(distance, color) -- we'll retain similar naming to the DLabel shadow
	self.shadowDistance = distance or 1
	self.shadowColor = ix.util.DimColor(self.color, 0.5)
end

function PANEL:Paint(width, height)
	surface.SetFont(self.font)
	local x = self.bCentered and (width * 0.5 - self:GetContentSize() * 0.5) or 0

	for i = 1, #self.text do
		local character = self.text[i]
		local textWidth, _ = surface.GetTextSize(character)
		local kerning = i == 1 and 0 or self.kerning
		local shadowDistance = self.shadowDistance

		-- shadow
		if (self.shadowDistance > 0) then
			surface.SetTextColor(self.shadowColor)
			surface.SetTextPos(x + kerning + shadowDistance, shadowDistance)
			surface.DrawText(character)
		end

		-- character
		surface.SetTextColor(self.color)
		surface.SetTextPos(x + kerning, 0)
		surface.DrawText(character)

		x = x + textWidth + kerning
	end
end

function PANEL:GetContentSize(bCalculate)
	if (bCalculate or !self.contentSize) then
		local width = 0
		surface.SetFont(self.font)

		for i = 1, #self.text do
			local textWidth, _ = surface.GetTextSize(self.text[i])
			width = width + textWidth + self.kerning
		end

		self.contentSize = {width, draw.GetFontHeight(self.font)}
	end

	return self.contentSize[1], self.contentSize[2]
end

function PANEL:SizeToContents()
	self:SetSize(self:GetContentSize(true))
end

vgui.Register("ixKLabel", PANEL, "Panel")

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

	self:DockMargin(self.iconWidth + 2, 0, 0, 8)
end

function PANEL:Paint(width, height)
	BaseClass.Paint(self, width, height)

	-- there's no inset for text entries so we'll have to get creative
	DisableClipping(true)
		surface.SetDrawColor(self:GetBackgroundColor())
		surface.DrawRect(-self.iconWidth - 2, 0, self.iconWidth + 2, height)

		surface.SetFont("ixSmallTitleIcons")
		surface.SetTextColor(self.iconColor)
		surface.SetTextPos(-self.iconWidth, 0)
		surface.DrawText("V")
	DisableClipping(false)
end

vgui.Register("ixIconTextEntry", PANEL, "ixTextEntry")
