
PLUGIN.name = "Stamina"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds a stamina system to limit running."

-- luacheck: push ignore 631
ix.config.Add("staminaDrain", 1, "How much stamina to drain per tick (every quarter second). This is calculated before attribute reduction.", nil, {
	data = {min = 0, max = 10, decimals = 2},
	category = "characters"
})

ix.config.Add("staminaRegeneration", 1.75, "How much stamina to regain per tick (every quarter second).", nil, {
	data = {min = 0, max = 10, decimals = 2},
	category = "characters"
})

ix.config.Add("staminaCrouchRegeneration", 2, "How much stamina to regain per tick (every quarter second) while crouching.", nil, {
	data = {min = 0, max = 10, decimals = 2},
	category = "characters"
})
-- luacheck: pop

if (SERVER) then
	function PLUGIN:PostPlayerLoadout(client)
		local uniqueID = "ixStam"..client:SteamID()
		local offset = 0
		local runSpeed = client:GetRunSpeed() - 5

		timer.Create(uniqueID, 0.25, 0, function()
			if (!IsValid(client)) then
				timer.Remove(uniqueID)
				return
			end

			local character = client:GetCharacter()

			if (!character or client:GetMoveType() == MOVETYPE_NOCLIP) then
				return
			end

			runSpeed = ix.config.Get("runSpeed") + character:GetAttribute("stm", 0)

			if (client:WaterLevel() > 1) then
				runSpeed = runSpeed * 0.775
			end

			local walkSpeed = ix.config.Get("walkSpeed")
			local maxAttributes = ix.config.Get("maxAttributes", 30)

			if (client:KeyDown(IN_SPEED) and client:GetVelocity():LengthSqr() >= (walkSpeed * walkSpeed)) then
				-- characters could have attribute values greater than max if the config was changed
				offset = -ix.config.Get("staminaDrain", 1) + math.min(character:GetAttribute("end", 0), maxAttributes) / maxAttributes
			else
				offset = client:Crouching() and ix.config.Get("staminaCrouchRegeneration", 2) or ix.config.Get("staminaRegeneration", 1.75)
			end

			offset = hook.Run("AdjustStaminaOffset", client, offset) or offset

			local current = client:GetLocalVar("stm", 0)
			local value = math.Clamp(current + offset, 0, 100)

			if (current != value) then
				client:SetLocalVar("stm", value)

				if (value == 0 and !client:GetNetVar("brth", false)) then
					client:SetRunSpeed(walkSpeed)
					client:SetNetVar("brth", true)

					character:UpdateAttrib("end", 0.1)
					character:UpdateAttrib("stm", 0.01)

					hook.Run("PlayerStaminaLost", client)
				elseif (value >= 50 and client:GetNetVar("brth", false)) then
					client:SetRunSpeed(runSpeed)
					client:SetNetVar("brth", nil)

					hook.Run("PlayerStaminaGained", client)
				end
			end
		end)
	end

	function PLUGIN:CharacterPreSave(character)
		local client = character:GetPlayer()

		if (IsValid(client)) then
			character:SetData("stamina", client:GetLocalVar("stm", 0))
		end
	end

	function PLUGIN:PlayerLoadedCharacter(client, character)
		timer.Simple(0.25, function()
			client:SetLocalVar("stm", character:GetData("stamina", 100))
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
