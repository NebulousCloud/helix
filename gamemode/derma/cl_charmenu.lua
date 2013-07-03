local PANEL = {}
	function PANEL:ResetMenu()
		self.cancel:Remove()

		if (self.create) then
			self.create:SetVisible(true)
		end

		if (self.load) then
			self.load:SetVisible(true)
		end

		if (self.ret) then
			self.ret:SetVisible(true)
		end

		if (self.leave) then
			self.leave:SetVisible(true)
		end
		
		if (IsValid(nut.gui.char)) then
			nut.gui.char:Finish(true)
			nut.gui.char:Remove()
		end

		if (IsValid(nut.gui.charList)) then
			nut.gui.charList:Remove()
		end
	end

	function PANEL:ShowCancel()
		if (self.ret) then
			self.ret:SetVisible(false)
		end

		if (self.create) then
			self.create:SetVisible(false)
		end

		if (self.load) then
			self.load:SetVisible(false)
		end

		if (self.leave) then
			self.leave:SetVisible(false)
		end
		
		self.cancel = self.panel:Add("nut_MenuButton")
		self.cancel:SetText(nut.lang.Get("cancel"))
		self.cancel:SetToolTip(nut.lang.Get("cancel_tip"))
		self.cancel.OnClick = function()
			if (IsValid(nut.gui.char) and nut.gui.char.validating) then
				return false
			else
				self:ResetMenu()
			end
		end
	end

	function PANEL:Init()
		self:SetSize(ScrW(), ScrH())
		self:SetDrawBackground(false)
		self:MakePopup()

		self.panel = self:Add("DScrollPanel")
		self.panel:SetWide(ScrW() * 0.275)

		self.title = self:Add("DLabel")
		self.title:SetText(SCHEMA.name)
		self.title:SetPos(32, 16)
		self.title:SetFont("nut_TitleFont")
		self.title:SetTextColor(Color(250, 250, 250))
		self.title:SetExpensiveShadow(5, color_black)
		self.title:SizeToContentsY()
		self.title:SetWide(ScrW() * 0.275 - 16)

		surface.SetFont("nut_TitleFont")
		local w, h = surface.GetTextSize(self.title:GetText())

		self.desc = self:Add("DLabel")
		self.desc:SetFont("nut_SubTitleFont")
		self.desc:SetText(nut.lang.Get("schema_author", SCHEMA.author).." "..SCHEMA.desc)
		self.desc:SetPos(32, h + 24)
		self.desc:SetWide(ScrW() * 0.275 - 16)
		self.desc:SetTextColor(Color(250, 250, 250))
		self.desc:SetExpensiveShadow(1, color_black)
		self.desc:SizeToContentsY();

		local w2, h2 = surface.GetTextSize(self.desc:GetText())
		h = h + h2 + 32

		self.panel:SetPos(32, h - 48)
		self.panel:SetTall(ScrH() - h)

		if (nut.faction.Count() > 0) then
			self.create = self.panel:Add("nut_MenuButton")
			self.create:SetText(nut.lang.Get("create"))
			self.create:SetToolTip(nut.lang.Get("create_tip"))
			self.create.OnClick = function(create)
				if (!IsValid(nut.gui.char)) then
					if (LocalPlayer().characters and #LocalPlayer().characters >= nut.config.maxChars) then
						return false
					end

					self:ShowCancel()

					nut.gui.char = self:Add("nut_CharacterCreate")
				end
			end
		end

		self.load = self.panel:Add("nut_MenuButton")
		self.load:SetText(nut.lang.Get("load"))
		self.load:SetToolTip(nut.lang.Get("load_tip"))
		self.load.OnClick = function(load)
			if (!IsValid(nut.gui.charList)) then
				self:ShowCancel()

				nut.gui.charList = self:Add("nut_CharacterList")
			end
		end

		if (!nut.loaded) then
			self.leave = self.panel:Add("nut_MenuButton")
			self.leave:SetText(nut.lang.Get("leave"))
			self.leave:SetToolTip(nut.lang.Get("leave_tip"))
			self.leave.OnClick = function()
				RunConsoleCommand("disconnect")
			end
		end
		
		if (nut.loaded) then
			self.ret = self.panel:Add("nut_MenuButton")
			self.ret:SetText(nut.lang.Get("return"))
			self.ret:SetToolTip(nut.lang.Get("cancel_tip"))
			self.ret.OnClick = function()
				nut.gui.charMenu:FadeOutMusic()
				nut.gui.charMenu:Remove()
			end
		end
		
		if (nut.config.menuMusic) then
			if (nut.menuMusic) then
				nut.menuMusic:Stop()
				nut.menuMusic = nil
			end

			local lower = string.lower(nut.config.menuMusic)

			if (string.Left(lower, 4) == "http") then
				local function createMusic()
					local nextAttempt = 0

					sound.PlayURL(nut.config.menuMusic, "noplay", function(music)
						if (music) then
							nut.menuMusic = music
							nut.menuMusic:Play()

							timer.Simple(0.5, function()
								if (!nut.menuMusic) then
									return
								end
								
								nut.menuMusic:SetVolume(nut.config.menuMusicVol / 100)
							end)
						elseif (nextAttempt < CurTime()) then
							nextAttempt = CurTime() + 1

							createMusic()
						end
					end)
				end

				createMusic()
			else
				nut.menuMusic = CreateSound(LocalPlayer(), nut.config.menuMusic)
				nut.menuMusic:Play()
				nut.menuMusic:ChangeVolume(nut.config.menuMusicVol / 100, 0)
			end
		end

		nut.loaded = true
	end

	function PANEL:FadeOutMusic()
		if (!nut.menuMusic) then
			return
		end

		if (nut.menuMusic.SetVolume) then
			local start = CurTime()
			local finish = CurTime() + nut.config.menuMusicFade

			if (timer.Exists("nut_FadeMenuMusic")) then
				timer.Remove("nut_FadeMenuMusic")

				if (nut.menuMusic) then
					nut.menuMusic:Stop()
					nut.menuMusic = nil
				end
			end

			timer.Create("nut_FadeMenuMusic", 0, 0, function()
				local fraction = (1 - math.TimeFraction(start, finish, CurTime())) * nut.config.menuMusicVol

				if (nut.menuMusic) then
					nut.menuMusic:SetVolume(fraction / 100)

					if (fraction <= 0) then
						nut.menuMusic:SetVolume(0)
						nut.menuMusic:Stop()
						nut.menuMusic = nil
					end
				end
			end)
		else
			nut.menuMusic:FadeOut(nut.config.menuMusicFade)
			nut.menuMusic = nil
		end
	end

	local gradient = surface.GetTextureID("gui/gradient")

	function PANEL:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 245)
		surface.SetTexture(gradient)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end
vgui.Register("nut_CharMenu", PANEL, "DPanel")

net.Receive("nut_CharMenu", function(length)
	local forced = net.ReadBit() == 1

	if (IsValid(nut.gui.charMenu)) then
		nut.gui.charMenu:FadeOutMusic()
		nut.gui.charMenu:Remove()

		if (!forced) then
			return
		end
	end

	if (forced) then
		nut.loaded = nil
	end

	nut.gui.charMenu = vgui.Create("nut_CharMenu")
end)