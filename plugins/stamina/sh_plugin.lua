PLUGIN.name = "Stamina"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a stamina system to limit running."

if (SERVER) then
	function PLUGIN:PostPlayerLoadout(client)
		client:setLocalVar("stm", 100)

		local uniqueID = "nutStam"..client:SteamID()
		local offset = 0
		local velocity
		local length2D = 0
		local runSpeed = client:GetRunSpeed() - 5

		timer.Create(uniqueID, 0.25, 0, function()
			if (IsValid(client)) then
				local character = client:getChar()

				if (client:GetMoveType() != MOVETYPE_NOCLIP and character) then
					velocity = client:GetVelocity()
					length2D = velocity:Length2D()
					runSpeed = nut.config.get("runSpeed") + character:getAttrib("stm", 0)

					if (client:WaterLevel() > 1) then
						runSpeed = runSpeed * 0.775
					end

					if (client:KeyDown(IN_SPEED) and length2D >= (runSpeed - 10)) then
						offset = -2 + (character:getAttrib("end", 0) / 60)
					elseif (offset > 0.5) then
						offset = 1
					else
						offset = 1.75
					end

					if (client:Crouching()) then
						offset = offset + 1
					end

					local current = client:getLocalVar("stm", 0)
					local value = math.Clamp(current + offset, 0, 100)

					if (current != value) then
						client:setLocalVar("stm", value)

						if (value == 0 and !client.nutBreathing) then
							client:SetRunSpeed(nut.config.get("walkSpeed"))
							client.nutBreathing = true

							character:updateAttrib("end", 0.1)
							character:updateAttrib("stm", 0.01)

							hook.Run("PlayerStaminaLost", client)
						elseif (value >= 50 and client.nutBreathing) then
							client:SetRunSpeed(runSpeed)
							client.nutBreathing = false
						end
					end
				end
			else
				timer.Remove(uniqueID)
			end
		end)
	end

	local playerMeta = FindMetaTable("Player")

	function playerMeta:restoreStamina(amount)
		local current = self:getLocalVar("stm", 0)
		local value = math.Clamp(current + amount, 0, 100)

		self:setLocalVar("stm", value)
	end
else
	nut.bar.add(function()
		return LocalPlayer():getLocalVar("stm", 0) / 100
	end, Color(200, 200, 40), nil, "stm")
end