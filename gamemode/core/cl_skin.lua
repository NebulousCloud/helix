
local gradient = surface.GetTextureID("vgui/gradient-d")
local gradientUp = surface.GetTextureID("vgui/gradient-u")
local gradientLeft = surface.GetTextureID("vgui/gradient-l")
local gradientRadial = Material("helix/gui/radial-gradient.png")
local defaultBackgroundColor = Color(30, 30, 30, 200)

local SKIN = {}
derma.DefineSkin("helix", "The base skin for the Helix framework.", SKIN)

SKIN.fontCategory = "ixMediumLightFont"
SKIN.fontCategoryBlur = "ixMediumLightBlurFont"
SKIN.fontSegmentedProgress = "ixMediumLightFont"

SKIN.Colours = table.Copy(derma.SkinList.Default.Colours)

SKIN.Colours.Info = Color(100, 185, 255)
SKIN.Colours.Success = Color(64, 185, 85)
SKIN.Colours.Error = Color(255, 100, 100)
SKIN.Colours.Warning = Color(230, 180, 0)
SKIN.Colours.MenuLabel = color_white
SKIN.Colours.DarkerBackground = Color(0, 0, 0, 77)

SKIN.Colours.SegmentedProgress = {}
SKIN.Colours.SegmentedProgress.Bar = Color(64, 185, 85)
SKIN.Colours.SegmentedProgress.Text = color_white

SKIN.Colours.Area = {}

SKIN.Colours.Window.TitleActive = Color(0, 0, 0)
SKIN.Colours.Window.TitleInactive = color_white

SKIN.Colours.Button.Normal = color_white
SKIN.Colours.Button.Hover = color_white
SKIN.Colours.Button.Down = Color(180, 180, 180)
SKIN.Colours.Button.Disabled = Color(0, 0, 0, 100)

SKIN.Colours.Label.Default = color_white

function SKIN.tex.Menu_Strip(x, y, width, height, color)
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(x, y, width, height)

	surface.SetDrawColor(ColorAlpha(color or ix.config.Get("color"), 175))
	surface.SetTexture(gradient)
	surface.DrawTexturedRect(x, y, width, height)

	surface.SetTextColor(color_white)
end

hook.Add("ColorSchemeChanged", "ixSkin", function(color)
	SKIN.Colours.Area.Background = color
end)

function SKIN:DrawHelixCurved(x, y, radius, segments, barHeight, fraction, color)
	radius = radius or math.min(ScreenScale(72), 128) * 2
	segments = segments or 76
	barHeight = barHeight or 64
	color = color or ix.config.Get("color")
	fraction = fraction or 1

	surface.SetTexture(-1)

	for i = 1, math.ceil(segments) do
		local angle = math.rad((i / segments) * -360)
		local barX = x + math.sin(angle + (fraction * math.pi * 2)) * radius
		local barY = y + math.cos(angle + (fraction * math.pi * 2)) * radius
		local barOffset = math.sin(SysTime() + i * 0.5)

		if (barOffset > 0) then
			surface.SetDrawColor(color)
		else
			surface.SetDrawColor(Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a))
		end

		surface.DrawTexturedRectRotated(barX, barY, 4, barOffset * (barHeight * fraction), math.deg(angle))
	end
end

function SKIN:DrawHelix(x, y, width, height, segments, color, fraction, speed)
	segments = segments or width * 0.05
	color = color or ix.config.Get("color")
	fraction = fraction or 0.25
	speed = speed or 1

	for i = 1, math.ceil(segments) do
		local offset = math.sin((SysTime() + speed) + i * fraction)
		local barHeight = height * offset

		surface.SetTexture(-1)

		if (offset > 0) then
			surface.SetDrawColor(color)
		else
			surface.SetDrawColor(Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a))
		end

		surface.DrawTexturedRectRotated(x + (i / segments) * width, y + height * 0.5, 4, barHeight, 0)
	end
end

function SKIN:PaintFrame(panel)
	if (!panel.bNoBackgroundBlur) then
		ix.util.DrawBlur(panel, 10)
	end

	surface.SetDrawColor(30, 30, 30, 150)
	surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())

	if (panel:GetTitle() != "" or panel.btnClose:IsVisible()) then
		surface.SetDrawColor(ix.config.Get("color"))
		surface.DrawRect(0, 0, panel:GetWide(), 24)

		if (panel.bHighlighted) then
			self:DrawImportantBackground(0, 0, panel:GetWide(), 24, ColorAlpha(color_white, 22))
		end
	end

	surface.SetDrawColor(ix.config.Get("color"))
	surface.DrawOutlinedRect(0, 0, panel:GetWide(), panel:GetTall())
end

function SKIN:PaintBaseFrame(panel, width, height)
	if (!panel.bNoBackgroundBlur) then
		ix.util.DrawBlur(panel, 10)
	end

	surface.SetDrawColor(30, 30, 30, 150)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(ix.config.Get("color"))
	surface.DrawOutlinedRect(0, 0, width, height)
end

function SKIN:DrawImportantBackground(x, y, width, height, color)
	color = color or defaultBackgroundColor

	surface.SetTexture(gradientLeft)
	surface.SetDrawColor(color)
	surface.DrawTexturedRect(x, y, width, height)
end

function SKIN:DrawCharacterStatusBackground(panel, fraction)
	surface.SetDrawColor(0, 0, 0, fraction * 100)
	surface.DrawRect(0, 0, ScrW(), ScrH())
	ix.util.DrawBlurAt(0, 0, ScrW(), ScrH(), 5, nil, fraction * 255)
end

function SKIN:PaintPanel(panel)
	if (panel.m_bBackground) then
		local width, height = panel:GetSize()

		surface.SetDrawColor(30, 30, 30, 100)
		surface.DrawRect(0, 0, width, height)

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawOutlinedRect(0, 0, width, height)
	end
end

function SKIN:PaintMenuBackground(panel, width, height, alphaFraction)
	alphaFraction = alphaFraction or 1

	surface.SetDrawColor(ColorAlpha(color_black, alphaFraction * 255))
	surface.SetTexture(gradient)
	surface.DrawTexturedRect(0, 0, width, height)

	ix.util.DrawBlur(panel, alphaFraction * 15, nil, 200)
end

function SKIN:PaintPlaceholderPanel(panel, width, height, barWidth, padding)
	local size = math.max(width, height)
	barWidth = barWidth or size * 0.05

	local segments = size / barWidth

	for i = 1, segments do
		surface.SetTexture(-1)
		surface.SetDrawColor(Color(0, 0, 0, 88))
		surface.DrawTexturedRectRotated(i * barWidth, i * barWidth, barWidth, size * 2, -45)
	end
end

function SKIN:PaintCategoryPanel(panel, text, color)
	text = text or ""
	color = color or ix.config.Get("color")

	surface.SetFont(self.fontCategoryBlur)

	local textHeight = select(2, surface.GetTextSize(text)) + 6
	local width, height = panel:GetSize()

	surface.SetDrawColor(Color(0, 0, 0, 100))
	surface.DrawRect(0, textHeight, width, height - textHeight)

	self:DrawImportantBackground(0, 0, width, textHeight, color)

	surface.SetTextColor(color_black)
	surface.SetTextPos(4, 4)
	surface.DrawText(text)

	surface.SetFont(self.fontCategory)
	surface.SetTextColor(color_white)
	surface.SetTextPos(4, 4)
	surface.DrawText(text)

	surface.SetDrawColor(color)
	surface.DrawOutlinedRect(0, 0, width, height)

	return 1, textHeight, 1, 1
end

function SKIN:PaintButton(panel)
	if (panel.m_bBackground) then
		local w, h = panel:GetWide(), panel:GetTall()
		local alpha = 50

		if (panel:GetDisabled()) then
			alpha = 10
		elseif (panel.Depressed) then
			alpha = 180
		elseif (panel.Hovered) then
			alpha = 75
		end

		surface.SetDrawColor(30, 30, 30, alpha)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawOutlinedRect(0, 0, w, h)

		surface.SetDrawColor(180, 180, 180, 2)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
	end
end

function SKIN:PaintEntityInfoBackground(panel, width, height)
	ix.util.DrawBlur(panel, 1)

	surface.SetDrawColor(self.Colours.DarkerBackground)
	surface.DrawRect(0, 0, width, height)
end

function SKIN:PaintTooltipBackground(panel, width, height)
	ix.util.DrawBlur(panel, 1)

	surface.SetDrawColor(self.Colours.DarkerBackground)
	surface.DrawRect(0, 0, width, height)
end

function SKIN:PaintTooltipMinimalBackground(panel, width, height)
	surface.SetDrawColor(0, 0, 0, 150 * panel.fraction)
	surface.SetMaterial(gradientRadial)
	surface.DrawTexturedRect(0, 0, width, height)
end

function SKIN:PaintSegmentedProgressBackground(panel, width, height)
end

function SKIN:PaintSegmentedProgress(panel, width, height)
	local font = panel:GetFont() or self.fontSegmentedProgress
	local textColor = panel:GetTextColor() or self.Colours.SegmentedProgress.Text
	local barColor = panel:GetBarColor() or self.Colours.SegmentedProgress.Bar
	local segments = panel:GetSegments()
	local segmentHalfWidth = width / #segments * 0.5

	surface.SetDrawColor(barColor)
	surface.DrawRect(0, 0, panel:GetFraction() * width, height)

	for i = 1, #segments do
		local text = segments[i]
		local x = (i - 1) / #segments * width + segmentHalfWidth
		local y = height * 0.5

		draw.SimpleText(text, font, x, y, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function SKIN:PaintCharacterCreateBackground(panel, width, height)
	surface.SetDrawColor(Color(40, 40, 40, 255))
	surface.SetTexture(gradient)
	surface.DrawTexturedRect(0, 0, width, height)
end

function SKIN:PaintCharacterLoadBackground(panel, width, height)
	surface.SetDrawColor(Color(40, 40, 40, panel:GetBackgroundFraction() * 255))
	surface.SetTexture(gradient)
	surface.DrawTexturedRect(0, 0, width, height)
end

function SKIN:PaintCharacterTransitionOverlay(panel, x, y, width, height, color)
	color = color or ix.config.Get("color")

	surface.SetDrawColor(color)
	surface.DrawRect(x, y, width, height)
end

function SKIN:PaintAreaEntry(panel, width, height)
	local color = ColorAlpha(panel:GetBackgroundColor() or self.Colours.Area.Background, panel:GetBackgroundAlpha())

	self:DrawImportantBackground(0, 0, width, height, color)
end

function SKIN:PaintListRow(panel, width, height)
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawRect(0, 0, width, height)
end

function SKIN:PaintSettingsRowBackground(panel, width, height)
	local index = panel:GetBackgroundIndex()
	local bReset = panel:GetShowReset()

	if (index == 0) then
		surface.SetDrawColor(Color(30, 30, 30, 45))
		surface.DrawRect(0, 0, width, height)
	end

	if (bReset) then
		surface.SetDrawColor(self.Colours.Warning)
		surface.DrawRect(0, 0, 2, height)
	end
end

function SKIN:PaintVScrollBar(panel, width, height)
end

function SKIN:PaintScrollBarGrip(panel, width, height)
	local parent = panel:GetParent()
	local upButtonHeight = parent.btnUp:GetTall()
	local downButtonHeight = parent.btnDown:GetTall()

	DisableClipping(true)
		surface.SetDrawColor(Color(30, 30, 30, 200))
		surface.DrawRect(4, -upButtonHeight, width - 8, height + upButtonHeight + downButtonHeight)
	DisableClipping(false)
end

function SKIN:PaintButtonUp(panel, width, height)
end

function SKIN:PaintButtonDown(panel, width, height)
end

function SKIN:PaintComboBox(panel, width, height)
end

function SKIN:PaintComboDownArrow(panel, width, height)
	surface.SetFont("ixIconsSmall")

	local textWidth, textHeight = surface.GetTextSize("r")
	local alpha = (panel.ComboBox:IsMenuOpen() or panel.ComboBox.Hovered) and 200 or 100

	surface.SetTextColor(ColorAlpha(ix.config.Get("color"), alpha))
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, height * 0.5 - textHeight * 0.5)
	surface.DrawText("r")
end

function SKIN:PaintMenu(panel, width, height)
	ix.util.DrawBlur(panel)

	surface.SetDrawColor(Color(30, 30, 30, 150))
	surface.DrawRect(0, 0, width, height)
end

function SKIN:PaintMenuOption(panel, width, height)
	if (panel.m_bBackground and (panel.Hovered or panel.Highlight)) then
		self:DrawImportantBackground(0, 0, width, height, ix.config.Get("color"))
	end
end

function SKIN:PaintHelixSlider(panel, width, height)
	surface.SetDrawColor(self.Colours.DarkerBackground)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(self.Colours.Success)
	surface.DrawRect(0, 0, panel:GetVisualFraction() * width, height)
end

function SKIN:PaintChatboxTabButton(panel, width, height)
	if (panel:GetActive()) then
		surface.SetDrawColor(ix.config.Get("color"))
		surface.DrawRect(0, 0, width, height)
	else
		surface.SetDrawColor(Color(0, 0, 0, 100))
		surface.DrawRect(0, 0, width, height)

		if (panel:GetUnread()) then
			surface.SetDrawColor(ColorAlpha(self.Colours.Warning, Lerp(panel.unreadAlpha, 0, 100)))
			surface.SetTexture(gradient)
			surface.DrawTexturedRect(0, 0, width, height - 1)
		end
	end

	-- border
	surface.SetDrawColor(color_black)
	surface.DrawRect(width - 1, 0, 1, height) -- right
end

function SKIN:PaintChatboxTabs(panel, width, height, alpha)
	surface.SetDrawColor(0, 0, 0, 33)
	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(0, 0, 0, 100)
	surface.SetTexture(gradient)
	surface.DrawTexturedRect(0, height * 0.5, width, height * 0.5)

	local tab = panel:GetActiveTab()

	if (tab) then
		local button = tab:GetButton()
		local x, _ = button:GetPos()

		-- outline
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, height - 1, x, 1) -- left
		surface.DrawRect(x + button:GetWide(), height - 1, width - x - button:GetWide(), 1) -- right
	end
end

function SKIN:PaintChatboxBackground(panel, width, height)
	ix.util.DrawBlur(panel, 10)

	if (panel:GetActive()) then
		surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), 120))
		surface.SetTexture(gradientUp)
		surface.DrawTexturedRect(0, panel.tabs.buttons:GetTall(), width, height * 0.25)
	end

	surface.SetDrawColor(color_black)
	surface.DrawOutlinedRect(0, 0, width, height)
end

function SKIN:PaintChatboxEntry(panel, width, height)
	surface.SetDrawColor(0, 0, 0, 66)
	surface.DrawRect(0, 0, width, height)

	panel:DrawTextEntryText(color_white, ix.config.Get("color"), color_white)

	surface.SetDrawColor(color_black)
	surface.DrawOutlinedRect(0, 0, width, height)
end

function SKIN:DrawChatboxPreviewBox(x, y, text, color)
	color = color or ix.config.Get("color")

	local textWidth, textHeight = surface.GetTextSize(text)
	local width, height = textWidth + 8, textHeight + 8

	-- background
	surface.SetDrawColor(color)
	surface.DrawRect(x, y, width, height)

	-- text
	surface.SetTextColor(color_white)
	surface.SetTextPos(x + width * 0.5 - textWidth * 0.5, y + height * 0.5 - textHeight * 0.5)
	surface.DrawText(text)

	-- outline
	surface.SetDrawColor(Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 255))
	surface.DrawOutlinedRect(x, y, width, height)

	return width
end

function SKIN:DrawChatboxPrefixBox(panel, width, height)
	local color = panel:GetBackgroundColor()

	-- background
	surface.SetDrawColor(color)
	surface.DrawRect(0, 0, width, height)

	-- outline
	surface.SetDrawColor(Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 255))
	surface.DrawOutlinedRect(0, 0, width, height)
end


function SKIN:PaintChatboxAutocompleteEntry(panel, width, height)
	-- selected background
	if (panel.highlightAlpha > 0) then
		self:DrawImportantBackground(0, 0, width, height, ColorAlpha(ix.config.Get("color"), panel.highlightAlpha * 66))
	end

	-- lower border
	surface.SetDrawColor(200, 200, 200, 33)
	surface.DrawRect(0, height - 1, width, 1)
end

function SKIN:PaintWindowMinimizeButton(panel, width, height)
end

function SKIN:PaintWindowMaximizeButton(panel, width, height)
end

do
	-- check if sounds exist, otherwise fall back to default UI sounds
	local bWhoosh = file.Exists("sound/helix/ui/whoosh1.wav", "GAME")
	local bRollover = file.Exists("sound/helix/ui/rollover.wav", "GAME")
	local bPress = file.Exists("sound/helix/ui/press.wav", "GAME")
	local bNotify = file.Exists("sound/helix/ui/REPLACEME.wav", "GAME") -- @todo

	sound.Add({
		name = "Helix.Whoosh",
		channel = CHAN_STATIC,
		volume = 0.4,
		level = 80,
		pitch = bWhoosh and {90, 105} or 100,
		sound = bWhoosh and {
			"helix/ui/whoosh1.wav",
			"helix/ui/whoosh2.wav",
			"helix/ui/whoosh3.wav",
			"helix/ui/whoosh4.wav",
			"helix/ui/whoosh5.wav",
			"helix/ui/whoosh6.wav"
		} or ""
	})

	sound.Add({
		name = "Helix.Rollover",
		channel = CHAN_STATIC,
		volume = 0.5,
		level = 80,
		pitch = {95, 105},
		sound = bRollover and "helix/ui/rollover.wav" or "ui/buttonrollover.wav"
	})

	sound.Add({
		name = "Helix.Press",
		channel = CHAN_STATIC,
		volume = 0.5,
		level = 80,
		pitch = bPress and {95, 110} or 100,
		sound = bPress and "helix/ui/press.wav" or "ui/buttonclickrelease.wav"
	})

	sound.Add({
		name = "Helix.Notify",
		channel = CHAN_STATIC,
		volume = 0.35,
		level = 80,
		pitch = 140,
		sound = bNotify and "helix/ui/REPLACEME.wav" or "weapons/grenade/tick1.wav"
	})
end

derma.RefreshSkins()
