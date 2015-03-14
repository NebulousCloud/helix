PLUGIN.name = "Spawn Saver"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Saves the position of a character."

-- Called right before the character has its information save.
function PLUGIN:CharacterPreSave(character)
	-- Get the player from the character.
	local client = character:getPlayer()

	-- Check to see if we can get the player's position.
	if (IsValid(client)) then
		-- Store the position in the character's data.
		character:setData("pos", {client:GetPos(), client:EyeAngles(), game.GetMap()})
	end
end

-- Called after the player's loadout has been set.
function PLUGIN:PlayerLoadedChar(client, character, lastChar)
	timer.Simple(0, function()
		if (IsValid(client)) then
			-- Get the saved position from the character data.
			local position = character:getData("pos")

			-- Check if the position was set.
			if (position) then
				if (position[3] and position[3]:lower() == game.GetMap():lower()) then
					-- Restore the player to that position.
					client:SetPos(position[1].x and position[1] or client:GetPos())
					client:SetEyeAngles(position[2].p and position[2] or Angle(0, 0, 0))
				end

				-- Remove the position data since it is no longer needed.
				character:setData("pos", nil)
			end
		end
	end)
end