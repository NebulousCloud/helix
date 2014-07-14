local PANEL = {}
	local gradient = surface.GetTextureID("gui/gradient_up")
	local gradient2 = surface.GetTextureID("gui/gradient_down")
	local gradient3 = surface.GetTextureID("gui/gradient")
	local gradient4 = surface.GetTextureID("vgui/gradient-r")
	local blur = Material("pp/blurscreen")

	local function DrawBlur(panel, amount)
		local x, y = panel:LocalToScreen(0, 0)
		local scrW, scrH = ScrW(), ScrH()

		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(blur)

		for i = 1, 3 do
			blur:SetFloat("$blur", (i / 3) * (amount or 6))
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
		end
	end

	function PANEL:Init()
		timer.Remove("nut_FadeMenuMusic")
		
		self:SetSize(ScrW(), ScrH())
		self:MakePopup()
		self:ParentToHUD()

		local color = nut.config.mainColor
		local r, g, b = color.r, color.g, color.b

		self.side = self:Add("DPanel")
		self.side:SetPos(ScrW() * 0.075, 0)
		self.side:SetSize(ScrW() * 0.275, ScrH())
		self.side.Paint = function(this, w, h)
			DrawBlur(self.side, 8)

			surface.SetDrawColor(0, 0, 0, 80)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(20, 20, 20, 200)
			surface.SetTexture(gradient2)
			surface.DrawTexturedRect(0, 0, w, h)

			surface.SetDrawColor(25, 25, 25, 80)
			surface.DrawLine(0, 0, 0, h)
			surface.DrawLine(w - 1, 0, w - 1, h)
		end

		self.title = self.side:Add("DLabel")
		self.title:Dock(TOP)
		self.title:SetFont("nut_TitleFont")
		self.title:SetWrap(true)
		self.title:SetAutoStretchVertical(true)
		self.title:SetTextColor(Color(240, 240, 240))
		self.title:DockMargin(24, 60, 0, 0)
		self.title:SetText(SCHEMA.name)
		self.title:SizeToContentsY()

		self.subTitle = self.side:Add("DLabel")
		self.subTitle:Dock(TOP)
		self.subTitle:SetText(SCHEMA.desc)
		self.subTitle:SetWrap(true)
		self.subTitle:SetAutoStretchVertical(true)
		self.subTitle:DockMargin(28, 0, 0, 0)
		self.subTitle:SetFont("nut_SubTitleFont")

		self.buttons = self.side:Add("DScrollPanel")
		self.buttons:Dock(FILL)
		self.buttons:DockMargin(0, 40, 0, 0)
		self.buttons:DockPadding(0, 0, 0, 80)
		self.buttons.Paint = function(this, w, h)
			surface.SetDrawColor(255, 255, 255, 60)
			surface.SetTexture(gradient3)
			surface.DrawTexturedRect(10, 0, w - 20, 1)
		end

		nut.OldRenderScreenspaceEffects = nut.RenderScreenspaceEffects

		timer.Simple(0.1, function()
			GAMEMODE.RenderScreenspaceEffects = function()
				if (IsValid(self)) then
					self:RenderScreenspaceEffects()
				else
					GAMEMODE.RenderScreenspaceEffects = nut.OldRenderScreenspaceEffects
				end
			end
		end)

		local first = true
		local sideWidth = self.side:GetWide()
		local i = 0

		local function AddButton(text, callback, noLang)
			if (self.choosing) then return end

			local button = self.buttons:Add("DButton")
			button:SetText(noLang and text:upper() or nut.lang.Get(text:lower()):upper())
			button:SetPos(0, i * 64 + 20)
			button:SetWide(sideWidth)
			button:SetFont("nut_BigThinFont")
			button:SetContentAlignment(4)
			button:SetTextColor(color_white)
			button:SetTextInset(28, 0)
			button:SetAlpha(100)
			button:SetTall(64)
			button.Paint = function(this, w, h)
				if (this.Hovered) then
					this:SetAlpha(240)

					local mainColor = nut.config.mainColor
					local r, g, b = mainColor.r, mainColor.g, mainColor.b

					surface.SetDrawColor(r, g, b, 100)
					surface.DrawRect(0, 0, w, h)
				else
					this:SetAlpha(100)
				end
			end
			button:SetExpensiveShadow(1, Color(0, 0, 0, 220))

			if (first) then
				button:DockMargin(0, 20, 0, 0)
				first = false
			end

			if (callback) then
				button.DoClick = callback
			end

			i = i + 1
		end

		local function CreateMainButtons()
			i = 0

			if (IsValid(self.content)) then
				self.content:Remove()
			end

			self.side:SizeTo(sideWidth, ScrH(), 0.25, 0, 0.5)
			self.buttons:Clear()
			
			local factions = {}

			for k, v in pairs(nut.faction.buffer) do
				if (nut.faction.CanBe(LocalPlayer(), v.index)) then
					factions[#factions + 1] = v
				end
			end

			if (#factions > 0 and (LocalPlayer().character and table.Count(LocalPlayer().characters) or 0) < nut.config.maxChars) then
				AddButton("create", function()
					i = 0

					self.buttons:Clear()

					local faction

					AddButton("return", function()
						CreateMainButtons()
					end)

					local function SetupCreationMenu()
						i = 0
						self.buttons:Clear()

						local model = ""

						AddButton("return", function()
							if (!self.creating) then
								CreateMainButtons()
							end
						end)

						AddButton("finish", function()
							if (self.creating) then return end

							local name = self.name:GetText()
							local gender = self.gender.male:GetChecked() and "male" or "female"
							local desc = self.desc:GetText()
							local attribs = {}
							local fault

							for k, v in ipairs(self.attribs) do
								attribs[k] = v:GetValue() or 0
							end

							if (!name or !name:find("%S")) then
								fault = nut.lang.Get("name")
							elseif (!gender or (gender != "male" and gender != "female")) then
								fault = nut.lang.Get("gender")
							elseif (!desc or #desc < nut.config.descMinChars or !desc:find("%S")) then
								fault = nut.lang.Get("desc")
							elseif (!model) then
								fault = nut.lang.Get("model")
							elseif (!faction or !nut.faction.GetByID(faction.index)) then
								fault = nut.lang.Get("faction")
							end

							if (fault) then
								self.notice:SetType(5)
								self.notice:SetText(nut.lang.Get("provide_valid").." "..fault:lower()..".")

								return
							end

							netstream.Start("nut_CharCreate", {
								name = name,
								gender = gender,
								desc = desc,
								model = model,
								faction = faction.index,
								attribs = attribs
							})

							self.creating = true
							self.creatingCallback = CreateMainButtons
							self.notice:SetType(6)
							self.notice:SetText(nut.lang.Get("char_creating"))

							local faulted = false

							netstream.Hook("nut_CharCreateFault", function(fault)
								if (IsValid(self.notice)) then
									self.notice:SetType(2)
									self.notice:SetText(fault)

									faulted = true
								end
							end)

							timer.Simple(10, function()
								if (IsValid(self) and self.creating) then
									self.creating = false

									if (!faulted) then
										self.notice:SetType(5)
										self.notice:SetText("Character creation request timed out.")
									end
								end
							end)
						end)

						local width = ScrW() * 0.375

						self.content = self.side:Add("DScrollPanel")
						self.content:Dock(RIGHT)
						self.content:SetWide(width)
						self.content:DockMargin(10, 40, 10, 10)

						width = width - 16

						local first = true
						local y = 20

						self.notice = self.content:Add("nut_NoticePanel")
						self.notice:SetPos(0, y)
						self.notice:SetSize(width, 28)
						self.notice:SetType(7)
						self.notice:SetText(nut.lang.Get("char_create_tip"))

						y = y + 36

						local function AddHeader(text, ignoreLang)
							local header = self.content:Add("DLabel")
							header:SetText(ignoreLang and text or nut.lang.Get(text))
							header:SetFont("nut_BigThinFont")
							header:SizeToContents()
							header:SetPos(0, y)

							y = y + header:GetTall()

							return header
						end

						local LoadModels

						AddHeader("name")

						self.name = self.content:Add("DTextEntry")
						self.name:SetPos(0, y)
						self.name:SetSize(width, 28)

						if (faction.GetDefaultName) then
							local name, canChange = faction:GetDefaultName(self.name)

							if (name) then
								self.name:SetText(name)
								self.name:SetEditable(canChange or false)
							end
						end

						y = y + 36
						AddHeader("desc")

						self.desc = self.content:Add("DTextEntry")
						self.desc:SetPos(0, y)
						self.desc:SetSize(width, 28)

						y = y + 36
						AddHeader("gender")

						self.gender = self.content:Add("DPanel")
						self.gender:SetPos(0, y)
						self.gender:SetSize(width, 28)
						self.gender:SetDrawBackground(false)

						self.gender.male = self.gender:Add("DCheckBoxLabel")
						self.gender.male:DockMargin(0, 6, 8, 6)
						self.gender.male:SetText(nut.lang.Get("male"))
						self.gender.male:SetValue(1)
						self.gender.male:Dock(LEFT)
						self.gender.male.OnChange = function(this, value)
							self.gender.female:SetChecked(false)
							this:SetChecked(true)

							LoadModels("male")
						end

						self.gender.female = self.gender:Add("DCheckBoxLabel")
						self.gender.female:DockMargin(0, 6, 0, 6)
						self.gender.female:SetText(nut.lang.Get("female"))
						self.gender.female:Dock(LEFT)
						self.gender.female.OnChange = function(this, value)
							self.gender.male:SetChecked(false)
							this:SetChecked(true)

							LoadModels("female")
						end

						y = y + 36
						AddHeader("model")

						self.modelsPanel = self.content:Add("DScrollPanel")
						self.modelsPanel:SetPos(0, y)
						self.modelsPanel:SetSize(width, 280)

						self.models = self.modelsPanel:Add("DIconLayout")
						self.models:Dock(FILL)
						self.models:SetSpaceX(1)
						self.models:SetSpaceY(1)

						function LoadModels(gender)
							self.models:Clear()

							local models = faction[gender.."Models"]

							if (!models) then
								if (faction.maleModels) then
									models = faction.maleModels
								else
									ErrorNoHalt("Faction '"..(faction.name or faction.uniqueID or "unknown").."' does not have any models!\n")

									return CreateMainButtons()
								end
							end

							for k, v in ipairs(models) do
								if (k == 1) then
									model = v
								end
								
								local icon = self.models:Add("SpawnIcon")
								icon.DoClick = function(this)
									model = v
								end
								icon:SetSize(64, 128)
								icon:InvalidateLayout(true)
								icon:SetModel(v)
								icon.PaintOver = function(this, w, h)
									if (model == v) then
										local color = nut.config.mainColor

										surface.SetDrawColor(color.r, color.g, color.b, 200)

										for i = 1, 3 do
											local i2 = i * 2
											surface.DrawOutlinedRect(i, i, w - i2, h - i2)
										end

										surface.SetDrawColor(color.r, color.g, color.b, 25)
										surface.DrawRect(4, 4, w - 8, h - 8)
									end
								end
							end
						end

						y = y + 280
						AddHeader("attribs")

						self.attribs = {}

						local pointsLeft = nut.config.startingPoints
						local activeBar

						for k, v in ipairs(nut.attribs.buffer) do
							local bar = self.content:Add("nut_AttribBar")
							bar:SetPos(0, y)
							bar:SetSize(width, 28)
							bar:SetMax(pointsLeft)
							bar:SetText(v.name)
							bar:SetToolTip(v.desc or "No description available.")
							bar.OnChanged = function(panel, hindered)
								pointsLeft = pointsLeft - (hindered and -1 or 1)
							end
							bar.CanChange = function(panel, hindered)
								if (hindered) then return true end

								return pointsLeft > 0
							end

							y = y + 28

							self.attribs[k] = bar
						end

						LoadModels("male")

						self.title:SetText(nut.lang.Get("create"))
						self.subTitle:SetText(nut.lang.Get("create_tip"))
						self.side:SizeTo(sideWidth + ScrW() * 0.3, ScrH(), 0.25, 0, 0.5, function()
							self.content:AlphaTo(255, 0.25, 0)
						end)
					end

					for k, v in ipairs(factions) do
						AddButton(v.name or v.uniqueID or "Unknown", function()
							faction = v
							SetupCreationMenu()
						end, true)
					end
				end)
			end

			local MODEL_ANGLE = Angle(0, 45, 0)

			if (LocalPlayer().characters and table.Count(LocalPlayer().characters) > (LocalPlayer().character and 1 or 0)) then
				local function LoadCallback()
					i = 0

					self.buttons:Clear()

					local faction

					AddButton("return", function()
						CreateMainButtons()
					end)

					local width = ScrW() * 0.375

					self.content = self.side:Add("DScrollPanel")
					self.content:Dock(RIGHT)
					self.content:SetWide(width)
					self.content:DockMargin(10, 40, 10, 10)

					self.name = self.content:Add("DLabel")
					self.name:SetFont("nut_BigThinFont")
					self.name:SetTextColor(color_white)
					self.name:SetExpensiveShadow(1, Color(0, 0, 0, 100))
					self.name:SetContentAlignment(5)
					self.name:SetSize(width, 28)

					self.model = self.content:Add("DModelPanel")
					self.model:SetPos(0, 28)
					self.model:SetFOV(72)
					self.model:SetSize(width, ScrH() * 0.55)
					self.model.LayoutEntity = function(panel, entity)
						local xRatio = gui.MouseX() / ScrW()
						local yRatio = gui.MouseY() / ScrH()

						entity:SetPoseParameter("head_pitch", yRatio*80 - 40)
						entity:SetPoseParameter("head_yaw", (xRatio - 0.75)*70 + 23)
						entity:SetAngles(MODEL_ANGLE)
						entity:SetIK(false)

						panel:RunAnimation()
					end
					self.model.OnMouseEntered = function() end
					self.model.OnMousePressed = function() end
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

					local x, y = self:ScreenToLocal(0, ScrH() - 28)

					self.bottom = self.content:Add("DPanel")
					self.bottom:SetPos(0, y - 232 - 48)
					self.bottom:SetSize(width, 48)
					self.bottom:SetDrawBackground(false)

					local charIndex = 1

					local function ChooseClick(this)
						if (nut.lastCharIndex == charIndex) then return end

						if (!self.choosing) then
							nut.lastCharIndex = charIndex
							netstream.Start("nut_CharChoose", charIndex)
							self.choosing = true
						end
					end
					local function DeleteClick(this)
						if (!self.choosing) then
							local oldName = self.name:GetText()

							self.name:SetText(nut.lang.Get("delete").." "..oldName.."?")
							self.choose:SetText(nut.lang.Get("yes"))
							self.choose.DoClick = function(this)
								LocalPlayer().characters[charIndex] = nil
								netstream.Start("nut_CharDelete", charIndex)

								self.choosing = false

								if (IsValid(self.content)) then
									self.content:Remove()
								end

								if (table.Count(LocalPlayer().characters) > (LocalPlayer().character and 1 or 0)) then
									LoadCallback()
								else
									CreateMainButtons()
								end
							end
							self.delete:SetText(nut.lang.Get("no"))
							self.delete.DoClick = function(this)
								self.name:SetText(oldName)
								self.choose:SetText(nut.lang.Get("choose"))
								self.choose.DoClick = ChooseClick
								self.delete:SetText(nut.lang.Get("delete"))
								self.delete.DoClick = DeleteClick
								self.choosing = false
							end

							self.choosing = true
						end
					end

					self.choose = self.bottom:Add("DButton")
					self.choose:SetWide(width / 2 - 8)
					self.choose:Dock(LEFT)
					self.choose:SetTextColor(color_white)
					self.choose:SetExpensiveShadow(1, Color(0, 0, 0, 100))
					self.choose:SetFont("nut_BigThinFont")
					self.choose:SetText(nut.lang.Get("choose"))
					self.choose.Paint = function() end
					self.choose.DoClick = ChooseClick

					self.delete = self.bottom:Add("DButton")
					self.delete:SetWide(width / 2 - 8)
					self.delete:Dock(RIGHT)
					self.delete:SetTextColor(color_white)
					self.delete:SetExpensiveShadow(1, Color(0, 0, 0, 100))
					self.delete:SetFont("nut_BigThinFont")
					self.delete:SetText(nut.lang.Get("delete"))
					self.delete.Paint = function() end
					self.delete.DoClick = DeleteClick


					local function SetupCharacter(index)
						local info = LocalPlayer().characters[index]

						if (info) then
							self.name:SetText(info.name)
							self.name:SetTextColor(team.GetColor(info.faction))
							self.model:SetModel(info.model)

							charIndex = info.id
						end
					end

					width = width - 16

					local first = true

					for k, v in SortedPairsByMemberValue(LocalPlayer().characters, "id") do
						if (k != "__SortedIndex" and !v.banned and v.id != nut.lastCharIndex) then
							AddButton(v.name, function()
								if (v.id != charIndex) then
									SetupCharacter(k)
								end
							end, true)

							if (first) then
								SetupCharacter(charIndex)
								first = false
							end
						end
					end

					self.title:SetText(nut.lang.Get("load"))
					self.subTitle:SetText(nut.lang.Get("load_tip"))
					self.side:SizeTo(sideWidth + ScrW() * 0.3, ScrH(), 0.25, 0, 0.5, function()
						self.content:AlphaTo(255, 0.25, 0)
					end)
				end

				AddButton("load", LoadCallback)
			end

			if (nut.config.website and nut.config.website:find("http")) then
				AddButton("website", function()
					gui.OpenURL(nut.config.website)
				end)
			end

			local charIsValid = LocalPlayer().character != nil

			AddButton(charIsValid and "return" or "leave", function()
				if (charIsValid) then
					self:Remove()
				else
					LocalPlayer():ConCommand("disconnect")
				end
			end)

			self.title:SetText(SCHEMA.name)
			self.subTitle:SetText(SCHEMA.desc)
		end

		timer.Simple(0, CreateMainButtons)

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

	local colorData = {}
	colorData["$pp_colour_addr"] = 0
	colorData["$pp_colour_addg"] = 0
	colorData["$pp_colour_addb"] = 0
	colorData["$pp_colour_brightness"] = -0.05
	colorData["$pp_colour_contrast"] = 1
	colorData["$pp_colour_colour"] = 0
	colorData["$pp_colour_mulr"] = 0
	colorData["$pp_colour_mulg"] = 0
	colorData["$pp_colour_mulb"] = 0

	function PANEL:RenderScreenspaceEffects()
		local x, y = self.side:LocalToScreen(0, 0)
		local w, h = self.side:GetWide(), ScrH()

		render.SetStencilEnable(true)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
		render.SetStencilReferenceValue(1)
		render.ClearStencilBufferRectangle(x, y, x + w, h, 1)
		render.SetStencilEnable(1)

		DrawColorModify(colorData)
		render.SetStencilEnable(false)
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

	function PANEL:OnRemove()
		self:FadeOutMusic()
	end
vgui.Register("nut_CharMenu", PANEL, "EditablePanel")

if (IsValid(nut.gui.charMenu)) then
	nut.gui.charMenu:Remove()
	nut.gui.charMenu = vgui.Create("nut_CharMenu")
end

netstream.Hook("nut_CharMenu", function(forced)
	if (type(forced) == "table") then
		if (forced[2] == true) then
			LocalPlayer().character = nil

			if (forced[3]) then
				for k, v in pairs(LocalPlayer().characters) do
					if (v.id == forced[3]) then
						LocalPlayer().characters[k] = nil
					end
				end
			end
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

netstream.Hook("nut_CharCreateAuthed", function()
	if (IsValid(nut.gui.charMenu)) then
		nut.gui.charMenu.creating = false
		nut.gui.charMenu.creatingCallback()
		nut.gui.charMenu.creatingCallback = nil
	end
end)