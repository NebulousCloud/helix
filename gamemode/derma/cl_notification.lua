local PANEL = {}
	function PANEL:Init()
		self:ParentToHUD()

		self.text = self:Add("DLabel")
		self.text:SetTextColor(color_white)
		self.text:SetExpensiveShadow(1, color_black)
		self.text:Dock(FILL)
		self.text:SetContentAlignment(5)

		self.start = CurTime()
		self.finish = self.start + 8

		LocalPlayer():EmitSound("buttons/button14.wav", 40)
	end

	function PANEL:SetText(text)
		self.text:SetText(text)
	end

	function PANEL:CallOnRemove(callback)
		self.callback = callback
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(40, 40, 45, 200)
		surface.DrawRect(0, 0, w, h)

		if (self.start and self.finish) then
			local fraction = 1 - math.TimeFraction(self.start, self.finish, CurTime())
			local color = nut.config.mainColor
			color.a = 50

			surface.SetDrawColor(color)
			surface.DrawRect(0, 21, w, 3)

			color.a = 225

			surface.SetDrawColor(color)
			surface.DrawRect(0, 21, w * fraction, 3)
		end
	end

	function PANEL:Think()
		if (self.start and self.finish and CurTime() > self.finish) then
			self:MoveTo(ScrW(), ScrH() - 25, 1.5, 0.1, 0.35)
			self:AlphaTo(0, 0.35, 0)
			
			timer.Simple(0.25, function()
				if (IsValid(self)) then
					if (self.callback) then
						self.callback()
					end

					self:Remove()
				end
			end)
		end
	end
vgui.Register("nut_Notification", PANEL, "DPanel")