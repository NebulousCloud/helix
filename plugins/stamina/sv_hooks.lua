local PLUGIN = PLUGIN

function PLUGIN:PlayerLoadedChar(client)
	local uniqueID = "nut_Stamina"..client:SteamID()

	timer.Remove(uniqueID)
	timer.Create(uniqueID, 0.9, 0, function()
		if (!IsValid(client)) then
			timer.Remove(uniqueID)

			return
		end

		local runSpeed = nut.config.runSpeed - 10

		if (client:GetMoveType() != MOVETYPE_NOCLIP and client.character) then
			local length2D = client:GetVelocity():Length2D()
			local value = 3

			if (length2D >= runSpeed) then
				value = -10
			elseif (length2D <= 10) then
				value = 5

				if (client:Crouching()) then
					value = 7
				end
			end

			local stamina = math.Clamp(client.character:GetVar("stamina", 100) + value, 0, 100)

			if (stamina != client.character:GetVar("stamina", 100)) then
				client.character:SetVar("stamina", stamina)
			end

			if (stamina <= 0) then
				client:SetRunSpeed(nut.config.walkSpeed)
				client.nut_OutOfStamina = true

				if (nut.config.breathing == true) then
					client.nut_Breathing = CreateSound(client, "player/breathe1.wav")
					client.nut_Breathing:Play()
					client.nut_Breathing:ChangeVolume(0.5, 0)
				end
			elseif (stamina >= nut.config.staminaRestore and client.nut_OutOfStamina) then
				client.nut_OutOfStamina = false
				client:SetRunSpeed(nut.config.runSpeed)

				if (client.nut_Breathing) then
					client.nut_Breathing:FadeOut(10)
					client.nut_Breathing = nil
				end
			end
		end
	end)
end

function PLUGIN:PlayerSpawn(client)
	if (client.character) then
		client.character:SetVar("stamina", 100)
	end
end