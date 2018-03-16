PLUGIN.name = "Stamina"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds a stamina system to limit running."

if (SERVER) then
	function PLUGIN:PostPlayerLoadout(client)
		client:SetLocalVar("stm", 100)

		local uniqueID = "ixStam"..client:SteamID()
		local offset = 0
		local velocity
		local length2D = 0
		local runSpeed = client:GetRunSpeed() - 5

		timer.Create(uniqueID, 0.25, 0, function()
			if (IsValid(client)) then
				local character = client:GetChar()

				if (client:GetMoveType() != MOVETYPE_NOCLIP and character) then
					velocity = client:GetVelocity()
					length2D = velocity:Length2D()
					runSpeed = ix.config.Get("runSpeed") + character:GetAttrib("stm", 0)

					if (client:WaterLevel() > 1) then
						runSpeed = runSpeed * 0.775
					end

					if (client:KeyDown(IN_SPEED) and length2D >= (runSpeed - 10)) then
						offset = -2 + (character:GetAttrib("end", 0) / 60)
					elseif (offset > 0.5) then
						offset = 1
					else
						offset = 1.75
					end

					if (client:Crouching()) then
						offset = offset + 0.25
					end

					offset = hook.Run("AdjustStaminaOffset", client, offset) or offset

					local current = client:GetLocalVar("stm", 0)
					local value = math.Clamp(current + offset, 0, 100)

					if (current != value) then
						client:SetLocalVar("stm", value)

						if (value == 0 and !client:GetNetVar("brth", false)) then
							client:SetRunSpeed(ix.config.Get("walkSpeed"))
							client:SetNetVar("brth", true)

							--character:UpdateAttrib("end", 0.1)
							--character:UpdateAttrib("stm", 0.01)

							hook.Run("PlayerStaminaLost", client)
						elseif (value >= 50 and client:GetNetVar("brth", false)) then
							client:SetRunSpeed(runSpeed)
							client:SetNetVar("brth", nil)

							hook.Run("PlayerStaminaGained", client)
						end
					end
				end
			else
				timer.Remove(uniqueID)
			end
		end)
	end

	local playerMeta = FindMetaTable("Player")

	function playerMeta:RestoreStamina(amount)
		local current = self:GetLocalVar("stm", 0)
		local value = math.Clamp(current + amount, 0, 100)

		self:SetLocalVar("stm", value)
	end
else
	ix.bar.Add(function()
		return LocalPlayer():GetLocalVar("stm", 0) / 100
	end, Color(200, 200, 40), nil, "stm")
end
