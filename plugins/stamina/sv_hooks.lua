local PLUGIN = PLUGIN
local math_min = math.min
local math_Clamp = math.Clamp
local GetVelocity = FindMetaTable("Entity").GetVelocity
local Length2D = FindMetaTable("Vector").Length2D

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
			local length2D = Length2D(GetVelocity(client))
			local value = 3

			if (length2D >= runSpeed) then
				value = -10 + math_min((client:GetAttrib(ATTRIB_END) or 0) * 0.25, 7.5)

				client:SetNutVar("runDist", client:GetNutVar("runDist", 0) + 1)

				if (client:GetNutVar("runDist") > 5) then
					client:UpdateAttrib(ATTRIB_END, 0.025)
					client:UpdateAttrib(ATTRIB_SPD, 0.0125)
					client:SetNutVar("runDist", 0)
				end
			elseif (length2D <= 10) then
				value = 5

				if (client:Crouching()) then
					value = 7
				end
			end

			local stamina = math_Clamp(client.character:GetVar("stamina", 100) + value, 0, 100)

			if (stamina != client.character:GetVar("stamina", 100)) then
				client.character:SetVar("stamina", stamina)
			end

			if (stamina <= 0) then
				client:SetRunSpeed(nut.config.walkSpeed)
				client:SetNutVar("outOfStam", true)

				hook.Run("PlayerLostStamina", client)
				
				if (nut.config.breathing == true and hook.Run("PlayerShouldBreathe", client) != false) then
					local breathing = CreateSound(client, "player/breathe1.wav")
					breathing:Play()
					breathing:ChangeVolume(0.5, 0)

					client:SetNutVar("breathing", breathing)
				end
			elseif (stamina >= nut.config.staminaRestore and client:GetNutVar("outOfStam")) then
				client:SetNutVar("outOfStam", false)
				client:SetRunSpeed(nut.config.runSpeed)

				local breathing = client:GetNutVar("breathing")

				if (breathing) then
					breathing:FadeOut(10)
					breathing = nil
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