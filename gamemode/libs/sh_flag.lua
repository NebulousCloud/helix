--[[
	Purpose: A library to set up player flags that can be used to control
	things such as access to spawning props or tool trust.
--]]

nut.flag = nut.flag or {}
nut.flag.buffer = nut.flag.buffer or {}

--[[
	Purpose: Registers a flag based off the character given as the desired flag
	and a structure for the flag, data. The structure should include onReceived,
	onTaken, and onSpawn. These three functions have a player passed.
--]]
function nut.flag.Create(flag, data)
	nut.flag.buffer[flag] = data
end

if (SERVER) then
	--[[
		Purpose: Used in the PlayerSpawn hook, it gathers all of the flags the
		player has and calls onSpawn, passing the player for the flags. This is
		needed for flags that allow weapons, such as the tool trust flag.
	--]]
	function nut.flag.OnSpawn(client)
		for k, v in pairs(client:GetFlags()) do
			local flagTable = nut.flag.buffer[v]

			if (flagTable and flagTable.onSpawn) then
				flagTable.onSpawn(client)
			end
		end
	end
else
	hook.Add("BuildHelpOptions", "nut_FlagHelp", function(data)
		data:AddHelp("Flags", function()
			local html = ""

			for k, v in SortedPairs(nut.flag.buffer) do
				local color = "<font color=\"red\">&#10008;"

				if (LocalPlayer():HasFlag(k)) then
					color = "<font color=\"green\">&#10004;"
				end

				html = html.."<p><b>"..color.."&nbsp;</font>"..k.."</b><br /><hi><i>Description:</i> "..v.desc or nut.lang.Get("no_desc").."</p>"
			end

			return html
		end, "icon16/flag_blue.png")
	end)
end

do
	local playerMeta = FindMetaTable("Player")

	-- Player flag functions.
	if (SERVER) then
		--[[
			Purpose: Validates that the flag exists within the system and inserts
			the flag into the flags character data, then calls onReceived for the flag,
			passing the player.
		--]]
		function playerMeta:GiveFlag(flag)
			if (self.character) then
				if (#flag > 1) then
					for k, v in pairs(string.Explode("", flag)) do
						self:GiveFlag(v)
					end

					return
				end

				local flagTable = nut.flag.buffer[flag]

				if (flagTable and flagTable.onReceived) then
					flagTable.onReceived(self)
				end

				self.character:SetData("flags", self:GetFlagString()..flag)
			end
		end

		--[[
			Purpose: Does the opposite of GiveFLag, removes any matches of the flag
			from the flags character data and calls onTaken from the flag's table, passing
			the player.
		--]]
		function playerMeta:TakeFlag(flag)
			if (self.character) then
				if (#flag > 1) then
					for k, v in pairs(string.Explode("", flag)) do
						self:TakeFlag(v)
					end

					return
				end

				local flagTable = nut.flag.buffer[flag]

				if (flagTable and flagTable.onTaken) then
					flagTable.onTaken(self)
				end

				self.character:SetData("flags", string.gsub(self:GetFlagString(), flag, ""))
			end
		end
	end

	--[[
		Purpose: Returns the raw flags character data.
	--]]
	function playerMeta:GetFlagString()
		if (self.character) then
			return self.character:GetData("flags", "")
		end

		return ""
	end

	--[[
		Purpose: Returns the flags as a table by exploding the player's flag string into
		seperate characters, since flags are only one character each. By a default, an
		empty table will be returned if nothing else was.
	--]]
	function playerMeta:GetFlags()
		if (self.character) then
			return string.Explode("", self:GetFlagString())
		end

		return {}
	end

	--[[
		Purpose: Checks to see if the flag string contains the flag specified and returns
		true if it does or false if it does not.
	--]]
	function playerMeta:HasFlag(flag)
		if (self.character) then
			return string.find(self:GetFlagString(), flag) != nil
		end

		return false
	end
end

-- Default flags that all schemas use.
nut.flag.Create("p", {
	desc = "Allows access to the physgun.",
	onReceived = function(client)
		client:Give("weapon_physgun")
		client:SelectWeapon("weapon_physgun")
	end,
	onTaken = function(client)
		client:StripWeapon("weapon_physgun")
	end,
	onSpawn = function(client)
		client:Give("weapon_physgun")
	end
})

nut.flag.Create("t", {
	desc = "Allows access to the toolgun.",
	onReceived = function(client)
		client:Give("gmod_tool")
		client:SelectWeapon("gmod_tool")
	end,
	onTaken = function(client)
		client:StripWeapon("gmod_tool")
	end,
	onSpawn = function(client)
		client:Give("gmod_tool")
	end
})

nut.flag.Create("e", {
	desc = "Allows one to spawn objects."
})

nut.flag.Create("n", {
	desc = "Allows one to spawn NPCs."
})

nut.flag.Create("r", {
	desc = "Allows one to spawn ragdolls."
})

nut.flag.Create("c", {
	desc = "Allows one to spawn vehicles."
})