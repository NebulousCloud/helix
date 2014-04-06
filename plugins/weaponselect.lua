PLUGIN.name = "Weapon Selector"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a custom weapon selector."

if (CLIENT) then
	PLUGIN.lastSlot = PLUGIN.lastSlot or 1
	PLUGIN.lifeTime = PLUGIN.lifeTime or 0
	PLUGIN.deathTime = PLUGIN.deathTime or 0

	local LIFE_TIME = 4
	local DEATH_TIME = 5

	function PLUGIN:OnSlotChanged()
		self.lifeTime = CurTime() + LIFE_TIME
		self.deathTime = CurTime() + DEATH_TIME

		for k, v in SortedPairs(LocalPlayer():GetWeapons()) do
			if (k == self.lastSlot) then
				if (v.Instructions and string.find(v.Instructions, "%S")) then
					self.markup = markup.Parse("<font=nut_TargetFont>"..v.Instructions.."</font>")

					return
				else
					self.markup = nil
				end
			end
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		local weapon = client:GetActiveWeapon()

		if (!client:InVehicle() and (!IsValid(weapon) or weapon:GetClass() != "weapon_physgun" or !client:KeyDown(IN_ATTACK))) then
			bind = string.lower(bind)

			if (string.find(bind, "invprev") and pressed) then
				self.lastSlot = self.lastSlot - 1

				if (self.lastSlot <= 0) then
					self.lastSlot = #client:GetWeapons()
				end

				self:OnSlotChanged()

				return true
			elseif (string.find(bind, "invnext") and pressed) then
				self.lastSlot = self.lastSlot + 1

				if (self.lastSlot > #client:GetWeapons()) then
					self.lastSlot = 1
				end

				self:OnSlotChanged()

				return true
			elseif (string.find(bind, "+attack") and pressed) then
				if (CurTime() < self.deathTime) then
					self.lifeTime = 0
					self.deathTime = 0

					for k, v in SortedPairs(LocalPlayer():GetWeapons()) do
						if (k == self.lastSlot) then
							RunConsoleCommand("nut_selectwep", v:GetClass())

							return true
						end
					end
				end
			elseif (string.find(bind, "slot")) then
				self.lastSlot = math.Clamp(tonumber(string.match(bind, "slot(%d)")) or 1, 1, #LocalPlayer():GetWeapons())
				self.lifeTime = CurTime() + LIFE_TIME
				self.deathTime = CurTime() + DEATH_TIME

				return true
			end
		end
	end

	function PLUGIN:HUDPaint()
		local x = ScrW() * 0.475

		for k, v in SortedPairs(LocalPlayer():GetWeapons()) do
			local y = (ScrH() * 0.4) + (k * 24)
			local y2 = y

			local color = Color(255, 255, 255)

			if (k == self.lastSlot) then
				color = nut.config.mainColor
			end

			color.a = math.Clamp(255 - math.TimeFraction(self.lifeTime, self.deathTime, CurTime()) * 255, 0, 255)
			nut.util.DrawText(x, y, string.upper(v:GetPrintName()), color, nil, 0)

			if (k == self.lastSlot and self.markup) then
				surface.SetDrawColor(30, 30, 30, color.a * 0.95)
				surface.DrawRect(x + 118, ScrH() * 0.4 - 4, self.markup:GetWidth() + 20, self.markup:GetHeight() + 18)

				self.markup:Draw(x + 128, ScrH() * 0.4 + 24, 0, 1, color.a)
			end
		end
	end
else
	concommand.Add("nut_selectwep", function(client, command, arguments)
		client:SelectWeapon(arguments[1] or (nut.config.nutFists and "nut_fists" or "nut_keys"))
	end)
end