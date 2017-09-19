local PANEL = {}
	function PANEL:Init()
		if (IsValid(nut.gui.charCreate)) then
			nut.gui.charCreate:Remove()
		end

		nut.gui.charCreate = self

		self:SetSize(ScrW() * 0.45, ScrH() * 0.55)
		self:SetPos(ScrW() * 0.3, ScrH() * 0.3 + 16)

		self.notice = self:Add("nutNoticeBar")
		self.notice:SetType(4)
		self.notice:SetText(L"charCreateTip")
		self.notice:SetWide(self:GetWide())

		self.payload = {}
		self.lastY = self.notice:GetTall() + 8
	end

	function PANEL:AddLabel(text)
		local label = self:Add("DLabel")
		label:SetPos(0, self.lastY)
		label:SetFont("nutMenuButtonFont")
		label:SetText(L(text))
		label:SizeToContents()
		label:SetTextColor(color_white)
		label:SetExpensiveShadow(2, Color(0, 0, 0, 200))

		self.lastY = self.lastY + label:GetTall() + 8

		return label
	end

	function PANEL:AddTextBox()
		local textBox = self:Add("DTextEntry")
		textBox:SetFont("nutMenuButtonLightFont")
		textBox:SetWide(self:GetWide())
		textBox:SetPos(0, self.lastY)
		textBox:SetTall(36)

		self.lastY = self.lastY + textBox:GetTall() + 8

		return textBox
	end

	function PANEL:SetUp(faction)
		self.faction = faction
		self.payload.faction = self.faction
		
		for k, v in SortedPairsByMemberValue(nut.char.vars, "index") do
			if (!v.noDisplay and k != "__SortedIndex") then
				if (v.shouldDisplay) then
					if (v.shouldDisplay(self) == false) then
						continue
					end
				end

				self:AddLabel(k)

				if (v.OnDisplay) then
					local panel = v.OnDisplay(self, self.lastY)

					if (IsValid(panel)) then
						self.lastY = self.lastY + panel:GetTall() + 8

						if (v.OnPostSetup) then
							v.OnPostSetup(panel, faction, self.payload)
						end
					end
				elseif (type(v.default) == "string") then
					local textBox = self:AddTextBox()
					textBox.OnTextChanged = function(this)
						self.payload[k] = this:GetText()
					end

					if (v.OnPostSetup) then
						v.OnPostSetup(textBox, faction, self.payload)
					end
				end
			end
		end
	end
vgui.Register("nutCharCreate", PANEL, "DScrollPanel")