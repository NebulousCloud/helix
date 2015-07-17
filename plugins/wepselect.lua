PLUGIN.name = "Weapon Select"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "A replacement for the default weapon selection."

if (SERVER) then
	concommand.Add("nut_selectweapon", function(client, command, arguments)
		local index = tonumber(arguments[1]) or 1
		local weapon = client:GetWeapons()[index]

		if (IsValid(weapon)) then
			client:SelectWeapon(weapon:GetClass())
		end
	end)
else
	PLUGIN.index = PLUGIN.index or 1
	PLUGIN.deltaIndex = PLUGIN.deltaIndex or PLUGIN.index
	PLUGIN.infoAlpha = PLUGIN.infoAlpha or 0
	PLUGIN.alpha = PLUGIN.alpha or 0
	PLUGIN.alphaDelta = PLUGIN.alphaDelta or PLUGIN.alpha
	PLUGIN.fadeTime = PLUGIN.fadeTime or 0

	function PLUGIN:HUDPaint()
		local frameTime = FrameTime()

		self.alphaDelta = Lerp(frameTime * 10, self.alphaDelta, self.alpha)

		local fraction = self.alphaDelta

		if (fraction > 0) then
			local weapons = LocalPlayer():GetWeapons()
			local total = #weapons
			local x, y = ScrW() * 0.5, ScrH() * 0.5
			local spacing = math.pi * 0.85
			local radius = 240 * self.alphaDelta

			self.deltaIndex = Lerp(frameTime * 12, self.deltaIndex, self.index) --math.Approach(self.deltaIndex, self.index, fTime() * 12)

			local index = self.deltaIndex
			
			for k, v in ipairs(weapons) do
				if (!weapons[self.index]) then
					self.index = total
				end

				local theta = (k - index) * 0.1
				local color = ColorAlpha(k == self.index and nut.config.get("color") or color_white, (255 - math.abs(theta * 3) * 255) * fraction)
				local lastY = 0
				local shiftX = ScrW()*.02

				if (self.markup and k < self.index) then
					local w, h = self.markup:Size()

					lastY = (h * fraction)

					if (k == self.index - 1) then
						self.infoAlpha = Lerp(frameTime * 3, self.infoAlpha, 255)

						self.markup:Draw(x + 5 + shiftX, y + 30, 0, 0, self.infoAlpha * fraction)
					end
				end

				surface.SetFont("nutSubTitleFont")
				local tx, ty = surface.GetTextSize(v:GetPrintName():upper())
				local scale = (1 - math.abs(theta*2))

				local matrix = Matrix()
				matrix:Translate(Vector(
					shiftX + x + math.cos(theta * spacing + math.pi) * radius + radius,
					y + lastY + math.sin(theta * spacing + math.pi) * radius - ty/2 ,
					1))
				matrix:Rotate(angle or Angle(0, 0, 0))
				matrix:Scale(Vector(1, 1, 0) * scale)

				cam.PushModelMatrix(matrix)
					nut.util.drawText(v:GetPrintName():upper(), 2, ty/2, color, 0, 1, "nutSubTitleFont")
				cam.PopModelMatrix()
			end

			if (self.fadeTime < CurTime() and self.alpha > 0) then
				self.alpha = 0
			end
		end
	end

	local weaponInfo = {
		"Author",
		"Contact",
		"Purpose",
		"Instructions"
	}

	function PLUGIN:onIndexChanged()
		self.alpha = 1
		self.fadeTime = CurTime() + 5

		local weapon = LocalPlayer():GetWeapons()[self.index]

		self.markup = nil

		if (IsValid(weapon)) then
			local text = ""

			for k, v in ipairs(weaponInfo) do
				if (weapon[v] and weapon[v]:find("%S")) then
					local color = nut.config.get("color")

					text = text.."<font=nutSmallBoldFont><color="..color.r..","..color.g..","..color.b..">"..L(v).."</font></color>\n"..weapon[v].."\n"
				end
			end

			if (text != "") then
				self.markup = markup.Parse("<font=nutSmallFont>"..text, ScrW() * 0.3)
				self.infoAlpha = 0
			end

			local source, pitch = hook.Run("WeaponCycleSound") or "common/talk.wav"

			LocalPlayer():EmitSound(source or "common/talk.wav", 50, pitch or 180)
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		local weapon = client:GetActiveWeapon()

		if (!client:InVehicle() and (!IsValid(weapon) or weapon:GetClass() != "weapon_physgun" or !client:KeyDown(IN_ATTACK))) then
			bind = bind:lower()

			if (bind:find("invprev") and pressed) then
				self.index = self.index - 1

				if (self.index < 1) then
					self.index = #client:GetWeapons()
				end

				self:onIndexChanged()

				return true
			elseif (bind:find("invnext") and pressed) then
				self.index = self.index + 1

				if (self.index > #client:GetWeapons()) then
					self.index = 1
				end

				self:onIndexChanged()

				return true
			elseif (bind:find("slot")) then
				self.index = math.Clamp(tonumber(bind:match("slot(%d)")) or 1, 1, #LocalPlayer():GetWeapons())
				self:onIndexChanged()

				return true
			elseif (bind:find("attack") and pressed and self.alpha > 0) then
				LocalPlayer():EmitSound(hook.Run("WeaponSelectSound", LocalPlayer():GetWeapons()[self.index]) or "buttons/button16.wav")

				RunConsoleCommand("nut_selectweapon", self.index)
				self.alpha = 0

				return true
			end
		end
	end
end