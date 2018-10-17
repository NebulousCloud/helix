ix.flag = ix.flag or {}
ix.flag.list = ix.flag.list or {}

-- Adds a flag that does something when set.
function ix.flag.Add(flag, description, callback)
	-- Add the flag to a list, storing the description and callback (if there is one).
	ix.flag.list[flag] = {description = description, callback = callback}
end

if (SERVER) then
	-- Called to apply flags when a player has spawned.
	function ix.flag.OnSpawn(client)
		-- Check if they have a valid character.
		if (client:GetCharacter()) then
			-- Get all of the character's flags.
			local flags = client:GetCharacter():GetFlags()

			for i = 1, #flags do
				-- Get each individual flag.
				local flag = flags[i]
				local info = ix.flag.list[flag]

				-- Check if the flag has a callback.
				if (info and info.callback) then
					-- Run the callback, passing the player and true so they get whatever benefits.
					info.callback(client, true)
				end
			end
		end
	end
end

do
	-- Extend the character metatable to allow flag giving/taking.
	local character = ix.meta.character

	-- Flags can only be set server-side.
	if (SERVER) then
		-- Set the flag data to the flag string.
		function character:SetFlags(flags)
			self:SetData("f", flags)
		end

		-- Add a flag to the flag string.
		function character:GiveFlags(flags)
			local addedFlags = ""

			-- Get the individual flags within the flag string.
			for i = 1, #flags do
				local flag = flags[i]
				local info = ix.flag.list[flag]

				if (info) then
					if (!self:HasFlags(flag)) then
						addedFlags = addedFlags..flag
					end

					if (info.callback) then
						-- Pass the player and true (true for the flag being given.)
						info.callback(self:GetPlayer(), true)
					end
				end
			end

			-- Only change the flag string if it is different.
			if (addedFlags != "") then
				self:SetFlags(self:GetFlags()..addedFlags)
			end
		end

		-- Remove the flags from the flag string.
		function character:TakeFlags(flags)
			local oldFlags = self:GetFlags()
			local newFlags = oldFlags

			-- Get the individual flags within the flag string.
			for i = 1, #flags do
				local flag = flags[i]
				local info = ix.flag.list[flag]

				-- Call the callback if the flag has been registered.
				if (info and info.callback) then
					-- Pass the player and false (false since the flag is being taken)
					info.callback(self:GetPlayer(), false)
				end

				newFlags = newFlags:gsub(flag, "")
			end

			if (newFlags != oldFlags) then
				self:SetFlags(newFlags)
			end
		end
	end

	-- Return the flag string.
	function character:GetFlags()
		return self:GetData("f", "")
	end

	-- Check if the flag string contains the flags specified.
	function character:HasFlags(flags)
		local bHasFlag = hook.Run("CharacterHasFlags", self, flags)

		if (bHasFlag == true) then
			return true
		end

		local flagList = self:GetFlags()

		for i = 1, #flags do
			if (flagList:find(flags[i], 1, true)) then
				return true
			end
		end

		return false
	end
end

do
	ix.flag.Add("p", "Access to the physgun.", function(client, isGiven)
		if (isGiven) then
			client:Give("weapon_physgun")
			client:SelectWeapon("weapon_physgun")
		else
			client:StripWeapon("weapon_physgun")
		end
	end)

	ix.flag.Add("t", "Access to the toolgun", function(client, isGiven)
		if (isGiven) then
			client:Give("gmod_tool")
			client:SelectWeapon("gmod_tool")
		else
			client:StripWeapon("gmod_tool")
		end
	end)

	ix.flag.Add("c", "Access to spawn chairs.")
	ix.flag.Add("C", "Access to spawn vehicles.")
	ix.flag.Add("r", "Access to spawn ragdolls.")
	ix.flag.Add("e", "Access to spawn props.")
	ix.flag.Add("n", "Access to spawn NPCs.")
end
