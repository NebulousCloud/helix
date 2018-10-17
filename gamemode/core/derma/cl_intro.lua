
local waveSegments = 32
local helixSegments = 76
local helixHeight = 64

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
	if (IsValid(ix.gui.intro)) then
		ix.gui.intro:Remove()
	end

	ix.gui.intro = self

	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetZPos(99999)
	self:MakePopup()

	-- animation parameters
	self.bBackground = true
	self.volume = 1
	self.sunbeamOffset = 0
	self.textOne = 0
	self.textTwo = 0
	self.kickTarget = 0
	self.helix = 0
	self.helixAlpha = 0
	self.continueText = 0
	self.pulse = 0

	self.waves = {
		{1.1, 0},
		{1.1, math.pi},
		{1.1, math.pi * 1.6},
		{1.1, math.pi * 0.5}
	}
end

-- @todo h a c k
function PANEL:Think()
	if (IsValid(LocalPlayer())) then
		self:BeginIntro()
		self.Think = nil
	end
end

function PANEL:BeginIntro()
	self:MoveToFront()
	self:RequestFocus()

	sound.PlayFile("sound/buttons/combine_button2.wav", "", function()
		timer.Create("ixIntroStart", 2, 1, function()
			sound.PlayFile("sound/helix/intro.mp3", "", function(channel, status, error)
				if (IsValid(channel)) then
					channel:SetVolume(self.volume)
					self.channel = channel
				end

				self:BeginAnimation()
			end)
		end)
	end)

	ix.option.Set("showIntro", false)
end

function PANEL:AnimateWaves(target, bReverse)
	for i = bReverse and #self.waves or 1,
		bReverse and 1 or #self.waves,
		bReverse and -1 or 1 do

		local animation = self:CreateAnimation(2, {
			index = 20 + (bReverse and (#self.waves - i) or i),
			bAutoFire = false,
			target = {
				waves = {
					[i] = {target}
				}
			},
			easing = bReverse and "inQuart" or "outQuint"
		})

		timer.Simple((bReverse and (#self.waves - i) or i) * 0.1, function()
			if (IsValid(self) and animation) then
				animation:Fire()
			end
		end)

		-- return last animation that plays
		if ((bReverse and i == 1) or (!bReverse and i == #self.waves)) then
			return animation
		end
	end
end

function PANEL:BeginAnimation()
	self:CreateAnimation(2, {
			target = {textOne = 1},
			easing = "inQuint",
			bIgnoreConfig = true
		})
		:CreateAnimation(2, {
			target = {textOne = 0},
			easing = "inQuint",
			bIgnoreConfig = true
		})
		:CreateAnimation(2, {
			target = {textTwo = 1},
			easing = "inQuint",
			bIgnoreConfig = true,
			OnComplete = function(animation, panel)
				self:AnimateWaves(0)
			end
		})
		:CreateAnimation(2, {
			target = {textTwo = 0},
			easing = "inQuint",
			bIgnoreConfig = true
		})
		:CreateAnimation(4, {
			target = {sunbeamOffset = 1},
			bIgnoreConfig = true,
			OnComplete = function()
				self:CreateAnimation(2,{
					target = {helixAlpha = 1},
					easing = "inCubic"
				})
			end
		})
		:CreateAnimation(2, {
			target = {helix = 1},
			easing = "outQuart",
			bIgnoreConfig = true
		})
		:CreateAnimation(2, {
			target = {continueText = 1},
			easing = "linear",
			bIgnoreConfig = true
		})
end

function PANEL:PaintCurve(y, width, offset, scale)
	offset = offset or 1
	scale = scale or 32

	local points = {
		[1] = {
			x = 0,
			y = ScrH()
		}
	}

	for i = 0, waveSegments do
		local angle = math.rad((i / waveSegments) * -360)

		points[#points + 1] = {
			x = (width / waveSegments) * i,
			y = y + (math.sin(angle * 0.5 + offset) - 1) * scale
		}
	end

	points[#points + 1] = {
		x = width,
		y = ScrH()
	}

	draw.NoTexture()
	surface.DrawPoly(points)
end

function PANEL:Paint(width, height)
	local time = SysTime()
	local text = L("helix"):lower()
	local centerY = height * self.waves[#self.waves][1] + height * 0.5
	local textWidth, textHeight
	local fft

	-- background
	if (self.bBackground) then
		surface.SetDrawColor(Color(0, 0, 0, 255))
		surface.DrawRect(0, 0, width, height)
	end

	if (self.sunbeamOffset == 1) then
		fft = {}

		if (IsValid(self.channel)) then
			self.channel:FFT(fft, FFT_2048)

			local kick = (fft[4] or 0) * 8192
			self.kickTarget = math.Approach(self.kickTarget, kick, 8 * math.abs(kick - self.kickTarget) * FrameTime())
		end
	end

	-- waves
	for i = 1, #self.waves do
		local wave = self.waves[i]
		local ratio = i / #self.waves
		local color = ratio * 33

		surface.SetDrawColor(Color(color, color, color, self.bBackground and 255 or ratio * 320))
		self:PaintCurve(height * wave[1], width, wave[2])
	end

	-- helix
	if (self.helix > 0) then
		derma.SkinFunc("DrawHelixCurved",
			width * 0.5, centerY,
			math.min(ScreenScale(72), 128) * 2, -- font sizes are clamped to 128
			helixSegments * self.helix, helixHeight, self.helix,
			ColorAlpha(ix.config.Get("color"), self.helixAlpha * 255)
		)
	end

	-- title text glow
	surface.SetTextColor(Color(255, 255, 255,
		self.sunbeamOffset == 1 and self.kickTarget or math.sin(math.pi * self.sunbeamOffset) * 255
	))
	surface.SetFont("ixIntroTitleBlurFont")

	local logoTextWidth, logoTextHeight = surface.GetTextSize(text)
	surface.SetTextPos(width * 0.5 - logoTextWidth * 0.5, centerY - logoTextHeight * 0.5)
	surface.DrawText(text)

	-- title text
	surface.SetTextColor(Color(255, 255, 255, self.sunbeamOffset * 255))
	surface.SetFont("ixIntroTitleFont")

	logoTextWidth, logoTextHeight = surface.GetTextSize(text)
	surface.SetTextPos(width * 0.5 - logoTextWidth * 0.5, centerY - logoTextHeight * 0.5)
	surface.DrawText(text)

	-- text one
	surface.SetFont("ixIntroSubtitleFont")
	text = L("introTextOne"):lower()
	textWidth = surface.GetTextSize(text)

	surface.SetTextColor(Color(255, 255, 255, self.textOne * 255))
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, height * 0.66)
	surface.DrawText(text)

	-- text two
	text = L("introTextTwo", Schema.author or "nebulous"):lower()
	textWidth = surface.GetTextSize(text)

	surface.SetTextColor(Color(255, 255, 255, self.textTwo * 255))
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, height * 0.66)
	surface.DrawText(text)

	-- continue text
	surface.SetFont("ixIntroSmallFont")
	text = L("introContinue"):lower()
	textWidth, textHeight = surface.GetTextSize(text)

	if (self.continueText == 1) then
		self.pulse = self.pulse + 6 * FrameTime()

		if (self.pulse >= 360) then
			self.pulse = 0
		end
	end

	surface.SetTextColor(Color(255, 255, 255, self.continueText * 255 - (math.sin(self.pulse) * 100), 0))
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, centerY * 2 - textHeight * 2)
	surface.DrawText(text)

	-- sunbeams
	if (self.sunbeamOffset > 0 and self.sunbeamOffset != 1) then
		DrawSunbeams(0.25, 0.1, 0.02,
			(((width * 0.5 - logoTextWidth * 0.5) - 32) / width) + ((logoTextWidth + 64) / width) * self.sunbeamOffset,
			0.5 + math.sin(time * 2) * 0.01
		)
	end
end

function PANEL:OnKeyCodePressed(key)
	if (key == KEY_SPACE and self.continueText > 0.25) then
		self:Remove()
	end
end

function PANEL:OnRemove()
	timer.Remove("ixIntroStart")

	if (IsValid(self.channel)) then
		self.channel:Stop()
	end

	if (IsValid(ix.gui.characterMenu)) then
		ix.gui.characterMenu:PlayMusic()
	end
end

function PANEL:Remove(bForce)
	if (bForce) then
		BaseClass.Remove(self)
		return
	end

	if (self.bClosing) then
		return
	end

	self.bClosing = true
	self.bBackground = nil

	-- waves
	local animation = self:AnimateWaves(1.1, true)

	animation.OnComplete = function(anim, panel)
		panel:SetMouseInputEnabled(false)
		panel:SetKeyboardInputEnabled(false)
	end

	-- audio
	self:CreateAnimation(4.5, {
		index = 1,
		target = {volume = 0},

		Think = function(anim, panel)
			if (IsValid(panel.channel)) then
				panel.channel:SetVolume(panel.volume)
			end
		end,

		OnComplete = function()
			timer.Simple(0, function()
				BaseClass.Remove(self)
			end)
		end
	})
end

vgui.Register("ixIntro", PANEL, "EditablePanel")
