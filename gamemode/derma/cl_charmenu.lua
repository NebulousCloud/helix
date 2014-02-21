local PANEL = {}
	local gradient = surface.GetTextureID("gui/gradient_up")
	local gradient2 = surface.GetTextureID("gui/gradient_down")
	local gradient3 = surface.GetTextureID("gui/center_gradient")

	function PANEL:Init()
		timer.Remove("nut_FadeMenuMusic")
		
		self:SetSize(ScrW(), ScrH())
		self:SetDrawBackground(false)
		self:MakePopup()

		self.title = self:Add("DLabel")
		self.title:Dock(TOP)
		self.title:SetText(SCHEMA.name)
		self.title:SetFont("nut_TitleFont")
		self.title:SizeToContents()
		self.title:SetContentAlignment(5)
		self.title:SetTextColor(color_white)
		self.title:SetExpensiveShadow(1, color_black)
		self.title.Paint = function(panel, w, h)
			surface.SetDrawColor(0, 0, 0, 125)
			surface.SetTexture(gradient2)
			surface.DrawTexturedRect(0, 0, w, h)
		end

		self.subTitle = self:Add("DLabel")
		self.subTitle:Dock(TOP)
		self.subTitle:SetText(SCHEMA.desc)
		self.subTitle:SetFont("nut_SubTitleFont")
		self.subTitle:SizeToContents()
		self.subTitle:SetContentAlignment(5)
		self.subTitle:SetTextColor(color_white)
		self.subTitle:SetExpensiveShadow(1, color_black)
		self.subTitle.Paint = function(panel, w, h)
			surface.SetDrawColor(0, 0, 0, 125)
			surface.SetTexture(gradient3)
			surface.DrawTexturedRect(w * 0.25, 0, w * 0.5, h)
		end

		self.lowerPanel = self:Add("DPanel")
		self.lowerPanel:Dock(BOTTOM)
		self.lowerPanel:DockPadding(32, 0, 28, 0)
		self.lowerPanel:SetTall(ScrH() * 0.1)
		self.lowerPanel.Paint = function(panel, w, h)
			surface.SetDrawColor(20, 20, 20, 230)
			surface.DrawRect(0, 0, w, h)
		end

		self.rightPanel = self:Add("DScrollPanel")
		self.rightPanel:Dock(RIGHT)
		self.rightPanel:SetWide(ScrW() * 0.25)
		self.rightPanel:DockMargin(0, ScrH() * 0.45, 32, ScrH() * 0.075)
		
		local MODEL_ANGLE = Angle(0, 60, 0)

		self.model = self:Add("DModelPanel")
		self.model:ParentToHUD()
		self.model:Dock(FILL)
		self.model:DockMargin(ScrW() * 0.175, ScrH() * 0.05, 0, ScrH() * 0.05)
		self.model:SetFOV(105)
		self.model.OnCursorEntered = function() end
		self.model:SetDisabled(true)
		self.model:SetCursor("none")

		local SetModel = self.model.SetModel

		self.model.SetModel = function(panel, model)
			SetModel(panel, model)

			local entity = panel.Entity
			local sequence = entity:LookupSequence("idle")

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle_subtle")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("batonidle2")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle_unarmed")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle01")
			end

			if (sequence > 0) then
				entity:ResetSequence(sequence)
			end
		end

		self.model.LayoutEntity = function(panel, entity)
			if (!IsValid(nut.gui.charMenu)) then
				panel:Remove()

				return
			end
			
			local xRatio = gui.MouseX() / ScrW()
			local yRatio = gui.MouseY() / ScrH()

			entity:SetPoseParameter("head_pitch", yRatio*60 - 30)
			entity:SetPoseParameter("head_yaw", (xRatio - 0.75)*60)
			entity:SetAngles(MODEL_ANGLE)

			panel:RunAnimation()
		end

		self.characters = {}

		if (LocalPlayer().characters and table.Count(LocalPlayer().characters) > 0) then
			for k, v in SortedPairsByMemberValue(LocalPlayer().characters, "id", true) do
				local color = nut.config.mainColor
				local r, g, b = color.r, color.g, color.b

				local panel = self.rightPanel:Add("nut_MenuButton")
				panel:Dock(TOP)
				panel:DockMargin(0, 10, 0, 0)
				panel:SetText(v.name)
				panel:SetToolTip(v.desc)
				panel.OldPaint = panel.Paint
				panel.Paint = function(panel, w, h)
					panel.OldPaint(panel, w, h)

					if (self.id and self.id == v.id) then
						surface.SetDrawColor(r, g, b, 200)
						surface.DrawRect(0, 0, w, h)
					end
				end
				panel.OnClick = function(panel)
					self.id = v.id
					self.model:SetModel(v.model)
				end

				self.characters[v.id] = panel
			end
		end

		local function addLowerButton(variable, text, dock)
			local button = self.lowerPanel:Add("nut_MenuButton")
			button:Dock(dock)
			button:DockMargin(0, 0, 4, 0)
			button:SetText(text)
			button:SetWide(ScrW() * 0.12)

			self[variable] = button
		end

		if (nut.faction.Count() > 0) then
			addLowerButton("create", nut.lang.Get("create"), LEFT)

			self.create.OnClick = function(panel)
				if (IsValid(nut.gui.charCreate)) then
					return false
				end

				if (LocalPlayer().characters and table.Count(LocalPlayer().characters) >= nut.config.maxChars) then
					return false
				end

				if (IsValid(self.selector)) then
					self.selector:Remove()

					return
				end

				local grace = CurTime() + 0.1

				self.selector = self:Add("DPanel")
				self.selector:Dock(LEFT)
				self.selector:DockMargin(32, 0, 0, 0)
				self.selector:SetWide(ScrW() * 0.25)

				local y = 5

				for k, v in pairs(nut.faction.GetAll()) do
					if (nut.faction.CanBe(LocalPlayer(), v.index)) then
						if (!v.name) then
							ErrorNoHalt("Faction with ID "..k.." ("..(faction.uniqueID or "unknown").." missing name!\n")
						end

						local button = self.selector:Add("nut_MenuButton")
						button:SetText(v.name or (v.uniqueID or "unknown"))
						button:DockMargin(5, 0, 5, 5)
						button:SetToolTip(v.desc or nut.lang.Get("no_desc"))
						button:Dock(BOTTOM)
						button.OnClick = function(panel)
							nut.gui.charCreate = vgui.Create("nut_CharCreate")
							nut.gui.charCreate:SetupFaction(k)

							self.selector:Remove()
						end

						y = y + (button:GetTall() + 5)
					end
				end

				self.selector.Paint = function(panel, w, h)
					surface.SetDrawColor(30, 30, 30, 245)
					surface.DrawRect(0, h - y, w, h)
				end
			end

			self.create:SetToolTip(nut.lang.Get("create_tip"))
		end

		addLowerButton("leave", nut.loaded and nut.lang.Get("return") or nut.lang.Get("leave"), RIGHT)
		addLowerButton("delete", nut.lang.Get("delete"), RIGHT)
		addLowerButton("choose", nut.lang.Get("choose"), RIGHT)

		self.leave:SetToolTip(LocalPlayer().character and nut.lang.Get("return_tip") or nut.lang.Get("leave_tip"))
		self.delete:SetToolTip(nut.lang.Get("delete_tip"))
		self.choose:SetToolTip(nut.lang.Get("choose_tip"))

		self.delete.OnClick = function(panel)
			if (IsValid(nut.gui.charCreate)) then
				return false
			end
			
			if (!self.id) then
				return false
			end

			if (self.characters[self.id]) then
				Derma_Query("Are you sure you want to delete this character? It can not be undone.", "Confirm", "No", nil, "Yes", function()
					self.characters[self.id]:Remove()
					self.characters[self.id] = nil

					netstream.Start("nut_CharDelete", self.id)

					for k, v in pairs(LocalPlayer().characters) do
						if (v.id == self.id) then
							LocalPlayer().characters[k] = nil
						end
					end

					surface.PlaySound("buttons/button9.wav")

					timer.Simple(0, function()
						if (IsValid(nut.gui.charMenu)) then
							nut.gui.charMenu:FadeOutMusic()

							if (IsValid(nut.gui.charMenu.model)) then
								nut.gui.charMenu.model:Remove()
							end

							nut.gui.charMenu:Remove()
						end

						nut.gui.charMenu = vgui.Create("nut_CharMenu")
					end)
				end)
			end
		end

		self.leave.OnClick = function(panel)
			if (LocalPlayer().character) then
				if (IsValid(nut.gui.charCreate)) then
					return false
				end

				self:FadeOutMusic()

				if (IsValid(self.model)) then
					self.model:Remove()
				end

				self:Remove()
			else
				RunConsoleCommand("disconnect")
			end
		end

		self.choose.OnClick = function(panel)
			if (IsValid(nut.gui.charCreate)) then
				return false
			end
				
			if (self.id) then
				netstream.Start("nut_CharChoose", self.id)
			else
				return false
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
					if (!IsValid(nut.gui.charMenu)) then
						return
					end

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

	function PANEL:Paint(w, h)
		surface.SetDrawColor(20, 20, 20)
		surface.SetTexture(gradient)
		surface.DrawTexturedRect(0, 0, w, h)
	end
vgui.Register("nut_CharMenu", PANEL, "DPanel")

netstream.Hook("nut_CharMenu", function(forced)
	if (type(forced) == "table") then
		if (forced[2] == true) then
			LocalPlayer().character = nil
		end

		forced = forced[1]
	end

	if (IsValid(nut.gui.charMenu)) then
		nut.gui.charMenu:FadeOutMusic()

		if (IsValid(nut.gui.charMenu.model)) then
			nut.gui.charMenu.model:Remove()
		end

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