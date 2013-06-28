local PANEL = {}
	local STAGE_FACTION = 1
	local STAGE_GENDER = 2
	local STAGE_NAME = 3
	local STAGE_DESC = 4
	local STAGE_MODEL = 5
	local STAGE_ATTRIBS = 6

	local STAGE_ANSWERS = {}

	local STAGES = {}

	local function makeDisplay()
		return true
	end

	STAGES[STAGE_FACTION] = {
		shouldDisplay = function()
			local count = 0

			for k, v in SortedPairs(nut.faction.GetAll()) do
				if (nut.faction.CanBe(LocalPlayer(), v.index)) then
					count = count + 1
				end
			end

			if (count < 2) then
				STAGE_ANSWERS[STAGE_FACTION] = 1

				return false
			end

			return true
		end,
		title = nut.lang.Get("faction_status").."...",
		layout = function(panel, title)
			for k, v in SortedPairs(nut.faction.GetAll()) do
				if (nut.faction.CanBe(LocalPlayer(), v.index)) then
					local button = panel:Add("nut_MenuButton")
					button:Dock(TOP)
					button:DockMargin(8, 8, 8, 8)
					button:SetText(v.name)
					button.OnClick = function(button)
						STAGE_ANSWERS[STAGE_FACTION] = k

						title:SetText(nut.lang.Get("faction_status")..v.name..".")
						title:SizeToContents()
					end
				end
			end
		end,
		canContinue = function(panel)
			return nut.faction.GetByID(STAGE_ANSWERS[STAGE_FACTION]) != nil
		end
	}
	STAGES[STAGE_GENDER] = {
		shouldDisplay = makeDisplay,
		title = nut.lang.Get("gender_status").."...",
		layout = function(panel, title)
			local male = panel:Add("nut_MenuButton")
			male:Dock(TOP)
			male:SetText(nut.lang.Get("male"))
			male.OnClick = function()
				STAGE_ANSWERS[STAGE_GENDER] = "male"

				title:SetText(nut.lang.Get("gender_status")..nut.lang.GetLower("male")..".")
				title:SizeToContents()
			end

			local female = panel:Add("nut_MenuButton")
			female:Dock(TOP)
			female:SetText(nut.lang.Get("female"))
			female.OnClick = function()
				STAGE_ANSWERS[STAGE_GENDER] = "female"

				title:SetText(nut.lang.Get("gender_status")..nut.lang.GetLower("female")..".")
				title:SizeToContents()
			end
		end,
		canContinue = function(panel)
			return STAGE_ANSWERS[STAGE_GENDER] != nil
		end
	}
	STAGES[STAGE_NAME] = {
		shouldDisplay = function()
			local faction = nut.faction.GetByID(STAGE_ANSWERS[STAGE_FACTION])

			if (faction.GetDefaultName) then
				STAGE_ANSWERS[STAGE_NAME] = faction:GetDefaultName()

				return false
			end

			return true
		end,
		title = nut.lang.Get("name_status").."...",
		layout = function(panel, title)
			local submit

			local textEntry = panel:Add("DTextEntry")
			textEntry:SetTall(48)
			textEntry:Dock(TOP)
			textEntry:SetFont("nut_BigThinFont")
			textEntry.OnEnter = function()
				submit.OnClick()
			end

			submit = panel:Add("nut_MenuButton")
			submit:SetText(nut.lang.Get("set_as"))
			submit:Dock(TOP)
			submit:DockMargin(0, 16, 0, 0)
			submit.OnClick = function()
				local text = textEntry:GetText() or ""

				if (text == "") then
					return false
				end

				text = string.sub(text, 1, 70)

				title:SetText(nut.lang.Get("name_status")..text..".")
				title:SizeToContents()

				STAGE_ANSWERS[STAGE_NAME] = text
			end
		end,
		canContinue = function(panel)
			return STAGE_ANSWERS[STAGE_NAME] != nil
		end
	}
	STAGES[STAGE_DESC] = {
		shouldDisplay = makeDisplay,
		title = nut.lang.Get("desc_status").."...",
		layout = function(panel, title)
			local submit

			local textEntry = panel:Add("DTextEntry")
			textEntry:SetTall(48)
			textEntry:Dock(TOP)
			textEntry:SetFont("nut_BigThinFont")
			textEntry:SetToolTip(nut.lang.Get("desc_char_req", nut.config.descMinChars))
			textEntry.OnEnter = function()
				submit.OnClick()
			end

			submit = panel:Add("nut_MenuButton")
			submit:SetText(nut.lang.Get("set_as"))
			submit:Dock(TOP)
			submit:DockMargin(0, 16, 0, 0)
			submit.OnClick = function()
				local text = textEntry:GetText() or ""

				if (string.len(text) < nut.config.descMinChars) then
					return false
				end

				text = string.sub(text, 1, 240)
				
				title:SetText(nut.lang.Get("desc_status")..text..".")
				title:SetWide(panel:GetWide())

				STAGE_ANSWERS[STAGE_DESC] = text
			end
		end,
		canContinue = function(panel)
			return STAGE_ANSWERS[STAGE_DESC] != nil
		end
	}
	STAGES[STAGE_MODEL] = {
		shouldDisplay = function()
			local default = nut.faction.GetByID(STAGE_ANSWERS[STAGE_FACTION]).defaultModel

			if (default != nil) then
				STAGE_ANSWERS[STAGE_MODEL] = default

				return false
			end

			return true
		end,
		title = "I look like...",
		layout = function(panel, title)
			local faction = nut.faction.GetByID(STAGE_ANSWERS[STAGE_FACTION])
			local gender = STAGE_ANSWERS[STAGE_GENDER]
			local models = faction[gender.."Models"]

			local modelPanel = panel:Add("DModelPanel")
			modelPanel:SetSize(panel:GetSize())
			modelPanel:SetModel(models[1])

			STAGE_ANSWERS[STAGE_MODEL] = modelPanel.Entity:GetModel()
			
			local modelIndex = 1

			local prevModel = modelPanel:Add("nut_MenuButton")
			prevModel:SetText("<")
			prevModel:SetWide(48)
			prevModel:Dock(NODOCK)
			prevModel.OnClick = function()
				if (models[modelIndex - 1]) then
					modelIndex = modelIndex - 1
					modelPanel:SetModel(models[modelIndex])

					STAGE_ANSWERS[STAGE_MODEL] = modelPanel.Entity:GetModel()
				else
					return false
				end
			end

			local nextModel = modelPanel:Add("nut_MenuButton")
			nextModel:SetText(">")
			nextModel:SetWide(48)
			nextModel:SetPos(56, 0)
			nextModel:Dock(NODOCK)
			nextModel.OnClick = function()
				if (models[modelIndex + 1]) then
					modelIndex = modelIndex + 1
					modelPanel:SetModel(models[modelIndex])

					STAGE_ANSWERS[STAGE_MODEL] = modelPanel.Entity:GetModel()
				else
					return false
				end
			end
		end,
		canContinue = function(panel)
			return STAGE_ANSWERS[STAGE_MODEL] != nil
		end
	}
	STAGES[STAGE_ATTRIBS] = {
		shouldDisplay = function()
			return #nut.attribs.GetAll() > 0
		end,
		title = "You have # points left.",
		layout = function(panel, title)
			local points = nut.config.startingPoints
			local pointsLeft = points
			local bars = {}

			STAGE_ANSWERS[STAGE_ATTRIBS] = {}

			title:SetText("You have "..pointsLeft.." points left.")
			title:SizeToContents()

			for k, v in ipairs(nut.attribs.GetAll()) do
				local attribute = nut.attribs.Get(k)

				local bar = panel:Add("nut_AttribBar")
				bar:Dock(TOP)
				bar:SetMax(nut.config.startingPoints)
				bar:SetText(attribute.name)
				bar:SetToolTip(attribute.desc)
				bar.OnChanged = function(panel2, hindered)
					if (hindered) then
						pointsLeft = pointsLeft + 1
					else
						pointsLeft = pointsLeft - 1
					end

					title:SetText("You have "..pointsLeft.." points left.")
					title:SizeToContents()

					STAGE_ANSWERS[STAGE_ATTRIBS][k] = panel2:GetValue()
				end
				bar.CanChange = function(panel2, hindered)
					if (hindered) then
						return true
					end

					return pointsLeft > 0
				end

				bars[k] = bar
			end
		end,
		canContinue = function(panel)
			return true
		end
	}

	function PANEL:SetupStage(index)
		local stage = STAGES[index]

		if (stage and stage.shouldDisplay() == true) then
			self.panel:Clear(true)

			self.title:SetText(stage.title)
			self.title:SizeToContents()

			stage.layout(self.panel, self.title)
		else
			self.currentStage = self.currentStage + 1
			self:SetupStage(self.currentStage)
		end
	end

	function PANEL:Init()
		self:SetPos(ScrW() * 0.4, ScrH() * 0.15)
		self:SetSize(ScrW() * 0.5, ScrH() * 0.7)
		self:MakePopup()
		self:SetTitle("")
		self:SetDraggable(false)
		self:ShowCloseButton(false)

		self.panel = NULL
		self.currentStage = STAGE_FACTION

		self.next = self:Add("nut_MenuButton")
		self.next:SetText(">")
		self.next:Dock(RIGHT)
		self.next.OnClick = function(button)
			if (STAGES[self.currentStage].canContinue()) then
				self.currentStage = self.currentStage + 1

				if (STAGES[self.currentStage]) then
					self:SetupStage(self.currentStage)
				else
					self:Finish()
				end
			else
				return false
			end
		end

		self.panel = self:Add("DScrollPanel")
		self.panel:Dock(FILL)
		self.panel:DockMargin(32, 32, 32, 32)

		self.title = self:Add("DLabel")
		self.title:SetTextColor(Color(255, 255, 255))
		self.title:SetText("")
		self.title:SetFont("nut_HeaderFont")
		self.title:SetExpensiveShadow(1, color_black)
		self.title:SizeToContents()

		self:SetupStage(self.currentStage)
	end

	function PANEL:Finish(noSend)
		if (!noSend) then
			nut.gui.char.validating = true

			self.title:SetText(nut.lang.Get("char_validating"))
			self.title:SizeToContents()

			self.panel:Clear(true)
			self.next:Remove()

			timer.Simple(5, function()
				if (nut.gui.char.validating) then
					self.title:SetText("Validation timed out! Press 'Cancel'...")
					self.title:SizeToContents()

					nut.gui.char.validating = false
				end
			end)

			net.Start("nut_CharCreate")
				net.WriteString(STAGE_ANSWERS[STAGE_NAME])
				net.WriteString(STAGE_ANSWERS[STAGE_GENDER])
				net.WriteString(STAGE_ANSWERS[STAGE_DESC])
				net.WriteString(STAGE_ANSWERS[STAGE_MODEL])
				net.WriteUInt(STAGE_ANSWERS[STAGE_FACTION], 8)
				net.WriteTable(STAGE_ANSWERS[STAGE_ATTRIBS] or {})
			net.SendToServer()
		end

		STAGE_ANSWERS = {}
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end

	function PANEL:Paint(w, h)
	end
vgui.Register("nut_CharacterCreate", PANEL, "DFrame")

net.Receive("nut_CharCreateAuthed", function(length)
	nut.gui.char.validating = false
	nut.gui.charMenu:ResetMenu()
end)