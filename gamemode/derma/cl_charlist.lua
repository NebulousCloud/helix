local PANEL = {}
	function PANEL:ChooseChar(nextChar)
		local index = self.currentIndex + (nextChar and 1 or -1)
		local characters = LocalPlayer().characters

		if (!characters or table.Count(characters) < 1) then
			self.model:Remove()
			self.prev:Remove()
			self.next:Remove()
			self.name:Remove()
			self.menu:Remove()
			self.choose:Remove()
			self.delete:Remove()

			self.fault = self:Add("DLabel")
			self.fault:SetText("You do not have any characters.")
			self.fault:SetFont("nut_MenuButtonFont")
			self.fault:SetTextColor(Color(240, 240, 240))
			self.fault:SetExpensiveShadow(1, color_black)
			self.fault:SizeToContents()

			return
		end

		local character = characters[index]

		if (!character) then
			index = 1
			character = characters[index]
		end

		self.currentIndex = index

		self.prev:SetVisible(characters[self.currentIndex - 1] != nil)
		self.next:SetVisible(characters[self.currentIndex + 1] != nil)

		self.model:SetModel(character.model)
		self.model:SetSkin(character.skin)

		local faction = nut.faction.GetByID(character.faction).name or "No faction name."
		local name = character.name or "John Doe"
		local desc = character.desc or nut.lang.Get("no_desc")

		self.model:SetToolTip(nut.lang.Get("char_info", name, desc, faction))

		self.name:SetText(character.name)
		self.name:SizeToContentsY()
	end

	function PANEL:Init()
		self:SetPos(ScrW() * 0.4, ScrH() * 0.15)
		self:SetSize(ScrW() * 0.5, ScrH() * 0.7)
		self:MakePopup()
		self:SetTitle("")
		self:SetDraggable(false)
		self:ShowCloseButton(false)

		self.currentIndex = 1

		local characters = LocalPlayer().characters

		if (!characters or table.Count(characters) < 1) then
			self.fault = self:Add("DLabel")
			self.fault:SetText("You do not have any characters.")
			self.fault:SetFont("nut_MenuButtonFont")
			self.fault:SetTextColor(Color(240, 240, 240))
			self.fault:SetExpensiveShadow(1, color_black)
			self.fault:SizeToContents()

			return
		end

		local character = characters[self.currentIndex]

		self.model = self:Add("DModelPanel")
		self.model:Dock(FILL)
		self.model:DockMargin(16, 16, 16, 16)
		self.model:SetModel(character.model)
		self.model:SetFOV(90)

		local faction = nut.faction.GetByID(character.faction).name or "No faction name."
		local name = character.name or "John Doe"
		local desc = character.desc or nut.lang.Get("no_desc")
		
		self.model:SetToolTip(nut.lang.Get("char_info", name, desc, faction))

		self.prev = self.model:Add("nut_MenuButton")
		self.prev:SetText("<")
		self.prev:Dock(LEFT)
		self.prev:DockMargin(4, 4, 4, 4)
		self.prev.OnClick = function(prev)
			self:ChooseChar()
		end

		self.next = self.model:Add("nut_MenuButton")
		self.next:SetText(">")
		self.next:Dock(RIGHT)
		self.next:DockMargin(4, 4, 4, 4)
		self.next.OnClick = function(nextChar)
			self:ChooseChar(true)
		end

		self.prev:SetVisible(characters[self.currentIndex - 1] != nil)
		self.next:SetVisible(characters[self.currentIndex + 1] != nil)

		self.name = self:Add("DLabel")
		self.name:Dock(TOP)
		self.name:SetFont("nut_HeaderFont")
		self.name:SetExpensiveShadow(1, color_black)
		self.name:SetText(character.name)
		self.name:SetTextColor(Color(240, 240, 240))
		self.name:SizeToContentsY()
		self.name:SetWide(ScrW() * 0.4)
		self.name:SetContentAlignment(5)

		self.menu = self:Add("DPanel")
		self.menu:Dock(BOTTOM)

		surface.SetFont("nut_MenuButtonFont")
		local _, height = surface.GetTextSize("W")
		
		self.menu:SetTall(height + 16)
		self.menu:SetDrawBackground(false)

		self.choose = self.menu:Add("nut_MenuButton")
		self.choose:Dock(LEFT)
		self.choose:SetWide(ScrW() * 0.2)
		self.choose:SetText(nut.lang.Get("choose"))
		self.choose:SetToolTip(nut.lang.Get("choose_tip"))
		self.choose.OnClick = function()
			if (LocalPlayer().character) then
				hook.Run("OnCharChanged", LocalPlayer())
			end

			if (IsValid(nut.gui.inv)) then
				nut.gui.inv:Remove()
			end

			netstream.Start("nut_CharChoose", LocalPlayer().characters[self.currentIndex].id)
		end

		self.delete = self.menu:Add("nut_MenuButton")
		self.delete:Dock(RIGHT)
		self.delete:SetWide(ScrW() * 0.2)
		self.delete:SetText(nut.lang.Get("delete"))
		self.delete:SetToolTip(nut.lang.Get("delete_tip"))
		self.delete.OnClick = function(this)
			local selection = LocalPlayer().characters[self.currentIndex]

			if (selection and selection.id) then
				if (LocalPlayer().character and LocalPlayer().character:GetVar("id") == selection.id) then
					return false
				end
			end

			Derma_Query(nut.lang.Get("delete_question", self.name:GetText()), nut.lang.Get("delete"), nut.lang.Get("no"), function()
			end, nut.lang.Get("yes"), function()
				if (selection) then
					netstream.Start("nut_CharDelete", LocalPlayer().characters[self.currentIndex].id)
					LocalPlayer().characters[self.currentIndex] = nil
					self.currentIndex = self.currentIndex - 1

					if (LocalPlayer().characters[self.currentIndex + 1]) then
						self:ChooseChar(true)
					else
						self:ChooseChar()
					end
				end
			end)
		end
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end

	function PANEL:Paint(w, h)
	end
vgui.Register("nut_CharacterList", PANEL, "DFrame")