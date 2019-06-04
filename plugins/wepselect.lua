
PLUGIN.name = "Weapon Select"
PLUGIN.author = "Chessnut"
PLUGIN.description = "A replacement for the default weapon selection."

if (CLIENT) then
	PLUGIN.index = PLUGIN.index or 1
	PLUGIN.deltaIndex = PLUGIN.deltaIndex or PLUGIN.index
	PLUGIN.infoAlpha = PLUGIN.infoAlpha or 0
	PLUGIN.alpha = PLUGIN.alpha or 0
	PLUGIN.alphaDelta = PLUGIN.alphaDelta or PLUGIN.alpha
	PLUGIN.fadeTime = PLUGIN.fadeTime or 0
	PLUGIN.weapons = PLUGIN.weapons or {}

	function PLUGIN:LoadFonts(font, genericFont)
		surface.CreateFont("ixWeaponSelectFont", {
			font = font,
			size = ScreenScale(16),
			extended = true,
			weight = 1000
		})
	end

	function PLUGIN:HUDShouldDraw(name)
		if (name == "CHudWeaponSelection") then
			return false
		end
	end

	function PLUGIN:HUDPaint()
		local frameTime = FrameTime()

		self.alphaDelta = Lerp(frameTime * 10, self.alphaDelta, self.alpha)

		local fraction = self.alphaDelta

		if (fraction > 0.01) then
			local x, y = ScrW() * 0.5, ScrH() * 0.5
			local spacing = math.pi * 0.85
			local radius = 240 * self.alphaDelta
			local shiftX = ScrW() * .02

			self.deltaIndex = Lerp(frameTime * 12, self.deltaIndex, self.index)

			local index = self.deltaIndex

			if (!self.weapons[self.index]) then
				self.index = #self.weapons
			end

			for i = 1, #self.weapons do
				local theta = (i - index) * 0.1
				local color = ColorAlpha(
					i == self.index and ix.config.Get("color") or color_white,
					(255 - math.abs(theta * 3) * 255) * fraction
				)

				local lastY = 0

				if (self.markup and (i < self.index or i == 1)) then
					if (self.index != 1) then
						local _, h = self.markup:Size()
						lastY = h * fraction
					end

					if (i == 1 or i == self.index - 1) then
						self.infoAlpha = Lerp(frameTime * 3, self.infoAlpha, 255)
						self.markup:Draw(x + 6 + shiftX, y + 30, 0, 0, self.infoAlpha * fraction)
					end
				end

				surface.SetFont("ixWeaponSelectFont")
				local weaponName = self.weapons[i]:GetPrintName():upper()
				local _, ty = surface.GetTextSize(weaponName)
				local scale = 1 - math.abs(theta * 2)

				local matrix = Matrix()
				matrix:Translate(Vector(
					shiftX + x + math.cos(theta * spacing + math.pi) * radius + radius,
					y + lastY + math.sin(theta * spacing + math.pi) * radius - ty / 2 ,
					1))
				matrix:Scale(Vector(1, 1, 0) * scale)

				cam.PushModelMatrix(matrix)
					ix.util.DrawText(weaponName, 2, ty / 2, color, 0, 1, "ixWeaponSelectFont")
				cam.PopModelMatrix()
			end

			if (self.fadeTime < CurTime() and self.alpha > 0) then
				self.alpha = 0
			end
		elseif (#self.weapons > 0) then
			self.weapons = {}
		end
	end

	function PLUGIN:OnIndexChanged(weapon)
		self.alpha = 1
		self.fadeTime = CurTime() + 5
		self.markup = nil

		if (IsValid(weapon)) then
			local instructions = weapon.Instructions
			local text = ""

			if (instructions != nil and instructions:find("%S")) then
				local color = ix.config.Get("color")
				text = text .. string.format(
					"<font=ixItemBoldFont><color=%d,%d,%d>%s</font></color>\n%s\n",
					color.r, color.g, color.b, L("Instructions"), instructions
				)
			end

			if (text != "") then
				self.markup = markup.Parse("<font=ixItemDescFont>"..text, ScrW() * 0.3)
				self.infoAlpha = 0
			end

			local source, pitch = hook.Run("WeaponCycleSound")
			LocalPlayer():EmitSound(source or "common/talk.wav", 50, pitch or 180)
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		bind = bind:lower()

		if (!pressed or !bind:find("invprev") and !bind:find("invnext")
		and !bind:find("slot") and !bind:find("attack")) then
			return
		end

		local currentWeapon = client:GetActiveWeapon()
		local bValid = IsValid(currentWeapon)
		local bTool

		if (client:InVehicle() or (bValid and currentWeapon:GetClass() == "weapon_physgun" and client:KeyDown(IN_ATTACK))) then
			return
		end

		if (bValid and currentWeapon:GetClass() == "gmod_tool") then
			local tool = client:GetTool()
			bTool = tool and (tool.Scroll != nil)
		end

		self.weapons = {}

		for _, v in pairs(client:GetWeapons()) do
			self.weapons[#self.weapons + 1] = v
		end

		if (bind:find("invprev") and !bTool) then
			local oldIndex = self.index
			self.index = math.min(self.index + 1, #self.weapons)

			if (self.alpha == 0 or oldIndex != self.index) then
				self:OnIndexChanged(self.weapons[self.index])
			end

			return true
		elseif (bind:find("invnext") and !bTool) then
			local oldIndex = self.index
			self.index = math.max(self.index - 1, 1)

			if (self.alpha == 0 or oldIndex != self.index) then
				self:OnIndexChanged(self.weapons[self.index])
			end

			return true
		elseif (bind:find("slot")) then
			self.index = math.Clamp(tonumber(bind:match("slot(%d)")) or 1, 1, #self.weapons)
			self:OnIndexChanged(self.weapons[self.index])

			return true
		elseif (bind:find("attack") and self.alpha > 0) then
			local weapon = self.weapons[self.index]

			if (IsValid(weapon)) then
				LocalPlayer():EmitSound(hook.Run("WeaponSelectSound", weapon) or "HL2Player.Use")

				input.SelectWeapon(weapon)
				self.alpha = 0
			end

			return true
		end
	end

	function PLUGIN:ScoreboardShow()
		self.alpha = 0
	end

	function PLUGIN:ShouldPopulateEntityInfo(entity)
		if (self.alpha > 0) then
			return false
		end
	end
end
